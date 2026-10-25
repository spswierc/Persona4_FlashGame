# Nozoki local HTTP server. Windows PowerShell 5.1 compatible.
# Serves files only from the assets directory; Ruffle is loaded by the webpage from unpkg CDN.
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'assets'))
$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.ico'  = 'image/x-icon'
    '.xml'  = 'application/xml; charset=utf-8'
    '.swf'  = 'application/x-shockwave-flash'
    '.js'   = 'text/javascript; charset=utf-8'
    '.wasm' = 'application/wasm'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.png'  = 'image/png'
    '.svg'  = 'image/svg+xml'
    '.css'  = 'text/css; charset=utf-8'
    '.map'  = 'application/json; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.txt'  = 'text/plain; charset=utf-8'
}
$rootPrefix = $root.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = ([System.Net.IPEndPoint] $listener.LocalEndpoint).Port
$url = "http://127.0.0.1:$port/play.html"
Write-Host "Nozoki (local game, CDN-based Ruffle): $url"
Write-Host 'Game and configuration are local. The browser downloads Ruffle from unpkg.com.'
Write-Host 'Press Ctrl+C in this window to quit.'
Start-Process $url
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 15000
            $client.SendTimeout = 30000
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
            $request = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($request)) { continue }
            do { $header = $reader.ReadLine() } while ($null -ne $header -and $header -ne '')
            $parts = $request.Split(' ')
            $method = $parts[0]
            $allowedMethod = $method -eq 'GET' -or $method -eq 'HEAD'
            $requested = if ($parts.Count -ge 2) { $parts[1].Split('?')[0] } else { '' }
            $decoded = [Uri]::UnescapeDataString($requested)
            $path = if ($decoded -eq '/') { '/play.html' } else { $decoded }
            $path = $path.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $full = [System.IO.Path]::GetFullPath((Join-Path $root $path))
            $extension = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
            $valid = $allowedMethod -and $full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and $mime.ContainsKey($extension) -and (Test-Path -LiteralPath $full -PathType Leaf)
            $status = if ($valid) { '200 OK' } elseif (!$allowedMethod) { '405 Method Not Allowed' } else { '404 Not Found' }
            if ($valid) {
                $size = ([System.IO.FileInfo]::new($full)).Length
                $type = $mime[$extension]
            } else {
                $message = [System.Text.Encoding]::UTF8.GetBytes($status)
                $size = $message.Length
                $type = 'text/plain; charset=utf-8'
            }
            $h = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $size`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
            $hb = [System.Text.Encoding]::ASCII.GetBytes($h)
            $stream.Write($hb, 0, $hb.Length)
            if ($method -ne 'HEAD') {
                if ($valid) {
                    $fs = [System.IO.File]::OpenRead($full)
                    try { $fs.CopyTo($stream) } finally { $fs.Dispose() }
                } else { $stream.Write($message, 0, $message.Length) }
            }
            $stream.Flush()
            Write-Host "$method $requested -> $status"
        } catch {
            Write-Warning "Request problem: $_"
        } finally {
            $client.Dispose()
        }
    }
} finally {
    $listener.Stop()
}
