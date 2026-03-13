# Commands Network Module

function Get-NetworkCommands {
    return @{
        flushDNS = {
            Clear-DnsClientCache
            "DNS cache cleared successfully"
        }
        
        releaseRenewIP = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            $results = @()
            $results += "WARNING: This will temporarily disconnect your network!"
            $results += "Renewing IP without releasing (safer method)..."
            $results += ""
            try {
                # Only renew, don't release (prevents disconnection)
                $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
                if ($adapter) {
                    ipconfig /renew "$($adapter.Name)" 2>&1 | Out-String
                    $results += "IP renewed for adapter: $($adapter.Name)"
                } else {
                    $results += "No active network adapter found"
                }
            } catch {
                $results += "Error: $_"
            }
            $results -join "`n"
        }
        
        resetNetwork = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            $results = @()
            $results += "Resetting Winsock..."
            netsh winsock reset 2>&1 | Out-String
            $results += "Resetting IP stack..."
            netsh int ip reset 2>&1 | Out-String
            $results += "Network reset complete. Please restart computer."
            $results -join "`n"
        }
        
        showNetworkInfo = {
            Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
            Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize | Out-String
        }
        
        pingGoogle = {
            Test-Connection 8.8.8.8 -Count 4 | Format-Table Address, ResponseTime, Status -AutoSize | Out-String
        }
        
        resetWinsock = {
            if (-not $script:IsAdmin) { throw "Admin required" }
            netsh winsock reset 2>&1 | Out-String
            "Winsock reset complete. Please restart computer."
        }
        
        showOpenPorts = {
            Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess |
            Format-Table -AutoSize | Out-String
        }
        
        networkConnections = {
            Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State |
            Format-Table -AutoSize | Out-String
        }
        
        speedTest = {
            $results = @()
            $results += "Testing connection to Google DNS..."
            $ping = Test-Connection 8.8.8.8 -Count 4
            $avg = ($ping | Measure-Object ResponseTime -Average).Average
            $results += "Average ping: $([math]::Round($avg, 2)) ms"
            
            $results += "`nTesting download speed..."
            $url = "http://speedtest.tele2.net/1MB.zip"
            $temp = "$env:TEMP\speedtest.zip"
            
            try {
                $time = Measure-Command { Invoke-WebRequest $url -OutFile $temp -UseBasicParsing }
                $size = (Get-Item $temp).Length
                $speed = [math]::Round($size / $time.TotalSeconds / 1KB, 2)
                $results += "Download speed: $speed KB/s"
                Remove-Item $temp -Force
            } catch {
                $results += "Speed test failed: $_"
            }
            
            $results -join "`n"
        }
        
        arpCache = {
            Get-NetNeighbor | Where-Object { $_.State -ne "Permanent" } |
            Format-Table IPAddress, LinkLayerAddress, InterfaceAlias -AutoSize | Out-String
        }
        
        routingTable = {
            Get-NetRoute | Where-Object { $_.DestinationPrefix -ne "0.0.0.0/0" } |
            Format-Table DestinationPrefix, NextHop, InterfaceAlias -AutoSize | Out-String
        }
    }
}