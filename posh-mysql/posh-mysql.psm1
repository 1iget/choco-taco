


# Keep Private 
function Get-MysqlProfileConfig() {
    param()

    if((Get-Command Get-BadMishkaProfile -ErrorAction SilentlyContinue) -eq $null) {
        $configJsonPath = "$env:USERPROFILE/.badmishka"
    } else {
        $configJsonPath = Get-BadMishkaProfile 
    }

    return "$configJsonPath/mysql.json"
}


function Read-MySqlUserSettings() {
    param()

 $configJsonPath = Get-MysqlProfileConfig
    
    if(-not (Test-Path $configJsonPath)) {
        $json = "{`"path`": null}"
        $dir = Split-Path $configJsonPath
        if(-not (Test-Path $dir)) {
            mkdir $dir | Write-Debug
        }
        [System.IO.File]::WriteAllText($configJsonPath, $json)

        return (ConvertFrom-Json $json)
    }

    $json = [System.IO.File]::ReadAllText($configJsonPath)
    return (ConvertFrom-Json $json)
}

function Write-MySqlUserSettings() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $Settings
    )

     $configJsonPath = Get-MySqlProfileConfig
    $json =  $Settings | ConvertTo-Json -Depth 5 
    [System.IO.File]::WriteAllText($configJsonPath, $json)

    return
}

function Set-MysqlPath() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Path 
    )

    $settings = Read-NginxUserSettings
    $settings.path = $Path 

    $settings | Write-NginxUserSettings
}

function Start-Mysqld() {
    param(
        [string] $Path,
        [string] $Config = "my-defaults.ini"
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        if($settings.path -eq $Null) {
            Write-Error "Specify a Path with the function or use Set-NginxPath"
        }

        $Path = $settings.path 
    }

    $resolvedPath = (Resolve-Path $Path).Path 
    $exe = "$resolvedPath\bin\mysqld.exe"
    $info = New-Object System.Diagnostics.ProcessStartInfo($exe)
    $info.WorkingDirectory = $Path 
    $info.Arguments = "--defaults-file=`"$resolvedPath\$Confg`""
    return [System.Diagnostics.Process]::Start($info)
}

function Start-Mysql() {
    param(
        [string] $Path,
        [string] $User = "root",
        [string] $Password = ""
    )

     if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        if($settings.path -eq $Null) {
            Write-Error "Specify a Path with the function or use Set-MysqlPath"
        }

        $Path = $settings.path 
    }

    $resolvedPath = (Resolve-Path $Path).Path 
    $exe =  "$resolvedPath\bin\mysql.exe"
    Write-Host "$exe -u $User";
    & $exe -u $User -p $Password;
}

function Start-Mysqld() {
    param(
        [string] $Path,
        [string] $Config = "my-default.ini"
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        if($settings.path -eq $Null) {
            Write-Error "Specify a Path with the function or use Set-NginxPath"
        }

        $Path = $settings.path 
    }

    $resolvedPath = (Resolve-Path $Path).Path 
    $exe = "$resolvedPath\bin\mysqld.exe"

    $info = New-Object System.Diagnostics.ProcessStartInfo($exe)
    $info.WorkingDirectory = $Path 
    $info.Arguments = "--defaults-file=`"$resolvedPath\$Config`" --console"
    $info.CreateNoWindow = $true 
    $info.UseShellExecute = $false
    return [System.Diagnostics.Process]::Start($info)
}

function Stop-MySqld() {
    
    param(
        [string] $Path 
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        $Path = $settings.path 
    }

    Get-Process mysqld | Stop-Process
}