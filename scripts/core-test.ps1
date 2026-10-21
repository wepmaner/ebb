# Runs EbbCore tests on Windows inside the MSVC developer environment the Swift toolchain needs.
# Usage: powershell -File scripts/core-test.ps1 [extra swift test args]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$ErrorActionPreference = "Continue"
$vs = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;" + $env:Path
Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vs -DevCmdArguments "-arch=x64 -host_arch=x64" -SkipAutomaticLocation | Out-Null
# User-level variables written by the Swift installer (absent in shells opened before the install)
$userEnv = Get-ItemProperty "HKCU:\Environment"
if ($userEnv.SDKROOT) { $env:SDKROOT = $userEnv.SDKROOT }
if ($userEnv.DEVELOPER_DIR) { $env:DEVELOPER_DIR = $userEnv.DEVELOPER_DIR }
$env:Path = $userEnv.Path + ";" + $env:Path
Set-Location "$PSScriptRoot\..\Packages\EbbCore"
& swift test @Rest
exit $LASTEXITCODE
