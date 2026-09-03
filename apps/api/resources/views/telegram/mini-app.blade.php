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
            --muted: #9d9488;
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
            font-size: 14px;
        }
        .wrap {
            max-width: 420px;
            margin: 0 auto;
            padding: 16px 14px 28px;
        }
        .app-title {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
            letter-spacing: -0.02em;
        }
        .app-subtitle {
            margin: 6px 0 14px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.4;
        }
        .vehicle {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            margin-bottom: 8px;
            overflow: hidden;
        }
        .vehicle-head {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 12px 14px;
            border: 0;
            background: transparent;
            color: inherit;
            text-align: left;
            cursor: pointer;
        }
        .vehicle-title {
            font-size: 15px;
            font-weight: 600;
            line-height: 1.25;
        }
        .vehicle-summary {
            margin-top: 3px;
            color: var(--muted);
            font-size: 12px;
            line-height: 1.3;
        }
        .vehicle-meta {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }
        .badge {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            padding: 2px 6px;
            border-radius: 999px;
            border: 1px solid var(--line);
            color: var(--muted);
        }
        .badge.draft { color: var(--accent); border-color: rgba(245, 185, 66, 0.25); }
        .chevron {
            color: var(--muted);
            font-size: 16px;
            line-height: 1;
            transition: transform 0.15s ease;
        }
        .vehicle.open .chevron { transform: rotate(90deg); }
        .vehicle-body {
            display: none;
            border-top: 1px solid var(--line);
            padding: 0 14px 12px;
        }
        .vehicle.open .vehicle-body { display: block; }
        .section { padding-top: 10px; }
        .section-title {
            color: var(--muted);
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            margin-bottom: 4px;
        }
        .field-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 7px 0;
            border-top: 1px solid var(--line);
            line-height: 1.35;
        }
        .field-row:first-of-type { border-top: 0; }
        .field-label { color: var(--muted); flex: 1.1; font-size: 13px; }
        .field-value {
            flex: 1;
            text-align: right;
            font-size: 13px;
            word-break: break-word;
        }
        .field-value.empty { color: rgba(157, 148, 136, 0.55); }
        .footer-hint {
            margin-top: 10px;
            color: var(--muted);
            font-size: 11px;
            line-height: 1.4;
        }
    </style>
</head>
<body>
    <div class="wrap">
        <h1 class="app-title" id="title">AutoDoctor</h1>
        <p class="app-subtitle" id="subtitle">Загружаем…</p>
        <div id="vehicles"></div>
        <p class="footer-hint">Пустые поля — «—». Дописать можно боту; в базу — через «Записать».</p>
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
            document.getElementById('title').textContent = data.title || 'AutoDoctor';
            document.getElementById('subtitle').textContent = data.subtitle || data.error || 'Не удалось загрузить.';
            const root = document.getElementById('vehicles');
            root.innerHTML = '';
            (data.vehicles || []).forEach((vehicle, index) => {
                root.insertAdjacentHTML('beforeend', renderVehicle(vehicle, index));
            });
            root.querySelectorAll('.vehicle-head').forEach((button) => {
                button.addEventListener('click', () => {
                    button.closest('.vehicle').classList.toggle('open');
                });
            });
        }).catch(() => {
            document.getElementById('subtitle').textContent = 'Не удалось загрузить данные.';
        });

        function renderVehicle(vehicle, index) {
            const summary = vehicle.summary
                ? '<div class="vehicle-summary">' + escapeHtml(vehicle.summary) + '</div>'
                : '';
            const badge = vehicle.status === 'draft'
                ? '<span class="badge draft">черновик</span>'
                : '';
            const sections = (vehicle.sections || []).map(renderSection).join('');

            return '<div class="vehicle" id="vehicle-' + index + '">' +
                '<button class="vehicle-head" type="button" aria-expanded="false">' +
                '<div><div class="vehicle-title">' + escapeHtml(vehicle.title || 'Автомобиль') + '</div>' +
                summary + '</div>' +
                '<div class="vehicle-meta">' + badge +
                '<span class="chevron">›</span></div></button>' +
                '<div class="vehicle-body">' + sections + '</div></div>';
        }

        function renderSection(section) {
            const rows = (section.fields || []).map((field) => {
                const value = field.filled ? field.value : '—';
                const valueClass = field.filled ? 'field-value' : 'field-value empty';
                return '<div class="field-row">' +
                    '<div class="field-label">' + escapeHtml(field.label) + '</div>' +
                    '<div class="' + valueClass + '">' + escapeHtml(value) + '</div></div>';
            }).join('');

            return '<div class="section">' +
                '<div class="section-title">' + escapeHtml(section.title || '') + '</div>' +
                rows + '</div>';
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, (ch) => ({
                '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
            }[ch]));
        }
    </script>
</body>
</html>
