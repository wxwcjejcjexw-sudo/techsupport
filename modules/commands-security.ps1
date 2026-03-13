# Commands Security Module

function Get-SecurityCommands {
    return @{
        firewallStatus = {
            Get-NetFirewallProfile | Select-Object Name, Enabled |
            Format-Table -AutoSize | Out-String
        }
        
        enableFirewall = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
            "Firewall enabled for all profiles"
        }
        
        disableFirewall = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
            "Firewall disabled for all profiles"
        }
        
        defenderStatus = {
            Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, AntivirusEnabled, 
            AntispywareEnabled, FirewallEnabled, AMServiceEnabled |
            Format-List | Out-String
        }
        
        defenderQuickScan = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Start-MpScan -ScanType QuickScan
            "Quick scan started"
        }
        
        defenderFullScan = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Start-MpScan -ScanType FullScan
            "Full scan started (runs in background)"
        }
        
        updateDefender = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Update-MpSignature
            "Defender signatures updated"
        }
        
        uacStatus = {
            $uac = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
            $level = $uac.ConsentPromptBehaviorAdmin
            
            $levelName = switch ($level) {
                0 { "Never notify" }
                1 { "Always notify" }
                2 { "Default - Notify on app changes" }
                3 { "Default - Notify on app changes without dimming" }
                4 { "Default - Notify on app changes" }
                5 { "Default - Notify on app changes without dimming" }
                default { "Unknown" }
            }
            
            @"
UAC Status: Enabled
Prompt Level: $levelName
Value: $level
"@
        }
        
        userAccountInfo = {
            $current = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($current)
            $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            $groups = $current.Groups | ForEach-Object {
                try {
                    $_.Translate([Security.Principal.NTAccount]).Value
                } catch {
                    $_.Value
                }
            }
            
            @"
Username: $env:USERNAME
Domain: $env:USERDOMAIN
Is Admin: $isAdmin
Groups: $($groups -join ', ')
"@
        }
        
        listUsers = {
            Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordRequired |
            Format-Table -AutoSize | Out-String
        }
        
        localAdmins = {
            Get-LocalGroupMember -Group "Administrators" | 
            Format-Table Name, ObjectClass, SID -AutoSize | Out-String
        }
        
        recentLogins = {
            Get-WinEvent -LogName Security -MaxEvents 20 -EA SilentlyContinue | 
            Where-Object { $_.Id -in @(4624, 4625) } |
            Select-Object TimeCreated, Id, Message |
            Format-Table -AutoSize -Wrap | Out-String
        }
        
        openPorts = {
            Get-NetTCPConnection -State Listen | 
            Select-Object LocalAddress, LocalPort, OwningProcess |
            Format-Table -AutoSize | Out-String
        }
        
        sharedFolders = {
            Get-SmbShare | Where-Object { $_.Name -ne "IPC$" } |
            Format-Table Name, Path, Description -AutoSize | Out-String
        }
        
        windowsUpdateStatus = {
            try {
                $service = Get-Service wuauserv -EA SilentlyContinue
                $status = if ($service) { $service.Status } else { "Unknown" }
                
                @"
Windows Update Service: $status
Note: Use 'checkUpdates' to scan for available updates
"@
            } catch {
                "Error checking Windows Update service: $_"
            }
        }
        
        checkUpdates = {
            $results = @()
            $results += "Checking for Windows updates..."
            $results += "(This may take up to 30 seconds)"
            $results += ""
            
            try {
                # Use timeout to prevent hanging
                $job = Start-Job {
                    $updateSession = New-Object -ComObject Microsoft.Update.Session
                    $searcher = $updateSession.CreateUpdateSearcher()
                    $search = $searcher.Search("IsInstalled=0")
                    return $search
                }
                
                # Wait max 30 seconds
                if (Wait-Job $job -Timeout 30) {
                    $search = Receive-Job $job
                    Remove-Job $job
                    
                    $results += "Found $($search.Updates.Count) updates:"
                    
                    foreach ($update in $search.Updates | Select-Object -First 10) {
                        $results += "  - $($update.Title)"
                    }
                    
                    if ($search.Updates.Count -eq 0) {
                        $results += "System is up to date"
                    }
                } else {
                    Stop-Job $job -EA SilentlyContinue
                    Remove-Job $job -EA SilentlyContinue
                    $results += "Update check timed out (30s). Windows Update service may be busy."
                }
            } catch {
                $results += "Error checking updates: $_"
            }
            
            $results -join "`n"
        }
        
        installUpdates = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            
            "Installing updates is not available in this version."
            "Please use Windows Settings > Update & Security > Windows Update"
        }
        
        restorePoints = {
            try {
                Get-ComputerRestorePoint | Select-Object SequenceNumber, CreationTime, Description |
                Format-Table -AutoSize | Out-String
            } catch {
                "No restore points found or System Restore disabled"
            }
        }
        
        createRestorePoint = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            Checkpoint-Computer -Description "TechSupport Restore Point" -RestorePointType MODIFY_SETTINGS
            "Restore point created"
        }
        
        windowsDefender = {
            try {
                Start-Process "windowsdefender:" -ErrorAction Stop
                "Windows Security (Defender) opened"
            } catch {
                "Error opening Windows Defender: $_"
            }
        }
        
        quickScan = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            try {
                Start-MpScan -ScanType QuickScan -ErrorAction Stop
                "Quick scan started"
            } catch {
                "Error starting quick scan: $_"
            }
        }
        
        securityAudit = {
            $results = @()
            $results += "=== Security Audit ==="
            $results += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            $results += ""
            
            try {
                $fw = Get-NetFirewallProfile | Select-Object Name, Enabled
                $results += "Firewall profiles:"
                $fw | ForEach-Object {
                    $state = if ($_.Enabled) { "On" } else { "Off" }
                    $results += "  - $($_.Name): $state"
                }
            } catch {
                $results += "Firewall status: error - $_"
            }
            
            try {
                $mp = Get-MpComputerStatus
                $results += ""
                $results += "Defender status:"
                $results += "  Real-time protection: $($mp.RealTimeProtectionEnabled)"
                $results += "  Antivirus enabled   : $($mp.AntivirusEnabled)"
                $results += "  Antispyware enabled: $($mp.AntispywareEnabled)"
                $results += "  AMService enabled  : $($mp.AMServiceEnabled)"
            } catch {
                $results += ""
                $results += "Defender status: error - $_"
            }
            
            try {
                $uac = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
                $level = $uac.ConsentPromptBehaviorAdmin
                $levelName = switch ($level) {
                    0 { "Never notify" }
                    1 { "Always notify" }
                    2 { "Default - Notify on app changes" }
                    3 { "Default - Notify on app changes without dimming" }
                    4 { "Default - Notify on app changes" }
                    5 { "Default - Notify on app changes without dimming" }
                    default { "Unknown" }
                }
                $results += ""
                $results += "UAC:"
                $results += "  Prompt level: $levelName ($level)"
            } catch {
                $results += ""
                $results += "UAC status: error - $_"
            }
            
            try {
                $service = Get-Service wuauserv -EA SilentlyContinue
                $status = if ($service) { $service.Status } else { "Unknown" }
                $results += ""
                $results += "Windows Update service: $status"
            } catch {
                $results += ""
                $results += "Windows Update status: error - $_"
            }
            
            $results -join "`n"
        }
    }
}
