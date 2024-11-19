#!/bin/bash

# Função para verificar a existência do arquivo de certificado SSL
check_ssl_certificate() {
    DOMAIN=$1
    CERT_PATH="/etc/nginx/ssl/${DOMAIN}.crt"
    
    if [ ! -f "$CERT_PATH" ]; then
        echo "Certificado SSL não encontrado para ${DOMAIN}."
        return 1
    else
        echo "Certificado SSL encontrado para ${DOMAIN}."
        return 0
    fi
}

# Função para gerar certificado SSL com Let's Encrypt
generate_ssl_certificate() {
    DOMAIN=$1

    echo "Gerando certificado SSL com Let's Encrypt para ${DOMAIN}..."
    
    # Instalar o Certbot e o plugin do NGINX se não estiverem instalados
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx

    # Gerar o certificado SSL para o domínio
    sudo certbot --nginx -d "$DOMAIN"

    # Verificar se o Certbot gerou o certificado com sucesso
    if [ $? -eq 0 ]; then
        echo "Certificado SSL gerado com sucesso para ${DOMAIN}!"
    else
        echo "Erro ao gerar certificado SSL para ${DOMAIN}. Verifique o seu domínio."
        exit 1
    fi
}

# Função para corrigir a configuração do NGINX
fix_nginx_config() {
    DOMAIN=$1
    CONF_PATH="/etc/nginx/sites-available/${DOMAIN}"

    echo "Corrigindo configuração do NGINX para ${DOMAIN}..."

    # Verificar se o arquivo de configuração existe
    if [ ! -f "$CONF_PATH" ]; then
        echo "Arquivo de configuração do NGINX não encontrado para ${DOMAIN}."
        exit 1
    fi

    # Ajustar caminho dos certificados SSL na configuração do NGINX
    sudo sed -i "s|ssl_certificate .*|ssl_certificate /etc/nginx/ssl/${DOMAIN}.crt;|g" "$CONF_PATH"
    sudo sed -i "s|ssl_certificate_key .*|ssl_certificate_key /etc/nginx/ssl/${DOMAIN}.key;|g" "$CONF_PATH"

    # Testar a configuração do NGINX
    sudo nginx -t

    if [ $? -eq 0 ]; then
        echo "Configuração do NGINX corrigida com sucesso!"
        sudo systemctl restart nginx
        echo "NGINX reiniciado com sucesso!"
    else
        echo "Erro na configuração do NGINX. Verifique a configuração manualmente."
        exit 1
    fi
}

# Função principal
main() {
    # Solicitar o domínio
    read -p "Digite o domínio para corrigir (ex: proxy.macbvendas.com.br): " DOMAIN

    # Verificar se o certificado SSL existe
    check_ssl_certificate "$DOMAIN"
    if [ $? -ne 0 ]; then
        # Caso não exista, gerar o certificado SSL
        generate_ssl_certificate "$DOMAIN"
    fi

    # Corrigir configuração do NGINX
    fix_nginx_config "$DOMAIN"

    # Mensagem de sucesso
    echo "Tudo pronto! O certificado SSL e a configuração do NGINX foram corrigidos."
}

# Tornar o script executável
chmod +x "$0"

# Executar a função principal
main
