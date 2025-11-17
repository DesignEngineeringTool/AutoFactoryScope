# Fix ONNX Installation - Workaround for Windows Path Length Issue
# ================================================================
# This script installs ONNX to a shorter path to avoid Windows 260-character limit

$ErrorActionPreference = "Stop"

Write-Host "=== Fix ONNX Installation ===" -ForegroundColor Cyan
Write-Host ""

# Option 1: Install to shorter custom path
Write-Host "Option 1: Installing ONNX to shorter path..." -ForegroundColor Yellow
Write-Host ""

$shortPath = "C:\packages"
if (-not (Test-Path $shortPath)) {
    New-Item -ItemType Directory -Force -Path $shortPath | Out-Null
    Write-Host "Created directory: $shortPath" -ForegroundColor Green
}

# Set environment variables for this session
$env:PIP_TARGET = $shortPath
$env:PYTHONPATH = "$shortPath;$env:PYTHONPATH"

Write-Host "Installing ONNX to: $shortPath" -ForegroundColor Cyan
pip install onnx onnxslim --target $shortPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ ONNX installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To use it, set PYTHONPATH:" -ForegroundColor Yellow
    Write-Host "  `$env:PYTHONPATH = `"$shortPath;`$env:PYTHONPATH`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or run export with:" -ForegroundColor Yellow
    Write-Host "  `$env:PYTHONPATH = `"$shortPath;`$env:PYTHONPATH`"; python export_onnx.py" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Installation had issues. Trying alternative method..." -ForegroundColor Yellow
    Write-Host ""
    
    # Option 2: Try installing with --user flag
    Write-Host "Option 2: Installing with --user flag..." -ForegroundColor Yellow
    pip install --user onnx onnxslim
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ONNX installed to user directory!" -ForegroundColor Green
    } else {
        Write-Host "❌ Installation failed. See docs/ONNX_EXPORT_ISSUE.md for more options." -ForegroundColor Red
    }
}

Write-Host ""

