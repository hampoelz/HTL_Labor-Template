::
:: Copyright (c) 2022 Rene Hampölz
::
:: Use of this source code is governed by an MIT-style
:: license that can be found in the LICENSE file under
:: https://github.com/hampoelz/LaTeX-Template.
::

@echo off

set "hooks=applypatch-msg pre-applypatch post-applypatch pre-commit prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge pre-receive update post-receive post-update pre-auto-gc post-rewrite pre-push"

if [%1] == [] call:show_usage else (
    if [%1] == [/?]         call:show_usage
    if [%1] == [/help]      call:show_usage
    if not [%1] == [add] if not [%1] == [del] call:show_usage
    if not [%2] == [] if not [%3] == [] goto:start
)

exit

:show_usage
    echo.|set /p ="usage: hookmgr.bat <add | del> <githook> <shell command>"
    echo.
    echo.
    echo This script adds or removes a command to/from
    echo a specified git hook. Used to automatically
    echo handle hooks in a project.
    exit

:start
    setlocal enabledelayedexpansion

    set action=%~1
    set hook_name=%~2
    set command=%~3

    echo %hooks% | findstr "%hook_name%" >nul 2>&1 || (
        echo hookmgr.bat: Specified hook does not exist
        exit
    )
    
    set "hook_path=.\.git\hooks\%hook_name%"
    set "hook_command=nohup %command% > out/%hook_name%.log &"

    if not exist "%hook_path%" (
        if [%action%] == [del] exit
        echo #^^!/bin/sh >> "%hook_path%"
        echo. >> "%hook_path%"
    )

    if [%action%] == [add] (
        type "%hook_path%" | findstr /x /l /c:"%hook_command% " >nul && (
            echo hookmgr.bat: Your command already exists in the %hook_name% hook
        ) || (
            echo.|set /p ="%hook_command%" >> "%hook_path%"
            echo. >> "%hook_path%"
            echo hookmgr.bat: Your command has been added to the %hook_name% hook
        )

    )

    if [%action%] == [del] (
        type "%hook_path%" | findstr /x /v /l /c:"%hook_command% " > "%hook_path%.tmp"

        comp /m "%hook_path%" "%hook_path%.tmp" >nul && (
            del /q "%hook_path%.tmp"
            echo hookmgr.bat: Your command has already been removed from the %hook_name% hook
        ) || (
            move /y "%hook_path%.tmp" "%hook_path%" >nul
            echo hookmgr.bat: Your command has been removed from the %hook_name% hook
        )
    )