# Validate YOLO Annotation Format
# =================================
# Quick validation script to check YOLO annotation files
# Ensures format is correct before training
#
# Usage:
#   pwsh scripts/validate-yolo-annotations.ps1 [LabelsDir]

param(
    [string]$LabelsDir = "data/raw/RobotFloor/labels"
)

$ErrorActionPreference = "Stop"

Write-Host "=== YOLO Annotation Validator ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $LabelsDir)) {
    Write-Error "Labels directory not found: $LabelsDir"
    exit 1
}

$labelFiles = Get-ChildItem -Path $LabelsDir -Filter "*.txt" -File | Sort-Object Name
$total = $labelFiles.Count

if ($total -eq 0) {
    Write-Error "No annotation files found in $LabelsDir"
    exit 1
}

Write-Host "Found $total annotation files" -ForegroundColor Green
Write-Host ""

$validCount = 0
$invalidCount = 0
$emptyCount = 0
$errors = @()

foreach ($label in $labelFiles) {
    $content = Get-Content $label.FullName -Raw
    
    # Empty files are OK (images with no objects)
    if ([string]::IsNullOrWhiteSpace($content)) {
        $emptyCount++
        continue
    }
    
    $lines = Get-Content $label.FullName
    $lineNum = 0
    $isValid = $true
    
    foreach ($line in $lines) {
        $lineNum++
        $line = $line.Trim()
        
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        $parts = $line -split '\s+'
        
        # Check format: should have 5 values
        if ($parts.Count -ne 5) {
            $errors += "  $($label.Name): Line $lineNum - Expected 5 values, got $($parts.Count): '$line'"
            $isValid = $false
            continue
        }
        
        # Check class ID (first value)
        $classId = 0
        if (-not [int]::TryParse($parts[0], [ref]$classId)) {
            $errors += "  $($label.Name): Line $lineNum - Invalid class ID: '$($parts[0])'"
            $isValid = $false
            continue
        }
        
        if ($classId -lt 0) {
            $errors += "  $($label.Name): Line $lineNum - Class ID must be >= 0: '$classId'"
            $isValid = $false
            continue
        }
        
        # Check normalized coordinates (should be 0-1)
        for ($i = 1; $i -lt 5; $i++) {
            $value = 0.0
            if (-not [double]::TryParse($parts[$i], [ref]$value)) {
                $errors += "  $($label.Name): Line $lineNum - Invalid number: '$($parts[$i])'"
                $isValid = $false
                break
            }
            
            if ($value -lt 0 -or $value -gt 1) {
                $errors += "  $($label.Name): Line $lineNum - Value out of range (0-1): '$($parts[$i])'"
                $isValid = $false
                break
            }
        }
        
        # Check bounding box validity
        $centerX = [double]$parts[1]
        $centerY = [double]$parts[2]
        $width = [double]$parts[3]
        $height = [double]$parts[4]
        
        # Check if box extends outside image
        $halfW = $width / 2.0
        $halfH = $height / 2.0
        
        if ($centerX - $halfW -lt 0 -or $centerX + $halfW -gt 1) {
            $errors += "  $($label.Name): Line $lineNum - Box extends outside image (X): center=$centerX, width=$width"
            $isValid = $false
        }
        
        if ($centerY - $halfH -lt 0 -or $centerY + $halfH -gt 1) {
            $errors += "  $($label.Name): Line $lineNum - Box extends outside image (Y): center=$centerY, height=$height"
            $isValid = $false
        }
        
        # Check minimum size
        if ($width -lt 0.001 -or $height -lt 0.001) {
            $errors += "  $($label.Name): Line $lineNum - Box too small: width=$width, height=$height"
            $isValid = $false
        }
    }
    
    if ($isValid) {
        $validCount++
    } else {
        $invalidCount++
    }
}

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total files: $total" -ForegroundColor Yellow
Write-Host "  Valid files: $validCount" -ForegroundColor Green
Write-Host "  Invalid files: $invalidCount" -ForegroundColor $(if ($invalidCount -eq 0) { "Green" } else { "Red" })
Write-Host "  Empty files: $emptyCount" -ForegroundColor $(if ($emptyCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($errors.Count -gt 0) {
    Write-Host "=== Errors Found ===" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Write-Host ""
    exit 1
}

if ($invalidCount -eq 0) {
    Write-Host "✅ All annotations are valid!" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "⚠️  Some annotations have issues. Please review above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

