let alertLimit = 20;

// ⚡ Cache del último valor pintado por campo: evita reescribir el DOM cuando el
// valor entrante es idéntico al ya mostrado (reduce reflow/paint innecesarios).
let lastState = {};
let lastBlink = {};
let lastFade = {};
let lastOxVisible = null;
let lastWpVisible = null;
let lastVoiceTalking = null;
let lastArmorVisible = null;

// Flags de comportamiento controlados por Config/menú
let showArmorFeature = true;
let showOxygenFeature = true;
let smartFadeEnabled = true;
let autoHideArmorFeature = true;
let showZoneFeature = true;
let distanceUnit = 'metric';
let alertSoundEnabled = true;
let alertSoundVolume = 0.4;

// Estado del menú de ajustes
let menuStrings = {};
let currentSettings = {};
let factoryDefaults = {};

function setTextIfChanged(id, key, value) {
    if (value === undefined || value === null) return;
    if (lastState[key] === value) return;
    lastState[key] = value;
    const el = document.getElementById(id);
    if (el) el.innerText = value;
}

function toggleAlertBlink(elementId, shouldBlink) {
    if (lastBlink[elementId] === shouldBlink) return;
    lastBlink[elementId] = shouldBlink;
    let el = document.getElementById(elementId);
    if (el) { if (shouldBlink) el.classList.add('blink-hud-alert'); else el.classList.remove('blink-hud-alert'); }
}

function toggleFade(elementId, faded) {
    if (lastFade[elementId] === faded) return;
    lastFade[elementId] = faded;
    let el = document.getElementById(elementId);
    if (el) el.classList.toggle('hud-faded', faded);
}

function setVisibility(id, visible) {
    const el = document.getElementById(id);
    if (el) el.style.display = visible ? 'flex' : 'none';
}

// ============================================================
// 🔊 ALERTA SONORA — sintetizada con Web Audio, sin necesidad de assets .mp3/.wav
// ============================================================
let audioCtx = null;
let lastBeepTime = 0;
const BEEP_COOLDOWN_MS = 6000;

function playAlertBeep() {
    if (!alertSoundEnabled || alertSoundVolume <= 0) return;
    const now = performance.now();
    if (now - lastBeepTime < BEEP_COOLDOWN_MS) return;
    lastBeepTime = now;

    try {
        if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'sine';
        osc.frequency.value = 880;
        gain.gain.value = 0;
        osc.connect(gain);
        gain.connect(audioCtx.destination);

        const t = audioCtx.currentTime;
        gain.gain.setValueAtTime(0, t);
        gain.gain.linearRampToValueAtTime(alertSoundVolume * 0.5, t + 0.02);
        gain.gain.linearRampToValueAtTime(0, t + 0.18);

        osc.start(t);
        osc.stop(t + 0.2);
    } catch (e) { /* AudioContext no disponible: fallamos en silencio */ }
}

// ============================================================
// 📐 APLICACIÓN DE LAYOUT / VISIBILIDAD / TEMA — usado tanto en la
// primera carga ("show") como en la previsualización en vivo del menú
// ============================================================
function applySettings(s) {
    const container = document.getElementById('d87-hud');
    const finContainer = document.getElementById('d87-finance');
    const compassContainer = document.getElementById('d87-compass-box');
    const wrapper = document.getElementById('d87-hud-wrapper');

    if (s.size) container.style.transform = `scale(${s.size})`;
    if (s.statsBottom !== undefined) container.style.bottom = `${s.statsBottom}px`;
    if (s.statsLeft !== undefined) container.style.left = `${s.statsLeft}%`;

    if (s.compassBottom !== undefined) compassContainer.style.bottom = `${s.compassBottom}px`;
    if (s.compassLeft !== undefined) compassContainer.style.left = `${s.compassLeft}%`;

    if (s.topRightSize) finContainer.style.transform = `scale(${s.topRightSize})`;
    if (s.topMargin !== undefined) finContainer.style.top = `${s.topMargin}px`;
    if (s.rightMargin !== undefined) finContainer.style.right = `${s.rightMargin}px`;

    alertLimit = s.alertLimit !== undefined ? s.alertLimit : alertLimit;
    alertSoundEnabled = !!s.alertSound;
    alertSoundVolume = s.alertSoundVolume !== undefined ? s.alertSoundVolume : alertSoundVolume;
    distanceUnit = s.distanceUnit || 'metric';
    smartFadeEnabled = !!s.smartFadeOut;
    autoHideArmorFeature = !!s.autoHideArmor;
    showZoneFeature = !!s.showZone;
    showOxygenFeature = !!s.showOxygen;
    showArmorFeature = !!s.showArmor;

    wrapper.classList.remove('theme-blue', 'theme-red');
    if (s.theme === 'blue') wrapper.classList.add('theme-blue');
    else if (s.theme === 'red') wrapper.classList.add('theme-red');
    wrapper.classList.toggle('compact-mode', !!s.compactMode);

    setVisibility('stat-health', s.showHealth);
    setVisibility('stat-hunger', s.showHunger);
    setVisibility('stat-thirst', s.showThirst);
    setVisibility('stat-stress', s.showStress);
    setVisibility('stat-stamina', s.showStamina);
    setVisibility('stat-sleep', s.showSleep);
    setVisibility('stat-voice', s.showVoice);
    setVisibility('fin-cash', s.showCash);
    setVisibility('fin-bank', s.showBank);
    setVisibility('fin-job', s.showJob);
    compassContainer.style.display = (s.showCompass || s.showTime) ? 'flex' : 'none';

    // La armadura respeta además el auto-hide: si está desactivada globalmente, siempre oculta
    if (!showArmorFeature) {
        setVisibility('stat-armor', false);
        lastArmorVisible = false;
    } else if (!autoHideArmorFeature) {
        setVisibility('stat-armor', true);
        lastArmorVisible = true;
    }
    // Si autoHideArmor está activo, la visibilidad real la decide el handler de "update" según el valor de armadura
}

function formatDistance(meters, forVoice) {
    if (distanceUnit === 'imperial') {
        const feet = Math.round(meters * 3.28084);
        return feet + "ft";
    }
    return meters + "M";
}

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "show") {
        let wrapper = document.getElementById('d87-hud-wrapper');
        wrapper.style.display = 'block';

        let wpContainer = document.getElementById('stat-waypoint');
        let voiceContainer = document.getElementById('stat-voice');

        if (data.wpBottom) wpContainer.style.bottom = `${data.wpBottom}px`;
        if (data.wpLeft) wpContainer.style.left = `${data.wpLeft}%`;

        if (data.voiceBottom) voiceContainer.style.bottom = `${data.voiceBottom}px`;
        if (data.voiceRight) {
            voiceContainer.style.left = 'auto';
            voiceContainer.style.right = `${data.voiceRight}px`;
        }

        if (data.loadingStreet) document.getElementById('val-street').innerText = data.loadingStreet;

        document.getElementById('stat-id').style.display = 'flex';
        wpContainer.style.display = 'none';

        applySettings(data);
        currentSettings = Object.assign({}, data);

        // ⚡ Reiniciamos las cachés de estado al reabrir el HUD para forzar el primer pintado
        lastState = {};
        lastBlink = {};
        lastFade = {};
        lastOxVisible = null;
        lastWpVisible = null;
        lastVoiceTalking = null;
    }

    else if (data.action === "hide") {
        document.getElementById('d87-hud-wrapper').style.display = 'none';
    }

    else if (data.action === "update_finance") {
        if (data.cash !== undefined) setTextIfChanged('val-cash', 'cash', "$" + data.cash.toLocaleString('es-ES'));
        if (data.bank !== undefined) setTextIfChanged('val-bank', 'bank', "$" + data.bank.toLocaleString('es-ES'));
        if (data.job) {
            let gradeText = data.grade ? ` (${data.grade})` : "";
            setTextIfChanged('val-job', 'job', data.job + gradeText);
        }
    }

    else if (data.action === "toggleMenu") {
        menuStrings = data.strings || {};
        factoryDefaults = data.defaults || {};
        openSettingsMenu(data.settings || {}, data.open);
    }

    else if (data.action === "update") {
        setTextIfChanged('val-id', 'id', data.playerId);
        setTextIfChanged('val-compass', 'compass', data.compass);
        setTextIfChanged('val-street', 'street', data.street);
        setTextIfChanged('val-time', 'time', data.time);

        // 🗺️ Nombre de zona
        let zoneEl = document.getElementById('val-zone');
        if (zoneEl) {
            if (showZoneFeature && data.zone) {
                setTextIfChanged('val-zone', 'zone', data.zone);
                zoneEl.style.display = 'block';
            } else {
                zoneEl.style.display = 'none';
            }
        }

        // 📍 Lógica reactiva de la caja de ruta
        let wpBox = document.getElementById('stat-waypoint');
        if (wpBox) {
            if (data.wpActive) {
                if (lastWpVisible !== true) { wpBox.style.display = 'flex'; lastWpVisible = true; }
                setTextIfChanged('val-waypoint', 'waypoint', data.wpDistance);
            } else if (lastWpVisible !== false) {
                wpBox.style.display = 'none';
                lastWpVisible = false;
            }
        }

        if (data.voiceDist !== undefined) {
            setTextIfChanged('val-voice', 'voiceDist', formatDistance(data.voiceDist));
            if (lastVoiceTalking !== data.talking) {
                lastVoiceTalking = data.talking;
                let vIcon = document.getElementById('icon-voice');
                if (vIcon) {
                    if (data.talking) vIcon.classList.add('voice-talking-active');
                    else vIcon.classList.remove('voice-talking-active');
                }
            }
        }

        let oxBox = document.getElementById('stat-oxygen');
        if (showOxygenFeature && data.diving) {
            if (lastOxVisible !== true) { oxBox.style.display = 'flex'; lastOxVisible = true; }
            setTextIfChanged('val-oxygen', 'oxygen', data.oxygen);
            let oxAlert = data.oxygen <= 25;
            toggleAlertBlink('stat-oxygen', oxAlert);
            if (oxAlert) playAlertBeep();
        } else if (lastOxVisible !== false) {
            oxBox.style.display = 'none';
            lastOxVisible = false;
        }

        setTextIfChanged('val-health', 'health', data.health);
        let healthAlert = data.health <= alertLimit;
        toggleAlertBlink('stat-health', healthAlert);
        if (healthAlert) playAlertBeep();

        setTextIfChanged('val-armor', 'armor', data.armor);
        // 🛡️ Auto-hide de armadura: la caja desaparece por completo si no llevas chaleco
        if (showArmorFeature) {
            let shouldShowArmor = !autoHideArmorFeature || data.armor > 0;
            if (lastArmorVisible !== shouldShowArmor) {
                lastArmorVisible = shouldShowArmor;
                setVisibility('stat-armor', shouldShowArmor);
            }
        }

        setTextIfChanged('val-hunger', 'hunger', data.hunger);
        toggleAlertBlink('stat-hunger', data.hunger <= alertLimit);
        // ✨ Smart Fade Out: hambre/sed se ocultan solas cuando el personaje está saciado (>95%)
        toggleFade('stat-hunger', smartFadeEnabled && data.hunger >= 95);

        setTextIfChanged('val-thirst', 'thirst', data.thirst);
        toggleAlertBlink('stat-thirst', data.thirst <= alertLimit);
        toggleFade('stat-thirst', smartFadeEnabled && data.thirst >= 95);

        setTextIfChanged('val-stress', 'stress', data.stress);
        toggleAlertBlink('stat-stress', data.stress >= 80);

        setTextIfChanged('val-stamina', 'stamina', data.stamina);
        toggleAlertBlink('stat-stamina', data.stamina <= alertLimit);

        setTextIfChanged('val-sleep', 'sleep', data.sleep);
        toggleAlertBlink('stat-sleep', data.sleep <= alertLimit);
    }
});

// ============================================================
// 🧩 MENÚ DE AJUSTES EN VIVO
// ============================================================
function postNUI(name, payload) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload || {})
    }).catch(() => {});
}

const VISIBILITY_ITEMS = [
    { key: 'showHealth', labelKey: 'visHealth' },
    { key: 'showArmor', labelKey: 'visArmor' },
    { key: 'showHunger', labelKey: 'visHunger' },
    { key: 'showThirst', labelKey: 'visThirst' },
    { key: 'showStress', labelKey: 'visStress' },
    { key: 'showStamina', labelKey: 'visStamina' },
    { key: 'showSleep', labelKey: 'visSleep' },
    { key: 'showVoice', labelKey: 'visVoice' },
    { key: 'showOxygen', labelKey: 'visOxygen' },
    { key: 'showCompass', labelKey: 'visCompass' },
    { key: 'showTime', labelKey: 'visTime' },
    { key: 'showCash', labelKey: 'visCash' },
    { key: 'showBank', labelKey: 'visBank' },
    { key: 'showJob', labelKey: 'visJob' }
];

const SLIDER_FIELDS = [
    'size', 'topRightSize', 'statsBottom', 'statsLeft',
    'compassBottom', 'compassLeft', 'topMargin', 'rightMargin',
    'alertLimit', 'alertSoundVolume'
];

let menuInitialized = false;
let workingSettings = {};
let snapshotSettings = {};

function initMenuStaticText() {
    const map = {
        'menu-title': 'title', 'tab-layout': 'tabLayout', 'tab-visibility': 'tabVisibility',
        'tab-alerts': 'tabAlerts', 'tab-appearance': 'tabAppearance',
        'lbl-hud-scale': 'hudScale', 'lbl-fin-scale': 'finScale',
        'lbl-section-stats': 'sectionStats', 'lbl-stats-bottom': 'statsBottom', 'lbl-stats-left': 'statsLeft',
        'lbl-section-compass': 'sectionCompass', 'lbl-compass-bottom': 'compassBottom', 'lbl-compass-left': 'compassLeft',
        'lbl-section-finance': 'sectionFinance', 'lbl-top-margin': 'topMargin', 'lbl-right-margin': 'rightMargin',
        'lbl-alert-percent': 'alertPercent', 'lbl-alert-sound': 'alertSound', 'lbl-alert-volume': 'alertVolume',
        'lbl-theme': 'theme', 'lbl-compact': 'compact', 'lbl-smart-fade': 'smartFade',
        'lbl-show-zone': 'showZone', 'lbl-units': 'units',
        'menu-reset': 'btnReset', 'menu-save': 'btnSave'
    };
    Object.keys(map).forEach(id => {
        const el = document.getElementById(id);
        if (el && menuStrings[map[id]]) el.innerText = menuStrings[map[id]];
    });

    const themeSelect = document.getElementById('opt-theme');
    if (themeSelect && themeSelect.options.length === 3) {
        themeSelect.options[0].text = menuStrings.themePurple || themeSelect.options[0].text;
        themeSelect.options[1].text = menuStrings.themeBlue || themeSelect.options[1].text;
        themeSelect.options[2].text = menuStrings.themeRed || themeSelect.options[2].text;
    }
    const unitSelect = document.getElementById('opt-distanceUnit');
    if (unitSelect && unitSelect.options.length === 2) {
        unitSelect.options[0].text = menuStrings.unitMetric || unitSelect.options[0].text;
        unitSelect.options[1].text = menuStrings.unitImperial || unitSelect.options[1].text;
    }

    // Construimos la cuadrícula de visibilidad dinámicamente
    const grid = document.getElementById('visibility-grid');
    if (grid && grid.childElementCount === 0) {
        VISIBILITY_ITEMS.forEach(item => {
            const row = document.createElement('div');
            row.className = 'menu-row menu-row-toggle';
            row.innerHTML = `<label>${menuStrings[item.labelKey] || item.key}</label><input type="checkbox" id="opt-${item.key}">`;
            grid.appendChild(row);
            const input = row.querySelector('input');
            input.addEventListener('change', () => {
                workingSettings[item.key] = input.checked;
                applySettings(workingSettings);
            });
        });
    }

    document.querySelectorAll('.menu-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.menu-tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.menu-panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.querySelector(`.menu-panel[data-panel="${tab.dataset.tab}"]`).classList.add('active');
        });
    });

    SLIDER_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (!input) return;
        input.addEventListener('input', () => {
            const value = parseFloat(input.value);
            workingSettings[key] = value;
            const valEl = document.getElementById(`val-opt-${key}`);
            if (valEl) valEl.innerText = value;
            applySettings(workingSettings);
        });
    });

    const themeInput = document.getElementById('opt-theme');
    if (themeInput) themeInput.addEventListener('change', () => {
        workingSettings.theme = themeInput.value;
        applySettings(workingSettings);
    });
    const unitInput = document.getElementById('opt-distanceUnit');
    if (unitInput) unitInput.addEventListener('change', () => {
        workingSettings.distanceUnit = unitInput.value;
        applySettings(workingSettings);
    });

    ['alertSound', 'compactMode', 'smartFadeOut', 'showZone'].forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (!input) return;
        input.addEventListener('change', () => {
            workingSettings[key] = input.checked;
            applySettings(workingSettings);
        });
    });

    document.getElementById('menu-close').addEventListener('click', () => closeSettingsMenu(false));
    document.getElementById('menu-save').addEventListener('click', () => closeSettingsMenu(true));
    document.getElementById('menu-reset').addEventListener('click', () => {
        workingSettings = Object.assign({}, factoryDefaults);
        populateMenuInputs(workingSettings);
        applySettings(workingSettings);
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && document.getElementById('d87-menu-overlay').style.display !== 'none') {
            closeSettingsMenu(false);
        }
    });

    menuInitialized = true;
}

function populateMenuInputs(s) {
    SLIDER_FIELDS.forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (input && s[key] !== undefined) {
            input.value = s[key];
            const valEl = document.getElementById(`val-opt-${key}`);
            if (valEl) valEl.innerText = s[key];
        }
    });
    VISIBILITY_ITEMS.forEach(item => {
        const input = document.getElementById(`opt-${item.key}`);
        if (input) input.checked = !!s[item.key];
    });
    ['alertSound', 'compactMode', 'smartFadeOut', 'showZone'].forEach(key => {
        const input = document.getElementById(`opt-${key}`);
        if (input) input.checked = !!s[key];
    });
    const themeInput = document.getElementById('opt-theme');
    if (themeInput) themeInput.value = s.theme || 'purple';
    const unitInput = document.getElementById('opt-distanceUnit');
    if (unitInput) unitInput.value = s.distanceUnit || 'metric';
}

function openSettingsMenu(settings, open) {
    const overlay = document.getElementById('d87-menu-overlay');
    if (!open) {
        overlay.style.display = 'none';
        return;
    }
    if (!menuInitialized) initMenuStaticText();

    snapshotSettings = Object.assign({}, currentSettings, settings);
    workingSettings = Object.assign({}, snapshotSettings);
    populateMenuInputs(workingSettings);
    overlay.style.display = 'flex';
}

function closeSettingsMenu(save) {
    const overlay = document.getElementById('d87-menu-overlay');
    if (save) {
        postNUI('saveSettings', workingSettings);
        currentSettings = Object.assign({}, workingSettings);
    } else {
        applySettings(snapshotSettings);
        postNUI('closeMenu', {});
    }
    overlay.style.display = 'none';
}
