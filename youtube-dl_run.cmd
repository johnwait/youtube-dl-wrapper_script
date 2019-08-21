@if (@X)==(@Y) @end /* JScript comment
@echo off

:: Handle procedure calls
set __self=%~nx0
if (%1)==(:) if not (%2)==() shift & shift & goto %2

:: Enable delayed expansion *after* handling procedure calls
setlocal EnableDelayedExpansion

:: Config
set l_ytd_exe=youtube-dl.exe
:: - Default paths & other values
set l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin
:: - Query phrases
set "l_query_url=Enter or paste the URL here: "
:: - JScript.NET build
set l_exe_name=__ytd_saveas_helper
set l_exe_path=%tmp%
set l_exe=%l_exe_path%\%l_exe_name%.exe
set l_adsname=output_path.dat

:: Debug mode: recompile .NET/binary helper everytime
set DEBUG=1

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
for /F "tokens=1,2,3,* delims= " %%a in ('%l_ytd_exe% -F "%l_url%"^|find "mp4 "') do (
    :: Trim values
    set l_format_code=%%a
    set l_format_ext=%%b
    set l_format_res=%%c
    set l_format_note=%%d
    :: Further process format notes
    call %__self% : proc_parse_note l_format_note :
    :: Join together list of formats
    set l_format=!l_format_code!;!l_format_ext!;!l_format_res!;!l_format_note!
    if not [!l_formats!]==[] set l_formats=!l_formats!,
    set l_formats=!l_formats!!l_format!
)
set l_format_code=
set l_format_ext=
set l_format_res=
set l_format_note=
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
echo:
set l_choices=
set l_some_vidonly=no
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
    set l_format_note=
    set l_format_extra=
    for /F "tokens=1,2,3,4 delims=;" %%a in ("!l_format_%%z!") do (
        set l_format_%%z_code=%%a
        set l_format_%%z_ext=%%b
        set l_format_%%z_res=%%c
        set l_format_%%z_note=%%d
        if "%%d"=="" set l_format_%%z_note=
        set l_format_%%z_vidonly=no
        if not "!l_format_%%z_note!"=="" set "l_format_note=!l_format_%%z_note::video only:=:!"
        if not "!l_format_%%z_note!"=="" if not "!l_format_note!"=="!l_format_%%z_note!" set l_format_%%z_vidonly=yes
        if not "!l_format_note!"=="" set "l_format_note=!l_format_note::= !"
        if "!l_format_%%z_vidonly!"=="yes" set "l_format_extra=  *video only*"&set l_some_vidonly=yes
        if not "!l_format_note!"=="" echo:  !l_choice!^) !l_format_%%z_res!  ^(!l_format_%%z_ext!, !l_format_note!^)!l_format_extra!
        if "!l_format_note!"=="" echo:  !l_choice!^) !l_format_%%z_res!  ^(!l_format_%%z_ext!^)!l_format_extra!
    )
    set l_choices=!l_choices!!l_choice!
)
echo:  --
echo:  Q) Cancel
echo:
if "%l_some_vidonly%"=="yes" echo:  *NOTE: Video-only streams will be paired with best audio when downloaded&echo:
set l_format_chosen=
set /A l_quit_idx=%l_formats_count%+1
choice /C %l_choices%Q /N /M "Choose which format to download [1-%l_formats_count%,Q]: "
if ERRORLEVEL %l_quit_idx% goto canceled
for /l %%c in (%l_formats_count%,-1,1) do if ERRORLEVEL %%c (
    set l_format_chosen=!l_format_%%c!
    set l_format_chosen_code=!l_format_%%c_code!
    set l_format_chosen_ext=!l_format_%%c_ext!
    set l_format_chosen_res=!l_format_%%c_res!
    set l_format_chosen_note=!l_format_%%c_note!
    set l_format_chosen_vidonly=!l_format_%%c_vidonly!
)
if not "!l_format_chosen_note!"=="" echo:- Format chosen: %l_format_chosen_res% ^(%l_format_chosen_ext%, %l_format_chosen_note::= %^)
if "!l_format_chosen_note!"=="" echo:- Format chosen: %l_format_chosen_res% ^(%l_format_chosen_ext%^)

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
set "l_filename=%l_filename%_%l_format_chosen_res%.mp4"
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
REM "%l_ytd_exe%" -f "%l_format_chosen_id%+bestaudio/best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
set l_format_spec=%l_format_chosen_code%
if "%l_format_chosen_vidonly%"=="yes" set l_format_spec=%l_format_spec%+bestaudio
"%l_ytd_exe%" -f "%l_format_spec%/best[ext=mp4]/best" -o "%l_output%" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
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
set __self=
set l_ytd_exe=
set l_ffmpeg_path=
set l_query_url=
set l_exe_name=
set l_exe_path=
set l_exe=
set l_adsname=
set l_url=
set l_title=
set l_formats=
set l_format_code=
set l_format_ext=
set l_format_res=
set l_format_note=
set l_format=
set l_cntr=
set l_formats_remain=
for /L %%z in (1,1,%l_formats_count%) do set l_format_%%z=&set l_format_%%z_code=&set l_format_%%z_ext=&set l_format_%%z_res=&set l_format_%%z_note=&set l_format_%%z_vidonly=
set l_choices=
set l_some_vidonly=
set l_choice=
set l_format_extra=
set l_format_chosen=
set l_quit_idx=
set l_format_chosen_code=
set l_format_chosen_ext=
set l_format_chosen_res=
set l_format_chosen_note=
set l_format_chosen_vidonly=
set l_jsc=
set l_filename=
set l_output=
set l_format_spec=
set DEBUG=

goto :EOF

:: ----

:: Procedures

:proc_trim
set l_trim_target=%1
set l_trim_value=!%l_trim_target%!
:: Trim from left
for /f "tokens=* delims= " %%a in ("%l_trim_value%") do set l_trim_value=%%a
:: Trim from left
for /l %%a in (1,1,100) do if "!l_trim_value:~-1!"==" " set l_trim_value=!l_trim_value:~0,-1!
:: Update
set %l_trim_target%=%l_trim_value%
:: Cleanup
set l_trim_target=
set l_trim_value=
:: Exit procedure
goto :EOF

:proc_dedup_sp
set l_dedup_target=%1
set l_dedup_value=!%l_dedup_target%!
:: Trim from left
:dedup_loop
set "l_dedup_prev=%l_dedup_value%"
set l_dedup_value=%l_dedup_value:  = %
if not "%l_dedup_prev%"=="%l_dedup_value%" goto dedup_loop
:: Update
set %l_dedup_target%=%l_dedup_value%
:: Cleanup
set l_dedup_target=
set l_dedup_value=
set l_dedup_prev=
:: Exit procedure
goto :EOF

:proc_parse_note
set l_parse_target=%1
set l_sep_in=,
set l_sep_out=%3
if [%l_sep_out%]==[] set l_sep_out=:
set l_parse_value=!%l_parse_target%!
set l_return=
for /f "tokens=1,2,3,4,5 delims=%l_sep_in%" %%a in ("%l_parse_value%") do (
    set l_item=
    set l_item_a=%%a
    if not "!l_item_a!"=="" call %__self% : proc_trim l_item_a
    if not "!l_item_a!"=="" call %__self% : proc_dedup_sp l_item_a
    if not "!l_item_a!"=="" set l_item=!l_item!%l_sep_out%!l_item_a!
    set l_item_b=%%b
    if not "!l_item_b!"=="" call %__self% : proc_trim l_item_b
    if not "!l_item_b!"=="" call %__self% : proc_dedup_sp l_item_b
    if not "!l_item_b!"=="" set l_item=!l_item!%l_sep_out%!l_item_b!
    set l_item_c=%%c
    if not "!l_item_c!"=="" call %__self% : proc_trim l_item_c
    if not "!l_item_c!"=="" call %__self% : proc_dedup_sp l_item_c
    if not "!l_item_c!"=="" set l_item=!l_item!%l_sep_out%!l_item_c!
    set l_item_d=%%d
    if not "!l_item_d!"=="" call %__self% : proc_trim l_item_d
    if not "!l_item_d!"=="" call %__self% : proc_dedup_sp l_item_d
    if not "!l_item_d!"=="" set l_item=!l_item!%l_sep_out%!l_item_d!
    set l_item_e=%%e
    if not "!l_item_e!"=="" call %__self% : proc_trim l_item_e
    if not "!l_item_e!"=="" call %__self% : proc_dedup_sp l_item_e
    if not "!l_item_e!"=="" set l_item=!l_item!%l_sep_out%!l_item_e!
    if "!l_item:~0,1!"=="%l_sep_out%" set l_item=!l_item:~1!
    if not [!l_return!]==[] set l_return=!l_return!;
    set l_return=!l_return!!l_item!
)
:: Update
set %l_parse_target%=%l_return%
:: Cleanup
set l_parse_target=
set l_sep_in=
set l_sep_out=
set l_parse_value=
set l_return=
set l_item_a=
set l_item_b=
set l_item_c=
set l_item_d=
set l_item_e=
set l_item=
:: Exit procedure
goto :EOF

*/

import System;
import System.IO;
import System.Windows.Forms;
import System.Text.RegularExpressions;

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

// clean filename
var regexSearch : String = new String(Path.GetInvalidFileNameChars()) + new String(Path.GetInvalidPathChars()),
    r = new Regex(String.Format("[{0}]", Regex.Escape(regexSearch)));

filename = r.Replace(filename, "");

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