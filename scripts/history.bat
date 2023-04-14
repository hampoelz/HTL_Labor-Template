::
:: Copyright (c) 2023 Rene Hampölz
::
:: Use of this source code is governed by an MIT-style
:: license that can be found in the LICENSE file under
:: https://github.com/hampoelz/LaTeX-Template.
::

:: Benutzung: https://github.com/hampoelz/HTL_LaTeX-Template/wiki/02-Benutzung#git-versionsverlauf

@echo off

set "author_avatar_dir=.\out\images\"
set "cached_data_file=.\out\history.cache"

:: maximum commits to show in the history
set "commit_limit=5"

:: commits ignored in the generated history (seperate with space)
set "ignore_SHAs="

set "jq_bin_download=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win32.exe"
set "jq_bin_path=.\out\bin\jq-win32.exe"

:: List of Gitmojis that will be removed in the commit message seperate with space)
::   curl -s https://raw.githubusercontent.com/carloscuesta/gitmoji/master/packages/gitmojis/src/gitmojis.json | .\out\bin\jq-win32.exe -r .gitmojis[].code
set "gitmojis=:art: :zap: :fire: :bug: :ambulance: :sparkles: :memo: :rocket: :lipstick: :tada: :white_check_mark: :lock: :closed_lock_with_key: :bookmark: :rotating_light: :construction: :green_heart: :arrow_down: :arrow_up: :pushpin: :construction_worker: :chart_with_upwards_trend: :recycle: :heavy_plus_sign: :heavy_minus_sign: :wrench: :hammer: :globe_with_meridians: :pencil2: :poop: :rewind: :twisted_rightwards_arrows: :package: :alien: :truck: :page_facing_up: :boom: :bento: :wheelchair: :bulb: :beers: :speech_balloon: :card_file_box: :loud_sound: :mute: :busts_in_silhouette: :children_crossing: :building_construction: :iphone: :clown_face: :egg: :see_no_evil: :camera_flash: :alembic: :mag: :label: :seedling: :triangular_flag_on_post: :goal_net: :dizzy: :wastebasket: :passport_control: :adhesive_bandage: :monocle_face: :coffin: :test_tube: :necktie: :stethoscope: :bricks: :technologist: :money_with_wings: :thread: :safety_vest:"

set "title="
set "prefix="
set "prefix_entry="

if [%1] == [] goto:show_usage else (
    if [%1] == [/?]     call:show_usage
    if [%1] == [/help]  call:show_usage
    if [%1] == [timeline] (
        set "prefix=HistoryTimeline"
        set "prefix_entry=HistoryTlEntry"
        goto:start
    )
    if [%1] == [table] (
        set "prefix=HistoryTable"
        set "prefix_entry=HistoryTabEntry"
        goto:start
    )
)

exit

:show_usage
    echo.|set /p ="usage: history.bat <timeline | table> [title] [commit limit] [ignore SHAs]"
    echo.
    echo.
    echo This script prints LaTeX code to
    echo display the current git history
    echo in your document.
    echo The 'history.sty'-file is required.
    exit

:start
    setlocal enabledelayedexpansion

    if not "%~2" == "" set "title=[%~2]"
    if not "%~3" == "" set "commit_limit=%~3"
    if not "%~4" == "" set "ignore_SHAs=%~4"

    :: set no commit limit if parameter equal '0'
    if [%commit_limit%] == [0] set "commit_limit="

    :: prepend argument got git command when commit limit is set
    if not [%commit_limit%] == [] set "commit_limit=-n !commit_limit!"

    echo \begin{%prefix%}%title%

    :: get github api url of current repo
    set github_api=
    for /f "usebackq" %%f in (`"git config --get remote.origin.url | findstr https://github.com/"`) do (
        set github_api=%%f
        set github_api=!github_api:.git=!
        set github_api=!github_api://github.com/=//api.github.com/repos/!
    )

    :: loop through commits and get date and sha
    set /a commit_counter=0
    for /f "usebackq delims=" %%i in (`"git log %commit_limit% --pretty=format:%%as,%%h"`) do (
        :: reset commit variables
        set "commit_date=" & set "commit_sha=" & set "commit_msg=" & set "commit_author="
        set "github_sha_url=" & set "github_author_url=" & set "github_author_avatar_url=" & set "github_author_avatar_file="

        :: separate date and sha to write variables
        set /a c=0
        for %%j in (%%i) do (
            if [!c!] == [0] set commit_date=%%j
            if [!c!] == [1] set commit_sha=%%j
            set /a c+=1
        )

        :: check if commit is not in ignore list
        echo %ignore_SHAs% | findstr "!commit_sha!" >nul 2>&1 || (
            :: get current commit message and author (skip already handled commits)
            for /f "usebackq delims=" %%f in (`"git log -n 1 --skip !commit_counter! --pretty=format:%%s"`) do set "commit_msg=%%f"
            for /f "usebackq delims=" %%f in (`"git log -n 1 --skip !commit_counter! --pretty=format:%%aN"`) do set "commit_author=%%f"

            git log -n 1 --skip !commit_counter! --pretty=format:%%b | findstr "ignore-in-history" >nul || (
                :: remove gitmoji-codes from commit message
                for %%j in (%gitmojis%) do set commit_msg=!commit_msg:%%j =!

                set use_cached_data=false

                :: read cache file line by line
                if exist "%cached_data_file%" (
                    for /f "usebackq tokens=*" %%j in ("%cached_data_file%") do (
                        :: reset cache variables
                        set "cache_commit_sha=" & set "cache_commit_author="
                        set "cache_github_sha_url=" & set "cache_github_author_url="
                        
                        :: separate cache data to write variables
                        set /a c=0
                        for %%k in (%%j) do (
                            if [!c!] == [0] set cache_commit_sha=%%k
                            if [!c!] == [1] set cache_github_sha_url=%%k
                            if [!c!] == [2] set cache_commit_author=%%k
                            if [!c!] == [3] set cache_github_author_url=%%k
                            set /a c+=1
                        )

                        :: pass cache data to commit variables
                        if [!commit_sha!] == [!cache_commit_sha!] (
                            set commit_author=!cache_commit_author!
                            set github_sha_url=!cache_github_sha_url!
                            set github_author_url=!cache_github_author_url!
                            set use_cached_data=true
                        )
                    )
                )
                
                :: retrieve additional data from github if repo is hosted on github and github.com is reachable
                if not [%github_api%] == [] (
                    if not [!use_cached_data!] == [true] (
                        ping github.com -n 1 -w 1000 >nul && (
                            :: download the jq-tool to parse json
                            if not exist %jq_bin_path% (
                                if not exist "%jq_bin_path%\..\" mkdir "%jq_bin_path%\..\"
                                call curl -Ls "%jq_bin_download%" -o %jq_bin_path%
                            )

                            :: fetch & parse data from GitHub and separate to write variables
                            set /a c=0
                            for /f "usebackq delims=" %%j in (`"curl -s %github_api%/commits/!commit_sha! | %jq_bin_path% -r .html_url,.author.login,.author.html_url,.author.avatar_url"`) do (
                                if not [%%j] == [null] (
                                    if [!c!] == [0] set github_sha_url=%%j
                                    if [!c!] == [1] set commit_author=%%j
                                    if [!c!] == [2] set github_author_url=%%j
                                    if [!c!] == [3] set github_author_avatar_url=%%j
                                    set /a c+=1
                                )
                            )
                            
                            :: check if data was successfully parsed
                            if [!c!] == [4] (
                                :: download author avatar
                                if not exist "%author_avatar_dir%" mkdir "%author_avatar_dir%"
                                if not exist "%author_avatar_dir%!commit_author!.png" (
                                    if not [!github_author_avatar_url!] == [] (
                                        set "parm_size=size=50"
                                        if "!github_author_avatar_url:?=!" == "!github_author_avatar_url!" (
                                            set "parm_size=?!parm_size!"
                                        ) else (
                                            set "parm_size=&!parm_size!"
                                        )

                                        call curl -s "!github_author_avatar_url!!parm_size!" -o "%author_avatar_dir%!commit_author!.png"
                                    )
                                )

                                :: cache parsed data
                                if not exist "%cached_data_file%\..\" mkdir "%cached_data_file%\..\"
                                echo !commit_sha!,!github_sha_url!,!commit_author!,!github_author_url! >> "%cached_data_file%"
                            )
                        )
                    )
                )

                :: prepare data for LaTeX document
                if exist "%author_avatar_dir%!commit_author!.png" set "github_author_avatar_file=[!commit_author!.png]"

                if not [!commit_date!] == [] set "commit_date={!commit_date!}"
                if not [!commit_sha!] == [] set "commit_sha={!commit_sha!}"
                if not [!commit_msg!] == [] set "commit_msg={\directlua{tex.sprint(-2, "\luaescapestring{\unexpanded{!commit_msg!}}")}}"
                if not [!commit_author!] == [] set "commit_author={\directlua{tex.sprint(-2, "\luaescapestring{\unexpanded{!commit_author!}}")}}"

                if not [!github_sha_url!] == [] set "github_sha_url=[!github_sha_url!]"
                if not [!github_author_url!] == [] set "github_author_url=[\directlua{tex.sprint(-2, "\luaescapestring{\unexpanded{!github_author_url!}}")}]"

                :: output combined data
                echo.\%prefix_entry%!commit_date!!commit_sha!!github_sha_url!!commit_author!!github_author_url!!github_author_avatar_file!!commit_msg!
            )
        )

        set /a commit_counter+=1
    )

    endlocal

    echo \end{%prefix%}