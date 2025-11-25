# PowerShell Backup Script for Development Projects
# Author: Your Coding Genius Assistant 🚀
# Description: Incremental backup script with Flutter project cleanup

param(
    [string]$SourceRoot = "D:\DEV",
    [string]$BackupRoot = "G:\",
    [string[]]$FoldersToBackup = @("Projects", "WWW"),
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Configuration - Add more folders here as needed
$DefaultFolders = @("Projects", "WWW")
if ($FoldersToBackup.Count -eq 0) {
    $FoldersToBackup = $DefaultFolders
}

# Robocopy options for incremental backup
$RobocopyOptions = @(
    "/MIR",          # Mirror directory tree (copy new/changed files, remove deleted)
    "/FFT",          # Assume FAT file times (2-second granularity)
    "/Z",            # Copy files in restartable mode
    "/XA:H",         # Exclude hidden files
    "/W:5",          # Wait 5 seconds between retries
    "/R:3",          # Retry 3 times on failed copies
    "/MT:8",         # Multi-threaded copying (8 threads)
    "/LOG+:backup_log.txt"  # Append to log file
)

# Additional exclusions for development projects
$ExcludeDirectories = @(
    "node_modules",
    ".git",
    "build",
    ".dart_tool",
    ".pub-cache",
    "bin",
    "obj",
    ".vs",
    ".vscode",
    "target",
    "dist",
    "out"
)

# Add exclusions to robocopy options
foreach ($dir in $ExcludeDirectories) {
    $RobocopyOptions += "/XD"
    $RobocopyOptions += $dir
}

# Exclude common temporary and cache files
$ExcludeFiles = @(
    "*.tmp",
    "*.temp",
    "*.log",
    "*.cache",
    "*.lock",
    "Thumbs.db",
    ".DS_Store"
)

foreach ($file in $ExcludeFiles) {
    $RobocopyOptions += "/XF"
    $RobocopyOptions += $file
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-FlutterProject {
    param([string]$ProjectPath)
    
    $pubspecPath = Join-Path $ProjectPath "pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $content = Get-Content $pubspecPath -Raw
        return $content -match "flutter:"
    }
    return $false
}

function Invoke-FlutterClean {
    param([string]$ProjectPath)
    
    Write-ColorOutput "🧹 Cleaning Flutter project: $ProjectPath" "Yellow"
    
    Push-Location $ProjectPath
    try {
        if ($DryRun) {
            Write-ColorOutput "  [DRY RUN] Would run: flutter clean" "Cyan"
        } else {
            $result = & flutter clean 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "  ✅ Flutter clean completed successfully" "Green"
            } else {
                Write-ColorOutput "  ⚠️ Flutter clean failed: $result" "Red"
            }
        }
    }
    catch {
        Write-ColorOutput "  ❌ Error running flutter clean: $($_.Exception.Message)" "Red"
    }
    finally {
        Pop-Location
    }
}

function Find-FlutterProjects {
    param([string]$RootPath)
    
    $flutterProjects = @()
    
    if (Test-Path $RootPath) {
        Get-ChildItem -Path $RootPath -Recurse -Directory | ForEach-Object {
            if (Test-FlutterProject $_.FullName) {
                $flutterProjects += $_.FullName
            }
        }
    }
    
    return $flutterProjects
}

function Start-IncrementalBackup {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$FolderName
    )
    
    Write-ColorOutput "📁 Starting backup of folder: $FolderName" "Cyan"
    Write-ColorOutput "   Source: $SourcePath" "Gray"
    Write-ColorOutput "   Destination: $DestinationPath" "Gray"
    
    if (-not (Test-Path $SourcePath)) {
        Write-ColorOutput "   ⚠️ Source path does not exist, skipping..." "Yellow"
        return
    }
    
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $DestinationPath)) {
        if ($DryRun) {
            Write-ColorOutput "   [DRY RUN] Would create directory: $DestinationPath" "Cyan"
        } else {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
            Write-ColorOutput "   📂 Created destination directory" "Green"
        }
    }
    
    # Find and clean Flutter projects before backup
    $flutterProjects = Find-FlutterProjects $SourcePath
    if ($flutterProjects.Count -gt 0) {
        Write-ColorOutput "   🔍 Found $($flutterProjects.Count) Flutter project(s)" "Blue"
        foreach ($project in $flutterProjects) {
            Invoke-FlutterClean $project
        }
    }
    
    # Perform incremental backup using robocopy
    Write-ColorOutput "   🚀 Starting incremental copy..." "Blue"
    
    if ($DryRun) {
        Write-ColorOutput "   [DRY RUN] Would run robocopy with options: $($RobocopyOptions -join ' ')" "Cyan"
    } else {
        $robocopyArgs = @($SourcePath, $DestinationPath) + $RobocopyOptions
        
        if ($Verbose) {
            $robocopyArgs += "/V"  # Verbose output
        }
        
        $result = & robocopy @robocopyArgs
        $exitCode = $LASTEXITCODE
        
        # Robocopy exit codes: 0-7 are success, 8+ are errors
        if ($exitCode -le 7) {
            Write-ColorOutput "   ✅ Backup completed successfully (Exit code: $exitCode)" "Green"
        } else {
            Write-ColorOutput "   ❌ Backup failed with exit code: $exitCode" "Red"
        }
    }
}

# Main execution
Write-ColorOutput "🎯 Development Projects Backup Script" "Magenta"
Write-ColorOutput "=====================================`n" "Magenta"

if ($DryRun) {
    Write-ColorOutput "🔍 DRY RUN MODE - No actual changes will be made`n" "Yellow"
}

Write-ColorOutput "📋 Configuration:" "White"
Write-ColorOutput "   Source Root: $SourceRoot" "Gray"
Write-ColorOutput "   Backup Root: $BackupRoot" "Gray"
Write-ColorOutput "   Folders to backup: $($FoldersToBackup -join ', ')" "Gray"
Write-ColorOutput ""

# Check if source root exists
if (-not (Test-Path $SourceRoot)) {
    Write-ColorOutput "❌ Source root directory does not exist: $SourceRoot" "Red"
    exit 1
}

# Check if backup root is accessible
if (-not (Test-Path $BackupRoot)) {
    Write-ColorOutput "❌ Backup root directory is not accessible: $BackupRoot" "Red"
    exit 1
}

# Start backup process
$startTime = Get-Date
Write-ColorOutput "⏰ Backup started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Green"
Write-ColorOutput ""

foreach ($folder in $FoldersToBackup) {
    $sourcePath = Join-Path $SourceRoot $folder
    $destinationPath = Join-Path $BackupRoot $folder
    
    Start-IncrementalBackup -SourcePath $sourcePath -DestinationPath $destinationPath -FolderName $folder
    Write-ColorOutput ""
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "🎉 Backup process completed!" "Green"
Write-ColorOutput "⏱️ Total duration: $($duration.ToString('hh\:mm\:ss'))" "Green"
Write-ColorOutput "📝 Check backup_log.txt for detailed robocopy output" "Gray"

# Example usage information
Write-ColorOutput "`n💡 Usage Examples:" "Yellow"
Write-ColorOutput "   .\backup_dev.ps1                                    # Default backup" "Gray"
Write-ColorOutput "   .\backup_dev.ps1 -DryRun                           # Test run without changes" "Gray"
Write-ColorOutput "   .\backup_dev.ps1 -Verbose                          # Detailed output" "Gray"
Write-ColorOutput "   .\backup_dev.ps1 -FoldersToBackup @('Projects')    # Backup only Projects folder" "Gray"
Write-ColorOutput "   .\backup_dev.ps1 -BackupRoot 'E:\'                 # Use different backup drive" "Gray"
