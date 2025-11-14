# Setup Annotation Workflow for 36 PNG Files
# ===========================================
# This script prepares the directory structure and guides you through
# annotating the 36 original PNG files in YOLO format.
#
# Usage:
#   pwsh scripts/setup-annotation-workflow.ps1

param(
    [string]$RawImagesDir = "data/raw/RobotFloor",
    [string]$RawLabelsDir = "data/raw/RobotFloor/labels"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Annotation Workflow Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if raw images exist
if (-not (Test-Path $RawImagesDir)) {
    Write-Error "Raw images directory not found: $RawImagesDir"
    exit 1
}

# Get PNG files
$pngFiles = Get-ChildItem -Path $RawImagesDir -Filter "*.png" -File | Sort-Object Name
$pngCount = $pngFiles.Count

if ($pngCount -eq 0) {
    Write-Error "No PNG files found in $RawImagesDir"
    exit 1
}

Write-Host "Found $pngCount PNG files in $RawImagesDir" -ForegroundColor Green
Write-Host ""

# Create labels directory
if (-not (Test-Path $RawLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $RawLabelsDir | Out-Null
    Write-Host "Created labels directory: $RawLabelsDir" -ForegroundColor Green
} else {
    Write-Host "Labels directory exists: $RawLabelsDir" -ForegroundColor Yellow
}

# Check existing annotations
$existingLabels = Get-ChildItem -Path $RawLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
$existingCount = $existingLabels.Count
$missingCount = $pngCount - $existingCount

Write-Host ""
Write-Host "=== Current Status ===" -ForegroundColor Cyan
Write-Host "  Total PNG files: $pngCount" -ForegroundColor Yellow
Write-Host "  Existing annotations: $existingCount" -ForegroundColor $(if ($existingCount -eq $pngCount) { "Green" } else { "Yellow" })
Write-Host "  Missing annotations: $missingCount" -ForegroundColor $(if ($missingCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($existingCount -eq $pngCount) {
    Write-Host "✅ All images already have annotations!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run the complete pipeline" -ForegroundColor Cyan
    Write-Host "  pwsh scripts/complete-annotation-pipeline.ps1" -ForegroundColor Yellow
    exit 0
}

# Show missing annotations
if ($missingCount -gt 0) {
    Write-Host "=== Missing Annotations ===" -ForegroundColor Yellow
    $missingFiles = @()
    foreach ($png in $pngFiles) {
        $labelName = $png.Name -replace '\.png$', '.txt'
        $labelPath = Join-Path $RawLabelsDir $labelName
        if (-not (Test-Path $labelPath)) {
            $missingFiles += $png.Name
        }
    }
    
    if ($missingFiles.Count -le 10) {
        $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    } else {
        $missingFiles[0..9] | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        Write-Host "  ... and $($missingFiles.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host ""
}

# Instructions
Write-Host "=== Annotation Instructions ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need to annotate $missingCount images in YOLO format." -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: LabelImg (Recommended for beginners)" -ForegroundColor Green
Write-Host "  1. Install: pip install labelImg" -ForegroundColor Gray
Write-Host "  2. Run: labelImg" -ForegroundColor Gray
Write-Host "  3. Open directory: $RawImagesDir" -ForegroundColor Gray
Write-Host "  4. Set save directory: $RawLabelsDir" -ForegroundColor Gray
Write-Host "  5. IMPORTANT: Set format to 'YOLO' (not PascalVOC)" -ForegroundColor Yellow
Write-Host "  6. Draw bounding boxes around ALL robots" -ForegroundColor Gray
Write-Host "  7. Save each image (Ctrl+S)" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Pre-annotation with AI (Faster)" -ForegroundColor Green
Write-Host "  1. Install: pip install ultralytics" -ForegroundColor Gray
Write-Host "  2. Run: python scripts/pre-annotate-with-model.py" -ForegroundColor Gray
Write-Host "  3. Review and correct in LabelImg" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Roboflow (Web-based, AI-assisted)" -ForegroundColor Green
Write-Host "  1. Go to: https://roboflow.com" -ForegroundColor Gray
Write-Host "  2. Create project and upload images" -ForegroundColor Gray
Write-Host "  3. Use AI-assisted labeling" -ForegroundColor Gray
Write-Host "  4. Export in YOLO format" -ForegroundColor Gray
Write-Host ""
Write-Host "YOLO Format:" -ForegroundColor Cyan
Write-Host "  Each .txt file contains one line per robot:" -ForegroundColor Gray
Write-Host "  class_id center_x center_y width height" -ForegroundColor Gray
Write-Host "  All values normalized (0.0 to 1.0)" -ForegroundColor Gray
Write-Host "  Example: 0 0.5 0.5 0.1 0.15" -ForegroundColor Gray
Write-Host ""
Write-Host "After annotating, run:" -ForegroundColor Cyan
Write-Host "  pwsh scripts/complete-annotation-pipeline.ps1" -ForegroundColor Yellow
Write-Host ""

# Create a helper script to open LabelImg
$labelImgScript = @"
# Quick LabelImg Launcher
# Run this to open LabelImg with correct directories

`$imagesDir = "$RawImagesDir"
`$labelsDir = "$RawLabelsDir"

Write-Host "Opening LabelImg..." -ForegroundColor Cyan
Write-Host "Images: `$imagesDir" -ForegroundColor Yellow
Write-Host "Labels: `$labelsDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Set format to YOLO!" -ForegroundColor Red
Write-Host ""

# Try to launch LabelImg
try {
    labelImg `$imagesDir `$labelsDir
} catch {
    Write-Error "LabelImg not found. Install with: pip install labelImg"
    Write-Host ""
    Write-Host "Or run manually:" -ForegroundColor Yellow
    Write-Host "  labelImg" -ForegroundColor Gray
    Write-Host "  Then open: `$imagesDir" -ForegroundColor Gray
    Write-Host "  Set save to: `$labelsDir" -ForegroundColor Gray
}
"@

$labelImgScriptPath = "scripts/launch-labelimg.ps1"
$labelImgScript | Out-File -FilePath $labelImgScriptPath -Encoding UTF8
Write-Host "Created helper script: $labelImgScriptPath" -ForegroundColor Green
Write-Host "  Run: pwsh $labelImgScriptPath" -ForegroundColor Yellow
Write-Host ""

exit 0

