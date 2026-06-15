<#
.SYNOPSIS
  Escuta (somente leitura) o console serial do ESP32-S3 da telinha SKYLOONG
  e grava tudo em reverse\com6.log.

.DESCRIPTION
  A telinha enumera como USB\VID_303A&PID_1001 (USB-Serial-JTAG embutido do
  ESP32-S3). Este script abre a porta SEM mexer em DTR/RTS para nao resetar o
  chip, e apenas LE o que chega. Nao envia nada, nao flasha nada.

  Para capturar o banner de boot: rode o script e, em seguida, desconecte e
  reconecte o cabo USB do teclado.

.EXAMPLE
  pwsh -File reverse\serial-listen.ps1
  pwsh -File reverse\serial-listen.ps1 -Port COM6 -Baud 115200
#>
[CmdletBinding()]
param(
    [string]$Port = 'COM6',
    [int]$Baud = 115200,
    [string]$LogFile = (Join-Path $PSScriptRoot 'com6.log')
)

$ErrorActionPreference = 'Stop'

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud, ([System.IO.Ports.Parity]::None), 8, ([System.IO.Ports.StopBits]::One)
# CRITICO: nao assertar DTR/RTS -> nao reseta o ESP32-S3 nem entra em download mode.
$sp.DtrEnable  = $false
$sp.RtsEnable  = $false
$sp.ReadTimeout = 500
$sp.NewLine = "`n"

Write-Host "Abrindo $Port @ $Baud (somente leitura, DTR/RTS off)..." -ForegroundColor Cyan
Write-Host "Log: $LogFile" -ForegroundColor DarkGray
Write-Host "Dica: desconecte/reconecte o USB para capturar o banner de boot." -ForegroundColor Yellow
Write-Host "Ctrl-C para parar.`n" -ForegroundColor DarkGray

try {
    $sp.Open()
}
catch {
    Write-Host "Falha ao abrir ${Port}: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "A porta pode estar em uso (feche o console do device/IDE) ou o nome mudou." -ForegroundColor Red
    exit 1
}

# Cabecalho com timestamp no log
$stamp = "`n===== sessao iniciada $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Port @ $Baud =====`n"
Add-Content -Path $LogFile -Value $stamp -Encoding UTF8

try {
    while ($true) {
        try {
            $data = $sp.ReadExisting()
        }
        catch [TimeoutException] {
            $data = ''
        }
        if ($data -and $data.Length -gt 0) {
            [Console]::Out.Write($data)
            Add-Content -Path $LogFile -Value $data -NoNewline -Encoding UTF8
        }
        else {
            Start-Sleep -Milliseconds 50
        }
    }
}
finally {
    if ($sp.IsOpen) { $sp.Close() }
    $sp.Dispose()
    Write-Host "`n$Port fechada." -ForegroundColor Cyan
}
