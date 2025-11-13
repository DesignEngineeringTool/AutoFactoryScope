# Ensure Black Background Script
# Processes images to replace white/near-white backgrounds with black

param(
    [string]$SourceDir = "data/raw",
    [string]$OutputDir = "data/processed/black_bg",
    [int]$WhiteThreshold = 240  # Pixels with RGB values above this are considered white
)

$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Drawing

function Process-ImageWithBlackBackground {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$Threshold = 240
    )
    
    try {
        # Load image
        $original = [System.Drawing.Bitmap]::FromFile($SourcePath)
        
        # Create new bitmap with same dimensions
        $result = New-Object System.Drawing.Bitmap($original.Width, $original.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        
        # Lock bits for fast pixel access
        $originalData = $original.LockBits(
            [System.Drawing.Rectangle]::new(0, 0, $original.Width, $original.Height),
            [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
            $original.PixelFormat
        )
        
        $resultData = $result.LockBits(
            [System.Drawing.Rectangle]::new(0, 0, $result.Width, $result.Height),
            [System.Drawing.Imaging.ImageLockMode]::WriteOnly,
            $result.PixelFormat
        )
        
        # Get stride (bytes per row)
        $originalStride = $originalData.Stride
        $resultStride = $resultData.Stride
        
        # Get pointer to pixel data
        $originalPtr = $originalData.Scan0
        $resultPtr = $resultData.Scan0
        
        # Copy pixel data
        $originalBytes = New-Object byte[] ($originalStride * $original.Height)
        $resultBytes = New-Object byte[] ($resultStride * $result.Height)
        
        [System.Runtime.InteropServices.Marshal]::Copy($originalPtr, $originalBytes, 0, $originalBytes.Length)
        
        # Process each pixel
        for ($y = 0; $y -lt $original.Height; $y++) {
            for ($x = 0; $x -lt $original.Width; $x++) {
                # Calculate byte positions
                $originalPos = ($y * $originalStride) + ($x * 4)  # ARGB = 4 bytes
                $resultPos = ($y * $resultStride) + ($x * 3)      # RGB = 3 bytes
                
                # Get ARGB values (original may have alpha)
                $b = $originalBytes[$originalPos]
                $g = $originalBytes[$originalPos + 1]
                $r = $originalBytes[$originalPos + 2]
                $a = if ($original.PixelFormat -eq [System.Drawing.Imaging.PixelFormat]::Format32bppArgb) { 
                    $originalBytes[$originalPos + 3] 
                } else { 
                    255 
                }
                
                # Check if pixel is white or near-white
                $isWhite = ($r -ge $Threshold -and $g -ge $Threshold -and $b -ge $Threshold)
                
                if ($isWhite) {
                    # Replace with black
                    $resultBytes[$resultPos] = 0      # B
                    $resultBytes[$resultPos + 1] = 0  # G
                    $resultBytes[$resultPos + 2] = 0  # R
                } else {
                    # Keep original color (convert to RGB, ignoring alpha)
                    $resultBytes[$resultPos] = $b     # B
                    $resultBytes[$resultPos + 1] = $g # G
                    $resultBytes[$resultPos + 2] = $r # R
                }
            }
        }
        
        # Copy processed data back
        [System.Runtime.InteropServices.Marshal]::Copy($resultBytes, 0, $resultPtr, $resultBytes.Length)
        
        # Unlock bits
        $original.UnlockBits($originalData)
        $result.UnlockBits($resultData)
        
        # Save
        $result.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $original.Dispose()
        $result.Dispose()
        
        return $true
    }
    catch {
        Write-Error "Failed to process $SourcePath : $_"
        return $false
    }
}

# Main script
Write-Host "=== Ensure Black Background (Replace White) ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Yellow
Write-Host "Output: $OutputDir" -ForegroundColor Yellow
Write-Host "White Threshold: $WhiteThreshold (RGB values >= this will become black)" -ForegroundColor Yellow
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

# Get all PNG images
$images = Get-ChildItem -Path $SourceDir -Filter "*.png" | Sort-Object Name

if ($images.Count -eq 0) {
    Write-Warning "No PNG images found in $SourceDir"
    exit 1
}

Write-Host "Found $($images.Count) images to process" -ForegroundColor Green
Write-Host ""

$processedCount = 0
$failedCount = 0

foreach ($img in $images) {
    $outputPath = Join-Path $OutputDir $img.Name
    
    Write-Host "Processing: $($img.Name)" -ForegroundColor Gray -NoNewline
    
    if (Process-ImageWithBlackBackground -SourcePath $img.FullName -OutputPath $outputPath -Threshold $WhiteThreshold) {
        $processedCount++
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        $failedCount++
        Write-Host " [FAILED]" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Processed: $processedCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "  Failed: $failedCount" -ForegroundColor Red
}
Write-Host "  Output directory: $OutputDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Done! White backgrounds have been replaced with black." -ForegroundColor Green
