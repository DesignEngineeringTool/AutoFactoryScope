# How Robot Counting Works

## Overview

**Goal:** Count the number of robots in factory floor layout images.

**Method:** Object detection → Count detected objects = Robot count

---

## How It Works

### Step 1: Detection
The AI model detects robots in the image by drawing bounding boxes around each robot.

**Example Image:**
```
┌─────────────────────────┐
│                         │
│  [Robot]  [Robot]      │
│                         │
│      [Robot]            │
│                         │
└─────────────────────────┘
```

### Step 2: Counting
The system counts the number of bounding boxes detected.

**Result:**
- Detected boxes: 3
- **Robot count: 3** ✅

---

## How Counting is Implemented

### In Your Code

**DetectionResult.cs:**
```csharp
public sealed class DetectionResult
{
    public List<RobotInstance> Robots { get; } = new();
    public int Total => Robots.Count;  // ← This is the count!
}
```

**How it works:**
1. Model detects robots → Creates `RobotInstance` for each detection
2. Adds to `Robots` list
3. `Total` property returns `Robots.Count` = **robot count**

### CLI Output

When you run the application:
```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/Robotfloor1.png" \
  --model "models/onnx/robot_detection.onnx"
```

**Output:**
```
Robot count: 3
```

This means **3 robots** were detected in the image.

---

## Annotation for Counting

### Critical: Annotate EVERY Robot

**For accurate counting, you must:**
- ✅ Draw a box around **EVERY robot** in the image
- ✅ Don't miss any robots
- ✅ Don't double-count (one box per robot)

**Example:**

**Image with 5 robots:**
```
┌─────────────────────────┐
│ [R]  [R]                │
│                         │
│    [R]  [R]  [R]         │
│                         │
└─────────────────────────┘
```

**Annotation file must have 5 lines:**
```
0 0.15 0.2 0.1 0.15
0 0.35 0.2 0.1 0.15
0 0.5 0.6 0.1 0.15
0 0.7 0.6 0.1 0.15
0 0.85 0.6 0.1 0.15
```

**Result:** Model learns to detect all 5 robots → Count = 5 ✅

---

## Accuracy Considerations

### What Affects Counting Accuracy?

1. **Annotation Quality**
   - Missing robots in annotations → Model won't learn to detect them
   - Extra boxes → Model may detect false positives
   - Inconsistent boxes → Model confusion

2. **Model Training**
   - More training data → Better accuracy
   - Better annotations → Better model
   - Sufficient epochs → Model learns properly

3. **Detection Thresholds**
   - Confidence threshold too high → Misses robots
   - Confidence threshold too low → False positives
   - IoU threshold → Handles overlapping detections

### Testing Counting Accuracy

**Manual Verification:**
1. Count robots manually in test images
2. Run model on same images
3. Compare counts

**Example:**
```
Image: Robotfloor1.png
Manual count: 5 robots
Model count: 5 robots
Accuracy: 100% ✅
```

**Batch Testing:**
```powershell
# Test on all test images
$testImages = Get-ChildItem "data/test/images" -Filter "*.png"
foreach ($img in $testImages) {
    $result = dotnet run --project src/AutoFactoryScope.CLI -- --image $img.FullName --model "models/onnx/robot_detection.onnx"
    # Compare with expected count
}
```

---

## Future Expansion

### Current: Floor Robots
- **1,824 images** of floor layouts
- **Goal:** Count robots on floor

### Next: Gantry Detection
- Will need new dataset with gantry images
- New class: `gantry` (class 1)
- Same process: detect → count

**Updated dataset.yaml:**
```yaml
nc: 2
names:
  0: robot
  1: gantry
```

### Then: 7th Tracks with Robots
- Track detection + robot counting on tracks
- May need multiple classes:
  - `track` (the track itself)
  - `robot_on_track` (robots on tracks)

**Future dataset.yaml:**
```yaml
nc: 3
names:
  0: robot
  1: gantry
  2: robot_on_track
```

---

## Counting vs Detection

### Detection
- **What:** Find where robots are
- **Output:** Bounding boxes with coordinates
- **Use:** Visualization, location tracking

### Counting
- **What:** How many robots are there
- **Output:** Integer number
- **Use:** Inventory, capacity planning, reporting

**In this project:**
- Detection enables counting
- Count = Number of detections
- Both are important!

---

## Best Practices for Counting

### ✅ DO's

1. **Annotate every robot** - Missing one = wrong count
2. **Be consistent** - Same annotation style throughout
3. **Handle edge cases** - Partially visible robots still count
4. **Verify counts** - Manually check a sample of images
5. **Test thoroughly** - Verify counting accuracy on test set

### ❌ DON'Ts

1. **Don't skip robots** - Every robot needs a box
2. **Don't double-annotate** - One box per robot
3. **Don't annotate non-robots** - Only actual robots
4. **Don't ignore partial robots** - Still count them
5. **Don't forget to test** - Verify counting works

---

## Example Workflow

### Training Phase
1. Annotate 1,824 images
2. Each annotation = one robot boxed
3. Train model to detect robots
4. Model learns: "This is a robot"

### Inference Phase
1. Load image
2. Model detects robots (draws boxes)
3. Count boxes = robot count
4. Output: "Robot count: 5"

### Validation Phase
1. Test on 182 test images
2. Compare model count vs manual count
3. Calculate accuracy
4. Improve if needed

---

## Summary

**Counting = Detection + Count**

1. **Detect** robots (draw bounding boxes)
2. **Count** boxes (number of detections)
3. **Output** count (integer result)

**For accurate counting:**
- Annotate every robot
- Train model well
- Test thoroughly
- Verify accuracy

**Your 1,824 images will train the model to:**
- Detect robots accurately
- Count them correctly
- Handle various floor layouts

---

**Next Steps:**
1. Annotate all images (every robot!)
2. Train model
3. Test counting accuracy
4. Expand to gantry and tracks later

See `docs/NEXT_STEPS.md` for the complete workflow.

---

**Last Updated:** 2025

