targetScope = 'subscription'

param location string = deployment().location

@allowed(['blob','container'])
param softDeleteType string = 'blob'

var softDeleteTypeMap = {
  blob: 'deleteRetentionPolicy'
  container: 'containerDeleteRetentionPolicy'
}

var softDeleteTypeAlias = softDeleteTypeMap[softDeleteType]

resource azpDefEnableSoft 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'storage-${softDeleteType}-soft-delete-mustbe-enabled'
  scope: subscription()
  properties: {
    description: 'Storage ${softDeleteType} soft delete must be enabled'
    displayName: 'Storage -${softDeleteType} soft delete must be enabled'
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
            field: 'Microsoft.Storage/storageAccounts/blobServices/${softDeleteTypeAlias}.enabled'
            equals: false
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
 } 
}

resource azpDefSoft365 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'storage-${softDeleteType}-soft-delete-365-days'
  scope: subscription()
  properties: {
    description: 'Storage ${softDeleteType} soft delete should be 365 days'
    displayName: 'Storage ${softDeleteType} soft delete should be 365 days'
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
                field: 'Microsoft.Storage/storageAccounts/blobServices/${softDeleteTypeAlias}.enabled'
                notEquals: true
              }
              {
                field: 'Microsoft.Storage/storageAccounts/blobServices/${softDeleteTypeAlias}.days'
                notEquals: 365
              }
            ]
          }
        ]
      }
      then: {
        effect: 'modify'
        details : {
          conflictEffect: 'deny'
          roleDefinitionIds: [
            '/providers/microsoft.authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'
          ]
          operations: [
              {
                operation: 'addOrReplace'
                field: 'Microsoft.Storage/storageAccounts/blobServices/${softDeleteTypeAlias}.enabled'
                value: true
              }
              {
                operation: 'addOrReplace'
                field: 'Microsoft.Storage/storageAccounts/blobServices/${softDeleteTypeAlias}.days'
                value: 365
            }
          ]
        }
      }
    }
 } 
}


@description('The assignment is what binds the Policy Definition to a scope for enforcement')
resource azdAssignSoftEnable 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'storage-${softDeleteType}-soft-delete-enabled'
  location: location
  scope: subscription()
  properties: {
    policyDefinitionId: azpDefEnableSoft.id
    enforcementMode: 'Default'
    displayName: 'storage-soft-delete-enabled'
    description: 'storage-soft-delete-enabled'
  }
}

@description('The assignment is what binds the Policy Definition to a scope for enforcement')
resource azdAssignSoft365 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'storage-${softDeleteType}-soft-delete-365'
  location: location
  scope: subscription()
  properties: {
    policyDefinitionId: azpDefSoft365.id
    enforcementMode: 'Default'
    displayName: 'storage-${softDeleteType}-soft-delete-365'
    description: 'storage-${softDeleteType}-soft-delete-365'
  }
  identity: { //An identity is required as the policy definition uses the MODIFY effect. The role in the defintion will be assigned to this identity during the creation of the assignment
    type: 'SystemAssigned'
  }
}
