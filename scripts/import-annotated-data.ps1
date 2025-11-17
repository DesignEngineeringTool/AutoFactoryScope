# Import Annotated Data from External Location
# =============================================
# This script imports JPG images and annotations from an external directory
# and sets them up in the correct structure for the pipeline
#
# Usage:
#   pwsh scripts/import-annotated-data.ps1 -SourceDir "C:\path\to\annotated\data"

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDir,
    
    [string]$TargetImagesDir = "data/raw/RobotFloor",
    [string]$TargetLabelsDir = "data/raw/RobotFloor/labels",
    [switch]$ConvertToPng = $true,
    [switch]$CopyAnnotations = $true
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Import Annotated Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host "Target Images: $TargetImagesDir" -ForegroundColor Yellow
Write-Host "Target Labels: $TargetLabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check source directory
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

# Get source images
Write-Host "=== Scanning Source Directory ===" -ForegroundColor Cyan
$sourceImages = Get-ChildItem -Path $SourceDir -Filter "*.jpg" -File -ErrorAction SilentlyContinue
$sourceImages += Get-ChildItem -Path $SourceDir -Filter "*.jpeg" -File -ErrorAction SilentlyContinue
$sourceImages += Get-ChildItem -Path $SourceDir -Filter "*.png" -File -ErrorAction SilentlyContinue

if ($sourceImages.Count -eq 0) {
    Write-Error "No image files (.jpg, .jpeg, .png) found in $SourceDir"
    exit 1
}

Write-Host "Found $($sourceImages.Count) image files" -ForegroundColor Green

# Check for annotations in source directory
$sourceLabels = Get-ChildItem -Path $SourceDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
Write-Host "Found $($sourceLabels.Count) annotation files in source directory" -ForegroundColor $(if ($sourceLabels.Count -gt 0) { "Green" } else { "Yellow" })

# Check for annotations in subdirectories
$labelSubdirs = @("labels", "Labels", "LABELS", "annotations", "Annotations")
$foundLabels = $false
foreach ($subdir in $labelSubdirs) {
    $subdirPath = Join-Path $SourceDir $subdir
    if (Test-Path $subdirPath) {
        $subdirLabels = Get-ChildItem -Path $subdirPath -Filter "*.txt" -File -ErrorAction SilentlyContinue
        if ($subdirLabels.Count -gt 0) {
            Write-Host "Found $($subdirLabels.Count) annotation files in $subdir/" -ForegroundColor Green
            $sourceLabels += $subdirLabels
            $foundLabels = $true
        }
    }
}

# Check parent directory for labels
$parentDir = Split-Path $SourceDir -Parent
$parentLabels = Get-ChildItem -Path $parentDir -Recurse -Filter "*.txt" -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -ne $SourceDir }
if ($parentLabels.Count -gt 0) {
    Write-Host "Found $($parentLabels.Count) annotation files in parent directory" -ForegroundColor Yellow
    Write-Host "Please specify the exact location of annotation files if they're in a different location" -ForegroundColor Yellow
}

Write-Host ""

# Create target directories
Write-Host "=== Creating Target Directories ===" -ForegroundColor Cyan
if (-not (Test-Path $TargetImagesDir)) {
    New-Item -ItemType Directory -Force -Path $TargetImagesDir | Out-Null
    Write-Host "Created: $TargetImagesDir" -ForegroundColor Green
} else {
    Write-Host "Exists: $TargetImagesDir" -ForegroundColor Yellow
}

if (-not (Test-Path $TargetLabelsDir)) {
    New-Item -ItemType Directory -Force -Path $TargetLabelsDir | Out-Null
    Write-Host "Created: $TargetLabelsDir" -ForegroundColor Green
} else {
    Write-Host "Exists: $TargetLabelsDir" -ForegroundColor Yellow
}
Write-Host ""

# Import images
Write-Host "=== Importing Images ===" -ForegroundColor Cyan
$imported = 0
$skipped = 0

foreach ($img in $sourceImages) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($img.Name)
    $targetName = "$baseName.png"
    $targetPath = Join-Path $TargetImagesDir $targetName
    
    # Check if already exists
    if (Test-Path $targetPath) {
        Write-Host "  Skipping $targetName (already exists)" -ForegroundColor Gray
        $skipped++
        continue
    }
    
    try {
        if ($ConvertToPng -and $img.Extension -ne ".png") {
            # Convert to PNG using .NET
            Add-Type -AssemblyName System.Drawing
            $bitmap = New-Object System.Drawing.Bitmap($img.FullName)
            $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bitmap.Dispose()
            Write-Host "  Converted: $($img.Name) -> $targetName" -ForegroundColor Green
        } else {
            # Just copy
            Copy-Item -Path $img.FullName -Destination $targetPath -Force
            Write-Host "  Copied: $($img.Name) -> $targetName" -ForegroundColor Green
        }
        $imported++
    } catch {
        Write-Warning "Failed to import $($img.Name): $_"
    }
}

Write-Host ""
Write-Host "  Imported: $imported images" -ForegroundColor Green
Write-Host "  Skipped: $skipped images (already exist)" -ForegroundColor Yellow
Write-Host ""

# Import annotations
if ($CopyAnnotations -and $sourceLabels.Count -gt 0) {
    Write-Host "=== Importing Annotations ===" -ForegroundColor Cyan
    $importedLabels = 0
    $missingLabels = 0
    
    foreach ($img in $sourceImages) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($img.Name)
        $labelName = "$baseName.txt"
        
        # Find matching label file
        $matchingLabel = $sourceLabels | Where-Object { 
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $baseName 
        } | Select-Object -First 1
        
        if ($matchingLabel) {
            $targetLabelPath = Join-Path $TargetLabelsDir $labelName
            try {
                Copy-Item -Path $matchingLabel.FullName -Destination $targetLabelPath -Force
                $importedLabels++
                
                # Validate YOLO format
                $content = Get-Content $targetLabelPath -Raw
                if (-not [string]::IsNullOrWhiteSpace($content)) {
                    $lines = Get-Content $targetLabelPath
                    $valid = $true
                    foreach ($line in $lines) {
                        $line = $line.Trim()
                        if ([string]::IsNullOrWhiteSpace($line)) { continue }
                        $parts = $line -split '\s+'
                        if ($parts.Count -ne 5) {
                            Write-Warning "  Invalid format in ${labelName}: '$line'"
                            $valid = $false
                        }
                    }
                    if ($valid) {
                        Write-Host "  ✅ $labelName" -ForegroundColor Green
                    }
                } else {
                    Write-Host "  ⚠️  $labelName (empty file)" -ForegroundColor Yellow
                }
            } catch {
                Write-Warning "Failed to copy ${labelName}: $_"
            }
        } else {
            $missingLabels++
            Write-Host "  ❌ Missing annotation for $($img.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  Imported: $importedLabels annotations" -ForegroundColor Green
    Write-Host "  Missing: $missingLabels annotations" -ForegroundColor $(if ($missingLabels -eq 0) { "Green" } else { "Red" })
    Write-Host ""
} else {
    Write-Host "=== Annotations ===" -ForegroundColor Cyan
    if ($sourceLabels.Count -eq 0) {
        Write-Host "  ⚠️  No annotation files found in source directory" -ForegroundColor Yellow
        Write-Host "     Please check if annotations are in a subdirectory or different location" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "     You can manually copy annotation files to: $TargetLabelsDir" -ForegroundColor Yellow
    } else {
        Write-Host "  Found $($sourceLabels.Count) annotation files but CopyAnnotations is disabled" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Import Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images:" -ForegroundColor Cyan
Write-Host "  Source: $($sourceImages.Count) files" -ForegroundColor Yellow
Write-Host "  Imported: $imported files" -ForegroundColor Green
Write-Host "  Target: $TargetImagesDir" -ForegroundColor Yellow
Write-Host ""

if ($sourceLabels.Count -gt 0) {
    Write-Host "Annotations:" -ForegroundColor Cyan
    Write-Host "  Found: $($sourceLabels.Count) files" -ForegroundColor Yellow
    Write-Host "  Imported: $importedLabels files" -ForegroundColor Green
    Write-Host "  Missing: $missingLabels files" -ForegroundColor $(if ($missingLabels -eq 0) { "Green" } else { "Red" })
    Write-Host "  Target: $TargetLabelsDir" -ForegroundColor Yellow
    Write-Host ""
}

# Next steps
Write-Host "Next Steps:" -ForegroundColor Cyan
if ($importedLabels -eq $sourceImages.Count) {
    Write-Host "  ✅ All images and annotations imported!" -ForegroundColor Green
    Write-Host "  Run the pipeline:" -ForegroundColor Cyan
    Write-Host "    pwsh scripts/complete-annotation-pipeline.ps1" -ForegroundColor Yellow
} elseif ($importedLabels -gt 0) {
    Write-Host "  ⚠️  Some annotations are missing" -ForegroundColor Yellow
    Write-Host "  Please add missing annotations to: $TargetLabelsDir" -ForegroundColor Yellow
    Write-Host "  Then run: pwsh scripts/complete-annotation-pipeline.ps1" -ForegroundColor Yellow
} else {
    Write-Host "  ⚠️  No annotations found" -ForegroundColor Yellow
    Write-Host "  Please add annotation files to: $TargetLabelsDir" -ForegroundColor Yellow
    Write-Host "  Or run: pwsh scripts/setup-annotation-workflow.ps1" -ForegroundColor Yellow
}
Write-Host ""

