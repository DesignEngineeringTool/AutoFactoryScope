# YOLO Module Locations

## 📦 Python Package (ultralytics)

**Location:**
```
C:\Users\georgem\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\site-packages\ultralytics\
```

**Installation:**
```powershell
pip install ultralytics
```

**Version:** 8.3.199 (installed)

---

## 🤖 Trained Model Files

**Location:** `runs/detect/robot_detection/weights/`

**Files:**
- `best.pt` - **21.47 MB** - Best model from training (use this!)
- `last.pt` - **21.47 MB** - Last checkpoint
- `epoch0.pt` - **64.12 MB** - Epoch 0 checkpoint
- `epoch10.pt` - **64.12 MB** - Epoch 10 checkpoint
- `epoch20.pt` - **64.13 MB** - Epoch 20 checkpoint

**Full Path:**
```
C:\Users\georgem\source\repos\AutoFactoryScope\runs\detect\robot_detection\weights\best.pt
```

**Usage:**
```python
from ultralytics import YOLO
model = YOLO('runs/detect/robot_detection/weights/best.pt')
```

---

## 📥 Pre-trained Model Downloads

**Location:** Project root directory

**Files:**
- `yolov8s.pt` - Pre-trained YOLOv8 small model (downloaded automatically)
- `yolo11n.pt` - Pre-trained YOLO11 nano model

**Note:** These are downloaded automatically when you first use them:
```python
model = YOLO('yolov8s.pt')  # Downloads if not found
```

---

## 💾 Model Cache Location

**Default cache:** `C:\Users\georgem\.ultralytics`

This is where ultralytics stores:
- Downloaded pre-trained models
- Cache files
- Temporary files

---

## 📝 Code Files Using YOLO

**Python scripts:**
1. `train_robot_model.py` - Main training script
2. `scripts/pre-annotate-with-model.py` - Pre-annotation helper
3. `scripts/extract-annotations-from-images.py` - Annotation extraction

**Import statement:**
```python
from ultralytics import YOLO
```

---

## 🎯 Quick Reference

### To use the trained model:
```python
from ultralytics import YOLO
model = YOLO('runs/detect/robot_detection/weights/best.pt')
results = model('path/to/image.png')
```

### To export to ONNX:
```python
from ultralytics import YOLO
model = YOLO('runs/detect/robot_detection/weights/best.pt')
model.export(format='onnx')
```

### To check if ultralytics is installed:
```powershell
python -c "import ultralytics; print(ultralytics.__version__)"
```

---

## ⚠️ Important Notes

1. **Model files are large** (20-65 MB each)
2. **They're in .gitignore** - won't be committed to git
3. **Best model is `best.pt`** - use this for inference
4. **Pre-trained models** are cached in `~/.ultralytics`

---

## 🔍 Finding Models

**List all .pt files:**
```powershell
Get-ChildItem -Recurse -Filter "*.pt" | Select-Object FullName, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB, 2)}}
```

**Check ultralytics location:**
```powershell
python -c "import ultralytics; print(ultralytics.__file__)"
```

