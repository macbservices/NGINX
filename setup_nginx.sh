#!/bin/bash

# Configuração de variáveis
read -p "Informe o nome do domínio (ex: api.macbvendas.com.br): " DOMAIN
read -p "Informe o IP interno do servidor (ex: 100.102.90.20): " INTERNAL_IP
read -p "Informe a porta interna para o serviço (ex: 8080): " INTERNAL_PORT

# Atualização do sistema
apt update -y
apt upgrade -y

# Instalar NGINX
apt install -y nginx

# Criar diretórios para armazenar os arquivos de SSL (se for usar HTTPS)
mkdir -p /etc/nginx/ssl

# Certificados SSL (exemplo usando Let's Encrypt - ajuste conforme necessário)
# Vamos criar um arquivo de configuração de SSL que pode ser usado diretamente.
echo "Certifique-se de ter o certbot instalado e os certificados configurados antes de continuar."

# Criar configuração do NGINX para o domínio
cat <<EOF > /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    # Redirecionar todo o tráfego HTTP para HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;

    # Configuração de segurança básica para SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    # Redirecionamento para a porta interna sem exibir
    location / {
        proxy_pass http://$INTERNAL_IP:$INTERNAL_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Ativar o site configurado
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Testar e reiniciar o NGINX para aplicar as alterações
nginx -t && systemctl restart nginx

echo "Configuração do NGINX concluída para o domínio $DOMAIN."
echo "Não se esqueça de configurar o roteador para redirecionar as portas 80 e 443 para o IP da VPS onde o NGINX está rodando."

# Monitoramento básico de IPs
echo "Monitorando IPs conectados..."
netstat -tn 2>/dev/null | grep ':80\|:443'

echo "O NGINX está configurado para ocultar as portas e redirecionar o tráfego corretamente."
