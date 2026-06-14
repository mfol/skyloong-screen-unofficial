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

REM tenta python, depois py, depois node (http-server)
where python >nul 2>nul && ( python -m http.server %PORT% & goto :end )
where py     >nul 2>nul && ( py -m http.server %PORT%     & goto :end )
where npx    >nul 2>nul && ( npx --yes http-server -p %PORT% & goto :end )

echo  Nenhum servidor encontrado. Instale Python ou Node.js.
pause
:end
endlocal
