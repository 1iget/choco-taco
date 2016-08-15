
# Keep Private 
function Get-NginxProfileConfig() {
    param()

    if((Get-Command Get-BadMishkaProfile -ErrorAction SilentlyContinue) -eq $null) {
        $configJsonPath = "$env:USERPROFILE/.badmishka"
    } else {
        $configJsonPath = Get-BadMishkaProfile 
    }

    return "$configJsonPath/nginx.json"
}

function Read-NginxUserSettings() {
    param()
    
    $configJsonPath = Get-NginxProfileConfig
    
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

function Write-NginxUserSettings() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $Settings
    )

    $configJsonPath = Get-NginxProfileConfig

    $json =  $Settings | ConvertTo-Json -Depth 5 
    [System.IO.File]::WriteAllText($configJsonPath, $json)

    return
}

function Set-NginxPath() {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Path 
    )

    $settings = Read-NginxUserSettings
    $settings.path = $Path 

    $settings | Write-NginxUserSettings
}

function Start-Nginx() {
    param(
        [string] $Path
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        if($settings.path -eq $Null) {
            Write-Error "Specify a Path with the function or use Set-NginxPath"
        }

        $Path = $settings.path 
    }

    $resolvedPath = (Resolve-Path $Path).Path 
    $exe = "$resolvedPath\nginx.exe"
    $info = New-Object System.Diagnostics.ProcessStartInfo($exe)
    $info.WorkingDirectory = $Path 
    return [System.Diagnostics.Process]::Start($info)
}

function Stop-Nginx() {
    
    param(
        [string] $Path 
    )

    if([string]::IsNullOrEmpty($Path)) {
        $settings = Read-NginxUserSettings
        $Path = $settings.path 
    }

    if(-not [string]::IsNullOrWhiteSpace($Path)) {
        $exe = "$Path\nginx.exe"
        & $exe -s stop
        sleep 5 
    }

    Get-Process nginx | Stop-Process
}

