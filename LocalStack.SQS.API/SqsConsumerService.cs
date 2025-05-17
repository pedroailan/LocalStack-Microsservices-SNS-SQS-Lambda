using Amazon.Runtime;
using Amazon.SQS;
using Amazon.SQS.Model;

namespace LocalStack.SQS.API
{
    public class SqsConsumerService: BackgroundService
    {
        private readonly ILogger<SqsConsumerService> _logger;
        private readonly IAmazonSQS _sqs;
        private const string QueueUrl = "http://localhost:4566/000000000000/minha-fila-local";

        public SqsConsumerService(ILogger<SqsConsumerService> logger)
        {
            _logger = logger;

            var config = new AmazonSQSConfig
            {
                ServiceURL = "http://localstack:4566",
                AuthenticationRegion = "us-east-1"
            };

            _sqs = new AmazonSQSClient(
                new BasicAWSCredentials("test", "test"),
                config
            );
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var messages = await _sqs.ReceiveMessageAsync(new ReceiveMessageRequest
                {
                    QueueUrl = QueueUrl,
                    MaxNumberOfMessages = 10,
                    WaitTimeSeconds = 2
                }, stoppingToken);

                if (messages.Messages is null)
                {
                    continue;
                }

                foreach (var message in messages.Messages)
                {
                    _logger.LogInformation("Mensagem da fila: {0}", message.Body);

                    await _sqs.DeleteMessageAsync(QueueUrl, message.ReceiptHandle, stoppingToken);
                }
            }
        }
    }

}
