<#
.SYNOPSIS
    Master deployment script for Azure VNet and NSG infrastructure.

.DESCRIPTION
    This script executes all deployment scripts in sequence to create:
    1. Resource Groups
    2. Virtual Network with subnets
    3. Network Security Groups with rules

.EXAMPLE
    .\Deploy-All.ps1

.NOTES
    Author: Reid Patrick
    Blog: https://kelomai.io
    Article: https://kelomai.io/azure-vnet-nsg-automation/
    Requires: Azure CLI installed and authenticated (az login)
#>

$ErrorActionPreference = "Stop"

Write-Host -ForegroundColor Cyan "=============================================================="
Write-Host -ForegroundColor Cyan "  🚀 Azure VNet & NSG Automation - Complete Deployment"
Write-Host -ForegroundColor Cyan "=============================================================="
Write-Host ""
Write-Host -ForegroundColor Yellow "📋 This script will deploy:"
Write-Host "  1️⃣  Resource Groups in East US and West US"
Write-Host "  2️⃣  Virtual Network with App and Data subnets"
Write-Host "  3️⃣  Network Security Groups with security rules"
Write-Host ""
Write-Host -ForegroundColor Cyan "❓ Do you want to proceed? (yes/no): " -NoNewline
$confirm = Read-Host

if ($confirm -notmatch "^(yes|y)$") {
    Write-Host -ForegroundColor Green "✅ Deployment canceled by user."
    exit 0
}

Write-Host ""

try {
    # Step 1: Create Resource Groups
    Write-Host -ForegroundColor Magenta "=============================================================="
    Write-Host -ForegroundColor Magenta "📦 STEP 1: Creating Resource Groups"
    Write-Host -ForegroundColor Magenta "=============================================================="
    & ".\01-Create-ResourceGroups.ps1"
    Write-Host ""

    # Step 2: Create VNet and Subnets
    Write-Host -ForegroundColor Magenta "=============================================================="
    Write-Host -ForegroundColor Magenta "🌐 STEP 2: Creating VNet and Subnets"
    Write-Host -ForegroundColor Magenta "=============================================================="
    & ".\02-Create-VNet-Subnets.ps1"
    Write-Host ""

    # Step 3: Create NSGs
    Write-Host -ForegroundColor Magenta "=============================================================="
    Write-Host -ForegroundColor Magenta "🛡️  STEP 3: Creating Network Security Groups"
    Write-Host -ForegroundColor Magenta "=============================================================="
    & ".\03-Create-NSGs.ps1"
    Write-Host ""

    Write-Host -ForegroundColor Green "=============================================================="
    Write-Host -ForegroundColor Green "  🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    Write-Host -ForegroundColor Green "=============================================================="
    Write-Host ""
    Write-Host -ForegroundColor Cyan "✅ Your Azure network infrastructure is now deployed."
    Write-Host ""
    Write-Host -ForegroundColor Cyan "📊 To verify your deployment, run:"
    Write-Host "  az network vnet list --output table"
    Write-Host "  az network nsg list --output table"
    Write-Host ""
    Write-Host -ForegroundColor Cyan "🔍 To view NSG rules:"
    Write-Host "  az network nsg rule list --resource-group rg-network-eastus --nsg-name nsg-vnet-prod-eastus-snet-app --output table"
    Write-Host ""

}
catch {
    Write-Host -ForegroundColor Red "=============================================================="
    Write-Host -ForegroundColor Red "  ❌ DEPLOYMENT FAILED"
    Write-Host -ForegroundColor Red "=============================================================="
    Write-Host -ForegroundColor Red "Error: $_"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "⚠️  Please review the error message above and retry the deployment."
    exit 1
}
