#!/bin/bash
URL="http://127.0.0.1"
PORTA=80
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1404938519079555234/3cX4lVAWM797KJ9v4YUar5GSNOXnnw_M4hDxn3k92ajjRfnk2vRf8ml--jDYSv2SLxzo"
LOG_FILE="/usr/local/bin/verificacao.log"
SERVICO="nginx"

enviar_alerta() {
    local msg="$1"
    echo "$msg" >> "$LOG_FILE"
    curl -s -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$msg\"}" \
         "$DISCORD_WEBHOOK" > /dev/null
}

verificar_site() {
    if timeout 5 bash -c "</dev/tcp/127.0.0.1/$PORTA" 2>/dev/null; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")
        if [ "$HTTP_CODE" == "200" ]; then
            return 0
        fi
    fi
    return 1
}

tentar_reiniciar() {
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    enviar_alerta "$now - Serviço $SERVICO está OFFLINE. Tentando reiniciar..."
    systemctl restart "$SERVICO"
    sleep 10

    if verificar_site; then
        local now2=$(date '+%Y-%m-%d %H:%M:%S')
        enviar_alerta "$now2 - Serviço $SERVICO reiniciado com sucesso e está ONLINE."
        return 0
    else
        local now3=$(date '+%Y-%m-%d %H:%M:%S')
        enviar_alerta "$now3 - Serviço $SERVICO ainda está OFFLINE após reinício."
        return 1
    fi
}

DATA=$(date '+%Y-%m-%d %H:%M:%S')
ULTIMA_LINHA=$(tail -n 1 "$LOG_FILE" 2>/dev/null)

if verificar_site; then
    if [[ "$ULTIMA_LINHA" == *"OFFLINE"* ]]; then
        enviar_alerta "$DATA - Site está ONLINE."
    fi
else
    if [[ "$ULTIMA_LINHA" != *"OFFLINE"* ]]; then
        enviar_alerta "$DATA - Site está OFFLINE."
    fi
    tentar_reiniciar
fi

