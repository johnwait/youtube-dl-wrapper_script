@if (@X)==(@Y) @end /* Exclude batch code from JScript
@echo off

:: Handle procedure calls
set __self=%~nx0
set "__selfAbs=%~f0"
if (%~1)==(:) if not (%~2)==() shift & shift & goto %~2

:: Enable delayed expansion *after* handling procedure calls
setlocal EnableDelayedExpansion

:: Execution flags:
:: - DEBUG: When set, prevents the script from deleting the compiled executable
::          (which then becomes available from further analysis or tests)
:: - SAFETY: When set, prevents the script from reusing the compiled executable
::           generated from a previous run; notably, by doing that we forgo the
::           (unsafe) assumption that an executable with an identical name is
::           necessarily one we previously compiled. In doubt, leave it set.
set DEBUG=1
set SAFEMODE=1

:: Config
::  - Working directory, if any (leave blank to use the script's directory)
set "l_workdir="
::  - youtube-dl binary
set "l_ytdl_dir=%cd%"
set "l_ytdl_exe=youtube-dl.exe"
::  - Path to ffmpeg.exe; change accordingly
set "l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin"
::  - JScript.NET build
set l_exe_name=__ytdl_saveas
set l_exe_path=%tmp%
set l_exe=%l_exe_path%\%l_exe_name%.exe
:: - File for temporary storing format defs
set "l_fmtdump_file=__ytdl_formats.txt"
set "l_fmtdump_path=%tmp%"
set "l_fmtdump=%l_fmtdump_path%\%l_fmtdump_file%"

:: Localized strings (12x)
::  - Script's name
set "LC_SCRIPT_NAME_en=YouTube Video Downloader Script"
set "LC_SCRIPT_NAME_fr=Script de t‚l‚chargement de vid‚os YouTube"
::  - Query for the video URL
set "LC_QUERY_URL_en=Enter or paste the YouTube/video URL here: "
set "LC_QUERY_URL_fr=Veuillez taper ou d‚poser ici le lien vers la vid‚o : "
::  - Loading video details
set "LC_DETAILS_DOWNLOAD_en=Retrieving video details..."
set "LC_DETAILS_DOWNLOAD_fr=R‚cup‚ration des d‚tails de la vid‚o ..."
::  - "Done", used after each successful step
set "LC_STEP_DONE_en=... done"
set "LC_STEP_DONE_fr=... ‚tape accomplie."
::   NOTE: In French & German (and others), word might have a grammatical gender;
::         as such, for French at least and as visible above, we reuse the same
::         nominal group to ensure the qualifier always agree in gender with
::         the qualified noun, instead of the step's action noun/nominal group.
::  - Title of the video / for the URL
set "LC_VIDEO_TITLE_en=Title: "
set "LC_VIDEO_TITLE_fr=Titre de la vid‚o : "
::  - List of available formats
set "LC_AVAIL_FORMATS_en=Available formats:"
set "LC_AVAIL_FORMATS_fr=Formats disponibles :"
::  - Cancel option among listed formats
set "LC_OPTION_CANCEL_en=  Q) Cancel and exit"
set "LC_OPTION_CANCEL_fr=  Q) Annuler et quitter"
::  - For showing the chosen video format (which follows immediately)
set "LC_CHOSEN_FORMAT_en=- Format chosen: "
set "LC_CHOSEN_FORMAT_fr=- Format choisi : "
::  - For showing the filename under which the video will be saved
set "LC_OUTPUT_FILENAME_en=- Output filename: "
set "LC_OUTPUT_FILENAME_fr=- Nom du fichier vid‚o : "
::  - Downloading started
set "LC_DOWNLOAD_STARTED_en=Downloading..."
set "LC_DOWNLOAD_STARTED_fr=T‚l‚chargement en cours ..."
::  - Script completed
set "LC_SCRIPT_COMPLETED_en=Script completed."
set "LC_SCRIPT_COMPLETED_fr=Script termin‚."
::  - Script aborted
set "LC_SCRIPT_ABORTED_en=Script aborted."
set "LC_SCRIPT_ABORTED_fr=Script interrompu."

:: Extract user's locale
for /f "tokens=3* delims=	 " %%a in ('REG QUERY "HKEY_CURRENT_USER\Control Panel\Desktop" /v "PreferredUILanguages" ^| find /i "PreferredUILanguages"') do set l_ui_locale=%%a
for /f "tokens=1,2* delims=-" %%a in ("%l_ui_locale%") do set l_ui_locale_lang=%%a& set l_ui_locale_country=%%b
set l_script_lang=%l_ui_locale_lang%
:: Revert to default if not supported
if not "%l_script_lang%"=="en" if not "%l_script_lang%"=="fr" set l_script_lang=en

:: Expand localized strings
call "%__selfAbs%" : :proc_expand_lcstrs

:: Set up our workspace
set "l_run_path=%cd%"
set "path=%path%;%l_run_path%"
if "%l_workdir%"=="" set "l_workdir=%l_run_path%"
:: We want to be working within the TMP folder
:: => in case we end up with leftover files
pushd "%tmp%"
:: Get codepage of console I/O
for /F "tokens=1,2 delims=:" %%a in ('chcp') do set /A l_cmd_cp=%%b>nul

:: Header
echo:%LC_SCRIPT_NAME%
echo:

:: Handle arguments passed from the command line, if any
if not "%~1"=="" (
    set "l_url=%~1"
    if "!l_url:~0,24!"=="https://www.youtube.com/" goto got_url
    if "!l_url:~0,23!"=="http://www.youtube.com/" goto got_url
    if "!l_url:~0,17!"=="https://youtu.be/" goto got_url
    if "!l_url:~0,16!"=="http://youtu.be/" goto got_url
)

:: Query for an URL if none provided
set /p "l_url=%LC_QUERY_URL%"
echo:

:got_url
:: Retrieve title and formats
echo:%LC_DETAILS_DOWNLOAD%
set l_title=
for /F "tokens=*" %%a in ('%l_ytdl_exe% -e "%l_url%"') do set l_title=%%a
set l_formats=
%l_ytdl_exe% -F "%l_url%">"%l_fmtdump%" 2>nul
echo:... done
echo:
echo:Processing formats list...
set l_formats_count=0
for /F "tokens=1,2,3,4,5,6,* delims=," %%a in ('type "%l_fmtdump%"^|find "mp4"') do (
    :: Trim values
    set l_format_spec=%%a
    call "%__selfAbs%" : proc_trim l_format_spec
    set l_format_size=%%e
    call "%__selfAbs%" : proc_trim l_format_size
    :: Join together and further process format spec
    set l_format=!l_format_spec!  !l_format_size!
    call "%__selfAbs%" : proc_parse_format l_format ;
    if not [!l_formats!]==[] set l_formats=!l_formats!,
    set l_formats=!l_formats!!l_format!
)
set l_format_size=
set l_format_spec=
set l_format=
echo:%LC_STEP_DONE%
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
echo:%LC_VIDEO_TITLE%%l_title%
echo:
echo:%LC_AVAIL_FORMATS%
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
    for /F "tokens=1,2,3,4,5,6 delims=;" %%a in ("!l_format_%%z!") do set l_format_%%z_id=%%f&set l_format_%%z_key=%%c&echo:  !l_choice!^) %%c  ^(%%b @ %%d/s; size: %%e+audio^)
    set l_choices=!l_choices!!l_choice!
)
echo:  --
echo:%LC_OPTION_CANCEL%
echo:
set l_format_chosen=
set /A l_quit_idx=%l_formats_count%+1
choice /C %l_choices%Q /N /M "Choose which format to download [1-%l_formats_count%,Q]: "
if ERRORLEVEL %l_quit_idx% goto canceled
for /l %%c in (%l_formats_count%,-1,1) do if ERRORLEVEL %%c set l_format_chosen=!l_format_%%c!&set l_format_chosen_id=!l_format_%%c_id!&set l_format_chosen_key=!l_format_%%c_key!
echo:%LC_CHOSEN_FORMAT%%l_format_chosen_key%

:: Asking user for an output filename through our JScript.NET-compiled executable
:: - Set JScript.NET environment
for /f "tokens=* delims=" %%v in ('dir /b /s /a:-d  /o:-n "%SystemRoot%\Microsoft.NET\Framework\*jsc.exe"') do (
   set "l_jsc=%%v"
)
:: - Recompile .NET executable
if not exist "%l_exe%" (
    "%l_jsc%" /nologo /out:"%l_exe%" "%~dpsfnx0"
)
:: - Choose a default filename based on the video's title
set "l_filename=%l_title%_%l_format_chosen_key%.mp4"
:: - Execute the utility and store the filename chosen
set l_output=
for /F "tokens=* delims=" %%a in ('"%l_exe%" -dcp %l_cmd_cp% -f "%l_filename%" -p "%l_workdir%"') do set "l_output=%%a"
:: - Delete executable (unless in DEBUG mode)
if not [%DEBUG%]==[] del /f /q "%l_exe%"

:: Make sure user didn't cancel
if "%l_output%"=="" goto canceled
if "%l_output%"=="*" goto canceled

echo:%LC_OUTPUT_FILENAME%"%l_output%"
echo:

:: Execute youtube-dl.exe
echo:%LC_DOWNLOAD_STARTED%
echo:---
if "%l_format_chosen_id%"=="" (
    %l_ytdl_exe% -f "best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
) else (
    %l_ytdl_exe% -f "%l_format_chosen_id%+bestaudio/best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" --ffmpeg-location "%l_ffmpeg_path%" "%l_url%"
)
echo:---
echo:done.
echo:
echo:%LC_SCRIPT_COMPLETED%
echo:
goto footer

:canceled
echo:
echo:%LC_SCRIPT_ABORTED%
echo:
goto footer

:footer
:: Come back to original folder
popd
pause
goto cleanup

:cleanup
set __self=
set __selfAbs=
set DEBUG=
set SAFEMODE=
set l_workdir=
set l_ytdl_dir=
set l_ytdl_exe=
set l_ffmpeg_path=
set l_exe_name=
set l_exe_path=
set l_exe=
set l_fmtdump_file
set l_fmtdump_path=
set l_fmtdump=
set LC_SCRIPT_NAME_en=
set LC_SCRIPT_NAME_fr=
set LC_QUERY_URL_en=
set LC_QUERY_URL_fr=
set LC_DETAILS_DOWNLOAD_en=
set LC_DETAILS_DOWNLOAD_fr=
set LC_STEP_DONE_en=
set LC_STEP_DONE_fr=
set LC_VIDEO_TITLE_en=
set LC_VIDEO_TITLE_fr=
set LC_AVAIL_FORMATS_en=
set LC_AVAIL_FORMATS_fr=
set LC_OPTION_CANCEL_en=
set LC_OPTION_CANCEL_fr=
set LC_CHOSEN_FORMAT_en=
set LC_CHOSEN_FORMAT_en=
set LC_OUTPUT_FILENAME_en=
set LC_OUTPUT_FILENAME_fr=
set LC_DOWNLOAD_STARTED_en=
set LC_DOWNLOAD_STARTED_fr=
set LC_SCRIPT_COMPLETED_en=
set LC_SCRIPT_COMPLETED_fr=
set LC_SCRIPT_ABORTED_en=
set LC_SCRIPT_ABORTED_fr=
set l_ui_locale=
set l_ui_locale_lang=
set l_ui_locale_country=
set l_script_lang=
set l_run_path=
set l_cmd_cp=
set l_url=
set l_title=
set l_formats=
REM set l_format_spec=
REM set l_format_size=
REM set l_format=
set l_cntr=
set l_formats_remain=
for /L %%z in (1,1,%l_formats_count%) do set l_format_%%z=&set l_format_%%z_key=&set l_format_%%z_id=
set l_formats_count=
set l_choices=
set l_choice=
set l_format_chosen=
set l_quit_idx=
set l_format_chosen_id=
set l_format_chosen_key=
set l_jsc=
set l_filename=
set l_output=
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
set l_sep=
set l_value=
set l_return=
set l_item=
:: Exit procedure
goto :EOF

:proc_expand_lcstrs
:: Go through LC_* vars and keep the ones corresponding to script lang
for /F "tokens=1,2* delims==" %%a in ('set LC_') do (
    set "l_varname=%%a"
    if "!l_varname:~-2!"=="%l_script_lang%" set "!l_varname:~0,-3!=%%b"
)
:: Exit procedure
goto :EOF

*/

import System;
import System.Text;
import System.Text.RegularExpressions;
import System.IO;
import System.Windows.Forms;

const DEFAULT_TITLE : String = "Save output video file";
const DEFAULT_FILENAME : String = "video.mp4";

function decodeCodePage(text, codePage) {
    switch(codePage) {
        case '437':
        case '500':
        case '737':
        case '775':
        case '850':
        case '852':
        case '855':
        case '857':
        case '860':
        case '861':
        case '863':
        case '864':
        case '865':
        case '869':
        case '870':
            codePage = 'IBM' + codePage;
            break;
        case '708':
            codePage = 'ASMO-' + codePage;
            break;
        case '720':
        case '862':
            codePage = 'DOS-' + codePage;
            break;
        case '858':
            codePage = 'IBM00' + codePage;
            break;
        case '874':
        case '1250':
        case '1251':
        case '1252':
        case '1253':
        case '1254':
        case '1255':
        case '1256':
        case '1257':
        case '1258':
            codePage = 'windows-' + codePage;
            break;
        case '866':
        case '875':
            codePage = 'cp' + codePage;
            break;
        case '932':
            codePage = 'shift_jis';
            break;
        case '936':
            codePage = 'gb2312';
            break;
        case '949':
            codePage = 'ks_c_5601-1987';
            break;
        case '950':
            codePage = 'ks_c_5601-1987';
            break;
        case '1200':
            codePage = 'utf-16';
            break;
        case '1201':
            codePage = 'unicodeFFFE';
            break;
        case '12000':
            codePage = 'utf-32';
            break;
        case '12001':
            codePage = 'utf-32BE';
            break;
        case '20127':
            codePage = 'us-ascii';
            break;
        case '28591': // Western European (ISO)       
            codePage = 'iso-8859-1';
            break;
        case '28592': // Central European (ISO)       
            codePage = 'iso-8859-2';
            break;
        case '28593': // Latin 3 (ISO)                
            codePage = 'iso-8859-3';
            break;
        case '28594': // Baltic (ISO)                 
            codePage = 'iso-8859-4';
            break;
        case '28595': // Cyrillic (ISO)               
            codePage = 'iso-8859-5';
            break;
        case '28596': // Arabic (ISO)                 
            codePage = 'iso-8859-6';
            break;
        case '28597': // Greek (ISO)                  
            codePage = 'iso-8859-7';
            break;
        case '28598': // Hebrew (ISO-Visual)          
            codePage = 'iso-8859-8';
            break;
        case '28599': // Turkish (ISO)                
            codePage = 'iso-8859-9';
            break;
        case '28603': // Estonian (ISO)               
            codePage = 'iso-8859-13';
            break;
        case '28605': // Latin 9 (ISO)                
            codePage = 'iso-8859-15';
            break;
        case '65000':
            codePage = 'utf-7';
            break;
        case '65001':
            codePage = 'utf-8';
            break;
    }
    var srcEnc : Encoding = Encoding.GetEncoding(codePage),
        win1252 : Encoding = Encoding.GetEncoding("Windows-1252"),
        srcEncBytes : byte[] = srcEnc.GetBytes(text);
    return win1252.GetString(srcEncBytes);
}

var curPath : String = Environment.CurrentDirectory,
    inputCP : String = "",
    title : String = DEFAULT_TITLE,
    path : String = "",
    filename : String = DEFAULT_FILENAME;

var arguments:String[] = Environment.GetCommandLineArgs();
for (var i=1; i<arguments.length; i++) {
    switch(arguments[i].toLowerCase()) {
        case '/dcp':
        case '/decode-cp':
        case '-dcp':
        case '--decode-cp':
            if (i+1 < arguments.length) {
                inputCP = arguments[i+1];
                i++;
            }
            break;
        case '/t':
        case '/title':
        case '-t':
        case '--title':
            if (i+1 < arguments.length) {
                title = arguments[i+1];
                i++;
            }
            break;
        case '/p':
        case '/path':
        case '-p':
        case '--path':
            if (i+1 < arguments.length) {
                path = arguments[i+1];
                i++;
            }
            break;
        case '/f':
        case '/filename':
        case '-f':
        case '--filename':
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

// decode title, filename and path strings from secified codepage
if (inputCP.length > 0) {
    title = decodeCodePage(title, inputCP);
    path = decodeCodePage(path, inputCP);
    filename = decodeCodePage(filename, inputCP);
}
// if a path was indeed specified, use it (replacing our default value)
if (path.length > 0) {
    curPath = path;
}

var saveFileDialog1:SaveFileDialog = new SaveFileDialog();

saveFileDialog1.InitialDirectory = curPath;
saveFileDialog1.Filter = "MP4 Video|*.mp4";
saveFileDialog1.Title = title;
saveFileDialog1.FileName = filename.replace(/[<>:"\/\\\|\?\*]/g, "_");
if (saveFileDialog1.ShowDialog() == DialogResult.OK) {
    // If the file name is not an empty string open it for saving.
    if (saveFileDialog1.FileName != "") {
        print (saveFileDialog1.FileName);
    }
}

// End of file "youtube-dl_run_v6.cmd"