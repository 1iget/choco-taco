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
$targetRootDir = "$appPath/nginx" 
$version = $config.version
$targetDir = "$targetRootDir/$version"
$tempDir =  "${env:TEMP}/chocolatey/nginx/$version" 
$symlinkDir = "$targetRootDir/current"


$targetDir = (Resolve-Path $targetDir).Path 

if(Test-Path $tempDir) {
    Remove-Item $tempDir -Force -Recurse | Write-Debug
}

if(Test-Path $targetDir) {
    Remove-Item $targetDir -Force -Recurse | Write-Debug
}

$folders = gci $targetRootDir -Directory
if($folders.Length -gt 0) {
    if($folders.Length -le 1 -and (Test-Path $symlinkDir)) {
        Remove-Item "$symlinkDir" -Force 
    } elseif ((Test-Path $symlinkDir)) {
        $folders = ($folders | sort-object name)
        $nextVersion = $folders[-1]
        Remove-Item "$symlinkDir" -Force 
        cmd /c mklink /D  "`"$symlinkDir`"" "`"$nextVersion`"" | Write-Debug
    }
}