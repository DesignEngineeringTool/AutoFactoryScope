# Smart Annotation Workflow: Annotate 36, Get 1,824

## 🎯 Your Brilliant Idea

Instead of annotating all 1,824 images manually, you:
1. **Annotate only 36 original images** (much faster!)
2. **Transform annotations for rotated versions** (automatic!)
3. **Copy annotations for black background versions** (automatic!)

**Time savings:** 20-30 hours → 2-4 hours! 🎉

---

## 📊 Your Dataset Structure

```
36 original images (data/raw/)
   ↓ [Rotate 25 times each]
912 rotated images (data/processed/)
   ↓ [Change background to black]
912 black background images (data/processed/all_black_bg/)
   ↓ [Merge both sets]
1,824 total images (data/processed/RobotFloor/)
```

---

## ✅ Complete Workflow

### Step 1: Annotate Original 36 Images (2-4 hours)

**Location:** `data/raw/` (your 36 original PNG files)

**Create labels directory:**
```powershell
New-Item -ItemType Directory -Force -Path "data/raw/labels"
```

**Annotate using your preferred method:**

**Option A: Roboflow (Fastest)**
1. Go to https://roboflow.com
2. Upload `data/raw/` folder (36 images)
3. Enable AI labeling
4. Annotate all robots
5. Export YOLO format
6. Copy `train/labels/*.txt` to `data/raw/labels/`

**Option B: LabelImg (Manual)**
```bash
pip install labelImg
labelImg
# Open data/raw/, save to data/raw/labels/
# Annotate all 36 images
```

**Option C: Pre-annotation Script**
```bash
pip install ultralytics
# Temporarily point script to data/raw/
python scripts/pre-annotate-with-model.py
# Review and correct
```

**Result:** 36 `.txt` files in `data/raw/labels/`

**Time:** 2-4 hours (vs 20-30 hours for all 1,824!)

---

### Step 2: Transform Annotations for Rotations (5 minutes)

**What this does:**
- Takes annotations from 36 original images
- Calculates where bounding boxes are after rotation
- Creates annotations for all 912 rotated images

**Run the script:**
```powershell
pwsh scripts/transform-annotations-for-rotation.ps1
```

**What happens:**
- Reads original annotations from `data/raw/labels/`
- Finds rotated images in `data/processed/`
- Transforms bounding box coordinates for each rotation angle
- Saves annotations to `data/processed/labels/`

**Expected output:**
```
Found 36 original images
Rotation angles: 25 angles
Expected rotated images: 900
  Processed 900 rotated annotations...
✅ Annotation transformation complete!
```

**Result:** 912 `.txt` files in `data/processed/labels/` (one for each rotated image)

**Time:** 5 minutes (automatic!)

---

### Step 3: Copy Annotations for Black Background (2 minutes)

**What this does:**
- Black background images have same content, just background changed
- Bounding boxes are identical - just copy the annotations!

**Run the script:**
```powershell
pwsh scripts/copy-annotations-for-black-bg.ps1
```

**What happens:**
- Reads annotations from `data/processed/labels/`
- Copies them to `data/processed/all_black_bg/labels/`
- Matches by filename (same image names)

**Expected output:**
```
Found 912 black background images
  Copied 912 annotations...
✅ All annotations copied successfully!
```

**Result:** 912 `.txt` files in `data/processed/all_black_bg/labels/`

**Time:** 2 minutes (automatic!)

---

### Step 4: Merge Annotations for Final Dataset (2 minutes)

**What this does:**
- Your final dataset has images from both sources
- Need to copy annotations to match the merged structure

**Create script to merge annotations:**
```powershell
# scripts/merge-annotations-for-final-dataset.ps1
$source1 = "data/processed/labels"
$source2 = "data/processed/all_black_bg/labels"
$dest = "data/processed/RobotFloor/labels"

New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Copy from rotated images (with starting_ prefix)
Get-ChildItem $source1 -Filter "*.txt" | ForEach-Object {
    $destName = "starting_$($_.Name)"
    Copy-Item $_.FullName (Join-Path $dest $destName)
}

# Copy from black background images (with processed_ prefix)
Get-ChildItem $source2 -Filter "*.txt" | ForEach-Object {
    $destName = "processed_$($_.Name)"
    Copy-Item $_.FullName (Join-Path $dest $destName)
}

Write-Host "✅ Merged annotations complete!"
```

**Run it:**
```powershell
pwsh scripts/merge-annotations-for-final-dataset.ps1
```

**Result:** 1,824 `.txt` files in `data/processed/RobotFloor/labels/`

**Time:** 2 minutes (automatic!)

---

### Step 5: Verify Annotations (5 minutes)

**Check everything is correct:**
```powershell
# Verify final dataset
pwsh scripts/verify-annotations.ps1 -ImagesDir "data/processed/RobotFloor" -LabelsDir "data/processed/RobotFloor/labels"
```

**Expected output:**
```
Found 1824 images
  Total images: 1824
  Has labels: 1824
  Missing labels: 0
  Valid labels: 1824
✅ All annotations are valid!
```

---

### Step 6: Split and Train (Same as Before)

Now proceed with normal training workflow:

```powershell
# Split dataset
pwsh scripts/split-dataset.ps1

# Train model
python train_robot_model.py
```

---

## 🎯 Time Comparison

| Method | Time |
|--------|------|
| **Manual (all 1,824)** | 20-30 hours |
| **Your method (36 + transform)** | **2-4 hours** |
| **Time saved** | **16-26 hours!** 🎉 |

---

## ⚠️ Important Notes

### Coordinate Transformation

**When rotating images:**
- Original image: 640x640 pixels
- Rotated image: Larger canvas (e.g., 905x905 for 45° rotation)
- Bounding boxes need coordinate transformation
- Script handles this automatically

**The math:**
- Rotate corners of bounding box
- Find new bounding box containing rotated corners
- Normalize to new image dimensions

### Verification

**Always verify a sample:**
1. Pick a few rotated images
2. Open in LabelImg
3. Check annotations look correct
4. Adjust script if needed

### Edge Cases

**What if:**
- **Box goes outside image after rotation?** → Script clamps to 0-1 range
- **Box becomes too small?** → May need manual adjustment
- **Rotation looks wrong?** → Check a few samples manually

---

## 🔧 Script Details

### transform-annotations-for-rotation.ps1

**What it does:**
1. Reads original annotations (36 files)
2. For each rotation angle:
   - Calculates rotated image dimensions
   - Transforms bounding box coordinates
   - Accounts for larger canvas
3. Saves annotations for rotated images

**Key function:** `Rotate-BoundingBox`
- Takes original box coordinates
- Rotates corners
- Finds new bounding box
- Normalizes to rotated image size

### copy-annotations-for-black-bg.ps1

**What it does:**
- Simple file copy (same image = same annotations)
- Matches by filename
- Creates labels directory if needed

---

## 📋 Complete Checklist

- [ ] Annotate 36 original images → `data/raw/labels/`
- [ ] Transform for rotations → `data/processed/labels/`
- [ ] Copy for black background → `data/processed/all_black_bg/labels/`
- [ ] Merge for final dataset → `data/processed/RobotFloor/labels/`
- [ ] Verify all annotations
- [ ] Split dataset
- [ ] Train model

---

## 🎓 How It Works (For Learning)

### Rotation Transformation

**Original image (640x640):**
```
Robot at: center_x=0.5, center_y=0.5, width=0.1, height=0.15
```

**After 90° rotation (905x905 canvas):**
```
Robot at: center_x=0.5, center_y=0.5, width=0.15, height=0.1
(Width and height swap, but normalized coordinates stay similar)
```

**The script:**
1. Converts normalized → pixel coordinates
2. Rotates corners
3. Finds new bounding box
4. Converts back to normalized

### Black Background

**No transformation needed!**
- Same image content
- Same robot positions
- Just background color changed
- Copy annotations directly

---

## 🆘 Troubleshooting

### Problem: "Rotated annotations look wrong"

**Solution:**
1. Check a few samples in LabelImg
2. Verify rotation angles match
3. May need to adjust transformation math
4. Check if images were formatted before rotation

### Problem: "Some annotations missing"

**Solution:**
1. Check original annotations exist
2. Verify rotated images exist
3. Check filename matching
4. Run verification script

### Problem: "Boxes outside image after rotation"

**Solution:**
- Script clamps to 0-1 range
- May need to manually adjust edge cases
- Or crop boxes that go outside

---

## ✅ Benefits of Your Approach

1. **Massive time savings** - 2-4 hours vs 20-30 hours
2. **Consistent annotations** - All rotations have correct boxes
3. **Less error-prone** - No manual mistakes on 1,824 images
4. **Easy to update** - Fix 36, regenerate all
5. **Scalable** - Add more rotations easily

---

## 🎯 Summary

**Your workflow:**
```
36 originals → Annotate (2-4 hours)
   ↓
912 rotated → Transform annotations (5 min, automatic)
   ↓
912 black BG → Copy annotations (2 min, automatic)
   ↓
1,824 total → Ready for training!
```

**Total time:** 2-4 hours (vs 20-30 hours manual)

**This is a brilliant approach!** 🎉

---

**Next Steps:**
1. Annotate the 36 originals
2. Run transformation scripts
3. Verify a sample
4. Proceed with training

See `docs/BEGINNER_GUIDE.md` for training steps.

---

**Last Updated:** 2025

