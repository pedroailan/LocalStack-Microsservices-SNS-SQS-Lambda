$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

$ENDPOINT = "http://localhost:4566"
$LAMBDA_NAME = "MinhaFuncaoLambda"
$REGION = "us-east-1"
$ZIP_PATH = "/tmp/lambda.zip"

Log "Criando função Lambda..."
aws --endpoint-url=$ENDPOINT lambda create-function `
    --function-name $LAMBDA_NAME `
    --runtime dotnet8 `
    --handler LocalStack.Lambda.Function::Function::FunctionHandler `
    --role arn:aws:iam::000000000000:role/lambda-role `
    --zip-file fileb://$ZIP_PATH | Out-Null
Log "✔ Função Lambda criada"
