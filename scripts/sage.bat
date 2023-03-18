@echo off

setlocal enabledelayedexpansion

for %%a in ("%LocalAppData%" "%ProgramFiles%") do (
    call:find_sage "%%~a"
    
    if defined sage_path (
        start /wait /min "" "!sage_path!" -d --dir "%cd%" /bin/bash --login -c '/opt/sagemath-9.2/sage %*'
        exit /b
    )
)

exit /b 9009

:find_sage
    set "sage_path="
    if not exist "%~1\SageMath *" goto:EOF
    for /f "usebackq delims=" %%a in (`dir /b /s /a:d "%~1\SageMath *"`) do (
        set "sage_runtime=%%a\runtime\bin\mintty.exe"
        if exist "!sage_runtime!" (
            set "sage_path=!sage_runtime!"
            goto:EOF
        )
    )
    goto:EOF