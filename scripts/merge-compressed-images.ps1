# Merge Compressed Images Script
# Copies all PNG files from two source directories to a single destination,
# renaming files to avoid conflicts

param(
    [string]$SourceDir1 = "data/starting/all_black_bg_compressed",
    [string]$SourceDir2 = "data/processed_compressed",
    [string]$DestDir = "data/processed/RobotFloor",
    [string]$Prefix1 = "starting_",
    [string]$Prefix2 = "processed_"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Merge Compressed Images ===" -ForegroundColor Cyan
Write-Host "Source 1: $SourceDir1" -ForegroundColor Yellow
Write-Host "Source 2: $SourceDir2" -ForegroundColor Yellow
Write-Host "Destination: $DestDir" -ForegroundColor Yellow
Write-Host ""

# Check source directories
if (-not (Test-Path $SourceDir1)) {
    Write-Error "Source directory 1 not found: $SourceDir1"
    exit 1
}

if (-not (Test-Path $SourceDir2)) {
    Write-Error "Source directory 2 not found: $SourceDir2"
    exit 1
}

# Ensure destination directory exists
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    Write-Host "Created destination directory: $DestDir" -ForegroundColor Green
}

# Get all PNG images from both sources
$images1 = Get-ChildItem -Path $SourceDir1 -Filter "*.png" -File | Sort-Object Name
$images2 = Get-ChildItem -Path $SourceDir2 -Filter "*.png" -File | Sort-Object Name

Write-Host "Found $($images1.Count) images in source 1" -ForegroundColor Green
Write-Host "Found $($images2.Count) images in source 2" -ForegroundColor Green
Write-Host "Total: $($images1.Count + $images2.Count) images to copy" -ForegroundColor Green
Write-Host ""

$copied1 = 0
$copied2 = 0
$failed1 = 0
$failed2 = 0

# Copy files from source 1 with prefix
Write-Host "Copying files from source 1..." -ForegroundColor Cyan
foreach ($img in $images1) {
    $destPath = Join-Path $DestDir "$Prefix1$($img.Name)"
    try {
        Copy-Item -Path $img.FullName -Destination $destPath -Force
        $copied1++
        if ($copied1 % 100 -eq 0) {
            Write-Host "  Copied $copied1 files..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Error "Failed to copy $($img.Name): $_"
        $failed1++
    }
}

Write-Host "Copied $copied1 files from source 1" -ForegroundColor Green
if ($failed1 -gt 0) {
    Write-Host "Failed: $failed1 files" -ForegroundColor Red
}
Write-Host ""

# Copy files from source 2 with prefix
Write-Host "Copying files from source 2..." -ForegroundColor Cyan
foreach ($img in $images2) {
    $destPath = Join-Path $DestDir "$Prefix2$($img.Name)"
    try {
        Copy-Item -Path $img.FullName -Destination $destPath -Force
        $copied2++
        if ($copied2 % 100 -eq 0) {
            Write-Host "  Copied $copied2 files..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Error "Failed to copy $($img.Name): $_"
        $failed2++
    }
}

Write-Host "Copied $copied2 files from source 2" -ForegroundColor Green
if ($failed2 -gt 0) {
    Write-Host "Failed: $failed2 files" -ForegroundColor Red
}
Write-Host ""

# Verify final count
$finalCount = (Get-ChildItem -Path $DestDir -Filter "*.png" -File | Measure-Object).Count
$expectedCount = $images1.Count + $images2.Count

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Expected files: $expectedCount" -ForegroundColor Yellow
Write-Host "  Actual files: $finalCount" -ForegroundColor $(if ($finalCount -eq $expectedCount) { "Green" } else { "Red" })
Write-Host "  Source 1 copied: $copied1" -ForegroundColor Green
Write-Host "  Source 2 copied: $copied2" -ForegroundColor Green
if ($failed1 -gt 0 -or $failed2 -gt 0) {
    Write-Host "  Failed: $($failed1 + $failed2)" -ForegroundColor Red
}
Write-Host "  Destination: $DestDir" -ForegroundColor Yellow
Write-Host ""

if ($finalCount -eq $expectedCount) {
    Write-Host "Done! All images merged successfully." -ForegroundColor Green
} else {
    Write-Warning "File count mismatch! Expected $expectedCount but found $finalCount"
    exit 1
}

