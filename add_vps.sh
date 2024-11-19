#!/bin/bash

# Verificando se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root!" 
  exit 1
fi

# Solicitando informações do usuário
echo "Digite o IP do Proxmox VPS (exemplo: 100.102.90.50):"
read vps_ip
echo "Digite o domínio para o novo VPS (exemplo: proxmox2.macbvendas.com.br):"
read domain_name

# Criando arquivo de configuração do Nginx para o novo VPS
echo "Criando configuração para o novo VPS: $domain_name"
cat <<EOF > /etc/nginx/sites-available/$domain_name
server {
    listen 80;
    server_name $domain_name;

    location / {
        proxy_pass https://$vps_ip:8006; # IP do novo VPS
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
    server_name $domain_name;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;

    location / {
        proxy_pass https://$vps_ip:8006; # IP do novo VPS
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

# Ativando o novo site
ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/

# Testando a configuração do Nginx
nginx -t

# Reiniciando o Nginx
systemctl restart nginx

# Instalando certificado SSL com Certbot para o novo domínio
echo "Obtendo certificado SSL para $domain_name..."
certbot --nginx -d $domain_name --non-interactive --agree-tos -m seuemail@dominio.com

# Recarregar Nginx para aplicar o certificado
systemctl reload nginx

echo "Novo VPS configurado e funcionando com o domínio $domain_name!"
