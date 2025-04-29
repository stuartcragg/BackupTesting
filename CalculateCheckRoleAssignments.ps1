param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$DevManagedIdentityPrincipalId,

    [Parameter(Mandatory = $true)]
    [string]$TstManagedIdentityPrincipalId,

    [Parameter(Mandatory = $true)]
    [string]$VnetResourceGroup1,

    [Parameter(Mandatory = $true)]
    [string]$VnetResourceGroup2,

    [string]$RoleDefinitionResourceId = "/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
)

# Function to mimic Bicep's guid() function
function Get-BicepGuid {
    param (
        [string[]]$Inputs
    )
    # Concatenate inputs
    $concatenated = $Inputs -join ''
    # Compute SHA-256 hash
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($concatenated))
    # Create GUID from first 16 bytes
    $guid = [Guid]::New($hash[0..15])
    return $guid.ToString()
}

# Set the Azure subscription context
Set-AzContext -SubscriptionId $SubscriptionId

# Calculate GUIDs
$devGuid = Get-BicepGuid -Inputs @($SubscriptionId, $DevManagedIdentityPrincipalId, $RoleDefinitionResourceId)
$tstGuid = Get-BicepGuid -Inputs @($SubscriptionId, $TstManagedIdentityPrincipalId, $RoleDefinitionResourceId)

Write-Output "Calculated GUIDs:"
Write-Output "Dev Identity GUID (VNet1 RG and VNet2 RG): $devGuid"
Write-Output "Tst Identity GUID (VNet1 RG and VNet2 RG): $tstGuid"

# Check for existing role assignments
Write-Output "`nChecking for existing role assignments..."

# Subscription scope
$devRoleAssignmentsSub = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" | Where-Object { $_.RoleAssignmentName -eq $devGuid }
$tstRoleAssignmentsSub = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" | Where-Object { $_.RoleAssignmentName -eq $tstGuid }

# VNet1 RG scope
$devRoleAssignmentsRg1 = Get-AzRoleAssignment -ResourceGroupName $VnetResourceGroup1 | Where-Object { $_.RoleAssignmentName -eq $devGuid }
$tstRoleAssignmentsRg1 = Get-AzRoleAssignment -ResourceGroupName $VnetResourceGroup1 | Where-Object { $_.RoleAssignmentName -eq $tstGuid }

# VNet2 RG scope
$devRoleAssignmentsRg2 = Get-AzRoleAssignment -ResourceGroupName $VnetResourceGroup2 | Where-Object { $_.RoleAssignmentName -eq $devGuid }
$tstRoleAssignmentsRg2 = Get-AzRoleAssignment -ResourceGroupName $VnetResourceGroup2 | Where-Object { $_.RoleAssignmentName -eq $tstGuid }

# Display results
Write-Output "`nRole Assignments for Dev Identity GUID ($devGuid):"
if ($devRoleAssignmentsSub) {
    Write-Output "Found at Subscription Scope:"
    $devRoleAssignmentsSub | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if ($devRoleAssignmentsRg1) {
    Write-Output "Found at VNet1 RG ($VnetResourceGroup1):"
    $devRoleAssignmentsRg1 | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if ($devRoleAssignmentsRg2) {
    Write-Output "Found at VNet2 RG ($VnetResourceGroup2):"
    $devRoleAssignmentsRg2 | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if (-not ($devRoleAssignmentsSub -or $devRoleAssignmentsRg1 -or $devRoleAssignmentsRg2)) {
    Write-Output "No role assignments found."
}

Write-Output "`nRole Assignments for Tst Identity GUID ($tstGuid):"
if ($tstRoleAssignmentsSub) {
    Write-Output "Found at Subscription Scope:"
    $tstRoleAssignmentsSub | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if ($tstRoleAssignmentsRg1) {
    Write-Output "Found at VNet1 RG ($VnetResourceGroup1):"
    $tstRoleAssignmentsRg1 | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if ($tstRoleAssignmentsRg2) {
    Write-Output "Found at VNet2 RG ($VnetResourceGroup2):"
    $tstRoleAssignmentsRg2 | Select-Object RoleAssignmentName, RoleDefinitionId, ObjectId, Scope
}
if (-not ($tstRoleAssignmentsSub -or $tstRoleAssignmentsRg1 -or $tstRoleAssignmentsRg2)) {
    Write-Output "No role assignments found."
}

# Optional: Delete conflicting role assignments (uncomment to enable)
<#
Write-Output "`nDeleting conflicting role assignments (if any)..."
foreach ($assignment in $devRoleAssignmentsSub) {
    Remove-AzRoleAssignment -RoleAssignmentName $devGuid -Scope "/subscriptions/$SubscriptionId"
    Write-Output "Deleted Dev GUID ($devGuid) at Subscription Scope"
}
foreach ($assignment in $devRoleAssignmentsRg1) {
    Remove-AzRoleAssignment -RoleAssignmentName $devGuid -Scope "/subscriptions/$SubscriptionId/resourceGroups/$VnetResourceGroup1"
    Write-Output "Deleted Dev GUID ($devGuid) at VNet1 RG"
}
foreach ($assignment in $devRoleAssignmentsRg2) {
    Remove-AzRoleAssignment -RoleAssignmentName $devGuid -Scope "/subscriptions/$SubscriptionId/resourceGroups/$VnetResourceGroup2"
    Write-Output "Deleted Dev GUID ($devGuid) at VNet2 RG"
}
foreach ($assignment in $tstRoleAssignmentsSub) {
    Remove-AzRoleAssignment -RoleAssignmentName $tstGuid -Scope "/subscriptions/$SubscriptionId"
    Write-Output "Deleted Tst GUID ($tstGuid) at Subscription Scope"
}
foreach ($assignment in $tstRoleAssignmentsRg1) {
    Remove-AzRoleAssignment -RoleAssignmentName $tstGuid -Scope "/subscriptions/$SubscriptionId/resourceGroups/$VnetResourceGroup1"
    Write-Output "Deleted Tst GUID ($tstGuid) at VNet1 RG"
}
foreach ($assignment in $tstRoleAssignmentsRg2) {
    Remove-AzRoleAssignment -RoleAssignmentName $tstGuid -Scope "/subscriptions/$SubscriptionId/resourceGroups/$VnetResourceGroup2"
    Write-Output "Deleted Tst GUID ($tstGuid) at VNet2 RG"
}
#>
