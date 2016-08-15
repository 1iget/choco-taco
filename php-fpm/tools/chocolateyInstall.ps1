
if((Get-Command Get-WebFile -ErrorAction SilentlyContinue) -eq $null) {
    Write-Debug "Get-WebFile not found in the current session.";
    if(-not (Test-Path Env:\ChocolateyInstall)) {
        Write-Error "ChocolateyInstall environment variable not found.";
        return;
    }
    
    Import-Module ("$Env:ChocolateyInstall/helpers/chocolateyInstaller.psm1")
}


$toolsDir = Split-Path $MyInvocation.MyCommand.Path 
$appPath = Get-ToolsLocation
$json = [System.IO.File]::ReadAllText("$toolsDir/kweh.json")
$config = ConvertFrom-Json $json 
$packageName = $config.id
$targetRootDir = "$appPath/$packageName" 
$version = $config.version
$targetDir = "$targetRootDir/$version"
$tempDir =  "${env:TEMP}/chocolatey/$packageName/$version"
$zip =  "$tempDir/$packageName.zip"
$7z = "$Env:ChocolateyInstall/tools/7z.exe"  
$symlinkDir = "$targetRootDir/current"


if(-not (Test-Path $7z)) {
    $7z = "$Env:ChocolateyInstall/tools/7za.exe"

    if(-not (Test-Path $7z)) {
        Write-Error "7zip is not found";
        return
    }
}

if(-not (Test-Path $targetRootDir)) {
    mkdir $targetRootDir | Write-Debug
}

if(-not (Test-Path $targetDir)) {
    mkdir $targetDir | Write-Debug
}

if(-not (Test-Path $tempDir)) {
    mkdir $tempDir | Write-Debug
}

if(-not (Test-Path $zip)) {
    Get-WebFile -Url ($config.install.url) -Path $zip 
} 

$targetDir = (Resolve-Path $targetDir).Path 
if(Test-Path $targetDir) {
    Remove-Item $targetDir -Force -Recurse
}

& $7z x $zip -o"$targetDir" | Write-Debug

if(-not (Test-Path $symlinkDir)) {
    cmd /c mklink /D  "`"$symlinkDir`"" "`"$targetDir`"" | Write-Debug
}

if(-not (Test-Path "$targetDir\php.ini")) {
    Copy-Item "$targetDir\php.ini-production" "$targetDir\php.ini"

    $txt = [System.IO.File]::ReadAllText("$targetDir\php.ini")
    $txt = $txt.Replace(";extension_dir =", "extension_dir = `"$targetDir/ext`"") 
    $txt = $txt.Replace(";extension=php_bz2.dll",        "extension=php_bz2.dll");
    $txt = $txt.Replace(";extension=php_curl.dll",       "extension=php_curl.dll");
    $txt = $txt.Replace(";extension=php_gd2.dll",        "extension=php_gd2.dll");
    $txt = $txt.Replace(";extension=php_mysqli.dll",     "extension=php_mysqli.dll");
    $txt = $txt.Replace(";extension=php_pdo_mysql.dll",  "extension=php_pdo_mysql.dll");
    $txt = $txt.Replace(";extension=php_soap.dll",       "extension=php_soap.dll");
    $txt = $txt.Replace(";extension=php_sockets.dll",    "extension=php_sockets.dll");
    $txt = $txt.Replace(";extension=php_tidy.dll",       "extension=php_tidy.dll");
    $txt = $txt.Replace(";extension=php_xmlrpc.dll",     "extension=php_xmlrpc.dll");
    $txt = $txt.Replace(";extension=php_xsl.dll",        "extension=php_xsl.dll");

    [System.IO.File]::WriteAllText("$targetDir\php.ini", $txt)
}