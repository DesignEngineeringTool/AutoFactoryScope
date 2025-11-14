# Training Guide: From PNG Images to ONNX Model

## Overview

This guide explains how to go from PNG images (like your `Robotfloor*.png` files) to a trained ONNX model that can be used for inference in AutoFactoryScope.

**Important:** PNG images are **not directly converted** to ONNX. The process involves:
1. **Annotating** PNG images (labeling objects)
2. **Training** a YOLO model using those annotations
3. **Exporting** the trained model to ONNX format
4. **Using** the ONNX model for inference in this C# application

---

## Step-by-Step Process

### Step 1: Prepare Your PNG Images

You already have PNG images in `data/raw/` (e.g., `Robotfloor1.png`, `Robotfloor2.png`, etc.).

**Next steps:**
- Copy images to `data/training/images/` for training
- Copy images to `data/validation/images/` for validation (typically 20-30% of your dataset)
- Copy images to `data/test/images/` for final testing

**Recommended split:**
- 70% training
- 20% validation
- 10% test

### Step 2: Annotate Images (YOLO Format)

You need to label objects in each image. Each image needs a corresponding `.txt` file with bounding box annotations.

**YOLO annotation format** (one line per object):
```
class_id center_x center_y width height
```

Where all values are **normalized** (0.0 to 1.0) relative to image dimensions.

**Example:** `Robotfloor1.txt`
```
0 0.5 0.5 0.1 0.15
0 0.3 0.7 0.08 0.12
```

**Tools for annotation:**
- **LabelImg** (https://github.com/HumanSignal/labelImg) - Popular GUI tool
- **Roboflow** (https://roboflow.com) - Web-based, includes dataset management
- **CVAT** (https://cvat.org) - Advanced annotation platform

**Directory structure after annotation:**
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

### Step 3: Train a YOLO Model (Python)

Training is done in **Python** using frameworks like Ultralytics YOLO or PyTorch.

#### Option A: Using Ultralytics YOLOv8 (Recommended)

**Install:**
```bash
pip install ultralytics
```

**Create a dataset YAML file** (`dataset.yaml`):
```yaml
path: ./data  # dataset root dir
train: training/images  # train images (relative to 'path')
val: validation/images  # val images (relative to 'path')
test: test/images  # test images (optional)

# Classes
names:
  0: robot
  # Add more classes as needed:
  # 1: fixture
  # 2: pedestal
```

**Train the model:**
```python
from ultralytics import YOLO

# Load a pre-trained model (YOLOv8n, YOLOv8s, YOLOv8m, YOLOv8l, YOLOv8x)
model = YOLO('yolov8n.pt')  # or yolov8s.pt, yolov8m.pt, etc.

# Train
results = model.train(
    data='dataset.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    name='robot_detection'
)
```

**This will:**
- Train the model on your annotated images
- Save checkpoints to `runs/detect/robot_detection/weights/`
- Generate training metrics and plots

#### Option B: Using YOLOv5

**Install:**
```bash
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
```

**Train:**
```bash
python train.py --img 640 --batch 16 --epochs 100 --data dataset.yaml --weights yolov5s.pt
```

### Step 4: Export to ONNX Format

Once training is complete, export the trained model to ONNX.

#### Using Ultralytics YOLOv8:

```python
from ultralytics import YOLO

# Load your trained model
model = YOLO('runs/detect/robot_detection/weights/best.pt')

# Export to ONNX
model.export(format='onnx', imgsz=640)
```

This creates `best.onnx` in the same directory.

#### Using YOLOv5:

```python
import torch

# Load trained model
model = torch.hub.load('ultralytics/yolov5', 'custom', path='runs/train/exp/weights/best.pt')

# Export to ONNX
model.export(format='onnx', imgsz=640)
```

### Step 5: Place ONNX Model in Project

Copy your exported ONNX model to the project:

```bash
# Copy the ONNX file
cp best.onnx models/onnx/robot_detection.onnx
```

Or on Windows:
```powershell
Copy-Item best.onnx models/onnx/robot_detection.onnx
```

### Step 6: Use the ONNX Model in AutoFactoryScope

Now you can use your trained ONNX model for inference:

```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx" \
  --json --output results.json
```

---

## Quick Reference: Complete Workflow

```mermaid
PNG Images → Annotate (YOLO format) → Train (Python/YOLO) → Export (ONNX) → Use in C# App
```

1. **PNG Images** (`data/raw/Robotfloor*.png`)
2. **Annotate** → Create `.txt` files with bounding boxes
3. **Train** → Run YOLO training in Python
4. **Export** → Convert `.pt` model to `.onnx`
5. **Use** → Load ONNX in AutoFactoryScope for inference

---

## Tips & Best Practices

### Dataset Preparation
- **Minimum dataset size:** 100+ annotated images (more is better)
- **Class balance:** Try to have similar number of objects per class
- **Image diversity:** Include various lighting, angles, backgrounds
- **Validation set:** Use 20-30% of data for validation

### Training
- **Start with pre-trained weights:** Use `yolov8n.pt` or `yolov5s.pt` (transfer learning)
- **Image size:** Match your inference size (640x640 is standard)
- **Epochs:** Start with 50-100 epochs, increase if underfitting
- **Batch size:** Adjust based on GPU memory (16-32 is common)

### ONNX Export
- **Input size:** Must match training size (typically 640x640)
- **Dynamic vs Static:** Static shapes are faster but less flexible
- **Test the ONNX model:** Verify it works before using in C#

### Model Selection
- **YOLOv8n** - Fastest, smallest (good for testing)
- **YOLOv8s** - Balanced speed/accuracy (recommended)
- **YOLOv8m/l/x** - More accurate but slower

---

## Troubleshooting

### ONNX Export Fails
- Ensure you're using a recent version of `ultralytics` or `onnx`
- Check that the model file path is correct
- Try exporting with explicit input shape: `model.export(format='onnx', imgsz=640, dynamic=False)`

### Model Not Detecting Objects
- Verify annotations are correct (check a few `.txt` files)
- Ensure class IDs match between training and inference
- Check confidence threshold (try lowering `--confidence` in CLI)
- Verify image preprocessing matches training (640x640, RGB)

### Low Accuracy
- Add more training data
- Increase training epochs
- Use data augmentation
- Try a larger model (YOLOv8m instead of YOLOv8s)

---

## Resources

- **Ultralytics YOLO Docs:** https://docs.ultralytics.com/
- **YOLOv5 GitHub:** https://github.com/ultralytics/yolov5
- **LabelImg:** https://github.com/HumanSignal/labelImg
- **Roboflow:** https://roboflow.com (annotation + dataset management)
- **ONNX Runtime:** https://onnxruntime.ai/

---

## Example: Complete Training Script

Save as `train_robot_model.py`:

```python
from ultralytics import YOLO
import shutil
import os

# 1. Load pre-trained model
model = YOLO('yolov8n.pt')

# 2. Train
results = model.train(
    data='dataset.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    name='robot_detection',
    patience=20,  # Early stopping
    save=True,
    plots=True
)

# 3. Export to ONNX
best_model = YOLO('runs/detect/robot_detection/weights/best.pt')
best_model.export(format='onnx', imgsz=640)

# 4. Copy to project (adjust path as needed)
onnx_path = 'runs/detect/robot_detection/weights/best.onnx'
target_path = '../models/onnx/robot_detection.onnx'
shutil.copy(onnx_path, target_path)
print(f"ONNX model saved to: {target_path}")
```

Run:
```bash
python train_robot_model.py
```

---

**Last Updated:** November 2025




