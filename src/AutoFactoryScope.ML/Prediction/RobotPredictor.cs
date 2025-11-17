using System.Linq;
using AutoFactoryScope.Core.Models;
using AutoFactoryScope.ML.Models;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;

namespace AutoFactoryScope.ML.Prediction;

public sealed class RobotPredictor : IDisposable
{
    readonly string _onnxPath;
    readonly float _conf;
    readonly float _iou;

    InferenceSession? _session;

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
        _session?.Dispose();
        var options = new SessionOptions();
        options.AppendExecutionProvider_CPU();
        // Use file path directly instead of reading bytes - more reliable
        _session = new InferenceSession(_onnxPath, options);
    }

    public DetectionResult Predict(byte[] rgbBytes, int imageSize, string imagePath)
    {
        if (rgbBytes is null || rgbBytes.Length is 0) throw new ArgumentException("image bytes required");
        if (_session is null) throw new InvalidOperationException("Model not loaded");
        var input = ToOnnxInput(rgbBytes, imageSize);
        var tensor = new DenseTensor<float>(input, new[] { 1, 3, imageSize, imageSize });
        using var results = _session.Run(new[] { NamedOnnxValue.CreateFromTensor("images", tensor) });
        var detections = results.First().AsEnumerable<float>().ToArray();
        var result = new DetectionResult { ImagePath = imagePath };
        if (detections.Length == 0) return result;

        var dets = new List<RobotInstance>();
        const int stride = 6; // [x1, y1, x2, y2, score, class]
        for (var i = 0; i <= detections.Length - stride; i += stride)
        {
            var x1 = detections[i + 0];
            var y1 = detections[i + 1];
            var x2 = detections[i + 2];
            var y2 = detections[i + 3];
            var score = detections[i + 4];
            if (score < _conf) continue;
            var classId = (long)Math.Round(detections[i + 5]);
            var className = GetClassName(classId);
            var robotType = MapToRobotType(className);

            var width = Math.Max(0, x2 - x1);
            var height = Math.Max(0, y2 - y1);
            var x = Math.Max(0, x1);
            var y = Math.Max(0, y1);

            dets.Add(new RobotInstance
            {
                Confidence = score,
                Label = className,
                Type = robotType,
                Box = new BoundingBox { X = x, Y = y, Width = width, Height = height }
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

    public void Dispose() => _session?.Dispose();

    static float[] ToOnnxInput(byte[] rgbBytes, int imageSize)
    {
        if (rgbBytes is null) throw new ArgumentNullException(nameof(rgbBytes));
        var channels = 3;
        var plane = imageSize * imageSize;
        if (rgbBytes.Length != plane * channels)
            throw new ArgumentException($"Expected {plane * channels} bytes but received {rgbBytes.Length}");

        var floats = new float[rgbBytes.Length];
        for (var i = 0; i < plane; i++)
        {
            var src = i * channels;
            floats[i] = rgbBytes[src + 0] / 255f;               // R channel
            floats[plane + i] = rgbBytes[src + 1] / 255f;        // G channel
            floats[(plane * 2) + i] = rgbBytes[src + 2] / 255f;  // B channel
        }
        return floats;
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


