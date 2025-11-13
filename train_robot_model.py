"""
Train Robot Detection Model
===========================

This script trains a YOLO model to detect and count robots in factory floor images.

What this script does:
1. Loads a pre-trained YOLO model (transfer learning)
2. Trains it on your annotated images
3. Saves the best model
4. Exports to ONNX format for use in C#

Prerequisites:
- Python 3.8+ installed
- Annotated images in data/training/images/ and data/training/labels/
- dataset.yaml file created

Install dependencies:
    pip install ultralytics

Run this script:
    python train_robot_model.py
"""

from ultralytics import YOLO
import os
from pathlib import Path

# ============================================================================
# CONFIGURATION - Adjust these values as needed
# ============================================================================

# Model size: 'n' (nano), 's' (small), 'm' (medium), 'l' (large), 'x' (xlarge)
# Start with 's' for good balance of speed and accuracy
MODEL_SIZE = 's'

# Number of training epochs (iterations through the dataset)
# More epochs = better training, but takes longer
# Start with 100, increase if model isn't good enough
EPOCHS = 100

# Batch size (number of images processed at once)
# Larger = faster training but needs more GPU memory
# Reduce if you get "out of memory" errors
BATCH_SIZE = 16

# Image size (pixels)
# Must match your image size (640 is standard)
IMAGE_SIZE = 640

# Dataset configuration file
# This file tells YOLO where your images and labels are
DATA_YAML = 'dataset.yaml'

# Project name (creates folder with this name for results)
PROJECT_NAME = 'robot_detection'

# Early stopping patience
# Stop training if no improvement for this many epochs
PATIENCE = 20

# ============================================================================
# SCRIPT STARTS HERE
# ============================================================================

def main():
    print("=" * 70)
    print("Robot Detection Model Training")
    print("=" * 70)
    print()
    
    # Step 1: Check if dataset.yaml exists
    print("Step 1: Checking dataset configuration...")
    if not os.path.exists(DATA_YAML):
        print(f"❌ ERROR: {DATA_YAML} not found!")
        print()
        print("Please create dataset.yaml with this content:")
        print("""
path: ./data
train: training/images
val: validation/images
test: test/images

nc: 1
names:
  0: robot
""")
        return 1
    print(f"✅ Found {DATA_YAML}")
    print()
    
    # Step 2: Load pre-trained model
    print("Step 2: Loading pre-trained YOLO model...")
    model_name = f'yolov8{MODEL_SIZE}.pt'
    print(f"   Model: YOLOv8{MODEL_SIZE.upper()}")
    print(f"   This will download automatically if not found")
    print()
    
    try:
        # Load model (downloads automatically if needed)
        model = YOLO(model_name)
        print(f"✅ Model loaded: {model_name}")
        print()
    except Exception as e:
        print(f"❌ ERROR: Failed to load model: {e}")
        print("   Make sure you have internet connection for first-time download")
        return 1
    
    # Step 3: Train the model
    print("Step 3: Starting training...")
    print(f"   Epochs: {EPOCHS}")
    print(f"   Batch size: {BATCH_SIZE}")
    print(f"   Image size: {IMAGE_SIZE}x{IMAGE_SIZE}")
    print()
    print("   This will take 1-4 hours depending on your GPU...")
    print("   You can monitor progress in the output below.")
    print()
    print("-" * 70)
    
    try:
        # Train the model
        # This is where the magic happens - the model learns from your images
        results = model.train(
            data=DATA_YAML,           # Dataset configuration
            epochs=EPOCHS,             # How many times to go through the data
            imgsz=IMAGE_SIZE,         # Input image size
            batch=BATCH_SIZE,          # Images per batch
            name=PROJECT_NAME,        # Project name
            
            # Training options
            patience=PATIENCE,        # Early stopping
            save=True,                # Save checkpoints
            save_period=10,           # Save every N epochs
            plots=True,               # Generate training plots
            
            # Data augmentation (helps model generalize)
            hsv_h=0.015,             # Hue augmentation
            hsv_s=0.7,               # Saturation augmentation
            hsv_v=0.4,               # Value augmentation
            degrees=10,              # Rotation augmentation
            translate=0.1,           # Translation augmentation
            scale=0.5,               # Scale augmentation
            flipud=0.0,              # Vertical flip probability
            fliplr=0.5,              # Horizontal flip probability
            mosaic=1.0,              # Mosaic augmentation
            mixup=0.1,               # Mixup augmentation
            
            # Optimization
            optimizer='AdamW',       # Optimizer algorithm
            lr0=0.01,                # Initial learning rate
            lrf=0.1,                 # Final learning rate
            momentum=0.937,          # Momentum
            weight_decay=0.0005,    # Weight decay
            warmup_epochs=3,         # Warmup epochs
            warmup_momentum=0.8,     # Warmup momentum
            warmup_bias_lr=0.1,      # Warmup bias learning rate
            
            # Validation
            val=True,                # Validate during training
        )
        
        print("-" * 70)
        print()
        print("✅ Training completed!")
        print()
        
    except Exception as e:
        print()
        print(f"❌ ERROR during training: {e}")
        print()
        print("Common issues:")
        print("  - Out of memory: Reduce BATCH_SIZE (try 8 or 4)")
        print("  - Dataset not found: Check dataset.yaml paths")
        print("  - No GPU: Training will be slower on CPU")
        return 1
    
    # Step 4: Show results
    print("Step 4: Training results")
    print()
    
    # Best model is automatically saved
    best_model_path = f'runs/detect/{PROJECT_NAME}/weights/best.pt'
    last_model_path = f'runs/detect/{PROJECT_NAME}/weights/last.pt'
    
    if os.path.exists(best_model_path):
        print(f"✅ Best model saved: {best_model_path}")
    if os.path.exists(last_model_path):
        print(f"✅ Last model saved: {last_model_path}")
    print()
    
    # Step 5: Export to ONNX
    print("Step 5: Exporting to ONNX format...")
    print("   This creates a model file that can be used in C#")
    print()
    
    try:
        # Load the best model
        best_model = YOLO(best_model_path)
        
        # Export to ONNX
        # This converts the PyTorch model to ONNX format
        best_model.export(
            format='onnx',           # Export format
            imgsz=IMAGE_SIZE,       # Input size (must match training)
            dynamic=False,           # Static batch size (faster)
            simplify=True,           # Simplify ONNX model
            opset=12,                # ONNX opset version
            half=False,              # Use FP32 (more accurate)
        )
        
        onnx_path = f'runs/detect/{PROJECT_NAME}/weights/best.onnx'
        if os.path.exists(onnx_path):
            print(f"✅ ONNX model exported: {onnx_path}")
            print()
            
            # Get file size
            size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
            print(f"   File size: {size_mb:.2f} MB")
            print()
        else:
            print("⚠️  WARNING: ONNX file not found after export")
            print("   Check runs/detect/{PROJECT_NAME}/weights/ for files")
            return 1
            
    except Exception as e:
        print(f"❌ ERROR during ONNX export: {e}")
        print()
        print("Try updating ultralytics:")
        print("  pip install --upgrade ultralytics")
        return 1
    
    # Step 6: Final instructions
    print("=" * 70)
    print("✅ Training Complete!")
    print("=" * 70)
    print()
    print("Next steps:")
    print()
    print("1. Copy ONNX model to project:")
    print(f"   Copy: runs/detect/{PROJECT_NAME}/weights/best.onnx")
    print("   To:   models/onnx/robot_detection.onnx")
    print()
    print("2. Test the model in C#:")
    print("   dotnet run --project src/AutoFactoryScope.CLI -- \\")
    print("     --image \"data/test/images/Robotfloor1.png\" \\")
    print("     --model \"models/onnx/robot_detection.onnx\"")
    print()
    print("3. Check training results:")
    print(f"   - Training plots: runs/detect/{PROJECT_NAME}/")
    print("   - Metrics: Look for mAP (mean Average Precision)")
    print("   - Good mAP: > 0.7, Excellent: > 0.8")
    print()
    
    return 0

if __name__ == '__main__':
    exit(main())

