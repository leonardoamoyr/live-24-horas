#!/usr/bin/env bash

# ============================================================
# Live 24 Horas
# Instalador simplificado do Ant Media Server Community Edition
#
# Projeto independente e não afiliado à Ant Media.
# ============================================================

set -Eeuo pipefail

# -----------------------------
# Cores
# -----------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# -----------------------------
# Funções
# -----------------------------
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

# -----------------------------
# Cabeçalho
# -----------------------------
clear

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

# -----------------------------
# Verificar root
# -----------------------------
info "Verificando permissões..."

if [ "$(id -u)" -ne 0 ]; then
    echo
    error "Este instalador precisa ser executado como root."
    echo
    echo "Entre como root ou execute:"
    echo
    echo "sudo bash install.sh"
    echo
    exit 1
fi

ok "Permissões de administrador confirmadas."

# -----------------------------
# Verificar sistema operacional
# -----------------------------
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
    echo "Sistema detectado: ${PRETTY_NAME:-desconhecido}"
    exit 1
fi

ok "Sistema detectado: ${PRETTY_NAME}"

# -----------------------------
# Avisar sobre versões
# -----------------------------
case "${VERSION_ID:-}" in
    "20.04"|"22.04"|"24.04")
        ok "Versão Ubuntu reconhecida como compatível pelo instalador."
        ;;
    *)
        echo
        warning "Você está utilizando Ubuntu ${VERSION_ID:-desconhecido}."
        warning "Esta versão pode não estar na lista de versões oficialmente"
        warning "suportadas pelo Ant Media Server."
        echo
        read -r -p "Deseja continuar mesmo assim? [s/N]: " CONTINUE

        case "$CONTINUE" in
            s|S|sim|SIM|Sim)
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

# -----------------------------
# Verificar instalação existente
# -----------------------------
info "Verificando se o Ant Media já está instalado..."

if [ -d "/usr/local/antmedia" ]; then
    echo
    warning "Foi encontrada uma instalação do Ant Media em:"
    echo "/usr/local/antmedia"
    echo
    warning "Por segurança, este instalador não irá sobrescrevê-la."
    echo
    exit 1
fi

ok "Nenhuma instalação existente encontrada."

# -----------------------------
# Verificar comandos necessários
# -----------------------------
info "Preparando o servidor..."

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl wget ca-certificates

ok "Servidor preparado."

separator

# -----------------------------
# Baixar instalador oficial
# -----------------------------
info "Baixando o instalador oficial do Ant Media Server..."

INSTALLER="/tmp/install-ant-media-server.sh"

rm -f "$INSTALLER"

curl -fL \
    https://raw.githubusercontent.com/ant-media/Scripts/master/install_ant-media_server.sh \
    -o "$INSTALLER"

chmod 755 "$INSTALLER"

ok "Instalador oficial baixado."

# -----------------------------
# Instalar Ant Media
# -----------------------------
separator

echo -e "${BOLD}Instalando Ant Media Server...${NC}"
echo
echo "Essa etapa pode levar alguns minutos."
echo

bash "$INSTALLER"

# -----------------------------
# Verificar instalação
# -----------------------------
separator

info "Verificando instalação..."

if [ ! -d "/usr/local/antmedia" ]; then
    error "A pasta do Ant Media não foi encontrada após a instalação."
    exit 1
fi

if ! systemctl is-active --quiet antmedia; then
    echo
    error "O Ant Media foi instalado, mas o serviço não está ativo."
    echo
    echo "Para investigar, execute:"
    echo
    echo "systemctl status antmedia --no-pager"
    echo
    exit 1
fi

ok "Ant Media Server instalado."
ok "Serviço Ant Media está rodando."

# -----------------------------
# Descobrir IP público
# -----------------------------
info "Identificando o endereço da VPS..."

PUBLIC_IP=""

PUBLIC_IP="$(curl -4fsS --max-time 10 https://api.ipify.org || true)"

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

# -----------------------------
# Resultado
# -----------------------------
separator

echo -e "${GREEN}${BOLD}           INSTALAÇÃO CONCLUÍDA! 🎉${NC}"

separator

if [ -n "$PUBLIC_IP" ]; then
    echo -e "${BOLD}Abra o painel do Ant Media no navegador:${NC}"
    echo
    echo -e "${GREEN}http://${PUBLIC_IP}:5080${NC}"
else
    echo "Abra o painel utilizando:"
    echo
    echo -e "${GREEN}http://IP-DA-SUA-VPS:5080${NC}"
fi

echo
echo "No primeiro acesso, o Ant Media solicitará"
echo "a criação da conta de administrador."

separator

echo -e "${BOLD}Live 24 Horas${NC}"
echo "Instalação simplificada para transmissões 24/7."
echo
echo "Ant Media Server é um projeto da Ant Media."
echo "Este instalador é um projeto independente."
echo
