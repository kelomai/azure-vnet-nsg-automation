<#
.SYNOPSIS
    Creates Azure Resource Groups for network infrastructure. 📦

.DESCRIPTION
    This script creates resource groups in specified Azure regions to host
    Virtual Networks, subnets, and Network Security Groups.

.EXAMPLE
    .\01-Create-ResourceGroups.ps1

.NOTES
    Author: Reid Patrick
    Blog: https://kelomai.io
    Requires: Azure CLI installed and authenticated (az login)
#>

# Define resource groups and their regions
$resourceGroups = @{
    "rg-network-eastus"   = "eastus"
    "rg-network-westus"   = "westus"
}

Write-Host -ForegroundColor Cyan "=========================================="
Write-Host -ForegroundColor Cyan "🌍 Azure Resource Group Creation Script"
Write-Host -ForegroundColor Cyan "=========================================="
Write-Host ""

# Create each resource group in the specified region
foreach ($resourceGroup in $resourceGroups.Keys) {
    $region = $resourceGroups[$resourceGroup]
    Write-Host -ForegroundColor Blue "🚀 Creating resource group '$resourceGroup' in region '$region'..."

    try {
        az group create --name $resourceGroup --location $region --output jsonc
        Write-Host -ForegroundColor Green "✅ Resource group '$resourceGroup' created successfully in region '$region'."
        Write-Host ""
    }
    catch {
        Write-Host -ForegroundColor Red "❌ Failed to create resource group '$resourceGroup' in region '$region'."
        Write-Host -ForegroundColor Red "Error: $_"
        exit 1
    }
}

Write-Host -ForegroundColor Green "=========================================="
Write-Host -ForegroundColor Green "🎉 All resource groups created successfully!"
Write-Host -ForegroundColor Green "=========================================="
