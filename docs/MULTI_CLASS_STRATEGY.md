# Multi-Class Detection Strategy

## Your Question

**"Once I have an ONNX file for robots on the floor, what's best practice: create more ONNX files for different types (gantry, tracks) or add to the existing ONNX file?"**

## ✅ Recommended: Single Multi-Class Model

**Use ONE ONNX file with multiple classes:**
- `robot` (class 0)
- `gantry` (class 1)  
- `robot_on_track` (class 2)

---

## Why Single Multi-Class Model?

### ✅ Advantages

1. **One Inference Pass**
   - Detect all object types in a single image scan
   - Faster: 1 model load, 1 inference call
   - Lower memory usage

2. **Better Context Learning**
   - Model learns relationships between objects
   - "Robot near gantry" helps detection accuracy
   - More robust predictions

3. **Easier Deployment**
   - One model file to manage
   - One version to track
   - Simpler code (one predictor instance)

4. **Consistent Performance**
   - All classes trained together = balanced accuracy
   - No need to tune multiple models

5. **Future-Proof**
   - Easy to add new classes (just retrain with more data)
   - No architectural changes needed

### ❌ Disadvantages

1. **Retrain When Adding Classes**
   - Need to retrain entire model when adding new types
   - But: You can use previous model as starting point (transfer learning)

2. **All Classes Must Be Annotated**
   - Need images with all object types
   - But: You can start with one class and add more later

---

## Alternative: Multiple Models (Not Recommended)

### How It Would Work

```
robot_detection.onnx      → Detects robots
gantry_detection.onnx     → Detects gantries  
track_detection.onnx      → Detects robots on tracks
```

### ❌ Disadvantages

1. **Multiple Inference Passes**
   - Run 3 models = 3x slower
   - 3x memory usage
   - More complex code

2. **No Context Between Types**
   - Each model doesn't know about others
   - Can't learn "robot near gantry" relationships

3. **More Complex Code**
   - Need to manage multiple model files
   - Need to merge results from multiple predictions
   - More error-prone

4. **Version Management**
   - 3 model files to version
   - 3 files to update
   - Harder to keep in sync

### ✅ When Multiple Models Make Sense

Only use multiple models if:
- Object types are completely unrelated (e.g., robots vs. text detection)
- You need different confidence thresholds per type
- Different teams maintain different models
- Models are updated independently

**For your use case (all factory objects), single model is better.**

---

## Implementation Strategy

### Phase 1: Start with Robots (Current)

```
dataset.yaml:
  nc: 1
  names:
    0: robot
```

**Train model → `robot_detection.onnx`**

### Phase 2: Add Gantries

1. **Annotate gantries** in your images (add class 1)
2. **Update dataset.yaml:**
   ```yaml
   nc: 2
   names:
     0: robot
     1: gantry
   ```
3. **Retrain model** (use previous model as starting point)
4. **Export → `factory_detection.onnx`** (renamed to reflect multi-class)

### Phase 3: Add Tracks

1. **Annotate robots on tracks** (add class 2)
2. **Update dataset.yaml:**
   ```yaml
   nc: 3
   names:
     0: robot
     1: gantry
     2: robot_on_track
   ```
3. **Retrain model**
4. **Export → `factory_detection.onnx`** (updated)

---

## Code Changes Needed

### Current Code (Single Class)

```csharp
// Currently hardcodes "Robot" and ignores labels
dets.Add(new RobotInstance
{
    Label = "Robot",  // ← Hardcoded!
    Type = RobotType.Articulated,  // ← Hardcoded!
    // ...
});
```

### Updated Code (Multi-Class)

```csharp
// Use labels from ONNX output
var classId = output.Labels[i];  // 0=robot, 1=gantry, 2=robot_on_track
var className = GetClassName(classId);  // Map ID to name

dets.Add(new RobotInstance
{
    Label = className,  // ← From model!
    Type = MapToRobotType(className),  // ← Map to enum
    // ...
});
```

**See `docs/MULTI_CLASS_IMPLEMENTATION.md` for full code updates.**

---

## Best Practices

### 1. Start Simple, Expand Gradually

✅ **Do:**
- Start with robots only
- Get it working well
- Add gantries when ready
- Add tracks when ready

❌ **Don't:**
- Try to annotate everything at once
- Rush to multi-class before single class works

### 2. Use Transfer Learning

When adding new classes:
- Start from your previous model (not from scratch)
- Faster training
- Better accuracy
- Less data needed

**In training script:**
```python
# Load previous model instead of base YOLO
model = YOLO('runs/detect/factory_detection/weights/best.pt')  # ← Previous model
model.train(data='dataset.yaml', epochs=50)  # ← Fewer epochs needed
```

### 3. Maintain Class Order

**Keep class IDs consistent:**
- Class 0 = robot (always)
- Class 1 = gantry (always)
- Class 2 = robot_on_track (always)

**Don't change class IDs** - it breaks existing models!

### 4. Version Your Models

```
models/onnx/
  ├── robot_detection_v1.onnx      (robots only)
  ├── factory_detection_v2.onnx     (robots + gantries)
  └── factory_detection_v3.onnx    (robots + gantries + tracks)
```

Keep old versions for rollback if needed.

### 5. Test Each Addition

After adding a new class:
- Test on validation set
- Check mAP (mean Average Precision) per class
- Ensure new class doesn't hurt existing classes
- Verify in C# application

---

## Summary

| Aspect | Single Multi-Class Model | Multiple Models |
|--------|-------------------------|-----------------|
| **Speed** | ✅ Fast (1 inference) | ❌ Slow (N inferences) |
| **Memory** | ✅ Low | ❌ High (N models) |
| **Accuracy** | ✅ Better (context) | ⚠️ Good (isolated) |
| **Code Complexity** | ✅ Simple | ❌ Complex |
| **Maintenance** | ✅ Easy | ❌ Hard |
| **Adding Classes** | ⚠️ Retrain needed | ✅ Just add model |
| **Best For** | Related objects | Unrelated objects |

**For your use case (factory objects): Single multi-class model is the clear winner.**

---

## Next Steps

1. ✅ **Current:** Train robot detection model (single class)
2. 📝 **Update code:** Make it ready for multi-class (see implementation guide)
3. 🎯 **When ready:** Add gantry annotations, retrain with 2 classes
4. 🎯 **Later:** Add track annotations, retrain with 3 classes

**See `docs/MULTI_CLASS_IMPLEMENTATION.md` for code changes.**

