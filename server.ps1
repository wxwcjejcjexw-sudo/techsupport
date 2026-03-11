# TechSupport Pro - Local HTTP Server
# PowerShell HTTP Server for executing system commands

Add-Type -AssemblyName System.Web

# Configuration
$Port = 8080
$BaseUrl = "http://localhost:$Port"

# HTML content path
$ScriptPath = $PSScriptRoot
$IndexPath = Join-Path $ScriptPath "index.html"
$StylesPath = Join-Path $ScriptPath "styles.css"
$ScriptJSPath = Join-Path $ScriptPath "script.js"

# Command definitions
$Commands = @{
    # Cleaning commands
    "cleanTemp" = {
        $tempPath = $env:TEMP
        $before = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $beforeMB = [math]::Round($before / 1MB, 2)
        
        Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $after = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $afterMB = [math]::Round($after / 1MB, 2)
        $freed = [math]::Round($beforeMB - $afterMB, 2)
        
        "TEMP folder cleanup`nPath: $tempPath`nFreed: $freed MB`nBefore: $beforeMB MB`nAfter: $afterMB MB"
    }
    
    "cleanWindowsTemp" = {
        $tempPath = "C:\Windows\Temp"
        $before = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $beforeMB = [math]::Round($before / 1MB, 2)
        
        Start-Process powershell -ArgumentList "-Command Remove-Item '$tempPath\*' -Recurse -Force -ErrorAction SilentlyContinue" -Verb RunAs -Wait
        
        $after = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $afterMB = [math]::Round($after / 1MB, 2)
        $freed = [math]::Round($beforeMB - $afterMB, 2)
        
        "Windows Temp cleanup`nPath: $tempPath`nFreed: $freed MB`nBefore: $beforeMB MB`nAfter: $afterMB MB"
    }
    
    "cleanPrefetch" = {
        $prefetchPath = "C:\Windows\Prefetch"
        $before = (Get-ChildItem $prefetchPath -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $beforeMB = [math]::Round($before / 1MB, 2)
        
        Start-Process powershell -ArgumentList "-Command Remove-Item '$prefetchPath\*' -Force -ErrorAction SilentlyContinue" -Verb RunAs -Wait
        
        $after = (Get-ChildItem $prefetchPath -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $afterMB = [math]::Round($after / 1MB, 2)
        $freed = [math]::Round($beforeMB - $afterMB, 2)
        
        "Prefetch cleanup`nPath: $prefetchPath`nFreed: $freed MB"
    }
    
    "cleanRecycleBin" = {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        "Recycle Bin cleared successfully!"
    }
    
    "cleanBrowserCache" = {
        $results = @()
        
        # Chrome
        $chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        if (Test-Path $chromeCache) {
            Remove-Item "$chromeCache\*" -Recurse -Force -ErrorAction SilentlyContinue
            $results += "Chrome: cache cleared"
        }
        
        # Edge
        $edgeCache = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        if (Test-Path $edgeCache) {
            Remove-Item "$edgeCache\*" -Recurse -Force -ErrorAction SilentlyContinue
            $results += "Edge: cache cleared"
        }
        
        # Firefox
        $firefoxCache = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $firefoxCache) {
            Get-ChildItem $firefoxCache -Directory | ForEach-Object {
                $cachePath = Join-Path $_.FullName "cache2"
                if (Test-Path $cachePath) {
                    Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            $results += "Firefox: cache cleared"
        }
        
        $results -join "`n"
    }
    
    "cleanWindowsUpdate" = {
        $wuPath = "C:\Windows\SoftwareDistribution\Download"
        $before = (Get-ChildItem $wuPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $beforeMB = [math]::Round($before / 1MB, 2)
        
        Start-Process powershell -ArgumentList "-Command Remove-Item '$wuPath\*' -Recurse -Force -ErrorAction SilentlyContinue" -Verb RunAs -Wait
        
        $after = (Get-ChildItem $wuPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $afterMB = [math]::Round($after / 1MB, 2)
        $freed = [math]::Round($beforeMB - $afterMB, 2)
        
        "Windows Update files cleanup`nFreed: $freed MB"
    }
    
    # Network commands
    "flushDNS" = {
        $result = ipconfig /flushdns 2>&1
        $result | Out-String
    }
    
    "releaseRenewIP" = {
        $release = ipconfig /release 2>&1
        Start-Sleep -Seconds 2
        $renew = ipconfig /renew 2>&1
        "IP Release:`n$release`n`nIP Renew:`n$renew"
    }
    
    "resetNetwork" = {
        netsh winsock reset
        netsh int ip reset
        ipconfig /release
        ipconfig /renew
        "Network stack reset successfully!`nReboot recommended."
    }
    
    "showNetworkInfo" = {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $results = @()
        
        foreach ($adapter in $adapters) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $mac = $adapter.MacAddress
            $gateway = Get-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
            
            $results += "Adapter: $($adapter.Name)"
            $results += "  MAC: $mac"
            $results += "  IP: $($ip.IPAddress)"
            $results += "  Gateway: $($gateway.NextHop)"
            $results += ""
        }
        
        $results -join "`n"
    }
    
    "pingGoogle" = {
        $result = ping 8.8.8.8 -n 4 2>&1
        $result | Out-String
    }
    
    "resetWinsock" = {
        $result = netsh winsock reset 2>&1
        "$result`nWinsock catalog reset! Reboot recommended."
    }
    
    # System commands
    "systemInfo" = {
        $info = Get-ComputerInfo
        $results = @()
        $results += "Computer Name: $($info.CsName)"
        $results += "OS: $($info.WindowsProductName) $($info.WindowsVersion)"
        $results += "Build: $($info.OsBuildNumber)"
        $results += "CPU: $($info.CsProcessors[0].Name)"
        $results += "RAM: $([math]::Round($info.CsTotalPhysicalMemory / 1GB, 2)) GB"
        $results += "Manufacturer: $($info.CsManufacturer)"
        $results += "Model: $($info.CsModel)"
        $results += "Uptime: $($info.OsUptime)"
        
        $results -join "`n"
    }
    
    "checkDisk" = {
        Start-Process cmd -ArgumentList "/c echo Y | chkdsk C: /F" -Verb RunAs -Wait
        "Disk check for C: started. Check the separate window."
    }
    
    "sfcScan" = {
        Start-Process powershell -ArgumentList "-Command sfc /scannow; pause" -Verb RunAs
        "SFC scan started in separate window with admin rights."
    }
    
    "diskCleanup" = {
        Start-Process cleanmgr -ArgumentList "/d C"
        "Disk Cleanup utility started."
    }
    
    "defragDisk" = {
        Start-Process powershell -ArgumentList "-Command Optimize-Volume -DriveLetter C -Verbose; pause" -Verb RunAs
        "Disk C: optimization started in separate window."
    }
    
    "listProcesses" = {
        $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 20
        $results = @()
        $results += "Top 20 processes by CPU usage:`n"
        $results += "{0,-30} {1,10} {2,10} {3,15}" -f "Name", "CPU (s)", "RAM (MB)", "Threads"
        $results += "-" * 70
        
        foreach ($p in $processes) {
            $results += "{0,-30} {1,10:N0} {2,10:N0} {3,15}" -f $p.ProcessName, $p.CPU, ([math]::Round($p.WorkingSet64 / 1MB, 0)), $p.Threads.Count
        }
        
        $results -join "`n"
    }
    
    # Security commands
    "firewallStatus" = {
        $status = Get-NetFirewallProfile
        $results = @()
        
        foreach ($profile in $status) {
            $results += "Profile: $($profile.Name)"
            $results += "  Enabled: $($profile.Enabled)"
            $results += "  Action: $($profile.DefaultInboundAction)/$($profile.DefaultOutboundAction)"
            $results += ""
        }
        
        $results -join "`n"
    }
    
    "windowsDefender" = {
        Start-Process "windowsdefender:"
        "Windows Defender Security Center opened."
    }
    
    "quickScan" = {
        Start-Process powershell -ArgumentList "-Command Start-MpScan -ScanType QuickScan; Write-Host 'Quick scan started...'; pause" -Verb RunAs
        "Windows Defender quick scan started."
    }
    
    "updateDefender" = {
        Start-Process powershell -ArgumentList "-Command Update-MpSignature; Write-Host 'Signature update completed'; pause" -Verb RunAs
        "Windows Defender signature update started."
    }
    
    "showOpenPorts" = {
        $connections = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Select-Object LocalPort, OwningProcess
        $results = @()
        $results += "Open ports:`n"
        $results += "{0,10} {1,10} {2,-30}" -f "Port", "PID", "Process"
        $results += "-" * 55
        
        foreach ($conn in $connections | Sort-Object LocalPort) {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $results += "{0,10} {1,10} {2,-30}" -f $conn.LocalPort, $conn.OwningProcess, $process.ProcessName
        }
        
        $results -join "`n"
    }
    
    "securityAudit" = {
        $results = @()
        
        # Windows Defender
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        $results += "Windows Defender:"
        $results += "  Real-time protection: $($defender.RealTimeProtectionEnabled)"
        $results += "  Antivirus enabled: $($defender.AntivirusEnabled)"
        $results += ""
        
        # Firewall
        $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
        $results += "Firewall:"
        $results += "  Active profiles: $($firewall.Count)"
        $results += ""
        
        # Windows Update
        $update = Get-Service wuauserv -ErrorAction SilentlyContinue
        $results += "Windows Update:"
        $results += "  Service status: $($update.Status)"
        $results += ""
        
        # UAC
        $uac = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA
        $uacStatus = if($uac -eq 1){"Enabled"}else{"Disabled"}
        $results += "UAC: $uacStatus"
        
        $results -join "`n"
    }
    
    # Diagnostics commands
    "diskHealth" = {
        $disks = Get-PhysicalDisk
        $results = @()
        
        foreach ($disk in $disks) {
            $results += "Disk: $($disk.FriendlyName)"
            $results += "  Type: $($disk.MediaType)"
            $results += "  Size: $([math]::Round($disk.Size / 1GB, 2)) GB"
            $results += "  Health: $($disk.HealthStatus)"
            $results += "  Status: $($disk.OperationalStatus)"
            $results += ""
        }
        
        $results -join "`n"
    }
    
    "batteryReport" = {
        $reportPath = "$env:USERPROFILE\Desktop\battery-report.html"
        powercfg /batteryreport /output $reportPath
        "Battery report saved to: $reportPath"
    }
    
    "eventViewer" = {
        eventvwr.msc
        "Event Viewer opened."
    }
    
    "driverQuery" = {
        $drivers = driverquery /v /fo csv 2>&1 | ConvertFrom-Csv | Select-Object -First 30
        $results = @()
        $results += "Installed drivers (first 30):`n"
        $results += "{0,-40} {1,-15} {2,-12}" -f "Name", "Type", "Date"
        $results += "-" * 70
        
        foreach ($driver in $drivers) {
            $results += "{0,-40} {1,-15} {2,-12}" -f $driver.'Module Name', $driver.'Driver Type', $driver.'Date'
        }
        
        $results -join "`n"
    }
    
    "memoryDiagnostics" = {
        Start-Process powershell -ArgumentList "-Command Write-Host 'Starting memory diagnostics...'; Start-Process mdshedex.exe -Wait; pause" -Verb RunAs
        "Memory diagnostics will run on next reboot."
    }
    
    "performanceReport" = {
        Start-Process powershell -ArgumentList "-Command Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' -MaxEvents 10 | Format-List; pause" -NoNewWindow
        "Check Event Viewer for performance report."
    }
    
    # Tools commands
    "openTaskManager" = {
        taskmgr
        "Task Manager opened."
    }
    
    "openDeviceManager" = {
        devmgmt.msc
        "Device Manager opened."
    }
    
    "openControlPanel" = {
        control
        "Control Panel opened."
    }
    
    "openMsConfig" = {
        msconfig
        "System Configuration opened."
    }
    
    "openRegistry" = {
        regedit
        "Registry Editor opened."
    }
    
    "openPowerShell" = {
        Start-Process powershell
        "PowerShell opened."
    }
    
    # Quick Actions
    "fullDiagnostic" = {
        $results = @()
        $results += "=" * 50
        $results += "      FULL SYSTEM DIAGNOSTIC"
        $results += "=" * 50
        $results += ""
        
        # CPU Info
        $cpu = Get-WmiObject Win32_Processor
        $results += "> CPU"
        $results += "  Name: $($cpu.Name)"
        $results += "  Cores: $($cpu.NumberOfCores)"
        $results += "  Load: $($cpu.LoadPercentage)%"
        $results += ""
        
        # RAM Info
        $os = Get-WmiObject Win32_OperatingSystem
        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRAM = [math]::Round($totalRAM - $freeRAM, 2)
        $results += "> MEMORY"
        $results += "  Total: $totalRAM GB"
        $results += "  Used: $usedRAM GB"
        $results += "  Free: $freeRAM GB"
        $results += ""
        
        # Disk Info
        $disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $results += "> DISKS"
        foreach ($disk in $disks) {
            $total = [math]::Round($disk.Size / 1GB, 2)
            $free = [math]::Round($disk.FreeSpace / 1GB, 2)
            $used = [math]::Round($total - $free, 2)
            $results += "  $($disk.DeviceID) Total: ${total}GB | Used: ${used}GB | Free: ${free}GB"
        }
        $results += ""
        
        # Network
        $netAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $results += "> NETWORK"
        $results += "  Active adapters: $($netAdapters.Count)"
        foreach ($adapter in $netAdapters) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $results += "  $($adapter.Name): $($ip.IPAddress)"
        }
        $results += ""
        
        # Security
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        $defStatus = if($defender.RealTimeProtectionEnabled){"Active"}else{"Inactive"}
        $results += "> SECURITY"
        $results += "  Defender: $defStatus"
        $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
        $fwStatus = if($firewall){"Active"}else{"Inactive"}
        $results += "  Firewall: $fwStatus"
        $results += ""
        
        $results += ("=" * 50)
        $results += "      DIAGNOSTIC COMPLETE"
        $results += ("=" * 50)
        
        $results -join "`n"
    }
    
    "quickFix" = {
        $results = @()
        $results += "=" * 50
        $results += "      QUICK FIX"
        $results += "=" * 50
        $results += ""
        
        # DNS Flush
        $results += "> Flushing DNS cache..."
        $dns = ipconfig /flushdns 2>&1
        $results += "  Done"
        
        # Reset Network Stack
        $results += "> Resetting Winsock..."
        netsh winsock reset | Out-Null
        $results += "  Done"
        
        # Clear ARP Cache
        $results += "> Clearing ARP cache..."
        netsh interface ip delete arpcache | Out-Null
        $results += "  Done"
        
        # Reset IP
        $results += "> Resetting IP configuration..."
        netsh int ip reset | Out-Null
        $results += "  Done"
        
        $results += ""
        $results += ("=" * 50)
        $results += "   Reboot recommended!"
        $results += ("=" * 50)
        
        $results -join "`n"
    }
    
    "optimizeSystem" = {
        $results = @()
        $results += "=" * 50
        $results += "      SYSTEM OPTIMIZATION"
        $results += "=" * 50
        $results += ""
        
        # Clean Temp
        $results += "> Cleaning temp files..."
        $tempBefore = (Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        $tempAfter = (Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $results += "  Freed: $([math]::Round(($tempBefore - $tempAfter) / 1MB, 2)) MB"
        
        # Clean Recycle Bin
        $results += "> Cleaning Recycle Bin..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        $results += "  Done"
        
        # DNS Flush
        $results += "> Flushing DNS cache..."
        ipconfig /flushdns | Out-Null
        $results += "  Done"
        
        # Disk Analysis
        $results += "> Analyzing disk C:..."
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
        $results += "  Free on C:: $freeSpace GB"
        
        $results += ""
        $results += ("=" * 50)
        $results += "      OPTIMIZATION COMPLETE"
        $results += ("=" * 50)
        
        $results -join "`n"
    }
}

# System Info endpoint
function Get-SystemInfo {
    $cpu = (Get-WmiObject Win32_Processor).Name
    $ram = (Get-WmiObject Win32_OperatingSystem)
    $totalRAM = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($ram.FreePhysicalMemory / 1MB, 2)
    
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    $os = (Get-WmiObject Win32_OperatingSystem).Caption
    
    return @{
        cpu = $cpu
        ram = "$freeRAM GB / $totalRAM GB"
        disk = "$diskFree GB / $diskTotal GB"
        os = $os
    }
}

# HTTP Listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("$BaseUrl/")
$listener.Prefixes.Add("$BaseUrl/api/")

try {
    $listener.Start()
    Write-Host "=" * 60
    Write-Host "    TechSupport Pro - Server Started" -ForegroundColor Green
    Write-Host "=" * 60
    Write-Host ""
    Write-Host "  Web interface: $BaseUrl" -ForegroundColor Yellow
    Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=" * 60
    
    # Open browser
    Start-Process $BaseUrl
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.AbsolutePath
        $method = $request.HttpMethod
        
        # CORS headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        if ($method -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }
        
        try {
            switch ($path) {
                "/" {
                    $content = [System.IO.File]::ReadAllBytes($IndexPath)
                    $response.ContentType = "text/html; charset=utf-8"
                    $response.ContentLength64 = $content.Length
                    $response.OutputStream.Write($content, 0, $content.Length)
                }
                
                "/styles.css" {
                    $content = [System.IO.File]::ReadAllBytes($StylesPath)
                    $response.ContentType = "text/css; charset=utf-8"
                    $response.ContentLength64 = $content.Length
                    $response.OutputStream.Write($content, 0, $content.Length)
                }
                
                "/script.js" {
                    $content = [System.IO.File]::ReadAllBytes($ScriptJSPath)
                    $response.ContentType = "application/javascript; charset=utf-8"
                    $response.ContentLength64 = $content.Length
                    $response.OutputStream.Write($content, 0, $content.Length)
                }
                
                "/api/system-info" {
                    $info = Get-SystemInfo
                    $json = @{
                        success = $true
                        cpu = $info.cpu
                        ram = $info.ram
                        disk = $info.disk
                        os = $info.os
                    } | ConvertTo-Json
                    
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                }
                
                "/api/execute" {
                    if ($method -eq "POST") {
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $data = $body | ConvertFrom-Json
                        
                        $command = $data.command
                        
                        if ($Commands.ContainsKey($command)) {
                            try {
                                $result = & $Commands[$command]
                                $json = @{
                                    success = $true
                                    result = $result
                                } | ConvertTo-Json
                            } catch {
                                $json = @{
                                    success = $false
                                    error = $_.Exception.Message
                                } | ConvertTo-Json
                            }
                        } else {
                            $json = @{
                                success = $false
                                error = "Unknown command: $command"
                            } | ConvertTo-Json
                        }
                        
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $response.ContentType = "application/json; charset=utf-8"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                }
                
                default {
                    $response.StatusCode = 404
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                }
            }
        } catch {
            Write-Host "Error: $_" -ForegroundColor Red
            $response.StatusCode = 500
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error starting server: $_" -ForegroundColor Red
    Write-Host "Make sure the port is not in use." -ForegroundColor Yellow
} finally {
    $listener.Stop()
}