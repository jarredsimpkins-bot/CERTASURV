@echo off
setlocal
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "URL=https://raw.githubusercontent.com/jarredsimpkins-bot/CERTASURV/main/bootstrap/CertaNode-Legacy-Handoff.ps1"
set "ROOT=%ProgramData%\CertaSurv\NodeOffload"
set "SCRIPT=%ROOT%\CertaNode-Legacy-Handoff.ps1"
if not exist "%ROOT%" mkdir "%ROOT%"
echo [CertaSurv] Downloading latest curated multi-USB offload script...
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%SCRIPT%'"
if errorlevel 1 (
  echo [CertaSurv] Download failed.
  pause
  exit /b 1
)
echo [CertaSurv] Starting node offload. Live runtime/CAD data is protected.
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
echo [CertaSurv] Offload command finished. Review each USB's CERTASURV_SERVER_HANDOFF\99_LOGS folder.
pause
endlocal
