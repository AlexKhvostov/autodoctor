<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>AutoDoctor</title>
    <script src="https://telegram.org/js/telegram-web-app.js"></script>
    <style>
        :root {
            color-scheme: light;
            --bg: #eef3fb;
            --bg-soft: #f7faff;
            --card: #ffffff;
            --text: #152033;
            --muted: #6b7a90;
            --line: rgba(21, 32, 51, 0.08);
            --primary: #1ecad3;
            --primary-deep: #0aa9b3;
            --primary-soft: rgba(30, 202, 211, 0.12);
            --ai: #3b82f6;
            --ai-soft: rgba(59, 130, 246, 0.1);
            --ok: #22b573;
            --warn: #f59e0b;
            --bad: #ef4444;
            --shadow: 0 1px 3px rgba(21, 32, 51, 0.06), 0 4px 14px rgba(21, 32, 51, 0.04);
        }
        * { box-sizing: border-box; }
        html, body {
            margin: 0;
            height: 100%;
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 14px;
            -webkit-font-smoothing: antialiased;
        }
        .app {
            height: 100%;
            display: flex;
            flex-direction: column;
            max-width: 420px;
            margin: 0 auto;
            background: linear-gradient(180deg, #f3f8ff 0%, var(--bg) 120px);
        }
        .topbar {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 12px 8px;
        }
        .garage-btn {
            flex: 1;
            min-width: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 10px;
            border-radius: 12px;
            border: 1px solid var(--line);
            background: var(--card);
            box-shadow: var(--shadow);
            color: inherit;
            cursor: pointer;
            text-align: left;
        }
        .garage-kicker {
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--primary-deep);
            font-weight: 700;
        }
        .garage-title {
            font-size: 14px;
            font-weight: 700;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .garage-sub {
            font-size: 10px;
            color: var(--muted);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .avatar {
            width: 34px;
            height: 34px;
            border-radius: 50%;
            border: 1px solid var(--line);
            background: var(--card);
            color: var(--primary-deep);
            display: grid;
            place-items: center;
            font-size: 11px;
            font-weight: 700;
            flex-shrink: 0;
            box-shadow: var(--shadow);
        }
        .main {
            flex: 1;
            overflow: auto;
            padding: 0 12px 12px;
        }
        .panel { display: none; }
        .panel.active { display: block; }
        .hint {
            color: var(--muted);
            font-size: 11px;
            line-height: 1.4;
            margin: 0 0 8px;
        }
        .section-title {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--muted);
            font-weight: 700;
            margin: 8px 0 6px;
        }
        .state-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 6px;
        }
        .unit-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 7px 8px 6px;
            box-shadow: var(--shadow);
            min-height: 0;
        }
        .unit-card.status-overdue { border-color: rgba(239, 68, 68, 0.35); }
        .unit-card.status-soon { border-color: rgba(245, 158, 11, 0.35); }
        .unit-name {
            font-size: 12px;
            font-weight: 700;
            line-height: 1.15;
            margin-bottom: 5px;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .unit-bar-row {
            display: flex;
            align-items: center;
            gap: 5px;
            margin-bottom: 3px;
        }
        .unit-bar {
            flex: 1;
            height: 5px;
            border-radius: 999px;
            background: rgba(21, 32, 51, 0.08);
            overflow: hidden;
        }
        .unit-bar > span {
            display: block;
            height: 100%;
            border-radius: inherit;
        }
        .unit-pct {
            font-size: 10px;
            font-weight: 800;
            min-width: 28px;
            text-align: right;
        }
        .unit-meta, .unit-fact {
            font-size: 9px;
            line-height: 1.3;
            color: var(--muted);
        }
        .unit-fact strong { color: var(--text); font-weight: 600; }
        .road-list { display: flex; flex-direction: column; gap: 4px; }
        .road-item {
            display: flex;
            align-items: flex-start;
            gap: 7px;
            padding: 7px 8px;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            box-shadow: var(--shadow);
        }
        .road-item.required { border-left: 2px solid var(--warn); }
        .road-item.recommended { border-left: 2px solid rgba(107, 122, 144, 0.35); opacity: 0.95; }
        .road-icons {
            display: flex;
            flex-direction: column;
            gap: 2px;
            flex-shrink: 0;
            width: 18px;
            align-items: center;
            padding-top: 1px;
        }
        .ico {
            width: 16px;
            height: 16px;
            border-radius: 5px;
            display: grid;
            place-items: center;
            font-size: 9px;
            line-height: 1;
        }
        .ico-tier-reg { background: rgba(245, 158, 11, 0.15); color: #b45309; }
        .ico-tier-rec { background: rgba(107, 122, 144, 0.12); color: var(--muted); }
        .ico-urg-overdue { background: rgba(239, 68, 68, 0.14); color: var(--bad); }
        .ico-urg-soon { background: rgba(245, 158, 11, 0.14); color: var(--warn); }
        .ico-urg-soft { background: rgba(30, 202, 211, 0.14); color: var(--primary-deep); }
        .ico-urg-unknown { background: rgba(107, 122, 144, 0.12); color: var(--muted); }
        .road-body { flex: 1; min-width: 0; }
        .road-label { font-size: 12px; font-weight: 700; line-height: 1.2; }
        .road-detail { font-size: 10px; color: var(--muted); margin-top: 1px; }
        .road-now {
            text-align: center;
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: 0.1em;
            color: var(--primary-deep);
            font-weight: 800;
            margin: 4px 0 6px;
        }
        .agent-card {
            border-radius: 14px;
            padding: 10px 10px 8px;
            background: linear-gradient(135deg, rgba(30,202,211,0.14), rgba(59,130,246,0.08)), var(--card);
            border: 1px solid rgba(30, 202, 211, 0.28);
            box-shadow: var(--shadow);
            margin-bottom: 10px;
        }
        .agent-card.status-low, .agent-card.status-empty {
            border-color: rgba(245, 158, 11, 0.45);
            background: linear-gradient(135deg, rgba(245,158,11,0.12), rgba(59,130,246,0.06)), var(--card);
        }
        .agent-top { display: flex; gap: 10px; align-items: flex-start; }
        .agent-avatar {
            width: 46px;
            height: 46px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid rgba(255,255,255,0.9);
            box-shadow: 0 2px 8px rgba(30, 202, 211, 0.25);
            flex-shrink: 0;
            background: var(--primary-soft);
        }
        .agent-title { font-size: 15px; font-weight: 800; line-height: 1.1; letter-spacing: -0.02em; }
        .agent-subtitle { font-size: 11px; color: var(--muted); font-weight: 600; margin-top: 1px; }
        .agent-tokens-row {
            display: flex;
            align-items: center;
            gap: 4px;
            margin-top: 5px;
            flex-wrap: wrap;
        }
        .agent-token-val {
            font-size: 13px;
            font-weight: 800;
            color: var(--primary-deep);
        }
        .agent-token-meta { font-size: 10px; color: var(--muted); font-weight: 600; }
        .agent-intro {
            font-size: 11px;
            line-height: 1.35;
            color: var(--muted);
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px solid var(--line);
        }
        .settings-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 4px 10px;
            box-shadow: var(--shadow);
        }
        .setting-row {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            padding: 7px 0;
            border-top: 1px solid var(--line);
            font-size: 12px;
        }
        .setting-row:first-child { border-top: 0; }
        .setting-label { color: var(--muted); font-size: 11px; }
        .setting-value { text-align: right; max-width: 55%; font-size: 11px; font-weight: 600; }
        .analytics-list { margin-top: 4px; }
        .analytics-point {
            display: flex;
            justify-content: space-between;
            padding: 7px 8px;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 8px;
            margin-bottom: 4px;
            font-size: 12px;
            box-shadow: var(--shadow);
        }
        .bottom-nav {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 4px;
            padding: 6px 8px calc(6px + env(safe-area-inset-bottom));
            background: rgba(255,255,255,0.92);
            border-top: 1px solid var(--line);
            backdrop-filter: blur(8px);
        }
        .nav-btn {
            border: 0;
            background: transparent;
            color: var(--muted);
            border-radius: 10px;
            padding: 5px 3px;
            font-size: 9px;
            font-weight: 600;
            cursor: pointer;
        }
        .nav-btn.active { color: var(--text); background: var(--primary-soft); }
        .nav-btn-agent {
            background: linear-gradient(135deg, rgba(30,202,211,0.18), rgba(59,130,246,0.12));
            border: 1px solid rgba(30, 202, 211, 0.3);
            color: var(--primary-deep);
        }
        .nav-btn-agent.active { background: linear-gradient(135deg, rgba(30,202,211,0.28), rgba(59,130,246,0.18)); }
        .nav-icon { display: block; font-size: 14px; line-height: 1.1; margin-bottom: 1px; }
        .nav-agent-tokens { display: block; font-size: 9px; font-weight: 800; margin-top: 1px; }
        .sheet-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(21, 32, 51, 0.35);
            display: none;
            z-index: 20;
        }
        .sheet-backdrop.open { display: block; }
        .sheet {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            max-height: 82vh;
            background: var(--bg-soft);
            border-radius: 16px 16px 0 0;
            transform: translateY(100%);
            transition: transform 0.2s ease;
            z-index: 21;
            overflow: auto;
            padding: 12px 14px calc(16px + env(safe-area-inset-bottom));
            box-shadow: 0 -8px 30px rgba(21, 32, 51, 0.12);
        }
        .sheet.open { transform: translateY(0); }
        .sheet-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            gap: 8px;
        }
        .sheet-title { font-size: 16px; font-weight: 800; }
        .sheet-close, .sheet-back {
            border: 0;
            background: transparent;
            color: var(--muted);
            font-size: 22px;
            cursor: pointer;
            line-height: 1;
        }
        .sheet-back { font-size: 13px; color: var(--primary-deep); font-weight: 700; }
        .garage-hint { font-size: 11px; color: var(--muted); line-height: 1.4; margin-bottom: 10px; }
        .vehicle-tile {
            border: 1px solid var(--line);
            background: var(--card);
            border-radius: 12px;
            padding: 10px;
            margin-bottom: 8px;
            box-shadow: var(--shadow);
        }
        .vehicle-tile.active { border-color: rgba(30, 202, 211, 0.45); background: linear-gradient(135deg, rgba(30,202,211,0.08), #fff); }
        .vehicle-tile-head { display: flex; gap: 9px; align-items: flex-start; }
        .vehicle-icon {
            width: 38px;
            height: 38px;
            border-radius: 10px;
            background: var(--primary-soft);
            display: grid;
            place-items: center;
            font-size: 18px;
            flex-shrink: 0;
        }
        .vehicle-tile-title { font-weight: 700; font-size: 13px; }
        .vehicle-tile-sub { font-size: 10px; color: var(--muted); margin-top: 1px; }
        .vehicle-badge {
            display: inline-block;
            margin-top: 5px;
            font-size: 9px;
            padding: 2px 7px;
            border-radius: 999px;
            background: var(--primary-soft);
            color: var(--primary-deep);
            font-weight: 700;
        }
        .vehicle-actions { display: flex; gap: 6px; margin-top: 8px; }
        .btn {
            flex: 1;
            border: 0;
            border-radius: 8px;
            padding: 7px 8px;
            font-size: 11px;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-ghost { background: rgba(21,32,51,0.05); color: var(--text); }
        .btn-primary {
            background: var(--primary-soft);
            color: var(--primary-deep);
            border: 1px solid rgba(30, 202, 211, 0.35);
        }
        .btn-primary:disabled { opacity: 0.55; cursor: default; }
        .btn-add {
            width: 100%;
            margin-top: 2px;
            background: var(--card);
            border: 1px dashed rgba(21,32,51,0.15);
            color: var(--muted);
            box-shadow: var(--shadow);
        }
        .btn-add.locked { opacity: 0.6; cursor: default; }
        .passport-section { margin-top: 10px; }
        .passport-title {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            font-weight: 700;
            margin-bottom: 4px;
        }
        .field-row {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            padding: 5px 0;
            font-size: 11px;
            border-top: 1px solid var(--line);
        }
        .field-row:first-of-type { border-top: 0; }
        .field-value.empty { color: rgba(107, 122, 144, 0.65); }
    </style>
</head>
<body>
    <div class="app">
        <header class="topbar">
            <button class="garage-btn" id="garage-open" type="button">
                <div style="min-width:0;flex:1">
                    <div class="garage-kicker" id="garage-kicker">Гараж</div>
                    <div class="garage-title" id="garage-title">Выберите автомобиль</div>
                    <div class="garage-sub" id="garage-sub"></div>
                </div>
                <span style="color:var(--muted);font-size:11px">▾</span>
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
                <span class="nav-icon">✦</span>
                <span class="nav-agent-tokens" id="nav-tokens">—</span>
                <span>AI</span>
            </button>
        </nav>
    </div>

    <div class="sheet-backdrop" id="sheet-backdrop"></div>
    <div class="sheet" id="garage-sheet">
        <div class="sheet-head">
            <button class="sheet-back" id="garage-back" type="button" style="display:none">← Назад</button>
            <div class="sheet-title" id="sheet-title">Гараж</div>
            <button class="sheet-close" id="garage-close" type="button">×</button>
        </div>
        <div id="garage-content"></div>
    </div>

    <script>
        const tg = window.Telegram && window.Telegram.WebApp;
        if (tg) {
            tg.ready();
            tg.expand();
            if (tg.setHeaderColor) tg.setHeaderColor('#eef3fb');
            if (tg.setBackgroundColor) tg.setBackgroundColor('#eef3fb');
        }

        let appState = {
            vehicles: [], agent: {}, garage: {},
            activeVehicleKey: null, tab: 'state',
            garageView: 'list', garageDetailKey: null,
        };

        function vehicleKey(vehicle, index) {
            if (vehicle.id) return String(vehicle.id);
            if (vehicle.status === 'placeholder') return 'placeholder';
            if (vehicle.status === 'draft') return 'draft';
            return 'slot-' + index;
        }

        function activeVehicle() {
            const list = appState.vehicles || [];
            if (!list.length) return null;
            return list.find((v, i) => vehicleKey(v, i) === appState.activeVehicleKey) || list[0];
        }

        function vehicleByKey(key) {
            return (appState.vehicles || []).find((v, i) => vehicleKey(v, i) === key) || null;
        }

        function statusColor(status) {
            if (status === 'overdue') return 'var(--bad)';
            if (status === 'soon') return 'var(--warn)';
            if (status === 'unknown') return 'var(--muted)';
            return 'var(--ok)';
        }

        function renderHeader() {
            const vehicle = activeVehicle();
            document.getElementById('garage-kicker').textContent = 'Гараж';
            const title = document.getElementById('garage-title');
            const sub = document.getElementById('garage-sub');
            if (!vehicle || vehicle.status === 'placeholder') {
                title.textContent = 'Выберите автомобиль';
                sub.textContent = 'Нажмите — откроется гараж';
                return;
            }
            title.textContent = vehicle.title || 'Автомобиль';
            sub.textContent = (vehicle.status === 'draft' ? 'черновик · ' : '') +
                (vehicle.summary || 'активно для AI');
        }

        function renderGarageSheet() {
            const back = document.getElementById('garage-back');
            const title = document.getElementById('sheet-title');
            const root = document.getElementById('garage-content');
            const garage = appState.garage || {};

            if (appState.garageView === 'detail' && appState.garageDetailKey) {
                back.style.display = 'block';
                title.textContent = 'Паспорт';
                root.innerHTML = renderVehiclePassport(appState.garageDetailKey);
                return;
            }

            back.style.display = 'none';
            title.textContent = 'Гараж';
            let html = '<p class="garage-hint">Выберите авто для AI, состояния и roadmap.</p>';

            (appState.vehicles || []).forEach((vehicle, index) => {
                const key = vehicleKey(vehicle, index);
                if (vehicle.status === 'placeholder') {
                    html += '<div class="vehicle-tile"><div class="vehicle-tile-head">' +
                        '<div class="vehicle-icon">＋</div><div><div class="vehicle-tile-title">Пока нет автомобиля</div>' +
                        '<div class="vehicle-tile-sub">Расскажите боту про машину</div></div></div></div>';
                    return;
                }
                const isActive = key === appState.activeVehicleKey;
                html += '<div class="vehicle-tile' + (isActive ? ' active' : '') + '">' +
                    '<div class="vehicle-tile-head"><div class="vehicle-icon">🚗</div><div style="min-width:0;flex:1">' +
                    '<div class="vehicle-tile-title">' + escapeHtml(vehicle.title) + '</div>' +
                    '<div class="vehicle-tile-sub">' + escapeHtml(vehicle.summary || 'Нет данных') + '</div>' +
                    (isActive ? '<span class="vehicle-badge">' + escapeHtml(garage.active_label || 'Активна для AI') + '</span>' : '') +
                    '</div></div><div class="vehicle-actions">' +
                    '<button class="btn btn-ghost" type="button" data-detail="' + escapeHtml(key) + '">' +
                    escapeHtml(garage.detail_label || 'Подробнее') + '</button>' +
                    '<button class="btn btn-primary" type="button" data-select="' + escapeHtml(key) + '"' +
                    (isActive ? ' disabled' : '') + '>' +
                    (isActive ? '✓ Выбрана' : escapeHtml(garage.select_label || 'Для AI')) +
                    '</button></div></div>';
            });

            html += garage.can_add
                ? '<button class="btn btn-add" type="button" id="garage-add">+ Добавить автомобиль</button>' +
                  '<p class="garage-hint">' + escapeHtml(garage.add_hint || '') + '</p>'
                : '<button class="btn btn-add locked" type="button" disabled>+ Второй автомобиль — скоро</button>' +
                  '<p class="garage-hint">' + escapeHtml(garage.locked_hint || '') + '</p>';

            root.innerHTML = html;
            root.querySelectorAll('[data-select]').forEach((btn) => {
                btn.addEventListener('click', () => selectVehicle(btn.dataset.select));
            });
            root.querySelectorAll('[data-detail]').forEach((btn) => {
                btn.addEventListener('click', () => openVehicleDetail(btn.dataset.detail));
            });
            const addBtn = document.getElementById('garage-add');
            if (addBtn) addBtn.addEventListener('click', () => { closeGarage(); if (tg && tg.close) tg.close(); });
        }

        function renderVehiclePassport(key) {
            const vehicle = vehicleByKey(key);
            if (!vehicle) return '<p class="hint">Автомобиль не найден.</p>';
            let html = '<div class="vehicle-tile-title">' + escapeHtml(vehicle.title) + '</div>' +
                '<div class="vehicle-tile-sub" style="margin-bottom:10px">' + escapeHtml(vehicle.summary || '') + '</div>';
            (vehicle.sections || []).forEach((section) => {
                html += '<div class="passport-section"><div class="passport-title">' + escapeHtml(section.title) + '</div>';
                (section.fields || []).forEach((field) => {
                    const value = field.filled ? field.value : '—';
                    html += '<div class="field-row"><span>' + escapeHtml(field.label) + '</span>' +
                        '<span class="' + (field.filled ? 'field-value' : 'field-value empty') + '">' +
                        escapeHtml(value) + '</span></div>';
                });
                html += '</div>';
            });
            html += '<div class="vehicle-actions"><button class="btn btn-primary" type="button" id="passport-select"' +
                (key === appState.activeVehicleKey ? ' disabled' : '') + '>' +
                (key === appState.activeVehicleKey ? '✓ Активна для AI' : 'Выбрать для AI') + '</button></div>';
            setTimeout(() => {
                const btn = document.getElementById('passport-select');
                if (btn && !btn.disabled) btn.addEventListener('click', () => selectVehicle(key));
            }, 0);
            return html;
        }

        function selectVehicle(key) {
            appState.activeVehicleKey = key;
            localStorage.setItem('ad_active_vehicle', key);
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            closeGarage();
            renderAll();
        }

        function openVehicleDetail(key) {
            appState.garageView = 'detail';
            appState.garageDetailKey = key;
            renderGarageSheet();
        }

        function metricPercent(item) {
            if (item.wear_percent != null) return item.wear_percent;
            if (item.used_percent != null) return item.used_percent;
            return null;
        }

        function metricCaption(item) {
            if (item.wear_percent != null) {
                return 'износ · остаток ' + (item.remaining_percent ?? '—') + '%';
            }
            if (item.used_percent != null) return 'ресурс использован';
            return item.metric_label || 'нет данных';
        }

        function renderState() {
            const items = activeVehicle()?.tabs?.state || [];
            const root = document.getElementById('panel-state');
            if (!items.length) {
                root.innerHTML = '<p class="hint">Нет данных по узлам. Расскажите боту про обслуживание.</p>';
                return;
            }
            root.innerHTML = '<div class="state-grid">' + items.map((item) => {
                const status = item.status || 'unknown';
                const pct = metricPercent(item);
                const color = statusColor(status);
                const barWidth = pct == null ? 8 : Math.max(4, pct);
                const pctLabel = pct == null ? '—' : (pct + '%');
                const last = item.last_service ? escapeHtml(item.last_service) : '—';
                const next = item.next_due ? escapeHtml(item.next_due) : '—';
                return '<article class="unit-card status-' + status + '">' +
                    '<div class="unit-name">' + escapeHtml(item.label) + '</div>' +
                    '<div class="unit-bar-row">' +
                    '<div class="unit-bar"><span style="width:' + barWidth + '%;background:' + color + '"></span></div>' +
                    '<div class="unit-pct" style="color:' + color + '">' + pctLabel + '</div></div>' +
                    '<div class="unit-meta">' + escapeHtml(metricCaption(item)) + '</div>' +
                    '<div class="unit-fact">Было: ' + last + '</div>' +
                    '<div class="unit-fact"><strong>Далее:</strong> ' + next + '</div></article>';
            }).join('') + '</div>';
        }

        function urgencyIcon(tone) {
            if (tone === 'overdue') return '<span class="ico ico-urg-overdue" title="Срочно">!</span>';
            if (tone === 'soon') return '<span class="ico ico-urg-soon" title="Скоро">⏱</span>';
            if (tone === 'unknown') return '<span class="ico ico-urg-unknown" title="Уточнить">?</span>';
            return '<span class="ico ico-urg-soft" title="Можно позже">○</span>';
        }

        function tierIcon(tier) {
            if (tier === 'required') return '<span class="ico ico-tier-reg" title="Регламент">🛡</span>';
            return '<span class="ico ico-tier-rec" title="Рекомендация">✦</span>';
        }

        function renderRoadItem(item, tierClass) {
            return '<div class="road-item ' + tierClass + ' tone-' + (item.tone || 'soft') + '">' +
                '<div class="road-icons">' + tierIcon(tierClass) + urgencyIcon(item.tone) + '</div>' +
                '<div class="road-body"><div class="road-label">' + escapeHtml(item.label) + '</div>' +
                '<div class="road-detail">' + escapeHtml(item.detail || item.due_label || '—') + '</div></div></div>';
        }

        function renderRoadmap() {
            const roadmap = activeVehicle()?.tabs?.roadmap || { required: [], recommended: [], seasonal: [], hint: null };
            const root = document.getElementById('panel-roadmap');
            const required = roadmap.required || [];
            const recommended = [...(roadmap.recommended || []), ...(roadmap.seasonal || [])];
            if (!required.length && !recommended.length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(roadmap.hint || 'Пока нет ближайших работ.') + '</p>';
                return;
            }
            let html = roadmap.hint ? '<p class="hint">' + escapeHtml(roadmap.hint) + '</p>' : '';
            html += '<div class="road-now">● Сегодня</div><div class="road-list">';
            if (required.length) {
                html += '<div class="section-title">Регламент</div>';
                html += required.map((item) => renderRoadItem(item, 'required')).join('');
            }
            if (recommended.length) {
                html += '<div class="section-title">Рекомендации</div>';
                html += recommended.map((item) => renderRoadItem(item, 'recommended')).join('');
            }
            html += '</div>';
            root.innerHTML = html;
        }

        function renderAnalytics() {
            const analytics = activeVehicle()?.tabs?.analytics || { points: [], hint: null };
            const root = document.getElementById('panel-analytics');
            if (analytics.hint && !(analytics.points || []).length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(analytics.hint) + '</p>';
                return;
            }
            const rows = (analytics.points || []).slice().reverse().map((point) =>
                '<div class="analytics-point"><span>' + escapeHtml(point.date || '—') + '</span>' +
                '<span>' + escapeHtml(formatMileage(point.mileage, point.unit)) + '</span></div>'
            ).join('');
            root.innerHTML = (analytics.hint ? '<p class="hint">' + escapeHtml(analytics.hint) + '</p>' : '') +
                '<div class="analytics-list">' + rows + '</div>';
        }

        function renderAgent() {
            const agent = appState.agent || {};
            const root = document.getElementById('panel-agent');
            const statusClass = agent.status && agent.status !== 'ok' ? ' status-' + agent.status : '';
            const avatar = agent.avatar_url
                ? '<img class="agent-avatar" src="' + escapeHtml(agent.avatar_url) + '" alt="AI">'
                : '<div class="agent-avatar"></div>';
            const settings = (agent.settings || []).map((row) => {
                const value = row.value ? row.value : '—';
                return '<div class="setting-row"><span class="setting-label">' + escapeHtml(row.label) +
                    '</span><span class="setting-value' + (row.value ? '' : ' field-value empty') + '">' +
                    escapeHtml(value) + '</span></div>';
            }).join('');

            root.innerHTML =
                '<div class="agent-card' + statusClass + '"><div class="agent-top">' + avatar +
                '<div><div class="agent-title">' + escapeHtml(agent.title || 'AI-ассистент') + '</div>' +
                '<div class="agent-subtitle">' + escapeHtml(agent.subtitle || '') + '</div>' +
                '<div class="agent-tokens-row">' +
                '<span class="agent-token-val">⚡ ' + escapeHtml(agent.tokens_label || '—') + '</span>' +
                (agent.approx_replies_label
                    ? '<span class="agent-token-meta">' + escapeHtml(agent.approx_replies_label) + '</span>'
                    : '') +
                '</div>' +
                (agent.typical_spend_label
                    ? '<div class="agent-token-meta">' + escapeHtml(agent.typical_spend_label) + '</div>'
                    : '') +
                '</div></div>' +
                (agent.intro ? '<div class="agent-intro">' + escapeHtml(agent.intro) + '</div>' : '') +
                '</div>' +
                '<div class="section-title">Настройки собеседника</div>' +
                '<div class="settings-card">' + settings + '</div>' +
                (agent.hint ? '<p class="hint" style="margin-top:8px">' + escapeHtml(agent.hint) + '</p>' : '');
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
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            renderGarageSheet();
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('garage-sheet').classList.add('open');
        }

        function closeGarage() {
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            document.getElementById('sheet-backdrop').classList.remove('open');
            document.getElementById('garage-sheet').classList.remove('open');
        }

        document.getElementById('garage-open').addEventListener('click', openGarage);
        document.getElementById('garage-close').addEventListener('click', closeGarage);
        document.getElementById('garage-back').addEventListener('click', () => {
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            renderGarageSheet();
        });
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
            return Number(value).toLocaleString('ru-RU') + (unit === 'mi' ? ' mi' : ' км');
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
            appState.garage = data.garage || {};
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
