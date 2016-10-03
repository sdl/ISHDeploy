﻿param(
    $session = $null,
    $testingDeploymentName = "InfoShare"
)
. "$PSScriptRoot\Common.ps1"

#region variables

# Generating file pathes to remote PC files
$xmlPath = Join-Path $testingDeployment.WebPath ("\Web{0}\Author\ASP\XSL" -f $suffix )
$xmlPath = $xmlPath.ToString().replace(":", "$")
$xmlPath = "\\$computerName\$xmlPath"

$testName = "Test"
$invalidName = "Invalid"
#endregion

#region Script Blocks 

# Function reads target files and their content, searches for specified nodes in xm
function compareArray([string[]]$firstArray, [string[]]$secondArray){
    if ($firstArray.Length -eq $secondArray.Length){
        
        $compareArrayResult = 0
        for ($i=0; $i -le $firstArray.Length - 1;$i++){
            if ($firstArray[$i] -ne $secondArray[$i]) {$compareArrayResult++}
        } 

        return $compareArrayResult 
    }
    else{
        return $false
    }
}

function getButtonBarButton{
    param([string]$Name, [string]$ButtonBarType)

    [System.Xml.XmlDocument]$xmlButtonBarBar = new-object System.Xml.XmlDocument
    $xmlButtonBarBar.load("$xmlPath\$ButtonBarType.xml")
    $itemXml = $xmlButtonBarBar.SelectSingleNode("BUTTONBAR/BUTTON/INPUT[@NAME='$Name']/parent::BUTTON")
    
    if ($itemXml)
    {
        $item = @{Name = $itemXml.INPUT.NAME; Icon = $itemXml.INPUT.ICON; OnClick = $itemXml.INPUT.onClick}
        return $item
    }
    else
    {
        return $null 
    }
}

function getCountButtonBarButton{
    param([string]$Name, [string]$ButtonBarType)

    [System.Xml.XmlDocument]$xmlButtonBarBar = new-object System.Xml.XmlDocument
    $xmlButtonBarBar.load("$xmlPath\$ButtonBarType.xml")
    $itemXml = $xmlButtonBarBar.SelectNodes("BUTTONBAR/BUTTON/INPUT[@NAME='$Name']/parent::BUTTON")
    
    return $itemXml.Count
}

function checkAmountOFUserroles{
    param( [string]$Label)

    [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
      
    $textButtonBarBar = $XmlButtonBarBar.menubar.menuitem | ? {($_.label -eq $Label)}
    Return  $textButtonBarBar.userrole.Count
  
}

$scriptBlockSetButtonBarButton = {
    param (
        $ishDeployName,
        $parametersHash
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }

    $ishDeploy = Get-ISHDeployment -Name $ishDeployName
    Set-ISHUIButtonBarItem -ISHDeployment $ishDeploy @parametersHash
}

$scriptBlockMoveButtonBarButton = {
    param (
        $ishDeployName,
        $parametersHash,
        $switchState
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
    $ishDeploy = Get-ISHDeployment -Name $ishDeployName
    if ($switchState -eq "First"){
        Move-ISHUIButtonBarItem -ISHDeployment $ishDeploy @parametersHash -First
    }
    elseif($switchState -eq "Last"){
        Move-ISHUIButtonBarItem -ISHDeployment $ishDeploy @parametersHash -Last
    }
    else{
        Move-ISHUIButtonBarItem -ISHDeployment $ishDeploy @parametersHash
    }
}

$scriptBlockRemoveButtonBarBar= {
    param (
        [Parameter(Mandatory=$false)]
        $ishDeployName,
        [Parameter(Mandatory=$false)]
        $name,
        [Parameter(Mandatory=$false)]
        $buttonBar
    )
    if($PSSenderInfo) {
        $DebugPreference=$Using:DebugPreference
        $VerbosePreference=$Using:VerbosePreference 
    }
    $ishDeploy = Get-ISHDeployment -Name $ishDeployName
    Remove-ISHUIButtonBarItem -ISHDeployment $ishDeploy -Name $name -ButtonBar $buttonBar
}

Describe "Testing ISHUIButtonBarItemButton"{
    BeforeEach {
		ArtifactCleaner -filePath $xmlPath -fileName "CategoryMasterButtonbar.xml"
		UndoDeploymentBackToVanila $testingDeploymentName $true
    }

    It "Set button"{
        #Arrange
        $params = @{ButtonBar = "CategoryMasterButtonbar"; Name = $testName; Icon = "~/UIFramework/test.32x32.png"; OnClick = "testOnClick();"; }
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params
        #Assert
        $item = getButtonBarButton -Name $params.Name -ButtonBarType $params.ButtonBar
        $item.Name | Should be $params.Name
        $item.Icon | Should be $params.Icon
        $item.OnClick | Should be $params.OnClick
    }

    It "Remove main menu button"{
        #Arrange
        $params = @{ButtonBar = "CategoryMasterButtonbar"; Name = $testName; Icon = "~/UIFramework/test.32x32.png"; OnClick = "testOnClick();"; }
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params
        getCountButtonBarButton -Name $params.Name -ButtonBarType $params.ButtonBar | Should be 1
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockRemoveButtonBarBar -Session $session -ArgumentList $testingDeploymentName, $params.Name, $params.ButtonBar
        #Assert
        $item = getButtonBarButton -Name $params.Name -ButtonBarType $params.ButtonBar
        $item | Should be $null
        getCountButtonBarButton -Name $params.Name -ButtonBarType $params.ButtonBar | Should be 0
    }
       
    It "Sets button with no XML"{
        #Arrange
        Rename-Item "$xmlPath\CategoryMasterButtonbar.xml" "_CategoryMasterButtonbar.xml"
        $params = @{ButtonBar = "CategoryMasterButtonbar"; Name = $testName; Icon = "~/UIFramework/test.32x32.png"; OnClick = "testOnClick();"; }
        #Act/Assert
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} |Should Throw "Could not find file" 
        #Rollback
        Rename-Item "$xmlPath\_CategoryMasterButtonbar.xml" "CategoryMasterButtonbar.xml"
    }    
      
    It "Sets button with wrong XML"{
        #Arrange
        # Running valid scenario commandlet to out files into backup folder before they will ba manually modified in test
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockRemoveButtonBarBar -Session $session -ArgumentList $testingDeploymentName, $testName, "CategoryMasterButtonbar"
        Rename-Item "$xmlPath\CategoryMasterButtonbar.xml" "_CategoryMasterButtonbar.xml"
        New-Item "$xmlPath\CategoryMasterButtonbar.xml" -type file |Out-Null
        $params = @{ButtonBar = "CategoryMasterButtonbar"; Name = $testName; Icon = "~/UIFramework/test.32x32.png"; OnClick = "testOnClick();"; }
        #Act/Assert
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} |Should Throw "Root element is missing" 
        #Rollback
        Remove-Item "$xmlPath\CategoryMasterButtonbar.xml"
        Rename-Item "$xmlPath\_CategoryMasterButtonbar.xml" "CategoryMasterButtonbar.xml"
    }
  
    It "Remove button with no XML"{
        #Arrange
        # Running valid scenario commandlet to out files into backup folder before they will ba manually modified in test
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockRemoveButtonBarBar -Session $session -ArgumentList $testingDeploymentName, $testName, "CategoryMasterButtonbar"
        Rename-Item "$xmlPath\CategoryMasterButtonbar.xml" "_CategoryMasterButtonbar.xml"
        New-Item "$xmlPath\CategoryMasterButtonbar.xml" -type file |Out-Null
        #Act/Assert
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockRemoveButtonBarBar -Session $session -ArgumentList $testingDeploymentName, $testName, "CategoryMasterButtonbar"} |Should Throw "Root element is missing" 
        #Rollback
        Remove-Item "$xmlPath\CategoryMasterButtonbar.xml"
        Rename-Item "$xmlPath\_CategoryMasterButtonbar.xml" "CategoryMasterButtonbar.xml"
    }

    It "Set existing button"{
        #Arrange
        $params = @{ButtonBar = "CategoryMasterButtonbar"; Name = $testName; Icon = "~/UIFramework/test.32x32.png"; OnClick = "testOnClick();"; }
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params
        #Assert
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} | Should Not Throw
        getCountButtonBarButton -Name $params.Name -ButtonBarType $params.ButtonBar | Should be 1
    }

    It "Remove unexisting button"{
        #Act/Assert
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockRemoveButtonBarBar -Session $session -ArgumentList $testingDeploymentName, $testName, "CategoryMasterButtonbar"} | Should Not Throw
    }

    It "Move After"{
        #Arrange
        #getting 2 arrays with labels of nodes of Event Monitor Menu bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #don't rewrite this to $tempArray = $labelArray - in powershell it will be link to an object and if one changes - another will change too and test fails
        $tempArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #get label that will be moved
        $moveblelabel = $labelArray[$arrayLength -1]

        #Move array object in same way, as Move commandklet will move nodes
        $labelArray[1] = $moveblelabel
        for ($i=2; $i -le $arrayLength - 1;$i++){
            $labelArray[$i] = $tempArray[$i-1]
        }
        $params = @{Name = $moveblelabel; ButtonBar = "CategoryMasterButtonbar"; After = $tempArray[0]}
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params

        #read the updated xml file
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $thirdArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME 
    
        #Compare 2 arrays
        $compareArrayResult = 0
        for ($i=0; $i -le $arrayLength - 1;$i++){
            if ($labelArray[$i] -ne $thirdArray[$i]){$compareArrayResult++}
        }
        $checkResult = $compareArrayResult -eq 0
    
        #Assert
        $checkResult | Should Be "True"
    }

    It "Move Last"{
        #Arrange
        #getting 2 arrays with labels of nodes of Event Monitor Menu bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #don't rewrite this to $tempArray = $labelArray - in powershell it will be link to an object and if one changes - another will change too and test fails
        $tempArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #get label that will be moved
        $moveblelabel = $labelArray[0]

        #Move array object in same way, as Move commandklet will move nodes
        $labelArray[$arrayLength-1] = $moveblelabel
        for ($i=0; $i -le $arrayLength - 2;$i++){
            $labelArray[$i] = $tempArray[$i+1]
        }
        $params = @{Name = $moveblelabel; ButtonBar = "CategoryMasterButtonbar";}
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params, "Last"

        #read the updated xml file
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $thirdArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME 
    
        #Compare 2 arrays
        $compareArrayResult = 0
        for ($i=0; $i -le $arrayLength - 1;$i++){
            if ($labelArray[$i] -ne $thirdArray[$i]){$compareArrayResult++}
        }
        $checkResult = $compareArrayResult -eq 0 
        #Assert
        $checkResult | Should Be "True"
    }

    It "Move After itsels"{
        #Arrange
        #get array with labels on nodes in Event Monitor Menu Bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #select label that will be moved
        $moveblelabel = $labelArray[$arrayLength -1]
        $params = @{Name = $moveblelabel; ButtonBar = "CategoryMasterButtonbar"; After = $moveblelabel }
        #Act
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} | Should Not Throw

        #Get updated array with labels
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $compareArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #Compare 2 arrays - before move and after - they should be same
        $compareArrayResult = compareArray -firstArray $labelArray -secondArray $compareArray
    
        #Assert
        ($compareArrayResult -eq 0) | Should Be "True"
    }

    It "Move After non-existing label"{
        #Arrange
        #get array with labels on nodes in Event Monitor Menu Bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #select label that will be moved
        $moveblelabel = $labelArray[$arrayLength -1]
        $params = @{Name = $moveblelabel; ButtonBar = "CategoryMasterButtonbar"; After = $invalidName }
        #Act
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} | Should Not Throw

        #Get updated array with labels
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $compareArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #Compare 2 arrays - before move and after - they should be same
        $compareArrayResult = compareArray -firstArray $labelArray -secondArray $compareArray
    
        #Assert
        ($compareArrayResult -eq 0) | Should Be "True"
    }

    It "Move After non-existing label"{
        #Arrange
        #get array with labels on nodes in Event Monitor Menu Bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #select label that will be moved
        $moveblelabel = $labelArray[$arrayLength -1]
        $params = @{Name = $invalidName; ButtonBar = "CategoryMasterButtonbar";After = $moveblelabel }
        #Act
        {Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params} | Should Not Throw

        #Get updated array with labels
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $compareArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #Compare 2 arrays - before move and after - they should be same
        $compareArrayResult = compareArray -firstArray $labelArray -secondArray $compareArray
    
        #Assert
        ($compareArrayResult -eq 0)| Should Be "True"
    }

    It "Move First"{
        #Arrange
        #getting 2 arrays with labels of nodes of Event Monitor Menu bar
        [xml]$XmlButtonBarBar= Get-Content "$xmlPath\CategoryMasterButtonbar.xml"  -ErrorAction SilentlyContinue
        $labelArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        #don't rewrite this to $tempArray = $labelArray - in powershell it will be link to an object and if one changes - another will change too and test fails
        $tempArray = $XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME
        $arrayLength = $labelArray.Length
        #get label that will be moved
        $moveblelabel = $labelArray[$arrayLength -1]

        #Move array object in same way, as Move commandklet will move nodes
        $labelArray[0] = $moveblelabel
        for ($i=1; $i -le $arrayLength - 1;$i++){
            $labelArray[$i] = $tempArray[$i-1]
        }
        $params = @{Name = $moveblelabel; ButtonBar = "CategoryMasterButtonbar"; }
        #Act
        Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockMoveButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params, "First"

        #read the updated xml file
        [xml]$XmlButtonBarBar = RemoteReadXML "$xmlPath\CategoryMasterButtonbar.xml"
        $thirdArray =$XmlButtonBarBar.BUTTONBAR.BUTTON.INPUT.NAME 
    
        #Compare 2 arrays
        $compareArrayResult = 0
        for ($i=0; $i -le $arrayLength - 1;$i++){
            if ($labelArray[$i] -ne $thirdArray[$i]){$compareArrayResult++}
        }
        $checkResult = $compareArrayResult -eq 0 
        $CheckResult | Should Be "True"
     }

	#It "Update existing item"{
 #       #Arrange
 #       $params = @{Label = $testLabelName; UserRole = @("Administrator", "Translator"); Action = "TestPage.asp" }
 #       Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params
 #       $item = getButtonBarButton -Label $params.Label
 #       $item.UserRole.Count | Should Be 2
 #       $params = @{Label = $testLabelName; UserRole = @("Administrator", "Translator", "Reviewer"); Action = "TestPage.asp" }
 #       #Act
 #       Invoke-CommandRemoteOrLocal -ScriptBlock $scriptBlockSetButtonBarButton -Session $session -ArgumentList $testingDeploymentName, $params
 #       #Assert
 #       $item = getButtonBarButton -Label $params.Label
 #       $item.UserRole.Count | Should Be 3
 #   }
}