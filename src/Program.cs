using WebApplication.Services;

var builder = Microsoft.AspNetCore.Builder.WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddGrpc();
builder.Services.AddGrpcReflection();
builder.Services.AddSwaggerGen();
builder.Services.AddControllers();

var app = builder.Build();

// Log startup info
var appName = builder.Configuration.GetValue<string>("Application:Name") ?? "CoreBanking.API";
app.Logger.LogInformation("Starting {appName} with gRPC and HTTP/2 support...", appName);

// Map gRPC services
app.MapGrpcService<GreeterService>();

// Map gRPC reflection service (Development only)
// if (app.Environment.IsDevelopment())
// {
//     app.MapGrpcReflectionService();
// }
app.MapGrpcReflectionService();
// Routing
app.MapControllers();

// Health endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", app = appName }))
   .WithName("HealthCheck");

// Root endpoint
app.MapGet("/", () => Results.Ok($"{appName} running with gRPC support"));

// gRPC-Web endpoint for browser testing
app.MapGet("/grpc-test", () => Results.Ok(new
{
    message = "gRPC service available at /greet.Greeter",
    protocol = "HTTP/2",
    endpoint = "SayHello"
}));

app.Run();
