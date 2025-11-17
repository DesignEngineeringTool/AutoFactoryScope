# Verify Pipeline Setup for RobotFloor Identification
# ====================================================
# This script checks all prerequisites for the complete annotation pipeline
# Run this before starting the pipeline to ensure everything is ready

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pipeline Setup Verification" -ForegroundColor Cyan
Write-Host "RobotFloor Identification Pipeline" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allChecksPassed = $true

# ============================================================================
# 1. Check Raw Images
# ============================================================================
Write-Host "=== 1. Raw Images ===" -ForegroundColor Cyan
$rawImagesDir = "data/raw/RobotFloor"
if (Test-Path $rawImagesDir) {
    $pngFiles = Get-ChildItem -Path $rawImagesDir -Filter "*.png" -File -ErrorAction SilentlyContinue
    if ($pngFiles.Count -gt 0) {
        Write-Host "  ✅ Found $($pngFiles.Count) PNG files" -ForegroundColor Green
    } else {
        Write-Host "  ❌ No PNG files found in $rawImagesDir" -ForegroundColor Red
        $allChecksPassed = $false
    }
} else {
    Write-Host "  ❌ Directory not found: $rawImagesDir" -ForegroundColor Red
    $allChecksPassed = $false
}
Write-Host ""

# ============================================================================
# 2. Check Raw Annotations
# ============================================================================
Write-Host "=== 2. Raw Annotations ===" -ForegroundColor Cyan
$rawLabelsDir = "data/raw/RobotFloor/labels"
if (Test-Path $rawLabelsDir) {
    $labelFiles = Get-ChildItem -Path $rawLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
    if ($labelFiles.Count -gt 0) {
        Write-Host "  ✅ Found $($labelFiles.Count) annotation files" -ForegroundColor Green
        
        # Check if count matches images
        if ($pngFiles -and $labelFiles.Count -eq $pngFiles.Count) {
            Write-Host "  ✅ Annotation count matches image count" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Annotation count ($($labelFiles.Count)) doesn't match image count ($($pngFiles.Count))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  No annotation files found" -ForegroundColor Yellow
        Write-Host "     Run: pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Labels directory not found: $rawLabelsDir" -ForegroundColor Yellow
    Write-Host "     This is expected if you haven't annotated yet" -ForegroundColor Gray
    Write-Host "     Run: pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# 3. Check Processed Images
# ============================================================================
Write-Host "=== 3. Processed Images ===" -ForegroundColor Cyan
$processedDir = "data/processed/RobotFloor"
if (Test-Path $processedDir) {
    $processedImages = Get-ChildItem -Path $processedDir -Filter "*.png" -File -ErrorAction SilentlyContinue
    if ($processedImages.Count -gt 0) {
        Write-Host "  ✅ Found $($processedImages.Count) processed images" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No processed images found" -ForegroundColor Yellow
        Write-Host "     Run: pwsh scripts/complete-pipeline.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Processed directory not found: $processedDir" -ForegroundColor Yellow
    Write-Host "     Run: pwsh scripts/complete-pipeline.ps1" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# 4. Check Processed Annotations
# ============================================================================
Write-Host "=== 4. Processed Annotations ===" -ForegroundColor Cyan
$processedLabelsDir = "data/processed/RobotFloor/labels"
if (Test-Path $processedLabelsDir) {
    $processedLabels = Get-ChildItem -Path $processedLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
    if ($processedLabels.Count -gt 0) {
        Write-Host "  ✅ Found $($processedLabels.Count) processed annotation files" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No processed annotations found" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Processed labels directory not found" -ForegroundColor Yellow
    Write-Host "     Will be created by annotation pipeline" -ForegroundColor Gray
}
Write-Host ""

# ============================================================================
# 5. Check Training/Validation/Test Directories
# ============================================================================
Write-Host "=== 5. Dataset Split Directories ===" -ForegroundColor Cyan
$trainDir = "data/training/images"
$valDir = "data/validation/images"
$testDir = "data/test/images"

$trainExists = Test-Path $trainDir
$valExists = Test-Path $valDir
$testExists = Test-Path $testDir

if ($trainExists -and $valExists -and $testExists) {
    $trainCount = (Get-ChildItem -Path $trainDir -Filter "*.png" -File -ErrorAction SilentlyContinue).Count
    $valCount = (Get-ChildItem -Path $valDir -Filter "*.png" -File -ErrorAction SilentlyContinue).Count
    $testCount = (Get-ChildItem -Path $testDir -Filter "*.png" -File -ErrorAction SilentlyContinue).Count
    
    if ($trainCount -gt 0 -or $valCount -gt 0 -or $testCount -gt 0) {
        Write-Host "  ✅ Directories exist with images:" -ForegroundColor Green
        Write-Host "     Training:   $trainCount images" -ForegroundColor Green
        Write-Host "     Validation: $valCount images" -ForegroundColor Green
        Write-Host "     Test:       $testCount images" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Directories exist but are empty" -ForegroundColor Yellow
        Write-Host "     Run: pwsh scripts/split-dataset.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Some directories missing (will be created by split script)" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# 6. Check Python Installation
# ============================================================================
Write-Host "=== 6. Python Installation ===" -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Python installed: $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Python not found" -ForegroundColor Red
        $allChecksPassed = $false
    }
} catch {
    Write-Host "  ❌ Python not found" -ForegroundColor Red
    $allChecksPassed = $false
}
Write-Host ""

# ============================================================================
# 7. Check Python Dependencies
# ============================================================================
Write-Host "=== 7. Python Dependencies ===" -ForegroundColor Cyan
try {
    $ultralyticsVersion = python -c "import ultralytics; print(ultralytics.__version__)" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ ultralytics installed: version $ultralyticsVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ ultralytics not installed" -ForegroundColor Red
        Write-Host "     Install: pip install ultralytics" -ForegroundColor Yellow
        $allChecksPassed = $false
    }
} catch {
    Write-Host "  ❌ ultralytics not installed" -ForegroundColor Red
    Write-Host "     Install: pip install ultralytics" -ForegroundColor Yellow
    $allChecksPassed = $false
}
Write-Host ""

# ============================================================================
# 8. Check Training Script
# ============================================================================
Write-Host "=== 8. Training Script ===" -ForegroundColor Cyan
if (Test-Path "train_robot_model.py") {
    Write-Host "  ✅ Training script found: train_robot_model.py" -ForegroundColor Green
} else {
    Write-Host "  ❌ Training script not found: train_robot_model.py" -ForegroundColor Red
    $allChecksPassed = $false
}
Write-Host ""

# ============================================================================
# 9. Check Dataset Configuration
# ============================================================================
Write-Host "=== 9. Dataset Configuration ===" -ForegroundColor Cyan
if (Test-Path "dataset.yaml") {
    Write-Host "  ✅ Dataset configuration found: dataset.yaml" -ForegroundColor Green
} else {
    Write-Host "  ❌ Dataset configuration not found: dataset.yaml" -ForegroundColor Red
    Write-Host "     This file is required for training" -ForegroundColor Yellow
    $allChecksPassed = $false
}
Write-Host ""

# ============================================================================
# 10. Check Required Scripts
# ============================================================================
Write-Host "=== 10. Required Scripts ===" -ForegroundColor Cyan
$requiredScripts = @(
    "scripts/complete-annotation-pipeline.ps1",
    "scripts/complete-pipeline.ps1",
    "scripts/transform-annotations-for-rotation.ps1",
    "scripts/copy-annotations-for-black-bg.ps1",
    "scripts/merge-annotations-for-final-dataset.ps1",
    "scripts/verify-annotations.ps1",
    "scripts/split-dataset.ps1"
)

$missingScripts = @()
foreach ($script in $requiredScripts) {
    if (Test-Path $script) {
        Write-Host "  ✅ $script" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $script" -ForegroundColor Red
        $missingScripts += $script
        $allChecksPassed = $false
    }
}
Write-Host ""

# ============================================================================
# 11. Check Models Directory
# ============================================================================
Write-Host "=== 11. Models Directory ===" -ForegroundColor Cyan
$modelsOnnxDir = "models/onnx"
if (Test-Path $modelsOnnxDir) {
    Write-Host "  ✅ Models directory exists: $modelsOnnxDir" -ForegroundColor Green
    $onnxFiles = Get-ChildItem -Path $modelsOnnxDir -Filter "*.onnx" -File -ErrorAction SilentlyContinue
    if ($onnxFiles.Count -gt 0) {
        Write-Host "     Found $($onnxFiles.Count) ONNX model(s)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  Models directory not found (will be created when needed)" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# Summary
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allChecksPassed -and $missingScripts.Count -eq 0) {
    Write-Host "✅ All critical checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You're ready to run the pipeline:" -ForegroundColor Cyan
    Write-Host "  pwsh scripts/complete-annotation-pipeline.ps1" -ForegroundColor Yellow
    Write-Host ""
    
    # Check if annotations are needed
    if (-not (Test-Path $rawLabelsDir) -or ((Get-ChildItem -Path $rawLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue).Count -eq 0)) {
        Write-Host "⚠️  Note: You need to annotate images first:" -ForegroundColor Yellow
        Write-Host "  pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "❌ Some checks failed. Please fix the issues above." -ForegroundColor Red
    Write-Host ""
    
    if ($missingScripts.Count -gt 0) {
        Write-Host "Missing scripts:" -ForegroundColor Yellow
        foreach ($script in $missingScripts) {
            Write-Host "  - $script" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

Write-Host "For more information, see:" -ForegroundColor Cyan
Write-Host "  - docs/NEXT_STEPS.md" -ForegroundColor Yellow
Write-Host "  - docs/ANNOTATION_PIPELINE_SUMMARY.md" -ForegroundColor Yellow
Write-Host ""

