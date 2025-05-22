#!/bin/bash

# Define variables
SOURCE_KEYVAULT="source-keyvault-name"
DESTINATION_KEYVAULT="destination-keyvault-name"
SECRET_NAME="ExampleSecret"

# Retrieve the secret value from the source Key Vault
SECRET_VALUE=$(az keyvault secret show --name "$SECRET_NAME" --vault-name "$SOURCE_KEYVAULT" --query "value" -o tsv)

# Check if the secret already exists in the destination Key Vault
SECRET_CHECK=$(az keyvault secret list --vault-name "$DESTINATION_KEYVAULT" --query "[?name=='$SECRET_NAME'].name" -o tsv)

if [ -n "$SECRET_CHECK" ]; then
    echo "A secret with name $SECRET_NAME already exists in $DESTINATION_KEYVAULT"
else
    echo "Copying $SECRET_NAME to KeyVault: $DESTINATION_KEYVAULT"
    # Set the secret in the destination Key Vault
    az keyvault secret set --vault-name "$DESTINATION_KEYVAULT" --name "$SECRET_NAME" --value "$SECRET_VALUE" --output none
    echo "Secret $SECRET_NAME copied successfully."
fi
