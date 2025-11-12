using CommandLine;
using Serilog;
using AutoFactoryScope.ImageProcessing.Preprocessors;
using AutoFactoryScope.ML.Prediction;

Log.Logger = new LoggerConfiguration().WriteTo.Console().CreateLogger();

return Parser.Default.ParseArguments<PredictOptions>(args)
    .MapResult((PredictOptions o) => RunPredict(o), _ => 1);

static int RunPredict(PredictOptions o)
{
    try
    {
        if (File.Exists(o.Image) is false) { Serilog.Log.Error("Image not found: {P}", o.Image); return 2; }
        if (File.Exists(o.Model) is false) { Serilog.Log.Error("Model not found: {P}", o.Model); return 3; }

        var pre = new ImagePreprocessor();
        var rgb = pre.Preprocess(o.Image, o.Size, true);

        var predictor = new RobotPredictor(o.Model, o.Confidence, o.Iou);
        var result = predictor.Predict(rgb, o.Size, o.Image);

        Serilog.Log.Information("Robot count: {C}", result.Total);
        if (o.Json)
        {
            var json = System.Text.Json.JsonSerializer.Serialize(result, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(o.Output ?? "result.json", json);
            Serilog.Log.Information("Saved {F}", o.Output ?? "result.json");
        }
        return 0;
    }
    catch (Exception ex) { Serilog.Log.Fatal(ex, "Failed"); return 99; }
}

public sealed class PredictOptions
{
    [Option("image", Required = true)] public string Image { get; set; } = string.Empty;
    [Option("model", Required = true)] public string Model { get; set; } = string.Empty;
    [Option("size", Default = 640)] public int Size { get; set; }
    [Option("confidence", Default = 0.5f)] public float Confidence { get; set; }
    [Option("iou", Default = 0.4f)] public float Iou { get; set; }
    [Option("json", Default = true)] public bool Json { get; set; }
    [Option("output")] public string? Output { get; set; }
}
