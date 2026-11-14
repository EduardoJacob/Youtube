
param (
    [string]$ModelName = "qwen/qwen3.5-9b"
)

# Get the current status from lms
$status = lms status

if ($status -match [regex]::Escape($ModelName)) {
    Write-Host "Model '$ModelName' is already loaded. Skipping..." -ForegroundColor Cyan
} else {
    Write-Host "Model '$ModelName' not found in memory. Loading..." -ForegroundColor Yellow
    # Load model with ttl (time to live) ~ 24H
    lms load $ModelName --gpu max --ttl 86400
    lms server start
}

