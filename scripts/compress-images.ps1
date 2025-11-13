# Compress PNG Images Script
# Optimizes PNG images to reduce file size while maintaining quality

param(
    [string]$SourceDir = "data/processed/all_black_bg",
    [string]$OutputDir = "data/processed/all_black_bg_compressed",
    [int]$Quality = 90  # PNG compression level (0-100, higher = better quality but larger files)
)

$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Drawing

function Compress-PngImage {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$CompressionLevel = 90
    )
    
    try {
        # Load image
        $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create encoder parameters for PNG compression
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        
        # Set compression level (0 = best compression, 100 = best quality)
        # For PNG, we'll use a quality parameter that affects compression
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality,
            [long]$CompressionLevel
        )
        
        # Try to save with compression, but PNG encoder may not support quality parameter
        # So we'll use a different approach - convert to indexed color if possible
        
        # Check if we can reduce color depth
        $width = $original.Width
        $height = $original.Height
        
        # Create optimized bitmap
        # For images with mostly black backgrounds, we can use 8-bit indexed color
        $optimized = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format8bppIndexed)
        
        # Create palette (256 colors max for 8-bit)
        $palette = $optimized.Palette
        $colors = New-Object System.Drawing.Color[] 256
        
        # Start with black
        $colors[0] = [System.Drawing.Color]::Black
        
        # Build color palette from image (simplified - just use most common colors)
        # For now, we'll use a simpler approach: convert to 24-bit RGB but optimize
        
        $optimized.Dispose()
        
        # Alternative: Save with PNG optimization using different method
        # Create a new bitmap and copy, which can help with compression
        $result = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($result)
        $graphics.DrawImage($original, 0, 0, $width, $height)
        $graphics.Dispose()
        
        # Save with PNG format and compression
        # PNG doesn't support quality parameter, so we'll use a memory stream approach
        $ms = New-Object System.IO.MemoryStream
        $result.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Write to file
        [System.IO.File]::WriteAllBytes($OutputPath, $ms.ToArray())
        $ms.Dispose()
        
        $original.Dispose()
        $result.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to compress $SourcePath : $_"
        return $false
    }
}

function Optimize-PngImage {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )
    
    try {
        # Load image
        $img = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create optimized version
        # Use Format24bppRgb to remove alpha channel if present (saves space)
        $optimized = New-Object System.Drawing.Bitmap($img.Width, $img.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $g = [System.Drawing.Graphics]::FromImage($optimized)
        $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
        $g.Dispose()
        
        # Save using memory stream for better compression
        $ms = New-Object System.IO.MemoryStream
        $optimized.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Get compressed bytes
        $bytes = $ms.ToArray()
        $ms.Dispose()
        
        # Write to file
        [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
        
        $img.Dispose()
        $optimized.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to optimize $SourcePath : $_"
        return $false
    }
}

# Main script
Write-Host "=== Compress PNG Images ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host "Output: $OutputDir" -ForegroundColor Yellow
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
    
    if (Optimize-PngImage -SourcePath $img.FullName -OutputPath $outputPath) {
        $newSize = (Get-Item $outputPath).Length
        $saved = $originalSize - $newSize
        $totalSaved += $saved
        $savedPercent = [math]::Round(($saved / $originalSize) * 100, 1)
        
        $processedCount++
        Write-Host " [OK - Saved $savedPercent%]" -ForegroundColor Green
    } else {
        $failedCount++
        Write-Host " [FAILED]" -ForegroundColor Red
    }
}

# Calculate final sizes
$newSize = (Get-ChildItem -Path $OutputDir -Filter "*.png" -File | Measure-Object -Property Length -Sum).Sum
$newSizeMB = [math]::Round($newSize / 1MB, 2)
$totalSavedMB = [math]::Round($totalSaved / 1MB, 2)
$reductionPercent = [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)

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

