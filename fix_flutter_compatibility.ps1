# Script pour corriger la compatibilité Flutter 3.24
# Remplace .withValues(alpha: X) par .withOpacity(X)

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Remplacer .withValues(alpha: X) par .withOpacity(X)
    $newContent = $content -replace '\.withValues\(alpha:\s*([0-9.]+)\)', '.withOpacity($1)'
    
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Fixed: $($file.FullName)"
    }
}

Write-Host "`nRemplacement terminé!"
