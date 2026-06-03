# Define the model name
$modelName = "qwen/qwen3.5-9b"

# Get the current status from lms
$status = lms status

if ($status -match $modelName) {
    Write-Host "Model '$modelName' is currently loaded. Unloading..." -ForegroundColor Yellow
    lms unload $modelName
} else {
    Write-Host "Model '$modelName' is not in memory. Nothing to unload." -ForegroundColor Cyan
}
