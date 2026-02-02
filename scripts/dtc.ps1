<#
.SYNOPSIS
    DTC Compass - Main PowerShell wrapper for Codex CLI integration

.DESCRIPTION
    Provides quick access to dtc-compass functionality via command-line shortcuts.
    Designed to support ADHD executive function with minimal friction.

.PARAMETER Command
    The command to execute: start, focus, stuck, tangent, break, review, brief, wrap

.PARAMETER Args
    Additional arguments to pass to the command (e.g., focus topic)

.EXAMPLE
    dtc start     # Morning startup: show brief, launch codex
    dtc focus X   # Quick focus set with topic X
    dtc stuck     # Get help when stuck
    dtc tangent   # Capture a tangent thought
    dtc break     # Take a break
    dtc review    # Daily review
    dtc brief     # Show current state (no codex)
    dtc wrap      # End of day wrap-up

.NOTES
    Author: MJ @ Future Processing
    Part of DTC Compass framework
    Requires: Codex CLI installed and configured
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('start', 'focus', 'stuck', 'tangent', 'break', 'review', 'brief', 'wrap', 'help')]
    [string]$Command = 'help',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# ============================================================================
# Configuration
# ============================================================================

# Get the root directory of dtc-compass (parent of scripts folder)
$script:DTC_ROOT = Split-Path -Parent $PSScriptRoot

# State file locations
$script:STATE_DIR = Join-Path $DTC_ROOT "_state"
$script:FOCUS_FILE = Join-Path $STATE_DIR "current_focus.json"
$script:SESSION_FILE = Join-Path $STATE_DIR "session.json"

# Ensure state directory exists
if (-not (Test-Path $STATE_DIR)) {
    New-Item -ItemType Directory -Path $STATE_DIR -Force | Out-Null
}

# ============================================================================
# Helper Functions
# ============================================================================

function Get-CurrentFocus {
    <#
    .SYNOPSIS
        Read and return current focus from state file
    #>
    if (Test-Path $script:FOCUS_FILE) {
        try {
            $focus = Get-Content $script:FOCUS_FILE -Raw | ConvertFrom-Json
            return $focus
        }
        catch {
            Write-Warning "Could not parse focus file: $_"
            return $null
        }
    }
    return $null
}

function Get-SessionState {
    <#
    .SYNOPSIS
        Read current session state
    #>
    if (Test-Path $script:SESSION_FILE) {
        try {
            return Get-Content $script:SESSION_FILE -Raw | ConvertFrom-Json
        }
        catch {
            return $null
        }
    }
    return $null
}

function Save-SessionState {
    <#
    .SYNOPSIS
        Save session state to file
    #>
    param(
        [hashtable]$State
    )

    $State | ConvertTo-Json -Depth 5 | Set-Content $script:SESSION_FILE -Encoding UTF8
}

function Show-Brief {
    <#
    .SYNOPSIS
        Display current state summary without launching codex
    #>

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  DTC COMPASS - Current State" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Show time and energy window
    $hour = (Get-Date).Hour
    $energyWindow = switch ($hour) {
        { $_ -ge 7 -and $_ -lt 14 }  { "PEAK FOCUS (07:00-14:00) - Deep work time" }
        { $_ -ge 14 -and $_ -lt 19 } { "LOW ENERGY (14:00-19:00) - Admin & light tasks" }
        { $_ -ge 19 -and $_ -lt 20 } { "SECOND WIND (19:00-20:00) - Quick wins" }
        { $_ -ge 23 -or $_ -lt 1 }   { "CREATIVE BURST (23:00-01:00) - Strategy if not tired" }
        default { "OFF HOURS - Rest if possible" }
    }

    Write-Host "TIME: $(Get-Date -Format 'HH:mm dddd, MMMM dd')" -ForegroundColor White
    Write-Host "WINDOW: $energyWindow" -ForegroundColor Yellow
    Write-Host ""

    # Show current focus
    $focus = Get-CurrentFocus
    if ($focus) {
        Write-Host "CURRENT FOCUS:" -ForegroundColor Green
        Write-Host "  Task: $($focus.task)" -ForegroundColor White
        if ($focus.started) {
            $started = [DateTime]::Parse($focus.started)
            $elapsed = (Get-Date) - $started
            Write-Host "  Started: $($started.ToString('HH:mm')) ($([math]::Round($elapsed.TotalMinutes)) min ago)" -ForegroundColor Gray
        }
        if ($focus.notes) {
            Write-Host "  Notes: $($focus.notes)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "NO FOCUS SET" -ForegroundColor Yellow
        Write-Host "  Use 'dtc focus <task>' to set your focus" -ForegroundColor Gray
    }
    Write-Host ""

    # Show session info if exists
    $session = Get-SessionState
    if ($session -and $session.tasks_completed) {
        Write-Host "TODAY'S PROGRESS:" -ForegroundColor Green
        foreach ($task in $session.tasks_completed) {
            Write-Host "  [x] $task" -ForegroundColor Gray
        }
        Write-Host ""
    }

    # Check for calendar (if available)
    # Note: Windows calendar integration would require additional setup

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Toast {
    <#
    .SYNOPSIS
        Show Windows toast notification
    #>
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    # Use BurntToast module if available, otherwise fall back to basic notification
    if (Get-Module -ListAvailable -Name BurntToast) {
        Import-Module BurntToast -ErrorAction SilentlyContinue
        New-BurntToastNotification -Text $Title, $Message -ErrorAction SilentlyContinue
    }
    else {
        # Fallback: Use Windows.UI.Notifications (Windows 10+)
        try {
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

            $template = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$Title</text>
            <text id="2">$Message</text>
        </binding>
    </visual>
</toast>
"@
            $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xml.LoadXml($template)
            $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DTC Compass").Show($toast)
        }
        catch {
            # Final fallback: Console message
            Write-Host ""
            Write-Host "[$Type] $Title" -ForegroundColor $(switch ($Type) { 'Error' { 'Red' } 'Warning' { 'Yellow' } default { 'Cyan' } })
            Write-Host "  $Message" -ForegroundColor White
            Write-Host ""
        }
    }
}

function Invoke-Codex {
    <#
    .SYNOPSIS
        Launch codex with the specified prompt/skill
    #>
    param(
        [string]$Prompt,
        [string]$Skill
    )

    # Check if codex is installed
    $codexPath = Get-Command codex -ErrorAction SilentlyContinue
    if (-not $codexPath) {
        Write-Error "Codex CLI not found. Please install it first: npm install -g @openai/codex"
        return
    }

    # Build the command
    Push-Location $script:DTC_ROOT
    try {
        if ($Skill) {
            # Invoke with skill (slash command)
            codex "/$Skill $Prompt"
        }
        elseif ($Prompt) {
            codex $Prompt
        }
        else {
            codex
        }
    }
    finally {
        Pop-Location
    }
}

function Save-Focus {
    <#
    .SYNOPSIS
        Save current focus to state file
    #>
    param(
        [string]$Task,
        [string]$Notes
    )

    $focus = @{
        task = $Task
        started = (Get-Date).ToString('o')
        notes = $Notes
    }

    $focus | ConvertTo-Json | Set-Content $script:FOCUS_FILE -Encoding UTF8

    Show-Toast -Title "Focus Set" -Message $Task
    Write-Host "Focus set: $Task" -ForegroundColor Green
}

# ============================================================================
# Command Handlers
# ============================================================================

function Invoke-Start {
    <#
    .SYNOPSIS
        Morning startup routine: show brief, launch codex
    #>
    Write-Host ""
    Write-Host "Good morning! Starting DTC Compass..." -ForegroundColor Cyan
    Write-Host ""

    # Show the brief
    Show-Brief

    # Initialize or reset session state
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $session = Get-SessionState
    if (-not $session -or $session.date -ne $today) {
        Save-SessionState @{
            date = $today
            started = (Get-Date).ToString('o')
            tasks_completed = @()
        }
    }

    # Show toast notification
    Show-Toast -Title "DTC Compass" -Message "Morning startup. Time for deep work!"

    # Launch codex with morning routine prompt
    Write-Host "Launching Codex..." -ForegroundColor Yellow
    Write-Host ""

    Invoke-Codex -Prompt "Starting work. What's the priority for today?"
}

function Invoke-Focus {
    <#
    .SYNOPSIS
        Quick focus set
    #>
    param([string[]]$FocusArgs)

    if (-not $FocusArgs -or $FocusArgs.Count -eq 0) {
        # No args - show current focus or prompt
        $focus = Get-CurrentFocus
        if ($focus) {
            Write-Host "Current focus: $($focus.task)" -ForegroundColor Green
            Write-Host "Started: $($focus.started)" -ForegroundColor Gray
        }
        else {
            Write-Host "No focus set. Use: dtc focus <task description>" -ForegroundColor Yellow
        }
        return
    }

    # Join args into focus task
    $task = $FocusArgs -join ' '
    Save-Focus -Task $task

    # Launch codex with focus skill
    Invoke-Codex -Skill "focus" -Prompt $task
}

function Invoke-Stuck {
    <#
    .SYNOPSIS
        Get help when stuck - launches stuck skill
    #>
    Write-Host "Getting unstuck..." -ForegroundColor Yellow

    # Show current context
    $focus = Get-CurrentFocus
    if ($focus) {
        Write-Host "Current focus: $($focus.task)" -ForegroundColor Gray
    }

    Invoke-Codex -Skill "stuck"
}

function Invoke-Tangent {
    <#
    .SYNOPSIS
        Capture a tangent thought without losing focus
    #>
    param([string[]]$TangentArgs)

    $tangent = if ($TangentArgs) { $TangentArgs -join ' ' } else { $null }

    if ($tangent) {
        # Quick capture - append to tangents file
        $tangentsFile = Join-Path $script:STATE_DIR "tangents.md"
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        $entry = "- [$timestamp] $tangent"
        Add-Content $tangentsFile $entry -Encoding UTF8

        Write-Host "Tangent captured: $tangent" -ForegroundColor Cyan
        Show-Toast -Title "Tangent Captured" -Message $tangent
    }
    else {
        # Launch codex with tangent skill for interactive capture
        Invoke-Codex -Skill "tangent"
    }
}

function Invoke-Break {
    <#
    .SYNOPSIS
        Take a break - reminds about break activities
    #>
    Write-Host ""
    Write-Host "Break time! Suggested activities:" -ForegroundColor Cyan
    Write-Host "  - Walk (5-10 min)" -ForegroundColor White
    Write-Host "  - Stretch" -ForegroundColor White
    Write-Host "  - Water/snack" -ForegroundColor White
    Write-Host "  - NOT: Phone scrolling" -ForegroundColor Yellow
    Write-Host ""

    # Record break start
    $session = Get-SessionState
    if ($session) {
        $session.last_break = (Get-Date).ToString('o')
        Save-SessionState $session
    }

    Show-Toast -Title "Break Time" -Message "5-10 min. Walk or stretch. No phone!"

    # Optionally launch codex with break skill
    Invoke-Codex -Skill "break"
}

function Invoke-Review {
    <#
    .SYNOPSIS
        Daily review - summarize what got done
    #>
    Write-Host ""
    Write-Host "Starting daily review..." -ForegroundColor Cyan
    Write-Host ""

    # Show session summary
    $session = Get-SessionState
    if ($session -and $session.tasks_completed) {
        Write-Host "Today's completed tasks:" -ForegroundColor Green
        foreach ($task in $session.tasks_completed) {
            Write-Host "  [x] $task" -ForegroundColor White
        }
    }

    # Launch codex with review skill
    Invoke-Codex -Skill "review"
}

function Invoke-Wrap {
    <#
    .SYNOPSIS
        End of day wrap-up
    #>
    Write-Host ""
    Write-Host "Wrapping up for the day..." -ForegroundColor Cyan
    Write-Host ""

    # Show brief one more time
    Show-Brief

    # Clear focus for tomorrow
    if (Test-Path $script:FOCUS_FILE) {
        $focus = Get-CurrentFocus
        if ($focus) {
            Write-Host "Clearing focus: $($focus.task)" -ForegroundColor Gray
        }
        Remove-Item $script:FOCUS_FILE -Force
    }

    Show-Toast -Title "Day Complete" -Message "Great work! Rest up for tomorrow."

    # Launch codex with wrap-up prompt
    Invoke-Codex -Prompt "Wrapping up for the day. Please summarize what we accomplished and suggest tomorrow's first task."
}

function Show-Help {
    <#
    .SYNOPSIS
        Show available commands
    #>
    Write-Host ""
    Write-Host "DTC Compass - Commands" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  dtc start      - Morning startup, show brief, launch codex" -ForegroundColor White
    Write-Host "  dtc focus X    - Set focus to task X (calls `$focus skill)" -ForegroundColor White
    Write-Host "  dtc stuck      - Get help when stuck (calls `$stuck skill)" -ForegroundColor White
    Write-Host "  dtc tangent X  - Capture tangent thought X (calls `$tangent skill)" -ForegroundColor White
    Write-Host "  dtc break      - Take a break (calls `$break skill)" -ForegroundColor White
    Write-Host "  dtc review     - Daily review (calls `$review skill)" -ForegroundColor White
    Write-Host "  dtc brief      - Show current state (no codex launch)" -ForegroundColor White
    Write-Host "  dtc wrap       - End of day wrap-up" -ForegroundColor White
    Write-Host "  dtc help       - Show this help" -ForegroundColor White
    Write-Host ""
    Write-Host "State files:" -ForegroundColor Gray
    Write-Host "  $script:STATE_DIR" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# Main Entry Point
# ============================================================================

switch ($Command.ToLower()) {
    'start'   { Invoke-Start }
    'focus'   { Invoke-Focus -FocusArgs $Args }
    'stuck'   { Invoke-Stuck }
    'tangent' { Invoke-Tangent -TangentArgs $Args }
    'break'   { Invoke-Break }
    'review'  { Invoke-Review }
    'brief'   { Show-Brief }
    'wrap'    { Invoke-Wrap }
    'help'    { Show-Help }
    default   { Show-Help }
}
