$ENDPOINT = "http://localhost:4566"
$REST_API_FILE = "./api-info/restApiId.txt"  # uso de caminho relativo compatível

if (Test-Path $REST_API_FILE) {
    $restApiId = Get-Content $REST_API_FILE -Raw
    Write-Host "🎉 Tudo pronto! Teste via: $ENDPOINT/restapis/$restApiId/dev/_user_request_/invoke"
} else {
    Write-Host "⚠️ API ainda não criada ou falhou em etapas anteriores."
}
