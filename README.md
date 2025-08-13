># Projeto de monitoramento de Site

# Tecnologias Utilizadas

<a href="https://github.com/" target="_blank">
  <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
</a>
<a href="https://www.nginx.com/" target="_blank">
  <img src="https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white" alt="Nginx">
</a>
<a href="https://man7.org/linux/man-pages/man5/crontab.5.html" target="_blank">
  <img src="https://img.shields.io/badge/Crontab-Used for scheduling-333?style=for-the-badge" alt="Crontab">
</a>
<a href="https://developer.mozilla.org/pt-BR/docs/Web/HTML" target="_blank">
  <img src="https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white" alt="HTML5">
</a>
<a href="https://git-scm.com/" target="_blank">
  <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git">
</a>
<a href="https://discord.com/" target="_blank">
  <img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
</a>

# Indice
- [1 - Configuração do Ambiente](#1---configuração-do-ambiente)
- [2 - Criação da página HTML](#2---criação-da-página-html)
- [3 - Script de Verificação](#3---script-de-verificação)
- [4 - Como Testar a Funcionalidade do Sistema](#4---como-testar-a-funcionalidade-do-sistema)

# 1 - Configuração do Ambiente

Explicação de como instalar e configurar o servidor web Nginx para hospedar um site.

## 1.1 Instalação do Nginx

### Instalar o Nginx
No Ubuntu/Debian:

```bash
apt update
apt-get install nginx
```

## 1.2 Configuração do servidor

### Ativar e verificar se está online
```bash
systemctl start nginx
systemctl status nginx
```
Aparecerá essa mensagem:
<img width="873" height="71" alt="Image" src="https://github.com/user-attachments/assets/4869d06d-2264-482d-a4fb-54fef5dc13f2" />
<img width="1919" height="695" alt="Image" src="https://github.com/user-attachments/assets/8c7601f1-a78b-4db3-9dc7-55179d17fe1c" />

## 1.3 Configuração do cron
```bash
crontab -e
```
Logo após de abrir no nano, digite:
```nano
* * * * * /bin/bash /usr/local/bin/verificacao.sh >> /var/log/verificacao.log
```

# 2 - Criação da página HTML

### 2.1 A página foi criada no diretório padrão `/usr/local/bin`:

```bash
vi /usr/local/bin/index.html
```

### 2.2 Script da página
```vi
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Meu Primeiro Site</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            text-align: center;
            margin-top: 100px;
        }
        h1 {
            color: #2c3e50;
        }
        p {
            color: #555;
        }
    </style>
</head>
<body>
    <h1>Olá, mundo!</h1>
    <p>Esse é meu primeiro site rodando com Nginx.</p>
</body>
</html>
```

# 3 - Script de Verificação

## 3.1 Criação do script

O script foi criado no diretório `/usr/local/bin` com o nome `verificacao.sh`:

```bash
vi verificacao.sh
```

## 3.2 Explicação do script por partes

### 3.2.1 Variáveis

`URL` - endereço que quer monitorar

`PORTA` - porta TCP para verificar se o serviço está respondendo (HTTP padrão é 80).

`DISCORD_WEBHOOK` - link do webhook para enviar alertas no Discord.

`LOG_FILE` - arquivo onde serão salvos os logs do monitoramento.

`SERVICO` -  nome do serviço que será reiniciado se estiver offline (nginx neste caso).

### 3.2.2 Função enviar_alerta()
```bash
enviar_alerta() {
    local msg="$1"
    echo "$msg" >> "$LOG_FILE"
    curl -s -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$msg\"}" \
         "$DISCORD_WEBHOOK" > /dev/null
}
```
`local msg="$1"` - recebe a mensagem como parâmetro.

`echo "$msg" >> "$LOG_FILE"` - escreve a mensagem no arquivo de log.

`curl -s ...` - envia a mensagem para o webhook do Discord em formato JSON.

`> /dev/null` - descarta a saída do curl (não mostra no terminal).

### 3.2.3 Função verificar_site()
```bash
verificar_site() {
    if timeout 5 bash -c "</dev/tcp/127.0.0.1/$PORTA" 2>/dev/null; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")
        if [ "$HTTP_CODE" == "200" ]; then
            return 0
        fi
    fi
    return 1
}
```
`timeout 5 bash -c "</dev/tcp/127.0.0.1/$PORTA":` - 
Tenta abrir uma conexão TCP com o servidor na porta especificada.

`HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL"):` - 
Faz um curl silencioso para a URL e captura o código HTTP.

`if [ "$HTTP_CODE" == "200" ]; then return 0; fi:` - 
Se o site responder com HTTP 200 (OK), retorna sucesso (0 no Bash).

`return 1:`
Caso contrário, retorna falha (1 no Bash).

### 3.2.4 Função tentar_reiniciar()
```bash
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
```
`systemctl restart "$SERVICO"` - reinicia o serviço (nginx).

`sleep 10` - espera 10 segundos para dar tempo do serviço subir.

Verifica novamente com `verificar_site()`.

### 3.2.5 Lógica de data e decisão
```bash
DATA=$(date '+%Y-%m-%d %H:%M:%S')
ULTIMA_LINHA=$(tail -n 1 "$LOG_FILE" 2>/dev/null)
```

`DATA` - armazena a data e hora atuais.

`ULTIMA_LINHA` - lê a última linha do log para decidir se o status mudou.

### 3.2.6 Condição principal
```bash
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
Se estiver online:

Verifica se a última linha do log contém "OFFLINE". - 
Se sim, envia alerta dizendo que voltou a ficar online.

Se estiver offline:

Verifica se a última linha do log não contém "OFFLINE" - 
Se não tinha registro de OFFLINE → envia alerta de queda.

Chama `tentar_reiniciar` para reiniciar o serviço e logar o resultado

## 4 - Como testar a funcionalidade do sistema

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
