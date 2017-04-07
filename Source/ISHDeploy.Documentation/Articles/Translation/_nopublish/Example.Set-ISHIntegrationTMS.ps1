﻿# Uri and credentials for SDL TMS
$uri="http://tms.example.com/"
$credential=Get-Credential -Message "SDL TMS integration credential" 

$apiKey="ApiKey"
$secretKey="SecretKey"

# Set the integration with required parameters
Set-ISHIntegrationTMS -ISHDeployment $deploymentName -Name TMS -Uri $uri -Credential $credential -Mappings $mappings -Templates $templates -ApiKey $apiKey -SecretKey $secretKey

# Set the integration with extra parameters
Set-ISHIntegrationTMS -ISHDeployment $deploymentName -Name TMS -Uri $uri -Credential $credential -Mappings $mappings -Templates $templates -RequestMetadata $requestMetadata -GroupMetadata $groupMetadata -ApiKey $apiKey -SecretKey $secretKey