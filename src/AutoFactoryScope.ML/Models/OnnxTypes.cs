using Microsoft.ML.Data;

namespace AutoFactoryScope.ML.Models;

public sealed class ModelInput
{
    [ColumnName("images")] public byte[]? Image { get; init; }
}

public sealed class ModelOutput
{
    [ColumnName("boxes")] public float[]? Boxes { get; init; }
    [ColumnName("scores")] public float[]? Scores { get; init; }
    [ColumnName("labels")] public long[]? Labels { get; init; }
}


