# Get the clean process list from lms ps
$status = lms ps

Write-Host "Checking for all loaded models..." -ForegroundColor Cyan

# Find lines containing a model path (e.g., vendor/name) and extract just that identifier.
# It matches patterns like 'qwen/qwen3.5-9b' even if preceded by bullets or symbols.
$loadedModels = $status | ForEach-Object {
    if ($_ -match '([a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+)') {
        $Matches[1]
    }
} | Select-Object -Unique

if ($loadedModels) {
    Write-Host "Found $($loadedModels.Count) loaded model(s). Unloading all..." -ForegroundColor Yellow
    
    foreach ($model in $loadedModels) {
        Write-Host "Unloading: $model" -ForegroundColor DarkYellow
        lms unload $model
    }
    
    Write-Host "All loaded models have been processed." -ForegroundColor Green
} else {
    Write-Host "No active models found running in memory." -ForegroundColor Green
}
