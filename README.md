# Projeto de monitoramento automatizado

## Como Configurar o Ambiente do Servidor Nginx

Explicação de como instalar e configurar o servidor web Nginx para hospedar um site.

## Pré-requisitos

- Um servidor com sistema Linux (Ubuntu, Debian, Linux Mint etc)
- Acesso root para instalar pacotes e modificar configurações

## Instalação do Nginx

### Instalar o Nginx
No Ubuntu/Debian:

```bash
apt update
apt-get install nginx
```

## Configuração do cron
```bash
crontab -e
```
Logo após de abrir no nano, digite:
```nano
* * * * * /bin/bash /usr/local/bin/verificacao.sh >> /var/log/verificacao.log
```

## Script
```vi
#!/bin/bash
URL="http://127.0.0.1"
PORTA=80
DISCORD_WEBHOOK="https://discord"
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
```

## Configuração do servidor

### Ativar e verificar se está online
```bash
systemctl start nginx
systemctl status nginx
```
Aparecerá essa mensagem:
<img width="873" height="71" alt="Image" src="https://github.com/user-attachments/assets/4869d06d-2264-482d-a4fb-54fef5dc13f2" />
<img width="1919" height="695" alt="Image" src="https://github.com/user-attachments/assets/8c7601f1-a78b-4db3-9dc7-55179d17fe1c" />

## Como testar a funcionalidade do sistema

### Teste
Rode o script
```bash
bash verificacao.sh
```
Para parar o nginx rode este código no terminal:
```bash
systemctl stop nginx
```
Para verificar se o nginx parou:
```bash
systemctl status nginx
```
<img width="1901" height="657" alt="Image" src="https://github.com/user-attachments/assets/195c5af6-6c3b-4f03-b1fd-2fd7faa42fdf" />

E logo em seguida é só verificar no discord se o site foi reiniciado automaticamente:

<img width="1432" height="243" alt="Image" src="https://github.com/user-attachments/assets/fa62bf2c-64d2-49db-8ea3-081b031981b9" />
