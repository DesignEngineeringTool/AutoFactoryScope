# Simple Image Compression Script
# Reduces file size by color quantization while maintaining visual quality

param(
    [string]$SourceDir = "data/processed/all_black_bg",
    [string]$OutputDir = "data/processed/all_black_bg_compressed",
    [int]$QuantizationLevel = 4  # Higher = more compression (4 = quantize to 64 levels per channel)
)

$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Drawing

function Compress-Image {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$QuantLevel = 4
    )
    
    try {
        $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create new 24-bit RGB bitmap
        $compressed = New-Object System.Drawing.Bitmap($original.Width, $original.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        
        # Quantize colors to reduce file size
        for ($y = 0; $y -lt $original.Height; $y++) {
            for ($x = 0; $x -lt $original.Width; $x++) {
                $color = $original.GetPixel($x, $y)
                
                # Quantize color values
                $qR = [math]::Floor($color.R / $QuantLevel) * $QuantLevel
                $qG = [math]::Floor($color.G / $QuantLevel) * $QuantLevel
                $qB = [math]::Floor($color.B / $QuantLevel) * $QuantLevel
                
                # Clamp to valid range
                $qR = [math]::Min(255, [math]::Max(0, $qR))
                $qG = [math]::Min(255, [math]::Max(0, $qG))
                $qB = [math]::Min(255, [math]::Max(0, $qB))
                
                $compressed.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($qR, $qG, $qB))
            }
        }
        
        # Save with compression
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Compression, [long]9)  # Best compression
        
        $compressed.Save($OutputPath, $encoder, $encoderParams)
        
        $original.Dispose()
        $compressed.Dispose()
        $encoderParams.Dispose()
        
        return $true
    }
    catch {
        # Fallback: simple save
        try {
            $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
            $compressed = New-Object System.Drawing.Bitmap($original.Width, $original.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            $g = [System.Drawing.Graphics]::FromImage($compressed)
            $g.DrawImage($original, 0, 0)
            $g.Dispose()
            
            # Quantize during copy
            for ($y = 0; $y -lt $compressed.Height; $y++) {
                for ($x = 0; $x -lt $compressed.Width; $x++) {
                    $color = $compressed.GetPixel($x, $y)
                    $qR = [math]::Floor($color.R / $QuantLevel) * $QuantLevel
                    $qG = [math]::Floor($color.G / $QuantLevel) * $QuantLevel
                    $qB = [math]::Floor($color.B / $QuantLevel) * $QuantLevel
                    $compressed.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($qR, $qG, $qB))
                }
            }
            
            $compressed.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $original.Dispose()
            $compressed.Dispose()
            return $true
        }
        catch {
            Write-Error "Failed to compress $SourcePath : $_"
            return $false
        }
    }
}

# Main script
Write-Host "=== Compress PNG Images ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host "Output: $OutputDir" -ForegroundColor Yellow
Write-Host "Quantization Level: $QuantizationLevel" -ForegroundColor Yellow
Write-Host ""

# Check source directory
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

# Get original size
$originalSize = (Get-ChildItem -Path $SourceDir -Filter "*.png" -File | Measure-Object -Property Length -Sum).Sum
$originalSizeMB = [math]::Round($originalSize / 1MB, 2)

Write-Host "Original size: $originalSizeMB MB" -ForegroundColor Yellow
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
} else {
    # Clear existing files
    Get-ChildItem -Path $OutputDir -Filter "*.png" | Remove-Item -Force
}

# Get all PNG images
$images = Get-ChildItem -Path $SourceDir -Filter "*.png" -File | Sort-Object Name

if ($images.Count -eq 0) {
    Write-Warning "No PNG images found in $SourceDir"
    exit 1
}

Write-Host "Found $($images.Count) images to compress" -ForegroundColor Green
Write-Host ""

$processedCount = 0
$failedCount = 0
$total = $images.Count
$current = 0
$totalSaved = 0

foreach ($img in $images) {
    $current++
    $outputPath = Join-Path $OutputDir $img.Name
    
    $percent = [math]::Round(($current / $total) * 100, 1)
    Write-Host "[$current/$total - $percent%] Compressing: $($img.Name)" -ForegroundColor Gray -NoNewline
    
    $originalSize = $img.Length
    
    if (Compress-Image -SourcePath $img.FullName -OutputPath $outputPath -QuantLevel $QuantizationLevel) {
        $newSize = (Get-Item $outputPath).Length
        $saved = $originalSize - $newSize
        $totalSaved += $saved
        $savedPercent = if ($originalSize -gt 0) { [math]::Round(($saved / $originalSize) * 100, 1) } else { 0 }
        
        $processedCount++
        if ($savedPercent -gt 0) {
            Write-Host " [OK - Saved $savedPercent%]" -ForegroundColor Green
        } else {
            Write-Host " [OK]" -ForegroundColor Green
        }
    } else {
        $failedCount++
        Write-Host " [FAILED]" -ForegroundColor Red
    }
}

# Calculate final sizes
$newSize = (Get-ChildItem -Path $OutputDir -Filter "*.png" -File | Measure-Object -Property Length -Sum).Sum
$newSizeMB = [math]::Round($newSize / 1MB, 2)
$totalSavedMB = [math]::Round($totalSaved / 1MB, 2)
$reductionPercent = if ($originalSize -gt 0) { [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total images: $total" -ForegroundColor Yellow
Write-Host "  Processed: $processedCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "  Failed: $failedCount" -ForegroundColor Red
}
Write-Host "  Original size: $originalSizeMB MB" -ForegroundColor Yellow
Write-Host "  Compressed size: $newSizeMB MB" -ForegroundColor Green
Write-Host "  Space saved: $totalSavedMB MB ($reductionPercent%)" -ForegroundColor Cyan
Write-Host "  Output directory: $OutputDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Done! Images compressed successfully." -ForegroundColor Green




