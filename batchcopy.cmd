REM Copy files and directories from one location to another.
@echo off
setlocal enableextensions enabledelayedexpansion
echo.

rem [ ] TODO 4: Figure how to check if directory is empty (:undoDirectory)

rem [ ] EDGE CASE 1: What to do for each error code from Robocopy?
rem [ ] EDGE CASE 2: What to do with created dir after copying has failed?
rem [ ] EDGE CASE 3: How to handle empty input paths?
rem [ ] EDGE CASE 4: How to handle paths like "." or "../"?
rem [ ] EDGE CASE 5: What to do if destination is non-empty?

:: ----------------------------------------------------------------------------
:: Get source path
:: ----------------------------------------------------------------------------
set /p source=Source: 

:: Remove quotes
set source=%source:"=%
set source=%source:'=%

:: Remove trailing and leading slashes
:rmTrailingSlashes_src
if "%source:~-1%"=="\" ( set "source=%source:~0,-1%" & goto :rmTrailingSlashes_src)

:rmLeadingSlashes_src
if "%source:~0,1%"=="\" ( set "source=%source:~1%" & goto :rmLeadingSlashes_src)

if NOT exist "%source%" (
	echo ERROR: Source path does not exist.
	exit /b 1
)

:: ----------------------------------------------------------------------------
:: Get destination path
:: ----------------------------------------------------------------------------
set /p destination=Destination: 

:: Remove quotes
set destination=%destination:"=%
set destination=%destination:'=%

:: Remove trailing and leading slashes
:rmTrailingSlashes_dest
if "%destination:~-1%"=="\" ( set "destination=%destination:~0,-1%" & goto :rmTrailingSlashes_dest)

:rmLeadingSlashes_dest
if "%destination:~0,1%"=="\" ( set "destination=%destination:~1%" & goto :rmLeadingSlashes_dest)

if "%destination%"=="%source%" (
	echo ERROR: Cannot copy into same directory.
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
		echo Planning directory creation...
	)
)

:: ----------------------------------------------------------------------------
:: Confirm with user
:: ----------------------------------------------------------------------------
echo.
echo Are you SURE you want to copy "%source%" to "%destination%"?
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

:: ----------------------------------------------------------------------------
:: Copy files
:: ----------------------------------------------------------------------------
call :copy
echo.
echo Robocopy returned %errorlevel%
echo.

:: Report status
if %errorlevel% equ 0 ( echo No files were copied. They already exist in destination dir.)
if %errorlevel% equ 1 ( echo All files copied successfully!)
if %errorlevel% equ 2 ( echo No files copied. Additional files exist in destination dir.)
if %errorlevel% equ 3 ( echo Some files copied. Additional files were present.)
if %errorlevel% equ 5 ( echo Some files copied. Some files were mismatched.)
if %errorlevel% equ 6 ( echo No files copied. Additional and mismatched files exist in destination dir.)
if %errorlevel% equ 7 ( echo Files copied. Mismatched and additional files were present.)
if %errorlevel% equ 8 ( echo ERROR: Several files failed to copy.)
if %errorlevel% gtr 8 ( echo ERROR: Some failure has occured. Read copylog.log)

:: Exit
if %errorlevel% geq 8 (
	:: If error occured, delete created dir
	call :undoDirectory
	exit /b 1
)
exit /b 0

:: ----------------------------------------------------------------------------
:: Quasi "funcions"
:: ----------------------------------------------------------------------------
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
rem DEBUG: passed /L flag to run in test mode; don't copy, only log
robocopy "%source%" "%destination%" /E /mt:16 /V /LOG+:"copylog.log" /L
exit /b %errorlevel%
rem DEBUG: return error code 8
rem exit /b 8

:undoDirectory
echo.
echo Deleting destination "%destination%"...
echo.
:: Check if it still exists
if not exist "%destination%" (
	echo ERROR: Failed to delete destination. Couldn't find directory.
	exit /b 1
)
:: Check if empty
dir "%destination%" /b >nul 2>&1
if %errorlevel%==0 (
    echo ERROR: Failed to delete destination. Directory not empty.
    exit /b 1
)
:: Delete directory
rmdir "%destination%"
if not %errorlevel%==0 (
	echo ERROR: Failed to delete destination. RMDIR returned %errorlevel%
	exit /b 1
)
echo Destination deleted successfully.
exit /b 0