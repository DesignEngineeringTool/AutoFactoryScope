# Multi-Class Implementation Guide

## Overview

This guide shows how to update your code to support multiple object classes in a single ONNX model.

**Current state:** Code hardcodes "Robot" and ignores class labels from ONNX  
**Target state:** Code uses class labels from ONNX to support robot, gantry, tracks, etc.

---

## Step 1: Update Dataset Configuration

### File: `dataset.yaml`

**Current (single class):**
```yaml
nc: 1
names:
  0: robot
```

**Updated (multi-class):**
```yaml
nc: 3
names:
  0: robot
  1: gantry
  2: robot_on_track
```

**Important:** Class IDs must match your annotation tool (Roboflow, LabelImg, etc.)

---

## Step 2: Update C# Code

### File: `src/AutoFactoryScope.ML/Prediction/RobotPredictor.cs`

**Current code (ignores labels):**
```csharp
dets.Add(new RobotInstance
{
    Confidence = s,
    Label = "Robot",  // ← Hardcoded!
    Type = RobotType.Articulated,  // ← Hardcoded!
    Box = new BoundingBox { X = x, Y = y, Width = w, Height = h }
});
```

**Updated code (uses labels):**
```csharp
// Get class ID from model output
var classId = output.Labels?[i] ?? 0;  // Default to 0 (robot) if null
var className = GetClassName(classId);
var robotType = MapToRobotType(className);

dets.Add(new RobotInstance
{
    Confidence = s,
    Label = className,  // ← From model!
    Type = robotType,   // ← Mapped from class name
    Box = new BoundingBox { X = x, Y = y, Width = w, Height = h }
});
```

**Add helper methods:**
```csharp
// Map class ID to class name
private string GetClassName(long classId)
{
    return classId switch
    {
        0 => "robot",
        1 => "gantry",
        2 => "robot_on_track",
        _ => "unknown"
    };
}

// Map class name to RobotType enum
private RobotType MapToRobotType(string className)
{
    return className.ToLower() switch
    {
        "robot" => RobotType.Articulated,
        "gantry" => RobotType.Gantry,
        "robot_on_track" => RobotType.Mobile,
        _ => RobotType.Unknown
    };
}
```

---

## Step 3: Update Training Script (Optional)

### File: `train_robot_model.py`

**When adding new classes, use transfer learning:**

```python
# Instead of starting from scratch:
# model = YOLO('yolov8s.pt')  # ← Base model

# Load your previous model:
model = YOLO('runs/detect/robot_detection/weights/best.pt')  # ← Previous model

# Then train (fewer epochs needed):
results = model.train(
    data='dataset.yaml',
    epochs=50,  # ← Fewer epochs (was 100)
    # ... rest of config
)
```

**Benefits:**
- Faster training (50 epochs vs 100)
- Better accuracy (model already knows robots)
- Less data needed for new classes

---

## Step 4: Update Annotation Workflow

### When Adding New Classes

1. **Annotate new objects** in your images
   - Use same annotation tool (Roboflow, LabelImg)
   - Assign correct class ID (1 for gantry, 2 for tracks)

2. **Update dataset.yaml** (add new class)

3. **Retrain model** (use previous model as starting point)

4. **Test in C#** (verify new classes work)

---

## Step 5: Handle Class Name Mapping

### Option A: Hardcode Mapping (Simple)

**In `RobotPredictor.cs`:**
```csharp
private static readonly Dictionary<long, string> ClassNames = new()
{
    { 0, "robot" },
    { 1, "gantry" },
    { 2, "robot_on_track" }
};

private string GetClassName(long classId)
{
    return ClassNames.TryGetValue(classId, out var name) ? name : "unknown";
}
```

### Option B: Load from Config (Advanced)

**Create `models/onnx/classes.json`:**
```json
{
  "0": "robot",
  "1": "gantry",
  "2": "robot_on_track"
}
```

**Load in `RobotPredictor`:**
```csharp
private readonly Dictionary<long, string> _classNames;

public RobotPredictor(string onnxModelPath, string? classesConfigPath = null)
{
    // ... existing code ...
    
    // Load class names from config
    if (classesConfigPath != null && File.Exists(classesConfigPath))
    {
        var json = File.ReadAllText(classesConfigPath);
        var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
        _classNames = dict?.ToDictionary(
            kvp => long.Parse(kvp.Key),
            kvp => kvp.Value
        ) ?? new Dictionary<long, string>();
    }
    else
    {
        // Default fallback
        _classNames = new Dictionary<long, string>
        {
            { 0, "robot" },
            { 1, "gantry" },
            { 2, "robot_on_track" }
        };
    }
}
```

**Recommendation:** Start with Option A (hardcoded), move to Option B if you have many classes.

---

## Step 6: Update DetectionResult (Optional)

### File: `src/AutoFactoryScope.Core/Models/DetectionResult.cs`

**Current:**
```csharp
public sealed class DetectionResult
{
    public List<RobotInstance> Robots { get; } = new();
    public int Total => Robots.Count;
}
```

**Enhanced (group by class):**
```csharp
public sealed class DetectionResult
{
    public List<RobotInstance> Robots { get; } = new();
    public int Total => Robots.Count;
    
    // New: Count by class
    public int RobotCount => Robots.Count(r => r.Label == "robot");
    public int GantryCount => Robots.Count(r => r.Label == "gantry");
    public int TrackRobotCount => Robots.Count(r => r.Label == "robot_on_track");
    
    // New: Group by class
    public Dictionary<string, int> CountByClass => Robots
        .GroupBy(r => r.Label)
        .ToDictionary(g => g.Key, g => g.Count());
}
```

---

## Step 7: Testing

### Test Single Class (Current)

```bash
# Train with robots only
python train_robot_model.py

# Test in C#
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/image.png" \
  --model "models/onnx/robot_detection.onnx"
```

**Expected:** All detections labeled "robot"

### Test Multi-Class (After Adding Classes)

```bash
# Train with robots + gantries
python train_robot_model.py

# Test in C#
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/image.png" \
  --model "models/onnx/factory_detection.onnx"
```

**Expected:** Detections labeled "robot" or "gantry" based on what's in image

---

## Migration Checklist

- [ ] Update `dataset.yaml` with new classes
- [ ] Update `RobotPredictor.cs` to use `output.Labels`
- [ ] Add `GetClassName()` method
- [ ] Add `MapToRobotType()` method
- [ ] Test with single class (verify still works)
- [ ] Add annotations for new class
- [ ] Retrain model (use transfer learning)
- [ ] Test with multi-class model
- [ ] Update `DetectionResult` if needed
- [ ] Update documentation

---

## Common Issues

### Issue: Labels Array is Null

**Symptom:** `output.Labels` is null

**Fix:** Check ONNX export settings:
```python
# In train_robot_model.py, ensure labels are exported:
best_model.export(
    format='onnx',
    # ... other settings
)
```

**Workaround:** Default to class 0 if null:
```csharp
var classId = output.Labels?[i] ?? 0;
```

### Issue: Wrong Class Names

**Symptom:** Detections show wrong labels

**Fix:** Verify class IDs match `dataset.yaml`:
- Class 0 in YOLO = first class in `names:` list
- Class 1 in YOLO = second class in `names:` list
- etc.

### Issue: Model Performance Drops

**Symptom:** Adding new class hurts existing class accuracy

**Fix:**
- Use transfer learning (start from previous model)
- Ensure balanced dataset (similar number of images per class)
- Train for more epochs
- Check mAP per class in training results

---

## Example: Complete Updated RobotPredictor

See `src/AutoFactoryScope.ML/Prediction/RobotPredictor.cs` for full implementation.

---

## Next Steps

1. **Now:** Keep single class, but update code to be multi-class ready
2. **When ready:** Add gantry annotations, retrain with 2 classes
3. **Later:** Add track annotations, retrain with 3 classes

**The code will work with 1, 2, or 3 classes automatically!**

