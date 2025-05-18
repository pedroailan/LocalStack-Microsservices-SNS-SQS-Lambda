$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

try {
    $ENDPOINT = "http://localhost:4566"
    $REGION = "us-east-1"
    $LAMBDA_NAME = "MinhaFuncaoLambda"
    $STAGE_NAME = "dev"
    $RESOURCE_PATH = "invoke"

    Log "Criando API Gateway..."
    $api = aws --endpoint-url $ENDPOINT apigateway create-rest-api `
        --name "MinhaAPI" `
        --region $REGION | ConvertFrom-Json
    $apiId = $api.id

    $root = aws --endpoint-url $ENDPOINT apigateway get-resources `
        --rest-api-id $apiId | ConvertFrom-Json
    $rootId = ($root.items | Where-Object { $_.path -eq "/" }).id
    Log "✔ API: $apiId | Root: $rootId"

    Log "Criando recurso /$RESOURCE_PATH..."
    $resource = aws --endpoint-url $ENDPOINT apigateway create-resource `
        --rest-api-id $apiId `
        --parent-id $rootId `
        --path-part $RESOURCE_PATH | ConvertFrom-Json
    $resourceId = $resource.id

    Log "Criando métodos GET e POST..."
    foreach ($method in @("GET", "POST")) {
        aws --endpoint-url $ENDPOINT apigateway put-method `
            --rest-api-id $apiId `
            --resource-id $resourceId `
            --http-method $method `
            --authorization-type NONE | Out-Null
    }

    Log "Recuperando ARN da Lambda..."
    $functionArn = aws --endpoint-url $ENDPOINT lambda get-function `
        --function-name $LAMBDA_NAME | ConvertFrom-Json |
        Select-Object -ExpandProperty Configuration |
        Select-Object -ExpandProperty FunctionArn

    $integrationUri = "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${functionArn}/invocations"
    Log "URI de integração: $integrationUri"

    Log "Integrando métodos com Lambda..."
    foreach ($method in @("GET", "POST")) {
        aws --endpoint-url $ENDPOINT apigateway put-integration `
            --rest-api-id $apiId `
            --resource-id $resourceId `
            --http-method $method `
            --type AWS_PROXY `
            --integration-http-method POST `
            --uri $integrationUri | Out-Null
    }

    Log "Implantando API..."
    aws --endpoint-url $ENDPOINT apigateway create-deployment `
        --rest-api-id $apiId `
        --stage-name $STAGE_NAME | Out-Null

    $invokeUrl = "$ENDPOINT/restapis/$apiId/$STAGE_NAME/_user_request_/$RESOURCE_PATH"
    Log "✔ API disponível em: $invokeUrl"

    # Opcional: salvar ID para reuso
    if (-not (Test-Path "./api-info")) { New-Item "./api-info" -ItemType Directory | Out-Null }
    Set-Content -Path "./api-info/restApiId.txt" -Value $apiId
}
catch {
    Log "❌ Erro durante execução: $_"
    exit 1
}
