
$configJsonPath = "$env:USERPROFILE/.badmishka/php-fpm.json"

function Read-PhpFpmUserSettings() {
    param()

    
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

function Write-PhpFpmUserSettings() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $Settings
    )

    $json =  $Settings | ConvertTo-Json -Depth 5 
    [System.IO.File]::WriteAllText($configJsonPath, $json)

    return
}

function Set-PhpFpmPath() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Path 
    )

    $settings = Read-NginxUserSettings
    $settings.path = $Path 

    $settings | Write-NginxUserSettings
}

function Start-PhpFpm() {
    param(
        [string] $Path,
        [string] $Address = "127.0.0.1:9000"
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        if($settings.path -eq $Null) {
            Write-Error "Specify a Path with the function or use Set-NginxPath"
        }

        $Path = $settings.path 
    }

    $resolvedPath = (Resolve-Path $Path).Path 
    $exe = "$resolvedPath\php-cgi.exe"
    $info = New-Object System.Diagnostics.ProcessStartInfo($exe)
    $info.Arguments = "-b $Address"
    $info.WorkingDirectory = $Path 
    $info.UseShellExecute = $false 
    $info.CreateNoWindow = $true;
    return [System.Diagnostics.Process]::Start($info)
}

function Stop-PhpFpm() {
    
    param(
        [string] $Path 
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        $Path = $settings.path 
    }

    if(-not [string]::IsNullOrWhiteSpace($Path)) {
        $exe = "$Path\php-cgi.exe"
        & $exe -s stop
        sleep 5 
    }

    Get-Process php-cgi | Stop-Process
}