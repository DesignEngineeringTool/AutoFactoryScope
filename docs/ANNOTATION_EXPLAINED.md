# What is Image Annotation?

## Simple Explanation

**Annotation** = **Labeling objects in images** so the AI can learn what to detect.

Think of it like teaching a child: You show them a picture and say "this is a robot" by drawing a box around it. The AI needs the same thing - you draw boxes around robots in your images and tell it "this is a robot."

---

## Why Do We Need Annotation?

### The Problem
Your AI model needs to learn:
- **What** to look for (robots)
- **Where** they are in the image
- **How many** there are

But the model **can't learn this by itself** - it needs examples with labels.

### The Solution
You provide **annotated images**:
- Images with bounding boxes drawn around robots
- Each box tells the model: "This area contains a robot"

The model learns from thousands of these examples and eventually can detect robots on its own.

---

## What Does Annotation Look Like?

### Visual Example

**Original Image:**
```
┌─────────────────────────┐
│                         │
│      [Robot]            │
│                         │
│              [Robot]    │
│                         │
└─────────────────────────┘
```

**Annotated Image (with bounding boxes):**
```
┌─────────────────────────┐
│ ┌──────┐                │
│ │Robot │                │
│ └──────┘                │
│                         │
│              ┌──────┐   │
│              │Robot │   │
│              └──────┘   │
└─────────────────────────┘
```

**Annotation File (Robotfloor1.txt):**
```
0 0.25 0.25 0.2 0.3
0 0.75 0.75 0.2 0.3
```

---

## How Annotation Works

### Step 1: Open Image in Annotation Tool

You use a tool like **LabelImg**:
1. Open the image
2. See the image displayed

### Step 2: Draw Bounding Boxes

1. Click and drag to draw a rectangle around each robot
2. The tool shows the box on screen
3. Assign a class label (e.g., "robot" = class 0)

### Step 3: Save Annotation

The tool creates a `.txt` file with the same name as the image:
- `Robotfloor1.png` → `Robotfloor1.txt`
- Contains coordinates of all bounding boxes

---

## YOLO Annotation Format

Each `.txt` file contains **one line per object**:

```
class_id center_x center_y width height
```

### Example: `Robotfloor1.txt`
```
0 0.5 0.5 0.1 0.15
0 0.3 0.7 0.08 0.12
```

### What Each Number Means

**Line 1:** `0 0.5 0.5 0.1 0.15`
- `0` = Class ID (0 = robot)
- `0.5 0.5` = Center of bounding box (50% from left, 50% from top)
- `0.1 0.15` = Width and height (10% of image width, 15% of image height)

**Important:** All values are **normalized** (0.0 to 1.0), not pixels!

### Visual Breakdown

For an image that's 640x640 pixels:

```
┌─────────────────────────┐
│                         │
│      ┌──────┐           │
│      │      │           │
│      │Robot │           │
│      │      │           │
│      └──────┘           │
│                         │
└─────────────────────────┘
    640 pixels wide

Annotation: 0 0.5 0.5 0.1 0.15

Center: (320, 320) pixels = (0.5, 0.5) normalized
Width: 64 pixels = 0.1 normalized
Height: 96 pixels = 0.15 normalized
```

---

## Tools for Annotation

### 1. LabelImg (Recommended for Beginners)

**Install:**
```bash
pip install labelImg
labelImg
```

**How to Use:**
1. Open image folder
2. Set format to **YOLO** (important!)
3. Draw boxes around robots
4. Save - creates `.txt` file automatically

**Pros:**
- ✅ Free, open source
- ✅ Simple to use
- ✅ Works offline
- ✅ Creates YOLO format directly

**Cons:**
- ❌ One image at a time
- ❌ No collaboration features

### 2. Roboflow (Web-Based)

**Website:** https://roboflow.com

**How to Use:**
1. Upload images
2. Annotate in browser
3. Export in YOLO format
4. Download dataset

**Pros:**
- ✅ Web-based (no installation)
- ✅ Team collaboration
- ✅ Dataset management
- ✅ Automatic augmentation

**Cons:**
- ❌ Requires internet
- ❌ Free tier has limits

### 3. CVAT (Advanced)

**Website:** https://cvat.org

**Best For:**
- Large teams
- Complex annotations
- Quality control

---

## Annotation Workflow

### Complete Process

```
1. Open image in LabelImg
   ↓
2. Draw bounding box around robot
   ↓
3. Label as "robot" (class 0)
   ↓
4. Save annotation
   ↓
5. Creates Robotfloor1.txt
   ↓
6. Move to next image
   ↓
7. Repeat for all images
```

### File Structure After Annotation

```
data/
├── training/
│   ├── images/
│   │   ├── Robotfloor1.png  ← Image file
│   │   ├── Robotfloor2.png
│   │   └── ...
│   └── labels/
│       ├── Robotfloor1.txt   ← Annotation file (created by you)
│       ├── Robotfloor2.txt
│       └── ...
```

**Critical:** Image and label files must have **matching names** (except extension)!

---

## Annotation Best Practices

### ✅ DO's

1. **Draw tight boxes** - Box should fit closely around the robot
2. **Include entire object** - Don't cut off parts of the robot
3. **Be consistent** - Same type of object = same class
4. **Handle edge cases** - Partially visible robots still need boxes
5. **Verify annotations** - Check a few `.txt` files manually

### ❌ DON'Ts

1. **Don't use loose boxes** - Too much empty space
2. **Don't cut off objects** - Include the whole robot
3. **Don't skip difficult images** - Annotate everything
4. **Don't mix classes** - Robot = class 0, always
5. **Don't forget to save** - Each image needs its `.txt` file

---

## Example: Annotating One Image

### Step-by-Step

**Image:** `Robotfloor1.png` (640x640 pixels)

**What You See:**
- 2 robots in the image
- Robot 1: Center-left area
- Robot 2: Bottom-right area

**What You Do:**
1. Open in LabelImg
2. Draw box around Robot 1 → Label as "robot"
3. Draw box around Robot 2 → Label as "robot"
4. Save

**What Gets Created:** `Robotfloor1.txt`
```
0 0.25 0.4 0.15 0.2
0 0.75 0.8 0.12 0.18
```

**What It Means:**
- Line 1: Robot at center (25%, 40%), size 15% x 20%
- Line 2: Robot at center (75%, 80%), size 12% x 18%

---

## Time Estimate

### For Your Dataset (1,824 images)

**If splitting 70/20/10:**
- Training: ~1,277 images
- Validation: ~365 images
- Test: ~182 images

**Time per image:**
- Simple images (1-2 robots): 30-60 seconds
- Complex images (many robots): 2-5 minutes

**Total time:**
- Fast annotator: 10-15 hours
- Careful annotator: 20-30 hours
- With quality checks: 25-35 hours

**Tips to Speed Up:**
- Use keyboard shortcuts in LabelImg
- Batch similar images together
- Take breaks to maintain quality
- Use Roboflow for team collaboration

---

## Verification

### Check Your Annotations

**Visual Check:**
- Open image in LabelImg
- Verify boxes are correct
- Check class labels

**File Check:**
```powershell
# Verify all images have corresponding .txt files
$images = Get-ChildItem "data/training/images" -Filter "*.png"
$labels = Get-ChildItem "data/training/labels" -Filter "*.txt"

foreach ($img in $images) {
    $labelName = $img.Name -replace '\.png$', '.txt'
    $labelPath = Join-Path "data/training/labels" $labelName
    
    if (-not (Test-Path $labelPath)) {
        Write-Warning "Missing label for $($img.Name)"
    }
}
```

**Format Check:**
```python
# verify_annotations.py
import os
from PIL import Image

def check_annotation(image_path, label_path):
    img = Image.open(image_path)
    width, height = img.size
    
    with open(label_path, 'r') as f:
        for line_num, line in enumerate(f, 1):
            parts = line.strip().split()
            if len(parts) != 5:
                print(f"ERROR in {label_path} line {line_num}: Wrong format")
                return False
            
            class_id, cx, cy, w, h = map(float, parts)
            
            # Check if values are in valid range (0-1)
            if not all(0 <= val <= 1 for val in [cx, cy, w, h]):
                print(f"ERROR in {label_path} line {line_num}: Values out of range")
                return False
    
    return True
```

---

## Common Questions

### Q: Do I need to annotate ALL images?
**A:** Yes! The model needs examples to learn from. More annotations = better model.

### Q: What if a robot is partially visible?
**A:** Still annotate it! Draw a box around the visible part. The model will learn to handle partial objects.

### Q: What if I'm not sure if something is a robot?
**A:** When in doubt, annotate it. Better to have extra annotations than miss objects.

### Q: Can I use AI to help annotate?
**A:** Some tools (like Roboflow) have AI-assisted annotation, but you still need to review and correct.

### Q: What if I make a mistake?
**A:** Just re-open the image in LabelImg, fix the annotation, and save again.

---

## Summary

**Annotation = Drawing boxes around robots in images**

**Why:** AI needs labeled examples to learn

**How:** Use LabelImg or Roboflow to draw bounding boxes

**Output:** `.txt` files with coordinates (YOLO format)

**Time:** 10-30 hours for your dataset (depending on complexity)

**Result:** Model can detect robots in new images!

---

**Next Steps:**
1. Install LabelImg: `pip install labelImg`
2. Open your first image
3. Draw a box around a robot
4. Save and see the `.txt` file created
5. Repeat for all images

See `docs/NEXT_STEPS.md` for the complete workflow.

---

**Last Updated:** 2025

