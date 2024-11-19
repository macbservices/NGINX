#!/bin/bash

# Configurações iniciais
DOMAIN_BASE="macbvendas.com.br"  # Base para subdomínios
NGINX_CONF_PATH="/etc/nginx"  # Caminho do Nginx
VPS_CONFIG_PATH="${NGINX_CONF_PATH}/conf.d"  # Configurações de VPS
PUBLIC_IP="170.254.135.110"  # Seu IP público

# Atualiza e instala os pacotes necessários
echo "Atualizando sistema e instalando Nginx..."
apt update && apt upgrade -y
apt install -y nginx

# Configuração inicial do Nginx
echo "Configurando Nginx como proxy reverso..."

# Configuração principal do Nginx
cat <<EOF > ${NGINX_CONF_PATH}/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
}

http {
    log_format proxy_log '\$remote_addr - \$host [\$time_local] "\$request" '
                         '\$status \$body_bytes_sent "\$http_referer" "\$http_user_agent"';

    access_log /var/log/nginx/access.log proxy_log;
    error_log /var/log/nginx/error.log;

    include ${VPS_CONFIG_PATH}/*.conf;

    server {
        listen 80 default_server;
        server_name _;

        # Bloqueia requisições não configuradas
        return 444;
    }
}
EOF

mkdir -p ${VPS_CONFIG_PATH}

# Função para adicionar uma nova VPS
add_vps() {
    VPS_NAME=$1
    VPS_IP=$2
    VPS_PORT=$3

    echo "Adicionando VPS ${VPS_NAME} (${VPS_IP}:${VPS_PORT}) ao Nginx..."

    SUBDOMAIN="${VPS_NAME}.${DOMAIN_BASE}"

    # Cria configuração de proxy reverso para a VPS
    cat <<EOF > ${VPS_CONFIG_PATH}/${VPS_NAME}.conf
server {
    listen 80;
    server_name ${SUBDOMAIN};

    location / {
        proxy_pass http://${VPS_IP}:${VPS_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    # Recarrega o Nginx para aplicar as configurações
    nginx -t && systemctl reload nginx
    echo "Configuração para ${SUBDOMAIN} adicionada com sucesso!"
}

# Adiciona exemplo inicial de VPS
add_vps "vps1" "100.102.90.10" "8080"

# Instruções para adicionar novas VPS
echo "Para adicionar uma nova VPS, use o comando:"
echo "bash $0 add_vps <nome_vps> <ip_vps> <porta_vps>"
