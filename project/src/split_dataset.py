import argparse
import os
import random
import shutil
from pathlib import Path
from typing import List, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Split YOLO dataset into train/val/test.")
    parser.add_argument(
        "--dataset-root",
        type=str,
        required=True,
        help="Root folder containing 'images' and 'labels' subfolders.",
    )
    parser.add_argument(
        "--train-ratio",
        type=float,
        default=0.7,
        help="Proportion of images to use for training (default: 0.7).",
    )
    parser.add_argument(
        "--val-ratio",
        type=float,
        default=0.2,
        help="Proportion of images to use for validation (default: 0.2).",
    )
    parser.add_argument(
        "--test-ratio",
        type=float,
        default=0.1,
        help="Proportion of images to use for testing (default: 0.1).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducible splitting.",
    )
    parser.add_argument(
        "--mode",
        choices=["copy", "move"],
        default="copy",
        help="Whether to copy or move files into split directories.",
    )
    parser.add_argument(
        "--image-exts",
        nargs="+",
        default=[".jpg", ".jpeg", ".png"],
        help="Image extensions to include (default: .jpg .jpeg .png).",
    )
    return parser.parse_args()


def list_images(images_dir: Path, exts: List[str]) -> List[Path]:
    files: List[Path] = []
    for ext in exts:
        files.extend(images_dir.glob(f"*{ext}"))
    return sorted(files)


def ensure_label_for_image(image_path: Path, labels_dir: Path) -> Path:
    label_path = labels_dir / (image_path.stem + ".txt")
    return label_path


def split_indices(n: int, train_ratio: float, val_ratio: float, test_ratio: float) -> Tuple[List[int], List[int], List[int]]:
    total_ratio = train_ratio + val_ratio + test_ratio
    if abs(total_ratio - 1.0) > 1e-6:
        raise ValueError(f"Ratios must sum to 1.0, got {total_ratio:.4f}")

    n_train = int(round(n * train_ratio))
    n_val = int(round(n * val_ratio))
    # ensure all go somewhere
    n_test = n - n_train - n_val

    # Adjust if rounding caused off-by-one issues
    if n_test < 0:
        # reduce train/val a bit
        excess = -n_test
        n_test = 0
        if n_val >= excess:
            n_val -= excess
        else:
            excess -= n_val
            n_val = 0
            n_train -= excess

    indices = list(range(n))
    random.shuffle(indices)

    train_idx = indices[:n_train]
    val_idx = indices[n_train:n_train + n_val]
    test_idx = indices[n_train + n_val:]

    return train_idx, val_idx, test_idx


def prepare_split_dirs(root: Path, split_name: str) -> Tuple[Path, Path]:
    split_root = root / split_name
    images_out = split_root / "images"
    labels_out = split_root / "labels"
    images_out.mkdir(parents=True, exist_ok=True)
    labels_out.mkdir(parents=True, exist_ok=True)
    return images_out, labels_out


def transfer_pair(
    image_path: Path,
    label_path: Path,
    dst_images: Path,
    dst_labels: Path,
    mode: str,
) -> None:
    if mode == "copy":
        shutil.copy2(image_path, dst_images / image_path.name)
        if label_path.exists():
            shutil.copy2(label_path, dst_labels / label_path.name)
    else:  # move
        shutil.move(str(image_path), dst_images / image_path.name)
        if label_path.exists():
            shutil.move(str(label_path), dst_labels / label_path.name)


def main() -> None:
    args = parse_args()

    dataset_root = Path(args.dataset_root).resolve()
    images_dir = dataset_root / "images"
    labels_dir = dataset_root / "labels"

    if not images_dir.is_dir():
        raise FileNotFoundError(f"'images' directory not found at {images_dir}")
    if not labels_dir.is_dir():
        raise FileNotFoundError(f"'labels' directory not found at {labels_dir}")

    print(f"Dataset root: {dataset_root}")
    print(f"Images dir:   {images_dir}")
    print(f"Labels dir:   {labels_dir}")
    print(f"Mode:         {args.mode}")
    print(f"Ratios:       train={args.train_ratio}, val={args.val_ratio}, test={args.test_ratio}")
    print(f"Seed:         {args.seed}")

    random.seed(args.seed)

    # 1. List images
    images = list_images(images_dir, args.image_exts)
    if not images:
        raise RuntimeError(f"No images found in {images_dir} with extensions {args.image_exts}")

    print(f"Found {len(images)} images.")

    # Warn about missing labels
    missing_labels = []
    for img in images:
        lbl = ensure_label_for_image(img, labels_dir)
        if not lbl.exists():
            missing_labels.append(img.name)

    if missing_labels:
        print(f"⚠ WARNING: {len(missing_labels)} images have no corresponding label file.")
        for name in missing_labels[:10]:
            print(f"  - {name}")
        if len(missing_labels) > 10:
            print(f"  ... and {len(missing_labels) - 10} more")

    # 2. Compute split indices
    train_idx, val_idx, test_idx = split_indices(
        n=len(images),
        train_ratio=args.train_ratio,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
    )

    print(f"Split sizes:")
    print(f"  Train: {len(train_idx)} images")
    print(f"  Val:   {len(val_idx)} images")
    print(f"  Test:  {len(test_idx)} images")

    # 3. Prepare output directories
    train_img_out, train_lbl_out = prepare_split_dirs(dataset_root, "train")
    val_img_out, val_lbl_out = prepare_split_dirs(dataset_root, "val")
    test_img_out, test_lbl_out = prepare_split_dirs(dataset_root, "test")

    # 4. Transfer files
    def process_split(indices: List[int], dst_images: Path, dst_labels: Path, split_name: str) -> None:
        for idx in indices:
            img_path = images[idx]
            lbl_path = ensure_label_for_image(img_path, labels_dir)
            transfer_pair(img_path, lbl_path, dst_images, dst_labels, args.mode)
        print(f"✔ {split_name}: {len(indices)} images processed.")

    process_split(train_idx, train_img_out, train_lbl_out, "Train")
    process_split(val_idx, val_img_out, val_lbl_out, "Val")
    process_split(test_idx, test_img_out, test_lbl_out, "Test")

    print("\nDone.")
    print("Train/Val/Test splits created under:")
    print(f"  {dataset_root / 'train'}")
    print(f"  {dataset_root / 'val'}")
    print(f"  {dataset_root / 'test'}")
    if args.mode == "copy":
        print("Original 'images' and 'labels' remain unchanged.")
    else:
        print("Original 'images' and 'labels' may now be partially or fully empty (files moved).")


if __name__ == "__main__":
    main()