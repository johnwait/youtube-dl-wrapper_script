@echo off

:: Handle procedure calls
set __self=%0
if (%1)==(:) if not (%2)==() shift & shift & goto %2

:: Config
:: - Default values, peths, etc.
set l_default_vidh=
set l_ytd_path=.
set l_ytd_exe=youtube-dl.exe
set l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin
:: - Query phrases
set "l_query_url=Enter or paste the URL here: "
set "l_query_filebase=Enter the filename (without extension): "
set "l_query_vidh=Preferred height to download (default: %l_vidh%): "

:: Set up workspace; we want to be working within the temporary folder in case
:: we finish with left-overs (undeleted part files, after cancelations, etc.)
if "%l_ytd_path%"=="" set "l_ytd_path=%cd%"
set path=%path%;%l_ytd_path%\%l_ytd_exe%
pushd "%tmp%"

:: Payload
set /p "l_url=%l_query_url%"
echo:
set /p "l_filebase=%l_query_filebase%"
echo:
set l_vidh=%l_default_vidh%
set /p "l_vidh=%l_query_vidh%"
echo:
if "%l_vidh%"=="" %l_ytd_exe% -o "%l_filebase%.%%(ext)s" --ffmpeg-location "%l_ffmpeg_path%" %l_url%
if not "%l_vidh%"=="" %l_ytd_exe% -f "best[height=%l_vidh%]" -o "%l_filebase%.%%(ext)s" --ffmpeg-location "%l_ffmpeg_path%" %l_url%
echo:
pause

:cleanup
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
