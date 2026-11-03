@echo off
setlocal
cd /d "%~dp0"
echo ==========================================
echo   FRIDA Android v1.4 - Persiapan Proyek
echo ==========================================
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js belum terpasang. Instal Node.js LTS terbaru terlebih dahulu.
  pause
  exit /b 1
)
where npm >nul 2>nul
if errorlevel 1 (
  echo npm tidak ditemukan. Periksa instalasi Node.js.
  pause
  exit /b 1
)
echo.
echo Versi Node:
node --version
echo.
echo [1/3] Mengunduh dependensi Capacitor...
call npm install
if errorlevel 1 goto gagal
if not exist android (
  echo.
  echo [2/3] Membuat proyek Android...
  call npx cap add android
  if errorlevel 1 goto gagal
) else (
  echo.
  echo Folder android sudah ada, dilewati.
)
echo.
echo [3/3] Sinkronisasi aplikasi...
call npx cap sync android
if errorlevel 1 goto gagal
echo.
echo SELESAI. Buka Android Studio dan pilih folder:
echo %CD%\android
echo.
pause
exit /b 0
:gagal
echo.
echo Proses gagal. Salin pesan error untuk diperiksa.
pause
exit /b 1
