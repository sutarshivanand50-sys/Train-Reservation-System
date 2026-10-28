@echo off
setlocal enabledelayedexpansion
title Railway Reservation System Launcher

:: Change directory to the folder containing this batch script
cd /d "%~dp0"

echo =====================================================================
echo                RAILWAY RESERVATION SYSTEM LAUNCHER
echo =====================================================================

:: Check for Java installation
where java >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Java is not found in your system PATH.
    echo Please install Java 17+ or add Java to your PATH environment variable.
    pause
    exit /b 1
)

:: Locate M2 repository and set classpath
set "M2_DIR=%USERPROFILE%\.m2\repository"
set "CP=target\classes;target\test-classes;%M2_DIR%\org\mindrot\jbcrypt\0.4\jbcrypt-0.4.jar;%M2_DIR%\com\mysql\mysql-connector-j\8.3.0\mysql-connector-j-8.3.0.jar;%M2_DIR%\mysql\mysql-connector-java\8.0.28\mysql-connector-java-8.0.28.jar"

:: Compile if class files are missing
if not exist "target\classes\com\railway\RailwayApp.class" (
    echo [INFO] Compiling Java classes for the first run...
    if not exist "target\classes" mkdir "target\classes"
    dir /s /b src\main\java\*.java > sources.txt
    javac -cp "%CP%" -d target\classes @sources.txt
    if %errorlevel% neq 0 (
        echo [ERROR] Compilation failed.
        del sources.txt
        pause
        exit /b 1
    )
    del sources.txt
    echo [INFO] Compilation successful.
)

echo [INFO] Starting Railway Reservation Desktop Application...
java -cp "%CP%" com.railway.RailwayApp

if %errorlevel% neq 0 (
    echo.
    echo [NOTICE] Application terminated with exit code %errorlevel%.
)

pause
