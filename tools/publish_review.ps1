[CmdletBinding()]
param(
    [string]$PythonPath = "python",
    [string]$SofficePath = "C:\Program Files\LibreOffice\program\soffice.com",
    [string]$OutputDirectory = ".build\review"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputDirectory))
$buildRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot ".build"))

if (-not $outputRoot.StartsWith($buildRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw "OutputDirectory must resolve beneath $buildRoot"
}
if (-not (Test-Path -LiteralPath $SofficePath -PathType Leaf)) {
    throw "soffice.com was not found at $SofficePath"
}

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $outputRoot | Out-Null

$profilePath = Join-Path $outputRoot "libreoffice-profile"
New-Item -ItemType Directory -Path $profilePath | Out-Null
$profileUri = ([System.Uri]$profilePath).AbsoluteUri
$docxPath = Join-Path $repositoryRoot "Atlas_Enterprise_Platform_Course_Review_Edition.docx"
$pdfPath = Join-Path $outputRoot "Atlas_Enterprise_Platform_Course_Review_Edition.pdf"

& $PythonPath (Join-Path $PSScriptRoot "generate_review_docx.py")
if ($LASTEXITCODE -ne 0) { throw "DOCX generation failed with exit code $LASTEXITCODE" }

& $SofficePath --headless "-env:UserInstallation=$profileUri" --convert-to pdf --outdir $outputRoot $docxPath
if ($LASTEXITCODE -ne 0) { throw "LibreOffice conversion failed with exit code $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $pdfPath -PathType Leaf)) { throw "LibreOffice did not produce $pdfPath" }

& $PythonPath (Join-Path $PSScriptRoot "rasterize_review_pdf.py") $pdfPath $outputRoot --scale 2.0
if ($LASTEXITCODE -ne 0) { throw "PDF rasterization failed with exit code $LASTEXITCODE" }

& $PythonPath (Join-Path $PSScriptRoot "verify_review_render.py") $pdfPath $outputRoot
if ($LASTEXITCODE -ne 0) { throw "Render verification failed with exit code $LASTEXITCODE" }

Write-Output "Publishing pipeline completed. Inspect every page PNG in $outputRoot before release."
