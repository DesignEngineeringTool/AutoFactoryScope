# Commit and Push ONNX Model
# ===========================
# Quick script to commit and push the ONNX model for Rinesh

$ErrorActionPreference = "Stop"

Write-Host "=== Commit and Push ONNX Model ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "models/onnx/robot_detection.onnx")) {
    Write-Error "ONNX model not found! Run export first: pwsh scripts/export-and-share-onnx.ps1"
    exit 1
}

$size = [math]::Round((Get-Item "models/onnx/robot_detection.onnx").Length / 1MB, 2)
Write-Host "ONNX Model: models/onnx/robot_detection.onnx ($size MB)" -ForegroundColor Green
Write-Host ""

# Add files
Write-Host "Adding files to git..." -ForegroundColor Cyan
git add models/onnx/robot_detection.onnx
git add docs/YOLO_MODULE_LOCATIONS.md
git add RINESH_ONNX_READY.md -ErrorAction SilentlyContinue

# Commit
Write-Host "Committing..." -ForegroundColor Cyan
git commit -m "Add ONNX model export - ready for Rinesh

- Exported trained YOLOv8 model to ONNX format
- Model location: models/onnx/robot_detection.onnx
- Size: $size MB
- Ready for C# integration"

# Push
Write-Host "Pushing to remote..." -ForegroundColor Cyan
git push

Write-Host ""
Write-Host "✅ ONNX model pushed to git!" -ForegroundColor Green
Write-Host ""
Write-Host "Rinesh can now:" -ForegroundColor Cyan
Write-Host "  1. git pull" -ForegroundColor Gray
Write-Host "  2. Test: dotnet run --project src/AutoFactoryScope.CLI -- --image `"data/test/images/Robotfloor1.png`" --model `"models/onnx/robot_detection.onnx`"" -ForegroundColor Gray
Write-Host ""

