<?php

namespace Tests\Unit;

use App\Services\Firebase\FirebaseRemoteConfigClient;
use App\Services\Monetization\MonetizationCatalogService;
use Tests\TestCase;

class MonetizationCatalogServiceTest extends TestCase
{
    public function test_uses_bundled_defaults_when_remote_config_unavailable(): void
    {
        config(['firebase.force_defaults' => true]);

        $service = app(MonetizationCatalogService::class);
        $topup = $service->topupCatalog(null);

        $this->assertSame('defaults', $topup['source']);
        $this->assertSame('Добавить токены', $topup['button_label']);
        $this->assertNotEmpty($topup['options']);
        $this->assertSame('stars_pack_s', $topup['options'][0]['key']);
        $this->assertSame(50, $topup['options'][0]['stars_price']);
        $this->assertSame('50 ⭐', $topup['options'][0]['price_label']);
    }

    public function test_parses_firebase_json_override(): void
    {
        config(['firebase.force_defaults' => false, 'firebase.monetization_key' => 'monetization_v1']);

        $remote = $this->createMock(FirebaseRemoteConfigClient::class);
        $remote->method('getParameterString')->willReturn(json_encode([
            'version' => 1,
            'button_label' => 'Токены RC',
            'packs' => [
                [
                    'key' => 'stars_pack_s',
                    'type' => 'stars',
                    'title' => 'Test pack',
                    'tokens_amount' => 1111,
                    'stars_price' => 77,
                    'enabled' => true,
                    'sort_order' => 1,
                ],
            ],
        ], JSON_THROW_ON_ERROR));

        $service = new MonetizationCatalogService($remote);
        $topup = $service->topupCatalog(null);

        $this->assertSame('firebase', $topup['source']);
        $this->assertSame('Токены RC', $topup['button_label']);
        $this->assertCount(1, $topup['options']);
        $this->assertSame(77, $topup['options'][0]['stars_price']);
        $this->assertSame('+1 111', $topup['options'][0]['tokens_label']);
    }
}
