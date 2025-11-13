# Transform Annotations for Rotated Images
# ==========================================
# When you rotate an image, the bounding box coordinates need to be rotated too.
# This script takes annotations from original images and creates annotations
# for all rotated versions.
#
# Strategy:
# 1. Annotate only the 36 original images
# 2. Run this script to generate annotations for all rotated versions
# 3. Rotations preserve the relative positions, just need coordinate transformation

param(
    [string]$OriginalImagesDir = "data/raw",
    [string]$OriginalLabelsDir = "data/raw/labels",
    [string]$RotatedImagesDir = "data/processed",
    [string]$RotatedLabelsDir = "data/processed/labels",
    [int[]]$RotationAngles = @(90, 180, 270, 15, 30, 45, 60, 75, 105, 120, 135, 150, 165, 195, 210, 225, 240, 255, 285, 300, 315, 330, 345)
)

$ErrorActionPreference = "Stop"

# Load required assemblies for image dimensions
Add-Type -AssemblyName System.Drawing

Write-Host "=== Transform Annotations for Rotated Images ===" -ForegroundColor Cyan
Write-Host "Original images: $OriginalImagesDir" -ForegroundColor Yellow
Write-Host "Original labels: $OriginalLabelsDir" -ForegroundColor Yellow
Write-Host "Rotated images: $RotatedImagesDir" -ForegroundColor Yellow
Write-Host "Rotated labels: $RotatedLabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check directories
if (-not (Test-Path $OriginalImagesDir)) {
    Write-Error "Original images directory not found: $OriginalImagesDir"
    exit 1
}

if (-not (Test-Path $OriginalLabelsDir)) {
    Write-Error "Original labels directory not found: $OriginalLabelsDir"
    Write-Host "Please annotate the original images first!" -ForegroundColor Red
    exit 1
}

# Create rotated labels directory
if (-not (Test-Path $RotatedLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $RotatedLabelsDir | Out-Null
    Write-Host "Created directory: $RotatedLabelsDir" -ForegroundColor Green
}

# Get original images
$originalImages = Get-ChildItem -Path $OriginalImagesDir -Filter "*.png" -File | Sort-Object Name
$originalCount = $originalImages.Count

if ($originalCount -eq 0) {
    Write-Error "No original images found in $OriginalImagesDir"
    exit 1
}

Write-Host "Found $originalCount original images" -ForegroundColor Green
Write-Host "Rotation angles: $($RotationAngles.Count) angles" -ForegroundColor Green
Write-Host "Expected rotated images: $($originalCount * $RotationAngles.Count)" -ForegroundColor Green
Write-Host ""

# Function to rotate a point around center
function Rotate-Point {
    param(
        [double]$X,      # Normalized x (0-1)
        [double]$Y,      # Normalized y (0-1)
        [double]$Angle,  # Rotation angle in degrees
        [int]$ImgWidth,
        [int]$ImgHeight
    )
    
    # Convert normalized to pixel coordinates (center-based)
    $px = ($X - 0.5) * $ImgWidth
    $py = ($Y - 0.5) * $ImgHeight
    
    # Convert angle to radians
    $rad = $Angle * [math]::PI / 180.0
    $cos = [math]::Cos($rad)
    $sin = [math]::Sin($rad)
    
    # Rotate around center (0,0)
    $newPx = $px * $cos - $py * $sin
    $newPy = $px * $sin + $py * $cos
    
    # Convert back to normalized coordinates
    # Note: After rotation, image may be larger (with padding), so we need to account for that
    # For now, we'll assume the rotated image maintains the same dimensions
    # (The rotation script creates a larger canvas, but we'll work with normalized coords)
    
    $newX = ($newPx / $ImgWidth) + 0.5
    $newY = ($newPy / $ImgHeight) + 0.5
    
    return @{ X = $newX; Y = $newY }
}

# Function to rotate bounding box
# The rotation script creates a larger canvas, so we need to account for that
function Rotate-BoundingBox {
    param(
        [double]$CenterX,      # Normalized (0-1) in original image
        [double]$CenterY,       # Normalized (0-1) in original image
        [double]$Width,         # Normalized (0-1) in original image
        [double]$Height,        # Normalized (0-1) in original image
        [double]$Angle,        # Rotation angle in degrees
        [int]$OrigWidth,        # Original image width (pixels)
        [int]$OrigHeight,       # Original image height (pixels)
        [int]$RotWidth,         # Rotated image width (pixels) - larger canvas
        [int]$RotHeight         # Rotated image height (pixels) - larger canvas
    )
    
    # Convert normalized coordinates to pixel coordinates in original image
    $px = $CenterX * $OrigWidth
    $py = $CenterY * $OrigHeight
    $w = $Width * $OrigWidth
    $h = $Height * $OrigHeight
    
    # Calculate corner points in original image (pixel coordinates)
    $halfW = $w / 2.0
    $halfH = $h / 2.0
    
    $corners = @(
        @{ X = $px - $halfW; Y = $py - $halfH },  # Top-left
        @{ X = $px + $halfW; Y = $py - $halfH },  # Top-right
        @{ X = $px + $halfW; Y = $py + $halfH },  # Bottom-right
        @{ X = $px - $halfW; Y = $py + $halfH }   # Bottom-left
    )
    
    # Rotate script centers image, rotates, then places on larger canvas
    # The original image is centered at (RotWidth/2, RotHeight/2)
    # We need to transform coordinates relative to the rotated canvas center
    
    $rad = $Angle * [math]::PI / 180.0
    $cos = [math]::Cos($rad)
    $sin = [math]::Sin($rad)
    
    # Center of rotation (center of original image, which is at center of rotated canvas)
    $centerX_px = $RotWidth / 2.0
    $centerY_px = $RotHeight / 2.0
    
    # Rotate each corner point
    $rotatedCorners = @()
    foreach ($corner in $corners) {
        # Translate to origin (relative to image center)
        $dx = $corner.X - ($OrigWidth / 2.0)
        $dy = $corner.Y - ($OrigHeight / 2.0)
        
        # Rotate
        $rotDx = $dx * $cos - $dy * $sin
        $rotDy = $dx * $sin + $dy * $cos
        
        # Translate back (to rotated canvas center)
        $rotX = $rotDx + $centerX_px
        $rotY = $rotDy + $centerY_px
        
        $rotatedCorners += @{ X = $rotX; Y = $rotY }
    }
    
    # Find bounding box of rotated corners
    $minX = ($rotatedCorners | Measure-Object -Property X -Minimum).Minimum
    $maxX = ($rotatedCorners | Measure-Object -Property X -Maximum).Maximum
    $minY = ($rotatedCorners | Measure-Object -Property Y -Minimum).Minimum
    $maxY = ($rotatedCorners | Measure-Object -Property Y -Maximum).Maximum
    
    # Calculate new center and size (in rotated image pixels)
    $newCenterX_px = ($minX + $maxX) / 2.0
    $newCenterY_px = ($minY + $maxY) / 2.0
    $newWidth_px = $maxX - $minX
    $newHeight_px = $maxY - $minY
    
    # Normalize to 0-1 range (relative to rotated image size)
    $newCenterX = $newCenterX_px / $RotWidth
    $newCenterY = $newCenterY_px / $RotHeight
    $newWidth = $newWidth_px / $RotWidth
    $newHeight = $newHeight_px / $RotHeight
    
    # Clamp to valid range (0-1)
    $newCenterX = [math]::Max(0, [math]::Min(1, $newCenterX))
    $newCenterY = [math]::Max(0, [math]::Min(1, $newCenterY))
    $newWidth = [math]::Max(0.001, [math]::Min(1, $newWidth))  # Min 0.001 to avoid zero
    $newHeight = [math]::Max(0.001, [math]::Min(1, $newHeight))
    
    return @{
        CenterX = $newCenterX
        CenterY = $newCenterY
        Width = $newWidth
        Height = $newHeight
    }
}

$processed = 0
$skipped = 0
$errors = 0

foreach ($originalImg in $originalImages) {
    $baseName = $originalImg.BaseName  # e.g., "Robotfloor1"
    $labelFile = Join-Path $OriginalLabelsDir "$baseName.txt"
    
    # Check if original annotation exists
    if (-not (Test-Path $labelFile)) {
        Write-Warning "No annotation file for $($originalImg.Name), skipping..."
        $skipped++
        continue
    }
    
    # Get original image dimensions
    try {
        $img = [System.Drawing.Bitmap]::FromFile($originalImg.FullName)
        $origWidth = $img.Width
        $origHeight = $img.Height
        $img.Dispose()
    } catch {
        Write-Warning "Could not read image dimensions for $($originalImg.Name): $_"
        $errors++
        continue
    }
    
    # Read original annotations
    $originalAnnotations = Get-Content $labelFile
    
    # Process each rotation angle
    foreach ($angle in $RotationAngles) {
        $rotatedImageName = "${baseName}_rot${angle}.png"
        $rotatedImagePath = Join-Path $RotatedImagesDir $rotatedImageName
        $rotatedLabelPath = Join-Path $RotatedLabelsDir "${baseName}_rot${angle}.txt"
        
        # Check if rotated image exists
        if (-not (Test-Path $rotatedImagePath)) {
            # Skip if image doesn't exist (might not be created yet)
            continue
        }
        
        # Get rotated image dimensions (may be different due to padding)
        try {
            $rotImg = [System.Drawing.Bitmap]::FromFile($rotatedImagePath)
            $rotWidth = $rotImg.Width
            $rotHeight = $rotImg.Height
            $rotImg.Dispose()
        } catch {
            Write-Warning "Could not read rotated image: $rotatedImagePath"
            $errors++
            continue
        }
        
        # Transform annotations
        $rotatedAnnotations = @()
        foreach ($line in $originalAnnotations) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            
            $parts = $line -split '\s+'
            if ($parts.Count -ne 5) {
                Write-Warning "Invalid annotation line in $labelFile : '$line'"
                continue
            }
            
            $classId = $parts[0]
            $centerX = [double]$parts[1]
            $centerY = [double]$parts[2]
            $width = [double]$parts[3]
            $height = [double]$parts[4]
            
            # Rotate bounding box
            # Pass both original and rotated dimensions to handle canvas size change
            $rotated = Rotate-BoundingBox -CenterX $centerX -CenterY $centerY -Width $width -Height $height `
                                         -Angle $angle -OrigWidth $origWidth -OrigHeight $origHeight `
                                         -RotWidth $rotWidth -RotHeight $rotHeight
            
            # Format: class_id center_x center_y width height
            $rotatedLine = "{0} {1:F6} {2:F6} {3:F6} {4:F6}" -f $classId, $rotated.CenterX, $rotated.CenterY, $rotated.Width, $rotated.Height
            $rotatedAnnotations += $rotatedLine
        }
        
        # Save rotated annotations
        if ($rotatedAnnotations.Count -gt 0) {
            $rotatedAnnotations | Out-File -FilePath $rotatedLabelPath -Encoding UTF8 -NoNewline
            $processed++
        } else {
            Write-Warning "No valid annotations for $rotatedImageName"
        }
    }
    
    if ($processed % 100 -eq 0 -and $processed -gt 0) {
        Write-Host "  Processed $processed rotated annotations..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Processed: $processed rotated annotations" -ForegroundColor Green
Write-Host "  Skipped: $skipped (no original annotations)" -ForegroundColor Yellow
if ($errors -gt 0) {
    Write-Host "  Errors: $errors" -ForegroundColor Red
}
Write-Host ""
Write-Host "✅ Annotation transformation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Copy annotations for black background versions" -ForegroundColor Cyan
Write-Host "Run: pwsh scripts/copy-annotations-for-black-bg.ps1" -ForegroundColor Yellow

