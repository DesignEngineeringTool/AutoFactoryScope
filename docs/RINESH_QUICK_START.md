# Quick Start Guide for Rinesh

## ✅ What's Ready

- **ONNX Model:** `models/onnx/robot_detection.onnx` (42.67 MB)
- **Test Images:** `data/test/images/` (184 test images)
- **CLI Application:** Ready to use

---

## 🚀 How to Run

### Step 1: Pull Latest Code
```powershell
git pull
```

### Step 2: Build the Project (if needed)
```powershell
dotnet build
```

### Step 3: Run with Test Image

**Option A: Using dotnet run (Recommended)**
```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx"
```

**Option B: Using the executable directly**
```powershell
cd src/AutoFactoryScope.CLI\bin\Debug\net8.0
.\AutoFactoryScope.CLI.exe `
  --image "..\..\..\..\..\data\test\images\Robotfloor1.png" `
  --model "..\..\..\..\..\models\onnx\robot_detection.onnx"
```

**Option C: Using absolute paths**
```powershell
.\AutoFactoryScope.CLI.exe `
  --image "C:\Users\Rinesh.Sewpal\Source\Repos\AutoFactoryScope\data\test\images\Robotfloor1.png" `
  --model "C:\Users\Rinesh.Sewpal\Source\Repos\AutoFactoryScope\models\onnx\robot_detection.onnx"
```

---

## 📝 Command Syntax

The CLI requires two arguments:

```
--image <path>    Path to the image file to analyze
--model <path>    Path to the ONNX model file
```

**Optional arguments:**
```
--size <number>        Image size (default: 640)
--confidence <float>   Confidence threshold (default: 0.5)
--iou <float>          IoU threshold (default: 0.4)
--json <true|false>    Output as JSON (default: true)
--output <path>        Output file path
```

---

## 🔍 Troubleshooting

### Error: "Required option 'image' is missing"

**Problem:** You're running the executable without arguments.

**Solution:** Add the required `--image` and `--model` arguments:
```powershell
.\AutoFactoryScope.CLI.exe --image "path\to\image.png" --model "path\to\model.onnx"
```

### Error: "File not found"

**Problem:** Paths are incorrect or relative paths don't work from executable location.

**Solution:** Use absolute paths or navigate to project root:
```powershell
# From project root:
dotnet run --project src/AutoFactoryScope.CLI -- --image "data/test/images/Robotfloor1.png" --model "models/onnx/robot_detection.onnx"
```

### Error: "Model file not found"

**Check:**
1. Did you pull the latest code? `git pull`
2. Is the model file at `models/onnx/robot_detection.onnx`?
3. Use absolute path to be sure

---

## 📁 File Locations

**ONNX Model:**
```
models/onnx/robot_detection.onnx
```

**Test Images:**
```
data/test/images/
  - Robotfloor1.png
  - Robotfloor2.png
  - ... (184 test images)
```

**CLI Executable:**
```
src/AutoFactoryScope.CLI/bin/Debug/net8.0/AutoFactoryScope.CLI.exe
```

---

## ✅ Example Commands

### Test with first test image:
```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx"
```

### Test with custom confidence threshold:
```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx" `
  --confidence 0.3
```

### Test and save output to file:
```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx" `
  --output "results.json"
```

---

## 🎯 Expected Output

When successful, you should see:
- Detected robots with bounding boxes
- Confidence scores
- Robot count
- JSON output (if --json is true)

---

## 💡 Tips

1. **Always use `dotnet run`** from project root - it handles paths correctly
2. **Check file paths** - use absolute paths if relative paths fail
3. **Verify model exists** - check `models/onnx/robot_detection.onnx` is present
4. **Test images are ready** - 184 images in `data/test/images/`

---

## 🆘 Still Having Issues?

1. **Verify files exist:**
   ```powershell
   Test-Path "models/onnx/robot_detection.onnx"
   Test-Path "data/test/images/Robotfloor1.png"
   ```

2. **Check you're in the right directory:**
   ```powershell
   # Should be in project root
   Get-Location
   # Should show: ...\AutoFactoryScope
   ```

3. **Try absolute paths:**
   ```powershell
   $imagePath = Resolve-Path "data/test/images/Robotfloor1.png"
   $modelPath = Resolve-Path "models/onnx/robot_detection.onnx"
   dotnet run --project src/AutoFactoryScope.CLI -- --image $imagePath --model $modelPath
   ```

---

**Ready to test!** 🚀

