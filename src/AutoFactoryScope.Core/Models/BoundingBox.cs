namespace AutoFactoryScope.Core.Models;

public sealed class BoundingBox
{
    public float X { get; init; }
    public float Y { get; init; }
    public float Width { get; init; }
    public float Height { get; init; }

    public float X2 => X + Width;
    public float Y2 => Y + Height;
    public float Area => Width * Height;

    public float IoU(BoundingBox other)
    {
        if (other is null) return 0f;
        var ix1 = Math.Max(X, other.X);
        var iy1 = Math.Max(Y, other.Y);
        var ix2 = Math.Min(X2, other.X2);
        var iy2 = Math.Min(Y2, other.Y2);
        var iw = Math.Max(0, ix2 - ix1);
        var ih = Math.Max(0, iy2 - iy1);
        var inter = iw * ih;
        var denom = Area + other.Area - inter;
        if (denom <= 0) return 0f;
        return inter / denom;
    }
}


