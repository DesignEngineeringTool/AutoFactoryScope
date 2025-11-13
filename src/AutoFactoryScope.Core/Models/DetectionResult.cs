namespace AutoFactoryScope.Core.Models;

public sealed class DetectionResult
{
    public required string ImagePath { get; init; }
    public DateTime Timestamp { get; } = DateTime.UtcNow;
    public List<RobotInstance> Robots { get; } = new();
    public int Total => Robots.Count;

    // Count by class (useful for multi-class detection)
    public int RobotCount => Robots.Count(r => r.Label.Equals("robot", StringComparison.OrdinalIgnoreCase));
    public int GantryCount => Robots.Count(r => r.Label.Equals("gantry", StringComparison.OrdinalIgnoreCase));
    public int TrackRobotCount => Robots.Count(r => r.Label.Equals("robot_on_track", StringComparison.OrdinalIgnoreCase));

    // Get count by any class name
    public int GetCountByClass(string className) => Robots.Count(r => r.Label.Equals(className, StringComparison.OrdinalIgnoreCase));

    // Get dictionary of counts by class
    public Dictionary<string, int> CountByClass => Robots
        .GroupBy(r => r.Label, StringComparer.OrdinalIgnoreCase)
        .ToDictionary(g => g.Key, g => g.Count(), StringComparer.OrdinalIgnoreCase);
}


