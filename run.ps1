# PowerShell Launcher for Railway Reservation System
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "                RAILWAY RESERVATION SYSTEM LAUNCHER                 " -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan

# Check Java
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "[INFO] Detected Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Java is not installed or not in system PATH." -ForegroundColor Red
    pause
    exit 1
}

$m2 = "$env:USERPROFILE\.m2\repository"
$cp = "target\classes;target\test-classes;$m2\org\mindrot\jbcrypt\0.4\jbcrypt-0.4.jar;$m2\com\mysql\mysql-connector-j\8.3.0\mysql-connector-j-8.3.0.jar;$m2\mysql\mysql-connector-java\8.0.28\mysql-connector-java-8.0.28.jar"

# Compile if needed
if (-not (Test-Path "target\classes\com\railway\RailwayApp.class")) {
    Write-Host "[INFO] Compiling Java classes..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "target\classes" | Out-Null
    $files = Get-ChildItem -Path "src\main\java" -Filter "*.java" -Recurse | ForEach-Object { $_.FullName }
    [System.IO.File]::WriteAllLines("sources.txt", $files, [System.Text.Encoding]::ASCII)
    javac -cp $cp -d target\classes @sources.txt
    Remove-Item "sources.txt"
    Write-Host "[INFO] Compilation completed successfully." -ForegroundColor Green
}

Write-Host "[INFO] Launching Railway Reservation System Desktop GUI..." -ForegroundColor Cyan
java -cp $cp com.railway.RailwayApp

