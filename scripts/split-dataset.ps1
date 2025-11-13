# Split Dataset Script
# Splits processed images into training, validation, and test sets
# This is Step 1 in the ML training pipeline

param(
    [string]$SourceDir = "data/processed/RobotFloor",
    [string]$TrainingDir = "data/training/images",
    [string]$ValidationDir = "data/validation/images",
    [string]$TestDir = "data/test/images",
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
Write-Host "  Created: $TrainingDir" -ForegroundColor Green
Write-Host "  Created: $ValidationDir" -ForegroundColor Green
Write-Host "  Created: $TestDir" -ForegroundColor Green
Write-Host ""

# Copy images to training set
Write-Host "Copying training images..." -ForegroundColor Cyan
$copied = 0
for ($i = 0; $i -lt $trainCount; $i++) {
    $destPath = Join-Path $TrainingDir $images[$i].Name
    Copy-Item -Path $images[$i].FullName -Destination $destPath -Force
    $copied++
    if ($copied % 100 -eq 0) {
        Write-Host "  Copied $copied/$trainCount..." -ForegroundColor Gray
    }
}
Write-Host "  Training: $copied images copied" -ForegroundColor Green

# Copy images to validation set
Write-Host "Copying validation images..." -ForegroundColor Cyan
$copied = 0
for ($i = $trainCount; $i -lt ($trainCount + $valCount); $i++) {
    $destPath = Join-Path $ValidationDir $images[$i].Name
    Copy-Item -Path $images[$i].FullName -Destination $destPath -Force
    $copied++
    if ($copied % 50 -eq 0) {
        Write-Host "  Copied $copied/$valCount..." -ForegroundColor Gray
    }
}
Write-Host "  Validation: $copied images copied" -ForegroundColor Green

# Copy images to test set
Write-Host "Copying test images..." -ForegroundColor Cyan
$copied = 0
for ($i = ($trainCount + $valCount); $i -lt $total; $i++) {
    $destPath = Join-Path $TestDir $images[$i].Name
    Copy-Item -Path $images[$i].FullName -Destination $destPath -Force
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
    Write-Host "Next step: Annotate images in data/training/images/" -ForegroundColor Cyan
    Write-Host "See docs/BEGINNER_GUIDE.md for annotation instructions" -ForegroundColor Yellow
} else {
    Write-Warning "Some images may be missing. Please check the directories."
}

