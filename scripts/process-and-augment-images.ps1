# Image Processing and Augmentation Script
# Processes images from data/raw and creates augmented versions with rotations

param(
    [string]$SourceDir = "data/raw",
    [string]$OutputDir = "data/processed",
    [int[]]$RotationAngles = @(90, 180, 270, 15, 30, 45, 60, 75, 105, 120, 135, 150, 165, 195, 210, 225, 240, 255, 285, 300, 315, 330, 345),
    [switch]$FormatOnly = $false,
    [switch]$AugmentOnly = $false
)

$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Drawing

function Get-ImageInfo {
    param([string]$ImagePath)
    
    try {
        $img = [System.Drawing.Image]::FromFile($ImagePath)
        $info = @{
            Path = $ImagePath
            Name = Split-Path -Leaf $ImagePath
            Width = $img.Width
            Height = $img.Height
            PixelFormat = $img.PixelFormat.ToString()
            HorizontalResolution = [math]::Round($img.HorizontalResolution, 2)
            VerticalResolution = [math]::Round($img.VerticalResolution, 2)
        }
        $img.Dispose()
        return $info
    }
    catch {
        Write-Warning "Failed to read image: $ImagePath - $_"
        return $null
    }
}

function Format-Image {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$TargetSize = 640
    )
    
    # Use ImageSharp via dotnet CLI or create a simple C# tool
    # For now, we'll use a PowerShell approach with System.Drawing
    try {
        $img = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Calculate new dimensions maintaining aspect ratio
        $aspectRatio = $img.Width / $img.Height
        $newWidth = if ($aspectRatio > 1) { $TargetSize } else { [int]($TargetSize * $aspectRatio) }
        $newHeight = if ($aspectRatio > 1) { [int]($TargetSize / $aspectRatio) } else { $TargetSize }
        
        # Create new bitmap with target size and black background
        $formatted = New-Object System.Drawing.Bitmap($TargetSize, $TargetSize)
        $graphics = [System.Drawing.Graphics]::FromImage($formatted)
        $graphics.Clear([System.Drawing.Color]::Black)
        
        # Calculate centering position
        $x = ($TargetSize - $newWidth) / 2
        $y = ($TargetSize - $newHeight) / 2
        
        # Draw resized image centered
        $graphics.DrawImage($img, $x, $y, $newWidth, $newHeight)
        $graphics.Dispose()
        
        # Save as PNG
        $formatted.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $img.Dispose()
        $formatted.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to format image $SourcePath : $_"
        return $false
    }
}

function Rotate-Image {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [float]$Angle
    )
    
    try {
        $img = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Calculate new dimensions for rotated image
        $radians = $Angle * [math]::PI / 180
        $cos = [math]::Abs([math]::Cos($radians))
        $sin = [math]::Abs([math]::Sin($radians))
        $newWidth = [int]($img.Width * $cos + $img.Height * $sin)
        $newHeight = [int]($img.Width * $sin + $img.Height * $cos)
        
        # Create bitmap for rotated image
        $rotated = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($rotated)
        $graphics.Clear([System.Drawing.Color]::Black)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        
        # Translate to center, rotate, translate back
        $graphics.TranslateTransform($newWidth / 2, $newHeight / 2)
        $graphics.RotateTransform($Angle)
        $graphics.TranslateTransform(-$img.Width / 2, -$img.Height / 2)
        
        # Draw rotated image
        $graphics.DrawImage($img, 0, 0)
        $graphics.Dispose()
        
        # Save rotated image
        $rotated.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $img.Dispose()
        $rotated.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to rotate image $SourcePath by $Angle degrees: $_"
        return $false
    }
}

# Main script
Write-Host "=== Image Processing and Augmentation ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host "Output: $OutputDir" -ForegroundColor Yellow
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

# Get all PNG images
$images = Get-ChildItem -Path $SourceDir -Filter "*.png" | Sort-Object Name

if ($images.Count -eq 0) {
    Write-Warning "No PNG images found in $SourceDir"
    exit 1
}

Write-Host "Found $($images.Count) images" -ForegroundColor Green
Write-Host ""

# Step 1: Review and format images
if (-not $AugmentOnly) {
    Write-Host "=== Step 1: Reviewing Images ===" -ForegroundColor Cyan
    
    $imageInfo = @()
    foreach ($img in $images) {
        $info = Get-ImageInfo $img.FullName
        if ($info) {
            $imageInfo += $info
            Write-Host "  $($info.Name): $($info.Width)x$($info.Height) ($($info.PixelFormat))" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    if ($imageInfo.Count -gt 0) {
        $widths = $imageInfo | ForEach-Object { $_.Width }
        $heights = $imageInfo | ForEach-Object { $_.Height }
        $minWidth = ($widths | Measure-Object -Minimum).Minimum
        $maxWidth = ($widths | Measure-Object -Maximum).Maximum
        $minHeight = ($heights | Measure-Object -Minimum).Minimum
        $maxHeight = ($heights | Measure-Object -Maximum).Maximum
        Write-Host "  Dimensions: ${minWidth}x${minHeight} to ${maxWidth}x${maxHeight}"
    }
    Write-Host "  Total images: $($imageInfo.Count)"
    Write-Host ""
    
    if (-not $FormatOnly) {
        Write-Host "=== Step 2: Formatting Images (640x640) ===" -ForegroundColor Cyan
        $formattedCount = 0
        foreach ($img in $images) {
            $outputPath = Join-Path $OutputDir "formatted_$($img.Name)"
            if (Format-Image -SourcePath $img.FullName -OutputPath $outputPath) {
                $formattedCount++
                Write-Host "  Formatted: $($img.Name)" -ForegroundColor Gray
            }
        }
        Write-Host "Formatted $formattedCount images" -ForegroundColor Green
        Write-Host ""
    }
}

# Step 3: Create augmented versions with rotations
if (-not $FormatOnly) {
    Write-Host "=== Step 3: Creating Augmented Images (Rotations) ===" -ForegroundColor Cyan
    Write-Host "Rotation angles: $($RotationAngles -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    
    $augmentedCount = 0
    $sourceImages = if ($FormatOnly) { 
        Get-ChildItem -Path $SourceDir -Filter "*.png" 
    } else { 
        Get-ChildItem -Path $OutputDir -Filter "formatted_*.png" 
    }
    
    if ($sourceImages.Count -eq 0) {
        Write-Warning "No source images found for augmentation"
        exit 1
    }
    
    foreach ($img in $sourceImages) {
        $baseName = if ($img.Name.StartsWith("formatted_")) {
            $img.Name.Substring(10) -replace '\.png$', ''
        } else {
            $img.Name -replace '\.png$', ''
        }
        
        foreach ($angle in $RotationAngles) {
            $outputName = "${baseName}_rot${angle}.png"
            $outputPath = Join-Path $OutputDir $outputName
            
            if (Rotate-Image -SourcePath $img.FullName -OutputPath $outputPath -Angle $angle) {
                $augmentedCount++
                if ($augmentedCount % 10 -eq 0) {
                    Write-Host "  Processed $augmentedCount augmented images..." -ForegroundColor Gray
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "Created $augmentedCount augmented images" -ForegroundColor Green
    Write-Host ""
}

# Final summary
$totalImages = (Get-ChildItem -Path $OutputDir -Filter "*.png").Count
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Original images: $($images.Count)"
Write-Host "  Total output images: $totalImages"
Write-Host "  Augmentation multiplier: $([math]::Round($totalImages / $images.Count, 2))x" -ForegroundColor Green
Write-Host ""
Write-Host "Done! Output saved to: $OutputDir" -ForegroundColor Green

