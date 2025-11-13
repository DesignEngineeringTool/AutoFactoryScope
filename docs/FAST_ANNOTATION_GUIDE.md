# Fast Annotation Guide: Speed Up PNG Annotation

## Overview

Annotating 1,824 images can take 10-30 hours. Here are proven methods to **cut this time in half or more**.

---

## Method 1: AI-Assisted Annotation (Fastest)

### Roboflow (Recommended)

**Website:** https://roboflow.com

**How it works:**
1. Upload images
2. AI pre-annotates robots (uses existing models)
3. You review and correct
4. Export in YOLO format

**Time savings:** 50-70% faster

**Steps:**
1. Sign up (free tier available)
2. Create project → Upload images
3. Enable "AI-assisted labeling"
4. Review/correct AI suggestions
5. Export dataset

**Pros:**
- ✅ AI does most of the work
- ✅ Web-based (no installation)
- ✅ Team collaboration
- ✅ Dataset management
- ✅ Automatic augmentation

**Cons:**
- ❌ Requires internet
- ❌ Free tier has limits
- ❌ May need correction

### CVAT with AI

**Website:** https://cvat.org

**Features:**
- AI-assisted annotation
- Semi-automatic segmentation
- Team collaboration
- Quality control

**Setup:**
```bash
docker run -d -p 8080:8080 cvat/cvat
# Access at http://localhost:8080
```

---

## Method 2: Keyboard Shortcuts (LabelImg)

### Essential Shortcuts

**LabelImg Keyboard Shortcuts:**
- `W` - Create bounding box
- `D` - Next image
- `A` - Previous image
- `Del` - Delete selected box
- `Ctrl+S` - Save
- `Space` - Verify image

**Time savings:** 20-30% faster

### Workflow Optimization

**Efficient workflow:**
1. Open folder in LabelImg
2. Use `W` to draw box
3. Press `Enter` to confirm
4. Use `D` to go to next image
5. Repeat quickly

**Tips:**
- Don't perfect every box initially
- Do a quick pass first
- Refine later if needed
- Use `Space` to verify

---

## Method 3: Batch Processing

### Pre-annotation with Existing Model

**If you have ANY robot detection model:**

1. **Run model on all images**
2. **Export detections as annotations**
3. **Review and correct** (much faster than starting from scratch)

**Script:**
```python
from ultralytics import YOLO
import os

# Load any pre-trained YOLO model
model = YOLO('yolov8n.pt')  # Even generic model helps

# Process all images
images_dir = 'data/training/images'
labels_dir = 'data/training/labels'

for img_file in os.listdir(images_dir):
    if img_file.endswith('.png'):
        img_path = os.path.join(images_dir, img_file)
        
        # Get predictions
        results = model(img_path)
        
        # Convert to YOLO format
        label_path = os.path.join(labels_dir, img_file.replace('.png', '.txt'))
        with open(label_path, 'w') as f:
            for box in results[0].boxes:
                # Convert to YOLO format
                # (normalize coordinates)
                f.write(f"0 {cx} {cy} {w} {h}\n")
```

**Time savings:** 60-80% faster (you just correct, not create)

---

## Method 4: Team Collaboration

### Divide and Conquer

**Split work:**
- Person 1: Images 1-600
- Person 2: Images 601-1200
- Person 3: Images 1201-1824

**Tools:**
- **Roboflow** - Built-in collaboration
- **CVAT** - Team annotation
- **LabelImg** - Manual split

**Time savings:** 3x faster with 3 people

### Quality Control

**After annotation:**
1. Each person reviews another's work
2. Spot check 10% of annotations
3. Fix any issues found

---

## Method 5: Smart Annotation Tools

### LabelImg with Auto-save

**Configure LabelImg:**
- Auto-save on next image
- Auto-advance after save
- Pre-fill class labels

**Settings:**
```
File → Save Automatically: ON
File → Default Saved Dir: [labels folder]
```

### VGG Image Annotator (VIA)

**Website:** https://www.robots.ox.ac.uk/~vgg/software/via/

**Features:**
- Batch annotation
- Keyboard shortcuts
- Export to YOLO
- Faster workflow

---

## Method 6: Annotation Scripts

### Automated Pre-processing

**If images are similar:**

1. **Annotate one template image**
2. **Use script to apply to similar images**
3. **Adjust as needed**

**Example:**
```python
# If robots are in similar positions across images
# You can programmatically create initial annotations
# Then manually adjust
```

**Use case:** If your floor layouts are similar, robots may be in similar positions.

---

## Method 7: Progressive Annotation

### Two-Pass Strategy

**Pass 1: Quick annotation (30% of time)**
- Draw boxes quickly
- Don't perfect them
- Mark difficult images
- Goal: Get all robots boxed

**Pass 2: Refinement (70% of time)**
- Perfect box positions
- Fix difficult images
- Verify accuracy
- Goal: High quality

**Time savings:** Feels faster, better quality

---

## Recommended Workflow

### Fastest Approach

**Step 1: AI Pre-annotation (Roboflow)**
- Upload all images
- Let AI annotate
- Export annotations

**Step 2: Review and Correct**
- Open in LabelImg
- Review AI suggestions
- Correct mistakes
- Add missed robots

**Step 3: Quality Check**
- Spot check 10%
- Fix any issues
- Verify format

**Total time:** 5-10 hours (vs 20-30 hours manual)

---

## Tool Comparison

| Tool | Speed | Quality | Cost | Best For |
|------|-------|---------|------|----------|
| **Roboflow AI** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free/Paid | Fastest start |
| **LabelImg + Shortcuts** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | Manual control |
| **CVAT** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | Teams |
| **Pre-annotation Script** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Free | If model exists |
| **Team Collaboration** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | Multiple people |

---

## Quick Start: Roboflow (Recommended)

### 5-Minute Setup

1. **Sign up:** https://roboflow.com
2. **Create project:** "Robot Detection"
3. **Upload images:** Drag and drop folder
4. **Enable AI labeling:** Toggle on
5. **Review annotations:** Click through images
6. **Export:** YOLO format

**Time:** 5-10 hours total (vs 20-30 manual)

---

## Tips for Speed

### General Tips

1. **Use AI assistance** - Biggest time saver
2. **Learn shortcuts** - 20-30% faster
3. **Batch similar images** - Work on similar ones together
4. **Don't perfect initially** - Quick pass first
5. **Take breaks** - Maintain quality
6. **Use templates** - If images are similar
7. **Team up** - Divide work

### Quality vs Speed

**Balance:**
- Fast but inaccurate = Bad model
- Slow but perfect = Wasted time
- **Fast and good enough** = Best approach

**Target:** 90% accuracy in 50% of the time

---

## Time Estimates

### Manual Annotation
- **Slow:** 1-2 min/image = 30-60 hours
- **Medium:** 30-60 sec/image = 15-30 hours
- **Fast:** 15-30 sec/image = 7-15 hours

### With AI Assistance
- **Roboflow:** 10-20 sec/image = 5-10 hours
- **Pre-annotation:** 5-10 sec/image = 2-5 hours

### With Team (3 people)
- **Manual:** 5-10 hours per person
- **AI-assisted:** 2-3 hours per person

---

## Summary

**Fastest Method:**
1. ✅ Use Roboflow AI-assisted annotation
2. ✅ Review and correct (much faster than creating)
3. ✅ Export to YOLO format
4. ✅ Quality check

**Time:** 5-10 hours (vs 20-30 hours manual)

**Alternative:**
- Use pre-trained model to pre-annotate
- Correct annotations
- Train on corrected data

**Best Practice:**
- Start with AI/pre-annotation
- Review and correct
- Quality check
- Train model

---

**Next Steps:**
1. Try Roboflow (free tier)
2. Or use LabelImg with shortcuts
3. Or get team to help
4. Or use pre-annotation script

See `docs/ANNOTATION_EXPLAINED.md` for detailed annotation guide.

---

**Last Updated:** 2025

