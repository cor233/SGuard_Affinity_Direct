while ($true) {
	$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(60, 30)
	#权限检测
	if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		Start-Process powershell.exe "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
		exit
	}
	Clear-Host
	$Win = $Host.UI.RawUI
	$Buf = $Win.BufferSize
	$Win.BufferSize = New-Object System.Management.Automation.Host.Size(
		$Win.WindowSize.Width,
		$Win.WindowSize.Height
	)

	# 文件检测
	$Dir   = 'C:\Program Files\AntiCheatExpert\SGuard\x64'
	$File1 = 'SGuard64_Affinity_Direct.bat'
	$File2 = 'SGuardSvc64_Affinity_Direct.bat'
	$FileExist = (Test-Path (Join-Path $Dir $File1)) -or (Test-Path (Join-Path $Dir $File2))

	# 任务检测
	$Task1 = 'SGuard64_Affinity_Direct'
	$Task2 = 'SGuardSvc64_Affinity_Direct'
	$TaskExist = (Get-ScheduledTask -TaskName $Task1 -ErrorAction SilentlyContinue) -or `
				 (Get-ScheduledTask -TaskName $Task2 -ErrorAction SilentlyContinue)

	# 判断
	if ($FileExist -or $TaskExist) {
		$Exist = "True"
		"########################################"
		"#"
		"# 欢迎使用由阿政倾情制作的PowerShell脚本"
		"#"
		"# 脚本功能：ACE反作弊程序运行时自动降低优先级与CPU相关性"
		"#"
		"########################################"
		
		"`n1.覆盖重装(回车默认)"
		"`n2.卸载"
		"`n3.GitHub"
		"`n4.退出"
	} else {
		$Exist = "False"
		"`n1.安装(回车默认)"
		"`n2.GitHub"
		"`n3.退出"
	}


	# ========== 公共函数 ==========
	function Do-CommonWork {
		auditpol /set /subcategory:'{0CCE922B-69AE-11D9-BED3-505054503030}' /success:enable | Out-Null
		Write-Host "✅ 进程创建审计已启用" -ForegroundColor Green

		wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true /quiet
		Write-Host "✅ 任务历史记录已启用" -ForegroundColor Green


		New-Item -ItemType Directory -Force $Dir | Out-Null

		Set-Content -Path "$Dir\SGuard64_Affinity_Direct.bat" -Value @'
	wmic process where "name='SGuard64.exe'" call setpriority 64 >nul 2>&1
	powershell -NoP -C "Get-Process SGuard64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@ -Encoding ASCII

		Set-Content -Path "$Dir\SGuardSvc64_Affinity_Direct.bat" -Value @'

	wmic process where "name='SGuardSvc64.exe'" call setpriority 64 >nul 2>&1
	powershell -NoP -C "Get-Process SGuardSvc64 | %%{$_.ProcessorAffinity = 0x80000L}"
'@ -Encoding ASCII
		Write-Host "✅ bat文件已创建" -ForegroundColor Green
		"文件所在目录:`nC:\Program Files\AntiCheatExpert\SGuard\x64\    #ACE程序所在目录"


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

		Write-Host "✅ 事件任务创建成功" -ForegroundColor Green

		Write-Host "压制ACE成功，又少一个打不过对面的理由" -ForegroundColor Green
	}

	# ========== 主流程 ==========

	$choice = (Read-Host "`n请输入操作").Trim().ToUpper()

	switch ($choice) {
		'1' {
			Do-CommonWork
			break
		}
		'2' {
			if ($Exist -ieq "True"){
				$Files = @('SGuard64_Affinity_Direct.bat', 'SGuardSvc64_Affinity_Direct.bat')
				$Tasks = @('SGuard64_Affinity_Direct', 'SGuardSvc64_Affinity_Direct')

				# 1. 删除文件（忽略不存在）
				foreach ($f in $Files) {
					Remove-Item (Join-Path $Dir $f) -Force -ErrorAction SilentlyContinue
				}

				# 2. 删除任务（忽略不存在）
				foreach ($t in $Tasks) {
					Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
				}
				break
				}else{
					Start-Process "https://github.com/aznb6666/SGuard_Affinity_Direct"
					break
					}
			
		}
		'3' {
			if ($Exist -ieq "True"){
				Start-Process "https://github.com/aznb6666/SGuard_Affinity_Direct"
				break
				}else{
					Get-Process -Id $PID | Stop-Process -Force
					}
			# 打开默认浏览器并访问指定 URL
			
		}
		'4' {
			if ($Exist -ieq "True"){
				Get-Process -Id $PID | Stop-Process -Force
				}
		}
		'' {
			# 空输入也调用同一段
			Do-CommonWork
			break
		}
	}

}