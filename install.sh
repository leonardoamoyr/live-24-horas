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

trim() {
    echo "$1" | xargs
}

trap '
echo
error "Ocorreu um erro durante a instalação."
echo "Linha aproximada: $LINENO"
echo
echo "Você pode corrigir o problema e executar o instalador novamente."
echo
' ERR

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
    echo "Entre como root e execute novamente."
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
# VERIFICAR VERSÃO
# ============================================================

case "${VERSION_ID:-}" in

    "20.04"|"22.04"|"24.04"|"26.04")
        ok "Versão do Ubuntu reconhecida como compatível."
        ;;

    *)
        echo
        warning "Ubuntu ${VERSION_ID:-desconhecido} detectado."
        warning "Esta versão pode ainda não estar entre as versões"
        warning "oficialmente suportadas pelo Ant Media Server."
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
    ca-certificates \
    dnsutils

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
# BAIXAR INSTALADOR OFICIAL
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
# INSTALAR ANT MEDIA
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
# VERIFICAR INSTALAÇÃO
# ============================================================

separator

info "Verificando instalação..."

if [ ! -d "$ANTMEDIA_DIR" ]; then
    echo
    error "A pasta do Ant Media Server não foi encontrada."
    echo
    exit 1
fi

ok "Arquivos do Ant Media Server encontrados."

info "Verificando serviço Ant Media..."

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

ok "Ant Media Server está rodando."

# ============================================================
# IP PÚBLICO
# ============================================================

info "Identificando o IP público da VPS..."

PUBLIC_IP="$(curl -4fsS --max-time 10 https://api.ipify.org || true)"

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

if [ -n "$PUBLIC_IP" ]; then
    ok "IP público detectado: $PUBLIC_IP"
else
    warning "Não foi possível identificar automaticamente o IP público."
fi

# ============================================================
# RESULTADO DA INSTALAÇÃO
# ============================================================

separator

echo -e "${GREEN}${BOLD}        ANT MEDIA INSTALADO COM SUCESSO!${NC}"

separator

if [ -n "$PUBLIC_IP" ]; then
    echo -e "${BOLD}Painel sem SSL:${NC}"
    echo
    echo -e "${GREEN}http://${PUBLIC_IP}:5080${NC}"
else
    echo -e "${GREEN}http://IP-DA-SUA-VPS:5080${NC}"
fi

echo
echo "No primeiro acesso, crie sua conta de administrador."

# ============================================================
# DOMÍNIO E SSL
# ============================================================

separator

echo -e "${BOLD}DOMÍNIO E CERTIFICADO SSL${NC}"
echo
echo "Você pode acessar o Ant Media de forma segura utilizando"
echo "um subdomínio, por exemplo:"
echo
echo "live.seudominio.com"
echo
echo "Antes de continuar, o subdomínio precisa possuir um"
echo "registro DNS do tipo A apontando para o IP desta VPS."
echo

read -r -p "Deseja configurar domínio + SSL agora? [s/N]: " INSTALL_SSL

case "$INSTALL_SSL" in

    s|S|sim|SIM|Sim)

        separator

        # ====================================================
        # SOLICITAR E CONFIRMAR SUBDOMÍNIO
        # ====================================================

        while true; do

            echo

            read -r -p "Digite seu subdomínio (ex: live.seudominio.com): " DOMAIN

            DOMAIN="$(trim "$DOMAIN")"

            # Remove protocolo, caminho e porta caso o usuário
            # informe por engano.
            DOMAIN="${DOMAIN#http://}"
            DOMAIN="${DOMAIN#https://}"
            DOMAIN="${DOMAIN%%/*}"
            DOMAIN="${DOMAIN%%:*}"

            # Converte para letras minúsculas.
            DOMAIN="$(echo "$DOMAIN" | tr '[:upper:]' '[:lower:]')"

            if [ -z "$DOMAIN" ]; then
                echo
                error "Nenhum subdomínio foi informado."
                echo
                info "Digite novamente."
                continue
            fi

            # Validação básica do formato.
            if ! [[ "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
                echo
                error "O endereço informado não parece ser um domínio válido."
                echo
                echo "Exemplo:"
                echo "live.seudominio.com"
                echo
                info "Digite novamente."
                continue
            fi

            separator

            echo -e "${BOLD}CONFIRA SEU SUBDOMÍNIO${NC}"
            echo
            echo "Você informou:"
            echo
            echo -e "${GREEN}${BOLD}${DOMAIN}${NC}"
            echo
            echo "O certificado SSL será instalado para este endereço."
            echo

            read -r -p "O subdomínio está correto? [s/N]: " CONFIRM_DOMAIN

            case "$CONFIRM_DOMAIN" in

                s|S|sim|SIM|Sim)
                    echo
                    ok "Subdomínio confirmado: $DOMAIN"
                    break
                    ;;

                *)
                    echo
                    info "Sem problemas. Digite o subdomínio novamente."
                    ;;

            esac

        done

        # ====================================================
        # VERIFICAR DNS
        # ====================================================

        echo
        info "Verificando DNS do domínio..."

        DOMAIN_IP="$(dig +short A "$DOMAIN" | head -n 1 || true)"

        if [ -z "$DOMAIN_IP" ]; then
            echo
            error "O subdomínio ainda não possui um registro A válido."
            echo
            echo "Configure seu DNS desta forma:"
            echo
            echo "Tipo: A"
            echo "Nome: live"
            echo "Destino: ${PUBLIC_IP:-IP-DA-SUA-VPS}"
            echo
            echo "Depois aguarde a propagação do DNS."
            echo
            exit 1
        fi

        echo
        echo "IP encontrado no DNS: $DOMAIN_IP"
        echo "IP desta VPS:          ${PUBLIC_IP:-desconhecido}"
        echo

        if [ -n "$PUBLIC_IP" ] && [ "$DOMAIN_IP" != "$PUBLIC_IP" ]; then
            error "O subdomínio ainda não aponta para esta VPS."
            echo
            echo "O DNS está apontando para:"
            echo "$DOMAIN_IP"
            echo
            echo "Mas esta VPS utiliza:"
            echo "$PUBLIC_IP"
            echo
            echo "Corrija o registro DNS e aguarde a propagação."
            echo
            exit 1
        fi

        ok "O subdomínio aponta corretamente para esta VPS."

        # ====================================================
        # VERIFICAR PORTA 80
        # ====================================================

        info "Verificando a porta 80..."

        PORT80_PROCESS="$(ss -ltnp 2>/dev/null | grep ':80 ' || true)"

        if [ -n "$PORT80_PROCESS" ]; then
            echo
            warning "Existe um processo utilizando a porta 80."
            echo
            echo "$PORT80_PROCESS"
            echo
            warning "O Let's Encrypt pode não conseguir validar o domínio."
            echo
            echo "Pare o serviço que utiliza a porta 80 e tente novamente."
            echo
            exit 1
        fi

        ok "Porta 80 disponível."

        # ====================================================
        # INSTALAR SSL
        # ====================================================

        separator

        echo -e "${BOLD}Configurando certificado SSL...${NC}"
        echo
        echo "O Ant Media utilizará Let's Encrypt para gerar"
        echo "gratuitamente o certificado HTTPS."
        echo
        echo "Aguarde. Esta etapa pode levar alguns instantes."
        echo

        cd "$ANTMEDIA_DIR"

        ./enable_ssl.sh -d "$DOMAIN"

        # ====================================================
        # VERIFICAR HTTPS
        # ====================================================

        separator

        info "Verificando HTTPS..."

        sleep 5

        if ss -ltn 2>/dev/null | grep -q ':5443 '; then
            ok "Ant Media está ouvindo na porta HTTPS 5443."
        else
            warning "A porta 5443 ainda não apareceu como ativa."
        fi

        if curl -kfsS \
            --connect-timeout 10 \
            "https://127.0.0.1:5443/" \
            >/dev/null 2>&1; then

            ok "Servidor HTTPS respondeu corretamente."

        else

            warning "O certificado foi configurado,"
            warning "mas o teste HTTPS local não respondeu imediatamente."

        fi

        separator

        echo -e "${GREEN}${BOLD}          SSL CONFIGURADO COM SUCESSO!${NC}"

        separator

        echo -e "${BOLD}ACESSO RECOMENDADO COM SSL:${NC}"
        echo
        echo -e "${GREEN}https://${DOMAIN}:5443${NC}"
        echo

        if [ -n "$PUBLIC_IP" ]; then
            echo -e "${BOLD}ACESSO TEMPORÁRIO PELO IP:${NC}"
            echo
            echo -e "${GREEN}http://${PUBLIC_IP}:5080${NC}"
            echo
            echo "Se o subdomínio ainda não abrir no seu dispositivo,"
            echo "aguarde a propagação/atualização do DNS e utilize"
            echo "temporariamente o acesso direto pelo IP acima."
            echo
        fi

        echo "O certificado SSL é gratuito e sua renovação"
        echo "é configurada automaticamente."
        echo
        ;;

    *)

        echo
        info "Configuração SSL ignorada."
        echo

        if [ -n "$PUBLIC_IP" ]; then
            echo "Você pode configurar SSL posteriormente executando:"
            echo
            echo "cd /usr/local/antmedia"
            echo "./enable_ssl.sh -d live.seudominio.com"
            echo
            echo "Até lá, acesse:"
            echo
            echo "http://${PUBLIC_IP}:5080"
        fi
        ;;

esac

# ============================================================
# LIMPEZA
# ============================================================

rm -f "$TEMP_INSTALLER"

# ============================================================
# FINAL
# ============================================================

separator

echo -e "${GREEN}${BOLD}              TUDO PRONTO! 🎉${NC}"

separator

echo -e "${BOLD}Próximos passos:${NC}"
echo
echo "1. Abra o painel do Ant Media."
echo "2. Crie sua conta de administrador."
echo "3. Entre em LiveApp."
echo "4. Faça upload do seu vídeo em VoD."
echo "5. Crie uma Playlist."
echo "6. Adicione seu vídeo à playlist."
echo "7. Ative Loop Playlist."
echo "8. Inicie a transmissão."
echo "9. Configure o endpoint RTMP do YouTube."
echo

separator

echo -e "${BOLD}Live 24 Horas${NC}"
echo
echo "Projeto independente criado para simplificar"
echo "a instalação do Ant Media Server Community Edition."
echo
echo "Ant Media Server e suas marcas pertencem"
echo "aos seus respectivos proprietários."
echo
