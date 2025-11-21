<#
.SYNOPSIS
    Creates and configures Network Security Groups for App and Data subnets.

.DESCRIPTION
    This script creates NSGs with rules to secure App and Data subnets:
    - App Subnet: Allows HTTP/HTTPS inbound, PostgreSQL outbound to Data subnet
    - Data Subnet: Allows PostgreSQL from App subnet only, denies all outbound

.EXAMPLE
    .\03-Create-NSGs.ps1

.NOTES
    Author: Reid Patrick
    Blog: https://kelomai.io
    Requires: Azure CLI installed and authenticated (az login)
#>

# Configuration parameters
$vnetResourceGroupName = "rg-network-eastus"
$nsgResourceGroupName = "rg-network-eastus"
$vnetName = "vnet-prod-eastus"
$vnetLocation = "eastus"

# Define subnet configurations with NSG rules
$subnetsConfig = @{
    "snet-app"  = @{
        InboundRules  = @(
            @{
                Name                       = "AllowHTTPFromInternet"
                Priority                   = 100
                Direction                  = "Inbound"
                Access                     = "Allow"
                Protocol                   = "Tcp"
                SourceAddressPrefixes      = @("Internet")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("80")
            },
            @{
                Name                       = "AllowHTTPSFromInternet"
                Priority                   = 110
                Direction                  = "Inbound"
                Access                     = "Allow"
                Protocol                   = "Tcp"
                SourceAddressPrefixes      = @("Internet")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("443")
            },
            @{
                Name                       = "DenyAllInbound"
                Priority                   = 4096
                Direction                  = "Inbound"
                Access                     = "Deny"
                Protocol                   = "*"
                SourceAddressPrefixes      = @("*")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("*")
            }
        )
        OutboundRules = @(
            @{
                Name                       = "AllowToDataSubnet"
                Priority                   = 100
                Direction                  = "Outbound"
                Access                     = "Allow"
                Protocol                   = "Tcp"
                SourceAddressPrefixes      = @("*")
                DestinationAddressPrefixes = @("10.0.2.0/24")
                DestinationPortRanges      = @("5432")
            },
            @{
                Name                       = "DenyAllOutbound"
                Priority                   = 4096
                Direction                  = "Outbound"
                Access                     = "Deny"
                Protocol                   = "*"
                SourceAddressPrefixes      = @("*")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("*")
            }
        )
    }
    "snet-data" = @{
        InboundRules  = @(
            @{
                Name                       = "AllowFromAppSubnet"
                Priority                   = 100
                Direction                  = "Inbound"
                Access                     = "Allow"
                Protocol                   = "Tcp"
                SourceAddressPrefixes      = @("10.0.1.0/24")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("5432")
            },
            @{
                Name                       = "DenyAllInbound"
                Priority                   = 4096
                Direction                  = "Inbound"
                Access                     = "Deny"
                Protocol                   = "*"
                SourceAddressPrefixes      = @("*")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("*")
            }
        )
        OutboundRules = @(
            @{
                Name                       = "DenyAllOutbound"
                Priority                   = 4096
                Direction                  = "Outbound"
                Access                     = "Deny"
                Protocol                   = "*"
                SourceAddressPrefixes      = @("*")
                DestinationAddressPrefixes = @("*")
                DestinationPortRanges      = @("*")
            }
        )
    }
}

Write-Host -ForegroundColor Cyan "=========================================="
Write-Host -ForegroundColor Cyan "Azure NSG Creation and Configuration Script"
Write-Host -ForegroundColor Cyan "=========================================="
Write-Host ""

# Function to create NSG rules
function Create-NSGRule {
    param (
        [string]$resourceGroup,
        [string]$nsgName,
        [string]$ruleName,
        [int]$priority,
        [string]$direction,
        [string]$access,
        [string]$protocol,
        [array]$sourceAddressPrefixes,
        [array]$destinationAddressPrefixes,
        [array]$destinationPortRanges
    )

    Write-Host -ForegroundColor Blue "  Creating rule: $ruleName (Priority: $priority, Direction: $direction, Access: $access)"

    try {
        $sourceAddressPrefix = $sourceAddressPrefixes -join ","
        $destinationAddressPrefix = $destinationAddressPrefixes -join ","
        $destinationPortRange = $destinationPortRanges -join ","

        az network nsg rule create `
            --resource-group $resourceGroup `
            --nsg-name $nsgName `
            --name $ruleName `
            --priority $priority `
            --direction $direction `
            --access $access `
            --protocol $protocol `
            --source-address-prefixes $sourceAddressPrefix `
            --destination-address-prefixes $destinationAddressPrefix `
            --destination-port-ranges $destinationPortRange | Out-Null

        Write-Host -ForegroundColor Green "  ✓ Rule '$ruleName' created successfully"
    }
    catch {
        Write-Host -ForegroundColor Red "  ✗ Failed to create rule '$ruleName'. Error: $_"
        throw
    }
}

# Create NSGs and associate them with subnets
foreach ($subnetName in $subnetsConfig.Keys) {
    $nsgName = "nsg-$vnetName-$subnetName"

    Write-Host -ForegroundColor Blue "Creating NSG: $nsgName in resource group: $nsgResourceGroupName"
    az network nsg create --location $vnetLocation --name $nsgName --resource-group $nsgResourceGroupName | Out-Null
    Write-Host -ForegroundColor Green "✓ NSG '$nsgName' created successfully"
    Write-Host ""

    Write-Host -ForegroundColor Blue "Associating NSG: $nsgName with subnet: $subnetName"
    az network vnet subnet update --name $subnetName --network-security-group $nsgName --resource-group $vnetResourceGroupName --vnet-name $vnetName | Out-Null
    Write-Host -ForegroundColor Green "✓ NSG associated with subnet successfully"
    Write-Host ""

    # Create inbound rules
    Write-Host -ForegroundColor Cyan "Creating Inbound Rules for $nsgName:"
    foreach ($rule in $subnetsConfig[$subnetName].InboundRules) {
        Create-NSGRule -resourceGroup $nsgResourceGroupName -nsgName $nsgName `
            -ruleName $rule.Name `
            -priority $rule.Priority `
            -direction $rule.Direction `
            -access $rule.Access `
            -protocol $rule.Protocol `
            -sourceAddressPrefixes $rule.SourceAddressPrefixes `
            -destinationAddressPrefixes $rule.DestinationAddressPrefixes `
            -destinationPortRanges $rule.DestinationPortRanges
    }
    Write-Host ""

    # Create outbound rules
    Write-Host -ForegroundColor Cyan "Creating Outbound Rules for $nsgName:"
    foreach ($rule in $subnetsConfig[$subnetName].OutboundRules) {
        Create-NSGRule -resourceGroup $nsgResourceGroupName -nsgName $nsgName `
            -ruleName $rule.Name `
            -priority $rule.Priority `
            -direction $rule.Direction `
            -access $rule.Access `
            -protocol $rule.Protocol `
            -sourceAddressPrefixes $rule.SourceAddressPrefixes `
            -destinationAddressPrefixes $rule.DestinationAddressPrefixes `
            -destinationPortRanges $rule.DestinationPortRanges
    }
    Write-Host ""
    Write-Host -ForegroundColor Green "=========================================="
}

Write-Host -ForegroundColor Green "All NSGs created and configured successfully!"
Write-Host -ForegroundColor Green "=========================================="
