# Reusable compile/verify helper for the Railway Reservation System.
# Uses locally cached Maven dependencies in ~/.m2 (no Maven CLI required).
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$m2 = Join-Path $env:USERPROFILE ".m2\repository"

function Lib($group, $artifact, $ver) {
    $p = Join-Path $m2 (Join-Path $group (Join-Path $artifact (Join-Path $ver "$artifact-$ver.jar")))
    return $p
}

$libs = @(
    (Lib "org/mindrot" "jbcrypt" "0.4"),
    (Lib "com/mysql" "mysql-connector-j" "8.3.0"),
    (Lib "org/apache/pdfbox" "pdfbox" "3.0.3"),
    (Lib "org/apache/pdfbox" "fontbox" "3.0.3"),
    (Lib "com/google/zxing" "core" "3.5.3"),
    (Lib "com/google/zxing" "javase" "3.5.3")
)

$missing = @()
foreach ($l in $libs) { if (-not (Test-Path $l)) { $missing += $l } }

$out = Join-Path $root "target\verify"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$cp = "$out;" + ($libs -join ";")
$srcFile = Join-Path $root "sources.txt"

# Gather main sources
$mainFiles = Get-ChildItem -Path (Join-Path $root "src\main\java") -Filter "*.java" -Recurse | ForEach-Object { $_.FullName }
[System.IO.File]::WriteAllLines($srcFile, $mainFiles, [System.Text.Encoding]::ASCII)

Write-Host "=== Compiling MAIN sources ===" -ForegroundColor Cyan
if ($missing.Count -gt 0) {
    Write-Host "[WARN] Missing libs (compile may fail for those features):" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  $_" }
}
cmd /c "javac -cp `"$cp`" -d `"$out`" @`"$srcFile`" 2>&1"
$mainExit = $LASTEXITCODE
Write-Host "MAIN exit code: $mainExit" -ForegroundColor $(if ($mainExit -eq 0) {"Green"} else {"Red"})

# Gather test sources (optional)
$testDir = Join-Path $root "src\test\java"
if (Test-Path $testDir) {
    $testFiles = Get-ChildItem -Path $testDir -Filter "*.java" -Recurse | ForEach-Object { $_.FullName }
    [System.IO.File]::WriteAllLines($srcFile, $testFiles, [System.Text.Encoding]::ASCII)
    Write-Host "=== Compiling TEST sources ===" -ForegroundColor Cyan
    $testCp = "$out;$m2\org\junit\jupiter\junit-jupiter-api\5.10.2\junit-jupiter-api-5.10.2.jar;$m2\org\junit\platform\junit-platform-commons\1.10.2\junit-platform-commons-1.10.2.jar;$m2\org\opentest4j\opentest4j\1.3.0\opentest4j-1.3.0.jar;$m2\org\apiguardian\apiguardian-api\1.1.2\apiguardian-api-1.1.2.jar"
    cmd /c "javac -cp `"$testCp`" -d `"$out`" @`"$srcFile`" 2>&1"
    $testExit = $LASTEXITCODE
    Write-Host "TEST exit code: $testExit" -ForegroundColor $(if ($testExit -eq 0) {"Green"} else {"Red"})
}
Remove-Item $srcFile -ErrorAction SilentlyContinue
Write-Host "=== Done ===" -ForegroundColor Cyan
