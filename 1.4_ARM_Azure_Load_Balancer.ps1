#------------------------------------------------------------------------------  
#  
# Copyright © 2016 Microsoft Corporation.  All rights reserved.  
#  
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT  
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT  
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS  
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR   
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.  
#  
#------------------------------------------------------------------------------  
#  
# PowerShell Source Code  
#  
# NAME:  
#    ARM_Azure_Load_Balancer.ps1  
#  
# VERSION:  
#    1.4
#  
#------------------------------------------------------------------------------ 
 
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow 
""  | Write-Host -ForegroundColor Yellow 
" Copyright © 2016 Microsoft Corporation.  All rights reserved. " | Write-Host -ForegroundColor Yellow 
""  | Write-Host -ForegroundColor Yellow 
" THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED `“AS IS`” WITHOUT " | Write-Host -ForegroundColor Yellow 
" WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT " | Write-Host -ForegroundColor Yellow 
" LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS " | Write-Host -ForegroundColor Yellow 
" FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  " | Write-Host -ForegroundColor Yellow 
" RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. " | Write-Host -ForegroundColor Yellow 
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow 
""  | Write-Host -ForegroundColor Yellow 
" PowerShell Source Code " | Write-Host -ForegroundColor Yellow 
""  | Write-Host -ForegroundColor Yellow 
" NAME: " | Write-Host -ForegroundColor Yellow 
"    ARM_Azure_Load_Balancer.ps1 " | Write-Host -ForegroundColor Yellow 
"" | Write-Host -ForegroundColor Yellow 
" VERSION: " | Write-Host -ForegroundColor Yellow 
"    1.4" | Write-Host -ForegroundColor Yellow 
""  | Write-Host -ForegroundColor Yellow 
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow 
"" | Write-Host -ForegroundColor Yellow 
"`n This script SAMPLE is provided and intended only to act as a SAMPLE ONLY," | Write-Host -ForegroundColor Yellow 
" and is NOT intended to serve as a solution to any known technical issue."  | Write-Host -ForegroundColor Yellow 
"`n By executing this SAMPLE AS-IS, you agree to assume all risks and responsibility associated."  | Write-Host -ForegroundColor Yellow 
 
$ErrorActionPreference = "SilentlyContinue" 
$ContinueAnswer = Read-Host "`n Do you wish to proceed at your own risk? (Y/N)" 
If ($ContinueAnswer -ne "Y") { Write-Host "`n Exiting." -ForegroundColor Red;Exit } 

#import module
Import-Module Azure

#Check the Azure PowerShell module version
Write-Host "`n[WORKITEM] - Checking Azure PowerShell module verion" -ForegroundColor Yellow
$APSMajor =(Get-Module azure).version.Major
$APSMinor =(Get-Module azure).version.Minor
$APSBuild =(Get-Module azure).version.Build
$APSVersion =("$PSMajor.$PSMinor.$PSBuild")

If ($APSVersion -ge 2.0.1)
{
    Write-Host "`tSuccess" -ForegroundColor Green
}
Else
{
   Write-Host "[ERROR] - Azure PowerShell module must be version 2.0.1 or higher. Exiting." -ForegroundColor Red
   Exit
}

Write-Host "`n[INFO] - Login to Azure RM" -ForegroundColor Yellow
Login-AzureRmAccount

Write-Host "`n[INFO] - Obtaining subscriptions" -ForegroundColor Yellow
[array] $AllSubs = get-AzureRmSubscription

If ($AllSubs)
{
        Write-Host "`tSuccess" -ForegroundColor Green

        }
Else
{
        Write-Host "`tNo subscriptions found. Exiting." -ForegroundColor Red
        Exit
}

Write-Host "`n[SELECTION] - Select the Azure subscription." -ForegroundColor Yellow

$SelSubName = $AllSubs | Out-GridView -PassThru -Title "Select the Azure subscription"

If ($SelSubName)
{
	#Write sub
	Write-Host "`tSelection: $($SelSubName.SubscriptionName)"
		
        $SelSub = $SelSubName.SubscriptionId
        Select-AzureRmSubscription -Subscriptionid $SelSub | Out-Null
		Write-Host "`tSuccess" -ForegroundColor Green
}
Else
{
        Write-Host "`n[ERROR] - No Azure subscription was selected. Exiting." -ForegroundColor Red
        Exit
}

Write-Host "`n[SELECTION] - Input for script workload." -ForegroundColor Yellow

$input0 = new-object psobject
Add-Member -InputObject $input0 -MemberType NoteProperty -Name Workload -Value "Build example IPv4 public IP address load balancer" -Force
$input1 = new-object psobject
Add-Member -InputObject $input1 -MemberType NoteProperty -Name Workload -Value "Build example IPv6 public IP address load balancer" -Force
$input2 = new-object psobject
Add-Member -InputObject $input2 -MemberType NoteProperty -Name Workload -Value "Build example IPv4 private IP address load balancer" -Force
$input3 = new-object psobject

[array] $Inputy += $input0
[array] $Inputy += $input1
[array] $Inputy += $input2

$Work = $Inputy | Select-Object Workload | Out-GridView -Title "Select workload for script" -PassThru
$SelWork = $Work.Workload

## Build example IPv4 public IP address load balancer
if ($SelWork -eq "Build example IPv4 public IP address load balancer")
{
	$SelLocationName = ((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Network).ResourceTypes | Where-Object ResourceTypeName -eq virtualNetworks).Locations
	$Location = $SelLocationName | Out-GridView -Title "Select Region" -passthru
	$region = $Location
	
	[string]$cloudSvcName = Read-Host "`n `tWhat do you want the resource group to be named?" 
	$cloudSvcName=$cloudSvcName.tolower() 
	[string]$loadbalancernrp = "$($cloudSvcName)loadbalancer" 
	[string]$ResourceGroupName = "$($loadbalancernrp)-RG"
	
	[string]$DNSName = Read-Host "`n `tWhat DNS label to you want to use?" 
	$DNSName=$DNSName.tolower() 
	
	$DNStest = Test-AzureRmDnsAvailability -DomainNameLabel $DNSName -Location $region
	if($DNStest -eq $false)
	{
	Write-Host "`n[ERROR] - Domain name label $($DNSName) is already in use in location $($region). Exiting." -ForegroundColor Red
	Exit
	}
	
	Try
	{
		New-AzureRmResourceGroup -Name $ResourceGroupName -location $region -WarningAction Ignore
		Write-Host "`n[INFO] - Creating Vnet" -ForegroundColor Yellow
		$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name LB-Subnet-BE -AddressPrefix 10.0.2.0/24
		$Vnetwork = New-AzureRmvirtualNetwork -Name VNet -ResourceGroupName $ResourceGroupName -Location $region -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet -WarningAction Ignore
		$internaladdresspoolv4 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "BackendPoolIPv4"
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create Vnet, Exiting." -ForegroundColor Red
        Exit
	}
	#feedback to user for Vnet
	Write-Host "`tSuccess" -ForegroundColor Green

	[int]$IP4 = Read-Host "`n[INPUT] - How many public IPv4 IP(s) do you need to assign? (Max: 20)"
	
	Write-Host "`n[SELECTION] - Allocation method for public IP address" -ForegroundColor Yellow

	$ipinput0 = new-object psobject
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Workload -Value "Dynamic IP allocation" -Force
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Allocation -Value "Dynamic" -Force
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Max_IP -Value "5" -Force
	$ipinput1 = new-object psobject
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Workload -Value "Static IP allocation" -Force
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Allocation -Value "Static" -Force
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Max_IP -Value "20" -Force

	[array] $ipInputy += $ipinput0
	[array] $ipInputy += $ipinput1

	$selipWork = $ipInputy | Out-GridView -Title "Select allocation method for public IP address" -PassThru
	$ipWork = $selipWork.Allocation
	
	If(($ipWork -eq "Static")-and($IP4 -gt 5))
	{
		Write-Host "[ERROR] - To many dynamic IP address, Exiting." -ForegroundColor Red
		Exit	
	}

	If(($ipWork -eq "Dynamic")-and($IP4 -gt 20))
	{
		Write-Host "[ERROR] - To many static public IP address, Exiting." -ForegroundColor Red
		Exit
	}
	#feedback to user for ipworkload 
	Write-Host "`n[INFO] - IPv4 $ipWork allocation selected" -ForegroundColor Yellow
	
	#for IPv4 allocation
	Try
	{
		for($j = 1; $j -le $IP4; $j++) 
		{
	      [int]$ipnum = $j
	      $number = "$($loadbalancernrp)$($ipnum)"
		  $DNSLabelv4 = $DNSName+"-pub-ipv4-"+$number
		  $DNSLabelv4test = Test-AzureRmDnsAvailability -DomainNameLabel $DNSLabelv4 -Location $region
		  if($DNSLabelv4test -eq $false)
			{
			Write-Host "`n[ERROR] - Domain name label $($DNSLabelv4) is already in use in location $($region). Exiting." -ForegroundColor Red
			Exit
			}
		  Write-Host "`n[INFO] - Creating IPv4 Address $($ipnum)" -ForegroundColor Yellow
	      $publicIPv4 = New-AzureRmPublicIpAddress -Name "pub-ipv4-$($ipnum)" -ResourceGroupName $ResourceGroupName -Location $region –AllocationMethod $ipWork -IpAddressVersion IPv4 -DomainNameLabel $DNSLabelv4 -WarningAction Ignore
		  Write-Host "`tSuccess" -ForegroundColor Green
		  [Array]$arrpubip4 += $publicIPv4
		}
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create IP address, Exiting." -ForegroundColor Red
        Exit
	}
	Try
	{
		$NSGName = $DNSName+"-NSG"
		Write-Host "`n[INFO] - Creating NSG to allow RDP, HTTP for NIC" -ForegroundColor Yellow
		$NSGRule1 = New-AzureRmNetworkSecurityRuleConfig -Name "default-allow-rdp" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3387-3389"
		$NSGRule2 = New-AzureRmNetworkSecurityRuleConfig -Name "allow-Http" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 8080
		$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $region -SecurityRules $NSGRule1,$NSGRule2 -WarningAction Ignore
		Write-Host "`tSuccess" -ForegroundColor Green
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create NSG, Exiting." -ForegroundColor Red
        Exit
	}
	Try
	{
		$w=0
		foreach ($u in $arrpubip4)
		{
			If($w -eq 0) 
			{$frontendIPv4 = New-AzureRmLoadBalancerFrontendIpConfig -Name "LB-Frontendv4-$($u.name)" -PublicIpAddress $u; $w++}
			elseif ($w -ge 1){[Array]$AddIP4 += $u}
		}
		
			Write-Host "`n[INFO] - Creating Nat Rules" -ForegroundColor Yellow
			$inboundNATRule1v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule1v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3387 -BackendPort 3389
			$inboundNATRule2v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule3v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3388 -BackendPort 3389
			Write-Host "`tSuccess" -ForegroundColor Green
		    Write-Host "`n[INFO] - Creating Probe" -ForegroundColor Yellow
			$healthProbe1 = New-AzureRmLoadBalancerProbeConfig -Name "8080HealthProbe-v4" -Protocol Tcp -Port 8080 -IntervalInSeconds 15 -ProbeCount 2
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Probe Rule" -ForegroundColor Yellow
			$lbrule1v4 = New-AzureRmLoadBalancerRuleConfig -Name "HTTPv4" -FrontendIpConfiguration $frontendIPv4 -BackendAddressPool $internaladdresspoolv4 -Probe $healthProbe1 -Protocol Tcp -FrontendPort 80 -BackendPort 8080
		    Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Azure Load Balancer" -ForegroundColor Yellow
		   	$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name "LoadBalancer" -Location $region -FrontendIpConfiguration $frontendIPv4 -InboundNatRule $inboundNATRule1v4,$inboundNATRule2v4 -BackendAddressPool $internaladdresspoolv4 -Probe $healthProbe1 -LoadBalancingRule $lbrule1v4 -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green		
		    Write-Host "`n[INFO] - Creating NIC 1" -ForegroundColor Yellow
			$nic1IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule1v4
			$nic1 = New-AzureRmNetworkInterface -Name "NIC-1" -IpConfiguration $nic1IPv4 -ResourceGroupName $ResourceGroupName -Location $region -NetworkSecurityGroup $NSG -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating NIC 2" -ForegroundColor Yellow
			$nic2IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule2v4
			$nic2 = New-AzureRmNetworkInterface -Name "NIC-2" -IpConfiguration $nic2IPv4 -ResourceGroupName $ResourceGroupName -Location $region -NetworkSecurityGroup $NSG -WarningAction Ignore

	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create load balancer, Exiting." -ForegroundColor Red
        Exit
	}
	#feedback for LoadBalancer
	Write-Host "`tSuccess" -ForegroundColor Green
	
	Try
	{
		If ($AddIP4.count -ge 1)
		{
			foreach ($newip4 in $AddIP4)
				{
				Write-Host "`n[INFO] - Adding IPv4 Address $($newip4.name) to Azure Load Balancer" -ForegroundColor Yellow
				Get-AzureRmLoadBalancer -Name "LoadBalancer" -ResourceGroupName $ResourceGroupName | Add-AzureRmLoadBalancerFrontendIpConfig -Name "LB-Frontendv4-$($newip4.name)" -PublicIpAddress $newip4 | Set-AzureRmLoadBalancer | Out-Null
				}
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to add ip to LoadBalancer, Exiting." -ForegroundColor Red
        Exit
	}
	
$title = "Azure VM Creation"

$message ="Would you like script to create two Azure Virtual Machines?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Creates a Azure Virtual Machine."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Exit the script without Azure Virtual Machine."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {Write-Host "`tYou selected Yes." -ForegroundColor Green; $VM = $true }
        1 {Write-Host "`tYou selected No." -ForegroundColor Gray; Write-Host "`n Press any key to continue ...`n"; $End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); Exit}
    }
	
	Try
	{
		if ($VM = $true)
		{
			$DesktopPath = [Environment]::GetFolderPath("Desktop")
			$availabilitySetName = $DNSName + "availset"
			New-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName -location $region
			$availabilitySet = Get-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName
			$vmName1 = $DNSName + "vm" + 1
			$vmStorageAccount = $DNSName + "storacc"
			$disk1Name = $DNSName + "osdisk1"
			$StorageAccounttitle = "Storage Account"
			$StorageAccountmessage ="Choose storage account type."
			$Standard = New-Object System.Management.Automation.Host.ChoiceDescription "&Standard", `
			"Creates a Standard_LRS Account"
			$Premium = New-Object System.Management.Automation.Host.ChoiceDescription "&Premium", `
			"Creates a Premium_LRS Account."
			$StorageAccountoptions = [System.Management.Automation.Host.ChoiceDescription[]]($Standard, $Premium)
			$StorageAccountresult = $host.ui.PromptForChoice($StorageAccounttitle, $StorageAccountmessage, $StorageAccountoptions, 0) 

			switch ($StorageAccountresult)
			    {
					0 {Write-Host "`tYou selected Standard." -ForegroundColor Green; $LRS = "Standard_LRS" }
			        1 {Write-Host "`tYou selected Premium." -ForegroundColor Green; $LRS = "Premium_LRS" }

			    }
					
			Write-Host "`n[INFO] - Script is creating Virtual Machine $($LRS) storage account in the region $region, Please wait." -ForegroundColor Yellow
			
			New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -Location $region -SkuName $LRS -WarningAction SilentlyContinue | out-null
			#Check to make sure AzureStorageAccount was created
			$CreatedStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			If ($CreatedStorageAccount)
				{
					Write-Host "`tSuccess" -ForegroundColor Green
				}
				Else
				{
					Write-Host "`tFailed to create Storage Account" -ForegroundColor Red
					Exit
				}
			Write-Host "`n[INPUT] - Input for administrative credentials." -ForegroundColor Yellow
			[string]$user = Read-Host "`n `tEnter the local administrator username"
			$secpasswd = Read-Host "`n `tEnter the password for $user" -AsSecureString
			$mySecureCredentials = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
			if ($LRS -eq "Premium_LRS")
			{
			$AllVmSizesPrem = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -like "Standard_DS*") -or ($_.Name -like "Standard_GS*") -or ($_.Name -like "Standard_F*") -or ($_.Name -like "Standard_F*s") -or ($_.Name -like "*_v2")}
			$VMSizeselection = $AllVmSizesPrem | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			Else
			{
			$AllVmSizesStd = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -notlike "Basic_*") -and ($_.Name -notlike "Standard_DS*") -and ($_.Name -notlike "Standard_GS*") -and ($_.Name -notlike "Standard_F*") -and ($_.Name -notlike "Standard_F*s") -and ($_.Name -notlike "*_v2")}
			$VMSizeselection = $AllVmSizesStd | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			$vm1 = New-AzureRmVMConfig -VMName $vmName1 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm1 = Set-AzureRmVMOperatingSystem -VM $vm1 -Windows -ComputerName $vmName1 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm1 = Set-AzureRmVMSourceImage -VM $vm1 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id -Primary
			$osDisk1Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk1Name.vhd"
			$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $disk1Name -VhdUri $osDisk1Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName1), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm1
			#Check to make sure that vm1 was created
			$CreatedVM1 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName1 -ErrorAction SilentlyContinue
			If ($CreatedVM1)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName1 located at $($DesktopPath)\$($vmName1).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName1 -LocalPath "$DesktopPath\$($vmName1).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
			$vmName2 = $DNSName + "vm" + 2
			$disk2Name = $DNSName + "osdisk2"
			$vm2 = New-AzureRmVMConfig -VMName $vmName2 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm2 = Set-AzureRmVMOperatingSystem -VM $vm2 -Windows -ComputerName $vmName2 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm2 = Set-AzureRmVMSourceImage -VM $vm2 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id -Primary
			$osDisk2Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk2Name.vhd"
			$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $disk2Name -VhdUri $osDisk2Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName2), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm2
			#Check to make sure that vm2 was created
			$CreatedVM2 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName2 -ErrorAction SilentlyContinue
			If ($CreatedVM2)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName2 located at $($DesktopPath)\$($vmName2).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName2 -LocalPath "$DesktopPath\$($vmName2).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
		Write-Host "`n[INFO] - Run the following inside each Azure VM" -ForegroundColor Yellow
		Write-Host "`timport-module servermanager" -ForegroundColor White
		Write-Host "`tadd-windowsfeature web-server -includeallsubfeature" -ForegroundColor White
		Write-Host "`timport-module NetSecurity" -ForegroundColor White
		Write-Host "`tNew-NetFirewallRule -Protocol Tcp -LocalPort 8080 -Action Allow -Name `"ILB_Port`" -Profile Any -DisplayName `"ILB_Port`" -Direction Inbound" -ForegroundColor White
		Write-Host "`timport-module webadministration" -ForegroundColor White
		Write-Host "`tNew-WebBinding -Name `"Default Web Site`" -IP `"*`" -Port 8080 -Protocol http" -ForegroundColor White	
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create VM, Exiting." -ForegroundColor Red
	    Exit
	}
	
Write-Host "`n Press any key to continue ...`n"
$End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
}

## Build example IPv6 public IP address load balancer
if ($SelWork -eq "Build example IPv6 public IP address load balancer")
{
	$SelLocationName = ((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Network).ResourceTypes | Where-Object ResourceTypeName -eq virtualNetworks).Locations
	$Location = $SelLocationName | Out-GridView -Title "Select Region" -passthru
	$region = $Location
	
	[string]$cloudSvcName = Read-Host "`n `tWhat do you want the resource group to be named?" 
	$cloudSvcName=$cloudSvcName.tolower() 
	[string]$loadbalancernrp = "$($cloudSvcName)loadbalancer" 
	[string]$ResourceGroupName = "$($loadbalancernrp)-RG"
	
	[string]$DNSName = Read-Host "`n `tWhat DNS label to you want to use?" 
	$DNSName=$DNSName.tolower() 
	
	$DNStest = Test-AzureRmDnsAvailability -DomainNameLabel $DNSName -Location $region
	if($DNStest -eq $false)
	{
	Write-Host "`n[ERROR] - Domain name label $($DNSName) is already in use in location $($region). Exiting." -ForegroundColor Red
	Exit
	}

	Try
	{
		New-AzureRmResourceGroup -Name $ResourceGroupName -location $region -WarningAction Ignore
		Write-Host "`n[INFO] - Creating Vnet" -ForegroundColor Yellow
		$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name LB-Subnet-BE -AddressPrefix 10.0.2.0/24
		$Vnetwork = New-AzureRmvirtualNetwork -Name VNet -ResourceGroupName $ResourceGroupName -Location $region -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet -WarningAction Ignore
		$internaladdresspoolv4 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "BackendPoolIPv4"
		$internaladdresspoolv6 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "BackendPoolIPv6"
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create Vnet, Exiting." -ForegroundColor Red
        Exit
	}
	#feedback to user for Vnet
	Write-Host "`tSuccess" -ForegroundColor Green
	
	[int]$IP4 = Read-Host "`n[INPUT] - How many public IPv4 IP(s) do you need to assign (Max: 20)"
	[int]$IP6 = Read-Host "`n[INPUT] - How many public IPv6 IP(s) do you need to assign (Max: 1)?"
	If ($IP6 -ne 1)
	{
	Write-Host "`n[INFO] - You can only have one public IPv6 IP attached to a load balancer, changing selection to one." -ForegroundColor Gray
	[int]$IP6 = 1
	}
	
	Write-Host "`n[SELECTION] - Allocation method for public IPv4 address" -ForegroundColor Yellow

	$ipinput0 = new-object psobject
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Workload -Value "Dynamic IP allocation" -Force
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Allocation -Value "Dynamic" -Force
	Add-Member -InputObject $ipinput0 -MemberType NoteProperty -Name Max_IP -Value "5" -Force
	$ipinput1 = new-object psobject
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Workload -Value "Static IP allocation" -Force
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Allocation -Value "Static" -Force
	Add-Member -InputObject $ipinput1 -MemberType NoteProperty -Name Max_IP -Value "20" -Force

	[array] $ipInputy += $ipinput0
	[array] $ipInputy += $ipinput1

	$selipWork = $ipInputy | Out-GridView -Title "Select allocation method for public IPv4 address" -PassThru
	$ipWork = $selipWork.Allocation
	
	If(($ipWork -eq "Static")-and($IP4 -gt 20))
	{
		Write-Host "[ERROR] - To many static IPv4 address, Exiting." -ForegroundColor Red
		Exit	
	}

	If(($ipWork -eq "Dynamic")-and($IP4 -gt 5))
	{
		Write-Host "[ERROR] - To many dynamic public IPv4 address, Exiting." -ForegroundColor Red
		Exit
	}
	#feedback to user for ipworkload 
	Write-Host "`n[INFO] - IPv4 $ipWork allocation selected" -ForegroundColor Yellow
	Write-Host "`n[INFO] - IPv6 will be set to Dynamic" -ForegroundColor Gray
	
	#for IPv4 allocation
	Try
	{
		for($j = 1; $j -le $IP4; $j++) 
		{
		      [int]$ipnum = $j
		      $number = "$($loadbalancernrp)$($ipnum)"
			  $DNSLabelv4 = $DNSName+"-pub-ipv4-"+$number
			  $DNSLabelv4test = Test-AzureRmDnsAvailability -DomainNameLabel $DNSLabelv4 -Location $region
			  if($DNSLabelv4test -eq $false)
				{
				Write-Host "`n[ERROR] - Domain name label $($DNSLabelv4) is already in use in location $($region). Exiting." -ForegroundColor Red
				Exit
				}
			  Write-Host "`n[INFO] - Creating IPv4 Address $($ipnum)" -ForegroundColor Yellow
		      $publicIPv4 = New-AzureRmPublicIpAddress -Name "pub-ipv4-$($ipnum)" -ResourceGroupName $ResourceGroupName -Location $region –AllocationMethod $ipWork -IpAddressVersion IPv4 -DomainNameLabel $DNSLabelv4 -WarningAction Ignore
			  Write-Host "`tSuccess" -ForegroundColor Green
			  [Array]$arrpubip4 += $publicIPv4
		}
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create IP address, Exiting." -ForegroundColor Red
        Exit
	}
		
	Try
	{
		#for IPv6 allocation method must be dynamic 
		for($i = 1; $i -le $IP6; $i++) 
		{
		      [int]$ipnum = $i
		      $number = "$($loadbalancernrp)$($ipnum)"
			  $DNSLabelv6 = $DNSName+"-pub-ipv6-"+$number
			  $DNSLabelv6test = Test-AzureRmDnsAvailability -DomainNameLabel $DNSLabelv6 -Location $region
			  if($DNSLabelv6test -eq $false)
				{
				Write-Host "`n[ERROR] - Domain name label $($DNSLabelv6) is already in use in location $($region). Exiting." -ForegroundColor Red
				Exit
				}
			  Write-Host "`n[INFO] - Creating IPv6 Address $($ipnum)" -ForegroundColor Yellow
		      $publicIPv6 = New-AzureRmPublicIpAddress -Name "pub-ipv6-$($ipnum)" -ResourceGroupName $ResourceGroupName -Location $region –AllocationMethod Dynamic -IpAddressVersion IPv6 -DomainNameLabel $DNSLabelv6 -WarningAction Ignore
		      Write-Host "`tSuccess" -ForegroundColor Green
			  [Array]$arrpubip6 += $publicIPv6
		}
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create IP address, Exiting." -ForegroundColor Red
        Exit
	}
	
	Try
	{
		$w=0
		foreach ($u in $arrpubip4)
		{
			If($w -eq 0) 
			{$frontendIPv4 = New-AzureRmLoadBalancerFrontendIpConfig -Name "LB-Frontendv4-$($u.name)" -PublicIpAddress $u; $w++}
			elseif ($w -ge 1){[Array]$AddIP4 += $u}
		}
				
		$q=0
		foreach ($y in $arrpubip6)
		{
		      If($q -eq 0) 
			  {$frontendIPv6 = New-AzureRmLoadBalancerFrontendIpConfig -Name "LB-Frontendv6-$($Y.name)" -PublicIpAddress $y; $q++}
		      elseif ($q -ge 1){[Array]$AddIP6 += $y}
		}

		    Write-Host "`n[INFO] - Creating Nat Rules" -ForegroundColor Yellow
		    $inboundNATRule1v6 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule1v6" -FrontendIpConfiguration $frontendIPv6 -Protocol TCP -FrontendPort 3388 -BackendPort 3389
			$inboundNATRule1v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule1v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3388 -BackendPort 3389
		    $inboundNATRule2v6 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule2v6" -FrontendIpConfiguration $frontendIPv6 -Protocol TCP -FrontendPort 3387 -BackendPort 3389
			$inboundNATRule2v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule2v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3387 -BackendPort 3389
			Write-Host "`tSuccess" -ForegroundColor Green
		    Write-Host "`n[INFO] - Creating Probe" -ForegroundColor Yellow
			$healthProbe1 = New-AzureRmLoadBalancerProbeConfig -Name "8080HealthProbe-v4-v6" -Protocol Tcp -Port 8080 -IntervalInSeconds 15 -ProbeCount 2
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Probe Rule" -ForegroundColor Yellow
			$lbrule1v4 = New-AzureRmLoadBalancerRuleConfig -Name "HTTPv4" -FrontendIpConfiguration $frontendIPv4 -BackendAddressPool $internaladdresspoolv4 -Probe $healthProbe1 -Protocol Tcp -FrontendPort 80 -BackendPort 8080
			$lbrule1v6 = New-AzureRmLoadBalancerRuleConfig -Name "HTTPv6" -FrontendIpConfiguration $frontendIPv6 -BackendAddressPool $internaladdresspoolv6 -Probe $healthProbe1 -Protocol Tcp -FrontendPort 80 -BackendPort 8080
		    Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Azure Load Balancer" -ForegroundColor Yellow
		   	$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name "LoadBalancer" -Location $region -FrontendIpConfiguration $frontendIPv4, $frontendIPv6 -InboundNatRule $inboundNATRule1v6, $inboundNATRule1v4, $inboundNATRule2v6, $inboundNATRule2v4 -BackendAddressPool $internaladdresspoolv4, $internaladdresspoolv6 -Probe $healthProbe1 -LoadBalancingRule $lbrule1v4, $lbrule1v6 -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green		
		    Write-Host "`n[INFO] - Creating NIC 1" -ForegroundColor Yellow
			$nic1IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule1v4
			$nic1IPv6 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv6IPConfig" -PrivateIpAddressVersion "IPv6" -LoadBalancerBackendAddressPool $internaladdresspoolv6 -LoadBalancerInboundNatRule $inboundNATRule1v6
			$nic1 = New-AzureRmNetworkInterface -Name "NIC-1" -IpConfiguration $nic1IPv4,$nic1IPv6 -ResourceGroupName $ResourceGroupName -Location $region -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating NIC 2" -ForegroundColor Yellow
			$nic2IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule2v4
			$nic2IPv6 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv6IPConfig" -PrivateIpAddressVersion "IPv6" -LoadBalancerBackendAddressPool $internaladdresspoolv6 -LoadBalancerInboundNatRule $inboundNATRule2v6
			$nic2 = New-AzureRmNetworkInterface -Name "NIC-2" -IpConfiguration $nic2IPv4, $nic2IPv6 -ResourceGroupName $ResourceGroupName -Location $region -WarningAction Ignore
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create load balancer, Exiting." -ForegroundColor Red
        Exit
	}
	#feedback for LoadBalancer
	Write-Host "`tSuccess" -ForegroundColor Green

	Try
	{
		If ($AddIP4.count -ge 1)
		{
			foreach ($newip4 in $AddIP4)
				{
				Write-Host "`n[INFO] - Adding IPv4 Address $($newip4.name) to Azure Load Balancer" -ForegroundColor Yellow
				Get-AzureRmLoadBalancer -Name "LoadBalancer" -ResourceGroupName $ResourceGroupName | Add-AzureRmLoadBalancerFrontendIpConfig -Name "LB-Frontendv4-$($newip4.name)" -PublicIpAddress $newip4 | Set-AzureRmLoadBalancer | Out-Null
				Write-Host "`tSuccess" -ForegroundColor Green
				}
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to add ip to LoadBalancer, Exiting." -ForegroundColor Red
        Exit
	}

$title = "Azure IPv6 enabled network interface controller(s) require a new Azure VM image deployment"

$message ="Would you like script to create two Azure Virtual Machines?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Creates a Azure Virtual Machine."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Exit the script without Azure Virtual Machine."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {Write-Host "`tYou selected Yes." -ForegroundColor Green; $VM = $true }
        1 {Write-Host "`tYou selected No." -ForegroundColor Gray; Write-Host "`n Press any key to continue ...`n"; $End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); Exit}
    }
	
	Try
	{
		if ($VM = $true)
		{
			$DesktopPath = [Environment]::GetFolderPath("Desktop")
			$availabilitySetName = $DNSName + "availset"
			New-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName -location $region
			$availabilitySet = Get-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName
			$vmName1 = $DNSName + "vm" + 1
			$vmStorageAccount = $DNSName + "storacc"
			$disk1Name = $DNSName + "osdisk1"
			$StorageAccounttitle = "Storage Account"
			$StorageAccountmessage ="Choose storage account type."
			$Standard = New-Object System.Management.Automation.Host.ChoiceDescription "&Standard", `
			"Creates a Standard_LRS Account"
			$Premium = New-Object System.Management.Automation.Host.ChoiceDescription "&Premium", `
			"Creates a Premium_LRS Account."
			$StorageAccountoptions = [System.Management.Automation.Host.ChoiceDescription[]]($Standard, $Premium)
			$StorageAccountresult = $host.ui.PromptForChoice($StorageAccounttitle, $StorageAccountmessage, $StorageAccountoptions, 0) 

			switch ($StorageAccountresult)
			    {
					0 {Write-Host "`tYou selected Standard." -ForegroundColor Green; $LRS = "Standard_LRS" }
			        1 {Write-Host "`tYou selected Premium." -ForegroundColor Green; $LRS = "Premium_LRS" }

			    }
					
			Write-Host "`n[INFO] - Script is creating Virtual Machine $($LRS) storage account in the region $region, Please wait." -ForegroundColor Yellow
			
			New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -Location $region -SkuName $LRS -WarningAction SilentlyContinue | out-null
			#Check to make sure AzureStorageAccount was created
			$CreatedStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			If ($CreatedStorageAccount)
				{
					Write-Host "`tSuccess" -ForegroundColor Green
				}
				Else
				{
					Write-Host "`tFailed to create Storage Account" -ForegroundColor Red
					Exit
				}
			Write-Host "`n[INPUT] - Input for administrative credentials." -ForegroundColor Yellow
			[string]$user = Read-Host "`n `tEnter the local administrator username"
			$secpasswd = Read-Host "`n `tEnter the password for $user" -AsSecureString
			$mySecureCredentials = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
			if ($LRS -eq "Premium_LRS")
			{
			$AllVmSizesPrem = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -like "Standard_DS*") -or ($_.Name -like "Standard_GS*") -or ($_.Name -like "Standard_F*") -or ($_.Name -like "Standard_F*s") -or ($_.Name -like "*_v2")}
			$VMSizeselection = $AllVmSizesPrem | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			Else
			{
			$AllVmSizesStd = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -notlike "Basic_*") -and ($_.Name -notlike "Standard_DS*") -and ($_.Name -notlike "Standard_GS*") -and ($_.Name -notlike "Standard_F*") -and ($_.Name -notlike "Standard_F*s") -and ($_.Name -notlike "*_v2")}
			$VMSizeselection = $AllVmSizesStd | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			$vm1 = New-AzureRmVMConfig -VMName $vmName1 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm1 = Set-AzureRmVMOperatingSystem -VM $vm1 -Windows -ComputerName $vmName1 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm1 = Set-AzureRmVMSourceImage -VM $vm1 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id -Primary
			$osDisk1Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk1Name.vhd"
			$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $disk1Name -VhdUri $osDisk1Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName1), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm1
			#Check to make sure that vm1 was created
			$CreatedVM1 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName1 -ErrorAction SilentlyContinue
			If ($CreatedVM1)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName1 located at $($DesktopPath)\$($vmName1).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName1 -LocalPath "$DesktopPath\$($vmName1).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
			$vmName2 = $DNSName + "vm" + 2
			$disk2Name = $DNSName + "osdisk2"
			$vm2 = New-AzureRmVMConfig -VMName $vmName2 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm2 = Set-AzureRmVMOperatingSystem -VM $vm2 -Windows -ComputerName $vmName2 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm2 = Set-AzureRmVMSourceImage -VM $vm2 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id -Primary
			$osDisk2Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk2Name.vhd"
			$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $disk2Name -VhdUri $osDisk2Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName2), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm2
			#Check to make sure that vm2 was created
			$CreatedVM2 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName2 -ErrorAction SilentlyContinue
			If ($CreatedVM2)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName2 located at $($DesktopPath)\$($vmName2).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName2 -LocalPath "$DesktopPath\$($vmName2).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
		Write-Host "`n[WARNING] - Using NSG(s) is not possable to use with an IPv6 enabled load balancer" -ForegroundColor Magenta
		Write-Host "`n[INFO] - Run the following inside each Azure VM" -ForegroundColor Yellow
		Write-Host "`timport-module servermanager" -ForegroundColor White
		Write-Host "`tadd-windowsfeature web-server -includeallsubfeature" -ForegroundColor White
		Write-Host "`timport-module NetSecurity" -ForegroundColor White
		Write-Host "`tNew-NetFirewallRule -Protocol Tcp -LocalPort 8080 -Action Allow -Name `"ILB_Port`" -Profile Any -DisplayName `"ILB_Port`" -Direction Inbound" -ForegroundColor White
		Write-Host "`timport-module webadministration" -ForegroundColor White
		Write-Host "`tNew-WebBinding -Name `"Default Web Site`" -IP `"*`" -Port 8080 -Protocol http" -ForegroundColor White	
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create VM, Exiting." -ForegroundColor Red
	    Exit
	}
Write-Host "`n Press any key to continue ...`n"
$End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
}
## Build example IPv4 private  IP address load balancer
if ($SelWork -eq "Build example IPv4 private IP address load balancer")
{
	$SelLocationName = ((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Network).ResourceTypes | Where-Object ResourceTypeName -eq virtualNetworks).Locations
	$Location = $SelLocationName | Out-GridView -Title "Select Region" -passthru
	$region = $Location
	
	[string]$cloudSvcName = Read-Host "`n `tWhat do you want the resource group to be named?" 
	$cloudSvcName=$cloudSvcName.tolower() 
	[string]$loadbalancernrp = "$($cloudSvcName)loadbalancer" 
	[string]$ResourceGroupName = "$($loadbalancernrp)-RG"
	
	[string]$DNSName = Read-Host "`n `tWhat DNS label to you want to use?" 
	$DNSName=$DNSName.tolower() 
	
	$DNStest = Test-AzureRmDnsAvailability -DomainNameLabel $DNSName -Location $region
	if($DNStest -eq $false)
	{
	Write-Host "`n[ERROR] - Domain name label $($DNSName) is already in use in location $($region). Exiting." -ForegroundColor Red
	Exit
	}
	
	Try
	{
		New-AzureRmResourceGroup -Name $ResourceGroupName -location $region -WarningAction Ignore
		Write-Host "`n[INFO] - Creating Vnet" -ForegroundColor Yellow
		$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name LB-Subnet-BE -AddressPrefix 10.0.2.0/24
		$Vnetwork = New-AzureRmvirtualNetwork -Name VNet -ResourceGroupName $ResourceGroupName -Location $region -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet -WarningAction Ignore
		$internaladdresspoolv4 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "BackendPoolIPv4"
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create Vnet, Exiting." -ForegroundColor Red
        Exit
	}
	Write-Host "`tSuccess" -ForegroundColor Green
	
	$SubnetId = $Vnetwork.Subnets.id
	$AddressPrefix = $backendSubnet.AddressPrefix
	$AddressPrefixIp,$AddressPrefixMask = $AddressPrefix.Split("/")

	[int]$IP4 = Read-Host "`n[INPUT] - How many private IPv4 IP(s) do you need to assign? (Max: 20)"
	
	If($IP4 -gt 20)
	{
		Write-Host "[ERROR] - To many static IPv4 address, Exiting." -ForegroundColor Red
		Exit	
	}
	
	$test = 5
	for($i=1; $i -le $IP4; $i++)
	{
		$testip = [Regex]::Replace($AddressPrefixIp, '\d{1,3}$', {[Int]$Args[0].Value + 5 + $i})
		[Array]$arrprivip4 += $testip
	}

	Try
	{
		for($j = 1; $j -le 2; $j++) 
		{
	      [int]$ipnum = $j
	      $number = "$($loadbalancernrp)$($ipnum)"
		  $DNSLabelv4 = $DNSName+"-pub-ipv4-"+$number
		  $DNSLabelv4test = Test-AzureRmDnsAvailability -DomainNameLabel $DNSLabelv4 -Location $region
		  if($DNSLabelv4test -eq $false)
			{
			Write-Host "`n[ERROR] - Domain name label $($DNSLabelv4) is already in use in location $($region). Exiting." -ForegroundColor Red
			Exit
			}
		  Write-Host "`n[INFO] - Creating public address $($ipnum) for non load balanced access to VM" -ForegroundColor Yellow
	      $publicIPv4 = New-AzureRmPublicIpAddress -Name "pub-ipv4-$($ipnum)" -ResourceGroupName $ResourceGroupName -Location $region –AllocationMethod "Dynamic" -IpAddressVersion IPv4 -DomainNameLabel $DNSLabelv4 -WarningAction Ignore
		  Write-Host "`tSuccess" -ForegroundColor Green
		  [Array]$arrpubip4 += $publicIPv4
		}
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create IP address, Exiting." -ForegroundColor Red
        Exit
	}
	Try
	{
		$NSGName = $DNSName+"-NSG"
		Write-Host "`n[INFO] - Creating NSG to allow RDP, HTTP for NIC" -ForegroundColor Yellow
		$NSGRule1 = New-AzureRmNetworkSecurityRuleConfig -Name "default-allow-rdp" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3387-3389"
		$NSGRule2 = New-AzureRmNetworkSecurityRuleConfig -Name "allow-Http" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 8080
		$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $region -SecurityRules $NSGRule1,$NSGRule2 -WarningAction Ignore
		Write-Host "`tSuccess" -ForegroundColor Green
	}
	Catch [Exception]
	{
	    Write-Host "[ERROR] - Not able to create NSG, Exiting." -ForegroundColor Red
        Exit
	}
	Try
	{
		$w=0
		[int]$number = 1
		foreach ($u in $arrprivip4)
		{
			If($w -eq 0) 
			{$frontendIPv4 = New-AzureRmLoadBalancerFrontendIpConfig -Name "LB$($number)-PrivateFrontEndv4" -PrivateIpAddress $u -SubnetId $SubnetId; $w++; $number++}
			elseif ($w -ge 1){[Array]$AddIP4 += $u}
		}
		
			Write-Host "`n[INFO] - Creating Nat Rules" -ForegroundColor Yellow
			$inboundNATRule1v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule1v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3388 -BackendPort 3388
			$inboundNATRule2v4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "NicNatRule2v4" -FrontendIpConfiguration $frontendIPv4 -Protocol TCP -FrontendPort 3387 -BackendPort 3387
			Write-Host "`tSuccess" -ForegroundColor Green
		    Write-Host "`n[INFO] - Creating Probe" -ForegroundColor Yellow
			$healthProbe1 = New-AzureRmLoadBalancerProbeConfig -Name "8080HealthProbe-v4" -Protocol Tcp -Port 8080 -IntervalInSeconds 15 -ProbeCount 2
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Probe Rule" -ForegroundColor Yellow
			$lbrule1v4 = New-AzureRmLoadBalancerRuleConfig -Name "HTTPv4" -FrontendIpConfiguration $frontendIPv4 -BackendAddressPool $internaladdresspoolv4 -Probe $healthProbe1 -Protocol Tcp -FrontendPort 80 -BackendPort 8080
		    Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating Azure Load Balancer" -ForegroundColor Yellow
		   	$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name "LoadBalancer" -Location $region -FrontendIpConfiguration $frontendIPv4 -InboundNatRule $inboundNATRule1v4,$inboundNATRule2v4 -BackendAddressPool $internaladdresspoolv4 -Probe $healthProbe1 -LoadBalancingRule $lbrule1v4 -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green		
		    Write-Host "`n[INFO] - Creating NIC 1" -ForegroundColor Yellow
			$nic1IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -PublicIpAddress $arrpubip4[0] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule1v4
			$nic1 = New-AzureRmNetworkInterface -Name "NIC-1" -IpConfiguration $nic1IPv4 -ResourceGroupName $ResourceGroupName -Location $region -NetworkSecurityGroup $NSG -WarningAction Ignore
			Write-Host "`tSuccess" -ForegroundColor Green
			Write-Host "`n[INFO] - Creating NIC 2" -ForegroundColor Yellow
			$nic2IPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $Vnetwork.Subnets[0] -PublicIpAddress $arrpubip4[1] -LoadBalancerBackendAddressPool $internaladdresspoolv4 -LoadBalancerInboundNatRule $inboundNATRule2v4
			$nic2 = New-AzureRmNetworkInterface -Name "NIC-2" -IpConfiguration $nic2IPv4 -ResourceGroupName $ResourceGroupName -Location $region -NetworkSecurityGroup $NSG -WarningAction Ignore
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create load balancer, Exiting." -ForegroundColor Red
        Exit
	}
	#feedback for LoadBalancer
	Write-Host "`tSuccess" -ForegroundColor Green
	
	Try
	{
		If ($AddIP4.count -ge 1)
		{
			foreach ($newip4 in $AddIP4)
				{
				Write-Host "`n[INFO] - Adding IPv4 Address $($number) to Load Balancer" -ForegroundColor Yellow
				Get-AzureRmLoadBalancer -Name "LoadBalancer" -ResourceGroupName $ResourceGroupName | Add-AzureRmLoadBalancerFrontendIpConfig -Name "LB$($number)-PrivateFrontEndv4" -PrivateIpAddress $newip4 -SubnetId $SubnetId | Set-AzureRmLoadBalancer | Out-Null
				Write-Host "`tSuccess" -ForegroundColor Green
				$number++
				}
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to add ip to LoadBalancer, Exiting." -ForegroundColor Red
        Exit
	}
	
$title = "Azure VM Creation"

$message ="Would you like script to create two Azure Virtual Machines?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Creates a Azure Virtual Machine."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Exit the script without Azure Virtual Machine."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {Write-Host "`tYou selected Yes." -ForegroundColor Green; $VM = $true }
        1 {Write-Host "`tYou selected No." -ForegroundColor Gray; Write-Host "`n Press any key to continue ...`n"; $End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); Exit}
    }
	
	Try
	{
		if ($VM = $true)
		{
			$DesktopPath = [Environment]::GetFolderPath("Desktop")
			$availabilitySetName = $DNSName + "availset"
			New-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName -location $region
			$availabilitySet = Get-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $ResourceGroupName
			$vmName1 = $DNSName + "vm" + 1
			$vmStorageAccount = $DNSName + "storacc"
			$disk1Name = $DNSName + "osdisk1"
			$StorageAccounttitle = "Storage Account"
			$StorageAccountmessage ="Choose storage account type."
			$Standard = New-Object System.Management.Automation.Host.ChoiceDescription "&Standard", `
			"Creates a Standard_LRS Account"
			$Premium = New-Object System.Management.Automation.Host.ChoiceDescription "&Premium", `
			"Creates a Premium_LRS Account."
			$StorageAccountoptions = [System.Management.Automation.Host.ChoiceDescription[]]($Standard, $Premium)
			$StorageAccountresult = $host.ui.PromptForChoice($StorageAccounttitle, $StorageAccountmessage, $StorageAccountoptions, 0) 

			switch ($StorageAccountresult)
			    {
					0 {Write-Host "`tYou selected Standard." -ForegroundColor Green; $LRS = "Standard_LRS" }
			        1 {Write-Host "`tYou selected Premium." -ForegroundColor Green; $LRS = "Premium_LRS" }

			    }
					
			Write-Host "`n[INFO] - Script is creating Virtual Machine $($LRS) storage account in the region $region, Please wait." -ForegroundColor Yellow
			
			New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -Location $region -SkuName $LRS -WarningAction SilentlyContinue | out-null
			#Check to make sure AzureStorageAccount was created
			$CreatedStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $vmStorageAccount -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			If ($CreatedStorageAccount)
				{
					Write-Host "`tSuccess" -ForegroundColor Green
				}
				Else
				{
					Write-Host "`tFailed to create Storage Account" -ForegroundColor Red
					Exit
				}
			Write-Host "`n[INPUT] - Input for administrative credentials." -ForegroundColor Yellow
			[string]$user = Read-Host "`n `tEnter the local administrator username"
			$secpasswd = Read-Host "`n `tEnter the password for $user" -AsSecureString
			$mySecureCredentials = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
			if ($LRS -eq "Premium_LRS")
			{
			$AllVmSizesPrem = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -like "Standard_DS*") -or ($_.Name -like "Standard_GS*") -or ($_.Name -like "Standard_F*") -or ($_.Name -like "Standard_F*s") -or ($_.Name -like "*_v2")}
			$VMSizeselection = $AllVmSizesPrem | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			Else
			{
			$AllVmSizesStd = Get-AzureRmVMSize -Location $region | Where-Object {($_.Name -notlike "Basic_*") -and ($_.Name -notlike "Standard_DS*") -and ($_.Name -notlike "Standard_GS*") -and ($_.Name -notlike "Standard_F*") -and ($_.Name -notlike "Standard_F*s") -and ($_.Name -notlike "*_v2")}
			$VMSizeselection = $AllVmSizesStd | Select-Object Name,MemoryInMB,NumberOfCores,MaxDataDiskCount | Sort-Object -Property nameMaxDataDiskCount,MemoryInMb | Out-GridView -Title "What size of Azure VM do you want?" -PassThru
			}
			$vm1 = New-AzureRmVMConfig -VMName $vmName1 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm1 = Set-AzureRmVMOperatingSystem -VM $vm1 -Windows -ComputerName $vmName1 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm1 = Set-AzureRmVMSourceImage -VM $vm1 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id -Primary
			$osDisk1Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk1Name.vhd"
			$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $disk1Name -VhdUri $osDisk1Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName1), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm1
			#Check to make sure that vm1 was created
			$CreatedVM1 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName1 -ErrorAction SilentlyContinue
			If ($CreatedVM1)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName1 located at $($DesktopPath)\$($vmName1).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName1 -LocalPath "$DesktopPath\$($vmName1).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
			$vmName2 = $DNSName + "vm" + 2
			$disk2Name = $DNSName + "osdisk2"
			$vm2 = New-AzureRmVMConfig -VMName $vmName2 -VMSize $VMSizeselection.Name -AvailabilitySetId $availabilitySet.Id
			$vm2 = Set-AzureRmVMOperatingSystem -VM $vm2 -Windows -ComputerName $vmName2 -Credential $mySecureCredentials -ProvisionVMAgent -EnableAutoUpdate
			$vm2 = Set-AzureRmVMSourceImage -VM $vm2 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
			$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id -Primary
			$osDisk2Uri = $CreatedStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/$disk2Name.vhd"
			$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $disk2Name -VhdUri $osDisk2Uri -CreateOption FromImage
			Write-Host "`n[INFO] - Script is creating $($vmName2), Please wait." -ForegroundColor Yellow
			New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $region -VM $vm2
			#Check to make sure that vm2 was created
			$CreatedVM2 = get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName2 -ErrorAction SilentlyContinue
			If ($CreatedVM2)
			{
				Write-Host "`tSuccess" -ForegroundColor Green
				Write-Host "`n[INFO] - Script is creating RDP file for $vmName2 located at $($DesktopPath)\$($vmName2).rdp" -ForegroundColor Yellow
				Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $vmName2 -LocalPath "$DesktopPath\$($vmName2).rdp"
				Write-Host "`tSuccess" -ForegroundColor Green
			}
			Else
			{
				Write-Host "`tFailed to create VM" -ForegroundColor Red
				Exit
			}
		Write-Host "`n[INFO] - Run the following inside each Azure VM" -ForegroundColor Yellow
		Write-Host "`timport-module servermanager" -ForegroundColor White
		Write-Host "`tadd-windowsfeature web-server -includeallsubfeature" -ForegroundColor White
		Write-Host "`timport-module NetSecurity" -ForegroundColor White
		Write-Host "`tNew-NetFirewallRule -Protocol Tcp -LocalPort 8080 -Action Allow -Name `"ILB_Port`" -Profile Any -DisplayName `"ILB_Port`" -Direction Inbound" -ForegroundColor White
		Write-Host "`timport-module webadministration" -ForegroundColor White
		Write-Host "`tNew-WebBinding -Name `"Default Web Site`" -IP `"*`" -Port 8080 -Protocol http" -ForegroundColor White	
		}
	}
	Catch [Exception]
	{
		Write-Host "[ERROR] - Not able to create VM, Exiting." -ForegroundColor Red
	    Exit
	}
	
Write-Host "`n Press any key to continue ...`n"
$End = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
}