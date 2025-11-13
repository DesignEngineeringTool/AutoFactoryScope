# Best Practices: Saving and Sharing PNG Files for ML Projects

## Table of Contents
1. [Overview](#overview)
2. [Git Best Practices](#git-best-practices)
3. [File Organization](#file-organization)
4. [Storage Strategies](#storage-strategies)
5. [Sharing Methods](#sharing-methods)
6. [Backup Strategies](#backup-strategies)
7. [Compression & Optimization](#compression--optimization)
8. [Version Control for Datasets](#version-control-for-datasets)
9. [Quick Reference](#quick-reference)

---

## Overview

Managing large image datasets (like your 1,824 PNG files, ~206 MB) requires careful planning to:
- ✅ Keep repository size manageable
- ✅ Enable easy sharing and collaboration
- ✅ Maintain data integrity
- ✅ Support version control
- ✅ Facilitate backups

---

## Git Best Practices

### ❌ **DO NOT Commit Large Files to Git**

**Why:**
- Git is designed for code, not large binary files
- Large files slow down clone/pull operations
- GitHub has file size limits (100 MB per file, 1 GB per repo warning)
- Binary files don't benefit from Git's diff/merge features

**Your Current Setup (✅ Good!):**
```gitignore
# From .gitignore
data/
models/
```

**What to Commit:**
- ✅ Scripts (`.ps1`, `.py`, `.cs`)
- ✅ Documentation (`.md`)
- ✅ Configuration files (`.yaml`, `.json`)
- ✅ `.gitkeep` files (to preserve directory structure)

**What NOT to Commit:**
- ❌ PNG image files
- ❌ Trained models (`.pt`, `.onnx`)
- ❌ Large datasets
- ❌ Build artifacts

### ✅ **Use .gitkeep for Directory Structure**

Your repository already does this correctly:
```
data/
├── training/
│   ├── images/
│   │   └── .gitkeep  ✅
│   └── labels/
│       └── .gitkeep  ✅
```

This preserves directory structure without committing files.

---

## File Organization

### Recommended Directory Structure

```
AutoFactoryScope/
├── data/                          # All datasets (gitignored)
│   ├── raw/                       # Original source images
│   │   └── Robotfloor*.png        # 38 original files
│   ├── processed/                 # Processed images
│   │   └── RobotFloor/            # 1,824 processed files
│   ├── training/                  # Training split
│   │   ├── images/                # ~1,277 images
│   │   └── labels/                # Annotation files
│   ├── validation/                # Validation split
│   │   ├── images/                # ~365 images
│   │   └── labels/
│   └── test/                      # Test split
│       ├── images/                # ~182 images
│       └── labels/
├── models/                        # ML models (gitignored)
│   ├── checkpoints/               # Training checkpoints
│   ├── trained/                   # Trained .pt files
│   └── onnx/                      # ONNX models
└── scripts/                       # Processing scripts (committed)
    ├── complete-pipeline.ps1
    ├── compress-images.ps1
    └── ...
```

### Naming Conventions

**Best Practices:**
- ✅ Use descriptive, consistent names
- ✅ Include version/date if needed
- ✅ Avoid special characters
- ✅ Use lowercase with underscores

**Examples:**
```
✅ Good:
- Robotfloor1.png
- starting_Robotfloor1_rot90.png
- processed_Robotfloor1_rot90.png
- robot_detection_v1.onnx

❌ Bad:
- IMG_001.PNG
- robot floor 1.png
- robot-detection-v1.onnx (hyphens in some contexts)
```

---

## Storage Strategies

### Option 1: Local Storage (Current Setup)

**Best For:**
- Single developer
- Small to medium datasets (< 10 GB)
- Fast local access needed

**Pros:**
- ✅ Fast access
- ✅ No internet required
- ✅ Full control
- ✅ No storage costs

**Cons:**
- ❌ Not backed up automatically
- ❌ Not easily shareable
- ❌ Limited by disk space

**Recommendation:** Use for development, but add backup strategy.

### Option 2: Cloud Storage (Recommended for Sharing)

#### A. Google Drive / OneDrive / Dropbox

**Best For:**
- Small teams (2-5 people)
- Datasets < 15 GB
- Simple sharing

**Setup:**
```powershell
# Create symbolic link to cloud folder
# Example: Link data/ to OneDrive/AutoFactoryScope/data/
New-Item -ItemType SymbolicLink -Path "data" -Target "C:\Users\YourName\OneDrive\AutoFactoryScope\data"
```

**Pros:**
- ✅ Easy sharing
- ✅ Automatic sync
- ✅ Version history (OneDrive)
- ✅ Free tier available

**Cons:**
- ❌ Requires internet
- ❌ Sync conflicts possible
- ❌ Limited free storage

#### B. AWS S3 / Azure Blob Storage

**Best For:**
- Large datasets (> 10 GB)
- Production environments
- Team collaboration

**Setup:**
```powershell
# Install AWS CLI
# aws s3 sync data/processed/RobotFloor/ s3://your-bucket/datasets/robot-floor/
```

**Pros:**
- ✅ Scalable
- ✅ Reliable
- ✅ Versioning support
- ✅ Access control

**Cons:**
- ❌ Costs money
- ❌ Requires setup
- ❌ Learning curve

#### C. GitHub LFS (Large File Storage)

**Best For:**
- Small binary files (< 100 MB each)
- Version control needed
- GitHub integration

**Setup:**
```bash
# Install Git LFS
git lfs install

# Track PNG files
git lfs track "*.png"

# Add to .gitattributes
echo "*.png filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
```

**Pros:**
- ✅ Integrated with Git
- ✅ Version control
- ✅ Easy sharing

**Cons:**
- ❌ Costs money for large repos
- ❌ 1 GB free, then $5/month per 50 GB
- ❌ Slower than regular Git

**Recommendation:** Only for small datasets or critical files.

### Option 3: External Drive / NAS

**Best For:**
- Large datasets
- Offline access
- Team sharing (NAS)

**Pros:**
- ✅ Large capacity
- ✅ Fast local access
- ✅ One-time cost

**Cons:**
- ❌ Physical access required
- ❌ Can be lost/damaged
- ❌ Not automatically backed up

---

## Sharing Methods

### Method 1: Cloud Storage Links (Easiest)

**Google Drive:**
1. Upload folder to Google Drive
2. Right-click → Share → Get link
3. Share link with team

**OneDrive:**
1. Upload to OneDrive
2. Right-click → Share
3. Generate sharing link

**Pros:** Simple, no setup required  
**Cons:** Requires account, download needed

### Method 2: Compressed Archive

**Create Archive:**
```powershell
# Create ZIP archive
Compress-Archive -Path "data\processed\RobotFloor\*" -DestinationPath "robot_floor_dataset.zip"

# Or use 7-Zip for better compression
# 7z a -tzip robot_floor_dataset.zip data\processed\RobotFloor\*
```

**Share:**
- Upload to cloud storage
- Share via email (if < 25 MB)
- Use file sharing service (WeTransfer, etc.)

**Pros:** Single file, easy to share  
**Cons:** Must extract, no incremental updates

### Method 3: Dataset Registry / Platform

**Roboflow:**
- Upload images
- Annotate online
- Export in various formats
- Share with team

**Kaggle Datasets:**
- Upload dataset
- Public or private
- Version control
- Free hosting

**Hugging Face Datasets:**
- Upload dataset
- Version control
- Easy sharing
- Free for public datasets

**Pros:** Professional, versioned, easy sharing  
**Cons:** Requires account, some learning curve

### Method 4: Git LFS (For Small Files)

**Setup:**
```bash
# Install Git LFS
git lfs install

# Track specific files
git lfs track "data/raw/*.png"
git lfs track "models/onnx/*.onnx"

# Commit .gitattributes
git add .gitattributes
git commit -m "Add Git LFS tracking"
```

**Pros:** Integrated with Git workflow  
**Cons:** Costs money for large repos

---

## Backup Strategies

### Strategy 1: 3-2-1 Rule

**3 copies:**
1. Original (local)
2. Backup (cloud/external)
3. Offsite backup

**2 different media:**
- Local disk + Cloud storage

**1 offsite:**
- Cloud storage or external drive at different location

### Strategy 2: Automated Backups

**Windows Backup:**
```powershell
# Use Windows File History or Backup
# Settings → Update & Security → Backup
```

**Cloud Sync:**
- OneDrive / Google Drive automatic sync
- Set `data/` folder to sync

**Scripted Backup:**
```powershell
# scripts/backup-dataset.ps1
$source = "data/processed/RobotFloor"
$backup = "\\backup-server\datasets\AutoFactoryScope\$(Get-Date -Format 'yyyy-MM-dd')"

# Copy with verification
Robocopy $source $backup /MIR /R:3 /W:5 /LOG:backup.log
```

### Strategy 3: Versioned Backups

**Use cloud storage with versioning:**
- AWS S3 versioning
- Azure Blob versioning
- OneDrive version history

**Manual versioning:**
```powershell
# Create dated backup
$date = Get-Date -Format "yyyy-MM-dd"
Copy-Item "data/processed/RobotFloor" "backups/dataset_$date" -Recurse
```

---

## Compression & Optimization

### Why Compress?

- ✅ Faster transfers
- ✅ Less storage space
- ✅ Easier sharing

### Compression Methods

#### 1. Image Compression (Already Done ✅)

Your images are already compressed:
- Average size: ~115 KB per image
- Total: 206 MB for 1,824 images
- Good compression ratio

**Further optimization:**
```powershell
# Re-compress if needed (already done)
pwsh scripts/compress-images.ps1 -SourceDir "data/processed/RobotFloor" -OutputDir "data/processed/RobotFloor_compressed"
```

#### 2. Archive Compression

**ZIP (Standard):**
```powershell
Compress-Archive -Path "data\processed\RobotFloor\*" -DestinationPath "robot_floor.zip"
# Typical compression: 206 MB → ~180 MB (10-15% reduction)
```

**7-Zip (Better):**
```powershell
# Install 7-Zip first
7z a -tzip -mx=9 robot_floor.7z data\processed\RobotFloor\*
# Typical compression: 206 MB → ~160 MB (20-25% reduction)
```

**TAR.GZ (Linux/Mac):**
```bash
tar -czf robot_floor.tar.gz data/processed/RobotFloor/
```

### Compression Comparison

| Method | Compression Ratio | Speed | Compatibility |
|--------|------------------|-------|---------------|
| ZIP    | 10-15%           | Fast  | Universal     |
| 7-Zip  | 20-25%           | Medium| Windows       |
| TAR.GZ | 15-20%           | Medium| Linux/Mac     |

---

## Version Control for Datasets

### Problem: Tracking Dataset Changes

Git doesn't work well for large binary files, but you still need to track:
- When dataset was created
- What images are included
- Dataset version/iteration

### Solution 1: Dataset Manifest

**Create manifest file:**
```powershell
# scripts/create-dataset-manifest.ps1
$manifest = @{
    Version = "1.0"
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalImages = (Get-ChildItem "data/processed/RobotFloor" -Filter "*.png").Count
    TotalSize = [math]::Round((Get-ChildItem "data/processed/RobotFloor" -Filter "*.png" | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    Images = (Get-ChildItem "data/processed/RobotFloor" -Filter "*.png" | Select-Object Name, Length, LastWriteTime | ConvertTo-Json)
}

$manifest | ConvertTo-Json -Depth 10 | Out-File "data/dataset_manifest.json"
```

**Commit manifest (not images):**
```bash
git add data/dataset_manifest.json
git commit -m "Add dataset manifest v1.0"
```

### Solution 2: Dataset Versioning

**Naming convention:**
```
data/
├── v1.0/
│   └── RobotFloor/  # Original 1,824 images
├── v1.1/
│   └── RobotFloor/  # Added 100 more images
└── v2.0/
    └── RobotFloor/  # Re-processed with new pipeline
```

### Solution 3: Checksums

**Generate checksums:**
```powershell
# scripts/generate-checksums.ps1
$files = Get-ChildItem "data/processed/RobotFloor" -Filter "*.png"
$checksums = @{}

foreach ($file in $files) {
    $hash = Get-FileHash $file.FullName -Algorithm SHA256
    $checksums[$file.Name] = $hash.Hash
}

$checksums | ConvertTo-Json | Out-File "data/checksums.json"
```

**Verify integrity:**
```powershell
# Verify files haven't changed
$original = Get-Content "data/checksums.json" | ConvertFrom-Json
$current = @{}

foreach ($file in Get-ChildItem "data/processed/RobotFloor" -Filter "*.png") {
    $hash = Get-FileHash $file.FullName -Algorithm SHA256
    $current[$file.Name] = $hash.Hash
}

# Compare
foreach ($key in $original.PSObject.Properties.Name) {
    if ($original.$key -ne $current.$key) {
        Write-Warning "File changed: $key"
    }
}
```

---

## Quick Reference

### ✅ DO's

1. **Keep data/ and models/ in .gitignore** ✅ (Already done)
2. **Use .gitkeep to preserve directory structure** ✅ (Already done)
3. **Compress images before sharing** ✅ (Already done)
4. **Create dataset manifests for version tracking**
5. **Backup datasets regularly**
6. **Use cloud storage for sharing**
7. **Document dataset versions and changes**

### ❌ DON'Ts

1. **Don't commit PNG files to Git**
2. **Don't commit large model files**
3. **Don't store datasets in repository root**
4. **Don't use absolute paths in scripts**
5. **Don't share datasets via email (too large)**
6. **Don't forget to backup**

### Recommended Workflow

```
1. Process images → data/processed/RobotFloor/
2. Create manifest → data/dataset_manifest.json
3. Commit manifest (not images)
4. Backup to cloud storage
5. Share via cloud link or archive
```

### File Size Guidelines

| Size | Method |
|------|--------|
| < 100 MB | Email, Git LFS |
| 100 MB - 1 GB | Cloud storage link, compressed archive |
| 1 GB - 10 GB | Cloud storage, external drive |
| > 10 GB | Cloud storage (S3, Azure), NAS |

---

## Summary

**Your Current Setup:**
- ✅ Data/ and models/ are gitignored
- ✅ Directory structure preserved with .gitkeep
- ✅ Images are compressed (~115 KB each)
- ✅ Well-organized directory structure

**Recommended Additions:**
1. **Create dataset manifest** for version tracking
2. **Set up cloud backup** (OneDrive/Google Drive)
3. **Create sharing workflow** (cloud links or archives)
4. **Document dataset versions** in README or manifest

**Best Practices:**
- Keep large files out of Git
- Use cloud storage for sharing
- Compress before sharing
- Version your datasets (manifest/checksums)
- Backup regularly (3-2-1 rule)

---

**Last Updated:** 2025

