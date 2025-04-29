param name string
param vnetName string
param aksSubnetName string
//param appGatewayName string
param nodePoolRG string = '${((endsWith(resourceGroup().name, '_rg')) ? substring(resourceGroup().name, 0, length(resourceGroup().name) - 3) : resourceGroup().name)}_managed_resources_rg'
param aksAdminGroupObjectId string
param logAnalyticsWorkspaceId string
param location string
param tagsArray object

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: aksSubnetName
}

// resource applicationGateway 'Microsoft.Network/applicationGateways@2023-05-01' existing = {
//   name: appGatewayName
// }

// resource appGatewayUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
//   name: '${name}-identity'
// }


resource agicUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${name}-agic-identity'
  location: location
  tags: tagsArray
}

resource aksService 'Microsoft.ContainerService/managedClusters@2024-10-02-preview' = {
  name: name
  location: location
  tags: tagsArray
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: '${name}-dns'
    enableRBAC: true

    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0 //pick VMs default 
        count: 3
        enableAutoScaling: false
        vmSize: 'Standard_D4s_v4' //'Standard_F4s_v2' //Standard_F2s_v2 would be the cheapest non-burstable VM - but that does not have enough memory
        osType: 'Linux'
        osDiskType: 'Managed'
        //osDiskType: 'Ephemeral' - does not work, temp disk too small
        #disable-next-line BCP037
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        //availabilityZones: [ '1', '2', '3' ]
        enableNodePublicIP: false
        vnetSubnetID: aksSubnet.id
        tags: tagsArray
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      //not used anymore dockerBridgeCidr: '172.17.0.1/16'
    }
    disableLocalAccounts: true
    aadProfile: {
      managed: true
      adminGroupObjectIDs: [ aksAdminGroupObjectId ]
      enableAzureRBAC: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      defender: {
        securityMonitoring: {
          enabled: true
        }
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    //we were missing this one in AKS until now:
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricLabelsAllowlist: ''
          metricAnnotationsAllowList: ''
        }
      }
      containerInsights: {
         enabled: true
         logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
      }
      //Following seems to be a preview feature and I see limited docs for it
      //https://learn.microsoft.com/en-us/azure/templates/microsoft.containerservice/2024-10-02-preview/managedclusters?pivots=deployment-language-bicep#managedclusterazuremonitorprofileappmonitoring
      //perhaps once it's worth trying, but does not provide the same level of granularity as the YAML files
      // appMonitoring: {
      //   autoInstrumentation: {
      //     enabled: true
      //   }
      //   openTelemetryLogs: {
      //     enabled: true
      //   }
      //   openTelemetryMetrics: {
      //     enabled: true
      //   }
      // }
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      // https://learn.microsoft.com/en-us/samples/azure-samples/aks-agic/aks-agic/
      // AddOn Profile for AGIC can only be used when the default namespace is used exclusively for ingress
      // for multiple namespaces, use the AGIC Helm chart
      // ingressApplicationGateway: {
      //   enabled: true
      //   config: {
      //     applicationGatewayId: applicationGateway.id
      //     // userAssignedIdentityId: appGatewayUserManagedIdentity.id
      //     // subnetId: aksSubnet.id}  
      //   }      
      // }
      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azurepolicy: {
        config: {
          version: 'v2'
        }
        enabled:true
      }
    }
    nodeResourceGroup: nodePoolRG 
  }
}
// TODO: fix
// var policySetBaseline = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
// var policySetRestrictive = '/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00'
//TODO: fix
// resource aks_policies 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
//   name: '${resourceName}-${azurePolicyInitiative}'
//   location: location
//   properties: {
//     policyDefinitionId: azurePolicyInitiative == 'Baseline' ? policySetBaseline : policySetRestrictive
//     parameters: {
//       excludedNamespaces: {
//         value: [
//             'kube-system'
//             'gatekeeper-system'
//             'azure-arc'
//             'cluster-baseline-setting'
//         ]
//       }
//       effect: {
//         value: azurepolicy
//       }
//     }
//     metadata: {
//       assignedBy: 'Aks Construction'
//     }
//     displayName: 'Kubernetes cluster pod security ${azurePolicyInitiative} standards for Linux-based workloads'
//     description: 'As per: https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/'
//   }
// }

resource aksDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-aks-logs'
  scope: aksService
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

// resource aksNodePoolManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
//   name: '${aksService.name}-agentpool'
//   scope: resourceGroup(nodePoolRG)
// }

//output aksIdentityPrincipalId string = aksService.identity.principalId
//output aksIdentityTenantId string = aksService.identity.tenantId

output aksSecretsProviderIdentityPrincipalId string = aksService.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId

module aksNodePoolManagedIdentity 'user-assigned-identity.bicep' = {
  name: 'agentpool-identity'
  scope: resourceGroup(nodePoolRG)
  params: {
    name: '${aksService.name}-agentpool'
    rg: nodePoolRG
  }
  dependsOn: [
    #disable-next-line no-unnecessary-dependson
    aksService
  ]
}

// TODO: fix
// resource tmpOutboundIPAddressIDs 'Microsoft.Network/publicIPAddresses@2023-05-01' existing = [for publicIp in aksService.properties.networkProfile.loadBalancerProfile.outboundIPs.publicIPs : {
//   name: publicIp.id
// }]

// var tmp3 = [for (item, index) in tmpOutboundIPAddressIDs: ]

// output tmp2 string[] = map(aksService.properties.networkProfile.loadBalancerProfile.effectiveOutboundIPs, d => d.id)

// outboundIPAddressIDs

// var publicIpsStringArray = [for publicIp in publicIps : publicIp.properties.ipAddress]


output aksNodePoolIdentityPrincipalId string = aksNodePoolManagedIdentity.outputs.principalId // aksNodePoolManagedIdentity.properties.principalId
//Not using AGIC Addon - output aksIngressApplicationGatewayPrincipalId string = aksService.properties.addonProfiles.ingressApplicationGateway.identity.objectId
@description('This output can be directly leveraged when creating a ManagedId Federated Identity')
output aksOidcFedIdentityProperties object = {
  issuer: aksService.properties.oidcIssuerProfile.issuerURL
  audiences: ['api://AzureADTokenExchange']
  subject: 'system:serviceaccount:ns:svcaccount'
}

// TODO: fix
// output outboundIpAddresses string = concat(publicIpsStringArray)

output agicIdentityPrincipalId string = agicUserManagedIdentity.properties.principalId
output agicIdentityClientId string = agicUserManagedIdentity.properties.clientId
output agicIdentityResourceId string = agicUserManagedIdentity.id
output agicIdentityName string = agicUserManagedIdentity.name
