@if (@X)==(@Y) @end /* Exclude batch code from JScript
@echo off

:: --<license>-------------------------------------------------------------
::
:: Copyright © 2019-2020 Jonathan Richard-Brochu and contributors.
::
:: Permission is hereby granted, free of charge, to any person obtaining a
:: copy of this software and associated documentation files (the "Software"),
:: to deal in the Software without restriction, including without limitation
:: the rights to use, copy, modify, merge, publish, distribute, sublicense,
:: and/or sell copies of the Software, and to permit persons to whom the
:: Software is furnished to do so, subject to the following conditions:
::
:: 1. The above copyright notice and this permission notice shall be included
::    in all copies or substantial portions of the Software.
::
:: 2. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
::    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
::    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
::    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
::    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
::    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
::    OTHER DEALINGS IN THE SOFTWARE.
::
:: --</license>------------------------------------------------------------

:: History:
::
:: 2020-10-07:  The following changes were made:
:: (v9.4)       - (DEBUG) youtube-dl's --verbose flag is now always used, so
::                as to make failed runs easier to debug when they occur.
::              - Changed a few [if "%env_var%"==""] statements into their
::                less-runtime-error-prone [if not defined env_var] variant
::                (and eliminated them when both variants are used).
::              - Added support for extra FFMPEG (post-processing) command
::                line arguments.
::              - Renamed env. variable l_choice to l_choice_alpha to put
::                emphasis on the fact that it contains the alphanumeric
::                choice (pressed digit/letter for the stream option) of the
::                user, not the indexed equivalent of the same choice.
::              - Replace env. variable l_format_streams with l_chosen_streams,
::                the latter being set within the format selection loop.
::              - (DEBUG) The chosen format key(s) (a YouTube-generated stream
::                type ID) now gets shown in parentesis along with the user's
::                chosen stream(s).
::              - (DEBUG) The whole youtube-dl's command line is shown before
::                being run, to aid in debugging when it is needed.
:: 2019-11-08:  The following changes were made:
:: (v9.3)       - BUGFIX: Now showing the alphanumeric key for options instead
::                of their numeric index, as the former is really what the user
::                is expected to press for selecting a stream option.
::              - BUGFIX: Removed "N" in the list of possible stream choice
::                option keys since it's been previously reserved for skipping
::                the addition of a second, complementary stream to the first
::                one. At the same time, added "S" to the list of useable keys,
::                so that the maximum possible is still 26 choices.
:: 2019-10-14:  The following changes were made:
:: (v9.2)       - Improved support for dual stream downloads by remembering
::                properties of the first stream (key/ID, extension, quality).
::              - Now adapting the title of the Save-As dialog when downloading
::                audio-only streams.
::              - Added support for some debug verbosity for the JScript-based
::                compiled Save-As helper.
::              - Made some various optimizations to the compiled Save-As
::                helper.
:: 2019-09-30:  The following changes were made:
:: (v9.1)       - Added sanity checks to filter out invalid URLs while allowing
::                special options/verbs.
::              - Added option for triggering youtube-dl's self-update process.
:: 2019-08-25:  The following changes were made:
:: (v9.0)       - BUGFIX:Fixed bugs introduced following the reordering of code
::                blocks made in v7: (1) specifying a YouTube URL skipped the
::                clearing of command line arguments, and made script restarts
::                re-use the same URL everytime; and (2) when recompilation is
::                skipped, the bad GOTO destination caused an infinite loop.
::              - BUGFIX: For the compiled Save-As helper, fixed what value is
::                as the default (output) filename.
::              - Now only adding to the command line the path to the FFMPEG
::                binary if it is provided.
::              - Added more comments to the script.

:: Handle procedure calls
set __self=%~nx0
set "__selfAbs=%~f0"
if (%~1)==(:) if not (%~2)==() shift & shift & goto %~2

:: Since this script is being published, using the windows-1252 codepage
:: make editing the file easier (hopefully)
set l_cp_win_1252=1252
chcp %l_cp_win_1252% >nul 2>&1

:: Enable delayed expansion *after* handling procedure calls
setlocal EnableDelayedExpansion

:start
:: Execution flags:
:: - DEBUGEXE   When set, prevents the script from deleting the compiled
::              executable (which then becomes available from further
::              analysis or tests)
:: - SAFEMODE:  When set, prevents the script from reusing the compiled
::              executable generated from a previous run; notably, by
::              doing that we forgo the (unsafe) assumption that an
::              executable with an identical name is necessarily one we
::              previously compiled. In doubt, please leave this set.
:: - BATCHMODE: Whether to query, at the end of a video download, if the
::              script should be restarted to download another video
::              from a new URL.
set DEBUGEXE=1
set SAFEMODE=1
set BATCHMODE=1

:: Config
::  - Working directory, if any (leave blank to use the script's directory)
set "l_workdir="
::  - youtube-dl binary, as separate path and filename; change accordingly
set "l_ytdl_dir=%cd%"
set "l_ytdl_exe=youtube-dl.exe"
::  - additional flags for youtube-dl
set "l_ytdl_xtraflags=--verbose --youtube-skip-dash-manifest"
::  - Path to ffmpeg.exe, excluding the filename; change accordingly, e.g.
set "l_ffmpeg_path=C:\Program Files\ffmpeg-4.0.2-win64-static\bin"
set "l_ffmpeg_xargs="
::  - JScript.NET build
set l_exe_name=__ytdl_saveas
set l_exe_path=%tmp%
set l_exe=%l_exe_path%\%l_exe_name%.exe
:: - File for temporary storing format defs
set "l_fmtdump_file=__ytdl_formats.txt"
set "l_fmtdump_path=%tmp%"
set "l_fmtdump=%l_fmtdump_path%\%l_fmtdump_file%"

:: Localized strings
::  - Script's name
set "LC_SCRIPT_NAME_en=YouTube Video Downloader Script"
set "LC_SCRIPT_NAME_fr=Script de téléchargement de vidéos YouTube"
::  - Query for the video URL
set "LC_URL_QUERY_en=Enter or paste the YouTube/video URL here: "
set "LC_URL_QUERY_fr=Veuillez taper ou déposer ici le lien vers la vidéo : "
::  - URL validation
set "LC_INVALID_URL_en=** URL not valid"
set "LC_INVALID_URL_fr=** Adresse URL invalide"
::  - Option validation
set "LC_OPT_NOT_SUPPORTED_en=** Option not supported: "
set "LC_OPT_NOT_SUPPORTED_fr=** Option non prise en charge: "
::  - Option: Query youtube-dl version
set "LC_OPT_GET_VERSION_en=** Version of youtube-dl is: "
set "LC_OPT_GET_VERSION_fr=** La version actuelle de youtube-dl est : "
::  - Option: Trigger update of youtube-dl
set "LC_OPT_UPDATE_YTDL_en=Trying for the update of the the youtube-dl utility..."
set "LC_OPT_UPDATE_YTDL_fr=Début de la tentative de mise à jour de l'utilitaire youtube-dl ..."
::  - User must check whether youtube-dl update was a success
set "LC_CHECK_YTDL_UPDATE_en=Check result above, and press any key to continue..."
set "LC_CHECK_YTDL_UPDATE_fr=Vérifiez si le processus a réussi, et appuyer sur une touche pour continuer ..."
::  - "Done", used after each successful step
set "LC_STEP_DONE_en=... done"
set "LC_STEP_DONE_fr=... étape accomplie."
::   NOTE: In French & German (and others), word might have a grammatical gender;
::         as such, for French at least and as visible above, we reuse the same
::         nominal group to ensure the qualifier always agree in gender with
::         the qualified noun, instead of the step's action noun/nominal group.
::  - Loading video details
set "LC_STEP_DETAILS_DL_en=Retrieving video details..."
set "LC_STEP_DETAILS_DL_fr=Récupération des détails de la vidéo ..."
::  - Processing video formats
set "LC_STEP_PROC_FORMATS_en=Processing formats list..."
set "LC_STEP_PROC_FORMATS_fr=Traitement de la liste des formats disponibles ..."
::  - Title of the video / for the URL
set "LC_VIDEO_TITLE_en=Title: "
set "LC_VIDEO_TITLE_fr=Titre de la vidéo : "
::  - List of available formats
set "LC_AVAIL_FORMATS_en=Available formats:"
set "LC_AVAIL_FORMATS_fr=Formats disponibles :"
::  - Restart option among listed formats
set "LC_OPTION_TRYNEWURL_en=Retry with a new URL"
set "LC_OPTION_TRYNEWURL_fr=Réessayer avec un autre lien"
::  - Cancel option among listed formats
set "LC_OPTION_CANCEL_en=Cancel and exit"
set "LC_OPTION_CANCEL_fr=Annuler et quitter"
::  - Video format query prompt
set "LC_FORMAT_QUERY_en=Choose which format to download [1-??formatCount??,R,Q]: "
set "LC_FORMAT_QUERY_fr=Choisissez le format à télécharger [1-??formatCount??,R,Q] : "
::  - Format listings, video+audio
set "LC_FMT_LINE_VA_en=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s; res: ?$res??; size: ?$size??^)"
set "LC_FMT_LINE_VA_fr=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s ; résol. : ?$res?? ; taille : ?$size??^)"
::  - Format listings, video-only
set "LC_FMT_LINE_VO_en=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s+audio; res: ?$res??; size: ?$size??+audio^)"
set "LC_FMT_LINE_VO_fr=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s+audio ; résol. : ?$res?? ; taille : ?$size??+audio^)"
::  - Format listings, audio-only
set "LC_FMT_LINE_AO_en=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s+video; size: ?$size??+video^)"
set "LC_FMT_LINE_AO_fr=?$idx??^) ?$quality??  (?$ext?? @ ?$bitrate??/s+vidéo ; taille : ?$size??+vidéo^)"
::  - Format grouping, video+audio
set "LC_FMT_GROUP_VA_en=Combined ^^^(video+audio^^^)"
set "LC_FMT_GROUP_VA_fr=Combiné ^^^(vidéo+audio^^^)"
::  - Format grouping, video-only
set "LC_FMT_GROUP_VO_en=Video only"
set "LC_FMT_GROUP_VO_fr=Vidéo seulement"
::  - Format grouping, audio-only
set "LC_FMT_GROUP_AO_en=Audio only"
set "LC_FMT_GROUP_AO_fr=Audio seulement"
::  - Format grouping, additional choices
set "LC_FMT_GROUP_MORE_OPT_en=Additional options"
set "LC_FMT_GROUP_MORE_OPT_fr=Options additionnelles"
::  *** Template strings for the four ones coming right after
set "__vo_ao_dupe_en=\n \nYou also have the options [N]ot no have any ??type2?? stream, to [R]etry with\na new URL or [Q]uit the script [??choices??]: "
set "__vo_ao_dupe_fr=\n \nVous avez aussi comme options : [N]e pas ajouter de flux ??type2??, [R]éessayer\navec un autre lien ou encore [Q]uitter [??choices??] : "
set "__vo_ao_meta_en=ATTENTION: You've picked a ??type1??-only stream; please select among the list\n           of ??type2??-only streams one to be merged with the ??type1?? one.%__vo_ao_dupe_en%"
set "__vo_ao_meta_fr=ATTENTION : Vous avez choisi un format du type « ??type1?? seulement » ; veuillez\n            choisir parmi la liste des formats « ??type2?? seulement » un flux\n            ??type2?? à combiner avec le flux ??type1??.%__vo_ao_dupe_fr%"
::  - Video-only format chosen, pick an audio format
call set "LC_VO_CHOSEN_QUERY_AO_en=%%__vo_ao_meta_en:??type1??=video%%" & call set "LC_VO_CHOSEN_QUERY_AO_en=%%LC_VO_CHOSEN_QUERY_AO_en:??type2??=audio%%" & call set "LC_VO_CHOSEN_QUERY_AO_en=%%LC_VO_CHOSEN_QUERY_AO_en:a audio=an audio%%"
call set "LC_VO_CHOSEN_QUERY_AO_fr=%%__vo_ao_meta_fr:??type1??=vidéo%%" & call set "LC_VO_CHOSEN_QUERY_AO_fr=%%LC_VO_CHOSEN_QUERY_AO_fr:??type2??=audio%%"
::  - Audio-only format chosen, pick an video format
call set "LC_AO_CHOSEN_QUERY_VO_en=%%__vo_ao_meta_en:??type1??=audio%%" & call set "LC_AO_CHOSEN_QUERY_VO_en=%%LC_AO_CHOSEN_QUERY_VO_en:??type2??=video%%" & call set "LC_AO_CHOSEN_QUERY_VO_en=%%LC_AO_CHOSEN_QUERY_VO_en:a audio=an audio%%"
call set "LC_AO_CHOSEN_QUERY_VO_fr=%%__vo_ao_meta_fr:??type1??=audio%%" & call set "LC_AO_CHOSEN_QUERY_VO_fr=%%LC_AO_CHOSEN_QUERY_VO_fr:??type2??=vidéo%%"
::  *** Clean-up some template strings
set __vo_ao_dupe_en=
set __vo_ao_dupe_fr=
::  *** More template strings to avoid redundancy
set "__vo_ao_meta_en=No ??type1?? stream; download only the ??type2?? format as selected"
set "__vo_ao_meta_fr=Aucun flux ??type1?? ; ne télécharger que le format ??type2?? déjà sélectionné"
::  - No VO stream, only download+keep audio one
call set "LC_CHOICE_NO_VO_KEEP_AO_en=%%__vo_ao_meta_en:??type1??=video%%" & call set "LC_CHOICE_NO_VO_KEEP_AO_en=%%LC_CHOICE_NO_VO_KEEP_AO_en:??type2??=audio%%"
call set "LC_CHOICE_NO_VO_KEEP_AO_fr=%%__vo_ao_meta_fr:??type1??=vidéo%%" & call set "LC_CHOICE_NO_VO_KEEP_AO_fr=%%LC_CHOICE_NO_VO_KEEP_AO_fr:??type2??=audio%%"
::  - No AO stream, only download+keep video one
call set "LC_CHOICE_NO_AO_KEEP_VO_en=%%__vo_ao_meta_en:??type1??=audio%%" & call set "LC_CHOICE_NO_AO_KEEP_VO_en=%%LC_CHOICE_NO_AO_KEEP_VO_en:??type2??=video%%"
call set "LC_CHOICE_NO_AO_KEEP_VO_fr=%%__vo_ao_meta_fr:??type1??=audio%%" & call set "LC_CHOICE_NO_AO_KEEP_VO_fr=%%LC_CHOICE_NO_AO_KEEP_VO_fr:??type2??=vidéo%%"
::  *** Clean-up remaining template strings
set __vo_ao_dupe_en=
set __vo_ao_dupe_fr=
::  - For showing the chosen format (which follows immediately)
set "LC_CHOSEN_FORMAT_en=- Format chosen: "
set "LC_CHOSEN_FORMAT_fr=- Format choisi : "
::  - Formatting the format (sic) details when multiple streams are used
set "LC_CHOSEN_FORMAT_VOAO_DETAILS_en=Video: ??vo??; Audio: ??ao??"
set "LC_CHOSEN_FORMAT_VOAO_DETAILS_fr=Vidéo : ??vo?? ; Audio : ??ao??"
::  - Title for the Save-As dialog
set "LC_SAVEAS_DLG_TITLE_en=Location for saving the video file once downloaded"
set "LC_SAVEAS_DLG_TITLE_fr=Emplacement du fichier vidéo une fois téléchargé"
::  - For showing the filename under which the video will be saved
set "LC_OUTPUT_FILENAME_en=- Output filename: "
set "LC_OUTPUT_FILENAME_fr=- Nom du fichier vidéo : "
::  - Downloading started
set "LC_DOWNLOAD_STARTED_en=Downloading..."
set "LC_DOWNLOAD_STARTED_fr=Téléchargement en cours ..."
::  - Script restart
set "LC_SCRIPT_RESTART_QUERY_en=Do you wish to restart the script to process more video URLs? ([Y]es, [N]o): "
set "LC_SCRIPT_RESTART_QUERY_fr=Voulez-vous recommencer du début pour d'autres liens vidéos ? ([O]ui, [N]on) : "
set "LC_SCRIPT_RESTART_CHOICES_en=YN"
set "LC_SCRIPT_RESTART_CHOICES_fr=ON"
::  - Script completed
set "LC_SCRIPT_COMPLETED_en=Script completed."
set "LC_SCRIPT_COMPLETED_fr=Script terminé."
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
call "%__selfAbs%" : proc_expand_lcstrs

:: Set up our workspace
set "l_run_path=%l_ytdl_dir%"
set "path=%path%;%l_run_path%"
if not defined l_workdir set "l_workdir=%l_run_path%"
:: We want to be working within the TMP folder
:: => in case we end up with leftover files
pushd "%tmp%"

:: Get codepage of console I/O (normally: 850)
for /F "tokens=1,2 delims=:" %%a in ('chcp') do set /A l_cmd_cp=%%b>nul

:header
cls
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
:query_url
set l_url=
:: Query for an URL if none provided
set /p "l_url=%LC_URL_QUERY%"
:: Sanity checks
if not defined l_url goto query_url
:: Handle options
if "!l_url:~0,2!"=="--" (
    if /I "!l_url!"=="--update" goto opt_update
    if /I "!l_url!"=="--exit" goto canceled
    if /I "!l_url!"=="--version" (
        <nul set /p=%LC_OPT_GET_VERSION%
        "%l_ytdl_exe%" --version
        echo:
        goto query_url
    )
    echo:%LC_OPT_NOT_SUPPORTED%"%l_url%"
    goto query_url
)
if not "!l_url:~0,8!"=="https://" if not "!l_url:~0,7!"=="http://" echo:%LC_INVALID_URL%& goto query_url
echo:
goto got_url

:opt_update
echo:
echo:%LC_OPT_UPDATE_YTDL%
echo:
echo:--
call :proc_ytdl_upd
ping -w 5000 -n 1 192.0.0.8>nul
echo:--
echo:
<nul set /p=%LC_CHECK_YTDL_UPDATE%
pause>nul
goto header

:proc_ytdl_upd
"%l_ytdl_exe%" --update --verbose
exit /b
goto :EOF

:got_url

:: 2019-08-15: Make sure we don't have arguments anymore
:emptystack_loop
if "%~1"=="" goto emptystack_exit
shift & goto emptystack_loop
:emptystack_exit

:compile_helper
:: Build the helper executable
:: - Set JScript.NET environment
for /f "tokens=* delims=" %%v in ('dir /b /s /a:-d  /o:-n "%SystemRoot%\Microsoft.NET\Framework\*jsc.exe"') do (
   set "l_jsc=%%v"
)
:: - Recompile .NET executable, if not found *or* if %SAFEMODE%==1
if exist "%l_exe%" if not "%SAFEMODE%"=="1" goto dl_details
if "%DEBUGEXE%"=="1" "%l_jsc%" /nologo /debug+ /print+ /out:"%l_exe%" /t:exe "%~dpsfnx0"
if not "%DEBUGEXE%"=="1" "%l_jsc%" /nologo /fast+ /print+ /out:"%l_exe%" /t:exe "%~dpsfnx0"

:dl_details
:: Retrieve title and formats
echo:%LC_STEP_DETAILS_DL%
if not defined l_ytdl_xtraflags (
    set "l_ytdl_xtraflags= "
)
:: Get title of video
set l_title=
for /F "tokens=*" %%a in ('%l_ytdl_exe% %l_ytdl_xtraflags% -e "%l_url%"') do set "l_title=%%a"
:: Translate title to the console's codepage
for /F "tokens=* delims=" %%a in ('%l_exe% -nsd -cp %l_cmd_cp% -ocp %l_cp_win_1252% -t "%l_title%"') do set "l_title=%%a"
:: Get available video formats
%l_ytdl_exe% -F "%l_url%" %l_ytdl_xtraflags%>"%l_fmtdump%" 2>nul
echo:%LC_STEP_DONE%
echo:

:: Process list of available formats
echo:%LC_STEP_PROC_FORMATS%
set l_formats=
set l_formats_count=0
set l_formats_sep=;
set l_fmtfields_sep=,
REM for /F "tokens=1,2,3,4,5,6,* delims=," %%a in ('%l_ytdl_exe% -F "%l_url%" %l_ytdl_xtraflags%^|find "mp4"') do (
for /F "tokens=* delims=" %%z in ('type "%l_fmtdump%"^|find "mp4"') do (
    :: Filter format line
    set "l_line=%%z"
    set "l_line=!l_line:audio only=audio-only!"
    set "l_line=!l_line:DASH audio=DASH_audio!"
    set "l_line=!l_line:video only=video-only!"
    set "l_line=!l_line:(best)=,*best*!"
    for /F "tokens=1,2,3,4,5,6,* delims=," %%a in ("!l_line!") do (
        :: Trim values
        set "l_format_spec=%%a"
        call "%__selfAbs%" : proc_trim l_format_spec
        set "l_format_size=%%e"
        if "%%e"=="" set "l_format_size=%%d"
        if "%%e"=="*best*" set "l_format_size=%%d"
        if "!l_format_size!"=="" if "%%d"=="" set "l_format_size=%%c"
        if not "!l_format_size!"=="" call "%__selfAbs%" : proc_trim l_format_size
        :: Check for presence of the video-only tag
        set l_format_vidonly=0
        set "l_field_c=%%c"
        if not "!l_field_c!"=="" call "%__selfAbs%" : proc_trim l_field_c
        if "!l_field_c!"=="video-only" set "l_format_vidonly=1"
        if "!l_format_vidonly!"=="0" set "l_field_d=%%d"
        if not "!l_field_d!"=="" if "!l_format_vidonly!"=="0" call "%__selfAbs%" : proc_trim l_field_d
        if "!l_field_d!"=="video-only" set "l_format_vidonly=1"
        if "!l_format_vidonly!"=="0" set "l_field_e=%%e"
        if not "!l_field_e!"=="" if "!l_format_vidonly!"=="0" call "%__selfAbs%" : proc_trim l_field_e
        if "!l_field_e!"=="video-only" set "l_format_vidonly=1"
        :: Parse non-space separated fields
        set "l_format=!l_format_vidonly! !l_format_spec!"
        if not "!l_format_size!"=="" set "l_format=!l_format!  !l_format_size!"
        call "%__selfAbs%" : proc_parse_format l_format %l_fmtfields_sep% %l_formats_sep%
        if not [!l_formats!]==[] set l_formats=!l_formats!%l_formats_sep%
        set l_formats=!l_formats!!l_format!
    )
)
set l_line=
set l_format_spec=
set l_format_size=
set l_format_vidonly=
set l_field_c=
set l_field_d=
set l_field_e=
set l_format=

:: Group formats into video+audio, then video-only, then audio-only
set "l_formats_remain=%l_formats%"
set l_formats_va=
set l_formats_vo=
set l_formats_ao=
:fmt_loop_1
:: - Get formats one after the other and put them in the appropriate bin
for /F "tokens=1,* delims=%l_formats_sep%" %%a in ("%l_formats_remain%") do (
    set "l_formats_remain=%%b"
    set l_format_streams=
    set l_format_line=%%a
    for /F "tokens=1 delims=%l_fmtfields_sep%" %%z in ("!l_format_line!") do set "l_format_streams=%%z"
    if "!l_format_streams!"=="video+audio" (
        if not "!l_formats_va!"=="" set "l_formats_va=!l_formats_va!%l_formats_sep%"
        set "l_formats_va=!l_formats_va!!l_format_line!"
    )
    if "!l_format_streams!"=="video-only" (
        if not "!l_formats_vo!"=="" set "l_formats_vo=!l_formats_vo!%l_formats_sep%"
        set "l_formats_vo=!l_formats_vo!!l_format_line!"
    )
    if "!l_format_streams!"=="audio-only" (
        if not "!l_formats_ao!"=="" set "l_formats_ao=!l_formats_ao!%l_formats_sep%"
        set "l_formats_ao=!l_formats_ao!!l_format_line!"
    )
)
if not "%l_formats_remain%"=="" goto fmt_loop_1
set l_format_line=
:: - Put back grouped formats together
set l_formats=
if not "%l_formats_va%"=="" set "l_formats=%l_formats_va%"
if not "%l_formats_vo%"=="" (
    if not "%l_formats%"=="" set "l_formats=%l_formats%%l_formats_sep%"
    set "l_formats=!l_formats!%l_formats_vo%"
)
if not "%l_formats_ao%"=="" (
    if not "%l_formats%"=="" set "l_formats=%l_formats%%l_formats_sep%"
    set "l_formats=!l_formats!%l_formats_ao%"
)
set l_formats_va=
set l_formats_vo=
set l_formats_ao=

:: Now ordered, break them up into individual lines, and then into fields
set l_cntr=1
set "l_formats_remain=%l_formats%"
:fmt_loop_2
for /F "tokens=1,* delims=%l_formats_sep%" %%a in ("%l_formats_remain%") do set l_format_%l_cntr%=%%a&set /A l_cntr=%l_cntr%+1&set l_formats_remain=%%b
if not "%l_formats_remain%"=="" goto fmt_loop_2
set /A l_formats_count=%l_cntr%-1
:: Limit number of formats to 25
if %l_formats_count% GTR 25 set l_formats_count=25
:: Further break them up into their fields
for /L %%z in (1,1,%l_formats_count%) do (
    :: Ensure we have empty env. variables
    for /F "tokens=1 delims==" %%a in ('set l_format_%%z_ 2^>nul') do set %%a=
    :: Break up format spec into its fields
    for /F "tokens=1,2,3,4,5,6,7 delims=%l_fmtfields_sep%" %%a in ("!l_format_%%z!") do ( set "l_format_%%z_streams=%%a"&set "l_format_%%z_key=%%b"&set "l_format_%%z_ext=%%c"&set "l_format_%%z_res=%%d"&set "l_format_%%z_quality=%%e"&set "l_format_%%z_bitrate=%%f"&set "l_format_%%z_size=%%g" )
    REM call "%__selfAbs%" : proc_break_fmtfields l_format_%%z l_format_%%z %l_fmtfields_sep%
    if "!l_format_%%z_quality!"=="DASH_audio" set "l_format_%%z_quality=DASH"
    :: Ensure we have values for undefined fields
    if "!l_format_%%z_res!"=="" set "l_format_%%z_res=???x???"
    if "!l_format_%%z_quality!"=="" set "l_format_%%z_quality=not-specified"
    if "!l_format_%%z_bitrate!"=="" set "l_format_%%z_bitrate=???k"
    if "!l_format_%%z_size!"=="" set "l_format_%%z_size=?.??MiB"
)
:: Finished parsing formats!!
echo:%LC_STEP_DONE%
echo:

:: Display title and formats available
echo:%LC_VIDEO_TITLE%"%l_title%"
echo:
:: Build choice list for formats
echo:%LC_AVAIL_FORMATS%
echo:
set l_choices=
set l_alphanum=0123456789ABCDEFGHIJKLMOPS
set l_current_group=
set l_group_header_shown=
:: Let's make it easy for us this time...
set l_formats_vo_count=0
set l_formats_ao_count=0
set l_choices_vo=;
set l_choices_ao=;
set l_formats_list_vo=,
set l_formats_list_ao=,
set l_formats_idx_vo=,
set l_formats_idx_ao=,
for /L %%z in (1,1,%l_formats_count%) do (
    :: Get choice key
    set "l_choice_alpha=!l_alphanum:~%%z,1!"
    :: Print stream-type grouping, if required
    if not "!l_current_group!"=="!l_format_%%z_streams!" set "l_current_group=!l_format_%%z_streams!"&set l_group_header_shown=
    if "!l_group_header_shown!"=="" if "!l_current_group!"=="video+audio" echo:  ^[%LC_FMT_GROUP_VA%^]
    if "!l_group_header_shown!"=="" if "!l_current_group!"=="video-only" echo:  ^[%LC_FMT_GROUP_VO%^]
    if "!l_group_header_shown!"=="" if "!l_current_group!"=="audio-only" echo:  ^[%LC_FMT_GROUP_AO%^]
    set l_group_header_shown=1
    :: Display choice line, as long as we have a format key:
    REM NOTE: Below, we do a series of text substitutions to essentially replace
    REM       fields like ?$xyz?? by the value of %l_format_##_xyz%
    set l_line=
    if not "!l_format_%%z_key!"=="" (
        if "!l_format_%%z_streams!"=="video+audio" set "l_line=%LC_FMT_LINE_VA:??=¤%"
        if "!l_format_%%z_streams!"=="video-only" set "l_line=%LC_FMT_LINE_VO:??=¤%"
        if "!l_format_%%z_streams!"=="audio-only" set "l_line=%LC_FMT_LINE_AO:??=¤%"
        set "l_format_%%z_idx=!l_choice_alpha!"
        call set "l_line=!!l_line:?$=¤l_format_%%z_!!"
        set "l_line=!l_line:¤=%%!"
        call set "l_line=!l_line!"
        echo:    !l_line!
    )
    :: Append to list of keys for choice.exe
    set "l_choices=!l_choices!!l_choice_alpha!"
    :: Also build alternate lists in case user chooses a video-only or audio-only option
    if "!l_format_%%z_streams!"=="video-only" set /A l_formats_vo_count=!l_formats_vo_count!+1&set "l_choices_vo=!l_choices_vo!!l_choice_alpha!"&set "l_formats_list_vo=!l_formats_list_vo!!l_choice_alpha!,"&set "l_formats_idx_vo=!l_formats_idx_vo!%%z,"
    if "!l_format_%%z_streams!"=="audio-only" set /A l_formats_ao_count=!l_formats_ao_count!+1&set "l_choices_ao=!l_choices_ao!!l_choice_alpha!"&set "l_formats_list_ao=!l_formats_list_ao!!l_choice_alpha!,"&set "l_formats_idx_ao=!l_formats_idx_ao!%%z,"
)
echo:  --
echo:    R^) %LC_OPTION_TRYNEWURL%
echo:    Q^) %LC_OPTION_CANCEL%
echo:
set l_format_chosen=
set /A l_restart_idx=%l_formats_count%+1
set /A l_quit_idx=%l_formats_count%+2
call set "l_format_query=%%LC_FORMAT_QUERY:??formatCount??=%l_formats_count%%%"
choice /C %l_choices%RQ /N /M "%l_format_query%"
REM Remember, ERRORLEVELs are to be processed in reverse order (i.e. highest values being checked first)
:: Process [R] & [Q] options
if ERRORLEVEL %l_quit_idx% goto canceled
if ERRORLEVEL %l_restart_idx% goto header
:: Process format selection
for /L %%c in (%l_formats_count%,-1,1) do if ERRORLEVEL %%c (
    set "l_choice_idx=%%c"
    set "l_choice_alpha=!l_alphanum:~%%c,1!"
    set "l_format_chosen=!l_format_%%c!"
    set "l_chosen_key=!l_format_%%c_key!"
    set "l_chosen_ext=!l_format_%%c_ext!"
    set "l_chosen_quality=!l_format_%%c_quality!"
    set "l_chosen_streams=!l_format_%%c_streams!"
)
:: 2019-10-14: Keep desc of first stream choice if we don't end up merging it
set "l_choice_desc=%l_choice_alpha%) %l_chosen_quality%, %l_chosen_ext%"
:: Check if this is a video-only or audio-only stream
if "%l_chosen_streams%"=="video-only" goto got_video_only
if "%l_chosen_streams%"=="audio-only" goto got_audio_only
goto got_format
:got_video_only
:: Map fields of chosen format as *_vo
set l_other_format=l_format_ao
set "l_chosen_key_vo=%l_chosen_key%"
set l_other_key=l_chosen_key_ao
set "l_chosen_ext_vo=%l_chosen_ext%"
set l_other_ext=l_chosen_ext_ao
set "l_chosen_quality_vo=%l_chosen_quality%"
set l_other_quality=l_chosen_quality_ao
set "l_choice_vo=%l_choice_alpha%"
set l_choice_alpha=
set l_other_choice=l_choice_ao
:: Trim A-O choices and formats list (now that we'll use them)
set "l_format_vo=%l_format_chosen%"
set l_formats_count=%l_formats_ao_count%
set "l_choices=%l_choices_ao:~1%"
set "l_formats_list=%l_formats_list_ao:~1,-1%"
set "l_option_noaltflux=%LC_CHOICE_NO_AO_KEEP_VO%
call set "l_format_query=%%LC_VO_CHOSEN_QUERY_AO:??choices??=%l_formats_list%,N,R,Q%%"
goto voao_query
:got_audio_only
:: Map fields of chosen format as *_ao
set l_other_format=l_format_vo
set "l_chosen_key_ao=%l_chosen_key%"
set l_other_key=l_chosen_key_vo
set "l_chosen_ext_ao=%l_chosen_ext%"
set l_other_ext=l_chosen_ext_vo
set "l_chosen_quality_ao=%l_chosen_quality%"
set l_other_quality=l_chosen_quality_vo
set "l_choice_ao=%l_choice_alpha%"
set l_choice_alpha=
set l_other_choice=l_choice_vo
:: Trim V-O choices and formats list (now that we need them)
set "l_format_ao=%l_format_chosen%"
set l_formats_count=%l_formats_vo_count%
set "l_choices=%l_choices_vo:~1%"
set "l_formats_list=%l_formats_list_vo:~1,-1%"
set "l_option_noaltflux=%LC_CHOICE_NO_VO_KEEP_AO%
call set "l_format_query=%%LC_AO_CHOSEN_QUERY_VO:??choices??=%l_formats_list%,N,R,Q%%"
goto voao_query

:voao_query
:: Show the "keep as-is" option
echo:
echo:  [%LC_FMT_GROUP_MORE_OPT%]
echo:    N^) %l_option_noaltflux%
echo:
:: Get ERRORLEVEL values for N/R/Q options
set /A l_noalt_idx=%l_formats_count%+1
set /A l_restart_idx=%l_formats_count%+2
set /A l_quit_idx=%l_formats_count%+3
:: Show the query lines except for the last one
set "l_format_query=%l_format_query:\n=¤%"
set "l_query_remain=%l_format_query%"
set l_query_lastline=
:voao_query_loop
for /F "tokens=1,* delims=¤" %%a in ("%l_query_remain%") do (
    if not "%%b"=="" echo:%%a
    if "%%b"=="" set "l_query_lastline=%l_query_remain%"
    set "l_query_remain=%%b"
)
if not "%l_query_remain%"=="" goto voao_query_loop
set "l_choices_ref=0%l_choices%NRQ"
:: Show the last query line as part of the CHOICE command
choice /C %l_choices%NRQ /N /M "%l_query_lastline%"
echo:
:: Check if one of the N/R/Q options was picked
if ERRORLEVEL %l_quit_idx% goto canceled
if ERRORLEVEL %l_restart_idx% goto header
if ERRORLEVEL %l_noalt_idx% goto got_format
:: Process format selection, index first then key
for /L %%c in (%l_formats_count%,-1,1) do if ERRORLEVEL %%c (
    set "l_choice_alpha=!l_choices_ref:~%%c,1!"
    set "%l_other_choice%=!l_choice_alpha!"
)
set l_choice_idx=
for /L %%c in (25,-1,1) do (
    if "!l_alphanum:~%%c,1!"=="%l_choice_alpha%" set l_choice_idx=%%c
)
for /F "tokens=* delims=" %%c in ("%l_choice_idx%") do (
    set "%l_other_format%=!l_format_%%c!"
    set "%l_other_key%=!l_format_%%c_key!"
    set "%l_other_ext%=!l_format_%%c_ext!"
    set "%l_other_quality%=!l_format_%%c_quality!"
)
set "l_chosen_streams=video+audio"
:: Combine keys of chosen streams, and build description string
set "l_chosen_key=%l_chosen_key_vo%+%l_chosen_key_ao%"
call set "l_choice_desc=%%LC_CHOSEN_FORMAT_VOAO_DETAILS:??vo??=%l_choice_vo%) %l_chosen_ext_vo%, %l_chosen_quality_vo%%%"
call set "l_choice_desc=%%l_choice_desc:??ao??=%l_choice_ao%) %l_chosen_ext_ao%, %l_chosen_quality_ao%%%"
:: Keep some V-O values
set "l_chosen_ext=%l_chosen_ext_vo%"
set "l_chosen_quality=%l_chosen_quality_vo%"

:got_format
:: Display chosen format to be downloaded
set l_ytdl_merge_required=0
for /F "tokens=1,2 delims=+" %%a in ("%l_chosen_key%") do if not "%%b%"=="" set l_ytdl_merge_required=1
echo:%LC_CHOSEN_FORMAT%%l_choice_desc% ("%l_chosen_key%")

:: Ask user for an output filename through our JScript.NET-compiled executable
:: - Make sure we have an extension and quality
if "%l_chosen_ext%"=="" call set "l_chosen_ext=%%%l_other_ext%%%"
if "%l_chosen_quality%"=="" call set "l_chosen_quality=%%%l_other_quality%%%"
:: - Choose a default filename based on the video's title
set "l_filename=%l_title%_%l_chosen_quality%.%l_chosen_ext%"
:: - Adjust dialog title if needed
set "l_dialog_title=%LC_SAVEAS_DLG_TITLE%"
if not "%l_chosen_streams%"=="audio-only" goto ask_fname
for /F "tokens=2,3 delims=(+^^" %%a in ("%LC_FMT_GROUP_VA%") do set "l_transl_video=%%a"&set "l_transl_audio=%%b"
call set "l_dialog_title=%%l_dialog_title:%l_transl_video%=%l_transl_audio%%%"
:ask_fname
:: - Execute the utility and store the filename chosen
set l_output=
for /F "tokens=* delims=" %%a in ('%l_exe% -p "%l_workdir%" -f "%l_filename%" -t "%l_dialog_title%"') do set "l_output=%%a"

:: Make sure user didn't cancel
if "%l_output%"=="" goto canceled
if "%l_output%"=="*" goto canceled
:: Delete any existing file (as the user would already have confirmed such action)
if exist "%l_output%" del /f /q "%l_output%">nul 2>&1

:: Show output filename
echo:
echo:%LC_OUTPUT_FILENAME%"%l_output%"
echo:

:: Proceed to the download
echo:%LC_DOWNLOAD_STARTED%
echo:---
:: Use a different variable for extra args to prevent piling up the appends
set "l_ytdl_dlflags=%l_ytdl_xtraflags%"
REM if "%l_ytdl_merge_required%"=="1" set "l_ytdl_dlflags= --merge-output-format %l_chosen_ext% %l_ytdl_dlflags%"
:: 2020-10-07: Now always specifying the ffmpeg location when provided
if defined l_ffmpeg_path (
    set "l_ytdl_dlflags=--ffmpeg-location "%l_ffmpeg_path%^" !l_ytdl_dlflags!"
    if defined l_ffmpeg_xargs set "l_ytdl_dlflags=!l_ytdl_dlflags! --postprocessor-args "%l_ffmpeg_xargs%^""
)
:: Executing "youtube-dl.exe"
if "%l_chosen_key%"=="" (
    echo:[cmdline: %l_ytdl_exe% -f "best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" %l_ytdl_dlflags% "%l_url%"]
    %l_ytdl_exe% -f "best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" %l_ytdl_dlflags% "%l_url%"
) else (
    echo:[cmdline: %l_ytdl_exe% -f "%l_chosen_key%/best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" %l_ytdl_dlflags% "%l_url%"]
    %l_ytdl_exe% -f "%l_chosen_key%/best[ext=mp4]+bestaudio/best[ext=mp4]" -o "%l_output%" %l_ytdl_dlflags% "%l_url%"
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
if "%BATCHMODE%"=="1" (
    choice /C %LC_SCRIPT_RESTART_CHOICES% /N /M "%LC_SCRIPT_RESTART_QUERY%"
    if ERRORLEVEL 2 goto cleanup
    if ERRORLEVEL 1 goto start
) else pause
goto cleanup

:cleanup
:: - Delete executable (unless in DEBUGEXE mode)
if not [%DEBUGEXE%]==[] del /f /q "%l_exe%">nul 2>&1
set __self=
set __selfAbs=
set DEBUGEXE=
set SAFEMODE=
set BATCHMODE=
for /F "tokens=1 delims==" %%a in ('set l_ 2^>nul') do set %%a=
for /F "tokens=1 delims==" %%a in ('set LC_ 2^>nul') do set %%a=
goto :EOF

:: ----

:: Procedures

:proc_trim
set "l_p_target=%~1"
set l_p_value=!%l_p_target%!
:: Trim from left
for /f "tokens=* delims= " %%a in ("%l_p_value%") do set l_p_value=%%a
:: Trim from right
for /L %%a in (1,1,100) do if "!l_p_value:~-1!"==" " set l_p_value=!l_p_value:~0,-1!
:: Update
set %l_p_target%=%l_p_value%
:: Cleanup
set l_p_target=
set l_p_value=
:: Exit procedure
goto :EOF

:proc_parse_format
set "l_p_target=%~1"
set "l_p_field_sep=%2"
if [%l_p_field_sep%]==[] set l_p_field_sep=,
set "l_p_fmt_sep=%3"
if [%l_p_fmt_sep%]==[] set l_p_fmt_sep=;
set l_p_value=!%l_p_target%!
set l_p_return=
:: Input format: {video-only:0,1} {key} {format:mp4,m4a,webm,..} {res:WxH|or|audio-only} [ {quality:240p,360p,medium,..} [ {bitrate:###k} [ {size:###.##MiB} ] ] ]
for /f "tokens=1,2,3,4,5,6,7 delims= " %%a in ("%l_p_value%") do (
    if "%%a"=="1" set "l_p_streams=video-only"
    if "%%a"=="0" set "l_p_streams=video+audio"
    set "l_p_res=%%d"
    if "%%d"=="audio-only" set "l_p_res=n/a" & set "l_p_streams=audio-only"
    :: Output format: {streams:video+audio,video-only,audio-only},{key},{format},{res:WxH|or|n/a}[,{quality}[,{bitrate}[,{size}]]]
    set "l_p_item=!l_p_streams!%l_p_field_sep%%%b%l_p_field_sep%%%c%l_p_field_sep%!l_p_res!%l_p_field_sep%%%e%l_p_field_sep%%%f%l_p_field_sep%%%g"
    if not [!l_p_return!]==[] set "l_p_return=!l_p_return!%l_p_fmt_sep%"
    set "l_p_return=!l_p_return!!l_p_item!"
)
:: Update
set "%l_p_target%=%l_p_return%"
:: Cleanup
set l_p_target=
set l_p_field_sep=
set l_p_fmt_sep=
set l_p_value=
set l_p_return=
set l_p_streams=
set l_p_res=
set l_p_item=
:: Exit procedure
goto :EOF

:proc_break_fmtfields
set "l_p_target=%~1"
set "l_p_prefix=%2"
set "l_p_field_sep=%3"
if [%l_p_field_sep%]==[] set l_p_field_sep=,
call set "l_p_value=%%%l_p_target%%%"
for /F "tokens=1,2,3,4,5,6,7 delims=%l_p_field_sep%" %%a in ("%l_p_value%") do (
    set "%l_p_prefix%_key=%%a"
    set "%l_p_prefix%_ext=%%b"
    set "%l_p_prefix%_res=%%c"
    set "%l_p_prefix%_quality=%%d"
    set "%l_p_prefix%_bitrate=%%e"
    set "%l_p_prefix%_size=%%f"
    set "%l_p_prefix%_streams=%%g"
)
:: Cleanup
set l_p_target=
set l_p_prefix=
set l_p_field_sep=
set l_p_value=
:: Exit procedure
goto :EOF

:proc_expand_lcstrs
:: Go through LC_* vars and keep the ones corresponding to script lang
for /F "tokens=1,2* delims==" %%a in ('set LC_') do (
    set "l_p_varname=%%a"
    if "!l_p_varname:~-2!"=="%l_script_lang%" set "!l_p_varname:~0,-3!=%%b"
)
:: Cleanup
set l_p_varname=
:: Exit procedure
goto :EOF

*/

import System;
import System.Text;
import System.Text.RegularExpressions;
import System.IO;
import System.Windows.Forms;

const CP_DOS850    : String = "IBM850";
const CP_WIN1252   : String = "windows-1252";
const CP_UNICODE   : String = "utf-16";
const CP_UTF8      : String = "utf-8";
const CP_ISO8859_1 : String = "iso-8859-1";

function resolveCodePage(codePage) {
    switch(codePage) {
        case '437':     case '500':     case '737':
        case '775':     case '850':     case '852':
        case '855':     case '857':     case '860':
        case '861':     case '863':     case '864':
        case '865':     case '869':     case '870':
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
        case '874':     case '1250':    case '1251':
        case '1252':    case '1253':    case '1254':
        case '1255':    case '1256':    case '1257':
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
        case '28603': // Estonian (ISO)½
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
    return codePage;
}

function convertCodePage(text, fromCodePage, toCodePage) {
    var srcEnc : Encoding = Encoding.GetEncoding(resolveCodePage(fromCodePage)),
        destEnc : Encoding = Encoding.GetEncoding(resolveCodePage(toCodePage)),
        srcEncBytes : byte[] = srcEnc.GetBytes(text);
    return destEnc.GetString(srcEncBytes);
}

const DEFAULT_TITLE    : String = "Save output video file";
const DEFAULT_FILENAME : String = "video.mp4";
const DEFAULT_CODEPAGE : String = CP_WIN1252;

var curPath       : String = Environment.CurrentDirectory,
    inputCP       : String = DEFAULT_CODEPAGE,
    outputCP      : String = DEFAULT_CODEPAGE,
    title         : String = "",
    path          : String = "",
    filename      : String = "",
    outputPath    : String = "",
    convertCPOnly : Boolean = false,
    debugVerbosity: Boolean = false;

var arguments:String[] = Environment.GetCommandLineArgs();
for (var i=1; i<arguments.length; i++) {
    switch(arguments[i].toLowerCase()) {
        case '/nsd':
        case '/nosaveasdialog':
        case '-nsd':
        case '--no-saveas-dialog':
            convertCPOnly = true;
            break;
        case '/ocp':
        case '/outputcodepage':
        case '-ocp':
        case '--output-code-page':
            if (i+1 < arguments.length) {
                outputCP = arguments[i+1];
                i++;
            }
            break;
        case '/cp':
        case '/inputcodepage':
        case '-cp':
        case '--input-code-page':
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
        case '/debug':
        case '--debug':
            debugVerbosity = true;
            break;
        default:
            print( "Unhandled switch: " + arguments[i] );
            Environment.Exit(1);
    }
}

// decode title, filename and path strings from secified codepage
if (inputCP.length) { // signature: convertCodePage(someString, fromCodePage, toCodePage)
    if (title.length) title = convertCodePage(title, inputCP, DEFAULT_CODEPAGE);
    if (path.length) path = convertCodePage(path, inputCP, DEFAULT_CODEPAGE);
    if (filename.length) filename = convertCodePage(filename, inputCP, DEFAULT_CODEPAGE);
}

// check if we're being requested to show a Save-As dialog
if (!convertCPOnly) {
    var diffCP = (outputCP !== inputCP);
    if (debugVerbosity) {
        Console.Error.WriteLine('\r\n---\r\nYouTube Video Downloader Script Helper EXE\r\n\r\nPassed arguments:');
        if (title.length) Console.Error.WriteLine('- [dialog] title: "{0}"', diffCP  ? convertCodePage(title, DEFAULT_CODEPAGE, outputCP) : title);
        if (path.length) Console.Error.WriteLine('- [output] path: "{0}"', diffCP ? convertCodePage(path, DEFAULT_CODEPAGE, outputCP) : path);
        if (filename.length) Console.Error.WriteLine('- [suggested] filename: "{0}"', diffCP ? convertCodePage(filename, DEFAULT_CODEPAGE, outputCP) : filename);
        if (inputCP !== DEFAULT_CODEPAGE) Console.Error.WriteLine('- input-code-page: "{0}"', diffCP ? convertCodePage(inputCP, DEFAULT_CODEPAGE, outputCP) : inputCP);
        if (outputCP !== DEFAULT_CODEPAGE) Console.Error.WriteLine('- output-code-page: "{0}"', diffCP ? convertCodePage(outputCP, DEFAULT_CODEPAGE, outputCP) : outputCP);
        Console.Error.WriteLine();
    }
    // if a path was indeed specified, use it (replacing our default value)
    if (path.length) {
        curPath = path;
    }
    // use default values if title and/or filename weren't provided
    if (!title.length) title = DEFAULT_TITLE;
    if (!filename.length) filename = DEFAULT_FILENAME;
    // initialize a new file-save dialog
    var saveFileDlg : SaveFileDialog = new SaveFileDialog();
    saveFileDlg.InitialDirectory = curPath;
    // stick to provided filename extension
    var fileExt : String = (/[.]/.exec(filename)) ? /[^.]+$/.exec(filename)[0].toLowerCase() : 'mp4',
        formatName : String = "";
    // TODO: Localize, maybe?
    switch(fileExt) {
        case 'mp4':
            saveFileDlg.Filter = "MP4 Video (*.mp4)|*.mp4";
            break;
        case 'mkv':
            saveFileDlg.Filter = "Matroska Multimedia Container (*.mkv)|*.mkv";
            break;
        case 'm4v':     case 'vob':     case 'ogv':
        case 'ogg':     case 'webm':    case 'flv':
        case 'f4v':     case 'avi':     case 'wmv':
        case 'mov':     case 'qt':      case 'rm':
        case 'mpg':     case 'mpeg':    case 'mp2':
            if (fileExt == "mpg") fileExt = "mpeg"
            switch(fileExt) {
                case 'qt': formatName = "QuickTime"; break;
                case 'rm': formatName = "RealMedia"; break;
                case 'ogv': case 'ogg': formatName = "OGG Vorbis"; break;
                default: formatName = fileExt.toUpperCase();
            }
            saveFileDlg.Filter = formatName+" Video (*."+fileExt+")|*."+fileExt;
            break;
        case 'm4a':     case 'mp3':     case 'aa':
        case 'aac':     case 'aax':     case 'aiff':
        case 'ape':     case 'flac':    case 'm4b':
        case 'm4p':     case 'ra':      case 'voc':
        case 'wav':     case 'wma':     case 'wv':
            saveFileDlg.Filter = fileExt.toUpperCase() + " Audio (*."+fileExt+")|*."+fileExt;
            break;
        default:
            saveFileDlg.Filter = fileExt.toUpperCase() + " Multimedia File (*."+fileExt+")|*."+fileExt;
    }
    saveFileDlg.Title = title;
    saveFileDlg.FileName = filename.replace(/[<>:"\/\\\|\?\*]/g, "_");
    // set default output file path
    outputPath = '';
    // query user for the file location and name
    if (debugVerbosity) Console.Error.Write('Asking user for a filename...');
    if (saveFileDlg.ShowDialog() == DialogResult.OK) {
        // if the file name is not an empty string open it for saving.
        if (saveFileDlg.FileName != "") {
            outputPath = saveFileDlg.FileName;
            if (debugVerbosity) {
                Console.Error.WriteLine('\r\nPath and filename chosen: {0}', diffCP ? convertCodePage(outputPath, DEFAULT_CODEPAGE, outputCP) : outputPath);
            }
        }
    }
    if (!(outputPath.length) && debugVerbosity) {
        Console.Error.WriteLine('\r\nUser canceled selection of an output path and filename');
    }
    // convert to destination encoding if needed
    if (outputCP.length) {
        outputPath = convertCodePage(outputPath, DEFAULT_CODEPAGE, outputCP);
    }
    // return output path through StdOut
    print(outputPath);
    if (debugVerbosity) Console.Error.WriteLine('---');
} else {
    // convert to a destination encoding if required
    if (outputCP.length) {
        if (title.length) title = convertCodePage(title, DEFAULT_CODEPAGE, outputCP);
        if (path.length) path = convertCodePage(path, DEFAULT_CODEPAGE, outputCP);
        if (filename.length) filename = convertCodePage(filename, DEFAULT_CODEPAGE, outputCP);
    }
    // output *provided* strings in specific order: title, path, filename
    var bSecondLine : Boolean = false;
    if (title.length) {
        print(title);
        bSecondLine = true;
    }
    if (path.length) {
        if (bSecondLine) print("\n");
        print(path);
        bSecondLine = true;
    }
    if (filename.length) {
        if (bSecondLine) print("\n");
        print(filename);
    }
}

// End of file "youtube-dl_run_v9.4.cmd"