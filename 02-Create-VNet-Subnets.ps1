<#
.SYNOPSIS
    Creates Azure Virtual Network with App and Data subnets. 🌐

.DESCRIPTION
    This script creates a Virtual Network (VNet) with two subnets:
    - App Subnet: For hosting application VMs
    - Data Subnet: For hosting database servers

.EXAMPLE
    .\02-Create-VNet-Subnets.ps1

.NOTES
    Author: Reid Patrick
    Blog: https://kelomai.io
    Requires: Azure CLI installed and authenticated (az login)
#>

# Configuration parameters
$resourceGroup = "rg-network-eastus"
$location = "eastus"
$vnetName = "vnet-prod-eastus"
$addressSpace = "10.0.0.0/16"

# Define subnets
$subnets = @(
    @{
        Name          = "snet-app"
        AddressPrefix = "10.0.1.0/24"
    },
    @{
        Name          = "snet-data"
        AddressPrefix = "10.0.2.0/24"
    }
)

Write-Host -ForegroundColor Cyan "=========================================="
Write-Host -ForegroundColor Cyan "🌐 Azure VNet and Subnet Creation Script"
Write-Host -ForegroundColor Cyan "=========================================="
Write-Host ""

# Validate subnet address prefixes fall within VNet address space
function Test-SubnetInVNet {
    param (
        [string]$VNetCIDR,
        [string]$SubnetCIDR
    )

    # Simple validation - in production, use more robust IP address validation
    $vnetParts = $VNetCIDR.Split('/')
    $subnetParts = $SubnetCIDR.Split('/')

    # Check if the subnet mask is larger (more specific) than VNet mask
    if ([int]$subnetParts[1] -le [int]$vnetParts[1]) {
        return $false
    }

    # For /16 VNet (10.0.0.0/16), check first 2 octets match (10.0)
    # For /24 subnet (10.0.1.0/24), this should be within range
    $vnetMask = [int]$vnetParts[1]
    $octetsToCheck = [Math]::Floor($vnetMask / 8)

    if ($octetsToCheck -gt 0) {
        $vnetOctets = $vnetParts[0].Split('.')
        $subnetOctets = $subnetParts[0].Split('.')

        for ($i = 0; $i -lt $octetsToCheck; $i++) {
            if ($vnetOctets[$i] -ne $subnetOctets[$i]) {
                return $false
            }
        }
    }

    return $true
}

# Validate all subnets
Write-Host -ForegroundColor Blue "🔍 Validating subnet address spaces..."
foreach ($subnet in $subnets) {
    if (-not (Test-SubnetInVNet -VNetCIDR $addressSpace -SubnetCIDR $subnet.AddressPrefix)) {
        Write-Host -ForegroundColor Red "❌ Subnet '$($subnet.Name)' address prefix '$($subnet.AddressPrefix)' is not within VNet address space '$addressSpace'"
        exit 1
    }
    Write-Host -ForegroundColor Green "✅ Subnet '$($subnet.Name)' validated successfully"
}
Write-Host ""

# Create the Virtual Network
try {
    Write-Host -ForegroundColor Blue "🏗️  Creating Virtual Network '$vnetName' in resource group '$resourceGroup'..."
    az network vnet create `
        --resource-group $resourceGroup `
        --name $vnetName `
        --location $location `
        --address-prefix $addressSpace | Out-Null
    Write-Host -ForegroundColor Green "✅ Virtual Network '$vnetName' created successfully."
    Write-Host ""
}
catch {
    Write-Host -ForegroundColor Red "❌ Failed to create Virtual Network '$vnetName'. Error: $_"
    exit 1
}

# Create each subnet
foreach ($subnet in $subnets) {
    try {
        Write-Host -ForegroundColor Blue "🔧 Creating subnet '$($subnet.Name)' with address prefix '$($subnet.AddressPrefix)'..."
        az network vnet subnet create `
            --resource-group $resourceGroup `
            --vnet-name $vnetName `
            --name $subnet.Name `
            --address-prefix $subnet.AddressPrefix | Out-Null
        Write-Host -ForegroundColor Green "✅ Subnet '$($subnet.Name)' created successfully."
        Write-Host ""
    }
    catch {
        Write-Host -ForegroundColor Red "❌ Failed to create subnet '$($subnet.Name)'. Error: $_"
        exit 1
    }
}

Write-Host -ForegroundColor Green "=========================================="
Write-Host -ForegroundColor Green "🎉 VNet and subnets created successfully!"
Write-Host -ForegroundColor Green "=========================================="
Write-Host ""
Write-Host -ForegroundColor Cyan "📊 Summary:"
Write-Host "  VNet Name: $vnetName"
Write-Host "  Address Space: $addressSpace"
Write-Host "  Subnets:"
foreach ($subnet in $subnets) {
    Write-Host "    - $($subnet.Name): $($subnet.AddressPrefix)"
}
