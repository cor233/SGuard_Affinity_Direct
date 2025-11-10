# 腾讯ACE磁盘扫描服务自动调整脚本
- 使用windows自带的事件触发器，无需依赖任何外部程序
- ACE反作弊程序启动时自动调成优先级为“低”，调整CPU相关性为CPU19(因为我的电脑最多只有19)
- 支持覆盖安装以及一键卸载
- 调整目标程序：SGuard64.exe SGuardSvc64.exe
### 你可以使用powershell输入以下命令一键在线运行此脚本(无需下载)
`irm https://monojson.com/s/2XOJ9 | iex`
### 也可以通过.bat保存为文件
[ACE_Affinity_Direct.bat](https://gh-proxy.com/https://github.com/aznb6666/SGuard_Affinity_Direct/blob/main/ACE_Affinity_Direct.bat "ACE_Affinity_Direct.bat")
