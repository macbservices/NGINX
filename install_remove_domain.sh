#!/bin/bash

# Função para exibir mensagem de erro
error() {
    echo "Erro: $1" >&2
    exit 1
}

# URL do script 'remove_domain.sh' hospedado no GitHub
SCRIPT_URL="https://raw.githubusercontent.com/macbservices/NGINX/refs/heads/main/remove_domain.sh"

# Baixar e executar o script do GitHub
echo "Baixando e executando o script de remoção de domínio..."

bash <(curl -sSL "$SCRIPT_URL") || error "Falha ao executar o script de remoção do domínio."

echo "Script executado com sucesso!"
