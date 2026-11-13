@echo off
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Gerar-Projeto.ps1"
set "VAMP_BUILD_RESULT=%ERRORLEVEL%"
if "%VAMP_BUILD_RESULT%"=="0" (
    echo.
    echo Jogo atualizado. Reabra Luar de Cinzas.rbxlx no Roblox Studio e pressione F5.
) else (
    echo.
    echo Falha ao atualizar o jogo. Confira a mensagem acima.
)
pause
exit /b %VAMP_BUILD_RESULT%
