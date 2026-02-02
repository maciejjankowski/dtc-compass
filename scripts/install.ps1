<#
.SYNOPSIS
    DTC Compass Installation Helper for Windows

.DESCRIPTION
    Sets up DTC Compass for Windows:
    - Verifies Codex CLI is installed
    - Adds dtc-compass/scripts to PATH (optional)
    - Creates scheduled tasks for morning brief and end-of-day reminder (optional)
    - Initializes the _state directory

.PARAMETER AddToPath
    If specified, adds the scripts directory to user PATH

.PARAMETER SetupScheduledTasks
    If specified, creates scheduled tasks for morning/evening reminders

.PARAMETER MorningTime
    Time for morning brief task (default: 07:00)

.PARAMETER EveningTime
    Time for end-of-day reminder task (default: 17:00)

.EXAMPLE
    .\install.ps1
    # Basic installation - just verifies prerequisites

.EXAMPLE
    .\install.ps1 -AddToPath
    # Adds scripts to PATH

.EXAMPLE
    .\install.ps1 -AddToPath -SetupScheduledTasks
    # Full installation with scheduled tasks

.EXAMPLE
    .\install.ps1 -SetupScheduledTasks -MorningTime "08:00" -EveningTime "18:00"
    # Custom times for scheduled tasks

.NOTES
    Author: MJ @ Future Processing
    Part of DTC Compass framework
    Requires: Administrator privileges for scheduled tasks
#>

[CmdletBinding()]
param(
    [switch]$AddToPath,
    [switch]$SetupScheduledTasks,
    [string]$MorningTime = "07:00",
    [string]$EveningTime = "17:00"
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = 'Stop'

# Get paths
$ScriptDir = $PSScriptRoot
$DtcRoot = Split-Path -Parent $ScriptDir
$StateDir = Join-Path $DtcRoot "_state"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DTC Compass - Windows Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: Verify Prerequisites
# ============================================================================

Write-Host "Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "  PowerShell version: $psVersion" -ForegroundColor Gray
if ($psVersion.Major -lt 5) {
    Write-Warning "PowerShell 5.0 or later is recommended. You have $psVersion"
}
else {
    Write-Host "  [OK] PowerShell version" -ForegroundColor Green
}

# Check for Codex CLI
$codexPath = Get-Command codex -ErrorAction SilentlyContinue
if ($codexPath) {
    Write-Host "  [OK] Codex CLI found at: $($codexPath.Source)" -ForegroundColor Green
}
else {
    Write-Host "  [!!] Codex CLI not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "  To install Codex CLI:" -ForegroundColor Yellow
    Write-Host "    npm install -g @openai/codex" -ForegroundColor White
    Write-Host ""
    Write-Host "  Or if you don't have npm:" -ForegroundColor Yellow
    Write-Host "    1. Install Node.js from https://nodejs.org/" -ForegroundColor White
    Write-Host "    2. Run: npm install -g @openai/codex" -ForegroundColor White
    Write-Host ""

    $continue = Read-Host "Continue installation anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 1
    }
}

# Check for Node.js (needed for codex)
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if ($nodePath) {
    $nodeVersion = & node --version
    Write-Host "  [OK] Node.js found: $nodeVersion" -ForegroundColor Green
}
else {
    Write-Host "  [!!] Node.js not found (required for Codex)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# Step 2: Initialize State Directory
# ============================================================================

Write-Host "Initializing state directory..." -ForegroundColor Yellow

if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    Write-Host "  Created: $StateDir" -ForegroundColor Green
}
else {
    Write-Host "  Exists: $StateDir" -ForegroundColor Gray
}

# Add to .gitignore if not already there
$gitignorePath = Join-Path $DtcRoot ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -notmatch '_state/') {
        Add-Content $gitignorePath "`n# DTC Compass state (local)`n_state/" -Encoding UTF8
        Write-Host "  Added _state/ to .gitignore" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================================================
# Step 3: Add to PATH (optional)
# ============================================================================

if ($AddToPath) {
    Write-Host "Adding to PATH..." -ForegroundColor Yellow

    # Get current user PATH
    $currentPath = [Environment]::GetEnvironmentVariable('PATH', 'User')

    if ($currentPath -notlike "*$ScriptDir*") {
        # Add scripts directory to PATH
        $newPath = "$currentPath;$ScriptDir"
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')

        Write-Host "  Added to user PATH: $ScriptDir" -ForegroundColor Green
        Write-Host "  NOTE: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Already in PATH: $ScriptDir" -ForegroundColor Gray
    }

    Write-Host ""
}

# ============================================================================
# Step 4: Create Scheduled Tasks (optional)
# ============================================================================

if ($SetupScheduledTasks) {
    Write-Host "Setting up scheduled tasks..." -ForegroundColor Yellow
    Write-Host ""

    # Check for admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Scheduled tasks require administrator privileges."
        Write-Host "  Please run this script as Administrator, or create tasks manually." -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        # Morning Brief Task (weekdays at configured time)
        $morningTaskName = "DTC Compass - Morning Brief"
        $morningAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptDir\dtc.ps1`" brief"
        $morningTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday -At $MorningTime
        $morningSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        try {
            # Remove existing task if present
            Unregister-ScheduledTask -TaskName $morningTaskName -Confirm:$false -ErrorAction SilentlyContinue

            Register-ScheduledTask -TaskName $morningTaskName -Action $morningAction -Trigger $morningTrigger -Settings $morningSettings -Description "DTC Compass morning brief - shows current state" | Out-Null
            Write-Host "  [OK] Created task: $morningTaskName (weekdays at $MorningTime)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not create morning task: $_"
        }

        # End of Day Reminder Task (weekdays at configured time)
        $eveningTaskName = "DTC Compass - End of Day"
        $eveningAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptDir\notify.ps1`" -Title 'DTC Compass' -Message 'Time to wrap up! Run: dtc wrap' -Type Info"
        $eveningTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday -At $EveningTime
        $eveningSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        try {
            # Remove existing task if present
            Unregister-ScheduledTask -TaskName $eveningTaskName -Confirm:$false -ErrorAction SilentlyContinue

            Register-ScheduledTask -TaskName $eveningTaskName -Action $eveningAction -Trigger $eveningTrigger -Settings $eveningSettings -Description "DTC Compass end-of-day reminder" | Out-Null
            Write-Host "  [OK] Created task: $eveningTaskName (weekdays at $EveningTime)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not create evening task: $_"
        }

        Write-Host ""
        Write-Host "  To view/modify tasks: Open Task Scheduler and look for 'DTC Compass'" -ForegroundColor Gray
        Write-Host "  To remove tasks: Unregister-ScheduledTask -TaskName 'DTC Compass*'" -ForegroundColor Gray
    }

    Write-Host ""
}

# ============================================================================
# Step 5: Create PowerShell Profile Alias (alternative to PATH)
# ============================================================================

Write-Host "Creating PowerShell alias (optional)..." -ForegroundColor Yellow

# Check if profile exists
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$aliasLine = "Set-Alias -Name dtc -Value '$ScriptDir\dtc.ps1'"

if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -and $profileContent -match 'Set-Alias.*dtc') {
        Write-Host "  Alias already exists in profile" -ForegroundColor Gray
    }
    else {
        $addAlias = Read-Host "  Add 'dtc' alias to PowerShell profile? (y/n)"
        if ($addAlias -eq 'y') {
            Add-Content $profilePath "`n# DTC Compass alias`n$aliasLine" -Encoding UTF8
            Write-Host "  Added alias to: $profilePath" -ForegroundColor Green
        }
    }
}
else {
    $createProfile = Read-Host "  Create PowerShell profile with 'dtc' alias? (y/n)"
    if ($createProfile -eq 'y') {
        "# PowerShell Profile`n`n# DTC Compass alias`n$aliasLine" | Set-Content $profilePath -Encoding UTF8
        Write-Host "  Created profile: $profilePath" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal (for PATH/alias changes)" -ForegroundColor White
Write-Host "  2. Run 'dtc start' to begin your first session" -ForegroundColor White
Write-Host "  3. Use 'dtc help' to see available commands" -ForegroundColor White
Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Yellow
Write-Host "  dtc start     - Morning startup" -ForegroundColor Gray
Write-Host "  dtc focus X   - Set focus" -ForegroundColor Gray
Write-Host "  dtc stuck     - Get help when stuck" -ForegroundColor Gray
Write-Host "  dtc brief     - Show current state" -ForegroundColor Gray
Write-Host "  dtc wrap      - End of day wrap-up" -ForegroundColor Gray
Write-Host ""
Write-Host "Files location:" -ForegroundColor Yellow
Write-Host "  Scripts: $ScriptDir" -ForegroundColor Gray
Write-Host "  State:   $StateDir" -ForegroundColor Gray
Write-Host ""

# Test if installation works
Write-Host "Testing installation..." -ForegroundColor Yellow
try {
    & "$ScriptDir\dtc.ps1" help 2>&1 | Out-Null
    Write-Host "  [OK] dtc.ps1 runs successfully" -ForegroundColor Green
}
catch {
    Write-Warning "dtc.ps1 failed to run: $_"
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
