# AutoFactoryScope - Developer Handover

## Welcome

This document provides a complete handover guide for developers joining the AutoFactoryScope project. It covers repository structure, key files, setup instructions, and development workflow.

---

## Repository Overview

**AutoFactoryScope** is an AI-powered vision system for analyzing 2D automotive factory layouts. The first feature focuses on **robot detection and counting** from layout images using **C# + ML.NET + ONNX (YOLO)**.

**Tech Stack:**
- .NET 8
- ML.NET 5.0
- ONNX Runtime
- ImageSharp (image processing)
- CommandLineParser (CLI)
- Serilog (logging)
- xUnit (testing)

---

## Repository Structure

```
AutoFactoryScope/
├── src/                          # Source code projects
│   ├── AutoFactoryScope.Core/   # Core domain models
│   │   └── Models/
│   │       ├── BoundingBox.cs
│   │       ├── RobotInstance.cs
│   │       └── DetectionResult.cs
│   ├── AutoFactoryScope.ML/     # ML.NET ONNX inference
│   │   ├── Models/
│   │   │   └── OnnxTypes.cs
│   │   └── Prediction/
│   │       └── RobotPredictor.cs
│   ├── AutoFactoryScope.ImageProcessing/  # Image preprocessing
│   │   └── Preprocessors/
│   │       └── ImagePreprocessor.cs
│   └── AutoFactoryScope.CLI/    # Console application
│       └── Program.cs
├── tests/                        # Test projects
│   └── AutoFactoryScope.Core.Tests/
├── data/                        # Dataset directories (gitignored)
│   ├── raw/                     # Raw input images
│   ├── processed/               # Processed images
│   ├── training/                # Training dataset
│   │   ├── images/
│   │   └── labels/
│   ├── validation/              # Validation dataset
│   │   ├── images/
│   │   └── labels/
│   └── test/                    # Test dataset
│       ├── images/
│       └── labels/
├── models/                      # ML models (gitignored)
│   ├── checkpoints/             # Training checkpoints
│   ├── trained/                 # Trained models
│   └── onnx/                    # ONNX models (place YOLO models here)
├── docs/                        # Documentation
│   ├── HANDOVER.md             # This file
│   └── Roadmap.md              # Development roadmap
├── scripts/                     # Utility scripts
│   └── prepare-dataset.ps1     # Dataset preparation script
├── .github/
│   └── workflows/
│       └── dotnet-build.yml     # CI/CD pipeline
├── AutoFactoryScope.sln        # Visual Studio solution file
└── README.md                    # Quick start guide
```

---

## Key Files & Locations

### Solution & Projects
- **`AutoFactoryScope.sln`** - Main solution file (open this in Visual Studio)
- All projects are in `src/` and `tests/` directories
- Projects are organized in solution folders (`src` and `tests`)

### Core Models
**Location:** `src/AutoFactoryScope.Core/Models/`
- `BoundingBox.cs` - Bounding box with IoU calculation
- `RobotInstance.cs` - Detected robot instance with type enum
- `DetectionResult.cs` - Container for detection results

### ML Inference
**Location:** `src/AutoFactoryScope.ML/`
- `Models/OnnxTypes.cs` - ML.NET input/output types for ONNX
- `Prediction/RobotPredictor.cs` - ONNX model loading, prediction, and NMS filtering

### Image Processing
**Location:** `src/AutoFactoryScope.ImageProcessing/Preprocessors/`
- `ImagePreprocessor.cs` - Image resizing, padding, and RGB conversion

### CLI Application
**Location:** `src/AutoFactoryScope.CLI/`
- `Program.cs` - Main entry point with command-line parsing

### Documentation
- **`README.md`** - Quick start guide with CLI examples
- **`docs/Roadmap.md`** - 3-week development task checklist
- **`docs/HANDOVER.md`** - This handover document

### Configuration
- **`.gitignore`** - Excludes `data/` and `models/` directories
- **`.github/workflows/dotnet-build.yml`** - CI/CD pipeline (builds on push/PR)

---

## Getting Started

### Prerequisites
- .NET 8 SDK (or later)
- Visual Studio 2022 (recommended) or VS Code
- A YOLO ONNX model (download and place in `models/onnx/`)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DesignEngineeringTool/AutoFactoryScope.git
   cd AutoFactoryScope
   ```

2. **Open in Visual Studio:**
   - Open `AutoFactoryScope.sln`
   - Wait for NuGet packages to restore
   - All projects should load automatically

3. **Build the solution:**
   ```bash
   dotnet build
   ```
   Should complete with 0 warnings, 0 errors.

4. **Get a YOLO ONNX model:**
   - Download a YOLO model (e.g., YOLOv5, YOLOv8)
   - Convert to ONNX format if needed
   - Place in `models/onnx/yolov5s.onnx` (or your preferred name)

### Running the CLI

**Basic usage:**
```bash
dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/sample.jpg" \
  --model "models/onnx/yolov5s.onnx" \
  --json --output results.json
```

**CLI Options:**
- `--image` (required) - Input image path
- `--model` (required) - ONNX model path
- `--size` (default: 640) - Square input size
- `--confidence` (default: 0.5) - Confidence threshold
- `--iou` (default: 0.4) - NMS IoU threshold
- `--json` (default: true) - Output JSON file
- `--output` - JSON output file path (default: `result.json`)

---

## Development Workflow

### Code Style Guidelines
- **Guard clauses** - Use early returns, no `else`/`elseif`
- **Max 2 levels nesting** - Keep code flat
- **Use `is` / `is not`** instead of `!` operator
- **Composition over inheritance**
- **Minimal public APIs**

### Running Tests
```bash
dotnet test
```

### Building for Release
```bash
dotnet build --configuration Release
```

### CI/CD
- GitHub Actions automatically builds and tests on push/PR
- Workflow: `.github/workflows/dotnet-build.yml`
- Runs on Windows with .NET 8.0.x

---

## Important Notes

### Data & Models
- `data/` and `models/` directories are **gitignored**
- Place training data in `data/training/`
- Place ONNX models in `models/onnx/`
- `.gitkeep` files preserve directory structure

### Project Dependencies
- **CLI** depends on: ML, ImageProcessing, Core
- **ML** depends on: Core
- **ImageProcessing** depends on: Core
- **Tests** depend on: Core

### Current Status
- ✅ Solution compiles (0 warnings, 0 errors)
- ✅ All projects load in Visual Studio 2022
- ✅ Core models implemented
- ✅ ONNX inference pipeline ready
- ✅ CLI with command-line parsing
- ⏳ ONNX model needed (place in `models/onnx/`)
- ⏳ Unit tests to be added (see Roadmap)

---

## Next Steps

1. **Review the Roadmap:** `docs/Roadmap.md`
   - Week 1: Foundation tasks
   - Week 2: Data & Visualization
   - Week 3: Quality improvements

2. **Get an ONNX Model:**
   - Download or train a YOLO model
   - Convert to ONNX format
   - Place in `models/onnx/`

3. **Test the Pipeline:**
   - Add a test image to `data/test/`
   - Run the CLI with your model
   - Verify JSON output

4. **Start Development:**
   - Check off tasks in `docs/Roadmap.md`
   - Add unit tests (Week 1 task)
   - Implement visualization (Week 2 task)

---

## Troubleshooting

### Projects Show as "Unloaded" in Visual Studio
- Right-click solution → "Reload Solution"
- Or close VS, delete `.vs` folder, reopen

### Build Errors
- Run `dotnet restore`
- Check .NET SDK version: `dotnet --version` (should be 8.0+)

### ONNX Model Not Found
- Ensure model is in `models/onnx/`
- Check file path in CLI command
- Verify model is valid ONNX format

### Permission Issues (Git)
- Repository uses HTTPS with Personal Access Token
- Token stored in remote URL (consider using Git Credential Manager)

---

## Resources

- **ML.NET Documentation:** https://learn.microsoft.com/dotnet/machine-learning/
- **ONNX Runtime:** https://onnxruntime.ai/
- **ImageSharp:** https://sixlabors.com/products/imagesharp/
- **YOLO Models:** https://github.com/ultralytics/ultralytics

---

## Contact & Support

For questions or issues:
- Check `docs/Roadmap.md` for planned features
- Review `README.md` for quick start
- Open an issue on GitHub if needed

---

**Last Updated:** November 2025  
**Solution Status:** ✅ Ready for Development  
**Build Status:** ✅ Passing (0 warnings, 0 errors)

