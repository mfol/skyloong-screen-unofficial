<#
.SYNOPSIS
  Controle serial da telinha SKYLOONG (ESP32-S3) para o server.py.
  Envia "teclas" pela COM (espelha o teclado: ver firmware debug_USB_UART) e
  imprime SOMENTE um JSON no stdout (pra o server.py parsear).

  NUNCA flasha nada. Só escreve teclas (= apertar botao) e/ou le o log.

.PARAMETER Action
  ports  -> lista as portas COM disponiveis.
  force  -> manda as teclas de "forcar conexao" (default ` e /), depois LE o log
            por alguns segundos e tenta extrair o IP que a tela pegou na LAN.
  exit   -> manda '/' (sai do modo Configuracao -> volta a tocar GIF), sem reboot.

.EXAMPLE
  pwsh -NoProfile -File serial-ctl.ps1 -Action ports
  pwsh -NoProfile -File serial-ctl.ps1 -Action force -Port COM6
  pwsh -NoProfile -File serial-ctl.ps1 -Action exit  -Port COM6
#>
[CmdletBinding()]
param(
    [ValidateSet('ports','force','exit','switch','reset','wakegif')]
    [string]$Action = 'ports',
    [string]$Port = 'COM6',
    [string]$Keys = '`/',          # sequencia de teclas p/ 'force' (crase = troca app/acorda; / = modo Config)
    [int]$ReadSeconds = 14         # janela de leitura do log no 'force' (sai antes se achar IP)
)

$ErrorActionPreference = 'Stop'

function Out-Json($obj) {
    # stdout = SO o JSON (compacto, 1 linha)
    [Console]::Out.Write(($obj | ConvertTo-Json -Compress -Depth 5))
}

function Strip-Ansi([string]$s) {
    if (-not $s) { return '' }
    $s = $s -replace "\x1b\[[0-9;]*m", ''          # cores ANSI do ESP-IDF
    $s = $s -replace "[\x00-\x08\x0B\x0C\x0E-\x1F]", ''  # outros controles (mantem \n \r \t)
    return $s
}

function Open-Port([string]$p) {
    $sp = New-Object System.IO.Ports.SerialPort $p, 115200, ([System.IO.Ports.Parity]::None), 8, ([System.IO.Ports.StopBits]::One)
    $sp.DtrEnable  = $false   # NAO resetar o ESP32 de proposito
    $sp.RtsEnable  = $false
    $sp.ReadTimeout = 300
    $sp.Open()
    return $sp
}

try {
    if ($Action -eq 'ports') {
        $ports = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
        Out-Json @{ ok = $true; ports = @($ports) }
        exit 0
    }

    $sp = Open-Port $Port
    try {
        Start-Sleep -Milliseconds 600
        [void]$sp.ReadExisting()   # drena o que estiver no buffer

        if ($Action -eq 'exit') {
            $sp.Write('/')          # sai do modo Configuracao
            Start-Sleep -Milliseconds 300
            Out-Json @{ ok = $true; action = 'exit' }
            exit 0
        }

        if ($Action -eq 'reset') {
            # HardReset estilo esptool: pulsa RTS (=> EN baixo => reset do chip), depois solta
            # (boot normal). DTR fica false (GPIO0 alto) pra NAO cair em modo download.
            # Usado pelo "keep-awake": destacada no USB, a tela dorme em 10 min; o reset
            # reinicia o contador (protocol_init zera o timer). Reset = reboot a quente, inofensivo.
            $sp.RtsEnable = $true
            Start-Sleep -Milliseconds 200
            $sp.RtsEnable = $false
            # best-effort: tentar ver o banner de boot (pode falhar: o USB re-enumera no reset)
            $booted = $false
            try {
                $sb = New-Object System.Text.StringBuilder
                $end = (Get-Date).AddSeconds(2.5)
                while ((Get-Date) -lt $end) {
                    try { $d = $sp.ReadExisting() } catch { $d = '' }
                    if ($d) { [void]$sb.Append($d) }
                    if ($sb.ToString() -match 'ESP-ROM|rst:0x|cpu_start') { $booted = $true; break }
                    Start-Sleep -Milliseconds 80
                }
            } catch {}
            Out-Json @{ ok = $true; action = 'reset'; booted = $booted }
            exit 0
        }

        if ($Action -eq 'wakegif') {
            # reset (pulso RTS) e DEPOIS navega ate o app de GIF, garantindo que apos o
            # reboot a tela volte mostrando o GIF (e nao relogio/clima/etc).
            $sp.RtsEnable = $true
            Start-Sleep -Milliseconds 200
            $sp.RtsEnable = $false
            if ($sp.IsOpen) { $sp.Close() }
            $sp.Dispose(); $sp = $null
            Start-Sleep -Seconds 7          # boot + re-enumeracao do USB

            # reabre (a porta some/volta durante o reset)
            for ($i = 0; $i -lt 12 -and -not $sp; $i++) {
                try { $sp = Open-Port $Port } catch { $sp = $null; Start-Sleep -Milliseconds 500 }
            }
            if (-not $sp) { Out-Json @{ ok = $false; action = 'wakegif'; error = 'porta nao voltou apos reset' }; exit 1 }
            Start-Sleep -Milliseconds 600
            [void]$sp.ReadExisting()

            # helper de leitura (le por N ms, devolve texto limpo)
            $readFor = {
                param($ms)
                $b = New-Object System.Text.StringBuilder
                $stop = (Get-Date).AddMilliseconds($ms)
                while ((Get-Date) -lt $stop) {
                    try { $x = $sp.ReadExisting() } catch { $x = '' }
                    if ($x) { [void]$b.Append($x) }
                    Start-Sleep -Milliseconds 80
                }
                return (Strip-Ansi $b.ToString())
            }

            $onGif = $false; $info = $null
            # ja esta no GIF? (o app de GIF loga "Rolling"/"Playing" periodicamente)
            $pre = & $readFor 3200
            if ($pre -match 'GIF: (Playing|Rolling)') { $onGif = $true; $info = 'GIF' }

            # senao, troca de feature ate cair no GIF (lista pequena de apps)
            if (-not $onGif) {
                for ($k = 0; $k -lt 7; $k++) {
                    $sp.Write([string][char]96)     # crase = proxima feature
                    $clean = & $readFor 1500
                    if ($clean -match 'GIF: (Playing|Rolling)') { $onGif = $true; $info = 'GIF'; break }
                    $mm = [regex]::Matches($clean, 'Switch to (\d+)')
                    if ($mm.Count -gt 0) { $info = 'app ' + $mm[$mm.Count - 1].Groups[1].Value }
                }
            }
            Out-Json @{ ok = $true; action = 'wakegif'; onGif = $onGif; info = $info }
            exit 0
        }

        if ($Action -eq 'switch') {
            # crase = troca de app/feature na tela (GIF, relogio, clima, APS, QR/WiFi...)
            $sp.Write([string][char]96)
            $sb  = New-Object System.Text.StringBuilder
            $end = (Get-Date).AddMilliseconds(1300)
            while ((Get-Date) -lt $end) {
                try { $d = $sp.ReadExisting() } catch { $d = '' }
                if ($d) { [void]$sb.Append($d) }
                Start-Sleep -Milliseconds 80
            }
            $clean = Strip-Ansi $sb.ToString()
            $info = $null
            $mm = [regex]::Matches($clean, 'Switch to (\d+)')
            if ($mm.Count -gt 0) { $info = 'app ' + $mm[$mm.Count - 1].Groups[1].Value }
            if ($clean -match 'GIF: Playing') { $info = 'GIF' }
            Out-Json @{ ok = $true; action = 'switch'; info = $info }
            exit 0
        }

        # ---- force ----
        foreach ($ch in $Keys.ToCharArray()) {
            $sp.Write([string]$ch)
            Start-Sleep -Milliseconds 700
        }

        # le o log por ate ReadSeconds, parando assim que achar um IP de LAN
        $sb  = New-Object System.Text.StringBuilder
        $ip  = $null
        $end = (Get-Date).AddSeconds($ReadSeconds)
        $rxLan = '(?<![\d.])(?:192\.168\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(?![\d.])'
        while ((Get-Date) -lt $end) {
            try { $d = $sp.ReadExisting() } catch { $d = '' }
            if ($d) { [void]$sb.Append($d) }
            $clean = Strip-Ansi $sb.ToString()
            # prioriza linha de "sta ip"/"got ip"; senao qualquer IP de LAN != .4.1 (AP)
            $m = [regex]::Match($clean, 'sta ip:\s*(' + $rxLan + ')', 'IgnoreCase')
            if (-not $m.Success) { $m = [regex]::Match($clean, 'got ip:?\s*(' + $rxLan + ')', 'IgnoreCase') }
            if ($m.Success) { $ip = $m.Groups[1].Value; break }
            $any = [regex]::Match($clean, $rxLan)
            if ($any.Success -and $any.Value -ne '192.168.4.1') { $ip = $any.Value; break }
            Start-Sleep -Milliseconds 120
        }
        $tail = Strip-Ansi $sb.ToString()
        if ($tail.Length -gt 1200) { $tail = $tail.Substring($tail.Length - 1200) }
        Out-Json @{ ok = $true; action = 'force'; ip = $ip; log = $tail }
        exit 0
    }
    finally {
        if ($sp -and $sp.IsOpen) { $sp.Close() }
        if ($sp) { $sp.Dispose() }
    }
}
catch {
    Out-Json @{ ok = $false; error = $_.Exception.Message; action = $Action; port = $Port }
    exit 1
}
