
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
$extractDir = "$tempDir/$packageName-$version"
if(Test-Path $extractDir) {
    Remove-Item $extractDir -Force -Recurse 
}
& $7z x $zip -o"$tempDir" | Write-Debug
Copy-Item "$extractDir/*" $targetDir -Force -Recurse
Remove-Item $extractDir -Force -Recurse

if(-not (Test-Path $symlinkDir)) {
    cmd /c mklink /D  "`"$symlinkDir`"" "`"$targetDir`"" | Write-Debug
}

# TODO: create sites-enabled folder & inject include that references that folder 
# http {
#    include       mime.types;
#    include "c:/apps/nginx/[version]/conf/sites-enabled/*.conf";