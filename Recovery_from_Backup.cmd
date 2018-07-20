@set @x=0; /*
@echo off
echo Patch for recovering original files of Russian codepage and standart console settings v.2.5
echo.
echo !!! Roll back mode !!!
echo.
SetLocal EnableExtensions EnableDelayedExpansion
echo.
echo.
echo Checking for last installation completion.
set "key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\34"
reg query "%key%" /v 1 >NUL && (
  echo ERROR.
  echo.
  echo You should restart the system before starting the roll back.
  echo.
  pause& Exit /B
) || (
  echo OK
)
echo.
echo Cheking of system localization.
:: Проверка, является ли система локализованной
call :GetOSLanguage Install.Lang.Code Install.Lang.Name Program.Lang.Code Program.Lang.Name
echo.
echo OS installation language:            %Install.Lang.Name% [%Install.Lang.Code%]
echo Language for non-unicode programs:   %Program.Lang.Name% [%Program.Lang.Code%]
echo.
if "%Install.Lang.Code%" neq "0419" if "%Program.Lang.Code%" neq "0419" (
  echo Warning: only Russian, Belarussian and Ukrainian localizations are supported. Also the systems with MUI.
  echo.
  pause& Exit /B
) else (
  echo OK
)
echo.
:: Проверка версии ОС
ver
If /i "%PROCESSOR_ARCHITECTURE%"=="x86" (set "Core=x32") else (set "Core=x64")
set /p "=Bittness: %Core% "<nul
ver |>NUL find "6." && set "Family=Vista" || set "Family=NT"

:: Получаем права Администратора
if "%Family%"=="Vista" if "%1"=="" (cscript.exe //nologo //e:jscript "%~f0"& Exit /B)
echo Admin rights granted.

:: Переходим в папку с Batch-файлом
cd /d "%~dp0"

echo.
::ping 127.1 -n 3 >NUL

::echo Предварительная очистка разделов реестра...

::reg delete "HKCU\Control Panel\International" /F
::reg delete "HKCU\SYSTEM\CurrentControlSet\Control\Nls\CodePage" /F >NUL 2>&1
::reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage" /F
::reg delete "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /F >NUL 2>&1
::reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /F
::reg delete "HKCU\Console" /F

echo.
echo Recovering registry entries....
For %%a in (Backup\*.reg) do reg import "Backup\%%~nxa" & regedit /s "%~dp0Backup\%%~nxa"

::ping 127.1 -n 3 >NUL

goto SKIPBLOCK

echo.
echo Stady: recovering of codepage files
echo.
echo.

echo Take ownership
takeown /f "%windir%\system32\C*.NLS" >nul
echo.
echo Take full access rights
echo y|>nul cacls "%windir%\system32\C*.NLS" /e /g "%username%":f
echo.
echo Procedure of replacing files has started...
echo.
:: Переименовую все *.NLS в *.NLS_, чтобы обойти блокировку доступа к файлам, имеющим открытые дескрипторы
echo Renaming...
ren "%windir%\system32\C*.NLS" *.NLS_
echo.
echo Copying...
copy /y "*.NLS" "%windir%\system32\*.*" >nul
echo.
echo Reverting ownership into default - TrustedInstaller
if "%Family%"=="Vista" icacls "%windir%\system32\C*.NLS" /setowner "NT Service\TrustedInstaller" /C >nul
echo.
echo Restoring rights according to saved DACL table
echo.
icacls "%windir%\system32" /restore "CodePage.ACL" /C >nul

:: Удаление переименованных файлов NLS после перезагрузки
::set "key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\34"
::reg add "%key%" /f /v 1 /t REG_SZ /d "cmd /c del /f /q %windir%\system32\C*.NLS_"

:SKIPBLOCK

echo.
echo All operations are completed.
echo.
echo Windows rebooting is required.
set ch=
set /p "ch=Enter 1 to continue: "
if "%ch%"=="1" shutdown -r -t 1

pause& Exit /B

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

*/new ActiveXObject('Shell.Application').ShellExecute (WScript.ScriptFullName,'Admin','','runas',1);