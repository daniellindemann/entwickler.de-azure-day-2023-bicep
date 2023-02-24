# Instructions for Demo 4 - Bicep Registry

TODO:

## Prerequisites

### Container Registry

- Create a container registry

  ```bash
  RG=rg-azday-deps
  LOCATION=northeurope
  ACR_NAME=acrazdaysdep$RANDOM

  az group create --name $RG --location $LOCATION
  az acr create --name $ACR_NAME --resource-group $RG --sku Basic
  ```

- Store login server in variable

  ```bash
  ACR_LOGIN_SEVER=$(az acr show --name $ACR_NAME --resource-group $RG --query loginServer -o tsv)
  ```

## Push Bicep module to

- Push nsg-web.bicep module to ACR

  ```bash
  az bicep publish --file repository/nsg-web.bicep --target br:$ACR_LOGIN_SEVER/bicep/modules/nsg-web:1.0.0
  ```
