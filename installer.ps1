<#

.SYNOPSIS
A script for IT Admins in smaller companies to automate their software deplopyments on a per-machine basis.

.DESCRIPTION
This installer script is used to automate multiple software download and installs on a local machine. It downloads from the source specified in schema.json and outputs the downloaded files to C:\Windows\Tasks. Arguments are also specified in schema.json, default is "/passive" for silent installs. Change this to "/?" if you are adding your own sources and need to test them.

This installer script can also be used to download and install Lenovo Commercial Vantage, which is particularly useful in deployment of a generalized Windows image. See EXAMPLE for how-to's.

.EXAMPLE
PS> .\installer.ps1 box

.EXAMPLE
PS> .\installer.ps1 -Software slack, egnyte

.EXAMPLE
PS> .\installer.ps1 -Vantage $True

.EXAMPLE
PS> .\installer.ps1 webex -Vantage $True

.PARAMETER Software
Specify the software you want to download and install. Valid choices are "box, egnyte, slack, and/or webex". Mutiple values must be separated by commas, see EXAMPLE.

.PARAMETER Vantage
Optional, default is false. If true, Lenovo Commercial Vantage will be downloaded, unzipped, and installed locally. See EXAMPLE.

.NOTES
Installer (c) 2022 Rich Wright [HudsonOnHere]

This software is provided "as is" with no warranties or guarantees of any kind.
See LICENSE for the full terms.

#>


#Requires -RunAsAdministrator

Param(

    [Parameter(Position = 0)]
    [ValidateSet('Box', 'Egnyte', 'Slack', 'Webex')]
    [string[]]$Software,
    [bool]$Vantage = $false

)


$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptPathParent = Split-Path $ScriptPath -Parent
$SchemaPath = $ScriptPathParent + "\schema.json"
$Schema = Get-Content $SchemaPath -raw | ConvertFrom-Json


foreach ($i in $Software) {

    $Source = $Schema.software.$i.source
    $OutFile = $Schema.software.$i.destination
    $Arguments = $Schema.software.$i.arguments


    Write-Host "Starting a BITS transfer for $i"
    Start-BitsTransfer -DisplayName $i -Source $Source -Destination $OutFile

    # Start-Process $OutFile -ArgumentList $Arguments
    # Wait-Process (Get-Process -Name "msiexec").Id
    Write-Host "Starting to install $i"
    $Process = Start-Process $OutFile -ArgumentList $Arguments -PassThru
    Wait-Process $Process.Id

    Write-Host "Cleaning up..."
    Remove-Item -Path $OutFile -Force -Confirm:$false -ErrorAction SilentlyContinue
    
}


switch ($Vantage) {

    $true {

        $Source = $Schema.vantage.source
        $OutFile_Zipped = $Schema.vantage.destination
        $Outfile_Unzipped = $Schema.vantage.unzipped_package
        $Installer = $Schema.vantage.installer_path

        Start-BitsTransfer -DisplayName "Lenovo Vantage" -Source $Source -Destination $OutFile_Zipped
        Expand-Archive -Path $OutFile_Zipped -DestinationPath $Outfile_Unzipped

        $Process = Start-Process $Installer -PassThru
        Wait-Process $Process.Id

        Remove-Item -Path $OutFile_Zipped, $Outfile_Unzipped -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue

    }
}


