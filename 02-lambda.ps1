$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

try {
    # Variáveis
    $ENDPOINT = "http://localhost:4566"
    $LAMBDA_NAME = "MinhaFuncaoLambda"
    $REGION = "us-east-1"
    $PROJECT_PATH = "LocalStack.Lambda.Function/src/LocalStack.Lambda.Function"
    $PUBLISH_DIR = "publish"
    $ZIP_PATH = "lambda.zip"
    $HANDLER = "LocalStack.Lambda.Function::LocalStack.Lambda.Function.Function::FunctionHandler"
    $ROLE_ARN = "arn:aws:iam::000000000000:role/lambda-role"

    Log "🔧 Limpando publicação anterior..."
    if (Test-Path $PUBLISH_DIR) { Remove-Item $PUBLISH_DIR -Recurse -Force }
    if (Test-Path $ZIP_PATH) { Remove-Item $ZIP_PATH -Force }

    Log "🚀 Publicando projeto .NET..."
    dotnet publish "$PROJECT_PATH" -c Release -o $PUBLISH_DIR

    Log "📦 Gerando ZIP para Lambda..."
    Compress-Archive -Path "$PUBLISH_DIR\*" -DestinationPath $ZIP_PATH -Force

    if (-Not (Test-Path $ZIP_PATH)) {
        throw "❌ Arquivo ZIP não encontrado após compressão: $ZIP_PATH"
    }

    $zipFileParam = "fileb://$ZIP_PATH"
    Log "🧠 Criando função Lambda no LocalStack..."

    $result = aws --endpoint-url=$ENDPOINT lambda create-function `
        --function-name $LAMBDA_NAME `
        --runtime dotnet8 `
        --handler $HANDLER `
        --role $ROLE_ARN `
        --zip-file $zipFileParam 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "❌ Falha ao criar Lambda: $result"
    }

    Log "✔ Função Lambda criada com sucesso"
}
catch {
    Log "❌ Erro durante execução: $_"
    exit 1
}
