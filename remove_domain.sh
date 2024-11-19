#!/bin/bash

# Função para exibir mensagem de erro
error() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para listar os domínios configurados no NGINX
list_domains() {
    echo "Domínios configurados no NGINX:"
    local i=1
    declare -gA DOMAIN_LIST

    for file in /etc/nginx/sites-available/*; do
        if [[ -f "$file" ]]; then
            DOMAIN=$(basename "$file")
            DOMAIN_LIST["$i"]="$DOMAIN"
            echo "$i) $DOMAIN"
            ((i++))
        fi
    done

    # Verifica se há domínios disponíveis
    if [[ ${#DOMAIN_LIST[@]} -eq 0 ]]; then
        echo "Nenhum domínio configurado encontrado."
        exit 0
    fi
}

# Solicita o domínio para remoção com base no menu
select_domain() {
    echo
    read -p "Digite o número do domínio que deseja remover: " CHOICE

    # Valida a escolha
    if [[ -z "${DOMAIN_LIST[$CHOICE]}" ]]; then
        error "Escolha inválida. Tente novamente."
    fi

    DOMAIN="${DOMAIN_LIST[$CHOICE]}"
    echo "Domínio selecionado: $DOMAIN"
}

# Função para remover o domínio
remove_domain() {
    local DOMAIN="$1"
    local SITES_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
    local SITES_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
    local SSL_CERT="/etc/nginx/ssl/$DOMAIN.crt"
    local SSL_KEY="/etc/nginx/ssl/$DOMAIN.key"

    # Remove a configuração de sites-available
    if [[ -f "$SITES_AVAILABLE" ]]; then
        echo "Removendo configuração de sites-available..."
        rm "$SITES_AVAILABLE" || error "Não foi possível remover $SITES_AVAILABLE"
    else
        echo "Nenhuma configuração encontrada em sites-available para $DOMAIN."
    fi

    # Remove o link simbólico em sites-enabled
    if [[ -L "$SITES_ENABLED" ]]; then
        echo "Removendo configuração de sites-enabled..."
        rm "$SITES_ENABLED" || error "Não foi possível remover $SITES_ENABLED"
    else
        echo "Nenhuma configuração encontrada em sites-enabled para $DOMAIN."
    fi

    # Remove certificados SSL, se existirem
    if [[ -f "$SSL_CERT" ]] || [[ -f "$SSL_KEY" ]]; then
        echo "Removendo certificados SSL..."
        rm -f "$SSL_CERT" "$SSL_KEY" || error "Não foi possível remover os certificados SSL."
    else
        echo "Nenhum certificado SSL encontrado para $DOMAIN."
    fi

    # Testa a configuração do NGINX
    echo "Testando configuração do NGINX..."
    nginx -t || error "Erro na configuração do NGINX após a remoção."

    # Reinicia o NGINX para aplicar alterações
    echo "Reiniciando NGINX..."
    systemctl restart nginx || error "Não foi possível reiniciar o NGINX."

    echo "Domínio $DOMAIN removido com sucesso!"
}

# Executa o script
list_domains
select_domain
remove_domain "$DOMAIN"
