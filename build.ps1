<#
.SYNOPSIS
This is a Powershell script to bootstrap a Fake build.
.DESCRIPTION
This Powershell script will download NuGet if missing, restore NuGet tools (including Fake)
and execute your Fake build script with the parameters you provide.
.PARAMETER Target
The build script target to run.
.PARAMETER Configuration
The build configuration to use.
.PARAMETER Verbosity
Specifies the amount of information to be displayed.
.PARAMETER WhatIf
Performs a dry run of the build script.
No tasks will be executed.
.PARAMETER ScriptArgs
Remaining arguments are added here.
#>

[CmdletBinding()]
Param(
    [string]$Target = "Default",
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [ValidateSet("Quiet", "Minimal", "Normal", "Verbose", "Diagnostic")]
    [string]$Verbosity = "Verbose",
    [switch]$WhatIf,
    [Parameter(Position=0,Mandatory=$false,ValueFromRemainingArguments=$true)]
    [string[]]$ScriptArgs
)

$FakeVersion = "4.63.0"
$NugetVersion = "5.8.0";
$NugetUrl = "https://dist.nuget.org/win-x86-commandline/v$NugetVersion/nuget.exe"
$ProtobufVersion = "3.4.0"
$DocfxVersion = "2.59.4"

# Make sure tools folder exists
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$ToolPath = Join-Path $PSScriptRoot "tools"
if (!(Test-Path $ToolPath)) {
    Write-Verbose "Creating tools directory..."
    New-Item -Path $ToolPath -Type directory | out-null
}

###########################################################################
# INSTALL NUGET
###########################################################################

# Make sure nuget.exe exists.
$NugetPath = Join-Path $ToolPath "nuget.exe"
if (!(Test-Path $NugetPath)) {
    Write-Host "Downloading NuGet.exe..."
    (New-Object System.Net.WebClient).DownloadFile($NugetUrl, $NugetPath);
}

###########################################################################
# INSTALL FAKE
###########################################################################
# Make sure Fake has been installed.

$FakeExePath = Join-Path $ToolPath "FAKE/tools/FAKE.exe"
if (!(Test-Path $FakeExePath)) {
    Write-Host "Installing Fake..."
    Invoke-Expression "&`"$NugetPath`" install Fake -ExcludeVersion -Version $FakeVersion -OutputDirectory `"$ToolPath`"" | Out-Null;
    if ($LASTEXITCODE -ne 0) {
        Throw "An error occured while restoring Fake from NuGet."
    }
}

###########################################################################
# Docfx
###########################################################################

# Make sure Docfx has been installed.
$DocfxExePath = Join-Path $ToolPath "docfx.console/tools/docfx.exe"
if (!(Test-Path $DocfxExePath)) {
    Write-Host "Installing Docfx..."
    Invoke-Expression "&`"$NugetPath`" install docfx.console -ExcludeVersion -Version $DocfxVersion -OutputDirectory `"$ToolPath`"" | Out-Null;
    if ($LASTEXITCODE -ne 0) {
        Throw "An error occured while restoring docfx.console from NuGet."
    }
}

###########################################################################
# SignTool
###########################################################################

# Make sure the SignClient has been installed
if (Get-Command signclient -ErrorAction SilentlyContinue) {
    Write-Host "Found SignClient. Skipping install."
}
else{
    $SignClientFolder = Join-Path $ToolPath "signclient"
    Write-Host "SignClient not found. Installing to ... $SignClientFolder"
    dotnet tool install SignClient --version 1.3.155 --tool-path "$SignClientFolder"
}

###########################################################################
# RUN BUILD SCRIPT
###########################################################################

# Build the argument list.
$Arguments = @{
    target=$Target;
    configuration=$Configuration;
    verbosity=$Verbosity;
    dryrun=$WhatIf;
}.GetEnumerator() | %{"--{0}=`"{1}`"" -f $_.key, $_.value };

# Start Fake
Write-Host "Running build script..."
Invoke-Expression "$FakeExePath `"build.fsx`" $ScriptArgs $Arguments"

exit $LASTEXITCODE