namespace AutoFactoryScope.Core.Models;

public sealed class DetectionResult
{
    public required string ImagePath { get; init; }
    public DateTime Timestamp { get; } = DateTime.UtcNow;
    public List<RobotInstance> Robots { get; } = new();
    public int Total => Robots.Count;
}


