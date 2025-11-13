# Complete Beginner's Guide: From Images to Working Model

## 🎯 Goal

Train an AI model to **count robots** in factory floor images using your 1,824 processed PNG files.

**End Result:** A model file (ONNX) that can detect and count robots in new images.

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] Python 3.8 or higher installed
- [ ] 1,824 processed images in `data/processed/RobotFloor/`
- [ ] Basic understanding of file folders
- [ ] 10-20 hours for annotation (can be split over days)

**You DON'T need:**
- ❌ Advanced programming knowledge
- ❌ GPU (CPU works, just slower)
- ❌ Previous ML experience

---

## 🗺️ Complete Pipeline Overview

### Smart Workflow (If You Have 36 Originals)

```
Step 1: Annotate 36 Originals  (2-4 hours) ← Only annotate originals!
   ↓
Step 2: Transform for Rotations (5 minutes, automatic)
   ↓
Step 3: Copy for Black BG     (2 minutes, automatic)
   ↓
Step 4: Merge Annotations     (2 minutes, automatic)
   ↓
Step 5: Verify Annotations   (5 minutes)
   ↓
Step 6: Split Dataset         (5 minutes)
   ↓
Step 7: Train Model           (1-4 hours)
   ↓
Step 8: Export to ONNX        (1 minute)
   ↓
Step 9: Test in C#            (5 minutes)
```

**Total Time:** ~4-10 hours (vs 20-30 hours manual!)

### Standard Workflow (If Not Using Smart Method)

```
Step 1: Split Dataset          (5 minutes)
   ↓
Step 2: Annotate Images        (10-20 hours) ← Most time here
   ↓
Step 3: Verify Annotations     (5 minutes)
   ↓
Step 4: Create dataset.yaml   (2 minutes)
   ↓
Step 5: Train Model            (1-4 hours)
   ↓
Step 6: Export to ONNX         (1 minute)
   ↓
Step 7: Test in C#             (5 minutes)
```

**Total Time:** ~12-25 hours (mostly annotation)

---

## Step 1: Split Dataset (5 minutes)

### What This Does

Splits your 1,824 images into three groups:
- **Training** (70% = ~1,277 images) - Model learns from these
- **Validation** (20% = ~365 images) - Model checks itself on these
- **Test** (10% = ~182 images) - Final test after training

### How to Do It

**Open PowerShell in project folder:**
```powershell
# Navigate to project folder
cd C:\Users\georgem\source\repos\AutoFactoryScope

# Run the split script
pwsh scripts/split-dataset.ps1
```

**What happens:**
- Script copies images to `data/training/images/`, `data/validation/images/`, `data/test/images/`
- Shows progress and summary
- Verifies all images were copied

**Expected output:**
```
Found 1824 images
Split plan:
  Training:   1277 images (70%)
  Validation: 365 images (20%)
  Test:       182 images (10%)
✅ Dataset split completed successfully!
```

**✅ Success when:** You see "Dataset split completed successfully!"

**❌ If it fails:** Check that `data/processed/RobotFloor/` has PNG files

---

## Step 2: Annotate Images

### ⚡ Smart Workflow (Recommended - Saves 16-26 Hours!)

**If you have 36 original images that were rotated to create 912 images:**

1. **Annotate only the 36 originals** (2-4 hours)
2. **Transform annotations for rotations** (5 min, automatic)
3. **Copy annotations for black background** (2 min, automatic)

**Total time: 2-4 hours** (vs 20-30 hours manual!)

**See:** `docs/SMART_ANNOTATION_WORKFLOW.md` for complete instructions.

---

### Standard Workflow (If Not Using Smart Method)

### What This Does

You draw boxes around **every robot** in each image. The AI learns from these boxes.

**Each box = one robot. Count = number of boxes.**

### Option A: Fast Method - AI-Assisted (Recommended)

**Use Roboflow (web-based, fastest):**

1. **Sign up:** https://roboflow.com (free tier available)
2. **Create project:** Click "Create Project" → Name it "Robot Detection"
3. **Upload images:**
   - Click "Upload" → Select `data/training/images/` folder
   - Wait for upload (may take a while for 1,277 images)
4. **Enable AI labeling:**
   - Go to "Annotate" tab
   - Toggle "AI-assisted labeling" ON
   - AI will pre-annotate robots
5. **Review and correct:**
   - Click through images
   - Fix AI mistakes
   - Add boxes for missed robots
   - Much faster than starting from scratch!
6. **Export:**
   - Click "Export" → Select "YOLO" format
   - Download dataset
   - Extract to project folder
   - Copy `train/labels/` to `data/training/labels/`

**Time:** 5-10 hours (vs 20-30 hours manual)

### Option B: Pre-annotation Script (If you have any YOLO model)

**If you have ANY robot detection model (even a generic one):**

```powershell
# Install Python dependencies
pip install ultralytics

# Run pre-annotation script
python scripts/pre-annotate-with-model.py
```

**What it does:**
- Uses a pre-trained model to auto-annotate
- Creates `.txt` files automatically
- You review and correct (much faster!)

**Time:** 2-5 hours (review and correct)

### Option C: Manual Annotation (LabelImg)

**If you prefer manual control:**

1. **Install LabelImg:**
   ```bash
   pip install labelImg
   labelImg
   ```

2. **Configure:**
   - Open LabelImg
   - Click "Open Dir" → Select `data/training/images/`
   - Click "Change Save Dir" → Select `data/training/labels/`
   - **Important:** Set format to "YOLO" (not PascalVOC)

3. **Annotate:**
   - Press `W` to draw bounding box
   - Draw box around robot
   - Label as "robot" (class 0)
   - Press `D` to go to next image
   - Repeat for all images

**Keyboard shortcuts:**
- `W` - Create box
- `D` - Next image
- `A` - Previous image
- `Del` - Delete box
- `Ctrl+S` - Save

**Time:** 15-30 hours (manual)

### Annotation Format

Each image needs a `.txt` file with the same name.

**Example:** `Robotfloor1.png` → `Robotfloor1.txt`

**Format (one line per robot):**
```
0 0.5 0.5 0.1 0.15
0 0.3 0.7 0.08 0.12
```

**What each number means:**
- `0` = Class ID (0 = robot)
- `0.5 0.5` = Center of box (50% from left, 50% from top)
- `0.1 0.15` = Width and height (10% of image width, 15% of height)

**All values are 0.0 to 1.0 (normalized), not pixels!**

### Tips for Fast Annotation

1. **Don't perfect every box initially** - Quick pass first
2. **Use AI assistance** - Roboflow or pre-annotation script
3. **Batch similar images** - Work on similar ones together
4. **Take breaks** - Maintain quality
5. **Verify a sample** - Check 10-20 images manually

### Repeat for Validation and Test Sets

After training set, do the same for:
- `data/validation/images/` → `data/validation/labels/`
- `data/test/images/` → `data/test/labels/`

**Time:** Validation (2-3 hours), Test (1 hour)

---

## Step 3: Verify Annotations (5 minutes)

### What This Does

Checks that:
- Every image has a corresponding `.txt` file
- Annotation format is correct
- Values are in valid range (0-1)

### How to Do It

```powershell
# Verify training annotations
pwsh scripts/verify-annotations.ps1

# Verify validation annotations
pwsh scripts/verify-annotations.ps1 -ImagesDir "data/validation/images" -LabelsDir "data/validation/labels"

# Verify test annotations
pwsh scripts/verify-annotations.ps1 -ImagesDir "data/test/images" -LabelsDir "data/test/labels"
```

**Expected output:**
```
Found 1277 images
  Total images: 1277
  Has labels: 1277
  Missing labels: 0
  Empty labels: 0
  Invalid labels: 0
  Valid labels: 1277
✅ All annotations are valid!
```

**✅ Success when:** "All annotations are valid!"

**❌ If it fails:** Fix the issues shown (missing files, invalid format, etc.)

---

## Step 4: Create dataset.yaml (2 minutes)

### What This Does

Tells YOLO where to find your images and labels.

### How to Do It

**The file already exists:** `dataset.yaml`

**Just verify it's correct:**
```yaml
path: ./data
train: training/images
val: validation/images
test: test/images

nc: 1
names:
  0: robot
```

**If you need to create it:**
1. Copy the content above
2. Save as `dataset.yaml` in project root
3. Make sure paths match your folder structure

**✅ Success when:** File exists and paths are correct

---

## Step 5: Train Model (1-4 hours)

### What This Does

Trains the AI model to detect robots. This is where the model "learns" from your annotations.

### How to Do It

**First time setup (5 minutes):**

1. **Install Python** (if not installed):
   - Download from https://www.python.org/downloads/
   - Check "Add Python to PATH" during installation

2. **Install dependencies:**
   ```bash
   pip install ultralytics
   ```

**Train the model:**

```bash
# Run training script
python train_robot_model.py
```

**What happens:**
- Downloads pre-trained YOLO model (first time only)
- Trains on your images
- Shows progress (loss, mAP metrics)
- Saves best model automatically
- Exports to ONNX format

**Expected output:**
```
Step 1: Checking dataset configuration...
✅ Found dataset.yaml

Step 2: Loading pre-trained YOLO model...
✅ Model loaded: yolov8s.pt

Step 3: Starting training...
   Epochs: 100
   Batch size: 16
   Image size: 640x640
   
   [Training progress shown here...]
   
✅ Training completed!

Step 5: Exporting to ONNX format...
✅ ONNX model exported: runs/detect/robot_detection/weights/best.onnx
```

**Training time:**
- With GPU: 1-2 hours
- Without GPU (CPU): 4-8 hours

**What to watch for:**
- Loss decreasing = Good
- mAP increasing = Good
- mAP > 0.7 = Good model
- mAP > 0.8 = Excellent model

**✅ Success when:** You see "Training Complete!" and ONNX file is created

**❌ If it fails:**
- **Out of memory:** Reduce BATCH_SIZE in script (try 8 or 4)
- **Dataset not found:** Check dataset.yaml paths
- **No images:** Make sure images are in correct folders

---

## Step 6: Copy ONNX to Project (1 minute)

### What This Does

Moves the trained model to your project so C# can use it.

### How to Do It

```powershell
# Copy ONNX model to project
Copy-Item "runs\detect\robot_detection\weights\best.onnx" "models\onnx\robot_detection.onnx"
```

**Verify it's there:**
```powershell
# Check file exists
Test-Path "models\onnx\robot_detection.onnx"
# Should return: True
```

**✅ Success when:** File exists in `models/onnx/robot_detection.onnx`

---

## Step 7: Test in C# Application (5 minutes)

### What This Does

Tests your trained model in the C# application to make sure it works.

### How to Do It

```bash
# Test on a single image
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/images/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx"
```

**Expected output:**
```
Robot count: 3
```

**This means:** The model detected 3 robots in the image!

**Test on multiple images:**
```powershell
# Test on all test images
$testImages = Get-ChildItem "data\test\images" -Filter "*.png"
foreach ($img in $testImages) {
    Write-Host "Testing: $($img.Name)"
    dotnet run --project src/AutoFactoryScope.CLI -- `
      --image $img.FullName `
      --model "models/onnx/robot_detection.onnx"
    Write-Host ""
}
```

**✅ Success when:** Model detects robots and counts them correctly

**❌ If it fails:**
- Check model path is correct
- Verify image exists
- Check for error messages

---

## 🎉 Success Checklist

You're done when:

- [ ] Dataset split into train/val/test
- [ ] All images annotated (every robot boxed)
- [ ] Annotations verified (no errors)
- [ ] dataset.yaml created
- [ ] Model trained (mAP > 0.7)
- [ ] ONNX model exported
- [ ] Model works in C# application
- [ ] Robot counting is accurate

---

## 🆘 Troubleshooting

### Problem: "No module named 'ultralytics'"

**Solution:**
```bash
pip install ultralytics
```

### Problem: "CUDA out of memory"

**Solution:**
- Open `train_robot_model.py`
- Change `BATCH_SIZE = 16` to `BATCH_SIZE = 8` or `4`
- Save and run again

### Problem: "dataset.yaml not found"

**Solution:**
- Make sure `dataset.yaml` is in project root
- Check file name is exactly `dataset.yaml` (not `dataset.yml`)

### Problem: "No images found"

**Solution:**
- Check images are in correct folders
- Verify file extensions are `.png`
- Check dataset.yaml paths are correct

### Problem: "Model detects nothing"

**Solution:**
- Lower confidence threshold: `--confidence 0.25`
- Check annotations are correct
- Verify model trained properly (check mAP)

### Problem: "Wrong robot count"

**Solution:**
- Check annotations - did you annotate every robot?
- Verify test images have correct annotations
- May need more training data or better annotations

---

## 📚 Additional Resources

- **Annotation guide:** `docs/ANNOTATION_EXPLAINED.md`
- **Fast annotation:** `docs/FAST_ANNOTATION_GUIDE.md`
- **ONNX guide:** `docs/ONNX_COMPLETE_GUIDE.md`
- **Training details:** `docs/TRAINING_GUIDE.md`

---

## 💡 Tips for Success

1. **Start small:** Test on 10-20 images first
2. **Quality over speed:** Better annotations = better model
3. **Monitor training:** Watch mAP metrics
4. **Test frequently:** Verify model works as you go
5. **Ask for help:** Check documentation or ask questions

---

## ⏱️ Time Estimates

| Step | Time | Notes |
|------|------|-------|
| Split dataset | 5 min | Automated |
| Annotate (AI-assisted) | 5-10 hours | Fastest method |
| Annotate (manual) | 20-30 hours | Slower but more control |
| Verify annotations | 5 min | Automated |
| Create dataset.yaml | 2 min | One-time |
| Train model (GPU) | 1-2 hours | Faster |
| Train model (CPU) | 4-8 hours | Slower |
| Export ONNX | 1 min | Automated |
| Test in C# | 5 min | Quick verification |

**Total (with AI-assisted annotation):** ~12-15 hours  
**Total (manual annotation):** ~25-40 hours

---

## 🎯 Next Steps After Training

1. **Evaluate model:** Check mAP metrics
2. **Test on new images:** Verify it works
3. **Improve if needed:** Add more data, retrain
4. **Deploy:** Use in production
5. **Expand:** Add gantry and tracks detection

---

**You've got this!** Take it step by step, and don't hesitate to refer back to this guide.

**Last Updated:** 2025

