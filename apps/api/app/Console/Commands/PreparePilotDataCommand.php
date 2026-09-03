<?php

namespace App\Console\Commands;

use Database\Seeders\AiConfigSeeder;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Database\Seeders\TelegramPilotAllowlistSeeder;
use Illuminate\Console\Command;

class PreparePilotDataCommand extends Command
{
    protected $signature = 'autodoctor:prepare-pilot';

    protected $description = 'Apply migrations and seed published maintenance rules plus AI config for api-dev.';

    public function handle(): int
    {
        $this->call('migrate', ['--force' => true]);
        $this->call('db:seed', ['--class' => MaintenanceV1Seeder::class, '--force' => true]);
        $this->call('db:seed', ['--class' => MaintenanceV2Seeder::class, '--force' => true]);
        $this->call('db:seed', ['--class' => AiConfigSeeder::class, '--force' => true]);
        $this->call('db:seed', ['--class' => TelegramPilotAllowlistSeeder::class, '--force' => true]);
        $this->info('Pilot data is ready.');

        return self::SUCCESS;
    }
}
