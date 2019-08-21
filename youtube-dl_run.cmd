@echo off

:: Handle procedure calls
set __self=%0
if (%1)==(:) if not (%2)==() shift & shift & goto %2

:: Config
set l_ytd_exe=youtube-dl.exe
:: - Default paths & other values
set l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin
set l_default_vidh=
:: - Query phrases
set "l_query_url=Enter or paste the URL here: "
set "l_query_filebase=Enter the filename (without extension): "
set "l_query_vidh=Preferred height to download (default: %l_default_vidh%): "

:: Add parent folder to system paths
set path=%path%;%cd%
:: Navigate to output path
pushd "%l_output_path%"

:: Start download process
set /p "l_url=%l_query_url%"
echo:
set /p "l_filebase=%l_query_filebase%"
echo:
if "%l_filebase%"=="" %l_ytd_exe% -F "%l_url%"&pause&goto cleanup
set l_vidh=%l_default_vidh%
set /p "l_vidh=%l_query_vidh%"
echo:
if "%l_vidh%"=="" %l_ytd_exe% -o "%l_filebase%.%%(ext)s" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
if not "%l_vidh%"=="" %l_ytd_exe% -f "best[height=%l_vidh%][ext=mp4]+bestaudio" -o "%l_filebase%.%%(ext)s" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
echo:
pause

:cleanup
popd
set l_url=
set l_filebase=
set l_vidh=
set l_default_vidh=
set l_ytd_exe=
set l_ffmpeg_path=
set l_query_url=
set l_query_filebase=
set l_query_vidh=

goto :EOF
