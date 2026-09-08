#!/usr/bin/env bash

# ============================================================
# Live 24 Horas
# Instalador simplificado do Ant Media Server Community Edition
#
# Projeto independente e não afiliado à Ant Media.
# ============================================================

set -Eeuo pipefail

# ============================================================
# CONFIGURAÇÕES
# ============================================================

ANTMEDIA_INSTALLER_URL="https://raw.githubusercontent.com/ant-media/Scripts/master/install_ant-media-server.sh"
ANTMEDIA_DIR="/usr/local/antmedia"
TEMP_INSTALLER="/tmp/install-ant-media-server.sh"

# ============================================================
# CORES
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# FUNÇÕES
# ============================================================

ok() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

separator() {
    echo
    echo "============================================================"
    echo
}

# Exibe mensagem amigável caso alguma etapa inesperada falhe.
trap 'echo; error "Ocorreu um erro durante a instalação."; echo "Linha: $LINENO"; echo "Você pode executar novamente o instalador após corrigir o problema."; echo' ERR

# ============================================================
# CABEÇALHO
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}                    LIVE 24 HORAS${NC}"
echo -e "${BOLD}============================================================${NC}"
echo
echo "Instalador simplificado do Ant Media Server"
echo "Community Edition para Ubuntu."
echo
echo "Este projeto é independente e não possui vínculo oficial"
echo "com a Ant Media."
echo

# ============================================================
# VERIFICAR ROOT
# ============================================================

info "Verificando permissões..."

if [ "$(id -u)" -ne 0 ]; then
    echo
    error "Este instalador precisa ser executado como root."
    echo
    echo "Entre como usuário root e execute novamente."
    echo
    echo "Em muitas VPS você pode usar:"
    echo
    echo "sudo -i"
    echo
    exit 1
fi

ok "Permissões de administrador confirmadas."

# ============================================================
# VERIFICAR SISTEMA OPERACIONAL
# ============================================================

info "Verificando sistema operacional..."

if [ ! -f /etc/os-release ]; then
    error "Não foi possível identificar o sistema operacional."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
    echo
    error "Este instalador foi preparado para Ubuntu."
    echo
    echo "Sistema detectado:"
    echo "${PRETTY_NAME:-desconhecido}"
    echo
    exit 1
fi

ok "Sistema detectado: ${PRETTY_NAME}"

# ============================================================
# VERIFICAR VERSÃO DO UBUNTU
# ============================================================

case "${VERSION_ID:-}" in

    "20.04"|"22.04"|"24.04"|"26.04")

        ok "Versão do Ubuntu reconhecida como compatível."

        ;;

    *)

        echo
        warning "Ubuntu ${VERSION_ID:-desconhecido} detectado."
        warning "Esta versão pode ainda não estar entre as versões"
        warning "suportadas oficialmente pelo Ant Media Server."
        echo

        read -r -p "Deseja continuar mesmo assim? [s/N]: " CONTINUE

        case "$CONTINUE" in

            s|S|sim|SIM|Sim)
                echo
                warning "Continuando por escolha do usuário..."
                ;;

            *)
                echo
                info "Instalação cancelada."
                exit 0
                ;;

        esac

        ;;

esac

separator

# ============================================================
# VERIFICAR INSTALAÇÃO EXISTENTE
# ============================================================

info "Verificando se o Ant Media Server já está instalado..."

if [ -d "$ANTMEDIA_DIR" ]; then

    echo
    warning "Já existe uma instalação do Ant Media Server em:"
    echo
    echo "$ANTMEDIA_DIR"
    echo
    warning "Por segurança, nenhuma instalação existente será sobrescrita."
    echo
    exit 1

fi

ok "Nenhuma instalação existente encontrada."

# ============================================================
# PREPARAR SERVIDOR
# ============================================================

separator

info "Preparando o servidor..."

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    curl \
    wget \
    ca-certificates

ok "Dependências básicas instaladas."

# ============================================================
# TESTAR INTERNET
# ============================================================

info "Verificando conexão com a internet..."

if ! curl -fsS --max-time 10 https://github.com >/dev/null; then

    echo
    error "Não foi possível acessar o GitHub."
    error "Verifique a conexão da VPS com a internet."
    echo
    exit 1

fi

ok "Conexão com a internet funcionando."

# ============================================================
# BAIXAR INSTALADOR OFICIAL DO ANT MEDIA
# ============================================================

separator

info "Baixando o instalador oficial do Ant Media Server..."

rm -f "$TEMP_INSTALLER"

curl -fL \
    "$ANTMEDIA_INSTALLER_URL" \
    -o "$TEMP_INSTALLER"

if [ ! -s "$TEMP_INSTALLER" ]; then

    error "Não foi possível baixar o instalador oficial."
    exit 1

fi

chmod 755 "$TEMP_INSTALLER"

ok "Instalador oficial baixado."

# ============================================================
# INSTALAR ANT MEDIA SERVER
# ============================================================

separator

echo -e "${BOLD}Instalando Ant Media Server Community Edition...${NC}"
echo
echo "Essa etapa pode levar alguns minutos."
echo
echo "Não feche o terminal durante a instalação."
echo

bash "$TEMP_INSTALLER"

# ============================================================
# VERIFICAR PASTA DE INSTALAÇÃO
# ============================================================

separator

info "Verificando instalação..."

if [ ! -d "$ANTMEDIA_DIR" ]; then

    echo
    error "A instalação terminou, mas a pasta do Ant Media"
    error "não foi encontrada em:"
    echo
    echo "$ANTMEDIA_DIR"
    echo
    exit 1

fi

ok "Arquivos do Ant Media Server encontrados."

# ============================================================
# VERIFICAR SERVIÇO
# ============================================================

info "Verificando serviço Ant Media..."

if ! systemctl is-active --quiet antmedia; then

    echo
    error "O Ant Media Server foi instalado,"
    error "mas o serviço não está ativo."
    echo
    echo "Para investigar, execute:"
    echo
    echo "systemctl status antmedia --no-pager"
    echo
    exit 1

fi

ok "Ant Media Server está rodando."

# ============================================================
# VERIFICAR PORTA DO PAINEL
# ============================================================

info "Verificando painel de administração..."

if ss -ltn 2>/dev/null | grep -q ':5080 '; then

    ok "Painel do Ant Media está disponível na porta 5080."

else

    warning "O serviço está ativo, mas a porta 5080"
    warning "não foi detectada imediatamente."
    warning "Ela pode levar alguns segundos para ficar disponível."

fi

# ============================================================
# DESCOBRIR IP PÚBLICO
# ============================================================

info "Identificando o IP público da VPS..."

PUBLIC_IP=""

PUBLIC_IP="$(curl -4fsS --max-time 10 https://api.ipify.org || true)"

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

if [ -n "$PUBLIC_IP" ]; then

    ok "IP encontrado: $PUBLIC_IP"

else

    warning "Não foi possível identificar automaticamente o IP da VPS."

fi

# ============================================================
# REMOVER ARQUIVO TEMPORÁRIO
# ============================================================

rm -f "$TEMP_INSTALLER"

# ============================================================
# RESULTADO
# ============================================================

separator

echo -e "${GREEN}${BOLD}              INSTALAÇÃO CONCLUÍDA!${NC}"

separator

echo -e "${BOLD}Ant Media Server Community Edition está instalado.${NC}"
echo

if [ -n "$PUBLIC_IP" ]; then

    echo -e "${BOLD}Abra o painel no navegador:${NC}"
    echo
    echo -e "${GREEN}http://${PUBLIC_IP}:5080${NC}"

else

    echo -e "${BOLD}Abra o painel no navegador utilizando:${NC}"
    echo
    echo -e "${GREEN}http://IP-DA-SUA-VPS:5080${NC}"

fi

echo
echo "No primeiro acesso, o Ant Media solicitará"
echo "a criação da conta de administrador."

separator

echo -e "${BOLD}PRÓXIMOS PASSOS${NC}"
echo
echo "1. Abra o endereço acima no navegador."
echo "2. Crie sua conta de administrador."
echo "3. Entre no painel do Ant Media."
echo "4. Faça upload do seu vídeo."
echo "5. Crie uma playlist."
echo "6. Ative o Loop Playlist."
echo "7. Inicie sua transmissão."
echo

separator

echo -e "${BOLD}Live 24 Horas${NC}"
echo
echo "Projeto independente para simplificar a instalação"
echo "do Ant Media Server Community Edition."
echo
echo "Ant Media Server e suas marcas pertencem"
echo "aos seus respectivos proprietários."
echo
