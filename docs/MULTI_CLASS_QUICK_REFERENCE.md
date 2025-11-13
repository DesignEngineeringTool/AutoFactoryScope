# Multi-Class Detection Quick Reference

## TL;DR

**✅ Use ONE ONNX file with multiple classes** (not separate files)

**Why?** Faster, simpler, better accuracy, easier to maintain.

---

## Your Workflow

### Phase 1: Robots Only (Current)
```
dataset.yaml: nc: 1, names: {0: robot}
Train → robot_detection.onnx
```

### Phase 2: Add Gantries
```
dataset.yaml: nc: 2, names: {0: robot, 1: gantry}
Retrain (use previous model) → factory_detection.onnx
```

### Phase 3: Add Tracks
```
dataset.yaml: nc: 3, names: {0: robot, 1: gantry, 2: robot_on_track}
Retrain (use previous model) → factory_detection.onnx
```

---

## Code Changes Made

✅ **Updated `RobotPredictor.cs`** - Now uses class labels from ONNX  
✅ **Updated `DetectionResult.cs`** - Now supports counting by class

**The code is ready for multi-class!** It will work with 1, 2, or 3 classes automatically.

---

## When Adding New Classes

1. **Annotate** new objects (assign class ID: 1=gantry, 2=tracks)
2. **Update `dataset.yaml`** (add new class to `names:`)
3. **Retrain** (use previous model as starting point)
4. **Test** in C# application

---

## Class ID Mapping

| Class ID | Class Name | RobotType Enum |
|----------|------------|----------------|
| 0 | robot | Articulated |
| 1 | gantry | Gantry |
| 2 | robot_on_track | Mobile |

**Important:** Keep class IDs consistent! Don't change them after training.

---

## Using in Code

```csharp
var predictor = new RobotPredictor("models/onnx/factory_detection.onnx");
var result = predictor.Predict(imageBytes, 640, "image.png");

// Total count
Console.WriteLine($"Total objects: {result.Total}");

// Count by class
Console.WriteLine($"Robots: {result.RobotCount}");
Console.WriteLine($"Gantries: {result.GantryCount}");
Console.WriteLine($"Robots on tracks: {result.TrackRobotCount}");

// Count by any class
var gantryCount = result.GetCountByClass("gantry");

// All counts as dictionary
foreach (var (className, count) in result.CountByClass)
{
    Console.WriteLine($"{className}: {count}");
}
```

---

## Training with Transfer Learning

When adding new classes, use your previous model:

```python
# In train_robot_model.py, change:
# model = YOLO('yolov8s.pt')  # ← Old (from scratch)

model = YOLO('runs/detect/robot_detection/weights/best.pt')  # ← Previous model
model.train(data='dataset.yaml', epochs=50)  # ← Fewer epochs needed
```

**Benefits:**
- Faster training (50 epochs vs 100)
- Better accuracy
- Less data needed

---

## Files to Update When Adding Classes

1. ✅ `dataset.yaml` - Add class to `names:`
2. ✅ `RobotPredictor.cs` - Add to `ClassNames` dictionary (already done)
3. ✅ `RobotPredictor.cs` - Add to `MapToRobotType()` (already done)
4. ✅ Retrain model
5. ✅ Test in C#

---

## Summary

| Question | Answer |
|----------|--------|
| **One model or multiple?** | ✅ One multi-class model |
| **When to add classes?** | Start with robots, add others when ready |
| **How to add classes?** | Annotate → Update dataset.yaml → Retrain |
| **Code ready?** | ✅ Yes, already updated! |
| **Backward compatible?** | ✅ Yes, works with 1 class too |

---

## See Also

- `docs/MULTI_CLASS_STRATEGY.md` - Detailed explanation
- `docs/MULTI_CLASS_IMPLEMENTATION.md` - Full code guide
- `src/AutoFactoryScope.ML/Prediction/RobotPredictor.cs` - Updated code

