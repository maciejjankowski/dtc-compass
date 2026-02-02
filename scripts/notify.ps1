<#
.SYNOPSIS
    DTC Compass - Windows Toast Notification Script

.DESCRIPTION
    Displays Windows toast notifications for DTC Compass.
    Can be called directly or used as a hook for Codex CLI's notify system.

    When used as a Codex notify hook:
    - Receives JSON input from codex on agent-turn-complete events
    - Parses the JSON to extract relevant information
    - Shows a Windows toast notification

.PARAMETER Title
    The notification title

.PARAMETER Message
    The notification message body

.PARAMETER Type
    Notification type: Info, Warning, Error, Success (affects icon/color)

.PARAMETER Sound
    If specified, plays a notification sound

.PARAMETER JsonInput
    JSON string input (for Codex hook integration)
    Expected format: { "event": "agent-turn-complete", "message": "...", "context": {...} }

.PARAMETER FromPipeline
    If specified, reads JSON from pipeline/stdin (for Codex integration)

.EXAMPLE
    .\notify.ps1 -Title "DTC Compass" -Message "Task completed!" -Type Success

.EXAMPLE
    .\notify.ps1 -Title "Focus Reminder" -Message "Time to take a break" -Sound

.EXAMPLE
    # Codex hook usage (JSON input):
    '{"event":"agent-turn-complete","message":"Analysis complete"}' | .\notify.ps1 -FromPipeline

.NOTES
    Author: MJ @ Future Processing
    Part of DTC Compass framework

    To use with Codex notify hook, add to your codex config:
    {
      "hooks": {
        "notify": "powershell -File path/to/notify.ps1 -FromPipeline"
      }
    }
#>

[CmdletBinding(DefaultParameterSetName = 'Direct')]
param(
    [Parameter(ParameterSetName = 'Direct', Position = 0)]
    [string]$Title = "DTC Compass",

    [Parameter(ParameterSetName = 'Direct', Position = 1)]
    [string]$Message = "",

    [Parameter(ParameterSetName = 'Direct')]
    [ValidateSet('Info', 'Warning', 'Error', 'Success')]
    [string]$Type = 'Info',

    [Parameter(ParameterSetName = 'Direct')]
    [switch]$Sound,

    [Parameter(ParameterSetName = 'Json')]
    [string]$JsonInput,

    [Parameter(ParameterSetName = 'Pipeline')]
    [switch]$FromPipeline
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = 'SilentlyContinue'

# Sound file paths (Windows default sounds)
$script:Sounds = @{
    Info    = "$env:SystemRoot\Media\Windows Notify.wav"
    Warning = "$env:SystemRoot\Media\Windows Exclamation.wav"
    Error   = "$env:SystemRoot\Media\Windows Critical Stop.wav"
    Success = "$env:SystemRoot\Media\Windows Notify System Generic.wav"
}

# ============================================================================
# Helper Functions
# ============================================================================

function Play-NotificationSound {
    <#
    .SYNOPSIS
        Play a notification sound
    #>
    param(
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$SoundType = 'Info'
    )

    $soundFile = $script:Sounds[$SoundType]
    if (Test-Path $soundFile) {
        try {
            $player = New-Object System.Media.SoundPlayer
            $player.SoundLocation = $soundFile
            $player.Play()
        }
        catch {
            # Fallback: system beep
            [Console]::Beep(800, 200)
        }
    }
    else {
        # Fallback: system beep
        [Console]::Beep(800, 200)
    }
}

function Show-ToastNotification {
    <#
    .SYNOPSIS
        Display a Windows toast notification
    #>
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Type = 'Info',
        [switch]$PlaySound
    )

    # Method 1: Try BurntToast module (best experience)
    if (Get-Module -ListAvailable -Name BurntToast) {
        try {
            Import-Module BurntToast -ErrorAction Stop

            # Map type to BurntToast app logo
            $appLogo = switch ($Type) {
                'Error'   { 'Error' }
                'Warning' { 'Warning' }
                'Success' { 'Info' }
                default   { 'None' }
            }

            $toastParams = @{
                Text = $Title, $Message
            }

            # Add sound if requested
            if ($PlaySound) {
                $toastParams['Sound'] = switch ($Type) {
                    'Error'   { 'Alarm' }
                    'Warning' { 'Alarm2' }
                    'Success' { 'Notification.Mail' }
                    default   { 'Default' }
                }
            }

            New-BurntToastNotification @toastParams
            return $true
        }
        catch {
            # Fall through to next method
        }
    }

    # Method 2: Try Windows.UI.Notifications (Windows 10+)
    try {
        # Load required assemblies
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        # Build toast XML
        $toastXml = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$([System.Security.SecurityElement]::Escape($Title))</text>
            <text id="2">$([System.Security.SecurityElement]::Escape($Message))</text>
        </binding>
    </visual>
</toast>
"@
        # Add audio element if sound requested
        if ($PlaySound) {
            $toastXml = $toastXml -replace '</toast>', @"
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@
        }

        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)

        # Show notification
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DTC Compass").Show($toast)

        return $true
    }
    catch {
        # Fall through to next method
    }

    # Method 3: Use Windows Forms notification (legacy but reliable)
    try {
        Add-Type -AssemblyName System.Windows.Forms

        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Information
        $balloon.BalloonTipIcon = switch ($Type) {
            'Error'   { [System.Windows.Forms.ToolTipIcon]::Error }
            'Warning' { [System.Windows.Forms.ToolTipIcon]::Warning }
            default   { [System.Windows.Forms.ToolTipIcon]::Info }
        }
        $balloon.BalloonTipTitle = $Title
        $balloon.BalloonTipText = $Message
        $balloon.Visible = $true
        $balloon.ShowBalloonTip(5000)

        # Clean up after 6 seconds
        Start-Sleep -Seconds 6
        $balloon.Dispose()

        if ($PlaySound) {
            Play-NotificationSound -SoundType $Type
        }

        return $true
    }
    catch {
        # Fall through to console output
    }

    # Method 4: Console fallback
    $color = switch ($Type) {
        'Error'   { 'Red' }
        'Warning' { 'Yellow' }
        'Success' { 'Green' }
        default   { 'Cyan' }
    }

    Write-Host ""
    Write-Host "[$Type] $Title" -ForegroundColor $color
    Write-Host "  $Message" -ForegroundColor White
    Write-Host ""

    if ($PlaySound) {
        Play-NotificationSound -SoundType $Type
    }

    return $true
}

function Parse-CodexJson {
    <#
    .SYNOPSIS
        Parse JSON input from Codex notify hook
    #>
    param(
        [string]$Json
    )

    try {
        $data = $Json | ConvertFrom-Json

        # Extract relevant fields
        $result = @{
            Title   = "DTC Compass"
            Message = ""
            Type    = "Info"
        }

        # Handle different event types
        if ($data.event) {
            switch ($data.event) {
                'agent-turn-complete' {
                    $result.Title = "Codex Complete"
                    $result.Type = "Success"
                }
                'agent-error' {
                    $result.Title = "Codex Error"
                    $result.Type = "Error"
                }
                'agent-waiting' {
                    $result.Title = "Codex Waiting"
                    $result.Type = "Info"
                }
            }
        }

        # Get message
        if ($data.message) {
            $result.Message = $data.message
        }
        elseif ($data.content) {
            # Truncate long content
            $content = $data.content.ToString()
            if ($content.Length -gt 200) {
                $content = $content.Substring(0, 197) + "..."
            }
            $result.Message = $content
        }
        elseif ($data.summary) {
            $result.Message = $data.summary
        }
        else {
            $result.Message = "Task completed"
        }

        # Check for error indicator
        if ($data.error -or $data.status -eq 'error') {
            $result.Type = "Error"
            if ($data.error) {
                $result.Message = $data.error.ToString()
            }
        }

        return $result
    }
    catch {
        # Return default if parsing fails
        return @{
            Title   = "DTC Compass"
            Message = "Notification received"
            Type    = "Info"
        }
    }
}

# ============================================================================
# Main Logic
# ============================================================================

# Determine input method and get notification data
$notifyData = $null

switch ($PSCmdlet.ParameterSetName) {
    'Direct' {
        # Direct parameters provided
        $notifyData = @{
            Title   = $Title
            Message = $Message
            Type    = $Type
        }
    }

    'Json' {
        # JSON string provided as parameter
        $notifyData = Parse-CodexJson -Json $JsonInput
    }

    'Pipeline' {
        # Read from pipeline/stdin
        $pipelineInput = @($input) -join "`n"
        if ([string]::IsNullOrWhiteSpace($pipelineInput)) {
            # Try reading from stdin
            $pipelineInput = [Console]::In.ReadToEnd()
        }

        if (-not [string]::IsNullOrWhiteSpace($pipelineInput)) {
            # Check if it looks like JSON
            if ($pipelineInput.Trim().StartsWith('{') -or $pipelineInput.Trim().StartsWith('[')) {
                $notifyData = Parse-CodexJson -Json $pipelineInput
            }
            else {
                # Plain text input
                $notifyData = @{
                    Title   = "DTC Compass"
                    Message = $pipelineInput.Trim()
                    Type    = "Info"
                }
            }
        }
        else {
            $notifyData = @{
                Title   = "DTC Compass"
                Message = "Notification received"
                Type    = "Info"
            }
        }
    }
}

# Show the notification
if ($notifyData) {
    $showParams = @{
        Title     = $notifyData.Title
        Message   = $notifyData.Message
        Type      = $notifyData.Type
        PlaySound = $Sound
    }

    Show-ToastNotification @showParams
}
else {
    Write-Warning "No notification data to display"
}
