# Switches which Firebase config the Android build uses.
#
#   powershell -File tool\select_firebase.ps1 prod
#   powershell -File tool\select_firebase.ps1 demo
#
# Keep one file per environment next to the Android app:
#   android/app/google-services.prod.json   (Global Solar, project global-solar-2)
#   android/app/google-services.demo.json   (Solar Client App demo project)
#
# This copies the chosen one to android/app/google-services.json — the single
# file the Google Services Gradle plugin reads (it is gitignored, so every git
# branch shares whatever is currently there, hence this switcher).

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('prod', 'demo')]
    [string]$Env
)

$appDir = Join-Path $PSScriptRoot '..\android\app'
$src = Join-Path $appDir "google-services.$Env.json"
$dst = Join-Path $appDir 'google-services.json'

if (-not (Test-Path -LiteralPath $src)) {
    Write-Error "Missing $src - put the $Env google-services.json there first."
    exit 1
}

Copy-Item -LiteralPath $src -Destination $dst -Force

$json = Get-Content -LiteralPath $dst -Raw | ConvertFrom-Json
$pkg = if ($json.client) {
    $json.client[0].client_info.android_client_info.package_name
} else {
    '(none)'
}

Write-Host "Active Firebase config -> $Env"
Write-Host "  file    : android\app\google-services.json"
Write-Host "  package : $pkg"
