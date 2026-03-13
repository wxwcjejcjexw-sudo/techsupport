# Commands System Module

function Get-SystemCommands {
    return @{
        systemInfo = {
            $os = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor
            $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
            
            @"
SYSTEM INFORMATION
==================
Computer: $env:COMPUTERNAME
User: $env:USERNAME
Domain: $env:USERDOMAIN

OS: $($os.Caption)
Version: $($os.Version)
Build: $($os.BuildNumber)
Architecture: $($os.OSArchitecture)

CPU: $($cpu.Name)
Manufacturer: $($cpu.Manufacturer)
Cores: $($cpu.NumberOfCores)
Threads: $($cpu.NumberOfLogicalProcessors)
Max Speed: $([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz

Total RAM: $([math]::Round($ram.Sum / 1GB, 2)) GB
Free RAM: $([math]::Round($os.FreePhysicalMemory / 1MB, 2)) GB

Boot Time: $($os.LastBootUpTime)
"@
        }
        
        checkDisk = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            "Running CHKDSK scan on C: (read-only mode)..."
            chkdsk C: /scan 2>&1 | Out-String
        }
        
        sfcScan = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            "Running System File Checker (this may take several minutes)..."
            try {
                $process = Start-Process sfc -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden
                "SFC scan completed with exit code: $($process.ExitCode)"
                "Exit codes: 0 = no errors, 1 = errors fixed, 2 = errors found but not fixed"
            } catch {
                "Error running SFC: $_"
            }
        }
        
        diskCleanup = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            "Running Disk Cleanup..."
            try {
                # Use cleanmgr /sagerun:1 with predefined settings
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
                $items = Get-ChildItem $regPath -EA SilentlyContinue
                foreach ($item in $items) {
                    Set-ItemProperty -Path $item.PSPath -Name "StateFlags0001" -Value 2 -EA SilentlyContinue
                }
                Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
                "Disk Cleanup completed"
            } catch {
                "Error running Disk Cleanup: $_"
            }
        }
        
        defragDisk = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            "Analyzing drive C:..."
            $analysis = Optimize-Volume -DriveLetter C -Analyze -Verbose 4>&1
            $analysis | Out-String
        }
        
        listProcesses = {
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 | 
            Format-Table Name, CPU, WorkingSet64, Id -AutoSize | Out-String
        }
        
        diskHealth = {
            Get-PhysicalDisk | Format-Table FriendlyName, MediaType, HealthStatus, OperationalStatus, Size -AutoSize | Out-String
        }
        
        batteryReport = {
            try {
                $path = "$env:USERPROFILE\Desktop\battery-report.html"
                $result = powercfg /batteryreport /output $path 2>&1
                if (Test-Path $path) {
                    "Battery report saved to: $path"
                } else {
                    "Failed to create battery report"
                }
            } catch {
                "Error creating battery report: $_"
            }
        }
        
        eventViewer = {
            try {
                $events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2,3; StartTime=(Get-Date).AddDays(-1)} -MaxEvents 50 -EA SilentlyContinue |
                    Select-Object TimeCreated, Id, LevelDisplayName, Message |
                    Format-Table -AutoSize -Wrap | Out-String
                if ($events) { $events } else { "No critical events found in last 24 hours" }
            } catch {
                "Error reading event log: $_"
            }
        }
        
        driverQuery = {
            try {
                Get-WmiObject Win32_SystemDriver | Where-Object { $_.State -eq 'Running' } |
                    Select-Object Name, DisplayName, State, StartMode |
                    Format-Table -AutoSize | Out-String
            } catch {
                "Error querying drivers: $_"
            }
        }
        
        memoryDiagnostics = {
            try {
                $memory = Get-CimInstance Win32_PhysicalMemory
                $total = ($memory | Measure-Object Capacity -Sum).Sum / 1GB
                $results = @()
                $results += "Memory Information Report"
                $results += "========================"
                $results += "Total Memory: $([math]::Round($total, 2)) GB"
                $results += "Memory Modules: $($memory.Count)"
                foreach ($mem in $memory) {
                    $size = [math]::Round($mem.Capacity / 1GB, 2)
                    $speed = if ($mem.Speed) { "$($mem.Speed) MHz" } else { "Unknown" }
                    $results += "  - $($mem.DeviceLocator): $size GB @ $speed"
                }
                $results += ""
                $results += "To run Windows Memory Diagnostic, use command: mdsched"
                $results -join "`n"
            } catch {
                "Error getting memory info: $_"
            }
        }
        
        performanceReport = {
            try {
                Get-WinEvent -LogName 'Microsoft-Windows-Diagnostics-Performance/Operational' -MaxEvents 10 -EA SilentlyContinue |
                Format-Table TimeCreated, Id, LevelDisplayName -AutoSize | Out-String
            } catch {
                "No performance events found"
            }
        }
    }
}