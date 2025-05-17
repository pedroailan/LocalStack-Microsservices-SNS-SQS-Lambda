$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

try {
    $ENDPOINT = "http://localhost:4566"
    $TOPIC_NAME = "meu-topico-local"
    $QUEUE_NAME = "minha-fila-local"

    Log "Criando tópico SNS..."
    $TOPIC_ARN = (aws --endpoint-url=$ENDPOINT sns create-topic --name $TOPIC_NAME | ConvertFrom-Json).TopicArn
    Log "✔ Tópico criado: $TOPIC_ARN"

    Log "Criando fila SQS..."
    aws --endpoint-url=$ENDPOINT sqs create-queue --queue-name $QUEUE_NAME | Out-Null
    $QUEUE_URL = "http://localhost:4566/000000000000/$QUEUE_NAME"
    Log "✔ Fila criada: $QUEUE_URL"

    Log "Obtendo ARN da fila..."
    $attributes = aws --endpoint-url=$ENDPOINT sqs get-queue-attributes `
        --queue-url $QUEUE_URL `
        --attribute-name All | ConvertFrom-Json

    $QUEUE_ARN = $attributes.Attributes.QueueArn

    if (-not $QUEUE_ARN) {
        throw "❌ Falha ao obter o ARN da fila. Verifique se a fila foi criada corretamente."
    }

    Log "✔ ARN da fila: $QUEUE_ARN"

    Log "Montando policy SNS → SQS..."

    $policyObject = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Principal = "*"
                Action = "sqs:SendMessage"
                Resource = $QUEUE_ARN
                Condition = @{
                    ArnEquals = @{
                        "aws:SourceArn" = $TOPIC_ARN
                    }
                }
            }
        )
    }

    $policyRaw = $policyObject | ConvertTo-Json -Depth 5 -Compress
    $policyEscaped = $policyRaw -replace '"', '\"'

    Log "Aplicando policy na fila SQS..."
    aws --endpoint-url=$ENDPOINT sqs set-queue-attributes `
        --queue-url $QUEUE_URL `
        --attributes "Policy=\"$policyEscaped\""
    Log "✔ Policy aplicada com sucesso"

    Log "Criando subscription SNS → SQS..."
    $subResultSqs = aws --endpoint-url=$ENDPOINT sns subscribe `
        --topic-arn $TOPIC_ARN `
        --protocol sqs `
        --notification-endpoint $QUEUE_ARN | ConvertFrom-Json

    if ($subResultSqs.SubscriptionArn) {
        Log "✔ Subscription SQS criada: $($subResultSqs.SubscriptionArn)"
    } else {
        throw "❌ Falha ao criar subscription SNS → SQS."
    }

    Log "🎉 Ambiente SNS → SQS configurado com sucesso!"
}
catch {
    Write-Host "`n❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}
