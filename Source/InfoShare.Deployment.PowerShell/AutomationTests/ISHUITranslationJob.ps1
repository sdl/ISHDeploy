﻿Import-Module ISHBackdoor
Import-Module InfoShare.Deployment
. "$PSScriptRoot\Common.ps1"


$htmlStyle = Set-Style

$logFile = "C:\Automated_deployment\Test9.htm"


$WarningPreference = “Continue"
$VerbosePreference = "SilentlyCOntinue"
$global:logArray = @()


$deploy = Get-ISHDeployment -Name "InfoShareSQL2014"




$LicensePath = $deploy.WebPath
$LicensePath = $LicensePath + "\Web" 
$LicensePath = $LicensePath + $deploy.OriginalParameters.projectsuffix  
$LicensePath = $LicensePath + "\Author\ASP"
$xmlPath = $LicensePath + "\XSL"
#endregion



function checkTranslationJobEnabled{
[xml]$XmlEventMonitorBar= Get-Content "$xmlPath\EventMonitorMenuBar.xml"  -ErrorAction SilentlyContinue
[xml]$XmlTopDocumentButtonbar = Get-Content "$xmlPath\TopDocumentButtonbar.xml" -ErrorAction SilentlyContinue
$TreeHtm = Get-Content "$LicensePath\Tree.htm" -ErrorAction SilentlyContinue

$global:textEventMenuBar = $XmlEventMonitorBar.menubar.menuitem | ? {$_.label -eq "Translation Jobs"}
$global:textTopDocumentButtonbar = $XmlTopDocumentButtonbar.BUTTONBAR.BUTTON.INPUT | ? {$_.NAME -eq "TranslationJob"}
$global:textTreeHtm = $TreeHtm | Select-String '"Translation Jobs"'
$global:textFunctionTreeHtm = $TreeHtm | Select-String 'function HighlightTranslationJobs()'



$commentCheck = $global:textTreeHtm.ToString().Contains("//") -and $global:textFunctionTreeHtm.ToString().Contains("//")
if (!$commentCheck -and $global:textEventMenuBar -and $global:textTopDocumentButtonbar){

Return "Enabled"

}

elseif  ($commentCheck -and !$global:textEventMenuBar -and !$global:textTopDocumentButtonbar){
    
    Return "Disabled"

}


}



#region Tests

function enableTranslationJob_test(){

    

    $checkResult = checkTranslationJobEnabled -eq "Enabled"
    # Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "1"
}

function disableTranslationJob_test(){

    

    $checkResult = checkTranslationJobEnabled -eq "Disabled"
    # Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "2"
   
}

function enableTranslationJobWithNoXML_test(){
    #Arange
    Rename-Item "$xmlPath\EventMonitorMenuBar.xml" "_EventMonitorMenuBar.xml"

    #Action       
    try
    {
        Enable-ISHUITranslationJob -ISHDeployment $deploy -WarningVariable Warning -ErrorAction Stop
    }
    catch 
    {
        $ErrorMessage = $_.Exception.Message
    }

    $checkResult = $ErrorMessage -Match "Could not find file"
    # Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "3"
    
    #Rollback
    Rename-Item "$xmlPath\_EventMonitorMenuBar.xml" "EventMonitorMenuBar.xml"
}

function disableTranslationJobWithNoXML_test(){
    #Arange
    Rename-Item "$xmlPath\EventMonitorMenuBar.xml" "_EventMonitorMenuBar.xml"

    #Action  
    try
    {
        Disable-ISHUITranslationJob -ISHDeployment $deploy -WarningVariable Warning -ErrorAction Stop
    }
    catch 
    {
        $ErrorMessage = $_.Exception.Message
    }
    $checkResult = $ErrorMessage -Match "Could not find file"
    # Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "4"

    #Rollback
    Rename-Item "$xmlPath\_EventMonitorMenuBar.xml" "EventMonitorMenuBar.xml"
}

function enableTranslationJobWithWrongXML_test(){
    #Arange
    Rename-Item "$xmlPath\EventMonitorMenuBar.xml" "_EventMonitorMenuBar.xml"
    New-Item "$xmlPath\EventMonitorMenuBar.xml" -type file |Out-Null

    #Action 
    try
    {
        Enable-ISHUITranslationJob -ISHDeployment $deploy -WarningVariable Warning -ErrorAction Stop 
        
    }
    catch 
    {
        $ErrorMessage = $_.Exception.Message
    }

     $checkResult = $ErrorMessage -Match "Root element is missing"

     # Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "5"

    #Rollback
    Remove-Item "$xmlPath\EventMonitorMenuBar.xml"
    Rename-Item "$xmlPath\_EventMonitorMenuBar.xml" "EventMonitorMenuBar.xml"
}

function disableTranslationJobWithWrongXML_test(){
    #Arange
    Rename-Item "$xmlPath\EventMonitorMenuBar.xml" "_EventMonitorMenuBar.xml"
    New-Item "$xmlPath\EventMonitorMenuBar.xml" -type file |Out-Null
  
    try
    {
        disable-ISHUITranslationJob -ISHDeployment $deploy -WarningVariable Warning -ErrorAction Stop 
        
    }
    catch 
    {
        $ErrorMessage = $_.Exception.Message
    }

    $checkResult = $ErrorMessage -Match "Root element is missing"

    #Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "6"

    #Rollback
    Remove-Item "$xmlPath\EventMonitorMenuBar.xml"
    Rename-Item "$xmlPath\_EventMonitorMenuBar.xml" "EventMonitorMenuBar.xml"
}

function enableEnabledTranslationJob_test(){
    #Action
    Enable-ISHUITranslationJob -ISHDeployment $deploy
    Enable-ISHUITranslationJob -ISHDeployment $deploy
    
    
    $checkResult = checkTranslationJobEnabled -eq "Enabled"
    
    #Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "7"
}

function disableDisabledTranslationJob_test(){
    #Action
    Disable-ISHUITranslationJob -ISHDeployment $deploy
    Disable-ISHUITranslationJob -ISHDeployment $deploy

    

    $checkResult = checkTranslationJobEnabled -eq "Disabled"

    #Assert
    Assert_IsTrue $checkResult $MyInvocation.MyCommand.Name "8"

}



#endregion

#region Test Calls

Enable-ISHUITranslationJob -ISHDeployment $deploy
enableTranslationJob_test

Disable-ISHUITranslationJob -ISHDeployment $deploy
disableTranslationJob_test


enableTranslationJobWithNoXML_test
disableTranslationJobWithNoXML_test
enableTranslationJobWithWrongXML_test
disableTranslationJobWithWrongXML_test

enableEnabledTranslationJob_test
disableDisabledTranslationJob_test


#endregion


$global:logArray | ConvertTo-HTML -Head $htmlStyle | Out-File $logFile


Edit-LogHtml -targetHTML $logFile


Invoke-Expression $logFile

