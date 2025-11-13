# Compress PNG Images with Indexed Color
# Converts images to 8-bit indexed color for significant size reduction

param(
    [string]$SourceDir = "data/processed/all_black_bg",
    [string]$OutputDir = "data/processed/all_black_bg_compressed",
    [int]$MaxColors = 256  # Maximum colors in palette (8-bit = 256)
)

$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Drawing

function Compress-ImageWithIndexedColor {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$MaxColors = 256
    )
    
    try {
        # Load image
        $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create 8-bit indexed color bitmap
        $compressed = New-Object System.Drawing.Bitmap($original.Width, $original.Height, [System.Drawing.Imaging.PixelFormat]::Format8bppIndexed)
        
        # Get palette
        $palette = $compressed.Palette
        
        # Build color palette from image
        # For images with black backgrounds and colored lines, we can use a smaller palette
        $colorSet = New-Object System.Collections.Generic.HashSet[System.Drawing.Color]
        
        # Sample colors from image (every Nth pixel to avoid memory issues)
        $sampleRate = [math]::Max(1, [math]::Floor($original.Width * $original.Height / 10000))
        $pixelCount = 0
        
        for ($y = 0; $y -lt $original.Height; $y += $sampleRate) {
            for ($x = 0; $x -lt $original.Width; $x += $sampleRate) {
                $color = $original.GetPixel($x, $y)
                # Ignore fully transparent or near-black colors that are very similar
                $colorKey = [System.Drawing.Color]::FromArgb($color.R, $color.G, $color.B)
                if ($colorSet.Count -lt $MaxColors) {
                    $null = $colorSet.Add($colorKey)
                }
                $pixelCount++
                if ($colorSet.Count -ge $MaxColors) { break }
            }
            if ($colorSet.Count -ge $MaxColors) { break }
        }
        
        # Fill palette with colors (pad with black if needed)
        $colorArray = $colorSet.ToArray()
        for ($i = 0; $i -lt [math]::Min($MaxColors, $colorArray.Length); $i++) {
            $palette.Entries[$i] = $colorArray[$i]
        }
        # Fill remaining with black
        for ($i = $colorArray.Length; $i -lt $MaxColors; $i++) {
            $palette.Entries[$i] = [System.Drawing.Color]::Black
        }
        
        $compressed.Palette = $palette
        
        # Copy pixels with color matching
        for ($y = 0; $y -lt $original.Height; $y++) {
            for ($x = 0; $x -lt $original.Width; $x++) {
                $color = $original.GetPixel($x, $y)
                $colorKey = [System.Drawing.Color]::FromArgb($color.R, $color.G, $color.B)
                
                # Find closest color in palette
                $bestIndex = 0
                $minDistance = [double]::MaxValue
                for ($i = 0; $i -lt $colorArray.Length; $i++) {
                    $palColor = $colorArray[$i]
                    $distance = [math]::Sqrt(
                        [math]::Pow($color.R - $palColor.R, 2) +
                        [math]::Pow($color.G - $palColor.G, 2) +
                        [math]::Pow($color.B - $palColor.B, 2)
                    )
                    if ($distance -lt $minDistance) {
                        $minDistance = $distance
                        $bestIndex = $i
                    }
                }
                
                $compressed.SetPixel($x, $y, $palette.Entries[$bestIndex])
            }
        }
        
        # Save
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

# Simpler approach: Use Format8bppIndexed with quantized colors
function Compress-ImageSimple {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )
    
    try {
        $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create temporary 8-bit bitmap to get a palette
        $temp = New-Object System.Drawing.Bitmap(1, 1, [System.Drawing.Imaging.PixelFormat]::Format8bppIndexed)
        $palette = $temp.Palette
        $temp.Dispose()
        
        # Build color palette by quantizing (sample colors first)
        $colorMap = @{}
        $nextIndex = 0
        
        # Quantize colors to reduce palette size
        # Sample pixels to build palette
        $sampleStep = [math]::Max(1, [math]::Floor([math]::Sqrt($original.Width * $original.Height) / 50))
        for ($y = 0; $y -lt $original.Height; $y += $sampleStep) {
            for ($x = 0; $x -lt $original.Width; $x += $sampleStep) {
                if ($nextIndex -ge 256) { break }
                $color = $original.GetPixel($x, $y)
                # Quantize to reduce color space
                $qR = [math]::Floor($color.R / 8) * 8
                $qG = [math]::Floor($color.G / 8) * 8
                $qB = [math]::Floor($color.B / 8) * 8
                $colorKey = "$($qR),$($qG),$($qB)"
                
                if (-not $colorMap.ContainsKey($colorKey)) {
                    $colorMap[$colorKey] = $nextIndex
                    $palette.Entries[$nextIndex] = [System.Drawing.Color]::FromArgb($qR, $qG, $qB)
                    $nextIndex++
                }
            }
            if ($nextIndex -ge 256) { break }
        }
        
        # Fill remaining with black
        for ($i = $nextIndex; $i -lt 256; $i++) {
            $palette.Entries[$i] = [System.Drawing.Color]::Black
        }
        
        # Create 8-bit indexed bitmap
        $compressed = New-Object System.Drawing.Bitmap($original.Width, $original.Height, [System.Drawing.Imaging.PixelFormat]::Format8bppIndexed)
        $compressed.Palette = $palette
        
        # Map pixels to palette
        for ($y = 0; $y -lt $original.Height; $y++) {
            for ($x = 0; $x -lt $original.Width; $x++) {
                $color = $original.GetPixel($x, $y)
                $qR = [math]::Floor($color.R / 8) * 8
                $qG = [math]::Floor($color.G / 8) * 8
                $qB = [math]::Floor($color.B / 8) * 8
                $colorKey = "$($qR),$($qG),$($qB)"
                
                if ($colorMap.ContainsKey($colorKey)) {
                    $compressed.SetPixel($x, $y, $palette.Entries[$colorMap[$colorKey]])
                } else {
                    # Find closest color in palette
                    $bestIndex = 0
                    $minDist = [double]::MaxValue
                    for ($i = 0; $i -lt $nextIndex; $i++) {
                        $palColor = $palette.Entries[$i]
                        $dist = [math]::Sqrt(
                            [math]::Pow($color.R - $palColor.R, 2) +
                            [math]::Pow($color.G - $palColor.G, 2) +
                            [math]::Pow($color.B - $palColor.B, 2)
                        )
                        if ($dist -lt $minDist) {
                            $minDist = $dist
                            $bestIndex = $i
                        }
                    }
                    $compressed.SetPixel($x, $y, $palette.Entries[$bestIndex])
                }
            }
        }
        
        # Save
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

# Main script
Write-Host "=== Compress PNG Images (Indexed Color) ===" -ForegroundColor Cyan
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
    
    if (Compress-ImageSimple -SourcePath $img.FullName -OutputPath $outputPath) {
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

