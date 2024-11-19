#!/bin/bash

# Solicitar informações do usuário
read -p "Informe o domínio para o redirecionamento (ex: novadominio.macbvendas.com.br): " DOMAIN
read -p "Informe o IP interno da VPS (ex: 100.102.90.20): " INTERNAL_IP
read -p "Informe a porta interna do serviço na VPS (ex: 8081): " INTERNAL_PORT

# Criar configuração do NGINX
cat <<EOF > /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    # Redirecionar HTTP para HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    location / {
        proxy_pass http://$INTERNAL_IP:$INTERNAL_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Ativar a configuração no NGINX
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Testar e reiniciar o NGINX
nginx -t && systemctl restart nginx

echo "Configuração para o domínio $DOMAIN foi adicionada com sucesso!"
echo "Certifique-se de que os certificados SSL para $DOMAIN estão no caminho /etc/nginx/ssl/"
