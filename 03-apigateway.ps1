$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$LAMBDA_NAME = "MinhaFuncaoLambda"
$API_NAME = "MinhaApiGateway"

Log "Criando API Gateway..."
$restApiId = (aws --endpoint-url=$ENDPOINT apigateway create-rest-api `
    --name $API_NAME | ConvertFrom-Json).id
$rootResourceId = (aws --endpoint-url=$ENDPOINT apigateway get-resources `
    --rest-api-id $restApiId | ConvertFrom-Json).items[0].id
Log "✔ API: $restApiId | Root: $rootResourceId"

Log "Criando recurso /invoke..."
$resourceId = (aws --endpoint-url=$ENDPOINT apigateway create-resource `
    --rest-api-id $restApiId `
    --parent-id $rootResourceId `
    --path-part "invoke" | ConvertFrom-Json).id

Log "Criando método GET..."
aws --endpoint-url=$ENDPOINT apigateway put-method `
    --rest-api-id $restApiId `
    --resource-id $resourceId `
    --http-method GET `
    --authorization-type "NONE" | Out-Null

Log "Integrando com Lambda..."
$lambdaArn = "arn:aws:lambda:$REGION:000000000000:function:$LAMBDA_NAME"
$lambdaUri = "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$lambdaArn/invocations"

aws --endpoint-url=$ENDPOINT apigateway put-integration `
  --rest-api-id $restApiId `
  --resource-id $resourceId `
  --http-method GET `
  --type AWS_PROXY `
  --integration-http-method POST `
  --uri $lambdaUri | Out-Null

Log "Implantando API..."
aws --endpoint-url=$ENDPOINT apigateway create-deployment `
    --rest-api-id $restApiId `
    --stage-name dev | Out-Null

# Armazena o ID para o próximo script opcional
Set-Content -Path "/tmp/restApiId.txt" -Value $restApiId
