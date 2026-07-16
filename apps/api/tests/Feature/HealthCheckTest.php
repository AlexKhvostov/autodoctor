<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    public function test_api_health_endpoint_is_available(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response
            ->assertOk()
            ->assertExactJson([
                'status' => 'ok',
                'service' => 'autodoctor-api',
            ]);
    }
}
