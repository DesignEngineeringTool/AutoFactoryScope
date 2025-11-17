"""
Extract Annotations from Images
================================
This script detects visible annotations in images (text labels, bounding boxes)
and converts them to YOLO format annotation files.

It looks for:
- "Robot" text labels
- Bounding boxes (rectangles) drawn on images
- Any visible annotations

Requirements:
    pip install opencv-python pillow numpy
    pip install pytesseract  # For OCR (optional, for text detection)
"""

import os
import cv2
import numpy as np
from PIL import Image
import sys
from pathlib import Path

# Try to import OCR (optional)
try:
    import pytesseract
    HAS_OCR = True
except ImportError:
    HAS_OCR = False
    print("⚠️  pytesseract not installed. Text detection will be limited.")
    print("   Install: pip install pytesseract")


def detect_text_labels(image, text="Robot"):
    """Detect text labels in image using OCR."""
    if not HAS_OCR:
        return []
    
    try:
        # Get OCR data
        data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
        
        # Find text matching "Robot"
        boxes = []
        n_boxes = len(data['text'])
        for i in range(n_boxes):
            if text.lower() in data['text'][i].lower():
                x = data['left'][i]
                y = data['top'][i]
                w = data['width'][i]
                h = data['height'][i]
                boxes.append((x, y, w, h))
        
        return boxes
    except Exception as e:
        print(f"  OCR error: {e}")
        return []


def detect_rectangles(image):
    """Detect rectangular bounding boxes in image."""
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    
    # Detect edges
    edges = cv2.Canny(gray, 50, 150)
    
    # Find contours
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    boxes = []
    img_height, img_width = image.shape[:2]
    min_area = (img_width * img_height) * 0.01  # At least 1% of image
    
    for contour in contours:
        # Get bounding rectangle
        x, y, w, h = cv2.boundingRect(contour)
        area = w * h
        
        # Filter by size and aspect ratio
        if area > min_area and w > 20 and h > 20:
            # Check if it looks like a bounding box (rectangular, not too elongated)
            aspect_ratio = w / h if h > 0 else 0
            if 0.2 < aspect_ratio < 5.0:  # Reasonable aspect ratio
                boxes.append((x, y, w, h))
    
    return boxes


def detect_black_boxes(image):
    """Detect black rectangular bounding boxes (common in CAD drawings)."""
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    
    # Threshold to find dark/black regions
    _, thresh = cv2.threshold(gray, 50, 255, cv2.THRESH_BINARY_INV)
    
    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    boxes = []
    img_height, img_width = image.shape[:2]
    min_area = (img_width * img_height) * 0.005  # At least 0.5% of image
    
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        area = w * h
        
        # Filter by size
        if area > min_area and w > 15 and h > 15:
            # Check if it's roughly rectangular
            contour_area = cv2.contourArea(contour)
            if contour_area > 0:
                extent = area / contour_area
                if extent > 0.7:  # At least 70% filled (rectangular)
                    boxes.append((x, y, w, h))
    
    return boxes


def convert_to_yolo(x, y, w, h, img_width, img_height):
    """Convert pixel coordinates to YOLO format (normalized)."""
    # Calculate center
    center_x = (x + w / 2) / img_width
    center_y = (y + h / 2) / img_height
    
    # Normalize width and height
    norm_w = w / img_width
    norm_h = h / img_height
    
    # Ensure values are in valid range
    center_x = max(0, min(1, center_x))
    center_y = max(0, min(1, center_y))
    norm_w = max(0, min(1, norm_w))
    norm_h = max(0, min(1, norm_h))
    
    return f"0 {center_x:.6f} {center_y:.6f} {norm_w:.6f} {norm_h:.6f}"


def process_image(image_path, output_dir):
    """Process a single image and extract annotations."""
    print(f"Processing: {os.path.basename(image_path)}")
    
    # Load image
    img = cv2.imread(image_path)
    if img is None:
        print(f"  [ERROR] Could not load image")
        return False
    
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_height, img_width = img_rgb.shape[:2]
    
    # Detect annotations using multiple methods
    all_boxes = []
    
    # Method 1: Detect text labels
    if HAS_OCR:
        text_boxes = detect_text_labels(img_rgb, "Robot")
        if text_boxes:
            print(f"  Found {len(text_boxes)} text labels")
            all_boxes.extend(text_boxes)
    
    # Method 2: Detect black bounding boxes (common in CAD drawings)
    black_boxes = detect_black_boxes(img_rgb)
    if black_boxes:
        print(f"  Found {len(black_boxes)} black boxes")
        all_boxes.extend(black_boxes)
    
    # Method 3: Detect rectangles
    rect_boxes = detect_rectangles(img_rgb)
    if rect_boxes:
        print(f"  Found {len(rect_boxes)} rectangles")
        all_boxes.extend(rect_boxes)
    
    # Remove duplicates (boxes that overlap significantly)
    unique_boxes = []
    for box in all_boxes:
        x, y, w, h = box
        is_duplicate = False
        
        for ux, uy, uw, uh in unique_boxes:
            # Check overlap
            overlap_x = max(0, min(x + w, ux + uw) - max(x, ux))
            overlap_y = max(0, min(y + h, uy + uh) - max(y, uy))
            overlap_area = overlap_x * overlap_y
            
            box_area = w * h
            ubox_area = uw * uh
            overlap_ratio = overlap_area / min(box_area, ubox_area) if min(box_area, ubox_area) > 0 else 0
            
            if overlap_ratio > 0.5:  # More than 50% overlap
                is_duplicate = True
                break
        
        if not is_duplicate:
            unique_boxes.append(box)
    
    # Convert to YOLO format
    yolo_lines = []
    for x, y, w, h in unique_boxes:
        yolo_line = convert_to_yolo(x, y, w, h, img_width, img_height)
        yolo_lines.append(yolo_line)
    
    # Save annotation file
    base_name = Path(image_path).stem
    label_path = os.path.join(output_dir, f"{base_name}.txt")
    
    with open(label_path, 'w') as f:
        f.write('\n'.join(yolo_lines))
    
    print(f"  [OK] Created annotation: {len(yolo_lines)} objects")
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract-annotations-from-images.py <images_dir> [output_dir]")
        print("")
        print("Example:")
        print("  python extract-annotations-from-images.py \"C:\\path\\to\\images\" \"data/raw/RobotFloor/labels\"")
        sys.exit(1)
    
    images_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(images_dir, "labels")
    
    if not os.path.exists(images_dir):
        print(f"[ERROR] Images directory not found: {images_dir}")
        sys.exit(1)
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("=" * 70)
    print("Extract Annotations from Images")
    print("=" * 70)
    print(f"Images: {images_dir}")
    print(f"Output: {output_dir}")
    print("")
    
    # Get all image files
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
    image_files = []
    for ext in image_extensions:
        image_files.extend(Path(images_dir).glob(f"*{ext}"))
        image_files.extend(Path(images_dir).glob(f"*{ext.upper()}"))
    
    if not image_files:
        print(f"[ERROR] No image files found in {images_dir}")
        sys.exit(1)
    
    print(f"Found {len(image_files)} images")
    print("")
    
    # Process each image
    success_count = 0
    for img_path in sorted(image_files):
        if process_image(str(img_path), output_dir):
            success_count += 1
        print("")
    
    print("=" * 70)
    print(f"[SUCCESS] Processed {success_count}/{len(image_files)} images")
    print(f"Annotations saved to: {output_dir}")
    print("")
    print("[IMPORTANT] Please review the generated annotations!")
    print("   The automatic detection may not be perfect.")
    print("   You may need to manually adjust some bounding boxes.")
    print("")


if __name__ == "__main__":
    main()

