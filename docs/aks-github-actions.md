# Spring Boot Todo App on App Service

## Deploying Todo App into an App Service with Github actions (CI/CD Pipeline)

![Architecture Diagram](../diagrams/demo-app-app-service-managed-identities.drawio.png)

* Copy the repo's content into your personal or organizational GitHub Account
* This limited example is not utilising *GitHub->Settings->Environments* with the exception of PRODUCTION environment. PRODUCTION environment is used to demonstrate gated deployment and utilising deployment approvers.
* Click on *GitHub->Settings->Secrets and variables->Actions->Secrets* and set the following GitHub action secrets:
```
AAD_CLIENT_ID
AAD_TENANT_ID
AKS_ADMIN_GROUP_NAME
AKS_NAME
AKS_RESOURCE_GROUP
AKS_SUBSCRIPTION_ID
AZURE_LOCATION
CONTAINER_REGISTRY_NAME
CONTAINER_REGISTRY_RESOURCE_GROUP
CONTAINER_REGISTRY_SUBSCRIPTION_ID
DBA_GROUP_NAME
LOG_ANALYTICS_WRKSPC_NAME
LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP
LOG_ANALYTICS_WRKSPC_SUBSCRIPTION_ID
PET_CLINIC_APP_EDIT_AD_GROUP_NAME
PET_CLINIC_APP_VIEW_AD_GROUP_NAME
PET_CLINIC_CUSTS_SVC_DB_USER_NAME
PET_CLINIC_DB_NAME
PET_CLINIC_GIT_CONFIG_REPO_PASSWORD
PET_CLINIC_GIT_CONFIG_REPO_URI
PET_CLINIC_GIT_CONFIG_REPO_USERNAME
PET_CLINIC_VETS_SVC_DB_USER_NAME
PET_CLINIC_VISITS_SVC_DB_USER_NAME
PGSQL_NAME
PGSQL_RESOURCE_GROUP
PGSQL_SUBSCRIPTION_ID
TODO_APP_DB_NAME
TODO_APP_DB_USER_NAME
TODO_APP_EDIT_AD_GROUP_NAME
TODO_APP_VIEW_AD_GROUP_NAME
```

* Click on *GitHub->Settings->Secrets and variables->Actions->Variables* and set the following GitHub action variables:
```
AKS_RESOURCE_TAGS (example value: { \"Department\": \"RESEARCH\", \"CostCentre\": \"DEV\", \"DeleteNightly\": \"true\", \"Architecture\": \"AKS\"} )
CONTAINER_REGISTRY_RESOURCE_TAGS
LOG_ANALYTICS_WRKSPC_RESOURCE_TAGS
PET_CLINIC_GIT_CONFIG_REPO_URI
PGSQL_RESOURCE_TAGS
```

* Create a service principal and assigned roles needed for deploying resources, managing Key Vault secrets and assigning RBACs. You will need to assign RBAC for every subscription you are deploying into. The service principal will also need to have "Directory.Read" role assigned to it for the workflow to work, in this demo we will do it manually.:
```
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role "Key Vault Administrator" --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role contributor --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role owner --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
```
* Copy the output JSON into a new variable ```AZURE_CREDENTIALS``` in *Settings->Secrets->Actions* in your GitHub Repo
* Add ```Owner``` and ```Contributor``` roles to the newly created service principal
* Check all three roles (Owner, Contributor and Key Vault Administrator) have been assigned correctly
```
az role assignment list --assignee {SERVICE_PRINCIPAL_FROM_JSON_OUTPUT} -o table
```
* If you are using managed identities, you will need to provide the newly created service principal with a Directory.Read.All AD role for the workflow to work
* This may not be ideal, if you are not using a separated subscription for each workload as a part of your landing zones; the alternative is to modify deployment scripts so that these do not create resource groups and give RBAC contributor, owner and Key Vault administrator roles to the deployment service principal on the reasource group ```{YOUR_RG_NAME_rg}```. However, using a subscription per workload and giving the deployment service principle these roles allows us to have ```{YOUR_RG_NAME_rg}``` only automatically created and deleted. By deleting the resource group, Azure Resource Manager makes sure that resources have been deleted in the right order, otherwise you would have the responsibility  to delete resources in the right order. We should switch here to OICD as described [here](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure#use-the-azure-login-action-with-openid-connect) to avoid relying on storing deployment credentials
* Run the infrastructure deployment by running *Actions->98-Infra* manually; this action is defined in ```./aks-java-demo/.github/workflows/98-infra.yml```
* Run the code deployment by running *Actions->70-continuous-integration* manually; this action is defined in ```./aks-java-demo/.github/workflows/70-continuous-integration.yml```
* Open the app's URL (```https://${AZURE_APP_NAME}.azurewebsites.net/```) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (```https://${AZURE_APP_NAME}.scm.azurewebsites.net/```); check logs and bash
* Delete created resources by deleting all automaticcally created resource groups from Azure Portal. This will remove resources created.
