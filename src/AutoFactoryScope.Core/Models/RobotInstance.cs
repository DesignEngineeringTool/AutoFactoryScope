namespace AutoFactoryScope.Core.Models;

public enum RobotType { Unknown, Articulated, SCARA, Delta, Cobot, Mobile, Gantry, Palletizer }

public sealed class RobotInstance
{
    public Guid Id { get; } = Guid.NewGuid();
    public RobotType Type { get; init; } = RobotType.Articulated;
    public BoundingBox? Box { get; init; }
    public float Confidence { get; init; }
    public string Label { get; init; } = "Robot";
}


