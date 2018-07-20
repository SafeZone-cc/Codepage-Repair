@set @x=0; /*
@echo off
SetLocal EnableExtensions
title Codepage Repair
color 1A
goto MAIN

:: TODO
:: Pending Rename Operations
:: ComBofix XP

:PrintTitle
cls
echo.                                                          [   version 2.5    ]
echo.            --- Codepage Repair ---                       [ by Alex Dragokas ]
echo.
echo Recovering of original files of Russian codepage,
echo standart console settings and fonts                     
echo.
echo.
Exit /B

:MAIN
call :PrintTitle

cd /d "%~dp0"
if not exist "Clean" (
  echo.
  echo.Error!
  echo.
  echo You should unpack archive first!
  pause>NUL
  exit /B
)

set "key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\34"
reg query "%key%" /v 1 >NUL 2>NUL && (
  echo ERROR.
  echo.
  echo Patch has been already applied. Reboot is required to take effect for the actions.
  echo.
  pause >NUL & Exit /B
)

:: Проверка, является ли система локализованной
call :GetOSLanguage Install.Lang.Code Install.Lang.Name Program.Lang.Code Program.Lang.Name

if "%Install.Lang.Code%" neq "0419" if "%Program.Lang.Code%" neq "0419" (
  if "%Install.Lang.Code%" neq "0422" if "%Program.Lang.Code%" neq "0422" (
    if "%Install.Lang.Code%" neq "0423" if "%Program.Lang.Code%" neq "0423" (
      echo.
      echo Cheking of system localization.
      echo.
      echo OS installation language:           %Install.Lang.Name% [%Install.Lang.Code%]
      echo Language for non-unicode programs:  %Program.Lang.Name% [%Program.Lang.Code%]
      echo.
      echo Warning: only Russian, Belarussian and Ukrainian localizations are supported. Also the systems with MUI.
      echo.
      pause & Exit /B
    )
  )
)

:: Проверка версии ОС
call :GetSystemVersion OSVersion OSBitness OSBuild OSFamily EnvironmentCore
if "%EnvironmentCore%" neq "%OSBitness%" (
  echo Bittness of OS - %OSBitness%, of process - %EnvironmentCore%.
  echo.
  echo.
  echo Wrong running mode!
  echo Running from the Windows Explorer is required.
  pause >NUL & Exit /B
)

:: Получаем права Администратора
net session >NUL 2>&1 || if "%OSFamily%"=="Vista" if "%~1"=="" (echo Administrative privilages is required... & cscript.exe //nologo //e:jscript "%~f0"& Exit /B)

:: Переходим в папку с Batch-файлом
cd /d "%~dp0"

echo ^>^>^>^>^>  Stady: Backup  ^<^<^<^<^<
echo.

echo ATTENTION !!!
echo Replacing of files and localization setting is not safe procedure !
echo.
echo It is strongly recommended to create System Restore Point.
echo __________________________________________________________________________
echo Press any key to open restore point window.
pause >NUL

if "%OSFamily%"=="Vista" (
  rundll32 shell32.dll,Control_RunDLL sysdm.cpl,,4
) else (
  start "" "%SystemRoot%\System32\Restore\rstrui.exe"
)

call :PrintTitle
echo _________________________________________________________________________
echo 1. Please, make sure that you have recovery CD or flash disk, e.g. LiveCD,
echo installation disk or ERD Commander.
echo _________________________________________________________________________
echo.
echo You will not be able to recover the system if the problem
echo with OS boot will occurs.
echo.
echo 1. It can happens on non-original OS (pack).
echo.
echo 2. It is not recommended to run this program on malware infected machine.
echo.
echo 3. Temporarily disable your protection / antivirus software.
echo.
echo 4. Press any key if you have finished to create restore point and
echo if you carried out all the preventive measures.
pause >NUL
call :PrintTitle

if not exist Backup md Backup

move /y "Backup\Recovery_from_Backup.cmd" .

:: Резервирование файлов *.NLS
if not exist Backup\*.nls goto BACKUP_Files
echo Warning: backup of codepage files has been already created earlier.
set ch=
set /p "ch=Would you like to remove it? (Y/N) "
if /i "%ch%"=="Y" del /q Backup\*.nls

:BACKUP_Files
echo n|>nul copy /-y "%windir%\system32\C*.nls" Backup\*.*
echo.
echo Backup completed.

:: Резервное копирование заменяемых кустов реестра
if not exist Backup\*.reg goto BACKUP_Registry
echo Warning: backup of processed keys has been already made earlier.
set ch=
set /p "ch=Would you like to remove it? (Y/N) "
if /i "%ch%"=="Y" del /q Backup\*.reg

:BACKUP_Registry
if not exist Backup\International_CU.reg  reg export "HKCU\Control Panel\International"                                  Backup\International_CU.reg
if not exist Backup\CodePage_LM.reg       reg export "HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage"                Backup\CodePage_LM.reg
if not exist Backup\CodePage_CU.reg       reg export "HKCU\SYSTEM\CurrentControlSet\Control\Nls\CodePage"                Backup\CodePage_CU.reg       2>NUL 1>&2
if not exist Backup\Font_LM.reg           reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" Backup\Font_LM.reg
if not exist Backup\Font_CU.reg           reg export "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" Backup\Font_CU.reg           2>NUL 1>&2
if not exist Backup\Console_CU.reg        reg export "HKCU\Console"                                                      Backup\Console_CU.reg
echo.

echo Pre-clean the registry keys ...

set "RootDelayed=%%SystemRoot%%"
::reg delete "HKCU\Control Panel\International"                                  /va /F
::reg delete "HKCU\SYSTEM\CurrentControlSet\Control\Nls\CodePage"                /F 2>NUL 1>&2
::reg delete "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /F 2>NUL 1>&2

::reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage"                /va /F
::reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /F

reg delete "HKCU\Console"                                                      /va /F
reg delete "HKCU\Console\%RootDelayed%_System32_cmd.exe"                       /va /F 2>NUL 1>&2
reg delete "HKCU\Console\%RootDelayed%_SysWOW64_cmd.exe"                       /va /F 2>NUL 1>&2

echo.
echo Replacing of registry entries...
reg import "Clean\International_CU.reg"
reg import "Clean\CodePage_LM.reg"
reg import "Clean\Font_LM.reg"

:: Продублируем
regedit /s "Clean\International_CU.reg"
regedit /s "Clean\CodePage_LM.reg"
regedit /s "Clean\Font_LM.reg"

echo.
echo Stady: replacing codepage files
echo.

if "%OSFamily%"=="Vista" (
  echo Saving access rights of NSL-files into DACL table
  icacls "%windir%\system32\C*.NLS" /save "Backup\CodePage.ACL" /C >nul
)
echo.
if "%OSFamily%"=="Vista" (
  echo Replacing owner into self
  takeown /f "%windir%\system32\C*.NLS" >nul
)
echo.
echo Taking full access rights
echo y|>nul cacls "%windir%\system32\C*.NLS" /e /g "%username%":f
echo.
echo Checking of *.NLS file damage and replacing it by original
echo.

For %%a in (Backup\*.*) do (
  if exist "Clean\%%~nxa" (
    fc /b "Clean\%%~nxa" "Backup\%%~nxa" || (
      echo Detected damage of "%%~nxa"
      if "%OSFamily%"=="Vista" sfc /SCANFILE="%windir%\system32\%%~nxa" | find " "
      fc /b "Clean\%%~nxa" "Backup\%%~nxa" || (
        ren "%windir%\system32\%%~nxa" "%%~nxa.bak"
        copy /y "Clean\%%~nxa" "%windir%\system32\%%~nxa"
        rem revert <- access denied for copy operation only
        if not exist "%windir%\system32\%%~nxa" ren "%windir%\system32\%%~nxa.bak" "%%~nxa"
      )
    )
  )
)

echo.
echo Reverting ownership into default - TrustedInstaller
if "%OSFamily%"=="Vista" (
  icacls "%windir%\system32\C*.NLS" /setowner "NT Service\TrustedInstaller" /C >nul
)
echo.
echo Restoring rights according to saved DACL table
echo.
if "%OSFamily%"=="Vista" (
  icacls "%windir%\system32" /restore "Backup\CodePage.ACL" /C >nul
)

echo Checking damage of font files
for /f "delims=" %%a in ('dir /b /a-d "%windir%\Fonts\*"') do (
  echo %%a
  sfc /SCANFILE="%windir%\Fonts\%%~nxa" | find " "
  set "Font_%%a=true"
)

for /f "skip=2 delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"') do call :ProcessRegLine "%%a"

:: Удаление переименованных файлов NLS после перезагрузки
set "key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\34"
::reg add "%key%" /f /v 1 /t REG_SZ /d "cmd /c del /f /q %windir%\system32\C*.NLS.bak"

:: Метка
reg add "%key%" /f /v 1 /t REG_SZ /d "cmd /c"

echo.
echo All operations are completed.
echo.
echo Windows rebooting is required.
set ch=
set /p "ch=Enter 1 and press ENTER to do it now: "
if "%ch%"=="1" shutdown -r -t 1
Exit /B

:GetOSLanguage [Install.Lang.Code] [Install.Lang.Name] [Program.Lang.Code] [Program.Lang.Name]
  :: Возвращает оригинальный язык установки системы в виде кода, а также язык, используемый для программ, не поддерживающих Юникод
  set "_key1=HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language"
  set "_key2=HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout\DosKeybCodes"
  For /f "tokens=2*" %%a In ('Reg.exe query "%_key1%" /v "InstallLanguage"^|Find "InstallLanguage"') do (
    set "%~1=%%~b"
    For /f "tokens=2*" %%c In ('Reg.exe query "%_key2%" /v "0000%%~b"^|Find "0000%%~b"') do set "%~2=%%~d"
  )
  For /f "tokens=2*" %%a In ('Reg.exe query "%_key1%" /v "Default"^|Find "Default"') do (
    set "%~3=%%~b"
    For /f "tokens=2*" %%c In ('Reg.exe query "%_key2%" /v "0000%%~b"^|Find "0000%%~b"') do set "%~4=%%~d"
  )
Exit /B

:GetSystemVersion [OSVersion] [OSBitness] [OSBuild] [OSFamily] [EnvironmentCore]
:: Определить версию ОС
:: %1-исх.Переменная для хранения названия ОС
:: %2-исх.Переменная для хранения разрядности ОС
:: %3-исх.Переменная для хранения версии сборки ОС
:: %4-исх.Переменная, идентифицирующая семейство ОС (9x, NT, Vista)
:: %5-исх.Переменная, идентифицирующая разрядность среды, из-под которой запущен скрипт
  Set "xOS=x64"& If "%PROCESSOR_ARCHITECTURE%"=="x86" If Not Defined PROCESSOR_ARCHITEW6432 Set "xOS=x32"
  set "%~2=%xOS%"
  set "%~5=x32"& if "%xOS%"=="x64" echo "%PROGRAMFILES%" |>nul find "x86" || set "%~5=x64"
  set "_key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
  For /f "tokens=2*" %%a In ('Reg.exe query "%_key%" /v "CurrentBuildNumber"^|Find "CurrentBuildNumber"') do set "%~3=%%~b"
  For /f "tokens=2*" %%a In ('Reg.exe query "%_key%" /v "CurrentVersion"^|Find "CurrentVersion"') do set "_ver=%%~b"
  For /f "tokens=2*" %%a In ('Reg.exe query "%_key%" /v "ProductName"^|Find "ProductName"') do set "%~1=%%~b"
  if "%_ver:~0,1%"=="6" (set "%~4=Vista") else (set "%~4=NT")
  if "%_ver:~0,2%"=="10" (set "%~4=Vista")
Exit /B

:ProcessRegLine
  set "Line=%~1"
  for /f "tokens=1*" %%a in ("%Line%") do (
    if "%%a"=="REG_SZ" (
      if not Defined Font_%%b (
        echo %%b
        sfc /SCANFILE="%windir%\Fonts\%%~nxb" | find " "
        sfc /SCANFILE="%%b" | find " "
      )
    ) else (
      if "%%b" neq "" call :ProcessRegLine "%%b"
    )
  )
Exit /B

*/new ActiveXObject('Shell.Application').ShellExecute (WScript.ScriptFullName,'Admin','','runas',1);