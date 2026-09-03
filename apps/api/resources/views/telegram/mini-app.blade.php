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
            --card-elevated: #25221c;
            --text: #f5f0e8;
            --muted: #9d9488;
            --accent: #f5b942;
            --ai: #7cb8ff;
            --line: rgba(245, 240, 232, 0.08);
            --ok: #79c784;
            --warn: #f5b942;
            --bad: #f07474;
            --soft: rgba(157, 148, 136, 0.75);
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
            line-height: 1.45;
            margin: 0 0 12px;
        }
        .section-title {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            color: var(--muted);
            margin: 14px 0 8px;
        }
        .section-title:first-child { margin-top: 0; }
        .state-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
        }
        .unit-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 10px;
            min-height: 132px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .unit-card.status-overdue { border-color: rgba(240, 116, 116, 0.45); }
        .unit-card.status-soon { border-color: rgba(245, 185, 66, 0.35); }
        .unit-card.status-unknown { border-color: rgba(157, 148, 136, 0.25); }
        .unit-head {
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }
        .unit-ring {
            width: 44px;
            height: 44px;
            flex-shrink: 0;
        }
        .unit-ring svg { display: block; width: 44px; height: 44px; }
        .unit-name {
            font-size: 12px;
            font-weight: 600;
            line-height: 1.25;
            flex: 1;
        }
        .unit-metric {
            font-size: 10px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .unit-value {
            font-size: 13px;
            font-weight: 700;
            line-height: 1.2;
        }
        .unit-fact {
            font-size: 10px;
            color: var(--muted);
            line-height: 1.35;
        }
        .unit-fact strong { color: var(--text); font-weight: 500; }
        .timeline {
            position: relative;
            padding-left: 18px;
        }
        .timeline::before {
            content: '';
            position: absolute;
            left: 5px;
            top: 4px;
            bottom: 4px;
            width: 2px;
            background: linear-gradient(var(--line), rgba(245,185,66,0.35), var(--line));
        }
        .timeline-now {
            position: relative;
            margin: 10px 0 12px -18px;
            padding-left: 18px;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--accent);
            font-weight: 700;
        }
        .timeline-now::before {
            content: '';
            position: absolute;
            left: 0;
            top: 50%;
            width: 12px;
            height: 12px;
            margin-top: -6px;
            border-radius: 50%;
            background: var(--accent);
            box-shadow: 0 0 0 3px rgba(245,185,66,0.2);
        }
        .timeline-item {
            position: relative;
            margin-bottom: 10px;
            padding: 10px 10px 10px 0;
        }
        .timeline-item::before {
            content: '';
            position: absolute;
            left: -16px;
            top: 14px;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: var(--card-elevated);
            border: 2px solid var(--muted);
        }
        .timeline-item.tone-overdue::before { border-color: var(--bad); background: rgba(240,116,116,0.25); }
        .timeline-item.tone-soon::before { border-color: var(--warn); background: rgba(245,185,66,0.2); }
        .timeline-item.tone-soft::before { border-color: var(--soft); opacity: 0.85; }
        .timeline-card {
            border-radius: 10px;
            padding: 10px 12px;
            background: var(--card);
            border: 1px solid var(--line);
        }
        .timeline-item.tone-overdue .timeline-card {
            border-color: rgba(240, 116, 116, 0.35);
            background: rgba(240, 116, 116, 0.08);
        }
        .timeline-item.tone-soon .timeline-card {
            border-color: rgba(245, 185, 66, 0.3);
        }
        .timeline-item.tone-soft .timeline-card {
            opacity: 0.88;
            background: rgba(255,255,255,0.02);
        }
        .timeline-item.required .timeline-card { border-left: 3px solid var(--warn); }
        .timeline-item.recommended .timeline-card { border-left: 3px solid rgba(157,148,136,0.35); }
        .timeline-label { font-size: 13px; font-weight: 600; }
        .timeline-detail { font-size: 12px; color: var(--muted); margin-top: 3px; }
        .timeline-badge {
            display: inline-block;
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            padding: 2px 6px;
            border-radius: 999px;
            margin-bottom: 4px;
        }
        .timeline-badge.reg { background: rgba(245,185,66,0.18); color: var(--accent); }
        .timeline-badge.rec { background: rgba(255,255,255,0.06); color: var(--soft); }
        .agent-hero {
            background: linear-gradient(135deg, rgba(124,184,255,0.18), rgba(245,185,66,0.12));
            border: 1px solid rgba(124,184,255,0.25);
            border-radius: 14px;
            padding: 14px;
            margin-bottom: 12px;
        }
        .agent-hero-top { display: flex; align-items: center; gap: 10px; }
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
        .agent-tokens { font-size: 22px; font-weight: 700; line-height: 1.1; }
        .agent-tokens-label { font-size: 11px; color: var(--muted); }
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
        .nav-btn-agent.active { background: rgba(124,184,255,0.22); color: #dbeaff; }
        .nav-icon { display: block; font-size: 15px; line-height: 1.2; margin-bottom: 2px; }
        .nav-agent-tokens { display: block; font-size: 10px; font-weight: 700; margin-top: 2px; }
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
            max-height: 82vh;
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
            gap: 8px;
        }
        .sheet-title { font-size: 16px; font-weight: 600; }
        .sheet-close, .sheet-back {
            border: 0;
            background: transparent;
            color: var(--muted);
            font-size: 22px;
            cursor: pointer;
            line-height: 1;
        }
        .sheet-back { font-size: 14px; color: var(--ai); }
        .garage-hint {
            font-size: 12px;
            color: var(--muted);
            line-height: 1.4;
            margin-bottom: 12px;
        }
        .vehicle-tile {
            border: 1px solid var(--line);
            background: var(--bg);
            border-radius: 12px;
            padding: 12px;
            margin-bottom: 10px;
        }
        .vehicle-tile.active {
            border-color: rgba(124,184,255,0.45);
            background: rgba(124,184,255,0.08);
        }
        .vehicle-tile-head {
            display: flex;
            gap: 10px;
            align-items: flex-start;
        }
        .vehicle-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            background: var(--card-elevated);
            display: grid;
            place-items: center;
            font-size: 20px;
            flex-shrink: 0;
        }
        .vehicle-tile-title { font-weight: 600; font-size: 14px; }
        .vehicle-tile-sub { font-size: 11px; color: var(--muted); margin-top: 2px; }
        .vehicle-badge {
            display: inline-block;
            margin-top: 6px;
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 999px;
            background: rgba(124,184,255,0.18);
            color: var(--ai);
        }
        .vehicle-actions {
            display: flex;
            gap: 8px;
            margin-top: 10px;
        }
        .btn {
            flex: 1;
            border: 0;
            border-radius: 8px;
            padding: 8px 10px;
            font-size: 12px;
            cursor: pointer;
        }
        .btn-ghost {
            background: rgba(255,255,255,0.06);
            color: var(--text);
        }
        .btn-primary {
            background: rgba(124,184,255,0.22);
            color: #dbeaff;
            border: 1px solid rgba(124,184,255,0.35);
        }
        .btn-primary:disabled {
            opacity: 0.55;
            cursor: default;
        }
        .btn-add {
            width: 100%;
            margin-top: 4px;
            background: transparent;
            border: 1px dashed var(--line);
            color: var(--muted);
        }
        .btn-add.locked { opacity: 0.6; cursor: default; }
        .passport-section { margin-top: 12px; }
        .passport-title {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--muted);
            margin-bottom: 6px;
        }
        .field-row {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            padding: 6px 0;
            font-size: 12px;
            border-top: 1px solid var(--line);
        }
        .field-row:first-of-type { border-top: 0; }
        .field-value.empty { color: rgba(157,148,136,0.55); }
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
            document.body.style.background = tg.themeParams.bg_color || '';
        }

        let appState = {
            vehicles: [],
            agent: {},
            garage: {},
            activeVehicleKey: null,
            tab: 'state',
            garageView: 'list',
            garageDetailKey: null,
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
            const list = appState.vehicles || [];
            return list.find((v, i) => vehicleKey(v, i) === key) || null;
        }

        function renderHeader() {
            const vehicle = activeVehicle();
            const kicker = document.getElementById('garage-kicker');
            const title = document.getElementById('garage-title');
            const sub = document.getElementById('garage-sub');
            kicker.textContent = 'Гараж';
            if (!vehicle || vehicle.status === 'placeholder') {
                title.textContent = 'Выберите автомобиль';
                sub.textContent = 'Нажмите — откроется гараж';
                return;
            }
            title.textContent = vehicle.title || 'Автомобиль';
            const status = vehicle.status === 'draft' ? 'черновик · ' : '';
            sub.textContent = status + (vehicle.summary || 'активно для AI и аналитики');
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
            let html = '<p class="garage-hint">Выберите автомобиль, с которым беседуете с AI. ' +
                'Состояние, roadmap и аналитика ниже — про активную машину.</p>';

            (appState.vehicles || []).forEach((vehicle, index) => {
                const key = vehicleKey(vehicle, index);
                if (vehicle.status === 'placeholder') {
                    html += '<div class="vehicle-tile"><div class="vehicle-tile-head">' +
                        '<div class="vehicle-icon">＋</div>' +
                        '<div><div class="vehicle-tile-title">Пока нет автомобиля</div>' +
                        '<div class="vehicle-tile-sub">Расскажите боту про машину</div></div></div></div>';
                    return;
                }
                const isActive = key === appState.activeVehicleKey;
                html += '<div class="vehicle-tile' + (isActive ? ' active' : '') + '">' +
                    '<div class="vehicle-tile-head">' +
                    '<div class="vehicle-icon">🚗</div>' +
                    '<div style="min-width:0;flex:1">' +
                    '<div class="vehicle-tile-title">' + escapeHtml(vehicle.title) + '</div>' +
                    '<div class="vehicle-tile-sub">' + escapeHtml(vehicle.summary || 'Нет данных') + '</div>' +
                    (isActive ? '<span class="vehicle-badge">' + escapeHtml(garage.active_label || 'Активна для AI') + '</span>' : '') +
                    '</div></div>' +
                    '<div class="vehicle-actions">' +
                    '<button class="btn btn-ghost" type="button" data-detail="' + escapeHtml(key) + '">' +
                    escapeHtml(garage.detail_label || 'Подробнее') + '</button>' +
                    '<button class="btn btn-primary" type="button" data-select="' + escapeHtml(key) + '"' +
                    (isActive ? ' disabled' : '') + '>' +
                    (isActive ? '✓ Выбрана' : escapeHtml(garage.select_label || 'Выбрать для AI')) +
                    '</button></div></div>';
            });

            if (garage.can_add) {
                html += '<button class="btn btn-add" type="button" id="garage-add">' +
                    '+ Добавить автомобиль</button>' +
                    '<p class="garage-hint">' + escapeHtml(garage.add_hint || '') + '</p>';
            } else {
                html += '<button class="btn btn-add locked" type="button" disabled>+ Второй автомобиль — скоро</button>' +
                    '<p class="garage-hint">' + escapeHtml(garage.locked_hint || '') + '</p>';
            }

            root.innerHTML = html;
            root.querySelectorAll('[data-select]').forEach((btn) => {
                btn.addEventListener('click', () => selectVehicle(btn.dataset.select));
            });
            root.querySelectorAll('[data-detail]').forEach((btn) => {
                btn.addEventListener('click', () => openVehicleDetail(btn.dataset.detail));
            });
            const addBtn = document.getElementById('garage-add');
            if (addBtn) {
                addBtn.addEventListener('click', () => {
                    closeGarage();
                    if (tg && tg.close) {
                        tg.close();
                    }
                });
            }
        }

        function renderVehiclePassport(key) {
            const vehicle = vehicleByKey(key);
            if (!vehicle) return '<p class="hint">Автомобиль не найден.</p>';
            let html = '<div class="vehicle-tile-title" style="margin-bottom:8px">' + escapeHtml(vehicle.title) + '</div>' +
                '<div class="vehicle-tile-sub" style="margin-bottom:12px">' + escapeHtml(vehicle.summary || '') + '</div>';
            (vehicle.sections || []).forEach((section) => {
                html += '<div class="passport-section"><div class="passport-title">' + escapeHtml(section.title) + '</div>';
                (section.fields || []).forEach((field) => {
                    const value = field.filled ? field.value : '—';
                    const cls = field.filled ? 'field-value' : 'field-value empty';
                    html += '<div class="field-row"><span>' + escapeHtml(field.label) + '</span>' +
                        '<span class="' + cls + '">' + escapeHtml(value) + '</span></div>';
                });
                html += '</div>';
            });
            html += '<div class="vehicle-actions" style="margin-top:14px">' +
                '<button class="btn btn-primary" type="button" id="passport-select"' +
                (key === appState.activeVehicleKey ? ' disabled' : '') + '>' +
                (key === appState.activeVehicleKey ? '✓ Активна для AI' : 'Выбрать для AI') +
                '</button></div>';
            setTimeout(() => {
                const btn = document.getElementById('passport-select');
                if (btn && !btn.disabled) {
                    btn.addEventListener('click', () => selectVehicle(key));
                }
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

        function ringSvg(percent, status) {
            const p = percent == null ? null : Math.min(100, Math.max(0, percent));
            const r = 18;
            const c = 2 * Math.PI * r;
            const color = status === 'overdue' ? 'var(--bad)'
                : status === 'soon' ? 'var(--warn)'
                : status === 'unknown' ? 'var(--muted)' : 'var(--ok)';
            if (p == null) {
                return '<svg viewBox="0 0 44 44"><circle cx="22" cy="22" r="' + r + '" fill="none" stroke="rgba(255,255,255,0.08)" stroke-width="4"/>' +
                    '<text x="22" y="24" text-anchor="middle" font-size="8" fill="var(--muted)">?</text></svg>';
            }
            const dash = (p / 100) * c;
            return '<svg viewBox="0 0 44 44">' +
                '<circle cx="22" cy="22" r="' + r + '" fill="none" stroke="rgba(255,255,255,0.08)" stroke-width="4"/>' +
                '<circle cx="22" cy="22" r="' + r + '" fill="none" stroke="' + color + '" stroke-width="4" ' +
                'stroke-dasharray="' + dash + ' ' + c + '" transform="rotate(-90 22 22)" stroke-linecap="round"/>' +
                '<text x="22" y="24" text-anchor="middle" font-size="9" font-weight="700" fill="' + color + '">' + p + '%</text></svg>';
        }

        function stateDisplayMetric(item) {
            if (item.wear_percent != null) {
                return { percent: item.wear_percent, label: 'износ', caption: 'остаток ' + (item.remaining_percent ?? '—') + '%' };
            }
            if (item.used_percent != null) {
                return { percent: item.used_percent, label: 'ресурс', caption: 'использовано' };
            }
            return { percent: null, label: item.metric_label || 'нет данных', caption: '' };
        }

        function renderState() {
            const vehicle = activeVehicle();
            const items = vehicle?.tabs?.state || [];
            const root = document.getElementById('panel-state');
            if (!items.length) {
                root.innerHTML = '<p class="hint">Нет данных по узлам. Расскажите боту про обслуживание.</p>';
                return;
            }
            root.innerHTML = '<div class="section-title">Узлы и износ</div><div class="state-grid">' +
                items.map((item) => {
                    const status = item.status || 'unknown';
                    const metric = stateDisplayMetric(item);
                    const last = item.last_service ? ('<strong>Было:</strong> ' + escapeHtml(item.last_service)) : '<strong>Было:</strong> —';
                    const next = item.next_due ? ('<strong>Далее:</strong> ' + escapeHtml(item.next_due)) : '<strong>Далее:</strong> —';
                    return '<article class="unit-card status-' + status + '">' +
                        '<div class="unit-head">' +
                        '<div class="unit-ring">' + ringSvg(metric.percent, status) + '</div>' +
                        '<div><div class="unit-name">' + escapeHtml(item.label) + '</div>' +
                        '<div class="unit-metric">' + escapeHtml(metric.label) + '</div></div></div>' +
                        (metric.caption ? '<div class="unit-value">' + escapeHtml(metric.caption) + '</div>' : '') +
                        '<div class="unit-fact">' + last + '</div>' +
                        '<div class="unit-fact">' + next + '</div></article>';
                }).join('') + '</div>';
        }

        function renderTimelineItems(items, tierClass) {
            return (items || []).map((item) => {
                const tone = item.tone || 'soft';
                const badge = tierClass === 'required'
                    ? '<span class="timeline-badge reg">Регламент</span>'
                    : '<span class="timeline-badge rec">Рекомендация</span>';
                return '<div class="timeline-item ' + tierClass + ' tone-' + tone + '">' +
                    '<div class="timeline-card">' + badge +
                    '<div class="timeline-label">' + escapeHtml(item.label) + '</div>' +
                    '<div class="timeline-detail">' + escapeHtml(item.detail || item.due_label || '—') + '</div></div></div>';
            }).join('');
        }

        function renderRoadmap() {
            const vehicle = activeVehicle();
            const roadmap = vehicle?.tabs?.roadmap || { required: [], recommended: [], seasonal: [], hint: null };
            const root = document.getElementById('panel-roadmap');
            const required = roadmap.required || [];
            const recommended = [...(roadmap.recommended || []), ...(roadmap.seasonal || [])];

            if (!required.length && !recommended.length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(roadmap.hint || 'Пока нет ближайших работ.') + '</p>';
                return;
            }

            let html = roadmap.hint ? '<p class="hint">' + escapeHtml(roadmap.hint) + '</p>' : '';
            html += '<div class="timeline"><div class="timeline-now">Сегодня</div>';
            if (required.length) {
                html += '<div class="section-title">Регламент и безопасность</div>';
                html += renderTimelineItems(required, 'required');
            }
            if (recommended.length) {
                html += '<div class="section-title">Рекомендации</div>';
                html += renderTimelineItems(recommended, 'recommended');
            }
            html += '</div>';
            root.innerHTML = html;
        }

        function renderAnalytics() {
            const vehicle = activeVehicle();
            const analytics = vehicle?.tabs?.analytics || { points: [], hint: null };
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
            const settings = (agent.settings || []).map((row) => {
                const value = row.value ? row.value : '—';
                const cls = row.value ? 'setting-value' : 'setting-value field-value empty';
                return '<div class="setting-row"><span class="setting-label">' + escapeHtml(row.label) +
                    '</span><span class="' + cls + '">' + escapeHtml(value) + '</span></div>';
            }).join('');
            root.innerHTML =
                '<div class="agent-hero"><div class="agent-hero-top">' +
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
