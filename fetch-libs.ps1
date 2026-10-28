 # Download public library JARs from Maven Central into the local ~/.m2 cache
# so the project can be compiled/run without a Maven CLI installation.
$ErrorActionPreference = "Stop"
$m2 = Join-Path $env:USERPROFILE ".m2\repository"
$base = "https://repo1.maven.org/maven2"

$artifacts = @(
    @{ dir = "org/apache/pdfbox/pdfbox/3.0.3";            file = "pdfbox-3.0.3.jar" },
    @{ dir = "org/apache/pdfbox/fontbox/3.0.3";           file = "fontbox-3.0.3.jar" },
    @{ dir = "com/google/zxing/core/3.5.3";               file = "core-3.5.3.jar" },
    @{ dir = "com/google/zxing/javase/3.5.3";             file = "javase-3.5.3.jar" }
)

foreach ($a in $artifacts) {
    $destDir = Join-Path $m2 $a.dir
    $dest = Join-Path $destDir $a.file
    if (Test-Path $dest) {
        Write-Host "[skip] $a.file already present" -ForegroundColor DarkGray
        continue
    }
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $url = "$base/$($a.dir)/$($a.file)"
    Write-Host "[get]  $url" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 60
        Write-Host "       OK ($((Get-Item $dest).Length) bytes)" -ForegroundColor Green
    } catch {
        Write-Host "       FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host "=== fetch complete ===" -ForegroundColor Cyan
