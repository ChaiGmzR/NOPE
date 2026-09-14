$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidRoot = Join-Path $projectRoot "android"
$keyPath = Join-Path $androidRoot "app\nope-release.jks"
$propertiesPath = Join-Path $androidRoot "key.properties"
$credentialsPath = Join-Path $androidRoot "SIGNING-CREDENTIALS.txt"

if ((Test-Path -LiteralPath $keyPath) -or
    (Test-Path -LiteralPath $propertiesPath) -or
    (Test-Path -LiteralPath $credentialsPath)) {
    throw "Signing files already exist. Refusing to replace the release identity."
}

$randomBytes = New-Object byte[] 36
[Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
$password = [Convert]::ToBase64String($randomBytes).TrimEnd("=").Replace("+", "A").Replace("/", "B")
$keytool = (Get-Command keytool -ErrorAction Stop).Source

& $keytool `
    -genkeypair `
    -v `
    -keystore $keyPath `
    -storepass $password `
    -keypass $password `
    -alias "nope-release" `
    -keyalg RSA `
    -keysize 4096 `
    -validity 10000 `
    -dname "CN=NOPE, OU=Mobile, O=NOPE, L=Mexico City, ST=CDMX, C=MX"

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE"
}

$properties = @(
    "storePassword=$password"
    "keyPassword=$password"
    "keyAlias=nope-release"
    "storeFile=nope-release.jks"
)
[IO.File]::WriteAllLines($propertiesPath, $properties)

$credentials = @(
    "NOPE Android release signing"
    ""
    "Alias: nope-release"
    "Password: $password"
    "Keystore: android/app/nope-release.jks"
    ""
    "BACK UP THIS FILE AND THE KEYSTORE TOGETHER."
    "Without them, Android cannot install future NOPE releases as updates."
)
[IO.File]::WriteAllLines($credentialsPath, $credentials)

Write-Output "Release signing identity created. Credentials remain local and are ignored by Git."
