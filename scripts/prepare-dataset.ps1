param([string]$Src="data/raw",[string]$Out="data/training/images")
if (-not (Test-Path $Out)) { New-Item -ItemType Directory -Force -Path $Out | Out-Null }
Write-Host "Place raw PDFs/JPG/PNG under $Src."
Write-Host "Add your PDF->image conversion here if needed."


