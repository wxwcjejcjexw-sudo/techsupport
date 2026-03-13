# Commands Management Module

function Get-ManagementCommands {
    return @{
        cleanTemp = {
            $tempPath = $env:TEMP
            $before = (Get-ChildItem $tempPath -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$tempPath\*" -Recurse -Force -EA SilentlyContinue
            $after = (Get-ChildItem $tempPath -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            $freed = [math]::Round(($before - $after) / 1MB, 2)
            "TEMP cleaned. Freed: $freed MB"
        }
        
        cleanWindowsTemp = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            $path = "C:\Windows\Temp"
            $before = (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$path\*" -Recurse -Force -EA SilentlyContinue
            $after = (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            $freed = [math]::Round(($before - $after) / 1MB, 2)
            "Windows TEMP cleaned. Freed: $freed MB"
        }
        
        cleanPrefetch = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Remove-Item "C:\Windows\Prefetch\*" -Force -EA SilentlyContinue
            "Prefetch cleaned"
        }
        
        cleanRecycleBin = {
            Clear-RecycleBin -Force -EA SilentlyContinue
            "Recycle Bin cleaned"
        }
        
        cleanBrowserCache = {
            $paths = @(
                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
            )
            $total = 0
            foreach ($p in $paths) {
                if (Test-Path $p) {
                    $before = (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
                    Remove-Item "$p\*" -Recurse -Force -EA SilentlyContinue
                    $total += $before
                }
            }
            "Browser cache cleaned. Freed: $([math]::Round($total / 1MB, 2)) MB"
        }
        
        cleanWindowsUpdate = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Stop-Service wuauserv -Force -EA SilentlyContinue
            $path = "C:\Windows\SoftwareDistribution\Download"
            $before = (Get-ChildItem $path -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$path\*" -Recurse -Force -EA SilentlyContinue
            Start-Service wuauserv -EA SilentlyContinue
            "Windows Update cache cleaned. Freed: $([math]::Round($before / 1MB, 2)) MB"
        }
        
        fullDiagnostic = {
            $results = @()
            $results += "=== SYSTEM DIAGNOSTIC ==="
            $results += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            $results += ""
            
            $cpu = Get-CimInstance Win32_Processor
            $results += "CPU: $($cpu.Name)"
            $results += "Cores: $($cpu.NumberOfCores)"
            
            $os = Get-CimInstance Win32_OperatingSystem
            $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            $results += "RAM: $freeRAM / $totalRAM GB free"
            
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
            $totalDisk = [math]::Round($disk.Size / 1GB, 2)
            $freeDisk = [math]::Round($disk.FreeSpace / 1GB, 2)
            $results += "Disk C:: $freeDisk / $totalDisk GB free"
            
            $ping = Test-Connection 8.8.8.8 -Count 1 -Quiet -EA SilentlyContinue
            $internetStatus = if ($ping) { 'Available' } else { 'Unavailable' }
            $results += "Internet: $internetStatus"
            
            $results -join "`n"
        }
        
        quickFix = {
            $results = @()
            
            Clear-DnsClientCache -EA SilentlyContinue
            $results += "DNS cache cleared"
            
            if ($script:IsAdmin) {
                netsh winsock reset | Out-Null
                $results += "Winsock reset"
            }
            
            ipconfig /release | Out-Null
            ipconfig /renew | Out-Null
            $results += "IP renewed"
            
            $results -join "`n"
        }
        
        optimizeSystem = {
            $results = @()
            $totalFreed = 0
            
            $before = (Get-ChildItem $env:TEMP -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$($env:TEMP)\*" -Recurse -Force -EA SilentlyContinue
            $totalFreed += $before
            $results += "TEMP cleaned"
            
            Clear-RecycleBin -Force -EA SilentlyContinue
            $results += "Recycle Bin cleaned"
            
            Clear-DnsClientCache -EA SilentlyContinue
            $results += "DNS cache cleared"
            
            $results += "`nTotal freed: $([math]::Round($totalFreed / 1MB, 2)) MB"
            $results -join "`n"
        }
        
        systemSummary = {
            $os = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
            
            $ram = [math]::Round($os.TotalVisibleMemorySize / 1KB, 0)
            $freeRam = [math]::Round($os.FreePhysicalMemory / 1KB, 0)
            
            $adminText = if($script:IsAdmin){'YES'}else{'NO'}
            
            @"
SYSTEM SUMMARY
===============
Computer: $env:COMPUTERNAME
User: $env:USERNAME
Admin: $adminText

OS: $($os.Caption)
CPU: $($cpu.Name)
RAM: $freeRam / $ram MB free
Disk: $([math]::Round($disk.FreeSpace / 1GB, 1)) / $([math]::Round($disk.Size / 1GB, 1)) GB free
"@
        }
        
        openTaskManager = {
            try {
                Start-Process "taskmgr.exe" -ErrorAction Stop
                "Task Manager opened"
            } catch {
                "Error opening Task Manager: $_"
            }
        }
        
        openDeviceManager = {
            try {
                Start-Process "devmgmt.msc" -ErrorAction Stop
                "Device Manager opened"
            } catch {
                "Error opening Device Manager: $_"
            }
        }
        
        openControlPanel = {
            try {
                Start-Process "control.exe" -ErrorAction Stop
                "Control Panel opened"
            } catch {
                "Error opening Control Panel: $_"
            }
        }
        
        openMsConfig = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            try {
                Start-Process "msconfig.exe" -ErrorAction Stop
                "MSConfig opened"
            } catch {
                "Error opening MSConfig: $_"
            }
        }
        
        openRegistry = {
            try {
                Start-Process "regedit.exe" -ErrorAction Stop
                "Registry Editor opened"
            } catch {
                "Error opening Registry Editor: $_"
            }
        }
        
        openPowerShell = {
            try {
                Start-Process "powershell.exe" -ErrorAction Stop
                "PowerShell opened"
            } catch {
                "Error opening PowerShell: $_"
            }
        }
    }
}