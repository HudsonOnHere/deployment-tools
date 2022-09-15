#Requires -RunAsAdministrator

Install-Module PSWindowsUpdate

Get-WindowsUpdate -AcceptAll -Install -AutoReboot
