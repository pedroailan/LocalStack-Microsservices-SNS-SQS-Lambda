#!/bin/bash

set -e

# Parâmetros
TOPIC_NAME="meu-topico-local"
QUEUE_NAME="minha-fila-local"
ENDPOINT="http://localhost:4566"
REGION="us-east-1"
ACCOUNT_ID="000000000000"

# Criação do tópico SNS
echo "📡 Criando tópico SNS: $TOPIC_NAME"
TOPIC_ARN=$(aws --endpoint-url=$ENDPOINT sns create-topic --name $TOPIC_NAME --output text --query 'TopicArn')
echo "✔ Tópico criado: $TOPIC_ARN"

# Criação da fila SQS
echo "📥 Criando fila SQS: $QUEUE_NAME"
QUEUE_URL=$(aws --endpoint-url=$ENDPOINT sqs create-queue --queue-name $QUEUE_NAME --output text --query 'QueueUrl')
echo "✔ Fila criada: $QUEUE_URL"

# Obtenção do ARN da fila
QUEUE_ARN=$(aws --endpoint-url=$ENDPOINT sqs get-queue-attributes \
  --queue-url $QUEUE_URL \
  --attribute-name QueueArn \
  --output text --query 'Attributes.QueueArn')
echo "🔗 ARN da fila: $QUEUE_ARN"

# Aplicar Policy de permissão SNS → SQS
echo "🔐 Aplicando policy de envio do SNS para a fila"
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "sqs:SendMessage",
    "Resource": "$QUEUE_ARN",
    "Condition": {
      "ArnEquals": {
        "aws:SourceArn": "$TOPIC_ARN"
      }
    }
  }]
}
EOF
)

aws --endpoint-url=$ENDPOINT sqs set-queue-attributes \
  --queue-url $QUEUE_URL \
  --attributes Policy="$POLICY"

echo "✔ Policy aplicada com sucesso"

# Criar subscription SNS → SQS
echo "🔁 Criando subscription SNS → SQS"
aws --endpoint-url=$ENDPOINT sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $QUEUE_ARN > /dev/null

echo "✔ Subscription SQS criada"

# Criar subscription SNS → API (via HTTP)
echo "🔁 Criando subscription SNS → HTTP (API localstack-sns-api)"
aws --endpoint-url=$ENDPOINT sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol http \
  --notification-endpoint http://localstack-sns-api/webhook > /dev/null

echo "✔ Subscription HTTP criada"

echo "🎉 Ambiente SNS → SQS e SNS → API configurado com sucesso!"
