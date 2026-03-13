# Commands Info Module

function Get-InfoCommands {
    return @{
        whoIsConnected = {
            $results = @()
            $results += "=== Active Sessions ==="
            query session 2>&1 | Out-String
            $results += "`n=== Network Connections ==="
            Get-NetTCPConnection -State Established | 
            Select-Object LocalPort, RemoteAddress, RemotePort | 
            Format-Table -AutoSize | Out-String
        }
        
        installedPrograms = {
            $paths = @(
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            
            Get-ItemProperty $paths -EA SilentlyContinue | 
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Sort-Object DisplayName |
            Format-Table -AutoSize -Wrap | Out-String
        }
        
        startupPrograms = {
            Get-CimInstance Win32_StartupCommand | 
            Select-Object Name, Command, Location |
            Format-Table -AutoSize -Wrap | Out-String
        }
        
        networkConnections = {
            Get-NetTCPConnection -State Established | 
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State |
            Format-Table -AutoSize | Out-String
        }
        
        servicesList = {
            Get-Service | Where-Object { $_.Status -eq "Running" } |
            Select-Object Name, DisplayName, Status |
            Format-Table -AutoSize -Wrap | Out-String
        }
        
        systemUptime = {
            $os = Get-CimInstance Win32_OperatingSystem
            $uptime = (Get-Date) - $os.LastBootUpTime
            
            @"
Last Boot: $($os.LastBootUpTime)
Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes
"@
        }
        
        userInfo = {
            $current = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($current)
            $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            @"
User: $env:USERNAME
Domain: $env:USERDOMAIN
Computer: $env:COMPUTERNAME
SID: $($current.User.Value)
Admin: $isAdmin
"@
        }
        
        windowsStatus = {
            try {
                $license = Get-CimInstance SoftwareLicensingProduct -Filter "Name like '%Windows%'" | 
                Where-Object { $_.PartialProductKey }
                
                $status = switch ($license.LicenseStatus) {
                    0 { "Unlicensed" }
                    1 { "Licensed" }
                    2 { "OOBGrace" }
                    3 { "OOTGrace" }
                    4 { "NonGenuineGrace" }
                    5 { "Notification" }
                    6 { "ExtendedGrace" }
                    default { "Unknown" }
                }
                
                @"
Product: $($license.Name)
Status: $status
Partial Key: $($license.PartialProductKey)
"@
            } catch {
                "Unable to get Windows license status"
            }
        }
        
        windowsUpdates = {
            Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20 |
            Format-Table HotFixID, Description, InstalledOn -AutoSize | Out-String
        }
        
        recentFiles = {
            $recent = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -EA SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 20 Name, LastWriteTime
            
            if ($recent) {
                $recent | Format-Table -AutoSize | Out-String
            } else {
                "No recent files found"
            }
        }
        
        clearClipboard = {
            try {
                # Use Windows Forms for clipboard access
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.Clipboard]::Clear()
                "Clipboard cleared successfully"
            } catch {
                "Unable to clear clipboard: $_"
            }
        }
    }
}
