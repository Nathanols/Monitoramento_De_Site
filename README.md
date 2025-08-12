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
