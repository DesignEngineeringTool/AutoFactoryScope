# Complete Annotation Pipeline
# =============================
# This script orchestrates the entire workflow:
# 1. Verify original annotations (36 files)
# 2. Process images (rotate, black background)
# 3. Transform annotations for rotations
# 4. Copy annotations for black background
# 5. Merge annotations for final dataset
# 6. Split dataset (train/val/test)
# 7. Train YOLO model
# 8. Export to ONNX format
#
# Prerequisites:
# - 36 PNG files annotated in data/raw/RobotFloor/labels/
# - Python with ultralytics installed
#
# Usage:
#   pwsh scripts/complete-annotation-pipeline.ps1 [-SkipTraining] [-SkipProcessing]

param(
    [switch]$SkipTraining = $false,
    [switch]$SkipProcessing = $false,
    [string]$RawImagesDir = "data/raw/RobotFloor",
    [string]$RawLabelsDir = "data/raw/RobotFloor/labels",
    [string]$ProcessedDir = "data/processed",
    [string]$FinalDir = "data/processed/RobotFloor"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Complete Annotation Pipeline" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Verify prerequisites
Write-Host "=== Step 0: Verifying Prerequisites ===" -ForegroundColor Cyan
Write-Host ""

# Check raw images
if (-not (Test-Path $RawImagesDir)) {
    Write-Error "Raw images directory not found: $RawImagesDir"
    exit 1
}

$pngFiles = Get-ChildItem -Path $RawImagesDir -Filter "*.png" -File
if ($pngFiles.Count -eq 0) {
    Write-Error "No PNG files found in $RawImagesDir"
    exit 1}

Write-Host "✅ Found $($pngFiles.Count) PNG files" -ForegroundColor Green

# Check annotations
if (-not (Test-Path $RawLabelsDir)) {
    Write-Error "Labels directory not found: $RawLabelsDir"
    Write-Host "Please annotate images first! Run: pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Red
    exit 1
}

$labelFiles = Get-ChildItem -Path $RawLabelsDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
if ($labelFiles.Count -ne $pngFiles.Count) {
    Write-Warning "Annotation count mismatch: $($labelFiles.Count) labels vs $($pngFiles.Count) images"
    Write-Host "Please complete annotations first! Run: pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found $($labelFiles.Count) annotation files" -ForegroundColor Green
Write-Host ""

# Verify YOLO format
Write-Host "Verifying YOLO format..." -ForegroundColor Yellow
$invalidCount = 0
foreach ($label in $labelFiles) {
    $content = Get-Content $label.FullName -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        continue  # Empty files are OK (no objects)
    }
    
    $lines = Get-Content $label.FullName
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $parts = $line -split '\s+'
        if ($parts.Count -ne 5) {
            Write-Warning "Invalid format in $($label.Name): '$line'"
            $invalidCount++
        }
    }
}

if ($invalidCount -gt 0) {
    Write-Error "Found $invalidCount invalid annotation lines. Please fix before continuing."
    exit 1
}

Write-Host "✅ All annotations are valid YOLO format" -ForegroundColor Green
Write-Host ""

# Step 1: Process images (if not skipped)
if (-not $SkipProcessing) {
    Write-Host "=== Step 1: Processing Images ===" -ForegroundColor Cyan
    Write-Host "This will:"
    Write-Host "  - Format images to 640x640"
    Write-Host "  - Create rotated versions (23 angles)"
    Write-Host "  - Apply black background"
    Write-Host "  - Compress images"
    Write-Host ""
    Write-Host "This may take 10-30 minutes depending on your system..." -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Continue? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Skipping image processing. Run manually: pwsh scripts/complete-pipeline.ps1" -ForegroundColor Yellow
    } else {
        & pwsh -File scripts/complete-pipeline.ps1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Image processing failed!"
            exit 1
        }
        
        Write-Host "✅ Image processing complete" -ForegroundColor Green
        Write-Host ""
    }
} else {
    Write-Host "=== Step 1: Skipped (using existing processed images) ===" -ForegroundColor Yellow
    Write-Host ""
}

# Step 2: Transform annotations for rotations
Write-Host "=== Step 2: Transforming Annotations for Rotations ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "$ProcessedDir/labels")) {
    & pwsh -File scripts/transform-annotations-for-rotation.ps1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Annotation transformation failed!"
        exit 1
    }
} else {
    Write-Host "✅ Rotated annotations already exist" -ForegroundColor Green
}

Write-Host ""

# Step 3: Copy annotations for black background
Write-Host "=== Step 3: Copying Annotations for Black Background ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "$ProcessedDir/all_black_bg/labels")) {
    & pwsh -File scripts/copy-annotations-for-black-bg.ps1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Copying annotations failed!"
        exit 1
    }
} else {
    Write-Host "✅ Black background annotations already exist" -ForegroundColor Green
}

Write-Host ""

# Step 4: Merge annotations for final dataset
Write-Host "=== Step 4: Merging Annotations for Final Dataset ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "$FinalDir/labels")) {
    & pwsh -File scripts/merge-annotations-for-final-dataset.ps1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Merging annotations failed!"
        exit 1
    }
} else {
    Write-Host "✅ Final dataset annotations already exist" -ForegroundColor Green
}

Write-Host ""

# Step 5: Verify annotations
Write-Host "=== Step 5: Verifying Annotations ===" -ForegroundColor Cyan
Write-Host ""

& pwsh -File scripts/verify-annotations.ps1 -ImagesDir $FinalDir -LabelsDir "$FinalDir/labels"

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Some annotation issues found. Please review."
    Write-Host "Continue anyway? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'Y' -and $response -ne 'y') {
        exit 1
    }
}

Write-Host ""

# Step 6: Split dataset
Write-Host "=== Step 6: Splitting Dataset ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "data/training/images") -or (Get-ChildItem "data/training/images" -Filter "*.png" -ErrorAction SilentlyContinue).Count -eq 0) {
    & pwsh -File scripts/split-dataset.ps1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Dataset splitting failed!"
        exit 1
    }
} else {
    Write-Host "✅ Dataset already split" -ForegroundColor Green
}

Write-Host ""

# Step 7: Train model (if not skipped)
if (-not $SkipTraining) {
    Write-Host "=== Step 7: Training YOLO Model ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will:"
    Write-Host "  - Train YOLOv8 model on your dataset"
    Write-Host "  - Export to ONNX format"
    Write-Host ""
    Write-Host "This may take 1-4 hours depending on your GPU..." -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Continue with training? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Skipping training. Run manually: python train_robot_model.py" -ForegroundColor Yellow
    } else {
        # Check if Python and ultralytics are available
        try {
            $pythonVersion = python --version 2>&1
            Write-Host "Python: $pythonVersion" -ForegroundColor Green
        } catch {
            Write-Error "Python not found! Please install Python 3.8+"
            exit 1
        }
        
        Write-Host ""
        Write-Host "Starting training..." -ForegroundColor Cyan
        Write-Host ""
        
        python train_robot_model.py
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Training failed!"
            exit 1
        }
        
        Write-Host ""
        Write-Host "✅ Training complete!" -ForegroundColor Green
        Write-Host ""
        
        # Check if ONNX file was created
        $onnxPath = "runs/detect/robot_detection/weights/best.onnx"
        if (Test-Path $onnxPath) {
            Write-Host "=== Step 8: ONNX Export Complete ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "✅ ONNX model exported: $onnxPath" -ForegroundColor Green
            
            $sizeMB = (Get-Item $onnxPath).Length / 1MB
            Write-Host "   File size: $([math]::Round($sizeMB, 2)) MB" -ForegroundColor Yellow
            Write-Host ""
            
            # Copy to models directory
            $targetPath = "models/onnx/robot_detection.onnx"
            if (-not (Test-Path "models/onnx")) {
                New-Item -ItemType Directory -Force -Path "models/onnx" | Out-Null
            }
            
            Copy-Item -Path $onnxPath -Destination $targetPath -Force
            Write-Host "✅ Copied to: $targetPath" -ForegroundColor Green
            Write-Host ""
        }
    }
} else {
    Write-Host "=== Step 7: Training Skipped ===" -ForegroundColor Yellow
    Write-Host "Run manually: python train_robot_model.py" -ForegroundColor Yellow
    Write-Host ""
}

# Final summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pipeline Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Original annotations: $($labelFiles.Count) files" -ForegroundColor Green
Write-Host "  ✅ Processed images: $(if (Test-Path $FinalDir) { (Get-ChildItem $FinalDir -Filter '*.png' -ErrorAction SilentlyContinue).Count } else { 'N/A' })" -ForegroundColor Green
Write-Host "  ✅ Final annotations: $(if (Test-Path "$FinalDir/labels") { (Get-ChildItem "$FinalDir/labels" -Filter '*.txt' -ErrorAction SilentlyContinue).Count } else { 'N/A' })" -ForegroundColor Green
Write-Host ""

if (Test-Path "models/onnx/robot_detection.onnx") {
    Write-Host "✅ ONNX model ready: models/onnx/robot_detection.onnx" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Test the model in C#:" -ForegroundColor Cyan
    Write-Host "  dotnet run --project src/AutoFactoryScope.CLI -- \" -ForegroundColor Yellow
    Write-Host "    --image `"data/test/images/Robotfloor1.png`" `" -ForegroundColor Yellow
    Write-Host "    --model `"models/onnx/robot_detection.onnx`"" -ForegroundColor Yellow
} else {
    Write-Host "Next step: Train the model:" -ForegroundColor Cyan
    Write-Host "  python train_robot_model.py" -ForegroundColor Yellow
}

Write-Host ""

