<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(MaintenanceV1Seeder::class);
        $this->call(MaintenanceV2Seeder::class);
        $this->call(AiConfigSeeder::class);
        $this->call(TokenTopupPackageSeeder::class);

        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        User::query()->updateOrCreate(
            ['email' => 'admin@autodoctor.local'],
            [
                'name' => 'AutoDoctor Admin',
                'password' => 'password',
                'is_admin' => true,
            ],
        );
    }
}
