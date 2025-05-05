using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace WAT.IoT.Functions
{
    public static class SampleFunction
    {
        [FunctionName("SampleFunction")]
        public static async Task Run(
            [TimerTrigger("0 */5 * * * *")] TimerInfo myTimer, // Runs every 5 minutes
            ILogger log)
        {
            log.LogInformation($"Sample function executed at: {DateTime.Now}");
            
            // Your function logic here
            await Task.Delay(1); // Placeholder for async operation
            
            log.LogInformation("Sample function completed successfully");
        }
    }
}
