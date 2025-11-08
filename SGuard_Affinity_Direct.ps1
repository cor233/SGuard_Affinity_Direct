if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}


auditpol /set /subcategory:'{0CCE922B-69AE-11D9-BED3-505054503030}' /success:enable | Out-Null

wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true /quiet


$Dir = 'C:\Program Files\AntiCheatExpert\SGuard\x64'
New-Item -ItemType Directory -Force $Dir | Out-Null

Set-Content -Path "$Dir\SGuard64_Affinity_Direct.bat" -Value @'
@echo off
wmic process where "name='SGuard64.exe'" call setpriority 64 >nul 2>&1
powershell -NoP -C "Get-Process SGuard64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@ -Encoding ASCII


Unregister-ScheduledTask -TaskName 'SGuard64_Affinity_Direct' -Confirm:$false -ErrorAction SilentlyContinue

$service = New-Object -ComObject Schedule.Service
$service.Connect()
$root = $service.GetFolder('\')
$task = $service.NewTask(0)

$task.RegistrationInfo.Description = 'SGuard64启动即运行SGuard64_Affinity_Direct.bat'
$task.Principal.UserId   = 'SYSTEM'
$task.Principal.RunLevel = 1

$set = $task.Settings
$set.StartWhenAvailable         = $true
$set.AllowDemandStart           = $true
$set.DisallowStartIfOnBatteries = $false
$set.StopIfGoingOnBatteries     = $false
$set.MultipleInstances = 2

$trigger = $task.Triggers.Create(0)   # 0 = EventTrigger
$trigger.Subscription = @"
<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>
      *[System[EventID=4688]] and
      *[EventData[Data[@Name='NewProcessName'] and
                 (Data='C:\Program Files\AntiCheatExpert\SGuard\x64\SGuard64.exe')]]
    </Select>
  </Query>
</QueryList>
"@
$trigger.Enabled = $true

$action = $task.Actions.Create(0)
$action.Path  = 'C:\Program Files\AntiCheatExpert\SGuard\x64\SGuard64_Affinity_Direct.bat'
$action.Arguments = ''
$action.WorkingDirectory = 'D:\'

$root.RegisterTaskDefinition('SGuard64_Affinity_Direct', $task, 6, $null, $null, 1, $null) | Out-Null


Set-Content -Path "$Dir\SGuardSvc64_Affinity_Direct.bat" -Value @'
@echo off
wmic process where "name='SGuardSvc64.exe'" call setpriority 64 >nul 2>&1
powershell -NoP -C "Get-Process SGuardSvc64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@ -Encoding ASCII


Unregister-ScheduledTask -TaskName 'SGuardSvc64_Affinity_Direct' -Confirm:$false -ErrorAction SilentlyContinue

$service = New-Object -ComObject Schedule.Service
$service.Connect()
$root = $service.GetFolder('\')
$task = $service.NewTask(0)

$task.RegistrationInfo.Description = 'SGuardSvc64启动即运行SGuardSvc64_Affinity_Direct.bat'
$task.Principal.UserId   = 'SYSTEM'
$task.Principal.RunLevel = 1

# 运行设置
$set = $task.Settings
$set.StartWhenAvailable         = $true
$set.AllowDemandStart           = $true
$set.DisallowStartIfOnBatteries = $false
$set.StopIfGoingOnBatteries     = $false
$set.MultipleInstances = 2

$trigger = $task.Triggers.Create(0)   # 0 = EventTrigger
$trigger.Subscription = @"
<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>
      *[System[EventID=4688]] and
      *[EventData[Data[@Name='NewProcessName'] and
                 (Data='C:\Program Files\AntiCheatExpert\SGuard\x64\SGuardSvc64.exe')]]
    </Select>
  </Query>
</QueryList>
"@
$trigger.Enabled = $true

$action = $task.Actions.Create(0)
$action.Path  = 'C:\Program Files\AntiCheatExpert\SGuard\x64\SGuardSvc64_Affinity_Direct.bat'
$action.Arguments = ''
$action.WorkingDirectory = 'D:\'

$root.RegisterTaskDefinition('SGuard64_Affinity_Direct', $task, 6, $null, $null, 1, $null) | Out-Null
