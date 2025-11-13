# Smart Annotation Quick Start

## 🎯 Your Workflow: Annotate 36, Get 1,824

**Time:** 2-4 hours (vs 20-30 hours manual!)

---

## ⚡ Quick Steps

### 1. Annotate 36 Originals (2-4 hours)

```powershell
# Create labels directory
New-Item -ItemType Directory -Force -Path "data/raw/labels"

# Annotate using Roboflow or LabelImg
# Save annotations to: data/raw/labels/
```

**Result:** 36 `.txt` files in `data/raw/labels/`

---

### 2. Transform for Rotations (5 minutes)

```powershell
pwsh scripts/transform-annotations-for-rotation.ps1
```

**What it does:**
- Reads 36 original annotations
- Calculates rotated coordinates
- Creates 912 annotations for rotated images

**Result:** 912 `.txt` files in `data/processed/labels/`

---

### 3. Copy for Black Background (2 minutes)

```powershell
pwsh scripts/copy-annotations-for-black-bg.ps1
```

**What it does:**
- Copies annotations (same image = same boxes)
- Creates 912 annotations for black BG images

**Result:** 912 `.txt` files in `data/processed/all_black_bg/labels/`

---

### 4. Merge for Final Dataset (2 minutes)

```powershell
pwsh scripts/merge-annotations-for-final-dataset.ps1
```

**What it does:**
- Combines annotations from both sources
- Matches with `starting_*` and `processed_*` prefixes

**Result:** 1,824 `.txt` files in `data/processed/RobotFloor/labels/`

---

### 5. Verify (5 minutes)

```powershell
pwsh scripts/verify-annotations.ps1 -ImagesDir "data/processed/RobotFloor" -LabelsDir "data/processed/RobotFloor/labels"
```

**Expected:** ✅ All annotations are valid!

---

### 6. Continue with Training

```powershell
# Split dataset
pwsh scripts/split-dataset.ps1

# Train model
python train_robot_model.py
```

---

## 📊 Time Comparison

| Method | Time |
|--------|------|
| Manual (all 1,824) | 20-30 hours |
| **Your method (36 + scripts)** | **2-4 hours** |
| **Time saved** | **16-26 hours!** 🎉 |

---

## ⚠️ Important Notes

1. **Annotate carefully** - Errors in 36 originals multiply to all 1,824
2. **Verify a sample** - Check a few rotated images in LabelImg
3. **Fix if needed** - If transformation looks wrong, adjust script

---

## 🆘 Troubleshooting

**Problem:** Rotated annotations look wrong
- Check a few samples manually
- Verify rotation angles match
- May need to adjust transformation

**Problem:** Missing annotations
- Check original annotations exist
- Verify image filenames match
- Run verification script

---

**Full guide:** `docs/SMART_ANNOTATION_WORKFLOW.md`

