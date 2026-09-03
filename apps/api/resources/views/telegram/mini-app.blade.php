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
            --ok: #8fd694;
            --draft: #f5b942;
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
        .card-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 12px;
        }
        .card-title {
            color: var(--muted);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }
        .badge {
            font-size: 11px;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            padding: 4px 8px;
            border-radius: 999px;
            border: 1px solid var(--line);
            color: var(--muted);
            white-space: nowrap;
        }
        .badge.saved { color: var(--ok); border-color: rgba(143, 214, 148, 0.25); }
        .badge.draft { color: var(--draft); border-color: rgba(245, 185, 66, 0.25); }
        .field-row {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            padding: 10px 0;
            border-top: 1px solid var(--line);
            font-size: 15px;
        }
        .field-row:first-of-type { border-top: 0; padding-top: 0; }
        .field-label { color: var(--muted); flex: 1; }
        .field-value {
            text-align: right;
            flex: 1;
            word-break: break-word;
        }
        .field-value.empty { color: rgba(183, 173, 160, 0.55); }
        .work {
            padding: 10px 0;
            border-top: 1px solid var(--line);
            font-size: 15px;
            line-height: 1.4;
        }
        .work:first-of-type { border-top: 0; padding-top: 0; }
        .empty-hint {
            color: var(--muted);
            font-size: 14px;
            line-height: 1.45;
            margin: 0;
        }
        .footer-hint {
            margin-top: 18px;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.45;
        }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="mark">AD</div>
        <h1 id="title">AutoDoctor</h1>
        <p class="lead" id="lead">Загружаем…</p>
        <div id="cards"></div>
        <p class="footer-hint">Пустые поля можно дописать боту в чате. Запись в базу — только через кнопку «Записать».</p>
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
            root.innerHTML = '';

            if (data.vehicle_card) {
                root.insertAdjacentHTML('beforeend', renderVehicleCard(data.vehicle_card));
            }
            if (data.works_journal) {
                root.insertAdjacentHTML('beforeend', renderWorksJournal(data.works_journal));
            }
        }).catch(() => {
            document.getElementById('lead').textContent = 'Не удалось загрузить данные.';
        });

        function renderVehicleCard(card) {
            const badgeClass = card.status === 'saved'
                ? 'badge saved'
                : (card.status === 'draft' ? 'badge draft' : 'badge');
            const rows = (card.fields || []).map((field) => {
                const value = field.filled ? field.value : '—';
                const valueClass = field.filled ? 'field-value' : 'field-value empty';
                return '<div class="field-row">' +
                    '<div class="field-label">' + escapeHtml(field.label) + '</div>' +
                    '<div class="' + valueClass + '">' + escapeHtml(value) + '</div>' +
                    '</div>';
            }).join('');

            return '<div class="card">' +
                '<div class="card-head">' +
                '<div class="card-title">Карточка авто</div>' +
                '<div class="' + badgeClass + '">' + escapeHtml(card.status_label || '') + '</div>' +
                '</div>' + rows + '</div>';
        }

        function renderWorksJournal(journal) {
            const items = journal.items || [];
            if (!items.length) {
                return '<div class="card">' +
                    '<div class="card-title">Журнал работ</div>' +
                    '<p class="empty-hint" style="margin-top:12px">' +
                    escapeHtml(journal.empty_hint || 'Пока нет записей.') +
                    '</p></div>';
            }

            const rows = items.map((item) => {
                return '<div class="work">' + escapeHtml(item.detail || item.title || 'Работа') + '</div>';
            }).join('');

            return '<div class="card"><div class="card-title">Журнал работ</div>' + rows + '</div>';
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, (ch) => ({
                '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
            }[ch]));
        }
    </script>
</body>
</html>
