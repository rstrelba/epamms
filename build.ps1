# PowerShell script for automatic Flutter app build
# Author: Genius programmer! 

Write-Host "Starting automatic Flutter app build!" -ForegroundColor Green

# Path to pubspec.yaml
$pubspecPath = "pubspec.yaml"

try {
    # Read pubspec.yaml content
    Write-Host "Reading pubspec.yaml..." -ForegroundColor Yellow
    $content = Get-Content $pubspecPath -Raw
    
    # Find version line (format: version: x.y.z+buildNumber)
    $versionPattern = 'version:\s*(\d+\.\d+\.\d+)\+(\d+)'
    $match = [regex]::Match($content, $versionPattern)
    
    if ($match.Success) {
        $versionNumber = $match.Groups[1].Value
        $currentBuildNumber = [int]$match.Groups[2].Value
        $newBuildNumber = $currentBuildNumber + 1
        
        Write-Host "Current version: $versionNumber+$currentBuildNumber" -ForegroundColor Cyan
        Write-Host "New version: $versionNumber+$newBuildNumber" -ForegroundColor Green
        
        # Replace build number
        $newVersionLine = "version: $versionNumber+$newBuildNumber"
        $newContent = $content -replace $versionPattern, $newVersionLine
        
        # Save changes
        Write-Host "Saving changes to pubspec.yaml..." -ForegroundColor Yellow
        Set-Content -Path $pubspecPath -Value $newContent -NoNewline
        
        Write-Host "Build number successfully incremented!" -ForegroundColor Green
        
        # Execute flutter pub get
        Write-Host "Running flutter pub get..." -ForegroundColor Yellow
        $pubGetResult = flutter pub get
        if ($LASTEXITCODE -eq 0) {
            Write-Host "flutter pub get completed successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "Error running flutter pub get!" -ForegroundColor Red
            exit 1
        }
        
        # Execute flutter build aab
        Write-Host "Starting AAB build..." -ForegroundColor Yellow
        Write-Host "This may take some time..." -ForegroundColor Cyan
        
        $buildResult = flutter build aab
        if ($LASTEXITCODE -eq 0) {
            Write-Host "AAB build completed successfully!" -ForegroundColor Green
            Write-Host "AAB file ready for Google Play Store upload!" -ForegroundColor Magenta
        }
        else {
            Write-Host "Error building AAB file!" -ForegroundColor Red
            exit 1
        }
        
    }
    else {
        Write-Host "Could not find version line in pubspec.yaml!" -ForegroundColor Red
        Write-Host "Expected format: version: x.y.z+buildNumber" -ForegroundColor Yellow
        exit 1
    }
    
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All operations completed successfully!" -ForegroundColor Green
Write-Host "App ready for deployment!" -ForegroundColor Magenta
# Открыть папку с билдом в Проводнике Windows:

# Предположим, что билд находится по стандартному пути Flutter build:
# build\app\outputs\bundle\release

$buildFolder = "build\app\outputs\bundle\release"

if (Test-Path $buildFolder) {
    Write-Host "Opening build folder: $buildFolder" -ForegroundColor Cyan
    Start-Process explorer.exe $buildFolder
}
else {
    Write-Host "Build folder ($buildFolder) not found." -ForegroundColor Yellow
}
