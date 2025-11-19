# Step-by-Step Guide: Augmenting 38 Annotated Images

**For Rinesh** - Complete guide to augment your 38 annotated images with rotations and black backgrounds.

---

## 🎯 Overview

**What we're doing:**
1. Take your 38 annotated images from `data/raw/RobotFloor/`
2. Rotate them at various angles (15°, 30°, 45°, etc.)
3. Change backgrounds to black
4. Transform annotations correctly for rotations
5. Create a large augmented dataset

**Result:**
- **38 original images** → **~1,824 augmented images**
- All with correct annotations
- Ready for training

---

## ✅ Prerequisites

Before starting, make sure you have:

- [ ] **38 PNG images** in `data/raw/RobotFloor/`
- [ ] **38 annotation files** (.txt) in `data/raw/RobotFloor/labels/`
- [ ] **PowerShell 7+** installed
- [ ] **.NET Framework** (for image processing)

**Check your setup:**
```powershell
# Navigate to project root
cd C:\Users\Rinesh.Sewpal\Source\Repos\AutoFactoryScope

# Check images
Get-ChildItem "data/raw/RobotFloor" -Filter "*.png" | Measure-Object
# Should show: 38

# Check annotations
Get-ChildItem "data/raw/RobotFloor/labels" -Filter "*.txt" | Measure-Object
# Should show: 38
```

---

## 🚀 Step-by-Step Instructions

### Step 1: Verify Your Annotations

**Before starting, make sure all 38 images have annotations:**

```powershell
# Check annotation count
$images = Get-ChildItem "data/raw/RobotFloor" -Filter "*.png"
$labels = Get-ChildItem "data/raw/RobotFloor/labels" -Filter "*.txt"

Write-Host "Images: $($images.Count)"
Write-Host "Labels: $($labels.Count)"

if ($images.Count -ne $labels.Count) {
    Write-Host "⚠️  WARNING: Some images are missing annotations!" -ForegroundColor Yellow
    Write-Host "Please annotate all images before continuing." -ForegroundColor Yellow
}
```

**Expected:** Both should show 38.

**If some are missing:** Annotate them first using LabelImg or your annotation tool.

---

### Step 2: Run the Augmentation Pipeline

**This is the main step - it does everything automatically:**

```powershell
# Run the augmentation pipeline
pwsh scripts/augment-annotated-images.ps1
```

**What this does:**
1. ✅ Formats images to 640x640
2. ✅ Creates rotated versions (23 different angles)
3. ✅ Transforms annotations for rotations
4. ✅ Creates black background versions
5. ✅ Copies annotations for black backgrounds
6. ✅ Merges everything to final directory

**Time:** ~10-30 minutes (depending on your computer)

**Expected Output:**
```
========================================
Augment Annotated Images Pipeline
========================================

=== Step 0: Verifying Prerequisites ===
✅ Found 38 PNG images
✅ Found 38 annotation files

=== Step 1: Formatting Original Images (640x640) ===
✅ Formatted 38 images

=== Step 2: Creating Rotated Images ===
✅ Created 874 rotated images

=== Step 3: Transforming Annotations for Rotations ===
✅ Annotations transformed for rotations

=== Step 4: Creating Black Background Versions ===
✅ Created black background versions

=== Step 5: Copying Annotations for Black Background ===
✅ Copied annotations for black background versions

=== Step 6: Merging to Final Directory ===

=== Summary ===
  Original images: 38
  Final images: 1824
  Final annotations: 1824
  Augmentation multiplier: 48.00x

✅ Augmentation pipeline complete!
```

---

### Step 3: Verify the Results

**Check that everything was created correctly:**

```powershell
# Check final images
$finalImages = Get-ChildItem "data/processed/RobotFloor" -Filter "*.png"
Write-Host "Final images: $($finalImages.Count)"
# Should be ~1,824

# Check final annotations
$finalLabels = Get-ChildItem "data/processed/RobotFloor/labels" -Filter "*.txt"
Write-Host "Final annotations: $($finalLabels.Count)"
# Should be ~1,824

# Verify they match
if ($finalImages.Count -eq $finalLabels.Count) {
    Write-Host "✅ Perfect! All images have annotations." -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: Image and annotation counts don't match!" -ForegroundColor Yellow
}
```

**Expected:** Both should show ~1,824.

---

### Step 4: Verify Annotation Quality (Optional but Recommended)

**Spot-check a few rotated images to make sure annotations are correct:**

```powershell
# Open a rotated image and its annotation
# Example: Check Robotfloor1 rotated 90 degrees

# View the annotation file
Get-Content "data/processed/RobotFloor/labels/starting_Robotfloor1_rot90.txt"

# Should show transformed coordinates
# Format: class_id center_x center_y width height
```

**What to check:**
- Annotations exist for rotated images
- Coordinates look reasonable (all values between 0 and 1)
- No obvious errors

**If you see issues:** Check the troubleshooting section below.

---

### Step 5: Split Dataset (Next Step)

**After augmentation, split into train/validation/test:**

```powershell
# Split the dataset
pwsh scripts/split-dataset.ps1 -SourceDir "data/processed/RobotFloor"
```

**This will:**
- Create `data/training/` (70% of images)
- Create `data/validation/` (20% of images)
- Create `data/test/` (10% of images)

---

## 📊 Understanding the Output

### Directory Structure

After running the pipeline, you'll have:

```
data/
├── raw/RobotFloor/              # Your original 38 images
│   ├── Robotfloor1.png
│   ├── Robotfloor2.png
│   └── ... (38 total)
│   └── labels/                   # Your original 38 annotations
│       ├── Robotfloor1.txt
│       └── ... (38 total)
│
└── processed/RobotFloor/        # Augmented dataset (~1,824 images)
    ├── starting_Robotfloor1.png          # Original formatted
    ├── starting_Robotfloor1_rot15.png     # Rotated 15°
    ├── starting_Robotfloor1_rot30.png     # Rotated 30°
    ├── ... (many rotated versions)
    ├── processed_Robotfloor1.png          # Black background
    ├── processed_Robotfloor1_rot15.png    # Rotated + black background
    └── ... (~1,824 total)
    └── labels/                            # All annotations
        ├── starting_Robotfloor1.txt
        ├── starting_Robotfloor1_rot15.txt
        └── ... (~1,824 total)
```

### Image Naming Convention

- **`starting_*`** = Original formatted images (white background)
- **`starting_*_rot<angle>`** = Rotated versions (white background)
- **`processed_*`** = Black background versions
- **`processed_*_rot<angle>`** = Rotated + black background

### Rotation Angles

The pipeline creates rotated versions at these angles:
- **15°, 30°, 45°, 60°, 75°, 90°, 105°, 120°, 135°, 150°, 165°, 180°**
- **195°, 210°, 225°, 240°, 255°, 270°, 285°, 300°, 315°, 330°, 345°**

**Total: 23 rotation angles per image**

---

## 🐛 Troubleshooting

### Problem: "No PNG files found"

**Solution:**
```powershell
# Check if images exist
Test-Path "data/raw/RobotFloor"

# Check if they're PNG files
Get-ChildItem "data/raw/RobotFloor" -Filter "*.png"
```

**Fix:** Make sure your 38 images are in `data/raw/RobotFloor/` and are PNG files.

---

### Problem: "Labels directory not found"

**Solution:**
```powershell
# Create labels directory if missing
New-Item -ItemType Directory -Force -Path "data/raw/RobotFloor/labels"

# Then annotate your images
```

**Fix:** Annotate all 38 images first before running the pipeline.

---

### Problem: "Annotation count mismatch"

**Solution:**
```powershell
# Find which images are missing annotations
$images = Get-ChildItem "data/raw/RobotFloor" -Filter "*.png"
$labels = Get-ChildItem "data/raw/RobotFloor/labels" -Filter "*.txt"

foreach ($img in $images) {
    $labelName = $img.BaseName + ".txt"
    $labelPath = Join-Path "data/raw/RobotFloor/labels" $labelName
    if (-not (Test-Path $labelPath)) {
        Write-Host "Missing: $labelName" -ForegroundColor Yellow
    }
}
```

**Fix:** Create missing annotation files (even if empty - use empty file for images with no robots).

---

### Problem: "Failed to rotate image"

**Cause:** Image file might be corrupted or in wrong format.

**Solution:**
```powershell
# Check image file
$img = [System.Drawing.Bitmap]::FromFile("data/raw/RobotFloor/Robotfloor1.png")
Write-Host "Width: $($img.Width), Height: $($img.Height)"
$img.Dispose()
```

**Fix:** Re-save the image as PNG if it's corrupted.

---

### Problem: Annotations look wrong after rotation

**Cause:** Annotation transformation might have issues.

**Solution:**
1. Check a few rotated images manually
2. Compare original vs rotated annotations
3. If consistently wrong, check the rotation script

**To verify:**
```powershell
# Compare original and rotated annotation
Write-Host "Original:"
Get-Content "data/raw/RobotFloor/labels/Robotfloor1.txt"

Write-Host "Rotated 90°:"
Get-Content "data/processed/RobotFloor/labels/starting_Robotfloor1_rot90.txt"
```

**Fix:** If annotations are consistently wrong, we may need to adjust the transformation script.

---

### Problem: Pipeline takes too long

**Cause:** Processing 1,824 images takes time.

**Solutions:**
1. **Be patient** - It's normal to take 10-30 minutes
2. **Check progress** - The script shows progress every 50 images
3. **Run overnight** - If needed, let it run overnight

**To check progress:**
```powershell
# Check how many images have been created
Get-ChildItem "data/processed/RobotFloor" -Filter "*.png" | Measure-Object
```

---

### Problem: Out of disk space

**Cause:** 1,824 images can take significant space.

**Solution:**
```powershell
# Check disk space
Get-PSDrive C | Select-Object Used,Free

# Check current size
$size = (Get-ChildItem "data/processed/RobotFloor" -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "Current size: $([math]::Round($size, 2)) GB"
```

**Fix:** Free up disk space or use a different drive.

---

## ✅ Success Checklist

After running the pipeline, verify:

- [ ] **38 original images** in `data/raw/RobotFloor/`
- [ ] **~1,824 final images** in `data/processed/RobotFloor/`
- [ ] **~1,824 annotation files** in `data/processed/RobotFloor/labels/`
- [ ] **Image and annotation counts match**
- [ ] **Sample annotations look correct** (spot-check a few)
- [ ] **No errors in the pipeline output**

---

## 🎯 Next Steps

After successful augmentation:

1. **Split dataset:**
   ```powershell
   pwsh scripts/split-dataset.ps1 -SourceDir "data/processed/RobotFloor"
   ```

2. **Train model:**
   ```powershell
   python train_robot_model.py
   ```

3. **Export to ONNX:**
   ```powershell
   python export_onnx.py
   ```

---

## 📞 Quick Reference

**Run augmentation:**
```powershell
pwsh scripts/augment-annotated-images.ps1
```

**Check results:**
```powershell
Get-ChildItem "data/processed/RobotFloor" -Filter "*.png" | Measure-Object
Get-ChildItem "data/processed/RobotFloor/labels" -Filter "*.txt" | Measure-Object
```

**Verify annotations:**
```powershell
Get-Content "data/processed/RobotFloor/labels/starting_Robotfloor1_rot90.txt"
```

---

## 💡 Tips

1. **Run during off-hours** - The pipeline can take 10-30 minutes
2. **Check disk space** - Ensure you have at least 500 MB free
3. **Spot-check annotations** - Verify a few rotated images look correct
4. **Keep originals** - Don't delete `data/raw/RobotFloor/` - keep as backup
5. **Use version control** - Commit your original annotations to Git

---

## 🆘 Still Having Issues?

1. **Check prerequisites** - Make sure all 38 images are annotated
2. **Read error messages** - They usually tell you what's wrong
3. **Check file paths** - Make sure you're in the project root directory
4. **Verify PowerShell version** - Use PowerShell 7+ (not Windows PowerShell 5.1)
5. **Check disk space** - Ensure you have enough free space

---

**Last Updated:** Current Session  
**Status:** ✅ Ready to Use  
**Expected Time:** 10-30 minutes

---

**Good luck! 🚀**

