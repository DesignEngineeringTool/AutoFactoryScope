# AutoFactoryScope

AI-powered vision for 2D automotive factory layouts. First feature: **robot detection & counting** from layout images using **C# + ML.NET + ONNX (YOLO)**. Designed to expand to **fixtures, pedestals, EOAT**.

## Quick start

```bash
dotnet build

# Download a YOLO ONNX (example):
# models/onnx/yolov5s.onnx

dotnet run --project src/AutoFactoryScope.CLI -- \
  --image "data/test/sample.jpg" \
  --model "models/onnx/yolov5s.onnx" \
  --json --output results.json
```

## Solution

* Core models, Image preprocessor, ONNX predictor with NMS, CLI.
* Scalable to new classes (fixtures, pedestals, EOAT).

## Roadmap (high level)

* Dataset & annotation (YOLO format).
* Training pipeline & evaluation (mAP, P/R/F1).
* Batch CLI, overlay visuals, API.
