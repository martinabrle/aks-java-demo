@description('The name of the DNS zone to be created.  Must have at least 2 segments, e.g. hostname.org')
param zoneName string

@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param recordName string

@description('The name of the Azure Public IP resource.')
param publicIPAddressName string

@description('The name of an existing parent DNS zone.')
param parentZoneName string

@description('The name of an existing parent DNS zone\'s resource group.')
param parentZoneRG string = ''

@description('Subscription id of an existing parent DNS zone.')
param parentZoneSubscriptionId string = ''

param parentZoneTagsArray object

param tagsArray object

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-05-01' existing = {
  name: publicIPAddressName
}

module parentDnsZoneModule './dns-zone-parent.bicep' = {
  name: 'dns-zone-parent'
  scope: resourceGroup(parentZoneSubscriptionId, parentZoneRG)
  params: {
    zoneName: parentZoneName
    tagsArray: parentZoneTagsArray
  }
}

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: '${zoneName}.${parentZoneName}'
  location: 'global'
  dependsOn: [
    parentDnsZoneModule
  ]
  tags: tagsArray
  properties: {
    zoneType: 'Public'
  }
}

resource dnsZoneRecord 'Microsoft.Network/dnszones/A@2023-07-01-preview' = {
  parent: dnsZone
  name: recordName
  properties: {
    TTL: 60
    targetResource: {
      id: publicIPAddress.id
    }
  }
}
