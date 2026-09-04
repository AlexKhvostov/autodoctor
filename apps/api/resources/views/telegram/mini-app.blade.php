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
            --tg-safe-top: calc(
                var(--tg-safe-area-inset-top, env(safe-area-inset-top, 0px))
                + var(--tg-content-safe-area-inset-top, 0px)
            );
            --tg-safe-bottom: calc(
                var(--tg-safe-area-inset-bottom, env(safe-area-inset-bottom, 0px))
                + var(--tg-content-safe-area-inset-bottom, 0px)
            );
            --tg-safe-left: calc(
                var(--tg-safe-area-inset-left, env(safe-area-inset-left, 0px))
                + var(--tg-content-safe-area-inset-left, 0px)
            );
            --tg-safe-right: calc(
                var(--tg-safe-area-inset-right, env(safe-area-inset-right, 0px))
                + var(--tg-content-safe-area-inset-right, 0px)
            );
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
            min-height: 100%;
            display: flex;
            flex-direction: column;
            max-width: 420px;
            margin: 0 auto;
            padding-top: var(--tg-safe-top);
            padding-left: var(--tg-safe-left);
            padding-right: var(--tg-safe-right);
            background: linear-gradient(180deg, #f3f8ff 0%, var(--bg) 120px);
            box-sizing: border-box;
        }
        .topbar-shell {
            background: var(--card);
            border-bottom: 1px solid var(--line);
            box-shadow: 0 2px 12px rgba(21, 32, 51, 0.06);
        }
        .topbar {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 6px 10px;
        }
        .garage-btn {
            flex: 1;
            min-width: 0;
            display: flex;
            align-items: center;
            gap: 7px;
            padding: 5px 8px;
            border-radius: 10px;
            border: 1px solid var(--line);
            background: var(--bg-soft);
            color: inherit;
            cursor: pointer;
            text-align: left;
        }
        .car-thumb {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background: var(--primary-soft);
            display: grid;
            place-items: center;
            font-size: 16px;
            flex-shrink: 0;
            overflow: hidden;
        }
        .car-thumb img { width: 100%; height: 100%; object-fit: cover; }
        .garage-text { min-width: 0; flex: 1; }
        .garage-title {
            font-size: 13px;
            font-weight: 700;
            line-height: 1.15;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .garage-sub {
            font-size: 10px;
            color: var(--muted);
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            margin-top: 1px;
        }
        .garage-chev { color: var(--muted); font-size: 10px; flex-shrink: 0; }
        .info-btn {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            border: 1px solid var(--line);
            background: var(--bg-soft);
            color: var(--primary-deep);
            font-size: 12px;
            font-weight: 800;
            font-style: italic;
            cursor: pointer;
            flex-shrink: 0;
        }
        .avatar {
            width: 28px;
            height: 28px;
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
            cursor: pointer;
            padding: 0;
        }
        .avatar:active { opacity: 0.85; }
        .state-divider {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 10px 0 8px;
            color: var(--muted);
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
        }
        .state-divider::before,
        .state-divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: var(--line);
        }
        .unit-card.untouched {
            opacity: 0.72;
            border-style: dashed;
        }
        .profile-row {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 10px 0;
            border-top: 1px solid var(--line);
            font-size: 13px;
        }
        .profile-row:first-of-type { border-top: 0; }
        .profile-label { color: var(--muted); font-size: 11px; }
        .profile-value { font-weight: 700; text-align: right; word-break: break-all; }
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
        .unit-card[data-unit] { cursor: pointer; }
        .unit-card[data-unit]:active { opacity: 0.92; }
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
        .road-list { display: flex; flex-direction: column; gap: 0; }
        .tl-wrap { position: relative; padding-left: 22px; }
        .tl-wrap::before {
            content: '';
            position: absolute;
            left: 7px;
            top: 0;
            bottom: 0;
            width: 2px;
            background: linear-gradient(rgba(34,181,115,0.35), var(--primary) 42%, rgba(21,32,51,0.1));
        }
        .tl-past-scroll {
            max-height: 140px;
            overflow-y: auto;
            margin-bottom: 4px;
            padding-right: 2px;
        }
        .tl-now {
            position: relative;
            margin: 4px 0 6px -22px;
            padding: 6px 8px 6px 22px;
            border-radius: 10px;
            background: var(--primary-soft);
            border: 1px solid rgba(30, 202, 211, 0.25);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .tl-now-main { min-width: 0; flex: 1; }
        .tl-now-label {
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: 0.1em;
            color: var(--primary-deep);
            font-weight: 800;
        }
        .tl-now-meta {
            font-size: 12px;
            font-weight: 700;
            margin-top: 2px;
            line-height: 1.25;
        }
        .tl-now-sub {
            font-size: 9px;
            color: var(--muted);
            margin-top: 2px;
            line-height: 1.35;
        }
        .mileage-side-btn {
            flex-shrink: 0;
            width: 58px;
            border: 1px solid rgba(30, 202, 211, 0.4);
            background: rgba(255, 255, 255, 0.72);
            color: var(--primary-deep);
            border-radius: 10px;
            padding: 6px 4px;
            font-size: 10px;
            font-weight: 800;
            line-height: 1.15;
            cursor: pointer;
            text-align: center;
            box-shadow: var(--shadow);
        }
        .mileage-side-btn:active { opacity: 0.85; }
        .mileage-form-hint {
            font-size: 11px;
            color: var(--muted);
            margin: 0 0 10px;
            line-height: 1.4;
        }
        .odo-wrap {
            display: flex;
            justify-content: center;
            gap: 4px;
            padding: 8px 4px 4px;
            margin-bottom: 10px;
            user-select: none;
            -webkit-user-select: none;
        }
        .odo-col {
            width: 36px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 2px;
        }
        .odo-btn {
            width: 100%;
            height: 28px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: var(--bg-soft);
            color: var(--primary-deep);
            font-size: 12px;
            font-weight: 800;
            cursor: pointer;
            padding: 0;
            line-height: 1;
        }
        .odo-btn:active { opacity: 0.8; background: rgba(30, 202, 211, 0.16); }
        .odo-digit {
            width: 100%;
            height: 42px;
            border-radius: 10px;
            border: 1px solid rgba(30, 202, 211, 0.35);
            background: var(--card);
            box-shadow: var(--shadow);
            display: grid;
            place-items: center;
            font-size: 22px;
            font-weight: 800;
            font-variant-numeric: tabular-nums;
            color: var(--ink);
        }
        .odo-value-label {
            text-align: center;
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 8px;
            color: var(--primary-deep);
        }
        .tl-now::before {
            content: '';
            position: absolute;
            left: 2px;
            top: 50%;
            width: 12px;
            height: 12px;
            margin-top: -6px;
            border-radius: 50%;
            background: var(--primary);
            box-shadow: 0 0 0 3px var(--primary-soft);
        }
        .tl-node {
            position: relative;
            margin-bottom: 5px;
            padding: 4px 8px 4px 0;
            display: flex;
            gap: 6px;
            align-items: flex-start;
        }
        .tl-node::before {
            content: '';
            position: absolute;
            left: -18px;
            top: 12px;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--card);
            border: 2px solid var(--muted);
        }
        .tl-node.past.done::before {
            border-color: var(--ok);
            background: var(--ok);
            box-shadow: 0 0 0 2px rgba(34,181,115,0.18);
        }
        .tl-check {
            width: 16px;
            height: 16px;
            border-radius: 50%;
            background: rgba(34,181,115,0.15);
            color: var(--ok);
            display: grid;
            place-items: center;
            font-size: 10px;
            font-weight: 800;
            flex-shrink: 0;
            margin-top: 1px;
        }
        .history-item {
            padding: 8px 10px;
            border: 1px solid rgba(34,181,115,0.22);
            border-radius: 8px;
            background: rgba(34,181,115,0.06);
            margin-bottom: 6px;
            display: flex;
            gap: 8px;
            align-items: flex-start;
        }
        .history-item-date { font-size: 12px; font-weight: 700; }
        .history-item-meta { font-size: 10px; color: var(--muted); margin-top: 2px; }
        .tl-node.overdue .tl-card { border-left-color: var(--bad); }
        .tl-node.required .tl-card { border-left: 2px solid var(--warn); }
        .tl-node.recommended .tl-card { border-left: 2px solid rgba(107,122,144,0.35); opacity: 0.92; }
        .tl-card {
            flex: 1;
            min-width: 0;
            background: var(--card);
            border: 1px solid var(--line);
            border-left: 2px solid rgba(107,122,144,0.35);
            border-radius: 8px;
            padding: 5px 7px;
            box-shadow: var(--shadow);
            display: flex;
            align-items: flex-start;
            gap: 6px;
        }
        .tl-card-body { min-width: 0; flex: 1; }
        .hint-btn {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            border: 1px solid var(--line);
            background: var(--bg-soft);
            color: var(--primary-deep);
            font-size: 11px;
            font-weight: 800;
            font-style: italic;
            cursor: pointer;
            flex-shrink: 0;
            line-height: 1;
            padding: 0;
            margin-top: 1px;
        }
        .hint-btn:active { opacity: 0.8; }
        .tl-label { font-size: 12px; font-weight: 700; line-height: 1.2; }
        .tl-meta { font-size: 9px; color: var(--muted); margin-top: 2px; line-height: 1.35; }
        .tl-icons { display: flex; gap: 3px; flex-shrink: 0; padding-top: 2px; }
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
        .chart-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px 10px 10px;
            margin-bottom: 8px;
            box-shadow: var(--shadow);
        }
        .chart-title { font-size: 12px; font-weight: 700; margin-bottom: 6px; }
        .chart-svg { width: 100%; height: 72px; display: block; }
        .chart-caption { font-size: 9px; color: var(--muted); margin-top: 4px; }
        .journal-list { display: flex; flex-direction: column; gap: 6px; }
        .journal-item {
            display: flex;
            gap: 8px;
            align-items: flex-start;
            padding: 8px 10px;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            box-shadow: var(--shadow);
        }
        .journal-item.tone-ok { border-left: 3px solid var(--ok); }
        .journal-item.tone-soft { border-left: 3px solid rgba(107,122,144,0.35); }
        .journal-mark {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            display: grid;
            place-items: center;
            font-size: 11px;
            font-weight: 800;
            flex-shrink: 0;
            margin-top: 1px;
            background: rgba(34,181,115,0.12);
            color: var(--ok);
        }
        .journal-item.tone-soft .journal-mark {
            background: rgba(107,122,144,0.12);
            color: var(--muted);
        }
        .journal-title { font-size: 13px; font-weight: 700; line-height: 1.2; }
        .journal-detail { font-size: 11px; color: var(--muted); margin-top: 3px; line-height: 1.35; }
        .journal-meta { font-size: 10px; color: var(--muted); margin-top: 4px; }
        .detail-lead {
            font-size: 12px;
            color: var(--ink);
            line-height: 1.45;
            margin: 0 0 10px;
        }
        .detail-badge {
            display: inline-block;
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--primary-deep);
            background: rgba(30, 202, 211, 0.12);
            border-radius: 6px;
            padding: 3px 7px;
            margin-bottom: 8px;
        }
        .token-topup-btn {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            width: 100%;
            margin-top: 10px;
            padding: 9px 11px;
            border-radius: 12px;
            border: 1px solid rgba(30, 202, 211, 0.35);
            background: linear-gradient(135deg, rgba(30,202,211,0.18), rgba(59,130,246,0.12));
            color: var(--ink);
            cursor: pointer;
            text-align: left;
            box-shadow: var(--shadow);
        }
        .token-topup-btn:active { opacity: 0.9; }
        .token-topup-title { font-size: 13px; font-weight: 800; line-height: 1.2; }
        .token-topup-sub { font-size: 10px; color: var(--muted); margin-top: 2px; font-weight: 600; }
        .token-topup-chev { color: var(--primary-deep); font-size: 16px; font-weight: 700; }
        .topup-option {
            display: flex;
            gap: 10px;
            align-items: flex-start;
            width: 100%;
            padding: 10px;
            margin-bottom: 8px;
            border-radius: 12px;
            border: 1px solid var(--line);
            background: var(--card);
            text-align: left;
            cursor: pointer;
            color: inherit;
            box-shadow: var(--shadow);
        }
        .topup-option:disabled {
            opacity: 0.72;
            cursor: default;
        }
        .topup-option:not(:disabled):active { opacity: 0.9; }
        .topup-ico {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            display: grid;
            place-items: center;
            font-size: 16px;
            flex-shrink: 0;
            background: rgba(30, 202, 211, 0.12);
        }
        .topup-option-title { font-size: 13px; font-weight: 800; line-height: 1.2; }
        .topup-option-sub { font-size: 11px; color: var(--muted); margin-top: 3px; line-height: 1.35; }
        .topup-option-meta {
            margin-top: 5px;
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
            align-items: center;
        }
        .topup-chip {
            font-size: 10px;
            font-weight: 700;
            border-radius: 999px;
            padding: 2px 7px;
            background: rgba(30, 202, 211, 0.14);
            color: var(--primary-deep);
        }
        .topup-chip.soon {
            background: rgba(107, 122, 144, 0.14);
            color: var(--muted);
        }
        .topup-toast {
            font-size: 11px;
            color: var(--muted);
            margin-top: 6px;
            min-height: 14px;
            font-weight: 600;
        }
        .bottom-nav.admin-mode { grid-template-columns: repeat(6, 1fr); }
        .nav-btn.admin-only { display: none; }
        .bottom-nav.admin-mode .nav-btn.admin-only { display: block; }
        .writer-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px 10px;
            margin-bottom: 6px;
            box-shadow: var(--shadow);
        }
        .writer-top {
            display: flex;
            justify-content: space-between;
            gap: 8px;
            align-items: flex-start;
        }
        .writer-name { font-size: 13px; font-weight: 700; line-height: 1.2; }
        .writer-meta { font-size: 10px; color: var(--muted); margin-top: 3px; line-height: 1.35; }
        .writer-badges { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
        .writer-badge {
            font-size: 9px;
            font-weight: 700;
            padding: 2px 6px;
            border-radius: 999px;
            background: rgba(107,122,144,0.12);
            color: var(--muted);
        }
        .writer-badge.on {
            background: rgba(34,181,115,0.15);
            color: var(--ok);
        }
        .writer-badge.warn {
            background: rgba(245,158,11,0.15);
            color: #b45309;
        }
        .writer-toggle {
            flex-shrink: 0;
            border: 1px solid rgba(30, 202, 211, 0.35);
            background: var(--primary-soft);
            color: var(--primary-deep);
            border-radius: 8px;
            padding: 6px 8px;
            font-size: 10px;
            font-weight: 700;
            cursor: pointer;
        }
        .writer-toggle.off {
            background: rgba(21,32,51,0.05);
            border-color: var(--line);
            color: var(--muted);
        }
        .writer-toggle:disabled { opacity: 0.55; cursor: default; }
        .form-card {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px 10px;
            margin-bottom: 8px;
            box-shadow: var(--shadow);
        }
        .form-label { font-size: 10px; color: var(--muted); font-weight: 600; margin-bottom: 4px; display: block; }
        .form-select, .form-textarea {
            width: 100%;
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 6px 8px;
            font-size: 11px;
            background: var(--bg-soft);
            color: var(--text);
        }
        .form-textarea { min-height: 64px; resize: vertical; }
        .form-range { width: 100%; margin: 4px 0; }
        .form-range-labels {
            display: flex;
            justify-content: space-between;
            font-size: 9px;
            color: var(--muted);
        }
        .form-save {
            width: 100%;
            margin-top: 6px;
            padding: 9px;
            border: 0;
            border-radius: 9px;
            background: linear-gradient(135deg, rgba(30,202,211,0.25), rgba(59,130,246,0.18));
            color: var(--primary-deep);
            font-weight: 700;
            font-size: 12px;
            cursor: pointer;
        }
        .form-save:disabled { opacity: 0.5; cursor: default; }
        .note-item {
            font-size: 10px;
            color: var(--muted);
            padding: 5px 0;
            border-top: 1px solid var(--line);
        }
        .note-item:first-child { border-top: 0; }
        .save-toast {
            font-size: 10px;
            color: var(--ok);
            font-weight: 600;
            min-height: 14px;
            margin-top: 4px;
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
            grid-template-columns: repeat(5, 1fr);
            gap: 2px;
            padding: 6px 6px calc(6px + var(--tg-safe-bottom));
            background: rgba(255,255,255,0.92);
            border-top: 1px solid var(--line);
            backdrop-filter: blur(8px);
        }
        .nav-btn {
            border: 0;
            background: transparent;
            color: var(--muted);
            border-radius: 10px;
            padding: 5px 2px;
            font-size: 8px;
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
            padding: 12px 14px calc(16px + var(--tg-safe-bottom));
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
            letter-spacing: 0.08em;
            color: var(--muted);
            font-weight: 700;
            margin-bottom: 6px;
        }
        .passport-edit-grid { display: grid; gap: 8px; margin-bottom: 10px; }
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
        <div class="topbar-shell">
            <header class="topbar">
                <button class="garage-btn" id="garage-open" type="button">
                    <div class="car-thumb" id="car-thumb">🚗</div>
                    <div class="garage-text">
                        <div class="garage-title" id="garage-title">Автомобиль</div>
                        <div class="garage-sub" id="garage-sub"></div>
                    </div>
                    <span class="garage-chev">▾</span>
                </button>
                <button class="info-btn" id="help-open" type="button" title="Подсказка">i</button>
                <button class="avatar" id="user-avatar" type="button" title="Профиль">AD</button>
            </header>
        </div>

        <main class="main">
            <section class="panel active" id="panel-state"></section>
            <section class="panel" id="panel-roadmap"></section>
            <section class="panel" id="panel-journal"></section>
            <section class="panel" id="panel-analytics"></section>
            <section class="panel" id="panel-allowlist"></section>
            <section class="panel" id="panel-agent"></section>
        </main>

        <nav class="bottom-nav" id="bottom-nav">
            <button class="nav-btn active" type="button" data-tab="state">
                <span class="nav-icon">◎</span>Состояние
            </button>
            <button class="nav-btn" type="button" data-tab="roadmap">
                <span class="nav-icon">→</span>План
            </button>
            <button class="nav-btn" type="button" data-tab="journal">
                <span class="nav-icon">≡</span>Журнал
            </button>
            <button class="nav-btn" type="button" data-tab="analytics">
                <span class="nav-icon">⌁</span>Аналитика
            </button>
            <button class="nav-btn admin-only" type="button" data-tab="allowlist" id="nav-allowlist">
                <span class="nav-icon">☑</span>Список
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
    <div class="sheet" id="help-sheet">
        <div class="sheet-head">
            <div class="sheet-title" id="help-title">Подсказка</div>
            <button class="sheet-close" id="help-close" type="button">×</button>
        </div>
        <div id="help-content"></div>
    </div>
    <div class="sheet" id="history-sheet">
        <div class="sheet-head">
            <div class="sheet-title" id="history-title">История</div>
            <button class="sheet-close" id="history-close" type="button">×</button>
        </div>
        <div id="history-content"></div>
    </div>
    <div class="sheet" id="profile-sheet">
        <div class="sheet-head">
            <div class="sheet-title" id="profile-title">Профиль</div>
            <button class="sheet-close" id="profile-close" type="button">×</button>
        </div>
        <div id="profile-content"></div>
    </div>

    <script>
        const tg = window.Telegram && window.Telegram.WebApp;

        function readInset(value) {
            return typeof value === 'number' && !Number.isNaN(value) && value > 0 ? value : 0;
        }

        function applyTelegramSafeAreas() {
            const content = (tg && tg.contentSafeAreaInset) || {};
            const safe = (tg && tg.safeAreaInset) || {};
            let top = readInset(safe.top) + readInset(content.top);
            let bottom = readInset(safe.bottom) + readInset(content.bottom);
            let left = readInset(safe.left) + readInset(content.left);
            let right = readInset(safe.right) + readInset(content.right);

            if (top === 0 && tg && (tg.isFullscreen || tg.isExpanded)) {
                top = 72;
            }

            const root = document.documentElement;
            if (top > 0) root.style.setProperty('--tg-safe-top', top + 'px');
            if (bottom > 0) root.style.setProperty('--tg-safe-bottom', bottom + 'px');
            if (left > 0) root.style.setProperty('--tg-safe-left', left + 'px');
            if (right > 0) root.style.setProperty('--tg-safe-right', right + 'px');
        }

        if (tg) {
            tg.ready();
            tg.expand();
            if (typeof tg.disableVerticalSwipes === 'function') tg.disableVerticalSwipes();
            if (typeof tg.requestFullscreen === 'function') tg.requestFullscreen();
            if (tg.setHeaderColor) tg.setHeaderColor('#eef3fb');
            if (tg.setBackgroundColor) tg.setBackgroundColor('#eef3fb');
            applyTelegramSafeAreas();
            setTimeout(applyTelegramSafeAreas, 50);
            setTimeout(applyTelegramSafeAreas, 300);
            if (typeof tg.onEvent === 'function') {
                tg.onEvent('contentSafeAreaChanged', applyTelegramSafeAreas);
                tg.onEvent('safeAreaChanged', applyTelegramSafeAreas);
                tg.onEvent('viewportChanged', applyTelegramSafeAreas);
                tg.onEvent('fullscreenChanged', applyTelegramSafeAreas);
            }
        }

        let appState = {
            vehicles: [], agent: {}, garage: {}, help: {}, user: {},
            isOwner: false, writers: [], writersLoaded: false, writersLoading: false,
            activeVehicleKey: null, tab: 'state',
            garageView: 'list', garageDetailKey: null,
            passportEditing: false, savingVehicle: false, vehicleToast: '',
            savingAgent: false, agentToast: '', topupToast: '',
        };

        const apiBase = @json(url('/telegram/app'));
        const initData = tg && tg.initData ? tg.initData : '';
        const apiHeaders = {
            'X-Telegram-Init-Data': initData,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        };

        function stateUrl() {
            const vehicle = activeVehicle();
            return vehicle && vehicle.id
                ? apiBase + '/state?vehicle_id=' + encodeURIComponent(vehicle.id)
                : apiBase + '/state';
        }

        function tierIcon(tier) {
            return tier === 'required'
                ? '<span class="ico ico-tier-reg" title="Регламент">🛡</span>'
                : '<span class="ico ico-tier-rec" title="Рекомендация">✦</span>';
        }

        function renderHeader() {
            const vehicle = activeVehicle();
            const title = document.getElementById('garage-title');
            const sub = document.getElementById('garage-sub');
            const thumb = document.getElementById('car-thumb');
            if (!vehicle || vehicle.status === 'placeholder') {
                title.textContent = 'Автомобиль';
                sub.textContent = 'Нажмите, чтобы выбрать';
                thumb.textContent = '🚗';
                return;
            }
            title.textContent = vehicle.title || 'Автомобиль';
            sub.textContent = vehicle.summary || '';
            thumb.textContent = '🚗';
        }

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

        function renderRoadmap() {
            const roadmap = activeVehicle()?.tabs?.roadmap || { now: {}, past: [], upcoming: [], hint: null };
            const root = document.getElementById('panel-roadmap');
            const past = roadmap.past || [];
            const upcoming = roadmap.upcoming || [];
            const now = roadmap.now || {};
            if (!past.length && !upcoming.length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(roadmap.hint || 'Пока нет ближайших работ.') + '</p>';
                return;
            }
            let html = roadmap.hint ? '<p class="hint">' + escapeHtml(roadmap.hint) + '</p>' : '';
            html += '<div class="tl-wrap">';
            if (past.length) {
                html += '<div class="tl-past-scroll">';
                past.forEach((item) => { html += renderPastNode(item); });
                html += '</div>';
            }
            html += renderNowNode(now);
            upcoming.forEach((item, index) => { html += renderTimelineNode(item, index); });
            html += '</div>';
            root.innerHTML = html;
            root.querySelectorAll('[data-tip]').forEach((btn) => {
                btn.addEventListener('click', (event) => {
                    event.stopPropagation();
                    const item = upcoming[Number(btn.dataset.tip)];
                    if (item) openRoadmapTip(item);
                });
            });
            const mileageBtn = root.querySelector('[data-open-mileage]');
            if (mileageBtn) mileageBtn.addEventListener('click', openMileageSheet);
        }

        function renderNowNode(now) {
            const meta = [
                now.date,
                now.mileage_label ? ('пробег ' + now.mileage_label) : null,
            ].filter(Boolean).join(' · ');
            const sub = now.last_event_date
                ? ('посл. событие: ' + now.last_event_date +
                    (now.last_event_mileage_label ? (' · ' + now.last_event_mileage_label) : ''))
                : '';
            const vehicle = activeVehicle();
            const canMileage = vehicle && vehicle.status === 'saved' && vehicle.id;
            return '<div class="tl-now"><div class="tl-now-main">' +
                '<div class="tl-now-label">Сейчас</div>' +
                '<div class="tl-now-meta">' + escapeHtml(meta || 'сегодня') + '</div>' +
                (sub ? '<div class="tl-now-sub">' + escapeHtml(sub) + '</div>' : '') +
                '</div>' +
                (canMileage
                    ? '<button class="mileage-side-btn" type="button" data-open-mileage="1" title="Обновить пробег">Пробег<br>↻</button>'
                    : '') +
                '</div>';
        }

        function renderPastNode(item) {
            const meta = [item.date, item.mileage_label].filter(Boolean).join(' · ');
            return '<div class="tl-node past done">' +
                '<div class="tl-check" title="Выполнено">✓</div>' +
                '<div class="tl-card"><div class="tl-card-body"><div class="tl-label">' + escapeHtml(item.label) + '</div>' +
                '<div class="tl-meta">' + escapeHtml(meta || '—') + '</div></div></div></div>';
        }

        function renderTimelineNode(item, index) {
            const meta = [
                item.days_label,
                item.due_date ? ('~ ' + item.due_date) : null,
                item.due_mileage_label ? ('~ ' + item.due_mileage_label) : null,
            ].filter(Boolean).join(' · ');
            const toneClass = item.tone === 'overdue' ? ' overdue' : '';
            return '<div class="tl-node' + toneClass + ' ' + (item.tier || 'recommended') + '">' +
                '<div class="tl-icons">' + tierIcon(item.tier) + '</div>' +
                '<div class="tl-card"><div class="tl-card-body"><div class="tl-label">' + escapeHtml(item.label) + '</div>' +
                '<div class="tl-meta">' + escapeHtml(meta || item.detail || '—') + '</div></div>' +
                '<button class="hint-btn" type="button" data-tip="' + index + '" title="Что это значит" aria-label="Подсказка">i</button>' +
                '</div></div>';
        }

        function openRoadmapTip(item) {
            const hint = item.hint || {};
            let html = '';
            if (hint.kind_label) {
                html += '<div class="detail-badge">' + escapeHtml(hint.kind_label) + '</div>';
            }
            if (hint.action) {
                html += '<p class="detail-lead">' + escapeHtml(hint.action) + '</p>';
            }
            if (hint.why) {
                html += '<div class="passport-section"><div class="passport-title">Зачем</div>' +
                    '<p class="garage-hint" style="margin:0">' + escapeHtml(hint.why) + '</p></div>';
            }
            const when = [
                item.days_label,
                item.due_date ? ('дата ~ ' + item.due_date) : null,
                item.due_mileage_label ? ('пробег ~ ' + item.due_mileage_label) : null,
            ].filter(Boolean).join(' · ');
            if (when || item.detail) {
                html += '<div class="passport-section" style="margin-top:10px"><div class="passport-title">В плане</div>';
                if (when) html += '<div class="field-row"><span>Срок</span><span class="field-value">' + escapeHtml(when) + '</span></div>';
                if (item.detail) html += '<div class="field-row"><span>Деталь</span><span class="field-value">' + escapeHtml(item.detail) + '</span></div>';
                html += '</div>';
            }
            openDetailSheet(item.label || 'Подсказка', html || '<p class="hint">Пока нет пояснения.</p>');
        }

        function placeholderChart() {
            return '<svg class="chart-svg" viewBox="0 0 300 72" preserveAspectRatio="none">' +
                '<polyline fill="none" stroke="rgba(30,202,211,0.55)" stroke-width="2" ' +
                'points="0,58 40,52 80,48 120,40 160,36 200,28 240,22 280,18 300,14"/>' +
                '<line x1="0" y1="68" x2="300" y2="68" stroke="rgba(21,32,51,0.08)" stroke-width="1"/></svg>';
        }

        function renderJournal() {
            const journal = activeVehicle()?.tabs?.journal || { events: [], hint: null };
            const root = document.getElementById('panel-journal');
            const events = journal.events || [];
            if (!events.length) {
                root.innerHTML = '<p class="hint">' + escapeHtml(journal.hint || 'Пока записей нет.') + '</p>';
                return;
            }
            let html = journal.hint ? '<p class="hint">' + escapeHtml(journal.hint) + '</p>' : '';
            html += '<div class="journal-list">' + events.map((event, index) => {
                const tone = event.tone === 'ok' ? 'tone-ok' : 'tone-soft';
                const mark = event.tone === 'ok' ? '✓' : '•';
                const meta = [event.date, event.time, event.mileage_label].filter(Boolean).join(' · ');
                return '<article class="journal-item ' + tone + '">' +
                    '<div class="journal-mark">' + mark + '</div><div style="min-width:0;flex:1">' +
                    '<div class="journal-title">' + escapeHtml(event.title || 'Запись') + '</div>' +
                    (event.detail ? '<div class="journal-detail">' + escapeHtml(event.detail) + '</div>' : '') +
                    (meta ? '<div class="journal-meta">' + escapeHtml(meta) + '</div>' : '') +
                    '</div><button class="hint-btn" type="button" data-journal="' + index +
                    '" title="Подробнее" aria-label="Подробнее">i</button></article>';
            }).join('') + '</div>';
            root.innerHTML = html;
            root.querySelectorAll('[data-journal]').forEach((btn) => {
                btn.addEventListener('click', (event) => {
                    event.stopPropagation();
                    const row = events[Number(btn.dataset.journal)];
                    if (row) openJournalDetail(row);
                });
            });
        }

        function openJournalDetail(event) {
            const fields = event.fields || [];
            let html = '';
            if (event.detail) {
                html += '<p class="detail-lead">' + escapeHtml(event.detail) + '</p>';
            }
            if (fields.length) {
                html += '<div class="passport-section"><div class="passport-title">Что записано</div>' +
                    fields.map((field) =>
                        '<div class="field-row"><span>' + escapeHtml(field.label || '') +
                        '</span><span class="field-value">' + escapeHtml(field.value || '—') + '</span></div>'
                    ).join('') + '</div>';
            } else {
                const fallback = [
                    ['Дата', event.date],
                    ['Время', event.time],
                    ['Пробег', event.mileage_label],
                ].filter((row) => row[1]);
                html += '<div class="passport-section"><div class="passport-title">Что записано</div>' +
                    fallback.map((row) =>
                        '<div class="field-row"><span>' + escapeHtml(row[0]) +
                        '</span><span class="field-value">' + escapeHtml(row[1]) + '</span></div>'
                    ).join('') + '</div>';
            }
            openDetailSheet(event.title || 'Запись журнала', html);
        }

        function renderAllowlist() {
            const root = document.getElementById('panel-allowlist');
            if (!appState.isOwner) {
                root.innerHTML = '<p class="hint">Раздел только для администратора.</p>';
                return;
            }
            if (appState.writersLoading && !appState.writersLoaded) {
                root.innerHTML = '<p class="hint">Загружаем список…</p>';
                return;
            }
            const writers = appState.writers || [];
            let html = '<p class="hint">Кто писал боту. Как в админке: добавляйте и убирайте из белого списка.</p>';
            if (!writers.length) {
                html += '<p class="hint">Пока никто не писал боту.</p>';
                root.innerHTML = html;
                return;
            }
            html += writers.map((writer) => {
                const allowed = !!writer.is_allowlisted;
                const badges = [];
                if (allowed) badges.push('<span class="writer-badge on">в списке</span>');
                if (writer.env_allowlisted) badges.push('<span class="writer-badge warn">env</span>');
                if (writer.is_owner) badges.push('<span class="writer-badge">владелец</span>');
                if (writer.access_requested_at) badges.push('<span class="writer-badge">заявка '+escapeHtml(writer.access_requested_at)+'</span>');
                const meta = [
                    'ID ' + writer.telegram_user_id,
                    writer.username ? ('@' + writer.username) : null,
                    writer.message_count != null ? (writer.message_count + ' сообщ.') : null,
                    writer.last_message_at ? ('был ' + writer.last_message_at) : null,
                ].filter(Boolean).join(' · ');
                const disabled = writer.is_owner && allowed ? ' disabled' : '';
                return '<div class="writer-card"><div class="writer-top"><div style="min-width:0;flex:1">' +
                    '<div class="writer-name">' + escapeHtml(writer.display_name || ('ID ' + writer.telegram_user_id)) + '</div>' +
                    '<div class="writer-meta">' + escapeHtml(meta) + '</div>' +
                    (badges.length ? '<div class="writer-badges">' + badges.join('') + '</div>' : '') +
                    '</div><button class="writer-toggle' + (allowed ? '' : ' off') + '" type="button" data-writer="' +
                    escapeHtml(String(writer.telegram_user_id)) + '" data-allowed="' + (allowed ? '1' : '0') + '"' + disabled + '>' +
                    (allowed ? 'Убрать' : 'Добавить') + '</button></div></div>';
            }).join('');
            root.innerHTML = html;
            root.querySelectorAll('[data-writer]').forEach((btn) => {
                btn.addEventListener('click', () => toggleWriter(btn.dataset.writer, btn.dataset.allowed !== '1'));
            });
        }

        async function loadWriters(force) {
            if (!appState.isOwner) return;
            if (appState.writersLoading) return;
            if (appState.writersLoaded && !force) {
                renderAllowlist();
                return;
            }
            appState.writersLoading = true;
            renderAllowlist();
            try {
                const res = await fetch(apiBase + '/admin/writers', { headers: apiHeaders });
                const data = await res.json();
                if (!res.ok) throw new Error('writers failed');
                appState.writers = data.writers || [];
                appState.writersLoaded = true;
            } catch (e) {
                appState.writers = [];
                appState.writersLoaded = false;
            } finally {
                appState.writersLoading = false;
                renderAllowlist();
            }
        }

        async function toggleWriter(telegramUserId, nextAllowed) {
            try {
                const res = await fetch(apiBase + '/admin/writers/' + encodeURIComponent(telegramUserId), {
                    method: 'PATCH',
                    headers: apiHeaders,
                    body: JSON.stringify({ is_allowlisted: !!nextAllowed }),
                });
                const data = await res.json();
                if (!res.ok) {
                    alert(data.message || 'Не удалось обновить список');
                    return;
                }
                await loadWriters(true);
            } catch (e) {
                alert('Не удалось обновить список');
            }
        }

        function renderAnalytics() {
            const analytics = activeVehicle()?.tabs?.analytics || { charts: [], points: [] };
            const root = document.getElementById('panel-analytics');
            const charts = analytics.charts || [
                { title: 'Пробег', caption: 'Скоро' },
                { title: 'Расход топлива', caption: 'Скоро' },
            ];
            root.innerHTML = charts.map((chart) =>
                '<div class="chart-card"><div class="chart-title">' + escapeHtml(chart.title) + '</div>' +
                placeholderChart() +
                '<div class="chart-caption">' + escapeHtml(chart.caption || '') + '</div></div>'
            ).join('');
        }

        function renderSelectField(key, field) {
            const options = (field.options || []).map((opt) =>
                '<option value="' + escapeHtml(opt.value) + '"' +
                (opt.value === field.value ? ' selected' : '') + '>' +
                escapeHtml(opt.label) + '</option>'
            ).join('');
            return '<div class="form-card"><label class="form-label" for="f-' + key + '">' +
                escapeHtml(field.label) + '</label>' +
                '<select class="form-select" id="f-' + key + '" data-field="' + key + '">' + options + '</select></div>';
        }

        function renderSliderField(key, field) {
            return '<div class="form-card"><label class="form-label">' + escapeHtml(field.label) +
                ' · <span id="fv-' + key + '">' + field.value + '</span></label>' +
                '<input class="form-range" type="range" min="0" max="10" step="1" id="f-' + key + '" ' +
                'data-field="' + key + '" value="' + field.value + '">' +
                '<div class="form-range-labels"><span>' + escapeHtml(field.low) + '</span>' +
                '<span>' + escapeHtml(field.high) + '</span></div></div>';
        }

        function renderNotesBlock(title, notes) {
            if (!notes || !notes.length) {
                return '<div class="note-item">' + escapeHtml('Пока пусто — появится из диалога') + '</div>';
            }
            return notes.slice(0, 5).map((note) =>
                '<div class="note-item">' + escapeHtml(note.body || '') + '</div>'
            ).join('');
        }

        function renderAgent() {
            const agent = appState.agent || {};
            const root = document.getElementById('panel-agent');
            const statusClass = agent.status && agent.status !== 'ok' ? ' status-' + agent.status : '';
            const avatar = agent.avatar_url
                ? '<img class="agent-avatar" src="' + escapeHtml(agent.avatar_url) + '" alt="AI">'
                : '<div class="agent-avatar"></div>';
            const form = agent.form;
            const topup = agent.topup || {};
            let formHtml = '';
            if (form && agent.editable) {
                formHtml =
                    renderSelectField('knowledge_band', form.knowledge_band) +
                    renderSelectField('hands_on', form.hands_on) +
                    renderSliderField('simplicity', form.simplicity) +
                    renderSliderField('verbosity', form.verbosity) +
                    renderSliderField('directness', form.directness) +
                    renderSliderField('initiative', form.initiative) +
                    '<div class="form-card"><label class="form-label" for="f-custom_instructions">' +
                    escapeHtml(form.custom_instructions.label) + '</label>' +
                    '<textarea class="form-textarea" id="f-custom_instructions" data-field="custom_instructions" ' +
                    'placeholder="' + escapeHtml(form.custom_instructions.placeholder || '') + '">' +
                    escapeHtml(form.custom_instructions.value || '') + '</textarea></div>' +
                    '<button class="form-save" id="agent-save" type="button"' +
                    (appState.savingAgent ? ' disabled' : '') + '>' +
                    (appState.savingAgent ? 'Сохраняем…' : 'Сохранить настройки') + '</button>' +
                    '<div class="save-toast" id="agent-toast">' + escapeHtml(appState.agentToast) + '</div>';
            }

            const topupBtn = topup.button_label
                ? '<button class="token-topup-btn" id="token-topup-open" type="button">' +
                  '<span><div class="token-topup-title">' + escapeHtml(topup.button_label) + '</div>' +
                  (topup.button_sub ? '<div class="token-topup-sub">' + escapeHtml(topup.button_sub) + '</div>' : '') +
                  '</span><span class="token-topup-chev">＋</span></button>'
                : '';

            root.innerHTML =
                '<div class="agent-card' + statusClass + '"><div class="agent-top">' + avatar +
                '<div><div class="agent-title">' + escapeHtml(agent.title || 'AI-ассистент') + '</div>' +
                '<div class="agent-subtitle">' + escapeHtml(agent.subtitle || '') + '</div>' +
                '<div class="agent-tokens-row"><span class="agent-token-val">⚡ ' +
                escapeHtml(agent.tokens_label || '—') + '</span>' +
                (agent.approx_replies_label ? '<span class="agent-token-meta">' +
                escapeHtml(agent.approx_replies_label) + '</span>' : '') + '</div>' +
                (agent.typical_spend_label ? '<div class="agent-token-meta">' +
                escapeHtml(agent.typical_spend_label) + '</div>' : '') +
                '</div></div>' + topupBtn +
                (agent.intro ? '<div class="agent-intro">' + escapeHtml(agent.intro) + '</div>' : '') +
                (agent.memory_hint ? '<div class="agent-intro" style="border-top:0;padding-top:0;margin-top:4px">' +
                escapeHtml(agent.memory_hint) + '</div>' : '') + '</div>' +
                '<div class="section-title">Настройки собеседника</div>' + formHtml +
                '<div class="section-title">Заметки агента</div>' +
                '<div class="form-card"><div class="form-label">О вас</div>' +
                renderNotesBlock('user', agent.notes?.user) + '</div>' +
                '<div class="form-card"><div class="form-label">О машине</div>' +
                renderNotesBlock('vehicle', agent.notes?.vehicle) + '</div>';

            root.querySelectorAll('.form-range').forEach((input) => {
                input.addEventListener('input', () => {
                    const label = document.getElementById('fv-' + input.dataset.field);
                    if (label) label.textContent = input.value;
                });
            });
            const saveBtn = document.getElementById('agent-save');
            if (saveBtn) saveBtn.addEventListener('click', saveAgentSettings);
            const topupOpen = document.getElementById('token-topup-open');
            if (topupOpen) topupOpen.addEventListener('click', openTokenTopup);
        }

        function openTokenTopup() {
            const topup = (appState.agent && appState.agent.topup) || {};
            const options = topup.options || [];
            let html = topup.sheet_intro
                ? '<p class="detail-lead">' + escapeHtml(topup.sheet_intro) + '</p>'
                : '';
            html += options.map((option) => {
                const chips = [];
                if (option.tokens_label) chips.push('<span class="topup-chip">' + escapeHtml(option.tokens_label) + '</span>');
                if (option.price_label) chips.push('<span class="topup-chip">' + escapeHtml(option.price_label) + '</span>');
                if (option.badge) chips.push('<span class="topup-chip soon">' + escapeHtml(option.badge) + '</span>');
                const disabled = option.enabled ? '' : ' disabled';
                return '<button class="topup-option" type="button" data-topup="' +
                    escapeHtml(option.key || '') + '"' + disabled + '>' +
                    '<div class="topup-ico">' + escapeHtml(option.icon || '⚡') + '</div>' +
                    '<div style="min-width:0;flex:1"><div class="topup-option-title">' +
                    escapeHtml(option.title || '') + '</div>' +
                    (option.subtitle ? '<div class="topup-option-sub">' + escapeHtml(option.subtitle) + '</div>' : '') +
                    (chips.length ? '<div class="topup-option-meta">' + chips.join('') + '</div>' : '') +
                    '</div></button>';
            }).join('');
            html += '<div class="topup-toast" id="topup-toast">' + escapeHtml(appState.topupToast || '') + '</div>';
            openDetailSheet(topup.sheet_title || 'Токены', html);
            document.querySelectorAll('[data-topup]').forEach((btn) => {
                btn.addEventListener('click', () => {
                    const option = options.find((row) => row.key === btn.dataset.topup);
                    if (!option) return;
                    if (option.action === 'mileage') {
                        openMileageSheet();
                        return;
                    }
                    if (!option.enabled || option.action === 'soon') {
                        appState.topupToast = topup.soon_toast || 'Этот способ скоро подключим';
                        const toast = document.getElementById('topup-toast');
                        if (toast) toast.textContent = appState.topupToast;
                        return;
                    }
                });
            });
        }

        function openMileageSheet() {
            const vehicle = activeVehicle();
            if (!vehicle || vehicle.status !== 'saved' || !vehicle.id) {
                openDetailSheet('Пробег', '<p class="hint">Сначала выберите сохранённый автомобиль в гараже.</p>');
                return;
            }
            const topup = (appState.agent && appState.agent.topup) || {};
            const mileage = topup.mileage || {};
            const currentRaw = vehicle.edit_profile?.mileage_value != null
                ? Number(vehicle.edit_profile.mileage_value)
                : (mileage.current_value != null ? Number(mileage.current_value) : 0);
            const current = Number.isFinite(currentRaw) && currentRaw >= 0 ? Math.round(currentRaw) : 0;
            const unit = vehicle.edit_profile?.mileage_unit || mileage.unit || 'km';
            const bonusLine = mileage.available
                ? ('Бонус ' + (mileage.reward_label || '') + ' токенов после сохранения (начисление — следующим шагом). Далее не раньше чем через ' + (mileage.cooldown_hours || 24) + ' ч.')
                : (mileage.available_label
                    ? ('Пробег сохранится. ' + mileage.available_label + '.')
                    : 'Пробег сохранится в карточке и журнале.');
            const digits = mileageDigitsFromValue(current);
            const html =
                '<p class="mileage-form-hint">Крутите цифры одометра — без клавиатуры телефона, экран не прыгает.</p>' +
                '<p class="mileage-form-hint">' + escapeHtml(bonusLine) + '</p>' +
                '<div class="odo-value-label" id="odo-value-label">' +
                escapeHtml(formatOdoValue(digits) + (unit === 'mi' ? ' миль' : ' км')) + '</div>' +
                '<div class="odo-wrap" id="mileage-odo" data-unit="' + escapeHtml(unit) + '">' +
                digits.map((digit, index) =>
                    '<div class="odo-col" data-i="' + index + '">' +
                    '<button type="button" class="odo-btn" data-odo-dir="up" aria-label="Больше">▴</button>' +
                    '<div class="odo-digit" data-odo-digit="' + index + '">' + digit + '</div>' +
                    '<button type="button" class="odo-btn" data-odo-dir="down" aria-label="Меньше">▾</button>' +
                    '</div>'
                ).join('') +
                '</div>' +
                '<button class="form-save" id="mileage-quick-save" type="button">Сохранить пробег</button>' +
                '<div class="save-toast" id="mileage-quick-toast"></div>';
            openDetailSheet('Обновить пробег', html);
            bindOdometerControls();
            const saveBtn = document.getElementById('mileage-quick-save');
            if (saveBtn) saveBtn.addEventListener('click', saveMileageQuick);
        }

        function mileageDigitsFromValue(value) {
            const safe = Math.max(0, Math.min(9999999, Math.round(Number(value) || 0)));
            const width = safe >= 1000000 ? 7 : 6;
            return String(safe).padStart(width, '0').split('').map((ch) => Number(ch));
        }

        function formatOdoValue(digits) {
            const raw = (digits || []).join('');
            const n = Number(raw || '0');
            return Number.isFinite(n) ? n.toLocaleString('ru-RU') : '0';
        }

        function readOdometerDigits() {
            return Array.from(document.querySelectorAll('[data-odo-digit]')).map((el) => {
                const n = Number(el.textContent || '0');
                return Number.isFinite(n) ? Math.max(0, Math.min(9, n)) : 0;
            });
        }

        function refreshOdometerLabel() {
            const label = document.getElementById('odo-value-label');
            const root = document.getElementById('mileage-odo');
            if (!label || !root) return;
            const unit = root.dataset.unit === 'mi' ? ' миль' : ' км';
            label.textContent = formatOdoValue(readOdometerDigits()) + unit;
        }

        function bindOdometerControls() {
            const root = document.getElementById('mileage-odo');
            if (!root) return;
            root.querySelectorAll('[data-odo-dir]').forEach((btn) => {
                btn.addEventListener('click', (event) => {
                    event.preventDefault();
                    const col = btn.closest('.odo-col');
                    const digitEl = col && col.querySelector('[data-odo-digit]');
                    if (!digitEl) return;
                    let value = Number(digitEl.textContent || '0');
                    if (!Number.isFinite(value)) value = 0;
                    if (btn.dataset.odoDir === 'up') value = (value + 1) % 10;
                    else value = (value + 9) % 10;
                    digitEl.textContent = String(value);
                    refreshOdometerLabel();
                });
            });
        }

        async function saveMileageQuick() {
            const vehicle = activeVehicle();
            const toast = document.getElementById('mileage-quick-toast');
            const saveBtn = document.getElementById('mileage-quick-save');
            if (!vehicle || !vehicle.id) return;
            const digits = readOdometerDigits();
            if (!digits.length) {
                if (toast) toast.textContent = 'Не удалось прочитать одометр';
                return;
            }
            const value = Number(digits.join(''));
            if (!Number.isFinite(value) || value < 0) {
                if (toast) toast.textContent = 'Введите корректный пробег';
                return;
            }
            if (saveBtn) saveBtn.disabled = true;
            if (toast) toast.textContent = 'Сохраняем…';
            try {
                const res = await fetch(apiBase + '/vehicle', {
                    method: 'PATCH',
                    headers: apiHeaders,
                    body: JSON.stringify({
                        vehicle_id: vehicle.id,
                        version: vehicle.version,
                        mileage: {
                            value: Math.round(value),
                            unit: vehicle.edit_profile?.mileage_unit || 'km',
                        },
                    }),
                });
                if (!res.ok) throw new Error('save failed');
                if (toast) toast.textContent = 'Пробег обновлён';
                await loadState();
                closeHelp();
            } catch (e) {
                if (toast) toast.textContent = 'Не удалось сохранить. Пробег не должен уменьшаться без причины.';
                if (saveBtn) saveBtn.disabled = false;
            }
        }

        async function saveAgentSettings() {
            if (appState.savingAgent) return;
            appState.savingAgent = true;
            appState.agentToast = '';
            renderAgent();
            try {
                const skillBody = {
                    knowledge_band: document.getElementById('f-knowledge_band')?.value,
                    hands_on: document.getElementById('f-hands_on')?.value,
                };
                const prefsBody = {
                    simplicity: Number(document.getElementById('f-simplicity')?.value ?? 5),
                    verbosity: Number(document.getElementById('f-verbosity')?.value ?? 5),
                    directness: Number(document.getElementById('f-directness')?.value ?? 5),
                    initiative: Number(document.getElementById('f-initiative')?.value ?? 5),
                    custom_instructions: document.getElementById('f-custom_instructions')?.value?.trim() || null,
                };
                const skillRes = await fetch(apiBase + '/agent/skill', {
                    method: 'PATCH', headers: apiHeaders, body: JSON.stringify(skillBody),
                });
                const prefsRes = await fetch(apiBase + '/agent/preferences', {
                    method: 'PATCH', headers: apiHeaders, body: JSON.stringify(prefsBody),
                });
                if (!skillRes.ok || !prefsRes.ok) throw new Error('save failed');
                await loadState();
                appState.agentToast = 'Настройки сохранены';
            } catch (e) {
                appState.agentToast = 'Не удалось сохранить';
            } finally {
                appState.savingAgent = false;
                renderAgent();
            }
        }

        function renderHelp() {
            const help = appState.help || {};
            document.getElementById('help-title').textContent = help.title || 'Подсказка';
            document.getElementById('help-content').innerHTML = (help.sections || []).map((section) =>
                '<div class="passport-section"><div class="passport-title">' + escapeHtml(section.title) +
                '</div><p class="garage-hint" style="margin-bottom:10px">' + escapeHtml(section.body) + '</p></div>'
            ).join('');
        }

        function openDetailSheet(title, html) {
            document.getElementById('help-title').textContent = title || 'Подсказка';
            document.getElementById('help-content').innerHTML = html || '';
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('help-sheet').classList.add('open');
        }

        function openHelp() {
            renderHelp();
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('help-sheet').classList.add('open');
        }

        function closeHelp() {
            document.getElementById('help-sheet').classList.remove('open');
            if (!anySheetOpen()) {
                document.getElementById('sheet-backdrop').classList.remove('open');
            }
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
            let html = '<p class="garage-hint">Выберите авто для AI, состояния, плана и журнала.</p>';

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

            if (vehicle.editable && vehicle.edit_profile && appState.passportEditing) {
                const p = vehicle.edit_profile;
                html += '<div class="passport-edit-grid">' +
                    '<div class="form-card"><label class="form-label">Марка</label>' +
                    '<input class="form-select" id="pe-make" value="' + escapeHtml(p.make || '') + '"></div>' +
                    '<div class="form-card"><label class="form-label">Модель</label>' +
                    '<input class="form-select" id="pe-model" value="' + escapeHtml(p.model || '') + '"></div>' +
                    '<div class="form-card"><label class="form-label">Год выпуска</label>' +
                    '<input class="form-select" id="pe-year" type="number" value="' +
                    escapeHtml(p.production_year != null ? String(p.production_year) : '') + '"></div>' +
                    '<div class="form-card"><label class="form-label">Пробег (км)</label>' +
                    '<input class="form-select" id="pe-mileage" type="number" value="' +
                    escapeHtml(p.mileage_value != null ? String(p.mileage_value) : '') + '"></div>' +
                    '<div class="form-card"><label class="form-label">VIN</label>' +
                    '<input class="form-select" id="pe-vin" value="' + escapeHtml(p.vin || '') + '"></div>' +
                    '</div>' +
                    '<button class="form-save" id="passport-save" type="button"' +
                    (appState.savingVehicle ? ' disabled' : '') + '>' +
                    (appState.savingVehicle ? 'Сохраняем…' : 'Сохранить') + '</button>' +
                    (appState.vehicleToast ? '<div class="save-toast">' + escapeHtml(appState.vehicleToast) + '</div>' : '');
            } else {
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
            }

            html += '<div class="vehicle-actions">';
            if (vehicle.editable && vehicle.status === 'saved') {
                html += '<button class="btn btn-ghost" type="button" id="passport-edit">' +
                    (appState.passportEditing ? 'Отмена' : 'Редактировать') + '</button>';
            }
            html += '<button class="btn btn-primary" type="button" id="passport-select"' +
                (key === appState.activeVehicleKey ? ' disabled' : '') + '>' +
                (key === appState.activeVehicleKey ? '✓ Активна для AI' : 'Выбрать для AI') + '</button></div>';

            setTimeout(() => {
                const editBtn = document.getElementById('passport-edit');
                if (editBtn) editBtn.addEventListener('click', () => {
                    appState.passportEditing = !appState.passportEditing;
                    appState.vehicleToast = '';
                    renderGarageSheet();
                });
                const saveBtn = document.getElementById('passport-save');
                if (saveBtn) saveBtn.addEventListener('click', () => saveVehicleProfile(key));
                const btn = document.getElementById('passport-select');
                if (btn && !btn.disabled) btn.addEventListener('click', () => selectVehicle(key));
            }, 0);
            return html;
        }

        async function saveVehicleProfile(key) {
            const vehicle = vehicleByKey(key);
            if (!vehicle || !vehicle.id || appState.savingVehicle) return;
            appState.savingVehicle = true;
            appState.vehicleToast = '';
            renderGarageSheet();
            try {
                const body = {
                    vehicle_id: vehicle.id,
                    version: vehicle.version,
                    make: document.getElementById('pe-make')?.value?.trim(),
                    model: document.getElementById('pe-model')?.value?.trim(),
                };
                const year = document.getElementById('pe-year')?.value?.trim();
                if (year) body.production_year = Number(year);
                const mileage = document.getElementById('pe-mileage')?.value?.trim();
                if (mileage) body.mileage = { value: Number(mileage), unit: vehicle.edit_profile?.mileage_unit || 'km' };
                const vin = document.getElementById('pe-vin')?.value?.trim();
                if (vin) body.vin = vin.toUpperCase();
                const res = await fetch(apiBase + '/vehicle', {
                    method: 'PATCH', headers: apiHeaders, body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error('save failed');
                appState.passportEditing = false;
                appState.vehicleToast = 'Сохранено';
                await loadState();
                appState.garageView = 'detail';
                appState.garageDetailKey = key;
                openGarage();
            } catch (e) {
                appState.vehicleToast = 'Не удалось сохранить';
            } finally {
                appState.savingVehicle = false;
                if (appState.garageView === 'detail') renderGarageSheet();
            }
        }

        function selectVehicle(key) {
            appState.activeVehicleKey = key;
            localStorage.setItem('ad_active_vehicle', key);
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            closeGarage();
            loadState();
        }

        function openVehicleDetail(key) {
            appState.garageView = 'detail';
            appState.garageDetailKey = key;
            appState.passportEditing = false;
            appState.vehicleToast = '';
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

        function isUnitTouched(item) {
            return !!(item.filled
                || item.last_service
                || (item.history && item.history.length));
        }

        function renderUnitCard(item) {
            const status = item.status || 'unknown';
            const pct = metricPercent(item);
            const color = statusColor(status);
            const barWidth = pct == null ? 8 : Math.max(4, pct);
            const pctLabel = pct == null ? '—' : (pct + '%');
            const last = item.last_service ? escapeHtml(item.last_service) : '—';
            const next = item.next_due ? escapeHtml(item.next_due) : '—';
            const hasHistory = item.history && item.history.length;
            const untouched = !isUnitTouched(item);
            return '<article class="unit-card status-' + status + (untouched ? ' untouched' : '') + '"' +
                (hasHistory ? ' data-unit="' + escapeHtml(item.key) + '"' : '') + '>' +
                '<div class="unit-name">' + escapeHtml(item.label) + '</div>' +
                '<div class="unit-bar-row">' +
                '<div class="unit-bar"><span style="width:' + barWidth + '%;background:' + color + '"></span></div>' +
                '<div class="unit-pct" style="color:' + color + '">' + pctLabel + '</div></div>' +
                '<div class="unit-meta">' + escapeHtml(metricCaption(item)) + '</div>' +
                '<div class="unit-fact">Было: ' + last + '</div>' +
                '<div class="unit-fact"><strong>Далее:</strong> ' + next + '</div>' +
                (hasHistory ? '<div class="unit-fact">История →</div>' : '') +
                '</article>';
        }

        function renderState() {
            const items = activeVehicle()?.tabs?.state || [];
            const root = document.getElementById('panel-state');
            if (!items.length) {
                root.innerHTML = '<p class="hint">Нет данных по узлам. Расскажите боту про обслуживание.</p>';
                return;
            }
            const touched = items.filter(isUnitTouched);
            const untouched = items.filter((item) => !isUnitTouched(item));
            let html = '';
            if (touched.length) {
                html += '<div class="section-title">С данными</div><div class="state-grid">' +
                    touched.map(renderUnitCard).join('') + '</div>';
            }
            if (touched.length && untouched.length) {
                html += '<div class="state-divider">ещё не заполняли</div>';
            } else if (untouched.length && !touched.length) {
                html += '<div class="section-title">Ещё не заполняли</div>';
            }
            if (untouched.length) {
                html += '<div class="state-grid">' + untouched.map(renderUnitCard).join('') + '</div>';
            }
            root.innerHTML = html;
            root.querySelectorAll('[data-unit]').forEach((card) => {
                card.addEventListener('click', () => openUnitHistory(card.dataset.unit));
            });
        }

        function anySheetOpen() {
            return document.getElementById('garage-sheet').classList.contains('open')
                || document.getElementById('help-sheet').classList.contains('open')
                || document.getElementById('history-sheet').classList.contains('open')
                || document.getElementById('profile-sheet').classList.contains('open');
        }

        function openProfile() {
            const user = appState.user || {};
            document.getElementById('profile-title').textContent = user.title || 'Профиль';
            const rows = [
                ['Имя', user.first_name || user.display_name || '—'],
                ['Никнейм', user.username ? ('@' + user.username) : '—'],
                ['Telegram ID', user.telegram_id != null ? String(user.telegram_id) : '—'],
            ];
            document.getElementById('profile-content').innerHTML =
                '<p class="garage-hint" style="margin-bottom:8px">Данные аккаунта Telegram. Настройки темы появятся позже.</p>' +
                rows.map((row) =>
                    '<div class="profile-row"><div class="profile-label">' + escapeHtml(row[0]) +
                    '</div><div class="profile-value">' + escapeHtml(row[1]) + '</div></div>'
                ).join('');
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('profile-sheet').classList.add('open');
        }

        function closeProfile() {
            document.getElementById('profile-sheet').classList.remove('open');
            if (!anySheetOpen()) {
                document.getElementById('sheet-backdrop').classList.remove('open');
            }
        }

        function openUnitHistory(workCode) {
            const item = (activeVehicle()?.tabs?.state || []).find((row) => row.key === workCode);
            if (!item) return;
            document.getElementById('history-title').textContent = item.label || 'История';
            const history = item.history || [];
            document.getElementById('history-content').innerHTML = history.length
                ? history.map((row) =>
                    '<div class="history-item"><div class="tl-check">✓</div><div>' +
                    '<div class="history-item-date">' + escapeHtml(row.date || '—') + '</div>' +
                    '<div class="history-item-meta">' +
                    escapeHtml([row.mileage_label, 'выполнено'].filter(Boolean).join(' · ')) +
                    '</div></div></div>'
                ).join('')
                : '<p class="hint">Пока нет записей по этому узлу.</p>';
            document.getElementById('sheet-backdrop').classList.add('open');
            document.getElementById('history-sheet').classList.add('open');
        }

        function closeHistory() {
            document.getElementById('history-sheet').classList.remove('open');
            if (!anySheetOpen()) {
                document.getElementById('sheet-backdrop').classList.remove('open');
            }
        }

        function renderNavTokens() {
            document.getElementById('nav-tokens').textContent = (appState.agent && appState.agent.tokens_label) || '—';
        }

        function renderTab() {
            if (appState.tab === 'allowlist' && !appState.isOwner) {
                appState.tab = 'state';
            }
            document.querySelectorAll('.panel').forEach((el) => el.classList.remove('active'));
            const panel = document.getElementById('panel-' + appState.tab);
            if (panel) panel.classList.add('active');
            document.querySelectorAll('.nav-btn').forEach((btn) => {
                btn.classList.toggle('active', btn.dataset.tab === appState.tab);
            });
            document.getElementById('bottom-nav').classList.toggle('admin-mode', !!appState.isOwner);
            if (appState.tab === 'allowlist') loadWriters(false);
        }

        function renderAll() {
            renderHeader();
            renderGarageSheet();
            renderState();
            renderRoadmap();
            renderJournal();
            renderAnalytics();
            renderAllowlist();
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
            appState.passportEditing = false;
            appState.vehicleToast = '';
            document.getElementById('garage-sheet').classList.remove('open');
            if (!anySheetOpen()) {
                document.getElementById('sheet-backdrop').classList.remove('open');
            }
        }

        document.getElementById('garage-open').addEventListener('click', openGarage);
        document.getElementById('garage-close').addEventListener('click', closeGarage);
        document.getElementById('help-open').addEventListener('click', openHelp);
        document.getElementById('help-close').addEventListener('click', closeHelp);
        document.getElementById('history-close').addEventListener('click', closeHistory);
        document.getElementById('user-avatar').addEventListener('click', openProfile);
        document.getElementById('profile-close').addEventListener('click', closeProfile);
        document.getElementById('garage-back').addEventListener('click', () => {
            appState.garageView = 'list';
            appState.garageDetailKey = null;
            appState.passportEditing = false;
            appState.vehicleToast = '';
            renderGarageSheet();
        });
        document.getElementById('sheet-backdrop').addEventListener('click', () => {
            closeGarage();
            closeHelp();
            closeHistory();
            closeProfile();
        });
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

        async function loadState() {
            try {
                const response = await fetch(stateUrl(), {
                    headers: { 'X-Telegram-Init-Data': initData, 'Accept': 'application/json' },
                });
                const data = await response.json();
                if (data.user && data.user.initial) {
                    document.getElementById('user-avatar').textContent = data.user.initial;
                }
                appState.user = data.user || {};
                appState.isOwner = !!data.is_owner;
                if (!appState.isOwner) {
                    appState.writers = [];
                    appState.writersLoaded = false;
                    if (appState.tab === 'allowlist') appState.tab = 'state';
                }
                appState.vehicles = data.vehicles || [];
                appState.agent = data.agent || {};
                appState.garage = data.garage || {};
                appState.help = data.help || {};
                const storedVehicle = localStorage.getItem('ad_active_vehicle');
                const defaultKey = data.active_vehicle_id != null
                    ? String(data.active_vehicle_id)
                    : vehicleKey(appState.vehicles[0], 0);
                const keys = appState.vehicles.map((v, i) => vehicleKey(v, i));
                if (!keys.includes(appState.activeVehicleKey)) {
                    appState.activeVehicleKey = keys.includes(storedVehicle) ? storedVehicle : defaultKey;
                } else if (appState.activeVehicleKey === null) {
                    appState.activeVehicleKey = keys.includes(storedVehicle) ? storedVehicle : defaultKey;
                }
                renderAll();
            } catch (e) {
                document.getElementById('panel-state').innerHTML =
                    '<p class="hint">Не удалось загрузить данные.</p>';
            }
        }

        appState.tab = localStorage.getItem('ad_active_tab') || 'state';
        loadState();
    </script>
</body>
</html>
