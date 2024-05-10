# Distributed version of the Spring PetClinic Sample Application built with Spring Cloud 

Clone of the  spring-petclinic-microservices GitHub Repo: [https://github.com/spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices), used to demonstrate deploying a distributed Spring Boot App into Azure Kubernetes Service (AKS), while usilising other services like a managed PostgreSQL database, Application Gateway (WAF), and Azure Key Vault.

Application architecture and the original description of this Spring Boot app can be found [here](./README_orig.md).

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Different ways of deploying the app into Azure Kubernetes Service (AKS):
* [Deploying the app using Azure Command Line Interface (az cli)](./docs/aks-az-cli.md)
* [Deploying the app using Bicep templates](./docs/aks-bicep.md)
* [Deploying the app using GitHub Actions (CI/CD pipelines)](./docs/aks-github-actions.md)

