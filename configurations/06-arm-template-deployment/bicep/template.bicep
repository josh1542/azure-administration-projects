param disk_name string = 'az104-bicep-disk4'

resource disk_name_resource 'Microsoft.Compute/disks@2025-01-02' = {
  name: disk_name
  location: 'australiaeast'
  tags: {
    Environment: 'Lab'
    ManagedBy: 'Bicep'
    Project: 'AZ104-ARM'
  }
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 32
    diskIOPSReadWrite: 500
    diskMBpsReadWrite: 60
    encryption: {
      type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'AllowAll'
    publicNetworkAccess: 'Enabled'
    dataAccessAuthMode: 'None'
  }
}
