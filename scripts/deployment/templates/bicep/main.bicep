// Secrets KeyVault integration https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
// Workload identities https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview#how-it-works

param aksName string
param aksAdminGroupObjectId string
param aksTags string

param pgsqlName string
param pgsqlAADAdminGroupName string
param pgsqlAADAdminGroupObjectId string
param pgsqlTodoAppDbName string = 'tododb'
param pgsqlPetClinicCustsSvcDbName string = 'petcliniccustomersdb'
param pgsqlPetClinicVetsSvcDbName string = 'petclinicvetssdb'
param pgsqlPetClinicVisitsSvcDbName string = 'petclinicvisitsdb'

param pgsqlSubscriptionId string
param pgsqlRG string
param pgsqlTags string

param todoAppUserManagedIdentityName string = '${aksName}-todo-app-identity'
param petClinicAdminSvcUserManagedIdentityName string = '${aksName}-pet-clinic-admin-identity'
param petClinicApiGWSvcUserManagedIdentityName string = '${aksName}-pet-clinic-api-gw-identity'
param petClinicConfigSvcUserManagedIdentityName string = '${aksName}-pet-clinic-config-identity'
param petClinicCustsSvcUserManagedIdentityName string = '${aksName}-pet-clinic-custs-identity'
param petClinicDiscoSvcUserManagedIdentityName string = '${aksName}-pet-clinic-disco-identity'
param petClinicVetsSvcUserManagedIdentityName string = '${aksName}-pet-clinic-vets-identity'
param petClinicVisitsSvcUserManagedIdentityName string = '${aksName}-pet-clinic-vists-identity'

param todoAppDbUserName string = 'todo_app'
param petClinicCustsSvcDbUserName string = 'pet_clinic_custs_svc'
param petClinicVetsSvcDbUserName string = 'pet_clinic_vets_svc'
param petClinicVisitsSvcDbUserName string = 'pet_clinic_visits_svc'

@description('URI of the GitHub config repo, for example: https://github.com/spring-petclinic/spring-petclinic-microservices-config')
param petClinicGitConfigRepoUri string
@description('User name used to access the GitHub config repo')
param petClinicGitConfigRepoUserName string
@secure()
@description('Password (PAT) used to access the GitHub config repo')
param petClinicGitConfigRepoPassword string

param logAnalyticsName string
param logAnalyticsSubscriptionId string
param logAnalyticsRG string
param logAnalyticsTags string

param containerRegistryName string
param containerRegistrySubscriptionId string
param containerRegistryRG string
param containerRegistryTags string

var aksTagsArray = json(aksTags)
var pgsqlTagsArray = json(pgsqlTags)
var containerRegistryTagsArray = json(containerRegistryTags)
var logAnalyticsTagsArray = json(logAnalyticsTags)

var appGatewayName = '${aksName}-appgw'
var vnetName = '${aksName}-vnet'
var aksSubnetName = 'aks-default'
var appGatewaySubnetName = 'appgw-subnet'

param deploymentClientIPAddress string

param location string

resource todoAppUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: todoAppUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicAdminSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicAdminSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicApiGWUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicApiGWSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicConfigSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicConfigSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicCustsSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicCustsSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicDiscoSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicDiscoSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicVetsSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicVetsSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

resource petClinicVisitsSvcUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: petClinicVisitsSvcUserManagedIdentityName
  location: location
  tags: aksTagsArray
}

module logAnalytics 'components/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: resourceGroup(logAnalyticsSubscriptionId, logAnalyticsRG)
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tagsArray: logAnalyticsTagsArray
  }
}

module todoAppInsights 'components/app-insights.bicep' = {
  name: 'todo-app-insights'
  params: {
    name: '${aksName}-todo-ai'
    location: location
    tagsArray: aksTagsArray
    logAnalyticsStringId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module petClinicAppInsights 'components/app-insights.bicep' = {
  name: 'pet-clinic-app-insights'
  params: {
    name: '${aksName}-pet-clinic-ai'
    location: location
    tagsArray: aksTagsArray
    logAnalyticsStringId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module pgsql './components/pgsql.bicep' = {
  name: 'pgsql'
  scope: resourceGroup(pgsqlSubscriptionId, pgsqlRG)
  params: {
    name: pgsqlName
    dbServerAADAdminGroupName: pgsqlAADAdminGroupName
    dbServerAADAdminGroupObjectId: pgsqlAADAdminGroupObjectId
    location: location
    tagsArray: pgsqlTagsArray
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    // incomingIpAddresses: aks.outputs.outboundIpAddresses TODO: fix
    deploymentClientIPAddress: deploymentClientIPAddress
  }
}

module containerRegistry './components/container-registry.bicep' = {
  name: 'container-registry'
  scope: resourceGroup(containerRegistrySubscriptionId, containerRegistryRG)
  params: {
    name: containerRegistryName
    location: location
    tagsArray: containerRegistryTagsArray
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module keyVault 'components/kv.bicep' = {
  name: 'keyvault'
  params: {
    name: '${aksName}-kv'
    location: location
    tagsArray: aksTagsArray
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module kvSecretTodoAppSpringDSURI 'components/kv-secret.bicep' = {
  name: 'kv-secret-todo-app-ds-uri'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'TODO-SPRING-DATASOURCE-URL'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlTodoAppDbName}'
  }
}

module kvSecretTodoAppDbUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-todo-app-ds-username'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'TODO-SPRING-DATASOURCE-USERNAME'
    secretValue: todoAppDbUserName
  }
}

module kvSecretTodoAppInsightsConnectionString 'components/kv-secret.bicep' = {
  name: 'kv-secret-todo-app-ai-connection-string'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'TODO-APP-INSIGHTS-CONNECTION-STRING'
    secretValue: todoAppInsights.outputs.appInsightsConnectionString
  }
}

module kvSecretTodoAppInsightsInstrumentationKey 'components/kv-secret.bicep' = {
  name: 'kv-secret-todo-app-ai-instrumentation-key'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'TODO-APP-INSIGHTS-INSTRUMENTATION-KEY'
    secretValue: todoAppInsights.outputs.appInsightsInstrumentationKey
  }
}

module kvSecretPetClinicConfigRepoURI 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-config-repo-uri'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-CONFIG-SVC-GIT-REPO-URI'
    secretValue: petClinicGitConfigRepoUri
  }
}

module kvSecretPetClinicConfigRepoUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-config-repo-usern-ame'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-CONFIG-SVC-GIT-REPO-USERNAME'
    secretValue: petClinicGitConfigRepoUserName
  }
}

module kvSecretPetClinicConfigRepoPassword 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-config-repo-password'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-CONFIG-SVC-GIT-REPO-PASSWORD'
    secretValue: petClinicGitConfigRepoPassword
  }
}

module kvSecretPetClinicCustSpringDSURL 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-cust-ds-url'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-CUST-SVC-SPRING-DATASOURCE-URL'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlPetClinicCustsSvcDbName}'
  }
}

module kvSecretPetClinicCustSvcDbUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-cust-svc-ds-username'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-CUST-SVC-SPRING-DS-USER'
    secretValue: petClinicCustsSvcDbUserName
  }
}

module kvSecretPetClinicVetSpringDSURL 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-vet-ds-url'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-VET-SVC-SPRING-DATASOURCE-URL'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlPetClinicVetsSvcDbName}'
  }
}

module kvSecretPetClinicVetSvcDbUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-vet-svc-ds-username'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-VET-SVC-SPRING-DS-USER'
    secretValue: petClinicVetsSvcDbUserName
  }
}

module kvSecretPetClinicVisitSpringDSURL 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-visit-ds-url'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-VISIT-SVC-SPRING-DATASOURCE-URL'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlPetClinicVisitsSvcDbName}'
  }
}

module kvSecretPetClinicVisitSvcDbUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-visit-svc-ds-username'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-VISIT-SVC-SPRING-DS-USER'
    secretValue: petClinicVisitsSvcDbUserName
  }
}

module kvSecretPetClinicAppInsightsConnectionString 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-ai-connection-string'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-APP-INSIGHTS-CONNECTION-STRING'
    secretValue: petClinicAppInsights.outputs.appInsightsConnectionString
  }
}

module kvSecretPetClinicAppInsightsInstrumentationKey 'components/kv-secret.bicep' = {
  name: 'kv-secret-pet-clinic-ai-instrumentation-key'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'PET-CLINIC-APP-INSIGHTS-INSTRUMENTATION-KEY'
    secretValue: petClinicAppInsights.outputs.appInsightsInstrumentationKey
  }
}

module vnet 'components/vnet.bicep' = {
  name: vnetName
  params: {
    name: '${aksName}-vnet'
    aksSubnetName: aksSubnetName
    appGatewaySubnetName: appGatewaySubnetName
    location: location
    tagsArray: aksTagsArray
  }
}

module appGateway 'components/app-gateway.bicep' = {
  name: 'app-gateway'
  params: {
    name: appGatewayName
    vnetName: vnet.outputs.vnetName
    appGatewaySubnetName: vnet.outputs.appGatewaySubnetName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    location: location
    tagsArray: aksTagsArray
  }
}

module aks 'components/aks.bicep' = {
  name: 'aks'
  params: {
    name: aksName
    vnetName: vnet.outputs.vnetName
    aksSubnetName: vnet.outputs.aksSubnetName
    appGatewayName: appGateway.outputs.appGatewayName
    aksAdminGroupObjectId: aksAdminGroupObjectId
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    location: location
    tagsArray: aksTagsArray
  }
}

module rbacContainerRegistryACRPull 'components/role-assignment-container-registry.bicep' = {
  name: 'deployment-rbac-container-registry-acr-pull'
  scope: resourceGroup(containerRegistryRG)
  params: {
    containerRegistryName: containerRegistryName
    roleDefinitionId: acrPullRole.id
    principalId: aks.outputs.aksNodePoolIdentityPrincipalId //.aksSecretsProviderIdentityPrincipalId
    roleAssignmentNameGuid: guid(aks.outputs.aksNodePoolIdentityPrincipalId, containerRegistry.outputs.containerRegistryId, acrPullRole.id)
  }
}

module rbacKV 'components/role-assignment-kv.bicep' = {
  name: 'rbac-kv-aks-service'
  scope: resourceGroup()
  params: {
    kvName: keyVault.outputs.keyVaultName
    roleAssignmentNameGuid: guid(aks.outputs.aksSecretsProviderIdentityPrincipalId, keyVault.outputs.keyVaultId, keyVaultSecretsUser.id)
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: aks.outputs.aksSecretsProviderIdentityPrincipalId
  }
}

// AGIC's identity requires "Contributor" permission over Application Gateway.
module rbacAppGatewayAGICContributor 'components/rolle-assignment-app-gateway.bicep' = {
  scope: resourceGroup()
  name: 'rbac-app-gw-agic-contributor'
  params: {
    appGatewayName: appGateway.outputs.appGatewayName
    roleAssignmentNameGuid: guid(aks.outputs.aksIngressApplicationGatewayPrincipalId, appGateway.outputs.appGatewayId, contributor.id)
    roleDefinitionId: managedIdentityOperator.id
    principalId: aks.outputs.aksIngressApplicationGatewayPrincipalId
  }
}

// AGIC's identity requires "Reader" permission over Application Gateway's resource group.
module rbacAppGwAGICResourceGroupReader 'components/role-assignment-resource-group.bicep' = {
  name: 'rbac-app-gw-agic-rg-reader'
  scope: resourceGroup()
  params: {
    roleAssignmentNameGuid:  guid(aks.outputs.aksIngressApplicationGatewayPrincipalId, resourceGroup().id, reader.id)
    roleDefinitionId: reader.id
    principalId: aks.outputs.aksIngressApplicationGatewayPrincipalId
  }
}

// AGIC's identity requires "Managed Identity Operator" permission over the user assigned identity of Application Gateway.
module rbacAppGwAGIC 'components/role-assignment-user-managed-identity.bicep' = {
  name: 'rbac-app-gw-agic-mi-op'
  scope: resourceGroup()
  params: {
    userManagedIdentityName: appGateway.outputs.appGatewayIdentityName
    roleAssignmentNameGuid: guid(appGateway.outputs.appGatewayIdentityPrincipalId, aks.outputs.aksIngressApplicationGatewayPrincipalId, managedIdentityOperator.id)
    roleDefinitionId: managedIdentityOperator.id
    principalId: aks.outputs.aksIngressApplicationGatewayPrincipalId
  }
}

module rbacKVSecretTodoDSUri './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-todo-ds-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: todoAppUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(todoAppUserManagedIdentity.properties.principalId, kvSecretTodoAppSpringDSURI.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretTodoAppSpringDSURI.outputs.kvSecretName
  }
}

module rbacKVSecretTodoAppDbUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-todo-app-db-user'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: todoAppUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(todoAppUserManagedIdentity.properties.principalId, kvSecretTodoAppDbUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretTodoAppDbUserName.outputs.kvSecretName
  }
}

module rbacKVSecretTodoAppAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-todo-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: todoAppUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(todoAppUserManagedIdentity.properties.principalId, kvSecretTodoAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretTodoAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretTodoAppAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-todo-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: todoAppUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(todoAppUserManagedIdentity.properties.principalId, kvSecretTodoAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretTodoAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetAdminSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-admin-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicAdminSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicAdminSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetAdminSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-admin-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicAdminSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicAdminSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetApiGWSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-api-gw-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicApiGWUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicApiGWUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetApiGWSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-api-gw-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicApiGWUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicApiGWUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetConfigSvcGitRepoURI './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-git-repo-uri'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicConfigSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicConfigSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicConfigRepoURI.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicConfigRepoURI.outputs.kvSecretName
  }
}

module rbacKVSecretPetConfigSvcGitRepoUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-git-repo-user'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicConfigSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicConfigSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicConfigRepoUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicConfigRepoUserName.outputs.kvSecretName
  }
}

module rbacKVSecretPetConfigSvcGitRepoPassword './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-git-repo-password'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicConfigSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicConfigSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicConfigRepoPassword.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicConfigRepoPassword.outputs.kvSecretName
  }
}

module rbacKVSecretPetConfigSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-config-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicConfigSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicConfigSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetConfigSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-config-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicConfigSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicConfigSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetCCustsSvcDSUri './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-custs-ds-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicCustsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicCustsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicCustSpringDSURL.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicCustSpringDSURL.outputs.kvSecretName
  }
}

module rbacKVSecretPetCustsSvcDBUSer './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-custs-svc-db-user'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicCustsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicCustsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicCustSvcDbUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicCustSvcDbUserName.outputs.kvSecretName
  }
}

module rbacKVSecretPetCustsSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-custs-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicCustsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicCustsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetCustsSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-custs-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicCustsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicCustsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetDiscoSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-disco-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicDiscoSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicDiscoSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetDiscoSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-disco-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicDiscoSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicDiscoSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetVetsSvcDSUri './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-vets-svc-ds-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVetsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVetsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicVetSpringDSURL.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicVetSpringDSURL.outputs.kvSecretName
  }
}

module rbacKVSecretPetVetsSvcDBUSer './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-vets-svc-db-user'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVetsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVetsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicVetSvcDbUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicVetSvcDbUserName.outputs.kvSecretName
  }
}

module rbacKVSecretPetVetsSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-vets-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVetsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVetsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetVetsSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-vets-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVetsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVetsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

module rbacKVSecretPetVisitsSvcDSUri './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-visits-svc-ds-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVisitsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVisitsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicVisitSpringDSURL.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicVisitSpringDSURL.outputs.kvSecretName
  }
}

module rbacKVSecretPetVisitsSvcDBUSer './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-visits-svc-db-user'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVisitsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVisitsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicVisitSvcDbUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicVisitSvcDbUserName.outputs.kvSecretName
  }
}

module rbacKVSecretPetVisitsSvcAppInsightsConStr './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-visits-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVisitsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVisitsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsConnectionString.outputs.kvSecretName
  }
}

module rbacKVSecretPetisitsSvcAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-pet-visits-app-insights-instr-key'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: petClinicVisitsSvcUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(petClinicVisitsSvcUserManagedIdentity.properties.principalId, kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVault.outputs.keyVaultName
    kvSecretName: kvSecretPetClinicAppInsightsInstrumentationKey.outputs.kvSecretName
  }
}

@description('This is the built-in AcrPull role. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull')
resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

@description('This is the built-in Key Vault Secrets User role. See https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('This is the built-in Contributor role. See https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#contributor')
resource contributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

@description('This is the built-in Reader role. See https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#reader')
resource reader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

@description('This is the built-in Managed Identity Operator role. See https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#reader')
resource managedIdentityOperator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: 'f1a07417-d97a-45cb-824c-7a7467783830'
}

output todoAppUserManagedIdentityName string = todoAppUserManagedIdentity.name
output todoAppUserManagedIdentityPrincipalId string = todoAppUserManagedIdentity.properties.principalId
output todoAppUserManagedIdentityClientId string = todoAppUserManagedIdentity.properties.clientId
output todoAppDbName string = pgsqlTodoAppDbName
output todoAppDbUserName string = todoAppDbUserName

output petClinicAdminSvcUserManagedIdentityName string = petClinicAdminSvcUserManagedIdentity.name
output petClinicAdminSvcUserManagedIdentityPrincipalId string = petClinicAdminSvcUserManagedIdentity.properties.principalId
output petClinicAdminSvcUserManagedIdentityClientId string = petClinicAdminSvcUserManagedIdentity.properties.clientId

output petClinicApiGWSvcUserManagedIdentityName string = petClinicApiGWUserManagedIdentity.name
output petClinicApiGWSvcUserManagedIdentityPrincipalId string = petClinicApiGWUserManagedIdentity.properties.principalId
output petClinicApiGWSvcUserManagedIdentityClientId string = petClinicApiGWUserManagedIdentity.properties.clientId

output petClinicConfigSvcUserManagedIdentityName string = petClinicConfigSvcUserManagedIdentity.name
output petClinicConfigSvcUserManagedIdentityPrincipalId string = petClinicConfigSvcUserManagedIdentity.properties.principalId
output petClinicConfigSvcUserManagedIdentityClientId string = petClinicConfigSvcUserManagedIdentity.properties.clientId

output petClinicCustsSvcUserManagedIdentityName string = petClinicCustsSvcUserManagedIdentity.name
output petClinicCustsSvcUserManagedIdentityPrincipalId string = petClinicCustsSvcUserManagedIdentity.properties.principalId
output petClinicCustsSvcUserManagedIdentityClientId string = petClinicCustsSvcUserManagedIdentity.properties.clientId
output petClinicCustsSvcDbName string = pgsqlPetClinicCustsSvcDbName
output petClinicCustsSvcDbUserName string = petClinicCustsSvcDbUserName

output petClinicDiscoSvcUserManagedIdentityName string = petClinicDiscoSvcUserManagedIdentity.name
output petClinicDiscoSvcUserManagedIdentityPrincipalId string = petClinicDiscoSvcUserManagedIdentity.properties.principalId
output petClinicDiscoSvcUserManagedIdentityClientId string = petClinicDiscoSvcUserManagedIdentity.properties.clientId

output petClinicVetsSvcUserManagedIdentityName string = petClinicVetsSvcUserManagedIdentity.name
output petClinicVetsSvcUserManagedIdentityPrincipalId string = petClinicVetsSvcUserManagedIdentity.properties.principalId
output petClinicVetsSvcUserManagedIdentityClientId string = petClinicVetsSvcUserManagedIdentity.properties.clientId
output petClinicVetsSvcDbUserName string = petClinicVetsSvcDbUserName
output petClinicVetsSvcDbName string = pgsqlPetClinicVetsSvcDbName

output petClinicVisitsSvcUserManagedIdentityName string = petClinicVisitsSvcUserManagedIdentity.name
output petClinicVisitsSvcUserManagedIdentityPrincipalId string = petClinicVisitsSvcUserManagedIdentity.properties.principalId
output petClinicVisitsSvcUserManagedIdentityClientId string = petClinicVisitsSvcUserManagedIdentity.properties.clientId
output petClinicVisitsSvcDbUserName string = petClinicVisitsSvcDbUserName
output petClinicVisitsSvcDbName string = pgsqlPetClinicVisitsSvcDbName

output pgsqlUpdatedFirewallRulesSet array = pgsql.outputs.validFirewallRules
