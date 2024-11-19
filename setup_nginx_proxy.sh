#!/bin/bash

# Configurações iniciais
DOMAIN_PREFIX="proxy"  # Subdomínio base, ex.: proxy.vps1.meudominio.com.br
GATEWAY="100.102.90.1" # Gateway interno
NGINX_CONF_PATH="/etc/nginx" # Caminho do Nginx
PUBLIC_IP="170.254.135.110"

# Atualiza e instala os pacotes necessários
echo "Atualizando sistema e instalando dependências..."
apt update && apt upgrade -y
apt install -y nginx certbot python3-certbot-nginx

# Configuração inicial do Nginx
echo "Configurando Nginx para proxy reverso..."
cat <<EOF > ${NGINX_CONF_PATH}/nginx.conf
stream {
    log_format proxy_log '\$remote_addr [\$time_local] \$protocol \$status \$bytes_sent \$bytes_received \$session_time "\$upstream_addr"';

    access_log /var/log/nginx/proxy_access.log proxy_log;
    error_log /var/log/nginx/proxy_error.log;

    include /etc/nginx/stream-enabled/*.conf;
}

http {
    server {
        listen 80 default_server;
        server_name _;
        return 444;
    }
}
EOF

mkdir -p ${NGINX_CONF_PATH}/stream-enabled

# Função para adicionar nova VPS
add_vps() {
    VPS_NAME=$1
    VPS_IP=$2
    VPS_PORT=$3
    SUBDOMAIN="${VPS_NAME}.${DOMAIN_PREFIX}.macbvendas.com.br"

    echo "Adicionando VPS ${VPS_NAME} com IP ${VPS_IP}:${VPS_PORT}..."

    # Cria configuração para o proxy reverso
    cat <<EOF > ${NGINX_CONF_PATH}/stream-enabled/${VPS_NAME}.conf
server {
    listen 443;
    proxy_pass ${VPS_IP}:${VPS_PORT};
}
EOF

    # Recarrega o Nginx
    nginx -t && systemctl reload nginx

    # Configura SSL com Let's Encrypt
    echo "Configurando SSL para ${SUBDOMAIN}..."
    certbot --nginx -d ${SUBDOMAIN} --non-interactive --agree-tos --email seuemail@dominio.com
}

# Adiciona exemplo inicial de VPS
add_vps "vps1" "100.102.90.10" "22"

# Script para adicionar novas VPS automaticamente
echo "Para adicionar uma nova VPS, use:"
echo "bash $0 add_vps <nome_vps> <ip_vps> <porta>"
