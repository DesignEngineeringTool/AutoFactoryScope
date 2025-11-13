# Verify Annotations Script
# Checks that all images have corresponding annotation files
# Validates annotation format and values
# This helps catch errors before training

param(
    [string]$ImagesDir = "data/training/images",
    [string]$LabelsDir = "data/training/labels"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Verify Annotations ===" -ForegroundColor Cyan
Write-Host "Images: $ImagesDir" -ForegroundColor Yellow
Write-Host "Labels: $LabelsDir" -ForegroundColor Yellow
Write-Host ""

# Check directories exist
if (-not (Test-Path $ImagesDir)) {
    Write-Error "Images directory not found: $ImagesDir"
    exit 1
}

if (-not (Test-Path $LabelsDir)) {
    Write-Error "Labels directory not found: $LabelsDir"
    Write-Host "Create the labels directory and add annotation files." -ForegroundColor Red
    exit 1
}

# Get all images
$images = Get-ChildItem -Path $ImagesDir -Filter "*.png" -File | Sort-Object Name
$total = $images.Count

if ($total -eq 0) {
    Write-Error "No images found in $ImagesDir"
    exit 1
}

Write-Host "Found $total images" -ForegroundColor Green
Write-Host ""

# Check for missing labels
$missingLabels = @()
$hasLabels = 0
$emptyLabels = 0
$invalidLabels = 0
$validLabels = 0

foreach ($img in $images) {
    $labelName = $img.Name -replace '\.png$', '.txt'
    $labelPath = Join-Path $LabelsDir $labelName
    
    if (-not (Test-Path $labelPath)) {
        $missingLabels += $img.Name
    } else {
        $hasLabels++
        
        # Check if label file is empty
        $content = Get-Content $labelPath -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            $emptyLabels++
            Write-Warning "Empty label file: $labelName"
        } else {
            # Validate format
            $lines = Get-Content $labelPath
            $isValid = $true
            
            foreach ($line in $lines) {
                $line = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                
                $parts = $line -split '\s+'
                if ($parts.Count -ne 5) {
                    Write-Warning "Invalid format in $labelName : '$line' (expected 5 values)"
                    $isValid = $false
                    $invalidLabels++
                    break
                }
                
                # Check if values are numbers and in valid range (0-1)
                foreach ($part in $parts) {
                    $num = 0
                    if (-not [double]::TryParse($part, [ref]$num)) {
                        Write-Warning "Invalid number in $labelName : '$part'"
                        $isValid = $false
                        $invalidLabels++
                        break
                    }
                    
                    # First value is class_id (can be 0 or higher)
                    # Rest should be 0-1 for normalized coordinates
                    if ($parts.IndexOf($part) -gt 0) {
                        if ($num -lt 0 -or $num -gt 1) {
                            Write-Warning "Value out of range (0-1) in $labelName : '$part'"
                            $isValid = $false
                            $invalidLabels++
                            break
                        }
                    }
                }
            }
            
            if ($isValid) {
                $validLabels++
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total images: $total" -ForegroundColor Yellow
Write-Host "  Has labels: $hasLabels" -ForegroundColor $(if ($hasLabels -eq $total) { "Green" } else { "Yellow" })
Write-Host "  Missing labels: $($missingLabels.Count)" -ForegroundColor $(if ($missingLabels.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Empty labels: $emptyLabels" -ForegroundColor $(if ($emptyLabels -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Invalid labels: $invalidLabels" -ForegroundColor $(if ($invalidLabels -eq 0) { "Green" } else { "Red" })
Write-Host "  Valid labels: $validLabels" -ForegroundColor Green
Write-Host ""

if ($missingLabels.Count -gt 0) {
    Write-Host "Missing label files:" -ForegroundColor Red
    $missingLabels | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    Write-Host ""
}

if ($missingLabels.Count -eq 0 -and $invalidLabels -eq 0 -and $emptyLabels -eq 0) {
    Write-Host "✅ All annotations are valid!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Create dataset.yaml and start training" -ForegroundColor Cyan
    Write-Host "See docs/BEGINNER_GUIDE.md for training instructions" -ForegroundColor Yellow
    exit 0
} else {
    Write-Warning "Please fix the issues above before training."
    exit 1
}

