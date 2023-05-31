targetScope = 'subscription'

param location string = deployment().location

resource azpDefEnableSoft 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'storage-soft-delete-enabled'
  scope: subscription()
  properties: {
    description: 'Storage account soft delete should be enabled'
    displayName: 'Storage account soft delete should be enabled'
    mode: 'All'
    metadata: {
      category: 'Storage'
      version: '1.0.0'
    }
    policyType: 'Custom'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts/blobServices'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.enabled'
                notEquals: true
              }
              {
                field: 'Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.days'
                notEquals: 365
              }
            ]
          }
        ]
      }
      then: {
        effect: 'modify'
        details : {
          conflictEffect: 'audit'
          roleDefinitionIds: [
            '/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' //Contribut
          ]
          operations: [
              {
                operation: 'addOrReplace'
                field: 'Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.enabled'
                value: true
              }
              {
                operation: 'addOrReplace'
                field: 'Microsoft.Storage/storageAccounts/blobServices/deleteRetentionPolicy.days'
                value: 365
            }
          ]
        }
      }
    }
 } 
}

var assignName = 'storage-soft-delete-enabled'

@description('The assignment is what binds the Policy Definition to a scope for enforcement')
resource azdAssignSoftEnable 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignName
  location: location
  scope: subscription()
  properties: {
    policyDefinitionId: azpDefEnableSoft.id
    enforcementMode: 'Default'
    displayName: assignName
    description: assignName
  }
  identity: { //An identity is required as the policy definition uses the modify effect. The role in the defintion will be assigned to this identity during the creation of the assignment
    type: 'SystemAssigned'
  }
}
