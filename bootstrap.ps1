$ErrorActionPreference = "Stop"

function Log($msg) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

try {
    Log "Executando 01-sns-sqs.ps1..."
    . "./01-sns-sqs.ps1"

    Log "Executando 02-lambda.ps1..."
    . "./02-lambda.ps1"

    Log "Executando 03-apigateway.ps1..."
    . "./03-apigateway.ps1"

    Log "Executando 99-final-log.ps1..."
    . "./99-final-log.ps1"

    Log "Todos os scripts foram executados com sucesso."
} catch {
    Log "Erro durante execução: $_"
    exit 1
}
