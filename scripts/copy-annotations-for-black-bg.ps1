# Copy Annotations for Black Background Images
# ============================================
# After rotating images and transforming annotations, we also created
# black background versions. These have the same image content, just
# with white backgrounds changed to black.
#
# Since the image content (robots) is the same, the bounding boxes
# are identical - we just need to copy the annotations!

param(
    [string]$SourceLabelsDir = "data/processed/labels",
    [string]$BlackBgLabelsDir = "data/processed/all_black_bg/labels",
    [string]$BlackBgImagesDir = "data/processed/all_black_bg"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Copy Annotations for Black Background Images ===" -ForegroundColor Cyan
Write-Host "Source labels: $SourceLabelsDir" -ForegroundColor Yellow
Write-Host "Black BG images: $BlackBgImagesDir" -ForegroundColor Yellow
Write-Host "Black BG labels: $BlackBgLabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check source directory
if (-not (Test-Path $SourceLabelsDir)) {
    Write-Error "Source labels directory not found: $SourceLabelsDir"
    Write-Host "Please run transform-annotations-for-rotation.ps1 first!" -ForegroundColor Red
    exit 1
}

# Check black background images directory
if (-not (Test-Path $BlackBgImagesDir)) {
    Write-Error "Black background images directory not found: $BlackBgImagesDir"
    Write-Host "Please process images with black background first!" -ForegroundColor Red
    exit 1
}

# Create black background labels directory
if (-not (Test-Path $BlackBgLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $BlackBgLabelsDir | Out-Null
    Write-Host "Created directory: $BlackBgLabelsDir" -ForegroundColor Green
}

# Get all black background images
$blackBgImages = Get-ChildItem -Path $BlackBgImagesDir -Filter "*.png" -File | Sort-Object Name
$total = $blackBgImages.Count

if ($total -eq 0) {
    Write-Error "No black background images found in $BlackBgImagesDir"
    exit 1
}

Write-Host "Found $total black background images" -ForegroundColor Green
Write-Host ""

$copied = 0
$missing = 0
$errors = 0

foreach ($img in $blackBgImages) {
    $labelName = $img.Name -replace '\.png$', '.txt'
    $sourceLabelPath = Join-Path $SourceLabelsDir $labelName
    $destLabelPath = Join-Path $BlackBgLabelsDir $labelName
    
    # Check if source annotation exists
    if (-not (Test-Path $sourceLabelPath)) {
        Write-Warning "No source annotation for $labelName"
        $missing++
        continue
    }
    
    try {
        # Copy annotation file (same content, robots are in same positions)
        Copy-Item -Path $sourceLabelPath -Destination $destLabelPath -Force
        $copied++
        
        if ($copied % 100 -eq 0) {
            Write-Host "  Copied $copied/$total annotations..." -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Error copying $labelName : $_"
        $errors++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total images: $total" -ForegroundColor Yellow
Write-Host "  Annotations copied: $copied" -ForegroundColor Green
Write-Host "  Missing source annotations: $missing" -ForegroundColor $(if ($missing -eq 0) { "Green" } else { "Yellow" })
if ($errors -gt 0) {
    Write-Host "  Errors: $errors" -ForegroundColor Red
}
Write-Host ""

if ($copied -eq $total) {
    Write-Host "✅ All annotations copied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Verify annotations and start training" -ForegroundColor Cyan
    Write-Host "Run: pwsh scripts/verify-annotations.ps1" -ForegroundColor Yellow
} else {
    Write-Warning "Some annotations may be missing. Please check."
}

