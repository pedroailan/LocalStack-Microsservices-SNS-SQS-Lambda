using Amazon.Extensions.NETCore.Setup;
using Amazon.Runtime;
using Amazon;
using Amazon.SQS;
using LocalStack.SQS.API;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddHostedService<SqsConsumerService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// When user SNS -> HTTP
//app.MapPost("/webhook", async (HttpRequest request) =>
//{
//    try
//    {
//        using var reader = new StreamReader(request.Body);
//        var body = await reader.ReadToEndAsync();

//        using var doc = JsonDocument.Parse(body);
//        var root = doc.RootElement;

//        var type = root.GetProperty("Type").GetString();

//        if (type == "SubscriptionConfirmation")
//        {
//            var originalUrl = doc.RootElement.GetProperty("SubscribeURL").GetString();

//            // change hostname to local
//            var fixedUrl = originalUrl!.Replace("localhost.localstack.cloud:4566", "localstack:4566");

//            using var client = new HttpClient();
//            var result = await client.GetAsync(fixedUrl);

//            result.EnsureSuccessStatusCode();

//            return Results.Ok(new { status = "SubscriptionConfirmed", httpCode = result.StatusCode });
//        }

//        if (type == "Notification")
//        {
//            var message = root.GetProperty("Message").GetString();
//            Console.WriteLine($"📨 Mensagem SNS: {message}");
//        }

//        return Results.Ok(new { status = "Recebido" });

//    }
//    catch (Exception ex)
//    {
//        Console.WriteLine(ex);
//        return Results.StatusCode(500);
//    }
//});

await app.RunAsync();