using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddSingleton<IAmazonSimpleNotificationService>(sp =>
{
    AmazonSimpleNotificationServiceConfig config = new()
    {
        ServiceURL = "http://host.docker.internal:4566",
        AuthenticationRegion = "us-east-1",
    };
    return new AmazonSimpleNotificationServiceClient("test", "test", config);
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapPost("/publish", async ([FromQuery] string message, IAmazonSimpleNotificationService sns) =>
{
    var topicArn = builder.Configuration["TopicName"];

    var response = await sns.PublishAsync(new PublishRequest
    {
        TopicArn = topicArn,
        Message = message
    });

    return Results.Ok(new
    {
        response.MessageId,
        Status = "Published with success! ;)"
    });
});

app.Run();
