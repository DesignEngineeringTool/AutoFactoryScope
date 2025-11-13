# ONNX Format: Why It's Perfect for AutoFactoryScope

## What is ONNX?

**ONNX (Open Neural Network Exchange)** is an open standard format for representing machine learning models. It allows you to train a model in one framework (like PyTorch, TensorFlow) and use it in another (like ML.NET, ONNX Runtime).

## Why ONNX for This Project?

### ✅ **1. Cross-Platform Compatibility**
- Train in **Python** (YOLO/PyTorch) - industry standard for ML training
- Run inference in **C#** (ML.NET) - your application language
- No need to rewrite models or use Python in production

### ✅ **2. ML.NET Native Support**
- ML.NET has excellent ONNX support via `Microsoft.ML.OnnxTransformer`
- Your code already uses this: `_ml.Transforms.ApplyOnnxModel()`
- Optimized inference engine built-in

### ✅ **3. YOLO Integration**
- YOLO models export to ONNX easily: `model.export(format='onnx')`
- Standard format for object detection models
- Works with YOLOv5, YOLOv8, and other versions

### ✅ **4. Performance**
- ONNX Runtime is highly optimized for inference
- Supports CPU, GPU, and specialized hardware
- Faster than running Python models directly

### ✅ **5. Model Portability**
- Single `.onnx` file contains the entire model
- Easy to version control and deploy
- Can be used across different platforms (Windows, Linux, mobile)

## Workflow Overview

```
┌─────────────────┐
│  Python/YOLO    │  ← Train model here (best tools for ML)
│  Training        │
└────────┬─────────┘
         │ Export
         ▼
┌─────────────────┐
│   .onnx file    │  ← Portable model format
│  (best.onnx)    │
└────────┬─────────┘
         │ Load
         ▼
┌─────────────────┐
│   ML.NET/C#     │  ← Use in your application
│   Inference     │
└─────────────────┘
```

## Alternative Formats (Why NOT to Use)

### ❌ **PyTorch (.pt)**
- Requires Python runtime in production
- Not natively supported by ML.NET
- Larger deployment footprint

### ❌ **TensorFlow (.pb)**
- More complex to use in C#
- Less common for YOLO models
- Requires additional dependencies

### ❌ **ML.NET Native (.zip)**
- Limited to ML.NET ecosystem
- Can't leverage Python training tools
- Less flexible for future changes

### ❌ **TensorFlow Lite (.tflite)**
- Primarily for mobile/edge devices
- Less suitable for server/desktop applications
- Limited YOLO support

## ONNX File Structure

Your ONNX model file contains:
- **Model architecture** (layers, operations)
- **Trained weights** (learned parameters)
- **Input/output specifications** (shapes, types)
- **Metadata** (version, producer info)

## File Location in Project

```
AutoFactoryScope/
└── models/
    └── onnx/
        ├── yolov5s.onnx          # Pre-trained example
        └── robot_detection.onnx  # Your trained model (to be created)
```

## Using ONNX in Your Code

Your `RobotPredictor.cs` already uses ONNX correctly:

```csharp
var pipeline = _ml.Transforms.ApplyOnnxModel(
    modelFile: _onnxPath,                    // Path to .onnx file
    outputColumnNames: new[] { "boxes", "scores", "labels" },
    inputColumnNames: new[] { "images" }
);
```

## Exporting from YOLO

### YOLOv8 (Recommended)
```python
from ultralytics import YOLO

model = YOLO('runs/detect/robot_detection/weights/best.pt')
model.export(format='onnx', imgsz=640)
```

### YOLOv5
```python
import torch

model = torch.hub.load('ultralytics/yolov5', 'custom', 
                       path='runs/train/exp/weights/best.pt')
model.export(format='onnx', imgsz=640)
```

## Verification

After exporting, verify your ONNX model:
```python
import onnx

model = onnx.load('best.onnx')
onnx.checker.check_model(model)
print("Model is valid!")
```

## Summary

**ONNX is the best choice because:**
1. ✅ Industry standard for model portability
2. ✅ Perfect fit for Python training → C# inference workflow
3. ✅ Native ML.NET support
4. ✅ Optimized performance
5. ✅ Single file deployment
6. ✅ Future-proof (works with many frameworks)

**Your current setup is optimal!** Keep using ONNX for all trained models.

---

**Next Steps:**
1. Train YOLO model in Python (see `TRAINING_GUIDE.md`)
2. Export to ONNX format
3. Place in `models/onnx/robot_detection.onnx`
4. Use in your C# application

