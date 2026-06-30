let alertLimit = 20;

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "show") {
        let wrapper = document.getElementById('d87-hud-wrapper');
        wrapper.style.display = 'block';
        
        let container = document.getElementById('d87-hud');
        let finContainer = document.getElementById('d87-finance');
        let compassContainer = document.getElementById('d87-compass-box');
        let wpContainer = document.getElementById('stat-waypoint');
        let voiceContainer = document.getElementById('stat-voice');
        
        // Carga de escalas
        if (data.size) container.style.transform = `scale(${data.size})`;
        
        // Columna de Estadísticas (Flanco Derecho del mapa)
        if (data.statsBottom) container.style.bottom = `${data.statsBottom}px`;
        if (data.statsLeft) container.style.left = `${data.statsLeft}%`;
        
        // Brújula y Reloj Transparente (Arriba del mapa)
        if (data.compassBottom) compassContainer.style.bottom = `${data.compassBottom}px`;
        if (data.compassLeft) compassContainer.style.left = `${data.compassLeft}%`;

        // Caja de Ruta Waypoint (Arriba a la derecha interna del mapa)
        if (data.wpBottom) wpContainer.style.bottom = `${data.wpBottom}px`;
        if (data.wpLeft) wpContainer.style.left = `${data.wpLeft}%`;

        // CORREGIDO: Micrófono PMA-Voice mapeado hacia la esquina inferior derecha absoluta
        if (data.voiceBottom) voiceContainer.style.bottom = `${data.voiceBottom}px`;
        if (data.voiceRight) {
            voiceContainer.style.left = 'auto'; // Rompe herencia izquierda antigua
            voiceContainer.style.right = `${data.voiceRight}px`;
        }

        // Bloque Financiero y Logotipo (Top-Right)
        if (data.topRightSize) finContainer.style.transform = `scale(${data.topRightSize})`;
        if (data.topMargin) finContainer.style.top = `${data.topMargin}px`;
        if (data.rightMargin) finContainer.style.right = `${data.rightMargin}px`;
        
        alertLimit = data.alertLimit ? data.alertLimit : 20;

        if (data.loadingStreet) document.getElementById('val-street').innerText = data.loadingStreet;

        // Visibilidad por Config de Constantes
        document.getElementById('stat-id').style.display = 'flex';
        document.getElementById('stat-voice').style.display = data.showVoice ? 'flex' : 'none';
        document.getElementById('stat-health').style.display = data.showHealth ? 'flex' : 'none';
        document.getElementById('stat-armor').style.display = data.showArmor ? 'flex' : 'none';
        document.getElementById('stat-hunger').style.display = data.showHunger ? 'flex' : 'none';
        document.getElementById('stat-thirst').style.display = data.showThirst ? 'flex' : 'none';
        document.getElementById('stat-stress').style.display = data.showStress ? 'flex' : 'none';
        document.getElementById('stat-stamina').style.display = data.showStamina ? 'flex' : 'none';
        document.getElementById('stat-sleep').style.display = data.showSleep ? 'flex' : 'none';

        // Visibilidad de Brújula y Finanzas
        compassContainer.style.display = (data.showCompass || data.showTime) ? 'flex' : 'none';
        document.getElementById('fin-cash').style.display = data.showCash ? 'flex' : 'none';
        document.getElementById('fin-bank').style.display = data.showBank ? 'flex' : 'none';
        document.getElementById('fin-job').style.display = data.showJob ? 'flex' : 'none';
        
        // CORREGIDO: Inicializamos el contenedor del Waypoint oculto en espera de ruta activa
        wpContainer.style.display = 'none';
    } 
    
    else if (data.action === "hide") {
        document.getElementById('d87-hud-wrapper').style.display = 'none';
    } 
    
    else if (data.action === "update_finance") {
        if (data.cash !== undefined) document.getElementById('val-cash').innerText = "$" + data.cash.toLocaleString('es-ES');
        if (data.bank !== undefined) document.getElementById('val-bank').innerText = "$" + data.bank.toLocaleString('es-ES');
        if (data.job) {
            let gradeText = data.grade ? ` (${data.grade})` : "";
            document.getElementById('val-job').innerText = data.job + gradeText;
        }
    }
    
    else if (data.action === "update") {
        if (data.playerId !== undefined) document.getElementById('val-id').innerText = data.playerId;
        
        if (data.compass) document.getElementById('val-compass').innerText = data.compass;
        if (data.street) document.getElementById('val-street').innerText = data.street;
        if (data.time) document.getElementById('val-time').innerText = data.time;

        // 📍 CORREGIDO: Lógica reactiva de la caja de ruta (Aparece perfecto dentro del mapa)
        let wpBox = document.getElementById('stat-waypoint');
        if (wpBox) {
            if (data.wpActive) {
                wpBox.style.display = 'flex'; // Forzamos el renderizado de la caja fucsia
                document.getElementById('val-waypoint').innerText = data.wpDistance;
            } else {
                wpBox.style.display = 'none';
            }
        }

        if (data.voiceDist !== undefined) {
            document.getElementById('val-voice').innerText = data.voiceDist + "M";
            let vIcon = document.getElementById('icon-voice');
            if (data.talking) {
                vIcon.classList.add('voice-talking-active');
            } else {
                vIcon.classList.remove('voice-talking-active');
            }
        }

        let oxBox = document.getElementById('stat-oxygen');
        if (data.diving) {
            oxBox.style.display = 'flex';
            document.getElementById('val-oxygen').innerText = data.oxygen;
            toggleAlertBlink('stat-oxygen', data.oxygen <= 25);
        } else {
            oxBox.style.display = 'none';
        }

        document.getElementById('val-health').innerText = data.health;
        toggleAlertBlink('stat-health', data.health <= alertLimit);

        document.getElementById('val-armor').innerText = data.armor;
        
        document.getElementById('val-hunger').innerText = data.hunger;
        toggleAlertBlink('stat-hunger', data.hunger <= alertLimit);

        document.getElementById('val-thirst').innerText = data.thirst;
        toggleAlertBlink('stat-thirst', data.thirst <= alertLimit);

        document.getElementById('val-stress').innerText = data.stress;
        toggleAlertBlink('stat-stress', data.stress >= 80);

        document.getElementById('val-stamina').innerText = data.stamina;
        toggleAlertBlink('stat-stamina', data.stamina <= alertLimit);

        document.getElementById('val-sleep').innerText = data.sleep;
        toggleAlertBlink('stat-sleep', data.sleep <= alertLimit);
    }
});

function toggleAlertBlink(elementId, shouldBlink) {
    let el = document.getElementById(elementId);
    if (el) { if (shouldBlink) el.classList.add('blink-hud-alert'); else el.classList.remove('blink-hud-alert'); }
}
