# Import Annotations Guide

## Current Status

✅ **Images imported:** 38 PNG files in `data/raw/RobotFloor/`  
❌ **Annotations missing:** No `.txt` files found

## Where Are Your Annotations?

If you've already annotated the images, the annotation files might be in:

### 1. Check Common Locations

```powershell
# Check if annotations are in a subdirectory
Get-ChildItem "C:\Users\georgem\source\repos\AutoFactoryScope_data" -Recurse -Filter "*.txt"

# Check for different annotation formats
Get-ChildItem "C:\Users\georgem\source\repos\AutoFactoryScope_data" -Recurse -Filter "*.xml"  # PascalVOC
Get-ChildItem "C:\Users\georgem\source\repos\AutoFactoryScope_data" -Recurse -Filter "*.json" # COCO
```

### 2. Common Annotation Tool Locations

- **LabelImg:** Usually saves in same directory as images, or in a `labels/` subdirectory
- **Roboflow:** Downloads as a zip with `train/labels/` and `valid/labels/` folders
- **CVAT:** Exports as XML (PascalVOC) or JSON (COCO) format
- **LabelMe:** Saves as JSON files

### 3. If Annotations Are in Different Format

If your annotations are in a different format (XML, JSON, etc.), you'll need to convert them to YOLO format:

**YOLO Format:** Each `.txt` file should have one line per object:
```
class_id center_x center_y width height
```

All values are normalized (0-1).

Example:
```
0 0.5 0.5 0.2 0.3
0 0.7 0.3 0.15 0.25
```

## Quick Setup Options

### Option A: Annotations Are Somewhere Else

If you know where your annotation files are:

```powershell
# Copy them to the correct location
Copy-Item "C:\path\to\annotations\*.txt" "data/raw/RobotFloor/labels/"
```

### Option B: Convert from Another Format

If you have XML (PascalVOC) or JSON (COCO) annotations, you'll need to convert them. There are online converters or scripts available.

### Option C: Re-annotate (If Needed)

If annotations don't exist or are lost:

```powershell
# Set up annotation workflow
pwsh scripts/setup-annotation-workflow.ps1
```

This will guide you through annotating with LabelImg or other tools.

## Verify Annotations

Once you have annotation files in `data/raw/RobotFloor/labels/`, verify them:

```powershell
pwsh scripts/validate-yolo-annotations.ps1
```

## Next Steps

1. **Locate your annotation files** (if they exist)
2. **Copy them to:** `data/raw/RobotFloor/labels/`
3. **Verify format:** Run validation script
4. **Run pipeline:** `pwsh scripts/complete-annotation-pipeline.ps1`

---

**Need help?** Let me know:
- Where your annotation files are located
- What format they're in (if not YOLO .txt)
- If you need to create new annotations

