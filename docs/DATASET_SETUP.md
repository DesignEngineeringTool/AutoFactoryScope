# Dataset Setup Guide: Where to Place Files for ML Training

## Current File Locations

### ✅ Processed Images (Ready for Training)
**Location:** `data/processed/RobotFloor/`
- **Total:** 1,824 PNG files
- **Size:** ~206 MB
- **Status:** ✅ Ready for training
- **Contents:**
  - 912 files from `starting_*` (prefixed)
  - 912 files from `processed_*` (prefixed)
  - All images: rotated, black background, compressed

### 📁 Raw Images (Source)
**Location:** `data/raw/`
- Original Robotfloor*.png files (38 files)
- Use these if you need to reprocess

## Recommended File Structure for Training

For YOLO training, you need to organize images into training/validation/test splits:

```
data/
├── training/
│   ├── images/          ← Copy ~70% of processed images here
│   └── labels/          ← Annotation files (.txt) go here
├── validation/
│   ├── images/          ← Copy ~20% of processed images here
│   └── labels/          ← Annotation files (.txt) go here
└── test/
    ├── images/          ← Copy ~10% of processed images here
    └── labels/          ← Annotation files (.txt) go here
```

## Quick Setup Script

Create a script to split your 1,824 images:

```powershell
# scripts/split-dataset.ps1
$source = "data/processed/RobotFloor"
$training = "data/training/images"
$validation = "data/validation/images"
$test = "data/test/images"

# Create directories
New-Item -ItemType Directory -Force -Path $training | Out-Null
New-Item -ItemType Directory -Force -Path $validation | Out-Null
New-Item -ItemType Directory -Force -Path $test | Out-Null

# Get all images
$images = Get-ChildItem -Path $source -Filter "*.png" | Sort-Object Name
$total = $images.Count

# Split: 70% training, 20% validation, 10% test
$trainCount = [math]::Floor($total * 0.7)
$valCount = [math]::Floor($total * 0.2)
$testCount = $total - $trainCount - $valCount

# Copy to training
$images[0..($trainCount-1)] | ForEach-Object {
    Copy-Item $_.FullName -Destination $training
}

# Copy to validation
$images[$trainCount..($trainCount+$valCount-1)] | ForEach-Object {
    Copy-Item $_.FullName -Destination $validation
}

# Copy to test
$images[($trainCount+$valCount)..($total-1)] | ForEach-Object {
    Copy-Item $_.FullName -Destination $test
}

Write-Host "Split complete:" -ForegroundColor Green
Write-Host "  Training: $trainCount images" -ForegroundColor Yellow
Write-Host "  Validation: $valCount images" -ForegroundColor Yellow
Write-Host "  Test: $testCount images" -ForegroundColor Yellow
```

## Next Steps: Annotation

After splitting, you need to **annotate** the images:

1. **Install LabelImg** (or use Roboflow web tool)
   ```bash
   pip install labelImg
   labelImg
   ```

2. **Annotate each image:**
   - Open image in LabelImg
   - Draw bounding boxes around robots
   - Save as YOLO format (creates .txt file)
   - Each .txt file should be in the same directory as the image

3. **YOLO annotation format:**
   ```
   class_id center_x center_y width height
   ```
   All values normalized (0.0 to 1.0)

## Training Workflow

### 1. Prepare Dataset
```powershell
# Split images
pwsh scripts/split-dataset.ps1

# Annotate images (use LabelImg or Roboflow)
# This creates .txt files in labels/ directories
```

### 2. Create dataset.yaml
```yaml
path: ./data
train: training/images
val: validation/images
test: test/images

names:
  0: robot
```

### 3. Train YOLO Model (Python)
```python
from ultralytics import YOLO

model = YOLO('yolov8n.pt')  # Start with nano model
results = model.train(
    data='dataset.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    name='robot_detection'
)
```

### 4. Export to ONNX
```python
best_model = YOLO('runs/detect/robot_detection/weights/best.pt')
best_model.export(format='onnx', imgsz=640)
```

### 5. Copy ONNX to Project
```powershell
Copy-Item runs/detect/robot_detection/weights/best.onnx models/onnx/robot_detection.onnx
```

### 6. Use in C# Application
```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx"
```

## File Size Requirements

### Current Status
- **Total images:** 1,824
- **Total size:** 206 MB
- **Average per image:** ~115 KB

### ML.NET Requirements
- ✅ **Minimum:** 50-100 MB (you have 206 MB)
- ✅ **Recommended:** 100+ MB for good training
- ✅ **Your dataset:** Exceeds requirements

### Training Recommendations
- **Minimum dataset:** 100+ annotated images
- **Your dataset:** 1,824 images (excellent!)
- **Split:** 70/20/10 (training/validation/test)
  - Training: ~1,277 images
  - Validation: ~365 images
  - Test: ~182 images

## Important Notes

1. **Don't commit large files to git:**
   - Add `data/` to `.gitignore` (if not already)
   - Only commit scripts and documentation

2. **Annotation is required:**
   - Images alone aren't enough
   - You need bounding box annotations (.txt files)
   - This is the most time-consuming step

3. **Use processed images:**
   - Your `data/processed/RobotFloor/` images are ready
   - They're already rotated, have black backgrounds, and are compressed
   - Perfect for training!

## Summary

✅ **Your processed images are ready** at `data/processed/RobotFloor/`  
✅ **File size is sufficient** (206 MB > 100 MB minimum)  
✅ **Next step:** Split into training/validation/test  
✅ **Then:** Annotate images with bounding boxes  
✅ **Finally:** Train YOLO model and export to ONNX  

See `TRAINING_GUIDE.md` for detailed training instructions.

