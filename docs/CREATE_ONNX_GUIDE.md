# Complete Guide: Creating the ONNX File

This guide walks you through creating the ONNX model file from your trained YOLO model in the AutoFactoryScope project.

---

## 🎯 Overview

**What is ONNX?**  
ONNX (Open Neural Network Exchange) is a format that allows your trained YOLO model to run in C# applications. It's the bridge between Python training and C# inference.

**Why ONNX?**  
- ✅ Works directly with ML.NET and ONNX Runtime in C#
- ✅ No Python runtime needed in production
- ✅ Optimized for inference
- ✅ Cross-platform compatible

**Current Status:**
- ✅ Model trained: `runs/detect/robot_detection/weights/best.pt`
- ✅ ONNX export script ready: `export_onnx.py`
- ✅ Target location: `models/onnx/robot_detection.onnx`

---

## 📋 Prerequisites

### Required

- [ ] **Trained model exists:** `runs/detect/robot_detection/weights/best.pt`
- [ ] **Python 3.8+** installed
- [ ] **Ultralytics installed:** `pip install ultralytics`

### Optional (for verification)

- [ ] **ONNX package:** `pip install onnx` (for validation)
- [ ] **ONNX Runtime:** `pip install onnxruntime` (for testing)

---

## 🚀 Method 1: Standard Export (Recommended)

### Step 1: Verify Trained Model Exists

```powershell
# Check if trained model exists
Test-Path "runs/detect/robot_detection/weights/best.pt"
```

**Expected:** `True`

**If False:** You need to train the model first. See `docs/BEGINNER_GUIDE.md`.

### Step 2: Install Dependencies

```powershell
# Install ultralytics (if not already installed)
pip install ultralytics

# Optional: Install ONNX for validation
pip install onnx
```

### Step 3: Run Export Script

**Option A: Using the provided script (easiest)**

```powershell
python export_onnx.py
```

**Option B: Manual export**

```powershell
python -c "from ultralytics import YOLO; model = YOLO('runs/detect/robot_detection/weights/best.pt'); model.export(format='onnx', imgsz=640, simplify=True, opset=12)"
```

**Expected Output:**
```
Loading best model...
Exporting to ONNX...
✅ ONNX model exported: runs/detect/robot_detection/weights/best.onnx
   Size: 42.67 MB
```

### Step 4: Copy to Project Directory

```powershell
# Create directory if it doesn't exist
if (-not (Test-Path "models/onnx")) {
    New-Item -ItemType Directory -Force -Path "models/onnx" | Out-Null
}

# Copy ONNX file
Copy-Item "runs/detect/robot_detection/weights/best.onnx" "models/onnx/robot_detection.onnx" -Force

# Verify
Test-Path "models/onnx/robot_detection.onnx"
```

**Expected:** `True`

### Step 5: Verify ONNX File

```powershell
# Check file size (should be ~40-45 MB)
$file = Get-Item "models/onnx/robot_detection.onnx"
Write-Host "File size: $([math]::Round($file.Length / 1MB, 2)) MB"
```

**Expected:** ~42.7 MB

**Validate ONNX structure (optional):**
```powershell
python -c "import onnx; model = onnx.load('models/onnx/robot_detection.onnx'); onnx.checker.check_model(model); print('✅ ONNX model is valid'); print(f'Input: {[i.name for i in model.graph.input]}'); print(f'Output: {[o.name for o in model.graph.output]}')"
```

**Expected Output:**
```
✅ ONNX model is valid
Input: ['images']
Output: ['output0']
```

---

## 🔧 Method 2: Export with PowerShell Script

### Using the Automated Script

```powershell
pwsh scripts/export-and-share-onnx.ps1
```

**This script:**
1. Exports model to ONNX
2. Copies to `models/onnx/robot_detection.onnx`
3. Verifies the file
4. Shows file size

---

## ⚠️ Method 3: Windows Path Length Workaround

**Problem:** Windows 260-character path limit can cause ONNX installation to fail.

**Symptoms:**
- `No module named 'onnx'`
- `No module named 'onnx.defs'`
- Partial installation errors

### Solution: Install ONNX to Short Path

**Step 1: Install ONNX to shorter path**

```powershell
# Run the fix script
pwsh scripts/fix-onnx-install.ps1
```

**Or manually:**
```powershell
# Create short path
$env:PIP_TARGET = "C:\packages"
pip install onnx onnxslim --target C:\packages

# Add to Python path
$env:PYTHONPATH = "C:\packages;$env:PYTHONPATH"
```

**Step 2: Export using short path**

```powershell
# Use the short path export script
pwsh scripts/export-onnx-short-path.ps1
```

**This script:**
- Sets `PYTHONPATH` to include `C:\packages`
- Runs the export
- Copies to project directory

---

## 📝 Export Options Explained

The `export_onnx.py` script uses these options:

```python
model.export(
    format='onnx',        # Export format
    imgsz=640,            # Input image size (must match training)
    simplify=True,       # Optimize ONNX graph (recommended)
    opset=12,            # ONNX operator set version (12 is widely supported)
    half=False           # Use FP32 (more accurate) or FP16 (faster)
)
```

### Option Details

**`imgsz=640`**
- Input image size in pixels
- Must match training size
- 640x640 is standard for YOLO

**`simplify=True`**
- Optimizes the ONNX graph
- Reduces file size slightly
- Improves inference speed
- **Recommended:** Always use

**`opset=12`**
- ONNX operator set version
- 12 is widely supported by ONNX Runtime
- Higher versions (17+) may have compatibility issues
- **Recommended:** Use 12 for compatibility

**`half=False`**
- `False` = FP32 (32-bit floats, more accurate)
- `True` = FP16 (16-bit floats, faster, smaller file)
- **Recommended:** Use `False` for accuracy

### Advanced Options

**Dynamic batch size:**
```python
model.export(
    format='onnx',
    imgsz=640,
    dynamic=True,  # Allows variable batch sizes
    simplify=True,
    opset=12
)
```

**Note:** Dynamic is slower but more flexible. Use `False` (static) for better performance.

**FP16 quantization:**
```python
model.export(
    format='onnx',
    imgsz=640,
    half=True,  # Use FP16 (faster, smaller)
    simplify=True,
    opset=12
)
```

**Note:** FP16 may reduce accuracy slightly but improves speed and reduces file size.

---

## ✅ Verification Checklist

After export, verify:

- [ ] **File exists:** `Test-Path "models/onnx/robot_detection.onnx"` → `True`
- [ ] **File size:** ~40-45 MB (not 0 bytes or very small)
- [ ] **ONNX structure valid:** No errors when loading with `onnx.load()`
- [ ] **Input/Output correct:** Input `images`, Output `output0`
- [ ] **C# can load:** Test with `RobotPredictor.Load()`

### Quick Verification Script

```powershell
# Complete verification
Write-Host "=== ONNX Verification ===" -ForegroundColor Cyan

# Check file exists
if (Test-Path "models/onnx/robot_detection.onnx") {
    Write-Host "✅ File exists" -ForegroundColor Green
    
    # Check file size
    $size = (Get-Item "models/onnx/robot_detection.onnx").Length / 1MB
    Write-Host "✅ File size: $([math]::Round($size, 2)) MB" -ForegroundColor Green
    
    if ($size -lt 1) {
        Write-Host "⚠️  WARNING: File is too small (may be corrupted)" -ForegroundColor Yellow
    }
    
    # Validate ONNX structure
    python -c "import onnx; model = onnx.load('models/onnx/robot_detection.onnx'); onnx.checker.check_model(model); print('✅ ONNX structure is valid')" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ONNX model is valid and ready to use!" -ForegroundColor Green
    } else {
        Write-Host "❌ ONNX validation failed" -ForegroundColor Red
    }
} else {
    Write-Host "❌ File not found" -ForegroundColor Red
}
```

---

## 🧪 Test the ONNX Model

### Test in Python (Optional)

```python
from ultralytics import YOLO
import numpy as np

# Load ONNX model
model = YOLO('models/onnx/robot_detection.onnx')

# Test on an image
results = model('data/test/images/Robotfloor1.png')

# Print results
print(f"Detected {len(results[0].boxes)} robots")
```

### Test in C# (Required)

```powershell
# Test with CLI
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx" `
  --confidence 0.3
```

**Expected Output:**
```
[INFO] Robot count: 2
[INFO] Detection complete!
```

**Or use the test script:**
```powershell
pwsh scripts/test-model.ps1
```

---

## 🐛 Troubleshooting

### Problem: "No module named 'onnx'"

**Solution 1: Install ONNX**
```powershell
pip install onnx
```

**Solution 2: Use short path workaround**
```powershell
pwsh scripts/fix-onnx-install.ps1
pwsh scripts/export-onnx-short-path.ps1
```

**Solution 3: Use Conda**
```powershell
conda install -c conda-forge onnx
```

### Problem: "No module named 'onnx.defs'"

**Cause:** Partial ONNX installation due to Windows path length limit.

**Solution:**
```powershell
# Use short path installation
pwsh scripts/fix-onnx-install.ps1
```

### Problem: "Model file not found"

**Check:**
```powershell
# Verify trained model exists
Test-Path "runs/detect/robot_detection/weights/best.pt"
```

**If False:** Train the model first:
```powershell
python train_robot_model.py
```

### Problem: "Export failed" or "ONNX file not found after export"

**Check:**
1. **Ultralytics version:**
   ```powershell
   pip install --upgrade ultralytics
   ```

2. **Check export location:**
   ```powershell
   # ONNX should be created here:
   Test-Path "runs/detect/robot_detection/weights/best.onnx"
   ```

3. **Check disk space:**
   ```powershell
   # Ensure you have at least 100 MB free
   Get-PSDrive C | Select-Object Used,Free
   ```

4. **Try manual export:**
   ```python
   from ultralytics import YOLO
   model = YOLO('runs/detect/robot_detection/weights/best.pt')
   model.export(format='onnx', imgsz=640, simplify=True, opset=12)
   ```

### Problem: "Invalid ONNX model" in C#

**Check:**
1. **File size:** Should be ~40-45 MB, not 0 bytes
2. **File corruption:** Re-export the model
3. **Wrong file:** Ensure using `robot_detection.onnx`, not `yolov5s.onnx`

**Solution:**
```powershell
# Re-export
python export_onnx.py

# Verify
python -c "import onnx; onnx.checker.check_model(onnx.load('models/onnx/robot_detection.onnx'))"
```

### Problem: "No graph was found in the protobuf"

**Cause:** Corrupted or invalid ONNX file.

**Solution:**
1. Delete the corrupted file
2. Re-export from `best.pt`
3. Verify export succeeded before using

---

## 📊 Export Process Flow

```
┌─────────────────────────────────┐
│  Trained Model                  │
│  best.pt (PyTorch)              │
│  Location: runs/detect/.../    │
└──────────────┬──────────────────┘
               │
               │ export(format='onnx')
               ▼
┌─────────────────────────────────┐
│  ONNX Export                    │
│  - Converts PyTorch → ONNX      │
│  - Optimizes graph              │
│  - Validates structure          │
└──────────────┬──────────────────┘
               │
               │ Creates
               ▼
┌─────────────────────────────────┐
│  ONNX Model                     │
│  best.onnx                      │
│  Location: runs/detect/.../     │
└──────────────┬──────────────────┘
               │
               │ Copy
               ▼
┌─────────────────────────────────┐
│  Project ONNX Model             │
│  robot_detection.onnx           │
│  Location: models/onnx/         │
└──────────────┬──────────────────┘
               │
               │ Use in C#
               ▼
┌─────────────────────────────────┐
│  C# Application                  │
│  RobotPredictor.Load()          │
│  RobotPredictor.Predict()       │
└─────────────────────────────────┘
```

---

## 🎯 Quick Reference

### Standard Export (One Command)

```powershell
python export_onnx.py && Copy-Item "runs/detect/robot_detection/weights/best.onnx" "models/onnx/robot_detection.onnx" -Force
```

### Export with PowerShell Script

```powershell
pwsh scripts/export-and-share-onnx.ps1
```

### Export with Windows Path Fix

```powershell
pwsh scripts/fix-onnx-install.ps1
pwsh scripts/export-onnx-short-path.ps1
```

### Verify Export

```powershell
Test-Path "models/onnx/robot_detection.onnx"
python -c "import onnx; onnx.checker.check_model(onnx.load('models/onnx/robot_detection.onnx')); print('✅ Valid')"
```

### Test in C#

```powershell
dotnet run --project src/AutoFactoryScope.CLI -- --image "data/test/images/Robotfloor1.png" --model "models/onnx/robot_detection.onnx"
```

---

## 📚 Related Documentation

- **`docs/ONNX_EXPLANATION.md`** - What is ONNX and why use it
- **`docs/ONNX_EXPORT_ISSUE.md`** - Windows path length troubleshooting
- **`docs/ONNX_COMPLETE_GUIDE.md`** - Complete ONNX workflow
- **`docs/BEGINNER_GUIDE.md`** - Full training and export guide
- **`export_onnx.py`** - Export script source code

---

## ✅ Success Checklist

You're done when:

- [ ] ONNX file created: `models/onnx/robot_detection.onnx`
- [ ] File size: ~40-45 MB (not 0 bytes)
- [ ] ONNX structure validated (no errors)
- [ ] C# application can load the model
- [ ] Detection works on test images

---

## 🎉 Next Steps

After successful export:

1. **Test the model:**
   ```powershell
   pwsh scripts/test-model.ps1
   ```

2. **Use in your application:**
   ```csharp
   var predictor = new RobotPredictor("models/onnx/robot_detection.onnx");
   var result = predictor.Predict(imageBytes, 640, "image.png");
   ```

3. **Commit to Git:**
   ```powershell
   git add models/onnx/robot_detection.onnx
   git commit -m "Add trained ONNX model"
   git push
   ```

---

**Last Updated:** Current Session  
**Status:** ✅ Production Ready  
**Model Location:** `models/onnx/robot_detection.onnx`

---

**Need help?** Check troubleshooting section above or see `docs/ONNX_EXPORT_ISSUE.md` for Windows-specific issues.

