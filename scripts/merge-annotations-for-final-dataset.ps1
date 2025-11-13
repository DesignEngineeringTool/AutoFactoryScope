# Merge Annotations for Final Dataset
# ====================================
# After transforming annotations for rotations and copying for black background,
# we need to merge them to match the final dataset structure in RobotFloor/
#
# The final dataset has:
# - starting_* files (from rotated images)
# - processed_* files (from black background images)

param(
    [string]$Source1LabelsDir = "data/processed/labels",
    [string]$Source2LabelsDir = "data/processed/all_black_bg/labels",
    [string]$DestImagesDir = "data/processed/RobotFloor",
    [string]$DestLabelsDir = "data/processed/RobotFloor/labels",
    [string]$Prefix1 = "starting_",
    [string]$Prefix2 = "processed_"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Merge Annotations for Final Dataset ===" -ForegroundColor Cyan
Write-Host "Source 1 (rotated): $Source1LabelsDir" -ForegroundColor Yellow
Write-Host "Source 2 (black BG): $Source2LabelsDir" -ForegroundColor Yellow
Write-Host "Destination: $DestLabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check source directories
if (-not (Test-Path $Source1LabelsDir)) {
    Write-Error "Source 1 labels directory not found: $Source1LabelsDir"
    Write-Host "Please run transform-annotations-for-rotation.ps1 first!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Source2LabelsDir)) {
    Write-Error "Source 2 labels directory not found: $Source2LabelsDir"
    Write-Host "Please run copy-annotations-for-black-bg.ps1 first!" -ForegroundColor Red
    exit 1
}

# Check destination images directory
if (-not (Test-Path $DestImagesDir)) {
    Write-Error "Destination images directory not found: $DestImagesDir"
    exit 1
}

# Create destination labels directory
if (-not (Test-Path $DestLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $DestLabelsDir | Out-Null
    Write-Host "Created directory: $DestLabelsDir" -ForegroundColor Green
}

# Get all images in final dataset
$finalImages = Get-ChildItem -Path $DestImagesDir -Filter "*.png" -File | Sort-Object Name
$total = $finalImages.Count

if ($total -eq 0) {
    Write-Error "No images found in $DestImagesDir"
    exit 1
}

Write-Host "Found $total images in final dataset" -ForegroundColor Green
Write-Host ""

$copied1 = 0
$copied2 = 0
$missing = 0

foreach ($img in $finalImages) {
    $imgName = $img.Name
    
    # Determine which source to use based on prefix
    if ($imgName.StartsWith($Prefix1)) {
        # From source 1 (rotated images)
        $sourceLabelName = $imgName.Substring($Prefix1.Length) -replace '\.png$', '.txt'
        $sourceLabelPath = Join-Path $Source1LabelsDir $sourceLabelName
        $destLabelPath = Join-Path $DestLabelsDir ($imgName -replace '\.png$', '.txt')
        
        if (Test-Path $sourceLabelPath) {
            Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
            $copied1++
        } else {
            Write-Warning "Missing annotation for $imgName (expected: $sourceLabelName)"
            $missing++
        }
    }
    elseif ($imgName.StartsWith($Prefix2)) {
        # From source 2 (black background images)
        $sourceLabelName = $imgName.Substring($Prefix2.Length) -replace '\.png$', '.txt'
        $sourceLabelPath = Join-Path $Source2LabelsDir $sourceLabelName
        $destLabelPath = Join-Path $DestLabelsDir ($imgName -replace '\.png$', '.txt')
        
        if (Test-Path $sourceLabelPath) {
            Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
            $copied2++
        } else {
            Write-Warning "Missing annotation for $imgName (expected: $sourceLabelName)"
            $missing++
        }
    }
    else {
        Write-Warning "Image $imgName doesn't match expected prefix pattern"
        $missing++
    }
    
    if (($copied1 + $copied2) % 100 -eq 0 -and ($copied1 + $copied2) -gt 0) {
        Write-Host "  Processed $($copied1 + $copied2)/$total..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total images: $total" -ForegroundColor Yellow
Write-Host "  From source 1 (rotated): $copied1" -ForegroundColor Green
Write-Host "  From source 2 (black BG): $copied2" -ForegroundColor Green
Write-Host "  Missing annotations: $missing" -ForegroundColor $(if ($missing -eq 0) { "Green" } else { "Red" })
Write-Host "  Total annotations: $($copied1 + $copied2)" -ForegroundColor $(if (($copied1 + $copied2) -eq $total) { "Green" } else { "Yellow" })
Write-Host ""

if (($copied1 + $copied2) -eq $total -and $missing -eq 0) {
    Write-Host "✅ All annotations merged successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Verify and split dataset" -ForegroundColor Cyan
    Write-Host "Run: pwsh scripts/verify-annotations.ps1 -ImagesDir `"$DestImagesDir`" -LabelsDir `"$DestLabelsDir`"" -ForegroundColor Yellow
} else {
    Write-Warning "Some annotations may be missing. Please check."
}

