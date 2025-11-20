# Quick Start: Image Augmentation

**For Rinesh** - Quick reference for augmenting 38 annotated images.

---

## 🚀 One Command to Run Everything

```powershell
pwsh scripts/augment-annotated-images.ps1
```

**That's it!** This single command will:
- ✅ Format images to 640x640
- ✅ Create 23 rotated versions of each image
- ✅ Transform annotations for rotations
- ✅ Create black background versions
- ✅ Copy annotations for black backgrounds
- ✅ Merge everything to final directory

**Time:** ~10-30 minutes  
**Output:** ~1,824 images with annotations

---

## ✅ Before Running

**Check you have:**
- [ ] 38 PNG images in `data/raw/RobotFloor/`
- [ ] 38 annotation files in `data/raw/RobotFloor/labels/`

**Quick check:**
```powershell
Get-ChildItem "data/raw/RobotFloor" -Filter "*.png" | Measure-Object
Get-ChildItem "data/raw/RobotFloor/labels" -Filter "*.txt" | Measure-Object
```

Both should show **38**.

---

## 📊 After Running

**Check results:**
```powershell
Get-ChildItem "data/processed/RobotFloor" -Filter "*.png" | Measure-Object
# Should show ~1,824

Get-ChildItem "data/processed/RobotFloor/labels" -Filter "*.txt" | Measure-Object
# Should show ~1,824
```

---

## 📚 Full Guide

For detailed instructions, troubleshooting, and explanations, see:
**`docs/RINESH_AUGMENTATION_GUIDE.md`**

---

**That's all you need to know!** 🎉

