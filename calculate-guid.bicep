param subscriptionId string
param devManagedIdentityPrincipalId string
param tstManagedIdentityPrincipalId string
param roleDefinitionResourceId string = '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

output devGuid string = guid(subscriptionId, devManagedIdentityPrincipalId, roleDefinitionResourceId)
output tstGuid string = guid(subscriptionId, tstManagedIdentityPrincipalId, roleDefinitionResourceId)
