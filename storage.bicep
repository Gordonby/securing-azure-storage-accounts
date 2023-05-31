param nameseed string = 'mystoragename'
param location string = resourceGroup().location
param uniqueSuffix string = uniqueString(resourceGroup().id, deployment().name, nameseed)

resource storageaccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: take('st${nameseed}${uniqueSuffix}}',24)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }

  resource blob 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 365
      }
    }

    resource container 'containers' = {
      name: 'mycontainer'
      properties: {
        publicAccess: 'None'
      }

      resource worm 'immutabilityPolicies' = {
        name: 'default'
        properties: {
          allowProtectedAppendWritesAll: true
          immutabilityPeriodSinceCreationInDays: 4096
        }
      }
    }
  } 
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'noDelete'
  scope: storageaccount
  properties: {
    level: 'CanNotDelete'
  }
}
