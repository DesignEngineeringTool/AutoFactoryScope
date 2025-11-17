# Quick Test Script for Rinesh
# ==============================
# This script runs the CLI with a test image

param(
    [string]$Image = "",
    [string]$Model = "models/onnx/robot_detection.onnx"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Test Robot Detection Model ===" -ForegroundColor Cyan
Write-Host ""

# Find a test image if not provided
if ([string]::IsNullOrEmpty($Image)) {
    $testImages = Get-ChildItem "data/test/images" -Filter "*.png" -ErrorAction SilentlyContinue
    if ($testImages.Count -gt 0) {
        $Image = $testImages[0].FullName
        Write-Host "Using test image: $($testImages[0].Name)" -ForegroundColor Green
    } else {
        Write-Error "No test images found in data/test/images/"
        Write-Host "Please provide an image: --Image `"path/to/image.png`"" -ForegroundColor Yellow
        exit 1
    }
}

# Check files exist
if (-not (Test-Path $Image)) {
    Write-Error "Image not found: $Image"
    exit 1
}

if (-not (Test-Path $Model)) {
    Write-Error "Model not found: $Model"
    Write-Host "Make sure you've pulled the latest code: git pull" -ForegroundColor Yellow
    exit 1
}

Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host "Image: $Image" -ForegroundColor Yellow
Write-Host ""

# Run the CLI
Write-Host "Running detection..." -ForegroundColor Cyan
Write-Host ""

dotnet run --project src/AutoFactoryScope.CLI -- `
  --image $Image `
  --model $Model

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Detection complete! Check result.json for details." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Detection failed. Check error messages above." -ForegroundColor Red
}

