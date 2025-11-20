# Quick Start: Annotation Pipeline for 36 PNG Files

This guide walks you through annotating your 36 PNG files and running the complete pipeline to get an ONNX model.

## 🎯 Overview

**Goal:** Annotate 36 original PNG files → Process images → Train model → Export ONNX

**Time:** 
- Annotation: 2-4 hours (36 files)
- Processing: 10-30 minutes (automatic)
- Training: 1-4 hours (automatic)

**Total: ~4-9 hours** (mostly annotation)

---

## Step 1: Setup Annotation Workflow (2 minutes)

```powershell
pwsh scripts/setup-annotation-workflow.ps1
```

This will:
- Check your 36 PNG files
- Create labels directory structure
- Show you which files need annotation
- Provide instructions for annotation tools

**Output:**
```
Found 36 PNG files
Created labels directory: data/raw/RobotFloor/labels
Missing annotations: 36
```

---

## Step 2: Annotate Images (2-4 hours)

You have 3 options:

### Option A: LabelImg (Recommended for beginners)

```powershell
# Install
pip install labelImg

# Launch helper script
pwsh scripts/launch-labelimg.ps1

# Or run manually
labelImg
```

**In LabelImg:**
1. Click "Open Dir" → Select `data/raw/RobotFloor`
2. Click "Change Save Dir" → Select `data/raw/RobotFloor/labels`
3. **IMPORTANT:** Set format to **"YOLO"** (not PascalVOC)
4. Press `W` to draw bounding box
5. Draw box around each robot
6. Label as "robot" (class 0)
7. Press `Ctrl+S` to save
8. Press `D` to go to next image

**Keyboard shortcuts:**
- `W` - Create box
- `D` - Next image
- `A` - Previous image
- `Del` - Delete box
- `Ctrl+S` - Save

### Option B: Pre-annotation with AI (Faster)

```powershell
# Install
pip install ultralytics

# Run pre-annotation
python scripts/pre-annotate-with-model.py

# Then review and correct in LabelImg
pwsh scripts/launch-labelimg.ps1
```

This uses a pre-trained model to auto-annotate, then you review and correct (much faster!).

### Option C: Roboflow (Web-based, AI-assisted)

1. Go to https://roboflow.com
2. Create project "Robot Detection"
3. Upload your 36 PNG files
4. Enable AI-assisted labeling
5. Review and correct
6. Export in YOLO format
7. Extract to `data/raw/RobotFloor/labels/`

---

## Step 3: Validate Annotations (1 minute)

```powershell
pwsh scripts/validate-yolo-annotations.ps1
```

This checks:
- All files have correct format
- Values are in valid range (0-1)
- Bounding boxes don't extend outside image

**Expected output:**
```
✅ All annotations are valid!
```

---

## Step 4: Run Complete Pipeline (Automatic)

This single command does everything:
- Processes images (rotate, black background)
- Transforms annotations for rotations
- Copies annotations for black background
- Merges annotations for final dataset
- Splits dataset (train/val/test)
- Trains YOLO model
- Exports to ONNX

```powershell
pwsh scripts/complete-annotation-pipeline.ps1
```

**Or run step-by-step:**

```powershell
# Step 4a: Process images
pwsh scripts/complete-pipeline.ps1

# Step 4b: Transform annotations
pwsh scripts/transform-annotations-for-rotation.ps1

# Step 4c: Copy for black background
pwsh scripts/copy-annotations-for-black-bg.ps1

# Step 4d: Merge annotations
pwsh scripts/merge-annotations-for-final-dataset.ps1

# Step 4e: Verify
pwsh scripts/verify-annotations.ps1 -ImagesDir "data/processed/RobotFloor" -LabelsDir "data/processed/RobotFloor/labels"

# Step 4f: Split dataset
pwsh scripts/split-dataset.ps1

# Step 4g: Train and export ONNX
python train_robot_model.py
```

---

## Step 5: Verify ONNX Model

After training completes, check:

```powershell
# Check if ONNX file exists
Test-Path "models/onnx/robot_detection.onnx"

# Or check training output
Test-Path "runs/detect/robot_detection/weights/best.onnx"
```

**Expected:**
- ONNX file: `models/onnx/robot_detection.onnx` (~20-50 MB)
- Training results: `runs/detect/robot_detection/`

---

## Step 6: Test in C# Application

```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx"
```

---

## 📋 YOLO Format Reference

Each annotation file (`.txt`) contains one line per robot:

```
class_id center_x center_y width height
```

**Example:** `Robotfloor1.txt`
```
0 0.5 0.5 0.1 0.15
0 0.3 0.7 0.08 0.12
```

**What each value means:**
- `0` = Class ID (0 = robot)
- `0.5 0.5` = Center of bounding box (50% from left, 50% from top)
- `0.1 0.15` = Width and height (10% of image width, 15% of image height)

**Important:** All values are **normalized** (0.0 to 1.0), not pixels!

---

## 🆘 Troubleshooting

### "No annotation files found"
- Make sure you saved annotations in `data/raw/RobotFloor/labels/`
- Check file names match: `Robotfloor1.png` → `Robotfloor1.txt`

### "Invalid format in annotation"
- Run: `pwsh scripts/validate-yolo-annotations.ps1`
- Check format: 5 values per line (class_id center_x center_y width height)
- All values except class_id must be 0.0 to 1.0

### "Training failed"
- Check `dataset.yaml` exists
- Verify images and labels are in correct directories
- Check Python and ultralytics are installed: `pip install ultralytics`

### "ONNX export failed"
- Update ultralytics: `pip install --upgrade ultralytics`
- Check training completed successfully first

---

## 📁 Directory Structure

After completing the pipeline:

```
data/
├── raw/
│   └── RobotFloor/
│       ├── Robotfloor1.png ... Robotfloor36.png
│       └── labels/
│           ├── Robotfloor1.txt ... Robotfloor36.txt
├── processed/
│   └── RobotFloor/
│       ├── [1824 processed images]
│       └── labels/
│           └── [1824 annotation files]
├── training/
│   ├── images/ [~1277 images]
│   └── labels/ [~1277 annotations]
├── validation/
│   ├── images/ [~365 images]
│   └── labels/ [~365 annotations]
└── test/
    ├── images/ [~182 images]
    └── labels/ [~182 annotations]

models/
└── onnx/
    └── robot_detection.onnx [Final ONNX model]
```

---

## ✅ Success Checklist

- [ ] 36 PNG files annotated in `data/raw/RobotFloor/labels/`
- [ ] Annotations validated: `pwsh scripts/validate-yolo-annotations.ps1`
- [ ] Pipeline completed: `pwsh scripts/complete-annotation-pipeline.ps1`
- [ ] Dataset split into train/val/test
- [ ] Model trained (mAP > 0.7)
- [ ] ONNX model exported: `models/onnx/robot_detection.onnx`
- [ ] Model tested in C# application

---

## 🎉 You're Done!

Your ONNX model is ready to use in the C# application!

**Next steps:**
- Test on more images
- Fine-tune model if needed (adjust epochs, batch size)
- Deploy to production

---

**Questions?** See:
- `docs/ANNOTATION_EXPLAINED.md` - What is annotation?
- `docs/TRAINING_GUIDE.md` - Training details
- `docs/ONNX_COMPLETE_GUIDE.md` - ONNX workflow

