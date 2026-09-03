<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>AutoDoctor</title>
    <script src="https://telegram.org/js/telegram-web-app.js"></script>
    <style>
        :root {
            color-scheme: dark;
            --bg: #12110f;
            --card: #1c1a16;
            --text: #f5f0e8;
            --muted: #b7ada0;
            --accent: #f5b942;
            --line: rgba(245, 240, 232, 0.08);
        }
        * { box-sizing: border-box; }
        html, body {
            margin: 0;
            min-height: 100%;
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        .wrap {
            max-width: 420px;
            margin: 0 auto;
            padding: 28px 20px 40px;
        }
        .mark {
            width: 56px;
            height: 56px;
            border-radius: 16px;
            background: var(--accent);
            color: #1a1408;
            display: grid;
            place-items: center;
            font-weight: 800;
            font-size: 22px;
            letter-spacing: -0.04em;
        }
        h1 {
            margin: 20px 0 8px;
            font-size: 28px;
            letter-spacing: -0.03em;
        }
        .lead { color: var(--muted); line-height: 1.45; margin: 0 0 24px; }
        .card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 18px;
            padding: 16px 18px;
            margin-bottom: 12px;
        }
        .label { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; }
        .value { margin-top: 6px; font-size: 18px; }
        .hint { margin-top: 18px; color: var(--muted); font-size: 13px; }
        .work { padding: 8px 0; border-top: 1px solid var(--line); font-size: 15px; }
        .work:first-child { border-top: 0; padding-top: 0; }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="mark">AD</div>
        <h1 id="title">AutoDoctor</h1>
        <p class="lead" id="lead">Загружаем…</p>
        <div id="cards"></div>
        <p class="hint">Пока это заставка Mini App. Журнал и советы — в чате с ботом.</p>
    </div>
    <script>
        const app = window.Telegram && window.Telegram.WebApp;
        if (app) {
            app.ready();
            app.expand();
            document.body.style.background = app.themeParams.bg_color || '';
        }
        const initData = app && app.initData ? app.initData : '';
        fetch(@json(url('/telegram/app/state')), {
            headers: { 'X-Telegram-Init-Data': initData, 'Accept': 'application/json' }
        }).then(async (response) => {
            const data = await response.json();
            document.getElementById('title').textContent = data.greeting || 'AutoDoctor';
            document.getElementById('lead').textContent = data.subtitle || data.error || 'Не удалось загрузить.';
            const root = document.getElementById('cards');
            if (data.vehicle) {
                const v = data.vehicle;
                const bits = [v.year, v.mileage ? (v.mileage + ' км') : null, v.fuel].filter(Boolean).join(' · ');
                root.insertAdjacentHTML('beforeend',
                    '<div class="card"><div class="label">Авто</div><div class="value">' +
                    escapeHtml(v.title) + '</div><div class="hint" style="margin:8px 0 0">' +
                    escapeHtml(bits) + '</div></div>'
                );
            }
            if (data.works && data.works.length) {
                const items = data.works.map((work) => {
                    return '<div class="work">' + escapeHtml((work.date ? work.date + ' · ' : '') + work.note) + '</div>';
                }).join('');
                root.insertAdjacentHTML('beforeend',
                    '<div class="card"><div class="label">Работы</div>' + items + '</div>'
                );
            }
        }).catch(() => {
            document.getElementById('lead').textContent = 'Не удалось загрузить данные.';
        });
        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, (ch) => ({
                '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
            }[ch]);
        }
    </script>
</body>
</html>
