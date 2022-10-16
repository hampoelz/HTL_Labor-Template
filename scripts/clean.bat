::
:: Copyright (c) 2022 Rene Hampölz
::
:: Use of this source code is governed by an MIT-style
:: license that can be found in the LICENSE file under
:: https://github.com/hampoelz/LaTeX-Template.
::

@echo off
git clean -Xdf

for /f "usebackq delims=" %%d in (`"dir /ad /s /b | sort /r"`) do (
    echo %%d | findstr /l ".git" >nul
    if errorlevel 1 rd "%%d"
)

exit 0