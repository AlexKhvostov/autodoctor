param(
    [string]$Php = "php",
    [switch]$PrepareOnly
)

$ErrorActionPreference = "Stop"
$apiRoot = Join-Path $PSScriptRoot "..\apps\api"
$envPath = Join-Path $apiRoot ".env"
$sqlitePath = Join-Path $apiRoot "database\database.sqlite"
$createdEnvironment = $false

Push-Location $apiRoot
try {
    if (-not (Test-Path $envPath)) {
        $environment = Get-Content ".env.example" -Raw
        $environment = $environment.Replace("DB_CONNECTION=pgsql", "DB_CONNECTION=sqlite")
        Set-Content -Path $envPath -Value $environment -Encoding UTF8
        $createdEnvironment = $true
        Write-Host "Created local .env with SQLite."
    }

    if (-not (Test-Path $sqlitePath)) {
        [System.IO.File]::WriteAllBytes($sqlitePath, [byte[]]::new(0))
        Write-Host "Created database/database.sqlite."
    }

    $environment = Get-Content $envPath -Raw
    if ($environment -notmatch "(?m)^VIN_HASH_KEY=.+$") {
        $bytes = [byte[]]::new(32)
        $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $generator.GetBytes($bytes)
        }
        finally {
            $generator.Dispose()
        }
        $vinHashKey = [Convert]::ToBase64String($bytes)
        if ($environment -match "(?m)^VIN_HASH_KEY=.*$") {
            $environment = [regex]::Replace(
                $environment,
                "(?m)^VIN_HASH_KEY=.*$",
                "VIN_HASH_KEY=$vinHashKey"
            )
        }
        else {
            $environment = "$environment`r`nVIN_HASH_KEY=$vinHashKey`r`n"
        }
        Set-Content -Path $envPath -Value $environment -Encoding UTF8
        Write-Host "Generated local VIN_HASH_KEY."
    }

    if ($createdEnvironment) {
        & $Php artisan key:generate --force
        if ($LASTEXITCODE -ne 0) { throw "Unable to generate APP_KEY." }
    }

    & $Php artisan migrate --force
    if ($LASTEXITCODE -ne 0) { throw "Database migration failed." }

    & $Php artisan db:seed --class=Database\Seeders\MaintenanceV1Seeder --force
    if ($LASTEXITCODE -ne 0) { throw "Maintenance v1 baseline seeding failed." }

    & $Php artisan db:seed --class=Database\Seeders\MaintenanceV2Seeder --force
    if ($LASTEXITCODE -ne 0) { throw "Maintenance v2 baseline seeding failed." }

    if (-not $PrepareOnly) {
        Write-Host "AutoDoctor API: http://0.0.0.0:8000"
        Write-Host "Android emulator uses: http://10.0.2.2:8000/api/v1"
        & $Php artisan serve --host=0.0.0.0 --port=8000
        if ($LASTEXITCODE -ne 0) { throw "Laravel development server stopped with an error." }
    }
}
finally {
    Pop-Location
}
