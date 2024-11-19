#!/bin/bash

# Verificando se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root!" 
  exit 1
fi

# Atualizando o sistema
echo "Atualizando o sistema..."
apt update && apt upgrade -y

# Instalando dependências
echo "Instalando dependências: Nginx, Certbot..."
apt install -y nginx certbot python3-certbot-nginx curl

# Configuração básica do Nginx
echo "Configurando Nginx..."
systemctl enable nginx
systemctl start nginx

# Criar um diretório para armazenar a configuração do Nginx
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Definindo permissões para facilitar
chmod 755 /etc/nginx/sites-available
chmod 755 /etc/nginx/sites-enabled

# Criação do arquivo de configuração padrão
echo "Criando configuração de servidor padrão..."
cat <<EOF > /etc/nginx/sites-available/proxmox_default
server {
    listen 80;
    server_name proxmox.macbvendas.com.br;

    location / {
        proxy_pass https://100.102.90.50:8006; # IP do Proxmox
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_ssl_verify off; # Desativa verificação SSL do Proxmox
    }

    # Redireciona para HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name proxmox.macbvendas.com.br;

    ssl_certificate /etc/letsencrypt/live/proxmox.macbvendas.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/proxmox.macbvendas.com.br/privkey.pem;

    location / {
        proxy_pass https://100.102.90.50:8006; # IP do Proxmox
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Configurações para WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Desativa verificação SSL do Proxmox
        proxy_ssl_verify off;
    }
}
EOF

# Ativando o site no Nginx
ln -s /etc/nginx/sites-available/proxmox_default /etc/nginx/sites-enabled/

# Testando a configuração do Nginx
echo "Testando configuração do Nginx..."
nginx -t

# Reiniciando o Nginx
systemctl restart nginx

# Instalando certificado SSL com Certbot
echo "Obtendo certificado SSL com Certbot..."
certbot --nginx -d proxmox.macbvendas.com.br --non-interactive --agree-tos -m seuemail@dominio.com

# Recarregar Nginx para aplicar o certificado
systemctl reload nginx

echo "Instalação e configuração do Nginx concluída!"
