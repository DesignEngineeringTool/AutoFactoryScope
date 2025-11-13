# Complete Image Processing Pipeline
# 1. Format and rotate images from raw
# 2. Apply black background
# 3. Compress images
# 4. Merge into final RobotFloor folder

param(
    [string]$RawDir = "data/raw",
    [string]$ProcessedDir = "data/processed",
    [string]$StartingDir = "data/starting",
    [string]$FinalDir = "data/processed/RobotFloor",
    [int]$WhiteThreshold = 240
)

$ErrorActionPreference = "Stop"

Write-Host "=== Complete Image Processing Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Format and rotate images
Write-Host "=== Step 1: Formatting and Rotating Images ===" -ForegroundColor Cyan
Write-Host "Source: $RawDir" -ForegroundColor Yellow
Write-Host "Output: $ProcessedDir" -ForegroundColor Yellow
Write-Host ""

& pwsh -File scripts\process-and-augment-images.ps1 -SourceDir $RawDir -OutputDir $ProcessedDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "Step 1 failed!"
    exit 1
}

Write-Host ""
Write-Host "=== Step 2: Applying Black Background ===" -ForegroundColor Cyan
Write-Host "Source: $ProcessedDir" -ForegroundColor Yellow
Write-Host ""

# Create black background versions
$blackBgDir = Join-Path $ProcessedDir "all_black_bg"
& pwsh -File scripts\process-all-with-black-bg.ps1 -SourceDir $ProcessedDir -OutputDir $blackBgDir -WhiteThreshold $WhiteThreshold

if ($LASTEXITCODE -ne 0) {
    Write-Error "Step 2 failed!"
    exit 1
}

Write-Host ""
Write-Host "=== Step 3: Compressing Images ===" -ForegroundColor Cyan
Write-Host ""

# Compress the black background images
$compressedDir = Join-Path $ProcessedDir "processed_compressed"
& pwsh -File scripts\compress-images.ps1 -SourceDir $blackBgDir -OutputDir $compressedDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "Step 3 failed!"
    exit 1
}

# Also check if starting directory exists and process it
if (Test-Path $StartingDir) {
    Write-Host ""
    Write-Host "=== Step 4: Processing Starting Directory ===" -ForegroundColor Cyan
    
    $startingBlackBgDir = Join-Path $StartingDir "all_black_bg"
    if (Test-Path $startingBlackBgDir) {
        $startingCompressedDir = Join-Path $StartingDir "all_black_bg_compressed"
        & pwsh -File scripts\compress-images.ps1 -SourceDir $startingBlackBgDir -OutputDir $startingCompressedDir
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Starting directory compression had issues, continuing..."
        }
    }
}

Write-Host ""
Write-Host "=== Step 5: Merging to Final Directory ===" -ForegroundColor Cyan
Write-Host ""

# Ensure final directory exists and is empty
if (Test-Path $FinalDir) {
    Write-Host "Clearing existing files in $FinalDir..." -ForegroundColor Yellow
    Get-ChildItem -Path $FinalDir -Filter "*.png" | Remove-Item -Force
}
New-Item -ItemType Directory -Force -Path $FinalDir | Out-Null

# Merge from both compressed directories
$source1 = Join-Path $StartingDir "all_black_bg_compressed"
$source2 = $compressedDir

# Check if starting directory compressed files exist
if (-not (Test-Path $source1)) {
    Write-Warning "Starting directory compressed files not found at $source1"
    Write-Warning "Will only copy from processed_compressed"
    $source1 = $null
}

if ($source1 -and (Test-Path $source1)) {
    # Merge from both sources
    & pwsh -File scripts\merge-compressed-images.ps1 -SourceDir1 $source1 -SourceDir2 $source2 -DestDir $FinalDir
} else {
    # Just copy from one source
    Write-Host "Copying files from $source2..." -ForegroundColor Cyan
    $files = Get-ChildItem -Path $source2 -Filter "*.png" -File
    $count = 0
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination (Join-Path $FinalDir $file.Name) -Force
        $count++
        if ($count % 100 -eq 0) {
            Write-Host "  Copied $count files..." -ForegroundColor Gray
        }
    }
    Write-Host "Copied $count files" -ForegroundColor Green
}

# Final verification
Write-Host ""
Write-Host "=== Final Verification ===" -ForegroundColor Cyan
$finalCount = (Get-ChildItem -Path $FinalDir -Filter "*.png" -File | Measure-Object).Count
$finalSize = (Get-ChildItem -Path $FinalDir -Filter "*.png" -File | Measure-Object -Property Length -Sum).Sum
$finalSizeMB = [math]::Round($finalSize / 1MB, 2)

Write-Host "  Total files: $finalCount" -ForegroundColor $(if ($finalCount -ge 1824) { "Green" } else { "Yellow" })
Write-Host "  Total size: $finalSizeMB MB" -ForegroundColor Yellow
Write-Host "  Average file size: $([math]::Round($finalSize / $finalCount / 1KB, 2)) KB" -ForegroundColor Yellow
Write-Host ""
Write-Host "ML.NET Requirements Check:" -ForegroundColor Cyan
Write-Host "  Minimum recommended: ~50-100 MB for training" -ForegroundColor Gray
Write-Host "  Current size: $finalSizeMB MB" -ForegroundColor $(if ($finalSizeMB -ge 50) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Final directory: $FinalDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Done! Pipeline completed successfully." -ForegroundColor Green

