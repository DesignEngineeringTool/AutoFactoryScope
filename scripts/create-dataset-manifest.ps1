# Create Dataset Manifest Script
# Generates a JSON manifest file for dataset version tracking

param(
    [string]$DatasetPath = "data/processed/RobotFloor",
    [string]$OutputPath = "data/dataset_manifest.json",
    [string]$Version = "1.0",
    [string]$Description = "Robot floor detection dataset"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Creating Dataset Manifest ===" -ForegroundColor Cyan
Write-Host "Dataset: $DatasetPath" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $DatasetPath)) {
    Write-Error "Dataset path not found: $DatasetPath"
    exit 1
}

# Get all PNG files
$images = Get-ChildItem -Path $DatasetPath -Filter "*.png" -File | Sort-Object Name

if ($images.Count -eq 0) {
    Write-Warning "No PNG images found in $DatasetPath"
    exit 1
}

# Calculate statistics
$totalSize = ($images | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
$avgSizeKB = [math]::Round($totalSize / $images.Count / 1KB, 2)

# Get file information
$fileList = @()
foreach ($img in $images) {
    $fileList += @{
        Name = $img.Name
        Size = $img.Length
        SizeKB = [math]::Round($img.Length / 1KB, 2)
        LastModified = $img.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Create manifest
$manifest = @{
    Version = $Version
    Description = $Description
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DatasetPath = $DatasetPath
    Statistics = @{
        TotalImages = $images.Count
        TotalSizeBytes = $totalSize
        TotalSizeMB = $totalSizeMB
        AverageSizeKB = $avgSizeKB
        MinSizeKB = [math]::Round(($images | Measure-Object -Property Length -Minimum).Minimum / 1KB, 2)
        MaxSizeKB = [math]::Round(($images | Measure-Object -Property Length -Maximum).Maximum / 1KB, 2)
    }
    Files = $fileList
}

# Save manifest
$manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Manifest created successfully!" -ForegroundColor Green
Write-Host "  Output: $OutputPath" -ForegroundColor Yellow
Write-Host "  Version: $Version" -ForegroundColor Yellow
Write-Host "  Total images: $($images.Count)" -ForegroundColor Yellow
Write-Host "  Total size: $totalSizeMB MB" -ForegroundColor Yellow
Write-Host "  Average size: $avgSizeKB KB" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now commit this manifest file to Git:" -ForegroundColor Cyan
Write-Host "  git add $OutputPath" -ForegroundColor Gray
Write-Host "  git commit -m 'Add dataset manifest v$Version'" -ForegroundColor Gray

