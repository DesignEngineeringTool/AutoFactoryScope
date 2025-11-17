# Export ONNX Model and Prepare for Sharing
# ==========================================
# This script exports the trained model to ONNX and prepares it for sharing with Rinesh

$ErrorActionPreference = "Stop"

Write-Host "=== Export ONNX Model and Share ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Export to ONNX
Write-Host "Step 1: Exporting model to ONNX..." -ForegroundColor Cyan
Write-Host ""

python -c @"
from ultralytics import YOLO
import os

print('Loading best model...')
model = YOLO('runs/detect/robot_detection/weights/best.pt')

print('Exporting to ONNX...')
model.export(
    format='onnx',
    imgsz=640,
    simplify=True,
    opset=12,
    half=False
)

onnx_path = 'runs/detect/robot_detection/weights/best.onnx'
if os.path.exists(onnx_path):
    size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
    print(f'✅ ONNX model exported: {onnx_path}')
    print(f'   Size: {size_mb:.2f} MB')
else:
    print('❌ ONNX export failed!')
    exit(1)
"@

if ($LASTEXITCODE -ne 0) {
    Write-Error "ONNX export failed!"
    exit 1
}

Write-Host ""

# Step 2: Copy to models directory
Write-Host "Step 2: Copying to models directory..." -ForegroundColor Cyan

if (-not (Test-Path "models/onnx")) {
    New-Item -ItemType Directory -Force -Path "models/onnx" | Out-Null
}

$sourceOnnx = "runs/detect/robot_detection/weights/best.onnx"
$targetOnnx = "models/onnx/robot_detection.onnx"

if (Test-Path $sourceOnnx) {
    Copy-Item -Path $sourceOnnx -Destination $targetOnnx -Force
    $size = [math]::Round((Get-Item $targetOnnx).Length / 1MB, 2)
    Write-Host "✅ Copied to: $targetOnnx" -ForegroundColor Green
    Write-Host "   Size: $size MB" -ForegroundColor Yellow
} else {
    Write-Error "Source ONNX file not found: $sourceOnnx"
    exit 1
}

Write-Host ""

# Step 3: Verify file
Write-Host "Step 3: Verifying ONNX file..." -ForegroundColor Cyan

if (Test-Path $targetOnnx) {
    $file = Get-Item $targetOnnx
    Write-Host "✅ ONNX model ready!" -ForegroundColor Green
    Write-Host "   Location: $targetOnnx" -ForegroundColor Gray
    Write-Host "   Size: $([math]::Round($file.Length / 1MB, 2)) MB" -ForegroundColor Gray
} else {
    Write-Error "ONNX file not found at target location!"
    exit 1
}

Write-Host ""
Write-Host "=== Ready to Share ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. git add models/onnx/robot_detection.onnx" -ForegroundColor Gray
Write-Host "  2. git commit -m 'Add ONNX model for Rinesh'" -ForegroundColor Gray
Write-Host "  3. git push" -ForegroundColor Gray
Write-Host ""
Write-Host "Or run: pwsh scripts/commit-and-push-onnx.ps1" -ForegroundColor Cyan
Write-Host ""

