<#
.SYNOPSIS
    Deletes Azure Resource Groups and all contained resources.

.DESCRIPTION
    This script safely deletes specified resource groups after user confirmation.
    All resources within the resource groups (VNets, NSGs, subnets) will be deleted.

.EXAMPLE
    .\04-Delete-ResourceGroups.ps1

.NOTES
    Author: Reid Patrick
    Blog: https://kelomai.io
    Requires: Azure CLI installed and authenticated (az login)
    WARNING: This operation is irreversible!
#>

# Define resource groups to delete
$resourceGroups = @{
    "rg-network-eastus" = "eastus"
    "rg-network-westus" = "westus"
}

Write-Host -ForegroundColor Cyan "=========================================="
Write-Host -ForegroundColor Cyan "Azure Resource Group Deletion Script"
Write-Host -ForegroundColor Cyan "=========================================="
Write-Host ""
Write-Host -ForegroundColor Yellow "⚠️  WARNING: This will delete the following resource groups and ALL contained resources:"
Write-Host ""
foreach ($resourceGroup in $resourceGroups.Keys) {
    Write-Host -ForegroundColor Yellow "  - $resourceGroup"
}
Write-Host ""

# Global confirmation
Write-Host -ForegroundColor Red "This operation is IRREVERSIBLE!"
Write-Host -ForegroundColor Cyan "Do you want to proceed with deletion of ALL resource groups? (yes/no): " -NoNewline
$globalConfirm = Read-Host

if ($globalConfirm -notmatch "^(yes|y)$") {
    Write-Host -ForegroundColor Green "Operation canceled by user. No resource groups were deleted."
    exit 0
}

Write-Host ""

# Delete each resource group
foreach ($resourceGroup in $resourceGroups.Keys) {
    Write-Host -ForegroundColor Yellow "Checking if resource group '$resourceGroup' exists..."

    $rgExists = az group exists --name $resourceGroup --output tsv

    if ($rgExists -eq "true") {
        Write-Host -ForegroundColor Blue "Resource group '$resourceGroup' found."

        # Individual confirmation for each resource group
        Write-Host -ForegroundColor Cyan "Confirm deletion of '$resourceGroup'? (yes/no): " -NoNewline
        $confirmDelete = Read-Host

        if ($confirmDelete -match "^(yes|y)$") {
            Write-Host -ForegroundColor Blue "Deleting resource group '$resourceGroup'..."

            try {
                # Using --no-wait for async deletion
                az group delete --name $resourceGroup --yes --output json --no-wait

                Write-Host -ForegroundColor Green "✓ Deletion of resource group '$resourceGroup' initiated successfully."
                Write-Host -ForegroundColor Yellow "  Note: Deletion is running in the background and may take several minutes to complete."
            }
            catch {
                Write-Host -ForegroundColor Red "✗ Failed to delete resource group '$resourceGroup'."
                Write-Host -ForegroundColor Red "Error: $_"
            }
        }
        else {
            Write-Host -ForegroundColor Yellow "Deletion of resource group '$resourceGroup' canceled by user."
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "Resource group '$resourceGroup' does not exist. Skipping."
    }

    Write-Host ""
}

Write-Host -ForegroundColor Green "=========================================="
Write-Host -ForegroundColor Green "Resource group deletion process completed!"
Write-Host -ForegroundColor Green "=========================================="
Write-Host ""
Write-Host -ForegroundColor Cyan "To check deletion status, run:"
Write-Host "  az group list --output table"
