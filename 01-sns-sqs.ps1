$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

$ENDPOINT = "http://localhost:4566"
$TOPIC_NAME = "meu-topico-local"
$QUEUE_NAME = "minha-fila-local"

Log "Criando tópico SNS..."
$TOPIC_ARN = (aws --endpoint-url=$ENDPOINT sns create-topic --name $TOPIC_NAME | ConvertFrom-Json).TopicArn
Log "✔ Tópico criado: $TOPIC_ARN"

Log "Criando fila SQS..."
aws --endpoint-url=$ENDPOINT sqs create-queue --queue-name $QUEUE_NAME | Out-Null
$QUEUE_URL = "$ENDPOINT/000000000000/$QUEUE_NAME"
Log "✔ Fila criada: $QUEUE_URL"

$QUEUE_ARN = (aws --endpoint-url=$ENDPOINT sqs get-queue-attributes `
    --queue-url $QUEUE_URL --attribute-name All | ConvertFrom-Json).Attributes.QueueArn
Log "✔ ARN da fila: $QUEUE_ARN"

Log "Aplicando policy SNS → SQS..."
$policyObject = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = "*"
            Action = "sqs:SendMessage"
            Resource = $QUEUE_ARN
            Condition = @{ ArnEquals = @{ "aws:SourceArn" = $TOPIC_ARN } }
        }
    )
}
$policyRaw = $policyObject | ConvertTo-Json -Depth 5 -Compress
$policyEscaped = $policyRaw -replace '"', '\"'
aws --endpoint-url=$ENDPOINT sqs set-queue-attributes `
    --queue-url $QUEUE_URL `
    --attributes "Policy=\"$policyEscaped\""

Log "✔ Policy aplicada"
Log "Criando subscription SNS → SQS..."
$subResultSqs = aws --endpoint-url=$ENDPOINT sns subscribe `
    --topic-arn $TOPIC_ARN `
    --protocol sqs `
    --notification-endpoint $QUEUE_ARN | ConvertFrom-Json
Log "✔ Subscription criada: $($subResultSqs.SubscriptionArn)"
