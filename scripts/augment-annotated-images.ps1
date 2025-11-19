# Augment Annotated Images Pipeline
# ==================================
# This script takes 38 annotated images and creates augmented versions:
# 1. Rotates images at various angles
# 2. Changes background to black
# 3. Transforms annotations correctly for rotations
# 4. Copies annotations for black background versions
#
# Prerequisites:
# - 38 PNG images in data/raw/RobotFloor/
# - 38 annotation files (.txt) in data/raw/RobotFloor/labels/
#
# Usage:
#   pwsh scripts/augment-annotated-images.ps1

param(
    [string]$RawImagesDir = "data/raw/RobotFloor",
    [string]$RawLabelsDir = "data/raw/RobotFloor/labels",
    [string]$ProcessedDir = "data/processed/RobotFloor",
    [int[]]$RotationAngles = @(15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240, 255, 270, 285, 300, 315, 330, 345),
    [int]$WhiteThreshold = 240
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Augment Annotated Images Pipeline" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Verify prerequisites
Write-Host "=== Step 0: Verifying Prerequisites ===" -ForegroundColor Cyan
Write-Host ""

# Check raw images
if (-not (Test-Path $RawImagesDir)) {
    Write-Error "Raw images directory not found: $RawImagesDir"
    exit 1
}

$pngFiles = Get-ChildItem -Path $RawImagesDir -Filter "*.png" -File | Sort-Object Name
if ($pngFiles.Count -eq 0) {
    Write-Error "No PNG files found in $RawImagesDir"
    exit 1
}

Write-Host "✅ Found $($pngFiles.Count) PNG images" -ForegroundColor Green

# Check annotations
if (-not (Test-Path $RawLabelsDir)) {
    Write-Error "Labels directory not found: $RawLabelsDir"
    Write-Host "Please annotate images first!" -ForegroundColor Red
    exit 1
}

$labelFiles = Get-ChildItem -Path $RawLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue | Sort-Object Name
Write-Host "✅ Found $($labelFiles.Count) annotation files" -ForegroundColor Green

if ($labelFiles.Count -ne $pngFiles.Count) {
    Write-Warning "Annotation count mismatch: $($labelFiles.Count) labels vs $($pngFiles.Count) images"
    Write-Host "Some images may not have annotations. Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Rotation angles: $($RotationAngles.Count) angles" -ForegroundColor Yellow
Write-Host "Expected output: $($pngFiles.Count) original + $($pngFiles.Count * $RotationAngles.Count) rotated + $($pngFiles.Count * ($RotationAngles.Count + 1)) black background = $($pngFiles.Count * ($RotationAngles.Count * 2 + 2)) total images" -ForegroundColor Yellow
Write-Host ""

# Create output directories
$rotatedDir = Join-Path $ProcessedDir "rotated"
$rotatedLabelsDir = Join-Path $rotatedDir "labels"
$blackBgDir = Join-Path $ProcessedDir "black_bg"
$blackBgLabelsDir = Join-Path $blackBgDir "labels"
$finalDir = $ProcessedDir
$finalLabelsDir = Join-Path $finalDir "labels"

New-Item -ItemType Directory -Force -Path $rotatedDir | Out-Null
New-Item -ItemType Directory -Force -Path $rotatedLabelsDir | Out-Null
New-Item -ItemType Directory -Force -Path $blackBgDir | Out-Null
New-Item -ItemType Directory -Force -Path $blackBgLabelsDir | Out-Null
New-Item -ItemType Directory -Force -Path $finalDir | Out-Null
New-Item -ItemType Directory -Force -Path $finalLabelsDir | Out-Null

# Load required assemblies
Add-Type -AssemblyName System.Drawing

# Step 1: Format original images to 640x640 (if needed)
Write-Host "=== Step 1: Formatting Original Images (640x640) ===" -ForegroundColor Cyan
Write-Host ""

$formattedDir = Join-Path $ProcessedDir "formatted"
New-Item -ItemType Directory -Force -Path $formattedDir | Out-Null

$formattedCount = 0
foreach ($img in $pngFiles) {
    $outputPath = Join-Path $formattedDir "starting_$($img.Name)"
    
    if (-not (Test-Path $outputPath)) {
        try {
            $bitmap = [System.Drawing.Bitmap]::FromFile($img.FullName)
            
            # Create 640x640 image with black background
            $formatted = New-Object System.Drawing.Bitmap(640, 640)
            $graphics = [System.Drawing.Graphics]::FromImage($formatted)
            $graphics.Clear([System.Drawing.Color]::Black)
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            
            # Calculate scaling to fit while maintaining aspect ratio
            $scale = [math]::Min(640.0 / $bitmap.Width, 640.0 / $bitmap.Height)
            $newWidth = [int]($bitmap.Width * $scale)
            $newHeight = [int]($bitmap.Height * $scale)
            $x = (640 - $newWidth) / 2
            $y = (640 - $newHeight) / 2
            
            $graphics.DrawImage($bitmap, $x, $y, $newWidth, $newHeight)
            $graphics.Dispose()
            $formatted.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            $bitmap.Dispose()
            $formatted.Dispose()
            $formattedCount++
        } catch {
            Write-Warning "Failed to format $($img.Name): $_"
        }
    } else {
        $formattedCount++
    }
}

Write-Host "✅ Formatted $formattedCount images" -ForegroundColor Green
Write-Host ""

# Step 2: Create rotated versions
Write-Host "=== Step 2: Creating Rotated Images ===" -ForegroundColor Cyan
Write-Host ""

$rotatedCount = 0
$formattedImages = Get-ChildItem -Path $formattedDir -Filter "*.png" -File

foreach ($img in $formattedImages) {
    $baseName = $img.BaseName -replace '^starting_', ''
    
    foreach ($angle in $RotationAngles) {
        $outputName = "starting_${baseName}_rot${angle}.png"
        $outputPath = Join-Path $rotatedDir $outputName
        
        if (-not (Test-Path $outputPath)) {
            try {
                $bitmap = [System.Drawing.Bitmap]::FromFile($img.FullName)
                
                # Calculate new dimensions for rotated image
                $radians = $angle * [math]::PI / 180
                $cos = [math]::Abs([math]::Cos($radians))
                $sin = [math]::Abs([math]::Sin($radians))
                $newWidth = [int]($bitmap.Width * $cos + $bitmap.Height * $sin)
                $newHeight = [int]($bitmap.Width * $sin + $bitmap.Height * $cos)
                
                # Create bitmap for rotated image
                $rotated = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
                $graphics = [System.Drawing.Graphics]::FromImage($rotated)
                $graphics.Clear([System.Drawing.Color]::Black)
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                
                # Translate to center, rotate, translate back
                $graphics.TranslateTransform($newWidth / 2, $newHeight / 2)
                $graphics.RotateTransform($angle)
                $graphics.TranslateTransform(-$bitmap.Width / 2, -$bitmap.Height / 2)
                
                # Draw rotated image
                $graphics.DrawImage($bitmap, 0, 0)
                $graphics.Dispose()
                $rotated.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
                
                $bitmap.Dispose()
                $rotated.Dispose()
                $rotatedCount++
            } catch {
                Write-Warning "Failed to rotate $($img.Name) by $angle degrees: $_"
            }
        } else {
            $rotatedCount++
        }
    }
    
    if ($rotatedCount % 50 -eq 0 -and $rotatedCount -gt 0) {
        Write-Host "  Created $rotatedCount rotated images..." -ForegroundColor Gray
    }
}

Write-Host "✅ Created $rotatedCount rotated images" -ForegroundColor Green
Write-Host ""

# Step 3: Transform annotations for rotations
Write-Host "=== Step 3: Transforming Annotations for Rotations ===" -ForegroundColor Cyan
Write-Host ""

& pwsh -File scripts/transform-annotations-for-rotation.ps1 `
    -OriginalImagesDir $formattedDir `
    -OriginalLabelsDir $RawLabelsDir `
    -RotatedImagesDir $rotatedDir `
    -RotatedLabelsDir $rotatedLabelsDir `
    -RotationAngles $RotationAngles

if ($LASTEXITCODE -ne 0) {
    Write-Error "Annotation transformation failed!"
    exit 1
}

Write-Host "✅ Annotations transformed for rotations" -ForegroundColor Green
Write-Host ""

# Step 4: Create black background versions
Write-Host "=== Step 4: Creating Black Background Versions ===" -ForegroundColor Cyan
Write-Host ""

# Copy formatted images to black bg directory
$blackBgCount = 0
foreach ($img in $formattedImages) {
    $outputPath = Join-Path $blackBgDir $img.Name
    if (-not (Test-Path $outputPath)) {
        Copy-Item $img.FullName $outputPath -Force
        $blackBgCount++
    } else {
        $blackBgCount++
    }
}

# Process black background for formatted images
& pwsh -File scripts/process-all-with-black-bg.ps1 -SourceDir $formattedDir -OutputDir $blackBgDir -WhiteThreshold $WhiteThreshold

# Process black background for rotated images
$rotatedImages = Get-ChildItem -Path $rotatedDir -Filter "*.png" -File
$rotatedBlackBgCount = 0

foreach ($img in $rotatedImages) {
    $outputPath = Join-Path $blackBgDir $img.Name
    if (-not (Test-Path $outputPath)) {
        # Process this rotated image to black background
        try {
            $bitmap = [System.Drawing.Bitmap]::FromFile($img.FullName)
            $result = New-Object System.Drawing.Bitmap($bitmap.Width, $bitmap.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            
            for ($y = 0; $y -lt $bitmap.Height; $y++) {
                for ($x = 0; $x -lt $bitmap.Width; $x++) {
                    $pixel = $bitmap.GetPixel($x, $y)
                    $r = $pixel.R
                    $g = $pixel.G
                    $b = $pixel.B
                    
                    # If pixel is white/near-white, make it black
                    if ($r -ge $WhiteThreshold -and $g -ge $WhiteThreshold -and $b -ge $WhiteThreshold) {
                        $result.SetPixel($x, $y, [System.Drawing.Color]::Black)
                    } else {
                        $result.SetPixel($x, $y, $pixel)
                    }
                }
            }
            
            $result.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bitmap.Dispose()
            $result.Dispose()
            $rotatedBlackBgCount++
        } catch {
            Write-Warning "Failed to process $($img.Name) to black background: $_"
        }
    } else {
        $rotatedBlackBgCount++
    }
}

Write-Host "✅ Created black background versions" -ForegroundColor Green
Write-Host ""

# Step 5: Copy annotations for black background versions
Write-Host "=== Step 5: Copying Annotations for Black Background ===" -ForegroundColor Cyan
Write-Host ""

# Copy annotations from formatted images
$formattedLabelsDir = $RawLabelsDir
foreach ($labelFile in $labelFiles) {
    $baseName = $labelFile.BaseName
    $sourceLabel = $labelFile.FullName
    $targetLabel = Join-Path $blackBgLabelsDir "starting_${baseName}.txt"
    
    if (Test-Path $sourceLabel) {
        Copy-Item $sourceLabel $targetLabel -Force
    }
}

# Copy annotations from rotated images
$rotatedLabelFiles = Get-ChildItem -Path $rotatedLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
foreach ($labelFile in $rotatedLabelFiles) {
    $targetLabel = Join-Path $blackBgLabelsDir $labelFile.Name
    Copy-Item $labelFile.FullName $targetLabel -Force
}

Write-Host "✅ Copied annotations for black background versions" -ForegroundColor Green
Write-Host ""

# Step 6: Merge all images and annotations to final directory
Write-Host "=== Step 6: Merging to Final Directory ===" -ForegroundColor Cyan
Write-Host ""

# Copy formatted images
foreach ($img in $formattedImages) {
    Copy-Item $img.FullName (Join-Path $finalDir $img.Name) -Force
}

# Copy rotated images
foreach ($img in $rotatedImages) {
    Copy-Item $img.FullName (Join-Path $finalDir $img.Name) -Force
}

# Copy black background images
$blackBgImages = Get-ChildItem -Path $blackBgDir -Filter "*.png" -File
foreach ($img in $blackBgImages) {
    $newName = $img.Name -replace '^starting_', 'processed_'
    Copy-Item $img.FullName (Join-Path $finalDir $newName) -Force
}

# Copy all annotations
$allLabelDirs = @($RawLabelsDir, $rotatedLabelsDir, $blackBgLabelsDir)
foreach ($labelDir in $allLabelDirs) {
    if (Test-Path $labelDir) {
        $labels = Get-ChildItem -Path $labelDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
        foreach ($label in $labels) {
            $newName = $label.Name -replace '^starting_', ''
            Copy-Item $label.FullName (Join-Path $finalLabelsDir $newName) -Force
        }
    }
}

# Final summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$finalImageCount = (Get-ChildItem -Path $finalDir -Filter "*.png" -File).Count
$finalLabelCount = (Get-ChildItem -Path $finalLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count

Write-Host "  Original images: $($pngFiles.Count)" -ForegroundColor Green
Write-Host "  Final images: $finalImageCount" -ForegroundColor Green
Write-Host "  Final annotations: $finalLabelCount" -ForegroundColor Green
Write-Host "  Augmentation multiplier: $([math]::Round($finalImageCount / $pngFiles.Count, 2))x" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Augmentation pipeline complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Output location: $finalDir" -ForegroundColor Yellow
Write-Host "Annotations location: $finalLabelsDir" -ForegroundColor Yellow
Write-Host ""

