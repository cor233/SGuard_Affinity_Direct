function Show-Menu {
    param([string]$Exist)
    Clear-Host
	"`n ########################################"
	" # "
	" # 欢迎使用由阿政倾情制作的PowerShell脚本"
	" # "
	" # 脚本功能：ACE反作弊程序后台自动降低优先级与CPU相关性"
	" # "
	" # 优化程序：SGuard64.exe  SGuardSvc64.exe"
	" # "
	" ########################################"
    if ($Exist -eq "True") {
        "`n 1.覆盖重装(回车默认)"
        "`n 2.卸载"
        "`n 3.GitHub"
        "`n 4.退出"
    } else {
        "`n 1.安装(回车默认)"
        "`n 2.GitHub"
        "`n 3.退出"
    }
}

function New-AffinityBatFile {
    param([string]$Dir, [string[]]$Files)
    # 创建 BAT 文件
    $BatContent64 = @'
wmic process where "name='SGuard64.exe'" call setpriority 64 >nul 2>&1
powershell -NoP -C "Get-Process SGuard64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@
    $BatContentSvc64 = @'
wmic process where "name='SGuardSvc64.exe'" call setpriority 64 >nul 2>&1
powershell -NoP -C "Get-Process SGuardSvc64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@

    New-Item -ItemType Directory -Force $script:Dir | Out-Null
    Set-Content -Path (Join-Path $script:Dir $Files[0]) -Value $BatContent64 -Encoding ASCII
    Set-Content -Path (Join-Path $script:Dir $Files[1]) -Value $BatContentSvc64 -Encoding ASCII
    Write-Host " ✅ bat文件已创建" -ForegroundColor Green
}

function New-AffinityTask {
    param([string]$TaskName, [string]$ProcessName, [string]$BatFile)

    # 删除旧任务
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    # 创建新任务
    $service = New-Object -ComObject Schedule.Service
    $service.Connect()
    $root = $service.GetFolder('\')
    $task = $service.NewTask(0)
    $task.RegistrationInfo.Description = "$ProcessName 启动即运行 ${BatFile}.bat"
    $task.Principal.UserId = 'SYSTEM'
    $task.Principal.RunLevel = 1

    # 运行设置
    $set = $task.Settings
    $set.StartWhenAvailable = $true
    $set.AllowDemandStart = $true
    $set.DisallowStartIfOnBatteries = $false
    $set.StopIfGoingOnBatteries = $false
    $set.MultipleInstances = 2

    # 事件触发
    $trigger = $task.Triggers.Create(0)  # EventTrigger
    $trigger.Subscription = @"
<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>
      *[System[EventID=4688]] and
      *[EventData[Data[@Name='NewProcessName'] and (Data="C:\Program Files\AntiCheatExpert\SGuard\x64\$ProcessName.exe")]]
    </Select>
  </Query>
</QueryList>
"@
    $trigger.Enabled = $true

    # 动作
    $action = $task.Actions.Create(0)
    $action.Path = (Join-Path $script:Dir $BatFile)
    $action.Arguments = ''
    $action.WorkingDirectory = 'D:\'

    $root.RegisterTaskDefinition($TaskName, $task, 6, $null, $null, 1, $null) | Out-Null
}

function Do-CommonWork {
    param([string]$Dir, [string[]]$Files, [string[]]$Tasks)

    # 启用审计和任务历史
    auditpol /set /subcategory:'{0CCE922B-69AE-11D9-BED3-505054503030}' /success:enable | Out-Null
    Write-Host " ✅ 进程创建审计已启用" -ForegroundColor Green
    wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true /quiet
    Write-Host " ✅ 任务历史记录已启用" -ForegroundColor Green

    # 创建 BAT 文件
    New-AffinityBatFile -Dir $Dir -Files $Files

    # 创建任务
    New-AffinityTask -TaskName $Tasks[0] -ProcessName 'SGuard64' -BatFile $Files[0]
    New-AffinityTask -TaskName $Tasks[1] -ProcessName 'SGuardSvc64' -BatFile $Files[1]

    Write-Host " ✅ 事件任务创建成功" -ForegroundColor Green
    Write-Host " 制裁ACE成功，又少一个打不过对面的理由" -ForegroundColor Green
    Read-Host "`n 按回车返回菜单"
    break
}

function Uninstall-Affinity {
    param([string]$Dir, [string[]]$Files, [string[]]$Tasks)

    # 删除文件
    foreach ($f in $Files) {
        Remove-Item (Join-Path $Dir $f) -Force -ErrorAction SilentlyContinue
    }
    Write-Host " ✅ BAT文件已删除" -ForegroundColor Green

    # 删除任务
    foreach ($t in $Tasks) {
        Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-Host " ✅ 事件任务已删除" -ForegroundColor Green
    Read-Host "`n 按回车返回菜单"
}

# ========== 主循环 ==========
while ($true) {
    # 设置窗口大小
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(60, 30)

    # 权限检测
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 这里-string 把整段脚本源码当文本传过去
    $source = @'
'@ + $MyInvocation.MyCommand.ScriptBlock.ToString() + @'
'@
    # 用 -Command 重新执行；加 -NoExit 方便调试，正式用可去掉
    Start-Process powershell.exe -ArgumentList '-NoExit','-Command',$source -Verb RunAs
    exit
}
    Clear-Host
    "`n 获取脚本信息......"
    $Protocol   = "https:"
	$Domain     = "//github.com"
	$Owner      = "aznb6666"
	$Repo       = "SGuard_Affinity_Direct"
	$repoUrl    = $Protocol + $Domain + "/" + $Owner + "/" + $Repo
    $RawUI = $Host.UI.RawUI
    $RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($RawUI.WindowSize.Width, $RawUI.WindowSize.Height)

    # 目录和文件/任务定义
    $Dir = 'C:\Program Files\AntiCheatExpert\SGuard\x64'
    $Files = @('SGuard64_Affinity_Direct.bat', 'SGuardSvc64_Affinity_Direct.bat')
    $Tasks = @('SGuard64_Affinity_Direct', 'SGuardSvc64_Affinity_Direct')
	
    # 文件检测
    $FileExist = ($Files | ForEach-Object { Test-Path (Join-Path $Dir $_) }) -contains $true

    # 任务检测
    $TaskExist = ($Tasks | ForEach-Object { Get-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue }) -ne $null

    # 判断是否存在
    $Exist = if ($FileExist -or $TaskExist) { "True" } else { "False" }
    # 显示菜单（现在函数已预定义）
    Show-Menu -Exist $Exist

    # ========== 主流程 ==========
    $choice = (Read-Host "`n 请输入操作").Trim().ToUpper()

    switch ($choice) {
        '1' { Do-CommonWork -Dir $Dir -Files $Files -Tasks $Tasks; break }
        '2' {
            if ($Exist -ieq "True") {
                Uninstall-Affinity -Dir $Dir -Files $Files -Tasks $Tasks
            } else {
                Start-Process $repoUrl
            }
            break
        }
        '3' {
            if ($Exist -ieq "True") {
                Start-Process $repoUrl
            } else {
                # 退出脚本
                Get-Process -Id $PID | Stop-Process -Force
            }
            break
        }
        '4' {
            if ($Exist -ieq "True") {
                Get-Process -Id $PID | Stop-Process -Force
            }
        }
        '' { Do-CommonWork -Dir $Dir -Files $Files -Tasks $Tasks; break }  # 空输入默认安装/覆盖
    }

}
