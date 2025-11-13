# Quick Start Guide

## 🚀 Get Started in 5 Steps

### Step 1: Split Dataset
```powershell
pwsh scripts/split-dataset.ps1
```

### Step 2: Annotate Images (Choose ONE method)

**Fastest - Roboflow:**
1. Go to https://roboflow.com
2. Upload `data/training/images/`
3. Enable AI labeling
4. Review and correct
5. Export YOLO format

**Or - Pre-annotation script:**
```bash
pip install ultralytics
python scripts/pre-annotate-with-model.py
# Then review and correct annotations
```

**Or - Manual (LabelImg):**
```bash
pip install labelImg
labelImg
# Open data/training/images/, save to data/training/labels/
```

### Step 3: Verify Annotations
```powershell
pwsh scripts/verify-annotations.ps1
```

### Step 4: Train Model
```bash
pip install ultralytics
python train_robot_model.py
```

### Step 5: Test in C#
```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/images/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx"
```

---

## 📚 Full Documentation

**Start here:** `docs/BEGINNER_GUIDE.md` - Complete step-by-step guide

**Other guides:**
- `docs/ANNOTATION_EXPLAINED.md` - What is annotation?
- `docs/FAST_ANNOTATION_GUIDE.md` - Speed up annotation
- `docs/ONNX_COMPLETE_GUIDE.md` - Complete ONNX workflow
- `docs/NEXT_STEPS.md` - Overview of all steps

---

## ⏱️ Time Estimates

- Split dataset: 5 min
- Annotate (AI-assisted): 5-10 hours
- Annotate (manual): 20-30 hours
- Train model: 1-4 hours
- Test: 5 min

**Total: ~12-25 hours** (mostly annotation)

---

## 🆘 Need Help?

1. Read `docs/BEGINNER_GUIDE.md` first
2. Check troubleshooting section
3. Verify each step before moving to next
4. Test frequently

---

**Ready? Start with:** `docs/BEGINNER_GUIDE.md`

