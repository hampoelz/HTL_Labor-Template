::
:: Copyright (c) 2023 Rene Hampölz
::
:: Use of this source code is governed by an MIT-style
:: license that can be found in the LICENSE file under
:: https://github.com/hampoelz/LaTeX-Template.
::

:: Benutzung: https://github.com/hampoelz/HTL_LaTeX-Template/wiki/02-Benutzung#vorkonfigurierte-skriptetasks

@echo off

set "gh_repo=hampoelz/HTL_Labor-Template"
set "remote_branch=main"

set "cwd_setup=%temp%\LatexSetup"
set "cwd_template=%cd%\LatexTemplate"

set "cwd_vscode=%LocalAppData%\Programs\Microsoft VS Code\bin"
set "cwd_texlive=%LocalAppData%\Programs\TeXLive"
set "cwd_git=%LocalAppData%\Programs\Git"
set "cwd_sagemath=%LocalAppData%\Programs\SageMath"
set "cwd_sagemath_wrapper=%cwd_sagemath%\wrapper"

set "refresh_env_url=https://raw.githubusercontent.com/hampoelz/LaTeX-Template/main/scripts/refreshenv.bat"

set "setup_vscode_url=https://aka.ms/win32-x64-user-stable"
set "setup_vscode=vscode-user.exe"

set "setup_texlive_url=https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip"
set "setup_texlive=texlive.zip"

set "setup_git_url=https://github.com/git-for-windows/git/releases/download/v2.37.3.windows.1/PortableGit-2.37.3-64-bit.7z.exe"
set "setup_git=portablegit.exe"

set "setup_sagemath_wrapper_url=https://raw.githubusercontent.com/%gh_repo%/%remote_branch%/scripts/sage.bat"
set "setup_sagemath_url=https://github.com/sagemath/sage-windows/releases/download/0.6.2-9.2/SageMath-9.2-Installer-v0.6.2.exe"
set "setup_sagemath=sagemath.exe"

set "setup_template_url=https://raw.githubusercontent.com/%gh_repo%/%remote_branch%/scripts/update.bat"
set "setup_template=template.bat"

echo.
echo ========================================================
echo     This script installs and configures all required
echo       software to use the latex template repository
echo.
echo     The following software will be installed:
echo       vs-code, texlive, sagemath, git
echo.
echo     The following vs-code addons will be installed:
echo       latex-workshop, latex-utilities,
echo       code-spell-checker, gitlens
echo.
echo.
echo           - Copyright (c) 2023 Rene Hampoelz -         
echo    --------------------------------------------------   
echo      By using this script you accept this project's
echo      MIT license found in the LICENSE file under
echo      https://github.com/hampoelz/LaTeX-Template
echo      and the licenses of the software that will
echo      be installed by this script.
echo    --------------------------------------------------   
echo ========================================================
echo.

choice /c YN /m "Continue with the script?"
echo.
if %errorlevel% equ 2 exit

:: name the repository folder as well as the script file name if it has changed
if not "%~n0" == "install" set "cwd_template=%cd%\%~n0"

if not exist "%cwd_setup%" mkdir "%cwd_setup%"

call:check_miktex
call:setup_vscode
call:setup_git
call:setup_texlive
call:setup_sagemath
call:synchronize_sagemath
call:configure_vscode
call:configure_git

if not "%1" == "/installonly" (
    call:setup_template
    start /min cmd /c call %cmd_vscode% "%cwd_template%"
    cd "%cwd_template%"
)

echo.
echo ========================================================
echo       The required software has been successfully
echo                 installed and configured
echo ========================================================
echo.

if not "%~n0" == "install" (
    (goto) 2>nul & del "%~f0"
)

exit

:check_miktex
    set /a check_miktex_count=0
    call:uninstall_miktex

:uninstall_miktex
    call miktex --help >nul 2>&1 || goto:EOF

    cls
    echo.
    echo ========================================================
    echo            Please uninstall MikTeX to proceed
    echo ========================================================
    echo.
    echo It is not recommended to use MikTeX as TeX distribution!
    echo.
    echo If you are forced to use MikTeX you have to install the
    echo required software manually. More information can be found
    echo in the wiki.

    if %check_miktex_count% lss 2 (
        call:soft_uninstall_miktex
        set /a check_miktex_count+=1
    ) else (
        call:force_uninstall_miktex
    )

    call:refresh_env
    goto:uninstall_miktex
    goto:EOF

:soft_uninstall_miktex
    echo.
    echo The script will open a window listing all your installed
    echo software - search for MikTeX and uninstall it to proceed.
    echo.
    pause

    call appwiz.cpl
    echo.
    echo After MikTeX has been uninstalled press any key to continue.
    echo.
    pause
    goto:EOF

:force_uninstall_miktex
    echo.
    echo Apparently the uninstall did not work,
    echo do you want to force remove MikTeX?
    echo.

    echo.
    choice /c YN /m "Force remove MikTeX?"
    echo.
    if %errorlevel% equ 2 (
        call:soft_uninstall_miktex
        goto:EOF
    )

    for /f "usebackq delims=" %%i in (`"where miktex"`) do (
        rmdir /s /q "%%~fi\..\..\..\"
    )
    cd "%cwd_setup%"
    goto:EOF

:setup_vscode
    if "%1" == "/installonly" goto:EOF
    if exist "%cwd_vscode%\code" goto:EOF

    echo.
    echo ========================================================
    echo     Download and install Microsoft Visual Studio Code
    echo ========================================================
    echo.
    cd "%cwd_setup%"
    call curl -L "%setup_vscode_url%" -o %setup_vscode% && (
        call .\%setup_vscode% /VERYSILENT /CURRENTUSER /NORESTART /MERGETASKS="addtopath,!runcode" /LOG="%cwd_setup%\%setup_vscode%.log" && (
            call:refresh_env
            
            echo -------- cleanup ---------
            del %setup_vscode%
            echo --------------------------

            goto:EOF
        )
    )

    echo -------- cleanup ---------
    if exist "%setup_vscode%" del %setup_vscode%
    echo --------------------------

    echo.
    echo --------------------------------------------
    echo  Error:
    echo.
    echo  The installation of Visual Studio Code
    echo  failed! Try to install it manually using
    echo  the 'User Installer' available on the
    echo  official website and run this script
    echo  again.
    echo.
    echo  see: https://code.visualstudio.com/
    echo -------------------------------------------- 
    echo.
    pause
    exit


:configure_vscode
    call code --help >nul 2>&1 && (
        set "cmd_vscode=code"
    ) || if exist "%cwd_vscode%\code" (
        cd "%cwd_vscode%"
        set "cmd_vscode=.\code"
    ) else (
        echo.
        echo --------------------------------------------
        echo  Error:
        echo.
        echo  Visual Studio Code cannot be found for
        echo  configuration, possibly your installation
        echo  is corrupted. Try to uninstall Visual
        echo  Studio Code and run this script again.
        echo -------------------------------------------- 
        echo.
        pause
        exit
    )

    setlocal enabledelayedexpansion

    set "installed_exts="
    for /f "usebackq delims=" %%i in (`"%cmd_vscode% --list-extensions"`) do (
        set "installed_exts=!installed_exts! %%i"
    )

    echo %installed_exts% | findstr "James-Yu.latex-workshop" | findstr "tecosaur.latex-utilities" | findstr "eamodio.gitlens" | findstr "streetsidesoftware.code-spell-checker" | findstr "streetsidesoftware.code-spell-checker-german" >nul 2>&1 || (
        echo.
        echo ========================================================
        echo    Install required and recommended VSCode extensions
        echo ========================================================
        echo.

        call %cmd_vscode% --install-extension James-Yu.latex-workshop
        call %cmd_vscode% --install-extension tecosaur.latex-utilities
        call %cmd_vscode% --install-extension eamodio.gitlens
        call %cmd_vscode% --install-extension streetsidesoftware.code-spell-checker
        call %cmd_vscode% --install-extension streetsidesoftware.code-spell-checker-german
    )

    endlocal

    cd "%cwd_setup%"
    goto:EOF

:setup_texlive
    call latexmk --help >nul 2>&1 && goto:EOF

    call tlmgr --help >nul 2>&1 && (
        echo.
        echo ========================================================
        echo                 Install TeX Live packages
        echo ========================================================
        echo.
        tlmgr init-usertree
        tlmgr install scheme-full
        goto:EOF
    )

    :: Use the default installation path as a fallback if the home folder contains accents
    for %%P in ("%UserProfile%") do set "UserFolder=%%~nP"
    powershell "if ('%UserFolder%' -match '[^a-zA-Z0-9\s-_]'){exit 1}" && (
        set "TEXLIVE_INSTALL_PREFIX=%cwd_texlive%"
    ) || (
        set "TEXLIVE_INSTALL_PREFIX=C:\TeXLive"
    )

    echo.
    echo ========================================================
    echo               Download TeX Live setup files
    echo ========================================================
    echo.
    cd "%cwd_setup%"
    call curl -L "%setup_texlive_url%" -o %setup_texlive% && (
        call tar -xvf "%cwd_setup%\%setup_texlive%" && (
            echo.
            echo ========================================================
            echo                     Install TeX Live
            echo ========================================================
            echo.

            cd "install-tl-*\."
            call .\install-tl-windows.bat -no-doc-install -no-src-install -non-admin -no-interaction -no-gui && (
                call:refresh_env
                cd "%cwd_setup%"

                echo -------- cleanup ---------
                del %setup_texlive%
                for /d %%f in ("install-tl-*") do rmdir /s /q "%%f"
                echo --------------------------

                goto:EOF
            )
        )
    )

    echo -------- cleanup ---------
    if defined TEXLIVE_INSTALL_PREFIX rmdir /s /q "%TEXLIVE_INSTALL_PREFIX%"
    if exist "%setup_texlive%" del %setup_texlive%
    for /d %%f in ("install-tl-*") do rmdir /s /q "%%f"
    echo --------------------------

    echo.
    echo --------------------------------------------
    echo  Error:
    echo.
    echo  The installation of TeX Live failed! Try
    echo  to install it manually and run this script
    echo  again. More informations are available on
    echo  the official website.
    echo.
    echo  see: https://www.tug.org/texlive/
    echo -------------------------------------------- 
    echo.
    pause
    exit

:setup_git
    call git --help >nul 2>&1 && (
        for /f "usebackq tokens=3 delims= " %%i in (`"git --version"`) do if "%%i" LSS "2.22.0" (
            call:install_git
        )
    ) || call:install_git
    goto:EOF

:install_git
    echo.
    echo ========================================================
    echo                 Download and install Git
    echo ========================================================
    echo.
    cd "%cwd_setup%"
    call curl -L "%setup_git_url%" -o %setup_git% && (
        call .\%setup_git% -o"%cwd_git%" -y && (
            call:add_env "%cwd_git%\bin"

            echo -------- cleanup ---------
            del %setup_git%
            echo --------------------------

            goto:EOF
        )
    )

    echo -------- cleanup ---------
    if exist "%setup_git%" del %setup_git%
    rmdir /s /q "%cwd_git%"
    echo --------------------------

    echo.
    echo --------------------------------------------
    echo  Error:
    echo.
    echo  The installation of Git failed! Try
    echo  to install it manually and run this script
    echo  again. More informations are available on
    echo  the official website.
    echo.
    echo  see: https://gitforwindows.org/
    echo -------------------------------------------- 
    echo.
    pause
    exit

:configure_git
    call:refresh_env
    call git --help >nul 2>&1 || (
        echo.
        echo --------------------------------------------
        echo  Error:
        echo.
        echo  Git cannot be found for configuration,
        echo  possibly your installation is corrupted.
        echo -------------------------------------------- 
        echo.
        pause
        exit
    )
    call git config user.name >nul && git config user.email >nul && goto:EOF
    set "mail="
    set "name="
    call:configure_git_details
    goto:EOF

:configure_git_details
    cls
    echo.
    echo ========================================================
    echo            Configure Git - email and username
    echo ========================================================
    echo.

    echo.
    echo Please enter your email address and your full name / username below
    echo.

    if not defined mail ( set /p mail="Email: %mail%" ) else echo Email: %mail%
    if not defined name ( set /p name="Name:  %name%" ) else echo Name:  %name%
    echo.

    if not defined mail (
        echo --------------------------------------------
        echo  Please enter your e-mail address.
        echo.
        echo  This is important because every Git commit
        echo  uses this information, and it's immutably
        echo  baked into the commits you start creating.
        echo --------------------------------------------
        echo.
        pause
        goto:configure_git_details
    )
    if not defined name (
        echo --------------------------------------------
        echo  Please enter your name.
        echo.
        echo  This is important because every Git commit
        echo  uses this information, and it's immutably
        echo  baked into the commits you start creating.
        echo --------------------------------------------
        echo.
        pause
        goto:configure_git_details
    )

    echo.
    choice /c YN /m "Are the details you entered correct?"
    echo.
    if %errorlevel% equ 2 (
        set mail=
        set name=
        goto:configure_git_details
    )

    call git config --global user.email "%mail%"
    call git config --global user.name "%name%"
    goto:EOF

:setup_sagemath
    call sage --help >nul 2>&1 && goto:EOF

    echo.
    echo ========================================================
    echo              Download and install SageMath
    echo ========================================================
    echo.
    cd "%cwd_setup%"
    call curl -L "%setup_sagemath_url%" -o %setup_sagemath% && (
        echo installing ...
        call .\%setup_sagemath% /VERYSILENT /CURRENTUSER /NORESTART /SETUPTYPE=custom /COMPONENTS=sage /MERGETASKS="!desktop" /LOG="%cwd_setup%\%setup_sagemath%.log" && (
            echo registering ...
            mkdir "%cwd_sagemath_wrapper%"
            call curl -L "%setup_sagemath_wrapper_url%" -o "%cwd_sagemath_wrapper%\sage.bat" && (
                call:add_env "%cwd_sagemath_wrapper%"

                call sage -c "exit"

                echo -------- cleanup ---------
                del %setup_sagemath%
                echo --------------------------

                goto:EOF
            )
        )
    )

    echo -------- cleanup ---------
    if exist "%setup_sagemath%" del %setup_sagemath%
    rmdir /s /q "%cwd_sagemath%"
    echo --------------------------

    echo.
    echo --------------------------------------------
    echo  Error:
    echo.
    echo  The installation of SageMath failed! Try
    echo  to install it manually and run this script
    echo  again. More informations are available on
    echo  the official website.
    echo.
    echo  see: https://www.sagemath.org/
    echo -------------------------------------------- 
    echo.
    pause
    exit

:synchronize_sagemath
    echo synchronize texlive with sagemath ...
    call:refresh_env

    set "texmflocal_path="
    for /f "usebackq delims=" %%a in (`"kpsewhich -var-value=TEXMFLOCAL"`) do set "texmflocal_path=%%a"
    for %%a in ("%texmflocal_path%") do set "texmflocal_path=%%~fa"
    if "%texmflocal_path:~-1%" == "\" set texmflocal_path=%texmflocal_path:~0,-1%

    set "sagetex_path="
    cd "%SystemDrive%\"
    for /f "usebackq delims=" %%a in (`dir /b /s /a:-d "sagetex.sty"`) do set "sagetex_path=%%~fa\..\..\..\..\"
    for %%a in ("%sagetex_path%") do set "sagetex_path=%%~fa"
    if "%sagetex_path:~-1%" == "\" set sagetex_path=%sagetex_path:~0,-1%

    cd "%cwd_setup%"

    if not exist "%sagetex_path%\" (
        echo.
        echo --------------------------------------------
        echo  Error:
        echo.
        echo  SageMath cannot be found for synchron-
        echo  ization with TeXLive, possibly your
        echo  installation is corrupted.
        echo -------------------------------------------- 
        echo.
        pause
        exit
    )

    if not exist "%texmflocal_path%\" (
        echo.
        echo --------------------------------------------
        echo  Error:
        echo.
        echo  TeXLive cannot be found for synchron-
        echo  ization with SageMath, possibly your
        echo  installation is corrupted.
        echo -------------------------------------------- 
        echo.
        pause
        exit
    )

    xcopy "%sagetex_path%" "%texmflocal_path%" /s /e /y
    texhash "%texmflocal_path%/"
    goto:EOF

:setup_template
    echo.
    echo ========================================================
    echo     Download update script from template repository
    echo ========================================================
    echo.
    cd "%cwd_setup%"
    call curl -L %setup_template_url% -o %setup_template%

    call:refresh_env

    echo.
    echo ========================================================
    echo           Initialize and update new repository
    echo ========================================================
    echo.
    if exist "%cwd_template%" (
        echo.
        echo The specified directory already exists!
        echo.
        goto:EOF
    )
    mkdir "%cwd_template%"
    cd "%cwd_template%"
    call git init
    call cmd /k "%cwd_setup%\%setup_template%"
    call latexmk -g -f --interaction=nonstopmode
    cd "%cwd_setup%"
    goto:EOF

:add_env
    set user_path=
    for /f "usebackq skip=2 tokens=1-2*" %%a in (`"%WinDir%\System32\Reg query HKCU\Environment /v Path 2>&1"`) do set "user_path=%%c"
    call "%WinDir%\System32\Reg" add "HKCU\Environment" /f /v Path /d "%~1;%user_path%"
    set "path=%~1;%path%"
    call:brodcast_env
    goto:EOF

:refresh_env
    echo.
    echo ------------------------------
    cd "%cwd_setup%"
    call:brodcast_env
    if not exist refreshenv.bat call curl -sL "%refresh_env_url%" -o refreshenv.bat
    call .\refreshenv.bat
    echo ------------------------------
    echo.
    goto:EOF

:brodcast_env
    :: Brodcast WM_SETTINGCHANGE to propagate the change to the environment variable list
    ::   Credits to https://github.com/ObjectivityLtd/PSCI/blob/master/PSCI/Public/utils/Update-EnvironmentVariables.ps1
    powershell -command "&{Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition '[DllImport(\"user32.dll\", SetLastError = true, CharSet = CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);' ; [win32.nativemethods]::SendMessageTimeout([intptr]0xffff, 0x1a, [uintptr]::Zero, \"Environment\", 2, 5000, [ref][uintptr]::zero)}" >nul
    goto:EOF