$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

function Wait-ForHttpConfirmation($topicArn, $endpoint) {
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 2
        $subs = aws --endpoint-url=$ENDPOINT sns list-subscriptions-by-topic `
            --topic-arn $topicArn | ConvertFrom-Json

        $confirmed = $subs.Subscriptions | Where-Object {
            $_.Endpoint -eq $endpoint -and $_.SubscriptionArn -ne "pending confirmation"
        }

        if ($confirmed) {
            return $confirmed.SubscriptionArn
        }
    }

    return $null
}

try {
    $ENDPOINT = "http://localhost:4566"
    $TOPIC_NAME = "meu-topico-local"
    $HTTP_ENDPOINT = "http://localstack-sqs-api/webhook"

    Log "Criando tópico SNS..."
    $TOPIC_ARN = (aws --endpoint-url=$ENDPOINT sns create-topic --name $TOPIC_NAME | ConvertFrom-Json).TopicArn
    Log "✔ Tópico criado: $TOPIC_ARN"

    Log "Criando subscription SNS → HTTP (API)..."
    $subResultHttp = aws --endpoint-url=$ENDPOINT sns subscribe `
        --topic-arn $TOPIC_ARN `
        --protocol http `
        --notification-endpoint $HTTP_ENDPOINT | ConvertFrom-Json

    if ($subResultHttp.SubscriptionArn -eq "pending confirmation") {
        Log "🕒 Aguardando confirmação automática via /webhook..."
        $confirmedArn = Wait-ForHttpConfirmation $TOPIC_ARN $HTTP_ENDPOINT

        if ($confirmedArn) {
            Log "✔ Subscription HTTP confirmada: $confirmedArn"
        }
        else {
            throw "❌ O endpoint HTTP não confirmou a inscrição. Verifique se o webhook está ativo."
        }
    }
    elseif ($subResultHttp.SubscriptionArn) {
        Log "✔ Subscription HTTP criada: $($subResultHttp.SubscriptionArn)"
    }
    else {
        throw "❌ Falha ao criar subscription SNS → HTTP."
    }

    Log "📤 Enviando mensagem de teste..."
    $publish = aws --endpoint-url=$ENDPOINT sns publish `
        --topic-arn $TOPIC_ARN `
        --message "Mensagem de teste SNS → HTTP" | ConvertFrom-Json

    Log "✔ Mensagem publicada com ID: $($publish.MessageId)"

    Log "🎉 Ambiente SNS → HTTP configurado com sucesso!"
}
catch {
    Write-Host "`n❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}
