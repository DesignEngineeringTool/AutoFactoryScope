using Microsoft.ML.Data;

namespace AutoFactoryScope.ML.Models;

public sealed class ModelInput
{
    [ColumnName("images")] public float[]? Image { get; init; }
}

public sealed class ModelOutput
{
    [ColumnName("output0")]
    [VectorType(300, 6)]
    public float[]? Detections { get; init; }
}


