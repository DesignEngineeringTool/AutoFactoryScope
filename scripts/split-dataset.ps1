# Split Dataset Script
# Splits processed images into training, validation, and test sets
# This is Step 1 in the ML training pipeline

param(
    [string]$SourceDir = "data/processed/RobotFloor",
    [string]$SourceLabelsDir = "data/processed/RobotFloor/labels",
    [string]$TrainingDir = "data/training/images",
    [string]$TrainingLabelsDir = "data/training/labels",
    [string]$ValidationDir = "data/validation/images",
    [string]$ValidationLabelsDir = "data/validation/labels",
    [string]$TestDir = "data/test/images",
    [string]$TestLabelsDir = "data/test/labels",
    [double]$TrainingPercent = 0.70,  # 70% for training
    [double]$ValidationPercent = 0.20,  # 20% for validation
    [double]$TestPercent = 0.10         # 10% for test
)

$ErrorActionPreference = "Stop"

Write-Host "=== Split Dataset ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host ""

# Check source directory exists
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    Write-Host "Please ensure images are processed first." -ForegroundColor Red
    exit 1
}

# Get all PNG images
$images = Get-ChildItem -Path $SourceDir -Filter "*.png" -File | Sort-Object Name
$total = $images.Count

if ($total -eq 0) {
    Write-Error "No PNG images found in $SourceDir"
    exit 1
}

Write-Host "Found $total images" -ForegroundColor Green
Write-Host ""

# Calculate split counts
$trainCount = [math]::Floor($total * $TrainingPercent)
$valCount = [math]::Floor($total * $ValidationPercent)
$testCount = $total - $trainCount - $valCount

Write-Host "Split plan:" -ForegroundColor Cyan
Write-Host "  Training:   $trainCount images ($([math]::Round($TrainingPercent * 100))%)" -ForegroundColor Yellow
Write-Host "  Validation: $valCount images ($([math]::Round($ValidationPercent * 100))%)" -ForegroundColor Yellow
Write-Host "  Test:       $testCount images ($([math]::Round($testCount / $total * 100, 1))%)" -ForegroundColor Yellow
Write-Host ""

# Create output directories
Write-Host "Creating output directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $TrainingDir | Out-Null
New-Item -ItemType Directory -Force -Path $ValidationDir | Out-Null
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
New-Item -ItemType Directory -Force -Path $TrainingLabelsDir | Out-Null
New-Item -ItemType Directory -Force -Path $ValidationLabelsDir | Out-Null
New-Item -ItemType Directory -Force -Path $TestLabelsDir | Out-Null
Write-Host "  Created: $TrainingDir" -ForegroundColor Green
Write-Host "  Created: $ValidationDir" -ForegroundColor Green
Write-Host "  Created: $TestDir" -ForegroundColor Green
Write-Host "  Created: $TrainingLabelsDir" -ForegroundColor Green
Write-Host "  Created: $ValidationLabelsDir" -ForegroundColor Green
Write-Host "  Created: $TestLabelsDir" -ForegroundColor Green
Write-Host ""

# Check if labels exist
$hasLabels = (Test-Path $SourceLabelsDir) -and ((Get-ChildItem -Path $SourceLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count -gt 0)

if ($hasLabels) {
    Write-Host "Found labels directory, will copy annotations too" -ForegroundColor Green
    Write-Host ""
}

# Copy images and labels to training set
Write-Host "Copying training images..." -ForegroundColor Cyan
$copied = 0
for ($i = 0; $i -lt $trainCount; $i++) {
    $img = $images[$i]
    $destImgPath = Join-Path $TrainingDir $img.Name
    Copy-Item -Path $img.FullName -Destination $destImgPath -Force
    
    # Copy corresponding label if it exists
    if ($hasLabels) {
        $labelName = $img.Name -replace '\.png$', '.txt'
        $sourceLabelPath = Join-Path $SourceLabelsDir $labelName
        if (Test-Path $sourceLabelPath) {
            $destLabelPath = Join-Path $TrainingLabelsDir $labelName
            Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
        }
    }
    
    $copied++
    if ($copied % 100 -eq 0) {
        Write-Host "  Copied $copied/$trainCount..." -ForegroundColor Gray
    }
}
Write-Host "  Training: $copied images copied" -ForegroundColor Green

# Copy images and labels to validation set
Write-Host "Copying validation images..." -ForegroundColor Cyan
$copied = 0
for ($i = $trainCount; $i -lt ($trainCount + $valCount); $i++) {
    $img = $images[$i]
    $destImgPath = Join-Path $ValidationDir $img.Name
    Copy-Item -Path $img.FullName -Destination $destImgPath -Force
    
    # Copy corresponding label if it exists
    if ($hasLabels) {
        $labelName = $img.Name -replace '\.png$', '.txt'
        $sourceLabelPath = Join-Path $SourceLabelsDir $labelName
        if (Test-Path $sourceLabelPath) {
            $destLabelPath = Join-Path $ValidationLabelsDir $labelName
            Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
        }
    }
    
    $copied++
    if ($copied % 50 -eq 0) {
        Write-Host "  Copied $copied/$valCount..." -ForegroundColor Gray
    }
}
Write-Host "  Validation: $copied images copied" -ForegroundColor Green

# Copy images and labels to test set
Write-Host "Copying test images..." -ForegroundColor Cyan
$copied = 0
for ($i = ($trainCount + $valCount); $i -lt $total; $i++) {
    $img = $images[$i]
    $destImgPath = Join-Path $TestDir $img.Name
    Copy-Item -Path $img.FullName -Destination $destImgPath -Force
    
    # Copy corresponding label if it exists
    if ($hasLabels) {
        $labelName = $img.Name -replace '\.png$', '.txt'
        $sourceLabelPath = Join-Path $SourceLabelsDir $labelName
        if (Test-Path $sourceLabelPath) {
            $destLabelPath = Join-Path $TestLabelsDir $labelName
            Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
        }
    }
    
    $copied++
    if ($copied % 20 -eq 0) {
        Write-Host "  Copied $copied/$testCount..." -ForegroundColor Gray
    }
}
Write-Host "  Test: $copied images copied" -ForegroundColor Green

# Verify
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
$trainActual = (Get-ChildItem -Path $TrainingDir -Filter "*.png" -File).Count
$valActual = (Get-ChildItem -Path $ValidationDir -Filter "*.png" -File).Count
$testActual = (Get-ChildItem -Path $TestDir -Filter "*.png" -File).Count

Write-Host "  Training:   $trainActual images" -ForegroundColor $(if ($trainActual -eq $trainCount) { "Green" } else { "Red" })
Write-Host "  Validation: $valActual images" -ForegroundColor $(if ($valActual -eq $valCount) { "Green" } else { "Red" })
Write-Host "  Test:       $testActual images" -ForegroundColor $(if ($testActual -eq $testCount) { "Green" } else { "Red" })
Write-Host "  Total:      $($trainActual + $valActual + $testActual) images" -ForegroundColor $(if (($trainActual + $valActual + $testActual) -eq $total) { "Green" } else { "Red" })
Write-Host ""

if (($trainActual + $valActual + $testActual) -eq $total) {
    Write-Host "✅ Dataset split completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    if ($hasLabels) {
        $trainLabels = (Get-ChildItem -Path $TrainingLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count
        $valLabels = (Get-ChildItem -Path $ValidationLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count
        $testLabels = (Get-ChildItem -Path $TestLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count
        
        Write-Host "Labels copied:" -ForegroundColor Cyan
        Write-Host "  Training labels:   $trainLabels" -ForegroundColor $(if ($trainLabels -eq $trainCount) { "Green" } else { "Yellow" })
        Write-Host "  Validation labels: $valLabels" -ForegroundColor $(if ($valLabels -eq $valCount) { "Green" } else { "Yellow" })
        Write-Host "  Test labels:       $testLabels" -ForegroundColor $(if ($testLabels -eq $testCount) { "Green" } else { "Yellow" })
        Write-Host ""
        Write-Host "Next step: Train the model" -ForegroundColor Cyan
        Write-Host "  python train_robot_model.py" -ForegroundColor Yellow
    } else {
        Write-Host "Next step: Annotate images in data/training/images/" -ForegroundColor Cyan
        Write-Host "See docs/BEGINNER_GUIDE.md for annotation instructions" -ForegroundColor Yellow
    }
} else {
    Write-Warning "Some images may be missing. Please check the directories."
}

