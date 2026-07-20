<?php

namespace Tests\Feature;

use Illuminate\Support\Carbon;
use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    public function test_api_health_endpoint_is_available(): void
    {
        Carbon::setTestNow('2026-07-17T08:00:00Z');

        $response = $this->getJson('/api/v1/health');

        $response
            ->assertOk()
            ->assertExactJson([
                'status' => 'ok',
                'service' => 'autodoctor-api',
                'version' => '0.4.0-draft',
                'time' => '2026-07-17T08:00:00.000000Z',
            ]);

        $response->assertHeader('X-Request-ID');
    }
}
