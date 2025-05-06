var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();



app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();


// Add the missing extension method for MapStaticAssets.  
public static class StaticAssetsExtensions
{
    public static IEndpointRouteBuilder MapStaticAssets(this IEndpointRouteBuilder endpoints)
    {
        var app = endpoints as IApplicationBuilder;
        if (app != null)
        {
            app.UseStaticFiles();
        }
        return endpoints;
    }
}// Add the missing extension method for WithStaticAssets.
public static class ControllerActionEndpointConventionBuilderExtensions
{
    public static ControllerActionEndpointConventionBuilder WithStaticAssets(this ControllerActionEndpointConventionBuilder builder)
    {
        // Fix: Use the IServiceProvider from the builder's application services to resolve IApplicationBuilder
        builder.Add(endpointBuilder =>
        {
            // EndpointBuilder does not have ApplicationServices. Instead, use the IServiceProvider from the builder.
            var applicationServices = builder.GetType()
                                              .GetProperty("ApplicationServices", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)?
                                              .GetValue(builder) as IServiceProvider;

            if (applicationServices != null)
            {
                var app = applicationServices.GetService(typeof(IApplicationBuilder)) as IApplicationBuilder;
                if (app != null)
                {
                    app.UseStaticFiles();
                }
            }
        });

        return builder;
    }
}
