"""
Pre-annotate Images with Existing Model
========================================

This script uses a pre-trained YOLO model to automatically create initial
annotations for your images. You then review and correct them, which is
much faster than annotating from scratch.

What this does:
1. Loads a pre-trained YOLO model (even a generic one helps)
2. Runs it on all your images
3. Converts detections to YOLO annotation format
4. Saves .txt files that you can review and correct

Time savings: 60-80% faster than manual annotation!

Usage:
    python scripts/pre-annotate-with-model.py

Requirements:
    pip install ultralytics
"""

from ultralytics import YOLO
import os
from pathlib import Path

# ============================================================================
# CONFIGURATION
# ============================================================================

# Model to use for pre-annotation
# Even a generic YOLO model can help identify objects
# Options: 'yolov8n.pt', 'yolov8s.pt', 'yolov5s.pt', etc.
# Or use your own trained model: 'runs/detect/robot_detection/weights/best.pt'
MODEL_PATH = 'yolov8n.pt'  # Nano model (fastest, downloads automatically)

# Confidence threshold
# Only create annotations for detections above this confidence
# Lower = more detections (but may include false positives)
# Higher = fewer detections (but more accurate)
CONFIDENCE_THRESHOLD = 0.25

# Image directories to process
IMAGES_DIRS = [
    'data/training/images',
    'data/validation/images',
    'data/test/images'
]

# Label directories (where to save annotations)
LABELS_DIRS = [
    'data/training/labels',
    'data/validation/labels',
    'data/test/labels'
]

# ============================================================================
# SCRIPT
# ============================================================================

def convert_to_yolo_format(box, img_width, img_height):
    """
    Convert YOLO detection box to YOLO annotation format.
    
    YOLO detection format: [x1, y1, x2, y2] (pixel coordinates)
    YOLO annotation format: [class_id, center_x, center_y, width, height] (normalized 0-1)
    """
    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
    
    # Calculate center and size
    center_x = (x1 + x2) / 2.0
    center_y = (y1 + y2) / 2.0
    width = x2 - x1
    height = y2 - y1
    
    # Normalize to 0-1 range
    center_x_norm = center_x / img_width
    center_y_norm = center_y / img_height
    width_norm = width / img_width
    height_norm = height / img_height
    
    # Get class ID (assuming class 0 for robot)
    class_id = int(box.cls[0].cpu().numpy())
    
    return f"{class_id} {center_x_norm:.6f} {center_y_norm:.6f} {width_norm:.6f} {height_norm:.6f}"

def pre_annotate_directory(model, images_dir, labels_dir, split_name):
    """Pre-annotate all images in a directory."""
    
    if not os.path.exists(images_dir):
        print(f"⚠️  Skipping {split_name}: Directory not found: {images_dir}")
        return 0, 0
    
    # Create labels directory if it doesn't exist
    os.makedirs(labels_dir, exist_ok=True)
    
    # Get all images
    image_files = [f for f in os.listdir(images_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    if len(image_files) == 0:
        print(f"⚠️  No images found in {images_dir}")
        return 0, 0
    
    print(f"\nProcessing {split_name} set: {len(image_files)} images")
    print("-" * 70)
    
    annotated = 0
    skipped = 0
    
    for i, img_file in enumerate(image_files, 1):
        img_path = os.path.join(images_dir, img_file)
        label_file = os.path.splitext(img_file)[0] + '.txt'
        label_path = os.path.join(labels_dir, label_file)
        
        # Skip if annotation already exists
        if os.path.exists(label_path):
            skipped += 1
            if i % 50 == 0:
                print(f"  Progress: {i}/{len(image_files)} (skipped existing: {skipped})")
            continue
        
        try:
            # Run model on image
            results = model(img_path, conf=CONFIDENCE_THRESHOLD, verbose=False)
            
            # Get image dimensions
            img = results[0].orig_img
            img_height, img_width = img.shape[:2]
            
            # Convert detections to YOLO format
            annotations = []
            for box in results[0].boxes:
                yolo_line = convert_to_yolo_format(box, img_width, img_height)
                annotations.append(yolo_line)
            
            # Save annotation file
            if len(annotations) > 0:
                with open(label_path, 'w') as f:
                    f.write('\n'.join(annotations))
                annotated += 1
            else:
                # Create empty file if no detections
                # You'll need to annotate these manually
                with open(label_path, 'w') as f:
                    f.write('')
                annotated += 1
            
            if i % 50 == 0:
                print(f"  Progress: {i}/{len(image_files)} (annotated: {annotated}, skipped: {skipped})")
                
        except Exception as e:
            print(f"  ⚠️  Error processing {img_file}: {e}")
            continue
    
    print(f"\n✅ {split_name} complete:")
    print(f"   Annotated: {annotated}")
    print(f"   Skipped (existing): {skipped}")
    
    return annotated, skipped

def main():
    print("=" * 70)
    print("Pre-annotation with YOLO Model")
    print("=" * 70)
    print()
    print("This script will:")
    print("  1. Load a pre-trained YOLO model")
    print("  2. Run it on all your images")
    print("  3. Create initial annotation files (.txt)")
    print("  4. You then review and correct them")
    print()
    print(f"Model: {MODEL_PATH}")
    print(f"Confidence threshold: {CONFIDENCE_THRESHOLD}")
    print()
    
    # Load model
    print("Loading model...")
    try:
        model = YOLO(MODEL_PATH)
        print(f"✅ Model loaded: {MODEL_PATH}")
        print()
    except Exception as e:
        print(f"❌ ERROR: Failed to load model: {e}")
        print()
        print("Make sure you have internet connection for first-time download")
        print("Or specify path to your trained model")
        return 1
    
    # Process each split
    total_annotated = 0
    total_skipped = 0
    
    for images_dir, labels_dir in zip(IMAGES_DIRS, LABELS_DIRS):
        split_name = os.path.basename(os.path.dirname(images_dir))
        annotated, skipped = pre_annotate_directory(model, images_dir, labels_dir, split_name)
        total_annotated += annotated
        total_skipped += skipped
    
    # Summary
    print()
    print("=" * 70)
    print("✅ Pre-annotation Complete!")
    print("=" * 70)
    print()
    print(f"Total annotated: {total_annotated}")
    print(f"Total skipped (already existed): {total_skipped}")
    print()
    print("Next steps:")
    print("  1. Review annotations in LabelImg or Roboflow")
    print("  2. Correct any mistakes")
    print("  3. Add annotations for missed robots")
    print("  4. Verify with: pwsh scripts/verify-annotations.ps1")
    print()
    print("This should be much faster than annotating from scratch!")
    print()
    
    return 0

if __name__ == '__main__':
    exit(main())

