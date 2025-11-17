# Find Annotation Files
# =====================
# This script helps you locate annotation files that might be in various locations

param(
    [string]$SearchRoot = "C:\Users\georgem\source\repos\AutoFactoryScope_data"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Searching for Annotation Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Searching in: $SearchRoot" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $SearchRoot)) {
    Write-Host "Search root not found. Trying common locations..." -ForegroundColor Yellow
    $SearchRoot = "C:\Users\georgem\source\repos"
}

# Search for .txt files (YOLO format)
Write-Host "=== Searching for .txt files (YOLO annotations) ===" -ForegroundColor Cyan
$txtFiles = Get-ChildItem -Path $SearchRoot -Recurse -Filter "*.txt" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Robotfloor" }

if ($txtFiles.Count -gt 0) {
    Write-Host "Found $($txtFiles.Count) .txt files that might be annotations:" -ForegroundColor Green
    Write-Host ""
    $txtFiles | ForEach-Object {
        Write-Host "  📄 $($_.FullName)" -ForegroundColor Yellow
        # Show first few lines to verify it's an annotation file
        try {
            $content = Get-Content $_.FullName -TotalCount 3
            if ($content.Count -gt 0) {
                $firstLine = $content[0].Trim()
                if ($firstLine -match '^\d+\s+[\d.]+\s+[\d.]+\s+[\d.]+\s+[\d.]+$') {
                    Write-Host "     ✅ Looks like YOLO format: $firstLine" -ForegroundColor Green
                } else {
                    Write-Host "     ⚠️  Format: $firstLine" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "     (Could not read file)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "❌ No .txt files found matching 'Robotfloor'" -ForegroundColor Red
}
Write-Host ""

# Search for XML files (PascalVOC format)
Write-Host "=== Searching for .xml files (PascalVOC annotations) ===" -ForegroundColor Cyan
$xmlFiles = Get-ChildItem -Path $SearchRoot -Recurse -Filter "*.xml" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Robotfloor" }

if ($xmlFiles.Count -gt 0) {
    Write-Host "Found $($xmlFiles.Count) .xml files (might be PascalVOC format):" -ForegroundColor Yellow
    $xmlFiles | Select-Object -First 5 | ForEach-Object {
        Write-Host "  📄 $($_.FullName)" -ForegroundColor Yellow
    }
    if ($xmlFiles.Count -gt 5) {
        Write-Host "  ... and $($xmlFiles.Count - 5) more" -ForegroundColor Gray
    }
} else {
    Write-Host "No .xml files found" -ForegroundColor Gray
}
Write-Host ""

# Search for JSON files (COCO format)
Write-Host "=== Searching for .json files (COCO annotations) ===" -ForegroundColor Cyan
$jsonFiles = Get-ChildItem -Path $SearchRoot -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Robotfloor|annotation" }

if ($jsonFiles.Count -gt 0) {
    Write-Host "Found $($jsonFiles.Count) .json files (might be COCO format):" -ForegroundColor Yellow
    $jsonFiles | Select-Object -First 5 | ForEach-Object {
        Write-Host "  📄 $($_.FullName)" -ForegroundColor Yellow
    }
    if ($jsonFiles.Count -gt 5) {
        Write-Host "  ... and $($jsonFiles.Count - 5) more" -ForegroundColor Gray
    }
} else {
    Write-Host "No .json files found" -ForegroundColor Gray
}
Write-Host ""

# Check common annotation tool directories
Write-Host "=== Checking Common Annotation Tool Directories ===" -ForegroundColor Cyan
$commonDirs = @(
    "labels",
    "Labels",
    "LABELS",
    "annotations",
    "Annotations",
    "train\labels",
    "valid\labels",
    "test\labels"
)

$foundDirs = @()
foreach ($dirName in $commonDirs) {
    $dirs = Get-ChildItem -Path $SearchRoot -Recurse -Directory -Filter $dirName -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $files = Get-ChildItem -Path $dir.FullName -Filter "*.txt" -File -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            $foundDirs += $dir
            Write-Host "  ✅ Found: $($dir.FullName) ($($files.Count) .txt files)" -ForegroundColor Green
        }
    }
}

if ($foundDirs.Count -eq 0) {
    Write-Host "  ❌ No common annotation directories found" -ForegroundColor Red
}
Write-Host ""

# Summary and instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($txtFiles.Count -gt 0) {
    Write-Host "✅ Found $($txtFiles.Count) potential annotation files!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To copy them to the correct location, run:" -ForegroundColor Cyan
    Write-Host ""
    
    # Group by directory
    $byDir = $txtFiles | Group-Object DirectoryName
    foreach ($group in $byDir) {
        Write-Host "  Copy from: $($group.Name)" -ForegroundColor Yellow
        Write-Host "  Copy to: data/raw/RobotFloor/labels/" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Command:" -ForegroundColor Cyan
        Write-Host "    Copy-Item `"$($group.Name)\*.txt`" `"data/raw/RobotFloor/labels/`"" -ForegroundColor White
        Write-Host ""
    }
} elseif ($xmlFiles.Count -gt 0 -or $jsonFiles.Count -gt 0) {
    Write-Host "⚠️  Found annotation files but in different format (XML/JSON)" -ForegroundColor Yellow
    Write-Host "   These need to be converted to YOLO format (.txt)" -ForegroundColor Yellow
    Write-Host "   Let me know and I can help convert them!" -ForegroundColor Yellow
} else {
    Write-Host "❌ No annotation files found" -ForegroundColor Red
    Write-Host ""
    Write-Host "If you used an annotation tool, the files might be:" -ForegroundColor Yellow
    Write-Host "  - In the same folder as images (check the image folder)" -ForegroundColor Gray
    Write-Host "  - In a 'labels' subfolder" -ForegroundColor Gray
    Write-Host "  - In a downloaded zip file from Roboflow or similar" -ForegroundColor Gray
    Write-Host "  - In a different location on your computer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "What annotation tool did you use?" -ForegroundColor Cyan
    Write-Host "  - LabelImg" -ForegroundColor Gray
    Write-Host "  - Roboflow" -ForegroundColor Gray
    Write-Host "  - CVAT" -ForegroundColor Gray
    Write-Host "  - Other?" -ForegroundColor Gray
}
Write-Host ""

