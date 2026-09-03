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
            --ai: #7cb8ff;
            --line: rgba(245, 240, 232, 0.08);
            --ok: #79c784;
            --warn: #f5b942;
            --bad: #f07474;
        }
        * { box-sizing: border-box; }
        html, body {
            margin: 0;
            height: 100%;
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 14px;
        }
        .app {
            height: 100%;
            display: flex;
            flex-direction: column;
            max-width: 420px;
            margin: 0 auto;
        }
        .topbar {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 12px;
            border-bottom: 1px solid var(--line);
            background: var(--bg);
        }
        .garage-btn {
            flex: 1;
            min-width: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 10px;
            border-radius: 10px;
            border: 1px solid var(--line);
            background: var(--card);
            color: inherit;
            cursor: pointer;
            text-align: left;
        }
        .garage-kicker {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
        }
        .garage-title {
            font-size: 14px;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .garage-sub {
            font-size: 11px;
            color: var(--muted);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            border: 1px solid var(--line);
            background: var(--card);
            color: var(--muted);
            display: grid;
            place-items: center;
            font-size: 12px;
            font-weight: 600;
            flex-shrink: 0;
        }
        .main {
            flex: 1;
            overflow: auto;
            padding: 12px;
        }
        .panel { display: none; }
        .panel.active { display: block; }
        .hint {
            color: var(--muted);
            font-size: 12px;
            line-height: 1.4;
            margin: 0 0 10px;
        }
        .row {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 0;
            border-top: 1px solid var(--line);
        }
        .row:first-child { border-top: 0; }
        .row-label { flex: 1; min-width: 0; font-size: 13px; }
        .row-meta { font-size: 11px; color: var(--muted); margin-top: 2px; }
        .row-value {
            text-align: right;
            font-size: 12px;
            color: var(--muted);
            max-width: 45%;
        }
        .bar {
            width: 52px;
            height: 6px;
            border-radius: 999px;
            background: rgba(255,255,255,0.08);
            overflow: hidden;
            flex-shrink: 0;
        }
        .bar > span {
            display: block;
            height: 100%;
            border-radius: inherit;
        }
        .bar.ok > span { background: var(--ok); width: 35%; }
        .bar.soon > span { background: var(--warn); width: 65%; }
        .bar.overdue > span { background: var(--bad); width: 90%; }
        .bar.unknown > span { background: rgba(157,148,136,0.35); width: 18%; }
        .tone-overdue { color: var(--bad); }
        .tone-soon { color: var(--warn); }
        .tone-unknown { color: var(--muted); }
        .agent-hero {
            background: linear-gradient(135deg, rgba(124,184,255,0.18), rgba(245,185,66,0.12));
            border: 1px solid rgba(124,184,255,0.25);
            border-radius: 14px;
            padding: 14px;
            margin-bottom: 12px;
        }
        .agent-hero-top {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .ai-logo {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            background: rgba(124,184,255,0.2);
            color: var(--ai);
            display: grid;
            place-items: center;
            font-weight: 800;
            font-size: 13px;
        }
        .agent-tokens {
            font-size: 22px;
            font-weight: 700;
            line-height: 1.1;
        }
        .agent-tokens-label {
            font-size: 11px;
            color: var(--muted);
        }
        .setting-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 9px 0;
            border-top: 1px solid var(--line);
            font-size: 13px;
        }
        .setting-row:first-of-type { border-top: 0; }
        .setting-label { color: var(--muted); }
        .setting-value { text-align: right; max-width: 55%; }
        .analytics-list { margin-top: 8px; }
        .analytics-point {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-top: 1px solid var(--line);
            font-size: 13px;
        }
        .bottom-nav {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 4px;
            padding: 8px 8px calc(8px + env(safe-area-inset-bottom));
            border-top: 1px solid var(--line);
            background: var(--bg);
        }
        .nav-btn {
            border: 0;
            background: transparent;
            color: var(--muted);
            border-radius: 10px;
            padding: 6px 4px;
            font-size: 10px;
            cursor: pointer;
        }
        .nav-btn.active { color: var(--text); background: rgba(255,255,255,0.05); }
        .nav-btn-agent {
            background: rgba(124,184,255,0.12);
            border: 1px solid rgba(124,184,255,0.28);
            color: var(--ai);
        }
        .nav-btn-agent.active {
            background: rgba(124,184,255,0.22);
            color: #dbeaff;
        }
        .nav-icon { display: block; font-size: 15px; line-height: 1.2; margin-bottom: 2px; }
        .nav-agent-tokens {
            display: block;
            font-size: 10px;
            font-weight: 700;
            margin-top: 2px;
        }
        .sheet-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.55);
            display: none;
            z-index: 20;
        }
        .sheet-backdrop.open { display: block; }
        .sheet {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            max-height: 78vh;
            background: var(--card);
            border-radius: 16px 16px 0 0;
            transform: translateY(100%);
            transition: transform 0.2s ease;
            z-index: 21;
            overflow: auto;
            padding: 12px 14px calc(16px + env(safe-area-inset-bottom));
        }
        .sheet.open { transform: translateY(0); }
        .sheet-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .sheet-title { font-size: 16px; font-weight: 600; }
        .sheet-close {
            border: 0;
            background: transparent;
            color: var(--muted);
            font-size: 22px;
            cursor: pointer;
        }
        .vehicle-pick {
            width: 100%;
            text-align: left;
            border: 1px solid var(--line);
            background: var(--bg);
            color: inherit;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 8px;
            cursor: pointer;
        }
        .vehicle-pick.selected { border-color: rgba(245,185,66,0.45); }
        .passport {
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px solid var(--line);
        }
        .passport-section { margin-top: 10px; }
        .passport-title {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            margin-bottom: 4px;
        }
        .field-row {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            padding: 6px 0;
            font-size: 12px;
        }
        .field-value.empty { color: rgba(157,148,136,0.55); }
    </style>
</head>
<body>
    <div class="app">
        <header class="topbar">
            <button class="garage-btn" id="garage-open" type="button">
                <div style="min-width:0;flex:1">
                    <div class="garage-kicker" id="garage-kicker">Гараж</div>
                    <div class="garage-title" id="garage-title">Автомобиль</div>
                    <div class="garage-sub" id="garage-sub"></div>
                </div>
                <span>▾</span>
            </button>
            <div class="avatar" id="user-avatar" title="Профиль">AD</div>
        </header>

        <main class="main">
            <p class="hint" id="subtitle">Загружаем…</p>

            <section class="panel active" id="panel-state"></section>
            <section class="panel" id="panel-roadmap"></section>
            <section class="panel" id="panel-analytics"></section>
            <section class="panel" id="panel-agent"></section>
        </main>

        <nav class="bottom-nav">
            <button class="nav-btn active" type="button" data-tab="state">
                <span class="nav-icon">◎</span>Состояние
            </button>
            <button class="nav-btn" type="button" data-tab="roadmap">
                <span class="nav-icon">→</span>Roadmap
            </button>
            <button class="nav-btn" type="button" data-tab="analytics">
                <span class="nav-icon">⌁</span>Аналитика
            </button>
            <button class="nav-btn nav-btn-agent" type="button" data-tab="agent" id="nav-agent">
                <span class="nav-icon ai-logo" style="width:auto;height:auto;background:transparent;border:0;font-size:12px;">AI</span>
                <span class="nav-agent-tokens" id="nav-tokens">—</span>
                <span>Агент</span>
            </button>
        </nav>
    </div>

    <div class="sheet-backdrop" id="sheet-backdrop"></div>
    <div class="sheet" id="garage-sheet">
        <div class="sheet-head">
            <div class="sheet-title">Гараж</div>
            <button class="sheet-close" id="garage-close" type="button">×</button>
        </div>
        <div id="garage-list"></div>
    </div>

    <script>
        const tg = window.Telegram && window.Telegram.WebApp;
        if (tg) {
            tg.ready();
            tg.expand();
            document.body.style.background = tg.themeParams.bg_color || '';
        }

        let appState = { vehicles: [], agent: {}, activeVehicleKey: null, tab: 'state' };

        function vehicleKey(vehicle, index) {
            if (vehicle.id) {
                return String(vehicle.id);
            }
            if (vehicle.status === 'placeholder') {
                return 'placeholder';
            }
            if (vehicle.status === 'draft') {
                return 'draft';
            }
            return 'slot-' + index;
        }

        function activeVehicle() {
            const list = appState.vehicles || [];
            if (!list.length) return null;
            const found = list.find((v, i) => vehicleKey(v, i) === appState.activeVehicleKey);
            return found || list[0];
        }

        function activeIndex() {
            const list = appState.vehicles || [];
            const idx = list.findIndex((v, i) => vehicleKey(v, i) === appState.activeVehicleKey);
            return idx >= 0 ? idx : 0;
        }

        function renderHeader() {
            const vehicle = activeVehicle();
            const kicker = document.getElementById('garage-kicker');
            const title = document.getElementById('garage-title');
            const sub = document.getElementById('garage-sub');
            if (!vehicle || vehicle.status === 'placeholder') {
                kicker.textContent = 'Гараж';
                title.textContent = 'Автомобиль';
                sub.textContent = 'Расскажите боту про машину';
                return;
            }
            kicker.textContent = vehicle.status === 'draft' ? 'Черновик' : 'Авто';
            title.textContent = vehicle.title || 'Автомобиль';
            sub.textContent = vehicle.summary || '';
        }

        function renderGarageSheet() {
            const root = document.getElementById('garage-list');
            root.innerHTML = '';
            (appState.vehicles || []).forEach((vehicle, index) => {
                const key = vehicleKey(vehicle, index);
                const btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'vehicle-pick' + (key === appState.activeVehicleKey ? ' selected' : '');
                btn.innerHTML = '<div style="font-weight:600">' + escapeHtml(vehicle.title) + '</div>' +
                    '<div style="font-size:12px;color:var(--muted)">' + escapeHtml(vehicle.summary || 'Нет данных') + '</div>';
                btn.addEventListener('click', () => {
                    appState.activeVehicleKey = key;
                    localStorage.setItem('ad_active_vehicle', key);
                    closeGarage();
                    renderAll();
                });
                root.appendChild(btn);

                const passport = document.createElement('div');
                passport.className = 'passport';
                (vehicle.sections || []).forEach((section) => {
                    const block = document.createElement('div');
                    block.className = 'passport-section';
                    block.innerHTML = '<div class="passport-title">' + escapeHtml(section.title) + '</div>' +
                        (section.fields || []).map((field) => {
                            const value = field.filled ? field.value : '—';
                            const cls = field.filled ? 'field-value' : 'field-value empty';
                            return '<div class="field-row"><span>' + escapeHtml(field.label) + '</span>' +
                                '<span class="' + cls + '">' + escapeHtml(value) + '</span></div>';
                        }).join('');
                    passport.appendChild(block);
                });
                btn.after(passport);
            });
        }

        function renderState() {
            const vehicle = activeVehicle();
            const items = vehicle?.tabs?.state || [];
            const root = document.getElementById('panel-state');
            if (!items.length) {
                root.innerHTML = '<p class="hint">Нет данных по узлам. Расскажите боту про обслуживание.</p>';
                return;
            }
            root.innerHTML = items.map((item) => {
                const status = item.status || 'unknown';
                const detail = item.filled ? item.detail : '—';
                const wear = item.wear_percent != null ? (' · износ ' + item.wear_percent + '%') : '';
                return '<div class="row">' +
                    '<div class="bar ' + status + '"><span></span></div>' +
                    '<div class="row-label">' + escapeHtml(item.label) +
                    '<div class="row-meta">' + escapeHtml(detail + wear) + '</div></div></div>';
            }).join('');
        }

        function renderRoadmap() {
            const vehicle = activeVehicle();
            const items = vehicle?.tabs?.roadmap || [];
            const root = document.getElementById('panel-roadmap');
            if (!items.length) {
                root.innerHTML = '<p class="hint">Пока нет ближайших работ — всё спокойно или данных мало.</p>';
                return;
            }
            root.innerHTML = items.map((item) => {
                const tone = item.tone || 'soon';
                return '<div class="row">' +
                    '<div class="row-label">' + escapeHtml(item.label) + '</div>' +
                    '<div class="row-value tone-' + tone + '">' + escapeHtml(item.detail || '—') + '</div></div>';
            }).join('');
        }

        function renderAnalytics() {
            const vehicle = activeVehicle();
            const analytics = vehicle?.tabs?.analytics || { points: [], hint: null };
            const root = document.getElementById('panel-analytics');
            if (analytics.hint && !(analytics.points || []).length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(analytics.hint) + '</p>';
                return;
            }
            const rows = (analytics.points || []).slice().reverse().map((point) => {
                return '<div class="analytics-point"><span>' + escapeHtml(point.date || '—') + '</span>' +
                    '<span>' + escapeHtml(formatMileage(point.mileage, point.unit)) + '</span></div>';
            }).join('');
            root.innerHTML = (analytics.hint ? '<p class="hint">' + escapeHtml(analytics.hint) + '</p>' : '') +
                '<div class="analytics-list">' + rows + '</div>';
        }

        function renderAgent() {
            const agent = appState.agent || {};
            const root = document.getElementById('panel-agent');
            const settings = (agent.settings || []).map((row) => {
                const value = row.value ? row.value : '—';
                const cls = row.value ? 'setting-value' : 'setting-value field-value empty';
                return '<div class="setting-row"><span class="setting-label">' + escapeHtml(row.label) +
                    '</span><span class="' + cls + '">' + escapeHtml(value) + '</span></div>';
            }).join('');
            root.innerHTML =
                '<div class="agent-hero">' +
                '<div class="agent-hero-top">' +
                '<div class="ai-logo">AI</div>' +
                '<div><div class="agent-tokens">' + escapeHtml(agent.tokens_label || '—') + '</div>' +
                '<div class="agent-tokens-label">токенов на ответы</div></div></div></div>' +
                settings +
                (agent.hint ? '<p class="hint" style="margin-top:12px">' + escapeHtml(agent.hint) + '</p>' : '');
        }

        function renderNavTokens() {
            document.getElementById('nav-tokens').textContent = (appState.agent && appState.agent.tokens_label) || '—';
        }

        function renderTab() {
            document.querySelectorAll('.panel').forEach((el) => el.classList.remove('active'));
            document.getElementById('panel-' + appState.tab).classList.add('active');
            document.querySelectorAll('.nav-btn').forEach((btn) => {
                btn.classList.toggle('active', btn.dataset.tab === appState.tab);
            });
        }

        function renderAll() {
            renderHeader();
            renderGarageSheet();
            renderState();
            renderRoadmap();
            renderAnalytics();
            renderAgent();
            renderNavTokens();
            renderTab();
        }

        function openGarage() {
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('garage-sheet').classList.add('open');
        }
        function closeGarage() {
            document.getElementById('sheet-backdrop').classList.remove('open');
            document.getElementById('garage-sheet').classList.remove('open');
        }

        document.getElementById('garage-open').addEventListener('click', openGarage);
        document.getElementById('garage-close').addEventListener('click', closeGarage);
        document.getElementById('sheet-backdrop').addEventListener('click', closeGarage);
        document.querySelectorAll('.nav-btn').forEach((btn) => {
            btn.addEventListener('click', () => {
                appState.tab = btn.dataset.tab;
                localStorage.setItem('ad_active_tab', appState.tab);
                renderTab();
            });
        });

        function formatMileage(value, unit) {
            if (value == null) return '—';
            const suffix = unit === 'mi' ? ' mi' : ' км';
            return Number(value).toLocaleString('ru-RU') + suffix;
        }

        function escapeHtml(value) {
            return String(value || '').replace(/[&<>"']/g, (ch) => ({
                '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
            }[ch]));
        }

        const initData = tg && tg.initData ? tg.initData : '';
        fetch(@json(url('/telegram/app/state')), {
            headers: { 'X-Telegram-Init-Data': initData, 'Accept': 'application/json' }
        }).then(async (response) => {
            const data = await response.json();
            document.getElementById('subtitle').textContent = data.subtitle || data.error || '';
            if (data.user && data.user.initial) {
                document.getElementById('user-avatar').textContent = data.user.initial;
            }
            appState.vehicles = data.vehicles || [];
            appState.agent = data.agent || {};
            const storedVehicle = localStorage.getItem('ad_active_vehicle');
            const defaultKey = data.active_vehicle_id != null
                ? String(data.active_vehicle_id)
                : vehicleKey(appState.vehicles[0], 0);
            const keys = appState.vehicles.map((v, i) => vehicleKey(v, i));
            appState.activeVehicleKey = keys.includes(storedVehicle) ? storedVehicle : defaultKey;
            appState.tab = localStorage.getItem('ad_active_tab') || 'state';
            renderAll();
        }).catch(() => {
            document.getElementById('subtitle').textContent = 'Не удалось загрузить данные.';
        });
    </script>
</body>
</html>
