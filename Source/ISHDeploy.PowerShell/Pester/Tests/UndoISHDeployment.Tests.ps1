﻿param(
    $session = $null,
    $testingDeploymentName = "InfoShare"
)

. "$PSScriptRoot\Common.ps1"

$moduleName = Invoke-CommandRemoteOrLocal -ScriptBlock { (Get-Module "ISHDeploy.*").Name } -Session $session
$backup = "\\$computerName\C$\ProgramData\$moduleName\$($testingDeployment.Name)"

$xmlPath = Join-Path $webPath.replace(":", "$") "Author"
$xmlPath = "\\$computerName\$xmlPath"

$CEXmlPath = Join-Path $xmlPath "ASP\XSL"
$EPxmlPath = Join-Path $xmlPath "ASP"
$QAxmlPath = Join-Path $xmlPath "ASP\Editors\Xopus\config"

$scriptBlockGet = {
    param (
        [Parameter(Mandatory=$false)]
        $ishDeployName 
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
    $ishDeploy = Get-ISHDeployment -Name $ishDeployName
    Get-ISHDeploymentHistory -ISHDeployment $ishDeploy
}

$scriptBlockClean = {
    param (
        [Parameter(Mandatory=$false)]
        $ishDeployName 
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
    $ishDeploy = Get-ISHDeployment -Name $ishDeployName
    Clear-ISHDeploymentHistory -ISHDeployment $ishDeploy
}

# Script block for Enable-ISHUIQualityAssistant. Added here for generating backup files
$scriptBlockEnableQA = {
    param (
        [Parameter(Mandatory=$true)]
        $ishDeployName 
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
        $ishDeploy = Get-ISHDeployment -Name $ishDeployName
        Enable-ISHUIQualityAssistant -ISHDeployment $ishDeploy
  
}

$scriptBlockEnableContentEditor = {
    param (
        [Parameter(Mandatory=$true)]
        $ishDeployName 
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
        $ishDeploy = Get-ISHDeployment -Name $ishDeployName
        Enable-ISHUIContentEditor -ISHDeployment $ishDeploy
  
}

$scriptBlockBackupFilesExist = {
    param (
        [Parameter(Mandatory=$true)]
        $backup 
    )
	$exist =
		(Test-Path ("$backup\Backup\Web\Author\ASP\Editors\Xopus\config\config.xml")) -and
		(Test-Path ("$backup\Backup\Web\Author\ASP\Editors\Xopus\config\bluelion-config.xml")) -and
		(Test-Path ("$backup\Backup\Web\Author\ASP\XSL\FolderButtonbar.xml")) -and
		(Test-Path ("$backup\Backup\Web\Author\ASP\XSL\InboxButtonBar.xml")) -and
		(Test-Path ("$backup\Backup\Web\Author\ASP\XSL\LanguageDocumentButtonbar.xml")) -and
		(Test-Path ("$backup\Backup\Web\Author\ASP\Web.config"))

	return $exist   
}

$scriptBlockGetCountOfItemsInFolder = {
    param (
        [Parameter(Mandatory=$true)]
        $path
    )
	$items = Get-ChildItem -Path $path

	return $items.Count   
}

function readTargetXML(){
    #Content Editor XML
    [xml]$XmlFolderButtonbar = Get-Content "$CExmlPath\FolderButtonbar.xml" -ErrorAction SilentlyContinue
    [xml]$XmlInboxButtonBar = Get-Content "$CExmlPath\InboxButtonBar.xml" -ErrorAction SilentlyContinue
    [xml]$XmlLanguageDocumentButtonbar = Get-Content "$CExmlPath\LanguageDocumentButtonbar.xml" -ErrorAction SilentlyContinue
    $textFolderButtonbar = $XmlFolderButtonbar.BUTTONBAR.BUTTON.INPUT | ? {$_.NAME -eq "CheckOutWithXopus"}
    $textInboxButtonBar = $XmlInboxButtonBar.BUTTONBAR.BUTTON.INPUT | ? {$_.NAME -eq "CheckOutWithXopus"}
    $textLanguageDocumentButtonbar = $XmlLanguageDocumentButtonbar.BUTTONBAR.BUTTON.INPUT | ? {$_.NAME -eq "CheckOutWithXopus"}

    #External preview XML
    [xml]$XmlWebConfig = Get-Content "$EPxmlPath\Web.config" #-ErrorAction SilentlyContinue

    $textWebConfig = $XmlWebConfig.configuration.'trisoft.infoshare.web.externalpreviewmodule'.identity | ? {$_.externalId -eq "ServiceUser"}
    $configSection = $XmlWebConfig.configuration.configSections.section | ? {$_.name -eq "trisoft.infoshare.web.externalpreviewmodule"}
    $module = $XmlWebConfig.configuration.'system.webServer'.modules.add  | ? {$_.name -eq "TrisoftExternalPreviewModule"}
    $configCustomID = $XmlWebConfig.configuration.'trisoft.infoshare.web.externalpreviewmodule'.identity | ? {$_.externalId -eq $customID}

    #Quality Assistant XML
    [xml]$XmlConfig = Get-Content "$QAxmlPath\config.xml" -ErrorAction SilentlyContinue
    [xml]$XmlBlueLionConfig = Get-Content "$QAxmlPath\bluelion-config.xml" -ErrorAction SilentlyContinue

    $textConfig = $XmlConfig.config.javascript | ? {$_.src -eq "../BlueLion-Plugin/Bootstrap/bootstrap.js"}
    $textBlueLionConfig = $XmlBlueLionConfig.SelectNodes("*/*[local-name()='import'][@src='../BlueLion-Plugin/create-toolbar.xml']")

    $CECheck = $textFolderButtonbar -and $textInboxButtonBar -and $textLanguageDocumentButtonbar
    $QACheck = $textConfig -and $textBlueLionConfig.Count -eq 1
    $EPCheck = $textWebConfig -and $configSection -and $module

    $initialCheckResult = !$CECheck -and !$QACheck -and !$EPCheck
    
	if($initialCheckResult){
        return "VanilaState"
    }
    else{
        return "changedState"
    }
}

$scriptBlockEnableExternalPreview = {
    param (
        [Parameter(Mandatory=$true)]
        $ishDeployName,
        [Parameter(Mandatory=$false)]
        $externalId
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
    if(!$externalId){
        $ishDeploy = Get-ISHDeployment -Name $ishDeployName
        Enable-ISHExternalPreview -ISHDeployment $ishDeploy
    }
    else{
        $ishDeploy = Get-ISHDeployment -Name $ishDeployName
        Enable-ISHExternalPreview -ISHDeployment $ishDeploy -ExternalId $externalId
    }
  
}

$scriptBlockSetISHSTSConfiguration = {
    param (
        $ishDeployName,
        $thumbprint,
        $authenticationMode
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }

    $ishDeploy = Get-ISHDeployment -Name $ishDeployName

    Set-ISHSTSConfiguration -ISHDeployment $ishDeploy -TokenSigningCertificateThumbprint $thumbprint -AuthenticationType $authenticationMode
 
}

$scriptBlockGetAppPoolStartTime = {
    param (
        $testingDeployment
    )

    $cmAppPoolName = ("TrisoftAppPool{0}" -f $testingDeployment.WebAppNameCM)
    $wsAppPoolName = ("TrisoftAppPool{0}" -f $testingDeployment.WebAppNameWS)
    $stsAppPoolName = ("TrisoftAppPool{0}" -f $testingDeployment.WebAppNameSTS)
    
    $result = @{}
    [Array]$array = iex 'C:\Windows\system32\inetsrv\appcmd list wps'
    foreach ($line in $array) {
        $splitedLine = $line.split(" ")
        $processIdAsString = $splitedLine[1]
        $processId = $processIdAsString.Substring(1,$processIdAsString.Length-2)
        if ($splitedLine[2] -match $cmAppPoolName)
        {
            $result["cm"] = (Get-Process -Id $processId).StartTime
        }
        if ($splitedLine[2] -match $wsAppPoolName)
        {
            $result["ws"] = (Get-Process -Id $processId).StartTime
        }
        if ($splitedLine[2] -match $stsAppPoolName)
        {
            $result["sts"] = (Get-Process -Id $processId).StartTime
        }
    }
    
    return $result
}

Describe "Testing Undo-ISHDeploymentHistory"{
    BeforeEach {
        UndoDeploymentBackToVanila $testingDeploymentName
    }

    It "Undo ish deploy history"{
		# Try enabling Quality Assistant for generating backup files
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockEnableContentEditor -Session $session -ArgumentList $testingDeploymentName
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockEnableQA -Session $session -ArgumentList $testingDeploymentName
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockEnableExternalPreview -Session $session -ArgumentList $testingDeploymentName
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockBackupFilesExist -Session $session -ArgumentList $backup  | Should Be "True"
        readTargetXML | Should Be "changedState"
        # Get web application pool start times
        $appPoolStartTimes1 = Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockGetAppPoolStartTime -Session $session -ArgumentList $testingDeployment

        UndoDeploymentBackToVanila $testingDeploymentName
        
        WebRequestToSTS $testingDeploymentName

        # Get web application pool start times
        $appPoolStartTimes2 = Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockGetAppPoolStartTime -Session $session -ArgumentList $testingDeployment

        (get-date $appPoolStartTimes1["cm"]) -gt (get-date $appPoolStartTimes2["cm"])  | Should Be $false
        (get-date $appPoolStartTimes1["ws"]) -gt (get-date $appPoolStartTimes2["ws"])  | Should Be $false
        (get-date $appPoolStartTimes1["sts"]) -gt (get-date $appPoolStartTimes2["sts"])  | Should Be $false



        RetryCommand -numberOfRetries 20 -command {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockBackupFilesExist -Session $session -ArgumentList $backup} -expectedResult $false | Should Be "False"
        
        readTargetXML | Should Be "VanilaState"
        $path =  Join-Path $webPath "InfoShareSTS\App_Data\"
        $countOfItemsInDataBaseFolder = Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockGetCountOfItemsInFolder -Session $session -ArgumentList $path 
        $countOfItemsInDataBaseFolder | Should Be 1
    }

    It "Undo-IshHistory works when there is no backup"{
        {UndoDeploymentBackToVanila $testingDeploymentName -WarningVariable Warning -ErrorAction Stop }| Should Not Throw
    }

	It "Undo-IshHistory works when there is no backup"{
        {UndoDeploymentBackToVanila $testingDeploymentName -WarningVariable Warning -ErrorAction Stop }| Should Not Throw
    }
}

