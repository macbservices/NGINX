#!/bin/bash

# Função para verificar e corrigir a configuração do NGINX
fix_proxy_pass() {
    echo "Verificando configurações do NGINX..."

    # Encontrar arquivos de configuração do NGINX em sites-enabled
    for config_file in /etc/nginx/sites-enabled/*; do
        # Verificar se a diretiva 'proxy_pass' está mal configurada
        if grep -q "proxy_pass" "$config_file"; then
            echo "Verificando arquivo: $config_file"

            # Corrigir diretiva proxy_pass com uma configuração padrão válida (ajuste conforme necessário)
            sed -i 's|proxy_pass .*|proxy_pass http://127.0.0.1:8080;|' "$config_file"
            echo "Diretiva proxy_pass corrigida em $config_file"
        fi
    done
}

# Função para verificar a configuração do NGINX
verify_nginx_config() {
    echo "Verificando configuração do NGINX..."
    sudo nginx -t
    if [[ $? -ne 0 ]]; then
        echo "Erro na configuração do NGINX. Corrija os erros antes de reiniciar."
        exit 1
    fi
}

# Função para reiniciar o NGINX
restart_nginx() {
    echo "Reiniciando o NGINX..."
    sudo systemctl restart nginx
    if [[ $? -eq 0 ]]; then
        echo "NGINX reiniciado com sucesso."
    else
        echo "Erro ao reiniciar o NGINX."
        exit 1
    fi
}

# Função para remover links simbólicos e arquivos de configuração do domínio
remove_domain() {
    echo "Listando domínios no NGINX..."
    available_domains=()
    i=1
    for config_file in /etc/nginx/sites-available/*; do
        available_domains+=("$i: $(basename "$config_file")")
        ((i++))
    done

    echo "Escolha o domínio que deseja remover:"
    select opt in "${available_domains[@]}"; do
        if [[ -n "$opt" ]]; then
            domain_name=$(echo "$opt" | sed 's/^[0-9]\+: //')
            echo "Removendo $domain_name..."

            # Remover o arquivo de configuração em sites-available
            sudo rm -f "/etc/nginx/sites-available/$domain_name"
            sudo rm -f "/etc/nginx/sites-enabled/$domain_name"

            # Verificar a configuração do NGINX após remoção
            verify_nginx_config

            break
        else
            echo "Opção inválida. Tente novamente."
        fi
    done
}

# Função principal
main() {
    # Corrigir diretivas proxy_pass
    fix_proxy_pass

    # Verificar configuração do NGINX
    verify_nginx_config

    # Reiniciar o NGINX após correções
    restart_nginx

    # Perguntar se deseja remover um domínio
    read -p "Você deseja remover algum domínio? (sim/não): " remove_choice
    if [[ "$remove_choice" == "sim" ]]; then
        remove_domain
    fi
}

# Tornar o script executável
if [[ ! -x "$0" ]]; then
    echo "Tornando o script executável..."
    chmod +x "$0"
fi

# Dar permissões necessárias para o script
echo "Garantindo permissões necessárias..."
sudo chown root:root "$0"

# Chamada da função principal
main
