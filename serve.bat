@echo off
REM ============================================================
REM  SKYLOONG 4.0 Console - servidor local
REM  Abrir por http:// evita os bloqueios do file:// (worker,
REM  import de modulo cross-origin). Du-plo clique para rodar.
REM ============================================================
setlocal
cd /d "%~dp0"
set PORT=8000
set URL=http://localhost:%PORT%/skyloong-ui.html

echo.
echo  SKYLOONG 4.0 Console
echo  -------------------------------------------
echo  Servindo em: %URL%
echo  (feche esta janela para parar o servidor)
echo.

REM abre o navegador na pagina ja servida
start "" "%URL%"

REM Preferir server.py (Python) -> habilita o banco SQLite de thumbnails/apelidos.
where python >nul 2>nul && ( python "%~dp0server.py" & goto :end )
where py     >nul 2>nul && ( py "%~dp0server.py"     & goto :end )

REM Sem Python: cai para servidor estatico simples (sem banco; usa cache do navegador).
echo  Python nao encontrado: rodando sem banco SQLite (thumbnails ficam so no navegador).
where npx    >nul 2>nul && ( npx --yes http-server -p %PORT% & goto :end )

echo  Nenhum servidor encontrado. Instale Python (recomendado) ou Node.js.
pause
:end
endlocal
