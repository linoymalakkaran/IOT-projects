# WAT Water Treatment Solution Deployment Guide

This guide provides step-by-step instructions for deploying the WAT (Water Treatment) IoT-based monitoring and control solution infrastructure on Microsoft Azure.

## Prerequisites

- An Azure account with an active subscription
- Azure CLI installed (version 2.40.0 or higher)
- PowerShell 7.0 or higher (for Windows) or Bash (for macOS/Linux)
- Basic knowledge of Azure Resource Manager (ARM) templates

## Deployment Files

The solution consists of the following ARM templates:

1. **main.json** - Main orchestration template that deploys all components
2. **iothub.json** - IoT Hub and Device Provisioning Service
3. **dataingestion.json** - Event Hubs and data ingestion components
4. **storage.json** - Data storage components (Cosmos DB, Time Series Insights, Data Lake, Blob Storage)
5. **processing.json** - Data processing components (Stream Analytics, Azure Functions, Databricks)
6. **application.json** - Application and integration components (Digital Twins, Web App, Power BI)
7. **network.json** - Network and connectivity components
8. **security.json** - Security components (Key Vault, Defender for IoT)
9. **monitoring.json** - Monitoring and alerting components
10. **simulator.json** - Device simulator for testing (optional)

## Deployment Steps

### 1. Download the Templates

Create a folder for the deployment and download all ARM templates to this folder.

```bash
mkdir wat-deployment
cd wat-deployment
# Download the template files into this folder
```

### 2. Create Parameters File

Create a `parameters.json` file with your deployment parameters:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "environmentName": {
            "value": "wat-prod"
        },
        "location": {
            "value": "eastus"
        },
        "secondaryLocation": {
            "value": "westus2"
        },
        "iotHubSkuName": {
            "value": "S1"
        },
        "iotHubCapacityUnits": {
            "value": 4
        },
        "cosmosDbThroughput": {
            "value": 10000
        },
        "administratorLogin": {
            "value": "watadmin"
        },
        "administratorLoginPassword": {
            "value": "REPLACE_WITH_YOUR_SECURE_PASSWORD"
        },
        "deployAlerting": {
            "value": true
        },
        "deviceSimulatorRequired": {
            "value": false
        }
    }
}
```

> **Important:** Replace placeholder values with your own, especially the `administratorLoginPassword` with a secure password.

### 3. Create Resource Group

Create an Azure Resource Group to deploy the solution:

```bash
# Login to Azure
az login

# Create Resource Group
az group create --name wat-resource-group --location eastus
```

### 4. Deploy the Solution

Deploy the main template which will orchestrate the deployment of all components:

```bash
az deployment group create \
  --name wat-deployment \
  --resource-group wat-resource-group \
  --template-file main.json \
  --parameters @parameters.json
```

The deployment will take approximately 30-45 minutes to complete.

### 5. Verify Deployment

Verify that all resources have been deployed successfully:

```bash
az deployment group show \
  --name wat-deployment \
  --resource-group wat-resource-group \
  --query properties.outputs
```

This will display the key outputs from the deployment, including connection strings and endpoints.

## Post-Deployment Configuration

### 1. Set up IoT Edge Devices

1. Install IoT Edge runtime on your gateway devices following the [Azure IoT Edge documentation](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge).
2. Register devices using the DPS (Device Provisioning Service) with the ID Scope provided in the deployment outputs.

### 2. Configure LoRaWAN Network

1. Set up your LoRaWAN gateways and configure them to connect to the Azure IoT Hub.
2. Register your LoRaWAN devices in the IoT Hub.

### 3. Set up Digital Twins Models

1. Navigate to the Azure Digital Twins instance in the Azure Portal.
2. Upload the Digital Twins models for water infrastructure components.
3. Create twin instances representing your physical infrastructure.

### 4. Configure Power BI Dashboard

1. Log in to Power BI service.
2. Connect to the Time Series Insights and Cosmos DB data sources.
3. Import the dashboard templates or create custom visualizations.

## Simulator Deployment (Optional)

If you need to test the system with simulated devices:

1. Update parameters.json to set `"deviceSimulatorRequired": true`.
2. Provide `simulatorAdminUsername` and `simulatorAdminPassword`.
3. Set `deviceCount` to the number of simulated devices you need.
4. Run an incremental deployment:

```bash
az deployment group create \
  --name wat-simulator-deployment \
  --resource-group wat-resource-group \
  --template-file main.json \
  --parameters @parameters.json
```

## Troubleshooting

### Common Issues

1. **Deployment failure**: Check the deployment operation details in the Azure Portal for specific error messages.
2. **IoT Hub connection issues**: Verify network settings and firewall rules.
3. **Stream Analytics job not starting**: Check the job configuration and input/output settings.

### Logs and Diagnostics

All system components are configured to send logs to Log Analytics. To access logs:

1. Navigate to the Log Analytics workspace in the Azure Portal.
2. Use the "Logs" blade to query operational data.
3. Check the custom dashboards and workbooks created during deployment.

## Security Considerations

The deployment includes several security features:

1. Azure Key Vault for secure storage of secrets
2. Network segmentation and firewall rules
3. Azure Defender for IoT for threat detection
4. Encryption at rest and in transit

Review the security components and customize according to your organization's security requirements.

## Maintenance and Updates

1. Regularly check for Azure service updates
2. Implement a CI/CD pipeline for ongoing development
3. Schedule regular backups of critical data
4. Monitor system performance and scale components as needed

For additional support or questions, contact the solution architecture team.
