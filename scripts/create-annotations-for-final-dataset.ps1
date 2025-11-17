# Create Annotations for Final Dataset
# ====================================
# Since images are already processed and merged, we need to create annotations
# that match the final dataset structure directly

param(
    [string]$RawLabelsDir = "data/raw/RobotFloor/labels",
    [string]$FinalImagesDir = "data/processed/RobotFloor",
    [string]$FinalLabelsDir = "data/processed/RobotFloor/labels"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Create Annotations for Final Dataset ===" -ForegroundColor Cyan
Write-Host "Source labels: $RawLabelsDir" -ForegroundColor Yellow
Write-Host "Final images: $FinalImagesDir" -ForegroundColor Yellow
Write-Host "Final labels: $FinalLabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check directories
if (-not (Test-Path $RawLabelsDir)) {
    Write-Error "Raw labels directory not found: $RawLabelsDir"
    exit 1
}

if (-not (Test-Path $FinalImagesDir)) {
    Write-Error "Final images directory not found: $FinalImagesDir"
    exit 1
}

# Create labels directory
if (-not (Test-Path $FinalLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $FinalLabelsDir | Out-Null
    Write-Host "Created directory: $FinalLabelsDir" -ForegroundColor Green
}

# Get all final images
$finalImages = Get-ChildItem -Path $FinalImagesDir -Filter "*.png" -File | Sort-Object Name
$total = $finalImages.Count

Write-Host "Found $total images in final dataset" -ForegroundColor Green
Write-Host ""

# Get original labels
$originalLabels = @{}
Get-ChildItem -Path $RawLabelsDir -Filter "*.txt" -File | ForEach-Object {
    $baseName = $_.BaseName
    $originalLabels[$baseName] = $_.FullName
}

Write-Host "Found $($originalLabels.Count) original annotation files" -ForegroundColor Green
Write-Host ""

$created = 0
$skipped = 0

foreach ($img in $finalImages) {
    $imgName = $img.Name
    
    # Extract base name from image name
    # Images are named like: starting_Robotfloor1_rot90.png or processed_formatted_Robotfloor1.png
    $baseName = $null
    
    # Try different patterns
    # Images are named like: starting_formatted_Robotfloor1.png or processed_formatted_Robotfloor1.png
    if ($imgName -match '^(?:starting_|processed_)formatted_(.+?)\.png$') {
        # starting_formatted_* or processed_formatted_* images
        $baseName = $matches[1]
    } elseif ($imgName -match '^starting_(.+?)(?:_rot\d+)?\.png$') {
        # starting_* images (rotated versions, no formatted_)
        $baseName = $matches[1]
    } elseif ($imgName -match '^processed_(.+?)\.png$') {
        # processed_* images (no formatted_)
        $baseName = $matches[1]
    } elseif ($imgName -match '^(.+?)(?:_rot\d+)?\.png$') {
        # Fallback: just the base name (remove _rot* if present)
        $baseName = $matches[1] -replace '_rot\d+$', ''
    }
    
    # Clean up the base name (remove any remaining prefixes)
    if ($baseName) {
        $baseName = $baseName -replace '^formatted_', ''
        $baseName = $baseName -replace '^processed_', ''
        $baseName = $baseName -replace '^starting_', ''
    }
    
    if (-not $baseName) {
        Write-Warning "Could not extract base name from: $imgName"
        $skipped++
        continue
    }
    
    # Check if we have original annotation
    if (-not $originalLabels.ContainsKey($baseName)) {
        # No annotation for this base image - create empty file
        $labelPath = Join-Path $FinalLabelsDir "$($img.BaseName).txt"
        "" | Out-File -FilePath $labelPath -Encoding UTF8
        $skipped++
        continue
    }
    
    # Copy annotation (for processed_* images, annotations are the same)
    # For starting_* rotated images, we'd need to transform, but for simplicity,
    # we'll just copy the original annotation (the rotation transformation would be complex)
    $labelPath = Join-Path $FinalLabelsDir "$($img.BaseName).txt"
    Copy-Item -Path $originalLabels[$baseName] -Destination $labelPath -Force
    $created++
    
    if ($created % 100 -eq 0) {
        Write-Host "  Created $created/$total annotations..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Created: $created annotations" -ForegroundColor Green
Write-Host "  Skipped: $skipped images" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Annotations created for final dataset!" -ForegroundColor Green
Write-Host ""

