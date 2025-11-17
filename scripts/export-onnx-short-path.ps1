# Export ONNX with Short Path Workaround
# =======================================
# This script exports ONNX using the short path installation

$ErrorActionPreference = "Stop"

Write-Host "=== Export ONNX Model (Short Path) ===" -ForegroundColor Cyan
Write-Host ""

# Set up short path
$shortPath = "C:\packages"
if (Test-Path $shortPath) {
    $env:PYTHONPATH = "$shortPath;$env:PYTHONPATH"
    Write-Host "Using ONNX from: $shortPath" -ForegroundColor Green
} else {
    Write-Host "Short path not found. Run: pwsh scripts/fix-onnx-install.ps1" -ForegroundColor Yellow
    exit 1
}

# Verify ONNX is available
Write-Host "Checking ONNX installation..." -ForegroundColor Cyan
python -c "import onnx; print(f'✅ ONNX version: {onnx.__version__}')" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ONNX not found. Installing..." -ForegroundColor Red
    & pwsh scripts/fix-onnx-install.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install ONNX"
        exit 1
    }
    $env:PYTHONPATH = "$shortPath;$env:PYTHONPATH"
}

Write-Host ""
Write-Host "Exporting model to ONNX..." -ForegroundColor Cyan
Write-Host ""

# Run export
python export_onnx.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ONNX export complete!" -ForegroundColor Green
    
    # Copy to models directory
    if (Test-Path "runs/detect/robot_detection/weights/best.onnx") {
        if (-not (Test-Path "models/onnx")) {
            New-Item -ItemType Directory -Force -Path "models/onnx" | Out-Null
        }
        Copy-Item "runs/detect/robot_detection/weights/best.onnx" "models/onnx/robot_detection.onnx" -Force
        $size = [math]::Round((Get-Item "models/onnx/robot_detection.onnx").Length / 1MB, 2)
        Write-Host "✅ Copied to: models/onnx/robot_detection.onnx ($size MB)" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "❌ Export failed. Check error messages above." -ForegroundColor Red
}

Write-Host ""

