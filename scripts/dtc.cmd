@echo off
REM ============================================================================
REM DTC Compass - Batch wrapper for dtc.ps1
REM ============================================================================
REM
REM This is a simple passthrough script that allows users to type:
REM   dtc start
REM   dtc focus <task>
REM   etc.
REM
REM Without needing to explicitly invoke PowerShell.
REM
REM Usage: Add the scripts directory to your PATH, or create an alias.
REM ============================================================================

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Pass all arguments to the PowerShell script
REM -ExecutionPolicy Bypass allows running unsigned scripts
REM -NoProfile speeds up startup by not loading profile
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%dtc.ps1" %*
