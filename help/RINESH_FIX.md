# Quick Fix for Rinesh

## ❌ The Error

You're seeing:
```
ERROR(S):
  Required option 'image' is missing.
  Required option 'model' is missing.
```

## ✅ The Solution

You need to add `--image` and `--model` arguments to your command.

### Easiest Way (from project root):

```powershell
pwsh scripts/test-model.ps1
```

This will automatically:
- Find a test image
- Use the ONNX model
- Run the detection

### Manual Way:

```powershell
dotnet run --project src/AutoFactoryScope.CLI -- `
  --image "data/test/images/starting_Robotfloor37_rot15.png" `
  --model "models/onnx/robot_detection.onnx"
```

### If Using the Executable Directly:

Make sure you're in the project root, then:

```powershell
.\src\AutoFactoryScope.CLI\bin\Debug\net8.0\AutoFactoryScope.CLI.exe `
  --image "data\test\images\starting_Robotfloor37_rot15.png" `
  --model "models\onnx\robot_detection.onnx"
```

## 📝 What You Need

1. **Image file** - Path to a PNG image to analyze
2. **Model file** - Path to `models/onnx/robot_detection.onnx`

## 🔍 Quick Check

```powershell
# Verify files exist
Test-Path "models/onnx/robot_detection.onnx"
Test-Path "data/test/images"
```

If files don't exist:
```powershell
git pull
```

## 📚 More Help

- **Quick Start:** `docs/RINESH_QUICK_START.md`
- **CLI Help:** `RINESH_CLI_HELP.md`
- **Test Script:** `pwsh scripts/test-model.ps1`

---

**The fix:** Just add `--image` and `--model` to your command! 🚀

