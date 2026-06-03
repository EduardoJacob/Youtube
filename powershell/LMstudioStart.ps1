
# Define the model name
$modelName = "qwen/qwen3.5-9b"

# Get the current status from lms
# We use -match to look for the model name in the output
$status = lms status

if ($status -match $modelName) {
    Write-Host "Model '$modelName' is already loaded. Skipping..." -ForegroundColor Cyan
} else {
    Write-Host "Model '$modelName' not found in memory. Loading..." -ForegroundColor Yellow
    lms load $modelName --gpu max --ttl 86400
    lms server start
}
 
