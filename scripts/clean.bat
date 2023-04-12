::
:: Copyright (c) 2023 Rene Hampölz
::
:: Use of this source code is governed by an MIT-style
:: license that can be found in the LICENSE file under
:: https://github.com/hampoelz/LaTeX-Template.
::

:: Benutzung: https://github.com/hampoelz/HTL_LaTeX-Template/wiki/02-Benutzung#vorkonfigurierte-skriptetasks

@echo off
git clean -Xdf

for /f "usebackq delims=" %%d in (`"dir /ad /s /b | sort /r"`) do (
    echo %%d | findstr /l ".git" >nul
    if errorlevel 1 rd "%%d"
)

exit 0