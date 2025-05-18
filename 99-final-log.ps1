$ENDPOINT = "http://localhost:4566"
if (Test-Path "/tmp/restApiId.txt") {
    $restApiId = Get-Content "/tmp/restApiId.txt"
    Write-Host "🎉 Tudo pronto! Teste via: $ENDPOINT/restapis/$restApiId/dev/_user_request_/invoke"
} else {
    Write-Host "⚠️ API ainda não criada ou falhou em etapas anteriores."
}
