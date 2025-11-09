if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $url = 'https://raw.githubusercontent.com/aznb6666/SGuard_Affinity_Direct/main/SGuard_Affinity_Direct.ps1 '
    Start-Process powershell.exe "-NoExit -Command `"& {Invoke-Expression (Invoke-WebRequest -Uri '$url' -UseBasicParsing).Content}`"" -Verb RunAs
    exit
}