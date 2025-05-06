// WAT.IoT.Devices/Helpers/DeviceSecurityHelper.cs
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Provisioning.Client;
using Microsoft.Azure.Devices.Provisioning.Client.Transport;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace WAT.IoT.Devices.Helpers
{
    public static class DeviceSecurityHelper
    {
        public static string ComputeDerivedSymmetricKey(string masterKey, string deviceId)
        {
            using (var hmac = new HMACSHA256(Convert.FromBase64String(masterKey)))
            {
                return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(deviceId)));
            }
        }

        public static async Task<DeviceRegistrationResult> RegisterDeviceWithDpsAsync(
            string idScope,
            string deviceId,
            string primaryKey,
            string globalEndpoint,
            ILogger logger)
        {
            try
            {
                logger.LogInformation("Registering device {DeviceId} with DPS", deviceId);

                // Create a security provider using symmetric key for authentication
                using var securityProvider = new SecurityProviderSymmetricKey(
                    deviceId,
                    primaryKey,
                    null);

                // Create the transport (MQTT) for communicating with DPS
                using var transport = new ProvisioningTransportHandlerMqtt();

                // Create the provisioning client
                var provClient = ProvisioningDeviceClient.Create(
                    globalEndpoint,
                    idScope,
                    securityProvider,
                    transport);

                // Register the device
                var result = await provClient.RegisterAsync();

                logger.LogInformation("Registration result: {Status}", result.Status);

                if (result.Status == ProvisioningRegistrationStatusType.Assigned)
                {
                    logger.LogInformation("Device {DeviceId} registered to hub {Hub} with ID {AssignedId}",
                        deviceId, result.AssignedHub, result.DeviceId);
                }
                else
                {
                    logger.LogWarning("Device {DeviceId} failed to register. Status: {Status}",
                        deviceId, result.Status);
                }

                return result;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error registering device {DeviceId} with DPS", deviceId);
                throw;
            }
        }

        public static DeviceClient CreateDeviceClientFromDpsRegistrationAsync(
     DeviceRegistrationResult registrationResult,
     string symmetricKey,
     ILogger logger)
        {
            if (registrationResult.Status != ProvisioningRegistrationStatusType.Assigned)
            {
                logger.LogError("Cannot create device client because device is not assigned");
                throw new InvalidOperationException("Device registration is not in 'Assigned' state");
            }

            // Create the device client using the provided symmetric key
            var auth = new DeviceAuthenticationWithRegistrySymmetricKey(
                registrationResult.DeviceId,
                symmetricKey);

            var deviceClient = DeviceClient.Create(
                registrationResult.AssignedHub,
                auth,
                TransportType.Mqtt);

            logger.LogInformation("Created device client for device {DeviceId}", registrationResult.DeviceId);
            return deviceClient;
        }

        public static async Task UpdateDeviceTwinAsync(DeviceClient deviceClient, Dictionary<string, object> reportedProperties, ILogger logger)
        {
            try
            {
                var twin = await deviceClient.GetTwinAsync();
                var patch = new TwinCollection();

                foreach (var prop in reportedProperties)
                {
                    patch[prop.Key] = prop.Value;
                }

                await deviceClient.UpdateReportedPropertiesAsync(patch);
                logger.LogInformation("Updated device twin properties");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error updating device twin properties");
                throw;
            }
        }
    }
}
