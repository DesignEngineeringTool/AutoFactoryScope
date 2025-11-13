# Complete ONNX Guide: From Images to Production

## Table of Contents
1. [Overview](#overview)
2. [Complete Workflow](#complete-workflow)
3. [Step-by-Step Procedure](#step-by-step-procedure)
4. [Best Practices](#best-practices)
5. [Common Issues & Solutions](#common-issues--solutions)
6. [Validation & Testing](#validation--testing)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting Checklist](#troubleshooting-checklist)

---

## Overview

This guide walks you through the **complete process** of creating an ONNX model for robot detection, from raw images to a production-ready model file.

### What You'll Learn
- ✅ Complete end-to-end workflow
- ✅ Best practices at each stage
- ✅ How to avoid common pitfalls
- ✅ How to validate your model
- ✅ Performance optimization tips

---

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Image Preparation                                        │
│    • Collect/process images                                 │
│    • Split into train/val/test                             │
│    • Verify image quality                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Annotation                                               │
│    • Label objects with bounding boxes                      │
│    • Create YOLO format .txt files                         │
│    • Validate annotations                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Dataset Configuration                                    │
│    • Create dataset.yaml                                    │
│    • Verify paths and class names                          │
│    • Check data balance                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Training (Python/YOLO)                                   │
│    • Choose YOLO version (v8 recommended)                  │
│    • Configure hyperparameters                             │
│    • Monitor training progress                              │
│    • Save best model                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Model Evaluation                                         │
│    • Check mAP (mean Average Precision)                    │
│    • Review confusion matrix                                │
│    • Test on validation set                                 │
│    • Verify detection quality                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. ONNX Export                                              │
│    • Export from PyTorch (.pt) to ONNX                      │
│    • Configure export parameters                            │
│    • Validate ONNX file                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. ONNX Validation                                          │
│    • Check ONNX file integrity                              │
│    • Verify input/output shapes                             │
│    • Test inference                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Integration (C#/ML.NET)                                  │
│    • Copy ONNX to project                                   │
│    • Update code if needed                                 │
│    • Test in application                                    │
│    • Performance testing                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Procedure

### Step 1: Image Preparation

#### 1.1 Verify Your Images
```powershell
# Check image count and size
$images = Get-ChildItem "data/processed/RobotFloor" -Filter "*.png"
Write-Host "Total images: $($images.Count)"
Write-Host "Total size: $([math]::Round(($images | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
```

**Requirements:**
- ✅ Minimum 100 images (you have 1,824 - excellent!)
- ✅ Consistent image size (640x640 recommended)
- ✅ Good quality, clear objects
- ✅ Diverse angles, lighting, backgrounds

#### 1.2 Split Dataset
```powershell
# Use the split script
pwsh scripts/split-dataset.ps1

# Or manually:
# 70% training (~1,277 images)
# 20% validation (~365 images)
# 10% test (~182 images)
```

**Best Practice:** Use stratified splitting if you have multiple classes to maintain class balance.

#### 1.3 Verify Split
```powershell
$train = (Get-ChildItem "data/training/images" -Filter "*.png").Count
$val = (Get-ChildItem "data/validation/images" -Filter "*.png").Count
$test = (Get-ChildItem "data/test/images" -Filter "*.png").Count
Write-Host "Training: $train, Validation: $val, Test: $test"
```

---

### Step 2: Annotation

#### 2.1 Install Annotation Tool

**Option A: LabelImg (Recommended for beginners)**
```bash
pip install labelImg
labelImg
```

**Option B: Roboflow (Web-based, includes dataset management)**
- Visit https://roboflow.com
- Upload images
- Annotate in browser
- Export in YOLO format

**Option C: CVAT (Advanced, for teams)**
```bash
docker run -d -p 8080:8080 cvat/cvat
```

#### 2.2 Annotation Process

1. **Open image in LabelImg**
2. **Set format to YOLO** (not PascalVOC)
3. **Draw bounding boxes** around each robot
4. **Assign class ID** (0 for robot)
5. **Save** - creates `.txt` file with same name

#### 2.3 YOLO Annotation Format

Each `.txt` file contains one line per object:
```
class_id center_x center_y width height
```

**Example:** `Robotfloor1.txt`
```
0 0.5 0.5 0.1 0.15
0 0.3 0.7 0.08 0.12
```

**Important:**
- All values are **normalized** (0.0 to 1.0)
- `center_x, center_y` = center of bounding box
- `width, height` = size of bounding box
- All relative to image dimensions

#### 2.4 Verify Annotations

```python
# verify_annotations.py
import os
from PIL import Image

def verify_annotation(image_path, label_path):
    img = Image.open(image_path)
    img_width, img_height = img.size
    
    with open(label_path, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) != 5:
                print(f"ERROR: Invalid line in {label_path}: {line}")
                return False
            
            class_id, cx, cy, w, h = map(float, parts)
            
            # Check if values are in valid range
            if not (0 <= cx <= 1 and 0 <= cy <= 1 and 0 <= w <= 1 and 0 <= h <= 1):
                print(f"ERROR: Values out of range in {label_path}")
                return False
            
            # Convert to pixel coordinates and check bounds
            x1 = (cx - w/2) * img_width
            y1 = (cy - h/2) * img_height
            x2 = (cx + w/2) * img_width
            y2 = (cy + h/2) * img_height
            
            if x1 < 0 or y1 < 0 or x2 > img_width or y2 > img_height:
                print(f"WARNING: Bounding box out of image bounds in {label_path}")
    
    return True

# Verify all annotations
for split in ['training', 'validation', 'test']:
    images_dir = f'data/{split}/images'
    labels_dir = f'data/{split}/labels'
    
    for img_file in os.listdir(images_dir):
        if img_file.endswith('.png'):
            img_path = os.path.join(images_dir, img_file)
            label_path = os.path.join(labels_dir, img_file.replace('.png', '.txt'))
            
            if not os.path.exists(label_path):
                print(f"WARNING: Missing label for {img_file}")
            else:
                verify_annotation(img_path, label_path)
```

**Run verification:**
```bash
python verify_annotations.py
```

---

### Step 3: Dataset Configuration

#### 3.1 Create dataset.yaml

Create `dataset.yaml` in your project root:

```yaml
# Dataset configuration for YOLO training
path: ./data  # Root directory of dataset
train: training/images  # Training images (relative to 'path')
val: validation/images  # Validation images (relative to 'path')
test: test/images  # Test images (optional, relative to 'path')

# Number of classes
nc: 1

# Class names
names:
  0: robot
  # Add more classes as you expand:
  # 1: fixture
  # 2: pedestal
  # 3: eoat
```

#### 3.2 Verify Dataset Structure

```
data/
├── training/
│   ├── images/
│   │   ├── Robotfloor1.png
│   │   ├── Robotfloor2.png
│   │   └── ...
│   └── labels/
│       ├── Robotfloor1.txt
│       ├── Robotfloor2.txt
│       └── ...
├── validation/
│   ├── images/
│   └── labels/
└── test/
    ├── images/
    └── labels/
```

**Critical:** Image and label files must have **matching names** (except extension).

#### 3.3 Check Data Balance

```python
# check_data_balance.py
import os
from collections import Counter

def count_objects_in_labels(labels_dir):
    counts = Counter()
    for label_file in os.listdir(labels_dir):
        if label_file.endswith('.txt'):
            with open(os.path.join(labels_dir, label_file), 'r') as f:
                for line in f:
                    class_id = int(line.strip().split()[0])
                    counts[class_id] += 1
    return counts

train_counts = count_objects_in_labels('data/training/labels')
val_counts = count_objects_in_labels('data/validation/labels')

print("Training set object counts:", dict(train_counts))
print("Validation set object counts:", dict(val_counts))
```

**Best Practice:** Ensure similar object counts across splits.

---

### Step 4: Training (Python/YOLO)

#### 4.1 Install YOLO

```bash
# Install Ultralytics YOLO (recommended)
pip install ultralytics

# Or install YOLOv5
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
```

#### 4.2 Choose YOLO Version

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| YOLOv8n | Smallest | Fastest | Good | Testing, edge devices |
| YOLOv8s | Small | Fast | Better | **Recommended start** |
| YOLOv8m | Medium | Medium | Good | Production (if accuracy needed) |
| YOLOv8l | Large | Slow | Better | High accuracy required |
| YOLOv8x | Largest | Slowest | Best | Maximum accuracy |

**Recommendation:** Start with **YOLOv8s** for good balance.

#### 4.3 Training Script

Create `train_robot_model.py`:

```python
from ultralytics import YOLO
import os

# Configuration
MODEL_SIZE = 's'  # n, s, m, l, x
EPOCHS = 100
BATCH_SIZE = 16
IMAGE_SIZE = 640
DATA_YAML = 'dataset.yaml'
PROJECT_NAME = 'robot_detection'

# Load pre-trained model (transfer learning)
print(f"Loading YOLOv8{MODEL_SIZE}...")
model = YOLO(f'yolov8{MODEL_SIZE}.pt')  # Downloads automatically if not found

# Train the model
print("Starting training...")
results = model.train(
    data=DATA_YAML,
    epochs=EPOCHS,
    imgsz=IMAGE_SIZE,
    batch=BATCH_SIZE,
    name=PROJECT_NAME,
    
    # Training options
    patience=20,  # Early stopping patience
    save=True,    # Save checkpoints
    save_period=10,  # Save checkpoint every N epochs
    plots=True,   # Generate training plots
    
    # Augmentation (helps with small datasets)
    hsv_h=0.015,  # Hue augmentation
    hsv_s=0.7,    # Saturation augmentation
    hsv_v=0.4,    # Value augmentation
    degrees=10,   # Rotation augmentation
    translate=0.1,  # Translation augmentation
    scale=0.5,    # Scale augmentation
    flipud=0.0,   # Vertical flip probability
    fliplr=0.5,   # Horizontal flip probability
    mosaic=1.0,   # Mosaic augmentation probability
    mixup=0.1,    # Mixup augmentation probability
    
    # Optimization
    optimizer='AdamW',  # or 'SGD'
    lr0=0.01,     # Initial learning rate
    lrf=0.1,      # Final learning rate (lr0 * lrf)
    momentum=0.937,
    weight_decay=0.0005,
    warmup_epochs=3,
    warmup_momentum=0.8,
    warmup_bias_lr=0.1,
    
    # Validation
    val=True,     # Validate during training
    plots=True,   # Generate validation plots
)

print("\nTraining completed!")
print(f"Best model saved to: runs/detect/{PROJECT_NAME}/weights/best.pt")
print(f"Last model saved to: runs/detect/{PROJECT_NAME}/weights/last.pt")
```

#### 4.4 Run Training

```bash
python train_robot_model.py
```

#### 4.5 Monitor Training

Training will show:
- **Loss curves** (train/val loss)
- **mAP metrics** (mean Average Precision)
- **Progress bar** with ETA
- **Best model** automatically saved

**Watch for:**
- ✅ Loss decreasing steadily
- ✅ mAP increasing
- ✅ No overfitting (val loss not much higher than train loss)

---

### Step 5: Model Evaluation

#### 5.1 Check Training Results

After training, check the results:

```python
from ultralytics import YOLO
import matplotlib.pyplot as plt

# Load best model
model = YOLO('runs/detect/robot_detection/weights/best.pt')

# Evaluate on validation set
metrics = model.val(data='dataset.yaml')

print(f"mAP50: {metrics.box.map50:.4f}")
print(f"mAP50-95: {metrics.box.map:.4f}")
print(f"Precision: {metrics.box.mp:.4f}")
print(f"Recall: {metrics.box.mr:.4f}")
```

**Good Metrics:**
- **mAP50 > 0.7** = Good model
- **mAP50 > 0.8** = Very good model
- **mAP50 > 0.9** = Excellent model

#### 5.2 Test on Sample Images

```python
# Test on a few images
results = model('data/test/images/Robotfloor1.png')

# Show results
results[0].show()  # Display image with bounding boxes
results[0].save('test_result.jpg')  # Save result
```

#### 5.3 Review Confusion Matrix

Check `runs/detect/robot_detection/confusion_matrix.png`:
- Shows true positives, false positives, false negatives
- Helps identify what the model struggles with

---

### Step 6: ONNX Export

#### 6.1 Export to ONNX

```python
from ultralytics import YOLO

# Load your trained model
model = YOLO('runs/detect/robot_detection/weights/best.pt')

# Export to ONNX
model.export(
    format='onnx',
    imgsz=640,           # Input image size (must match training)
    dynamic=False,       # Static batch size (faster inference)
    simplify=True,       # Simplify ONNX model
    opset=12,            # ONNX opset version (12 is widely supported)
    half=False,          # FP16 quantization (faster, but may reduce accuracy)
)
```

**Export Options Explained:**
- `imgsz=640`: Input size (must match training)
- `dynamic=False`: Static input shape (faster, less flexible)
- `dynamic=True`: Dynamic input shape (slower, more flexible)
- `simplify=True`: Optimize ONNX graph (recommended)
- `opset=12`: ONNX operator set version (12 is safe, 17 is latest)
- `half=False`: Use FP32 (more accurate) or FP16 (faster)

#### 6.2 Verify Export

```python
import onnx

# Load and validate ONNX model
onnx_model = onnx.load('runs/detect/robot_detection/weights/best.onnx')
onnx.checker.check_model(onnx_model)

print("✅ ONNX model is valid!")
print(f"Input shape: {onnx_model.graph.input[0].type.tensor_type.shape.dim}")
print(f"Output shapes: {[out.type.tensor_type.shape.dim for out in onnx_model.graph.output]}")
```

---

### Step 7: ONNX Validation

#### 7.1 Test ONNX Inference (Python)

```python
import onnxruntime as ort
import numpy as np
from PIL import Image

# Load ONNX model
session = ort.InferenceSession('runs/detect/robot_detection/weights/best.onnx')

# Get input/output names
input_name = session.get_inputs()[0].name
output_names = [output.name for output in session.get_outputs()]

print(f"Input name: {input_name}")
print(f"Output names: {output_names}")

# Load and preprocess image
img = Image.open('data/test/images/Robotfloor1.png')
img = img.resize((640, 640))
img_array = np.array(img).astype(np.float32) / 255.0
img_array = np.transpose(img_array, (2, 0, 1))  # HWC to CHW
img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension

# Run inference
outputs = session.run(output_names, {input_name: img_array})

print(f"Output shapes: {[out.shape for out in outputs]}")
print("✅ ONNX inference successful!")
```

#### 7.2 Compare ONNX vs PyTorch

```python
from ultralytics import YOLO
import onnxruntime as ort
import numpy as np

# Load PyTorch model
pt_model = YOLO('runs/detect/robot_detection/weights/best.pt')

# Load ONNX model
onnx_session = ort.InferenceSession('runs/detect/robot_detection/weights/best.onnx')

# Test on same image
img_path = 'data/test/images/Robotfloor1.png'

# PyTorch prediction
pt_results = pt_model(img_path)
pt_boxes = pt_results[0].boxes.data.cpu().numpy()

# ONNX prediction (preprocess image first)
img = Image.open(img_path)
img = img.resize((640, 640))
img_array = np.array(img).astype(np.float32) / 255.0
img_array = np.transpose(img_array, (2, 0, 1))
img_array = np.expand_dims(img_array, axis=0)

input_name = onnx_session.get_inputs()[0].name
outputs = onnx_session.run(None, {input_name: img_array})

# Compare results (should be similar)
print(f"PyTorch detected {len(pt_boxes)} objects")
print(f"ONNX detected {len(outputs[0])} objects")
```

---

### Step 8: Integration (C#/ML.NET)

#### 8.1 Copy ONNX to Project

```powershell
# Copy ONNX model to project
Copy-Item "runs/detect/robot_detection/weights/best.onnx" "models/onnx/robot_detection.onnx"
```

#### 8.2 Verify C# Integration

Your `RobotPredictor.cs` should work automatically:

```csharp
var predictor = new RobotPredictor("models/onnx/robot_detection.onnx");
var result = predictor.Predict(imageBytes, 640, "test_image.png");
```

#### 8.3 Test in Application

```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/images/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx" \
  --json --output results.json
```

---

## Best Practices

### 1. Dataset Preparation
- ✅ **Minimum 100 images per class** (you have 1,824 - excellent!)
- ✅ **70/20/10 split** (training/validation/test)
- ✅ **Consistent image size** (640x640 recommended)
- ✅ **Diverse images** (different angles, lighting, backgrounds)
- ✅ **Balanced classes** (similar number of objects per class)

### 2. Annotation
- ✅ **Accurate bounding boxes** (tight fit around objects)
- ✅ **Consistent labeling** (same object = same class)
- ✅ **Verify annotations** (check a sample manually)
- ✅ **Handle edge cases** (partially visible objects, occlusions)

### 3. Training
- ✅ **Start with pre-trained weights** (transfer learning)
- ✅ **Use appropriate model size** (YOLOv8s for balance)
- ✅ **Monitor training** (watch loss and mAP)
- ✅ **Use early stopping** (patience=20)
- ✅ **Save checkpoints** (save_period=10)
- ✅ **Enable augmentation** (helps with small datasets)

### 4. ONNX Export
- ✅ **Match input size** (same as training: 640x640)
- ✅ **Use static shapes** (dynamic=False for speed)
- ✅ **Simplify model** (simplify=True)
- ✅ **Test immediately** (verify ONNX works before deploying)

### 5. Validation
- ✅ **Test on validation set** (check mAP metrics)
- ✅ **Test on test set** (final evaluation)
- ✅ **Compare PyTorch vs ONNX** (ensure similar results)
- ✅ **Test in C# application** (end-to-end validation)

---

## Common Issues & Solutions

### Issue 1: "No module named 'ultralytics'"

**Solution:**
```bash
pip install ultralytics
# Or
pip install --upgrade ultralytics
```

### Issue 2: "CUDA out of memory"

**Solutions:**
- Reduce `batch_size` (try 8 or 4)
- Use smaller model (YOLOv8n instead of YOLOv8s)
- Reduce image size (try 416 instead of 640)
- Close other applications using GPU

### Issue 3: "mAP is very low (< 0.3)"

**Possible causes:**
- Insufficient training data
- Poor annotations
- Wrong class IDs
- Model not trained long enough

**Solutions:**
- Add more training images
- Review and fix annotations
- Verify class IDs in dataset.yaml
- Train for more epochs
- Check if objects are visible in images

### Issue 4: "ONNX export fails"

**Solutions:**
```python
# Try explicit opset version
model.export(format='onnx', opset=11)  # Try lower opset

# Or update dependencies
pip install --upgrade onnx onnxruntime

# Check ONNX version compatibility
import onnx
print(onnx.__version__)  # Should be >= 1.12.0
```

### Issue 5: "ONNX model produces different results than PyTorch"

**Causes:**
- Different preprocessing
- Quantization (FP16 vs FP32)
- Input shape mismatch

**Solutions:**
- Ensure same preprocessing in both
- Use `half=False` in export
- Verify input shapes match

### Issue 6: "Model detects nothing"

**Possible causes:**
- Confidence threshold too high
- Model not trained properly
- Input preprocessing wrong
- Wrong input size

**Solutions:**
```python
# Lower confidence threshold
results = model('image.png', conf=0.25)  # Default is 0.25

# Check model metrics
metrics = model.val()
print(f"mAP: {metrics.box.map50}")  # Should be > 0.5

# Verify input preprocessing
# Image should be 640x640, RGB, normalized 0-1
```

### Issue 7: "Training loss not decreasing"

**Solutions:**
- Check learning rate (try lr0=0.001)
- Verify annotations are correct
- Ensure images are loaded correctly
- Try different optimizer (SGD instead of AdamW)
- Check if model is too large for dataset

### Issue 8: "Overfitting (val loss >> train loss)"

**Solutions:**
- Add more training data
- Increase augmentation
- Use dropout (if available)
- Reduce model size
- Early stopping (already enabled)

### Issue 9: "ONNX Runtime error in C#"

**Common errors:**
```
- "Input shape mismatch"
- "Invalid input type"
- "Model not found"
```

**Solutions:**
```csharp
// Verify model path
if (!File.Exists(onnxPath)) throw new FileNotFoundException(onnxPath);

// Check input shape in C#
// Should match: [1, 3, 640, 640] for RGB image

// Verify input preprocessing matches training
// Image should be: 640x640, RGB, normalized 0-1, CHW format
```

### Issue 10: "Slow inference speed"

**Solutions:**
- Use smaller model (YOLOv8n)
- Reduce image size (416 instead of 640)
- Use GPU acceleration
- Enable FP16 quantization
- Use static input shapes (dynamic=False)

---

## Validation & Testing

### Pre-Training Checklist
- [ ] Images are properly split (train/val/test)
- [ ] All images have corresponding label files
- [ ] Annotations are in YOLO format
- [ ] dataset.yaml is correct
- [ ] Class names match annotations
- [ ] Image sizes are consistent

### Post-Training Checklist
- [ ] mAP50 > 0.7 (good model)
- [ ] Training loss decreased
- [ ] Validation loss not much higher than training
- [ ] Model detects objects on test images
- [ ] Confusion matrix looks reasonable

### Pre-ONNX Export Checklist
- [ ] Best model saved (best.pt)
- [ ] Model performs well on validation set
- [ ] Tested on sample images
- [ ] Metrics are acceptable

### Post-ONNX Export Checklist
- [ ] ONNX file created successfully
- [ ] ONNX model validates (onnx.checker.check_model)
- [ ] ONNX inference works in Python
- [ ] ONNX results match PyTorch results
- [ ] Input/output shapes are correct

### Pre-Deployment Checklist
- [ ] ONNX model copied to project
- [ ] C# code loads model successfully
- [ ] Inference works in C# application
- [ ] Results are reasonable
- [ ] Performance is acceptable

---

## Performance Optimization

### Training Speed
- Use GPU (CUDA)
- Increase batch size (if memory allows)
- Use mixed precision training
- Reduce image size during training (then scale up)

### Inference Speed
- Use smaller model (YOLOv8n)
- Reduce input image size
- Use ONNX Runtime with GPU
- Enable FP16 quantization
- Use static input shapes

### Model Size
- Use smaller YOLO variant (n or s)
- Quantize to INT8 (advanced)
- Prune model (remove unnecessary weights)

---

## Troubleshooting Checklist

When something goes wrong, check:

1. **Data Issues**
   - [ ] Images load correctly
   - [ ] Labels match images
   - [ ] Annotation format is correct
   - [ ] dataset.yaml paths are correct

2. **Training Issues**
   - [ ] CUDA/GPU available
   - [ ] Batch size fits in memory
   - [ ] Learning rate is reasonable
   - [ ] Model architecture matches data

3. **Export Issues**
   - [ ] PyTorch model loads
   - [ ] ONNX version compatible
   - [ ] Input size matches training
   - [ ] Dependencies up to date

4. **Integration Issues**
   - [ ] ONNX file path correct
   - [ ] Input preprocessing matches
   - [ ] Output parsing correct
   - [ ] ML.NET version compatible

---

## Quick Reference Commands

### Training
```bash
# Install
pip install ultralytics

# Train
python train_robot_model.py

# Evaluate
python -c "from ultralytics import YOLO; m = YOLO('runs/detect/robot_detection/weights/best.pt'); m.val()"
```

### Export
```python
from ultralytics import YOLO
model = YOLO('runs/detect/robot_detection/weights/best.pt')
model.export(format='onnx', imgsz=640)
```

### Validate
```python
import onnx
onnx.checker.check_model(onnx.load('best.onnx'))
```

### Test in C#
```bash
dotnet run --project src/AutoFactoryScope.CLI -- --image "test.png" --model "models/onnx/robot_detection.onnx"
```

---

## Summary

**Complete Workflow:**
1. ✅ Prepare images (split, verify)
2. ✅ Annotate (create .txt files)
3. ✅ Configure dataset (dataset.yaml)
4. ✅ Train YOLO model (Python)
5. ✅ Evaluate (check mAP)
6. ✅ Export to ONNX
7. ✅ Validate ONNX
8. ✅ Integrate in C#

**Key Success Factors:**
- Good quality annotations
- Sufficient training data
- Appropriate model size
- Proper validation
- Careful ONNX export

**Common Pitfalls to Avoid:**
- ❌ Skipping annotation verification
- ❌ Using wrong input size
- ❌ Not testing ONNX before deployment
- ❌ Mismatched preprocessing
- ❌ Ignoring training metrics

---

**Last Updated:** 2025
**Version:** 1.0

