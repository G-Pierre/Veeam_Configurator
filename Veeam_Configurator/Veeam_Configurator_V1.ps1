#   Auteur : Pierre GILLET 
#   Date dernière mise à jour : 04/03/2024

# Historique des versions
#   v 1.0 -> Redaction initiale



######### Script pour la configuration de VEEAM B&R en suivant les conseils de l'analyser ########


############################### Desactivation des services ###############################

### -> Remote Desktop Services (TermService) should be disabled
Stop-Service -Name TermService -Force
Set-Service -Name TermService -StartupType Disabled

# Verification
$service_1 = Get-Service -Name "TermService"

if ($service_1.Status -eq "Stopped" -and $service_1.StartType -eq "Disabled") {
    Write-Host "Le service TermService a ete arrete avec succes et son demarrage est desactive." -ForegroundColor Yellow
} else {
    Write-Host "Une erreur s'est produite lors de l'arret du service ou de la modification de son statut de demarrage." -ForegroundColor Red
}


### -> Remote Registry service (RemoteRegistry) should be disabled
Stop-Service -Name "RemoteRegistry"
Set-Service -Name "RemoteRegistry" -Status stopped -StartupType disabled

# Verification
$service_2 = Get-Service -Name "RemoteRegistry"

if ($service_2.Status -eq "Stopped" -and $service_2.StartType -eq "Disabled") {
    Write-Host "Le service RemoteRegistry a ete arrete avec succes et son demarrage est desactive." -ForegroundColor Yellow
} else {
    Write-Host "Une erreur s'est produite lors de l'arret du service ou de la modification de son statut de demarrage." -ForegroundColor Red
}


### -> Windows Remote Management (WinRM) service should be disabled
Stop-Service -Name "WinRM"
Set-Service -Name "WinRM" -Status stopped -StartupType disabled

# Verification
$service_3 = Get-Service -Name "WinRM"

if ($service_3.Status -eq "Stopped" -and $service_3.StartType -eq "Disabled") {
    Write-Host "Le service WinRM a ete arrete avec succes et son demarrage est desactive." -ForegroundColor Yellow
} else {
    Write-Host "Une erreur s'est produite lors de l'arret du service ou de la modification de son statut de demarrage." -ForegroundColor Red
}

############################### Activation du Firewall ###############################

### -> Windows Firewall should be enabled
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Verification
$firewallProfiles = Get-NetFirewallProfile

foreach ($profile in $firewallProfiles) {
    $profileStatus = if ($profile.Enabled) { "Active" } else { "Desactive"; Write-Host "Attention : Le profil $($profile.Name) est desactive." -ForegroundColor Red }
    Write-Host "Profil : $($profile.Name) - etat : $profileStatus"
}

############################### Modifications des cles de registres ###############################

Write-Host "

##############################################   Modification registre ############################################## " -ForegroundColor Yellow


$batFilePath = "Regedit_Modifs\DisableSSL2-3.bat"
$batFilePath2 = "Regedit_Modifs\DisableTLS1.bat"
$batFilePath3 = "Regedit_Modifs\WindowsScriptHost.bat"
$batFilePath4 = "Regedit_Modifs\EnableMulticast.bat"
$batFilePath5 = "Regedit_Modifs\Policy_Group_SMBV3.bat"
$batFilePath6 = "Regedit_Modifs\Disable_WDigest.bat"
$batFilePath7 = "Regedit_Modifs\Set_WinHttpAutoProxy.bat"

Write-Host " ################################  Execution du fichier $batFilePath...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath"

Write-Host " ################################  Execution du fichier $batFilePath2...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath2"

Write-Host " ################################  Execution du fichier $batFilePath3...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath3"

Write-Host " ################################  Execution du fichier $batFilePath4...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath4"

Write-Host "################################  Execution du fichier $batFilePath5...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath5"

Write-Host "################################  Execution du fichier $batFilePath6...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath6"

Write-Host " ################################  Execution du fichier $batFilePath7...   ################################ " -ForegroundColor Yellow
cmd.exe /c "$batFilePath7"

############################### Modifications via CLI VEEAM ###############################

### -> Unknown Linux servers should not be trusted automatically

Set-VBRLinuxTrustedHostPolicy -Type KnownHosts
Write-Host "Unknown Linux servers should not be trusted automatically -> Active" -ForegroundColor Yellow

############################### Desactivation SMB V1 ###############################

Write-Host "Desactivation du SMBV1" -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

############################### Activation SMB V3 ###############################

Set-SmbServerConfiguration -EncryptData $true
Restart-Service -Name "LanmanServer"

Start-Sleep -Seconds 5

$smbConfig = Get-SmbServerConfiguration
if ($smbConfig.EncryptData) {
    Write-Host "Le chiffrement des donnees SMB a ete active avec succes." -ForegroundColor Yellow
} else {
    Write-Host "Erreur : Le chiffrement des donnees SMB n'a pas ete active." -ForegroundColor Red
}

Write-Host "Merci de redemarrer le serveur puis relancer l'analyse VEEAM" -ForegroundColor Green