"""Export trained model to ONNX format"""
from ultralytics import YOLO
import os

print("Loading best model...")
model = YOLO('runs/detect/robot_detection/weights/best.pt')

print("Exporting to ONNX...")
try:
    model.export(
        format='onnx',
        imgsz=640,
        simplify=True,
        opset=12,
        half=False
    )
    
    onnx_path = 'runs/detect/robot_detection/weights/best.onnx'
    if os.path.exists(onnx_path):
        size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
        print(f"✅ ONNX model exported: {onnx_path}")
        print(f"   Size: {size_mb:.2f} MB")
    else:
        print("❌ ONNX file not found after export!")
        exit(1)
except Exception as e:
    print(f"❌ Export failed: {e}")
    exit(1)

