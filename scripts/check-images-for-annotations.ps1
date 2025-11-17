# Check Images for Embedded Annotations
# =====================================
# This script checks if images contain visible annotations, labels, or bounding boxes
# that might need to be extracted or converted to YOLO format

param(
    [string]$ImagesDir = "C:\Users\georgem\source\repos\AutoFactoryScope_data\Robotfloor jpg\Robotfloor jpg"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Images for Annotations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checking: $ImagesDir" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $ImagesDir)) {
    Write-Error "Directory not found: $ImagesDir"
    exit 1
}

$images = Get-ChildItem -Path $ImagesDir -Filter "*.jpg" -File | Select-Object -First 5
$totalImages = (Get-ChildItem -Path $ImagesDir -Filter "*.jpg" -File).Count

Write-Host "Found $totalImages images. Checking first 5 as samples..." -ForegroundColor Green
Write-Host ""

foreach ($img in $images) {
    Write-Host "=== $($img.Name) ===" -ForegroundColor Cyan
    Write-Host "  Size: $($img.Length) bytes" -ForegroundColor Gray
    Write-Host "  Path: $($img.FullName)" -ForegroundColor Gray
    
    # Try to get image dimensions using Python
    try {
        $pythonCmd = @"
from PIL import Image
import sys
img = Image.open(r'$($img.FullName)')
print(f"{img.size[0]},{img.size[1]}")
"@
        $dimensions = python -c $pythonCmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            $width, $height = $dimensions -split ','
            Write-Host "  Dimensions: ${width}x${height}" -ForegroundColor Green
        }
    } catch {
        Write-Host "  (Could not read dimensions)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If your images contain:" -ForegroundColor Yellow
Write-Host "  ✅ Visible 'Robot' labels or text" -ForegroundColor Green
Write-Host "  ✅ Bounding boxes drawn on images" -ForegroundColor Green
Write-Host "  ✅ Annotations visible in the image itself" -ForegroundColor Green
Write-Host ""
Write-Host "Then we need to:" -ForegroundColor Cyan
Write-Host "  1. Extract the bounding box coordinates" -ForegroundColor Yellow
Write-Host "  2. Convert them to YOLO format (.txt files)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Would you like me to:" -ForegroundColor Cyan
Write-Host "  A) Create a script to extract annotations from images?" -ForegroundColor White
Write-Host "  B) Help you manually annotate the images?" -ForegroundColor White
Write-Host "  C) Check if annotations exist elsewhere?" -ForegroundColor White
Write-Host ""

