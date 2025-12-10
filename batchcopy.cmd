REM Copy files and directories from one location to another.
@echo off
setlocal enableextensions enabledelayedexpansion

rem [X] TODO 1: Create destination dirs AFTER confirming
rem [X] TODO 2: fix formatting 							
rem [ ] TODO 3: (IMPORTANT) Sanatize paths being input!!!

rem [ ] EDGE CASE 1: What to do with created dir after copying has failed?
rem [ ] EDGE CASE 2: How to handle empty input paths?
rem [ ] EDGE CASE 3: How to handle paths like "." or "../"?

:: Get source path
set /p source=Source: 
if NOT exist "%source%" (
	echo ERROR: Source path does not exist.
	exit /b 1
)

:: Get destination path
set /p destination=Destination: 
if "%destination%"=="%source%" (
	echo ERROR: Cannot copy dir to itself.
	exit /b 1
)
if NOT exist "%destination%" (
	echo.
	echo Destination path does not exist. Create one?
	
	call :confirm
	
	:: No
	if !errorlevel!==1 (
		echo.
		echo Aborting batch job...
		exit /b 1

	) else (
		:: Yes
		set /A shouldMakeDestDir=1
		echo.
		echo Planned dir creation...
	)
)

:: Confirm with user
echo.
echo Are you sure you want to copy "%source%" to "%destination%"?
call :confirm

:: If no
if %errorlevel%==1 (
	echo.
	echo Aborting batch job...
	exit /b 1
)

:: Create destination if needed
if defined shouldMakeDestDir (
	call :createDestination
	
	if %errorlevel%==0 (
		echo.
		echo Successfully created destination.
	) else (
		echo.
		echo ERROR: Failed to create destination.
		exit /b 1
	)
)

:: Copy files
call :copy
echo.
echo Robocopy returned %errorlevel%
echo.

:: Report status
if %errorlevel% equ 0 ( echo No files were copied. They already exist in destination dir.)
if %errorlevel% equ 1 ( echo All files copied successfully.)
if %errorlevel% equ 2 ( echo No files copied. Additional files exist in destination dir.)
if %errorlevel% equ 3 ( echo Some files copied. Additional files were present.)
if %errorlevel% equ 5 ( echo Some files copied. Some files were mismatched.)
if %errorlevel% equ 6 ( echo No files copied. Additional and mismatched files exist in destination dir.)
if %errorlevel% equ 7 ( echo Files copied. Mismatched and additional files were present.)
if %errorlevel% equ 8 ( echo ERROR: Several files failed to copy.)
if %errorlevel% gtr 8 ( echo ERROR: Some failure has occured. Read copylog.log)

:: Exit
if %errorlevel% geq 8 (
	exit /b 1
)
exit /b 0

:: ------------------------------------
:: Quasi "funcions"
:: ------------------------------------
:confirm
setlocal
set /P userConfirmed=Please enter y or n: 
if /I "%userConfirmed%"=="y" (
	endlocal & exit /b 0
)
if /I "%userConfirmed%"=="n" (
	endlocal & exit /b 1
) else (
	endlocal
	goto :confirm
)

:createDestination
echo.
echo Creating destination "%destination%"...
mkdir "%destination%"
exit /b %errorlevel%

:copy
echo.
echo Copying "%source%" to "%destination%"...
echo.
robocopy %source% %destination% /E /mt:16 /V /LOG+:"copylog.log"
exit /b %errorlevel%