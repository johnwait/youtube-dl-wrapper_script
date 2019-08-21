@if (@X)==(@Y) @end /* JScript comment
@echo off

:: Handle procedure calls
set __self=%~nx0
if (%1)==(:) if not (%2)==() shift & shift & goto %2

:: Enable delayed expansion *after* handling procedure calls
setlocal EnableDelayedExpansion
set "l_newline=QMZ"
set l_newline=!l_newline:QMZ=^

!

:: Config
set l_ytd_exe=youtube-dl.exe
:: - Default paths & other values
set l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin
:: - Query phrases
set "l_query_url=Enter or paste the URL here: "
:: - JScript.NET build
set l_exe_name=__mp4_saveas
set l_exe_path=%tmp%
set l_exe=%l_exe_path%\%l_exe_name%.exe
set l_adsname=output_path.dat

:: Add parent folder to system paths
set path=%path%;%cd%

:: Header
echo:YouTube Video Downloader Script
echo:

:: Query params
set /p "l_url=%l_query_url%"
echo:

:: Retrieve title and formats
echo:Retrieving video details...
set l_title=
for /F "tokens=*" %%a in ('%l_ytd_exe% -e "%l_url%"') do set l_title=%%a
set l_formats=
for /F "tokens=1,2,3,4,5,6,* delims=," %%a in ('%l_ytd_exe% -F "%l_url%"^|find "mp4"^|find "video only"') do (
    :: Trim values
    set l_format_spec=%%a
    call %__self% : proc_trim l_format_spec
    set l_format_size=%%e
    call %__self% : proc_trim l_format_size
    :: Join together and further process format spec
    set l_format=!l_format_spec!  !l_format_size!
    call %__self% : proc_parse_format l_format ;
    if not [!l_formats!]==[] set l_formats=!l_formats!,
    set l_formats=!l_formats!!l_format!
)
set l_format_size=
set l_format_spec=
set l_format=
echo:... done
echo:

:: Further parse video formats
set l_cntr=1
set "l_formats_remain=%l_formats%"
:fmt_loop
for /F "tokens=1,* delims=," %%a in ("%l_formats_remain%") do set l_format_%l_cntr%=%%a&set /A l_cntr=%l_cntr%+1&set l_formats_remain=%%b
if not "%l_formats_remain%"=="" goto fmt_loop
set /A l_formats_count=%l_cntr%-1
:: Limit formats to 25
if %l_formats_count% GTR 25 set l_formats_count=25
:: Display title and formats available
echo:Title: %l_title%
echo:
echo:Available formats:
set l_choices=
for /L %%z in (1,1,%l_formats_count%) do (
    set l_choice=%%z
    if "!l_choice!"=="10" set l_choice=A
    if "!l_choice!"=="11" set l_choice=B
    if "!l_choice!"=="12" set l_choice=C
    if "!l_choice!"=="13" set l_choice=D
    if "!l_choice!"=="14" set l_choice=E
    if "!l_choice!"=="15" set l_choice=F
    if "!l_choice!"=="16" set l_choice=G
    if "!l_choice!"=="17" set l_choice=H
    if "!l_choice!"=="18" set l_choice=I
    if "!l_choice!"=="19" set l_choice=J
    if "!l_choice!"=="20" set l_choice=K
    if "!l_choice!"=="21" set l_choice=L
    if "!l_choice!"=="22" set l_choice=M
    if "!l_choice!"=="23" set l_choice=N
    if "!l_choice!"=="24" set l_choice=O
    if "!l_choice!"=="25" set l_choice=P
    for /F "tokens=1,2,3,4,5,6 delims=;" %%a in ("!l_format_%%z!") do set l_format_%%z_id=%%f&set l_format_%%z_key=%%c&echo:  !l_choice!^) %%c  ^(%%b, %%d, %%e+audio^)
    set l_choices=!l_choices!!l_choice!
)
echo:  --
echo:  Q) Cancel
echo:
set l_format_chosen=
set /A l_quit_idx=%l_formats_count%+1
choice /C %l_choices%Q /N /M "Choose which format to download [1-%l_formats_count%,Q]: "
if ERRORLEVEL %l_quit_idx% goto canceled
for /l %%c in (%l_formats_count%,-1,1) do if ERRORLEVEL %%c set l_format_chosen=!l_format_%%c!&set l_format_chosen_id=!l_format_%%c_id!&set l_format_chosen_key=!l_format_%%c_key!
echo:- Format chosen: %l_format_chosen_key%

:: Asking for an output filename
:: - Set JScript.NET environment
for /f "tokens=* delims=" %%v in ('dir /b /s /a:-d  /o:-n "%SystemRoot%\Microsoft.NET\Framework\*jsc.exe"') do (
   set "l_jsc=%%v"
)
:: - Recompile .NET executable
if not exist "%l_exe%" (
    "%l_jsc%" /nologo /out:"%l_exe%" "%~dpsfnx0"
)
:: Preop proposed filename
set "l_filename=%l_title::=_%"
set "l_filename=%l_filename:/=_%"
set "l_filename=%l_filename:\=_%"
set "l_filename=%l_filename:|=_%"
set "l_filename=%l_filename:____=_%"
set "l_filename=%l_filename:___=_%"
set "l_filename=%l_filename:__=_%"
set "l_filename=%l_filename%_%l_format_chosen_key%.mp4"
:: - Execute it with a suggested filename
set l_output=
echo:*>%__self%:%l_adsname%
"%l_exe%" -f "%l_filename%">%__self%:%l_adsname%&set /p l_output=< %__self%:%l_adsname%
:: - Delete executable (DEBUG mode)
if not [%DEBUG%]==[] del /f /q "%l_exe%"

:: Make sure user didn't cancel
if "%l_output%"=="" goto canceled
if "%l_output%"=="*" goto canceled

echo:- Output filename: "%l_output%"
echo:

:: Execute youtube-dl.exe
echo:Downloading...
echo:---
"%l_ytd_exe%" -f "%l_format_chosen_id%+bestaudio/best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
echo:---
echo:done.
echo:
echo:Script completed.
echo:
pause
goto cleanup

:canceled
echo:
echo:Script aborted.
echo:
pause
goto cleanup

:cleanup
set l_adsname=
set l_choice=
set l_choices=
set l_cntr=
set l_exe_name=
set l_exe_path=
set l_exe=
set l_ffmpeg_path=
set l_filename=
for /L %%z in (1,1,%l_formats_count%) do set l_format_%%z=&set l_format_%%z_key=
set l_format_chosen_key=
set l_format_chosen=
set l_format_size=
set l_format_spec=
set l_format=
set l_formats_count=
set l_formats_remain=
set l_formats=
set l_item=
set l_newline=
set l_quit_idx=
set l_return=
set l_sep=
set l_target=
set l_title=
set l_value=
set l_ytd_exe=
set DEBUG=

goto :EOF

:: ----

:: Procedures

:proc_trim
set l_target=%1
set l_value=!%l_target%!
:: Trim from left
for /f "tokens=* delims= " %%a in ("%l_value%") do set l_value=%%a
:: Trim from left
for /l %%a in (1,1,100) do if "!l_value:~-1!"==" " set l_value=!l_value:~0,-1!
:: Update
set %l_target%=%l_value%
:: Cleanup
set l_target=
set l_value=
:: Exit procedure
goto :EOF

:proc_parse_format
set l_target=%1
set l_sep=%2
if [%l_sep%]==[] set l_sep=;
set l_value=!%l_target%!
set l_return=
for /f "tokens=1,2,3,4,5,6 delims= " %%a in ("%l_value%") do (
    set l_item=%%b;%%c;%%d;%%e;%%f;%%a
    if not [!l_return!]==[] set l_return=!l_return!,
    set l_return=!l_return!!l_item!
)
:: Update
set %l_target%=%l_return%
:: Cleanup
set l_target=
set l_value=
set l_return=
set l_item=
:: Exit procedure
goto :EOF

*/

import System;
import System.Windows.Forms;

const DEFAULT_TITLE : String = "Save output video file";
const DEFAULT_FILENAME : String = "video.mp4";

var curPath = Environment.CurrentDirectory,
    title = DEFAULT_TITLE,
    filename = DEFAULT_FILENAME;

var arguments:String[] = Environment.GetCommandLineArgs();
for (var i=1; i<arguments.length; i++) {
    switch(arguments[i]) {
        case '/title':
        case '/t':
        case '-title':
        case '-t':
            if (i+1 < arguments.length) {
                title = arguments[i+1];
                i++;
            }
            break;
        case '/filename':
        case '/f':
        case '-filename':
        case '-f':
            if (i+1 < arguments.length) {
                filename = arguments[i+1];
                i++;
            }
            break;
        default:
            print( "Unhandled switch: " + arguments[i] );
            Environment.Exit(1);
    }
}

var saveFileDialog1:SaveFileDialog = new SaveFileDialog();

saveFileDialog1.InitialDirectory = curPath;
saveFileDialog1.Filter = "MP4 Video|*.mp4";
saveFileDialog1.Title = title;
saveFileDialog1.FileName = filename;
if (saveFileDialog1.ShowDialog() == DialogResult.OK) {
    // If the file name is not an empty string open it for saving.
    if (saveFileDialog1.FileName != "") {
        print (saveFileDialog1.FileName);
    }
}

// End of file "jscript-dot-net_example.cmd"