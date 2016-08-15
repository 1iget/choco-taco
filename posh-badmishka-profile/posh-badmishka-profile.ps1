

function Set-BadMishkaProfileLocation() {
    param(
        [string] $Path = "$env:USERPROFILE",
        [switch] $PerUser
    ) 

    $Path = "$Path\.badmishka"

    if($PerUser.ToBool()) {
        setx BadMishkaProfile $Path 
    } else {
        setx BadMishkaProfile $Path /M
    }

    $env:BadMishkaProfile = $Path 
}

function Get-BadMishkaProfileLocation() {

    if(-not (Test-Path env:\BadMishkaProfile)) {
        $env:BadMishkaProfile = "$env:USERPROFILE\.badmishka"
    }
    
    return  $env:BadMishkaProfile;
}

function New-BadMishkaPassword() {
    Param(
        [int] $Length = 16
    )

    Write-Host "Length $Length"
    $characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz$#@[]!+-".ToCharArray()
    $password = New-Object Char[]($Length)
    $bytes = new-object byte[] $Length

    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)

    Write-Host $bytes.Length;

    for($i = 0; $i -lt $Length; $i++) {
        $randomIndex = $bytes[$i] % $characters.Length;
        $password[$i] = $characters[$randomIndex];
    }

    return [string]::Join('', $password)
}