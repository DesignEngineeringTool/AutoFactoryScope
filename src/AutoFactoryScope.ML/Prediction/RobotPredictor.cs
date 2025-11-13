using Microsoft.ML;
using AutoFactoryScope.Core.Models;
using AutoFactoryScope.ML.Models;

namespace AutoFactoryScope.ML.Prediction;

public sealed class RobotPredictor
{
    readonly MLContext _ml = new();
    readonly string _onnxPath;
    readonly float _conf;
    readonly float _iou;

    ITransformer? _model;
    PredictionEngine<ModelInput, ModelOutput>? _engine;

    // Class name mapping: Maps class ID (from ONNX) to class name
    // Update this when adding new classes to your model
    static readonly Dictionary<long, string> ClassNames = new()
    {
        { 0, "robot" },
        { 1, "gantry" },
        { 2, "robot_on_track" }
    };

    public RobotPredictor(string onnxModelPath, float confidence = 0.5f, float iou = 0.4f)
    {
        _onnxPath = onnxModelPath ?? throw new ArgumentNullException(nameof(onnxModelPath));
        _conf = confidence;
        _iou = iou;
        Load();
    }

    void Load()
    {
        if (File.Exists(_onnxPath) is false) throw new FileNotFoundException(_onnxPath);
        var pipeline = _ml.Transforms.ApplyOnnxModel(
            modelFile: _onnxPath,
            outputColumnNames: new[] { "boxes", "scores", "labels" },
            inputColumnNames: new[] { "images" });
        _model = pipeline.Fit(_ml.Data.LoadFromEnumerable(Array.Empty<ModelInput>()));
        _engine = _ml.Model.CreatePredictionEngine<ModelInput, ModelOutput>(_model);
    }

    public DetectionResult Predict(byte[] rgbBytes, int imageSize, string imagePath)
    {
        if (rgbBytes is null || rgbBytes.Length is 0) throw new ArgumentException("image bytes required");
        if (_engine is null) throw new InvalidOperationException("Model not loaded");
        var output = _engine.Predict(new ModelInput { Image = rgbBytes });
        var result = new DetectionResult { ImagePath = imagePath };
        if (output?.Boxes is null || output.Scores is null) return result;

        var dets = new List<RobotInstance>();
        for (var i = 0; i < output.Scores.Length; i++)
        {
            var s = output.Scores[i];
            if (s < _conf) continue;
            var k = i * 4;
            var cx = output.Boxes[k + 0];
            var cy = output.Boxes[k + 1];
            var w = output.Boxes[k + 2];
            var h = output.Boxes[k + 3];
            var x = Math.Max(0, cx - w / 2);
            var y = Math.Max(0, cy - h / 2);

            // Get class ID from model output (default to 0 if labels not available)
            var classId = output.Labels?[i] ?? 0;
            var className = GetClassName(classId);
            var robotType = MapToRobotType(className);

            dets.Add(new RobotInstance
            {
                Confidence = s,
                Label = className,
                Type = robotType,
                Box = new BoundingBox { X = x, Y = y, Width = w, Height = h }
            });
        }

        var keep = new List<RobotInstance>();
        foreach (var d in dets.OrderByDescending(d => d.Confidence))
        {
            if (d.Box is null) continue;
            var overlaps = keep.Any(k => k.Box is not null && k.Box.IoU(d.Box) >= _iou);
            if (overlaps is false) keep.Add(d);
        }

        result.Robots.AddRange(keep);
        return result;
    }

    /// <summary>
    /// Maps class ID from ONNX model to class name.
    /// Class IDs must match your dataset.yaml configuration.
    /// </summary>
    static string GetClassName(long classId)
    {
        return ClassNames.TryGetValue(classId, out var name) ? name : "unknown";
    }

    /// <summary>
    /// Maps class name to RobotType enum.
    /// Update this when adding new object types.
    /// </summary>
    static RobotType MapToRobotType(string className)
    {
        return className.ToLower() switch
        {
            "robot" => RobotType.Articulated,
            "gantry" => RobotType.Gantry,
            "robot_on_track" => RobotType.Mobile,
            _ => RobotType.Unknown
        };
    }
}


