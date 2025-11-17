# Help for Rinesh - CLI Usage

## ❌ Error You're Seeing

```
ERROR(S):
  Required option 'image' is missing.
  Required option 'model' is missing.
```

## ✅ Solution

You need to provide the `--image` and `--model` arguments when running the CLI.

### Correct Command (from project root):

```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/Robotfloor1.png" `
  --model "models/onnx/robot_detection.onnx"
```

### Or using the executable directly:

```powershell
cd src\AutoFactoryScope.CLI\bin\Debug\net8.0
.\AutoFactoryScope.CLI.exe `
  --image "..\..\..\..\..\data\test\images\Robotfloor1.png" `
  --model "..\..\..\..\..\models\onnx\robot_detection.onnx"
```

## 📝 What Each Argument Does

- `--image` - Path to the image file you want to analyze
- `--model` - Path to the ONNX model file (`models/onnx/robot_detection.onnx`)

## 🔍 Quick Check

Before running, verify files exist:

```powershell
# Check model exists
Test-Path "models/onnx/robot_detection.onnx"

# Check test image exists  
Test-Path "data/test/images/Robotfloor1.png"
```

If files don't exist, run:
```powershell
git pull
```

## 📚 Full Guide

See `docs/RINESH_QUICK_START.md` for complete instructions.

---

**Quick fix:** Add `--image` and `--model` arguments to your command! 🚀

