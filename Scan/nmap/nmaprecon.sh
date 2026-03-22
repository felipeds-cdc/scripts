#!/bin/bash
# ============================================
# Nmap Recon Script - Educacional
# Autor: Felipe Diassis
# GitHub: github.com/felipeds-cdc
# ============================================
# AVISO: Use apenas em alvos autorizados.
# Lei 12.737/2012
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================
# BANNER
# ============================================
banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           NMAP RECON SCRIPT v1.0             ║"
    echo "║        github.com/felipeds-cdc               ║"
    echo "║   ⚠  Apenas para fins educacionais  ⚠        ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ============================================
# UTILITÁRIOS
# ============================================
titulo() {
    echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════════"
    echo -e "  $1"
    echo -e "══════════════════════════════════════════════${RESET}"
}

ok()   { echo -e "  ${GREEN}[+]${RESET} $1"; }
info() { echo -e "  ${YELLOW}[*]${RESET} $1"; }
erro() { echo -e "  ${RED}[!]${RESET} $1"; }

# ============================================
# VERIFICA DEPENDÊNCIAS
# ============================================
verificar_deps() {
    if ! command -v nmap &> /dev/null; then
        erro "nmap não encontrado. Instale: sudo apt install nmap"
        exit 1
    fi
    ok "nmap encontrado: $(nmap --version | head -1)"
}

# ============================================
# CRIA PASTA DE OUTPUT
# ============================================
criar_output() {
    ALVO=$1
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_DIR="nmap_results/${ALVO}_${TIMESTAMP}"
    mkdir -p "$OUTPUT_DIR"
    echo "$OUTPUT_DIR"
}

# ============================================
# FASE 1 — DESCOBERTA DE HOST
# ============================================
fase1_descoberta() {
    local alvo=$1
    local dir=$2
    titulo "FASE 1 — DESCOBERTA DE HOST"
    info "Verificando se o alvo está online..."

    nmap -sn "$alvo" \
        -oN "${dir}/fase1_descoberta.txt" 2>/dev/null

    if grep -q "Host is up" "${dir}/fase1_descoberta.txt"; then
        ok "Host ONLINE: $alvo"
    else
        erro "Host pode estar offline ou bloqueando pings"
        info "Continuando mesmo assim..."
    fi
}

# ============================================
# FASE 2 — TOP 1000 PORTAS
# ============================================
fase2_top1000() {
    local alvo=$1
    local dir=$2
    titulo "FASE 2 — TOP 1000 PORTAS"
    info "Escaneando top 1000 portas TCP..."

    nmap -sS -T4 \
        --open \
        "$alvo" \
        -oN "${dir}/fase2_top1000.txt" 2>/dev/null

    # Exibe portas abertas
    grep "open" "${dir}/fase2_top1000.txt" | while read linha; do
        ok "$linha"
    done
}

# ============================================
# FASE 3 — TODAS AS PORTAS
# ============================================
fase3_full_scan() {
    local alvo=$1
    local dir=$2
    titulo "FASE 3 — SCAN COMPLETO (65535 portas)"
    info "Isso pode demorar alguns minutos..."

    nmap -sS -T4 \
        -p- \
        --open \
        --min-rate 1000 \
        "$alvo" \
        -oN "${dir}/fase3_fullscan.txt" 2>/dev/null

    PORTAS=$(grep "open" "${dir}/fase3_fullscan.txt" \
        | awk '{print $1}' \
        | cut -d'/' -f1 \
        | tr '\n' ',' \
        | sed 's/,$//')

    if [ -n "$PORTAS" ]; then
        ok "Portas abertas encontradas: $PORTAS"
        echo "$PORTAS"
    else
        info "Nenhuma porta aberta encontrada"
        echo ""
    fi
}

# ============================================
# FASE 4 — VERSÕES E SO
# ============================================
fase4_versoes() {
    local alvo=$1
    local dir=$2
    local portas=$3
    titulo "FASE 4 — DETECÇÃO DE VERSÕES E SO"

    if [ -z "$portas" ]; then
        info "Sem portas para analisar — usando top portas"
        portas="--top-ports 100"
    else
        portas="-p $portas"
    fi

    info "Detectando versões e sistema operacional..."

    nmap -sV -O \
        $portas \
        --version-intensity 7 \
        "$alvo" \
        -oN "${dir}/fase4_versoes.txt" 2>/dev/null

    # Mostra serviços detectados
    grep "open" "${dir}/fase4_versoes.txt" | while read linha; do
        ok "$linha"
    done

    # Mostra SO detectado
    SO=$(grep "OS details" "${dir}/fase4_versoes.txt" | head -1)
    if [ -n "$SO" ]; then
        ok "Sistema Operacional: $SO"
    fi
}

# ============================================
# FASE 5 — SCRIPTS NSE
# ============================================
fase5_scripts() {
    local alvo=$1
    local dir=$2
    local portas=$3
    titulo "FASE 5 — SCRIPTS NSE (Vulnerabilidades)"

    if [ -z "$portas" ]; then
        portas="--top-ports 100"
    else
        portas="-p $portas"
    fi

    info "Executando scripts padrão e de vulnerabilidades..."

    nmap -sV \
        $portas \
        --script="default,vuln,auth" \
        "$alvo" \
        -oN "${dir}/fase5_scripts.txt" 2>/dev/null

    # Destaca vulnerabilidades encontradas
    if grep -qi "VULNERABLE\|CVE\|exploit" "${dir}/fase5_scripts.txt"; then
        echo -e "\n  ${RED}${BOLD}⚠ POSSÍVEIS VULNERABILIDADES ENCONTRADAS:${RESET}"
        grep -i "VULNERABLE\|CVE\|exploit" "${dir}/fase5_scripts.txt" | while read linha; do
            echo -e "  ${RED}[VULN]${RESET} $linha"
        done
    else
        info "Nenhuma vulnerabilidade crítica detectada nos scripts"
    fi
}

# ============================================
# FASE 6 — UDP SCAN
# ============================================
fase6_udp() {
    local alvo=$1
    local dir=$2
    titulo "FASE 6 — UDP SCAN (Top 20 portas)"
    info "UDP é mais lento — verificando portas críticas..."

    nmap -sU \
        --top-ports 20 \
        -T4 \
        "$alvo" \
        -oN "${dir}/fase6_udp.txt" 2>/dev/null

    grep "open" "${dir}/fase6_udp.txt" | while read linha; do
        ok "$linha"
    done
}

# ============================================
# RELATÓRIO FINAL
# ============================================
relatorio_final() {
    local alvo=$1
    local dir=$2
    titulo "RELATÓRIO FINAL"

    RELATORIO="${dir}/RELATORIO_COMPLETO.txt"

    {
        echo "═══════════════════════════════════════════"
        echo "        NMAP RECON - RELATÓRIO COMPLETO"
        echo "═══════════════════════════════════════════"
        echo "Alvo    : $alvo"
        echo "Data    : $(date)"
        echo "Autor   : Felipe Diassis"
        echo "GitHub  : github.com/felipeds-cdc"
        echo "═══════════════════════════════════════════"
        echo ""

        for fase in fase1 fase2 fase3 fase4 fase5 fase6; do
            arquivo="${dir}/${fase}_*.txt"
            for f in $arquivo; do
                if [ -f "$f" ]; then
                    echo ""
                    echo "--- $(basename $f) ---"
                    cat "$f"
                fi
            done
        done

        echo ""
        echo "═══════════════════════════════════════════"
        echo "⚠ USO EXCLUSIVAMENTE EDUCACIONAL"
        echo "⚠ Lei 12.737/2012 - Brasil"
        echo "═══════════════════════════════════════════"
    } > "$RELATORIO"

    ok "Relatório salvo em: $RELATORIO"
    ok "Pasta completa   : $dir/"
    info "Arquivos gerados:"
    ls -lh "$dir/" | while read linha; do
        echo "    $linha"
    done
}

# ============================================
# MAIN
# ============================================
main() {
    banner
    verificar_deps

    if [ $# -lt 1 ]; then
        echo -e "  ${BOLD}USO:${RESET}"
        echo "    ./nmap_recon.sh <alvo> [modo]"
        echo ""
        echo -e "  ${BOLD}MODOS:${RESET}"
        echo "    full     Todas as fases (padrão)"
        echo "    rapido   Só fases 1, 2 e 4"
        echo "    vuln     Foco em vulnerabilidades"
        echo ""
        echo -e "  ${BOLD}EXEMPLOS:${RESET}"
        echo "    ./nmap_recon.sh 192.168.1.1"
        echo "    ./nmap_recon.sh 192.168.1.1 rapido"
        echo "    ./nmap_recon.sh scanme.nmap.org vuln"
        echo ""
        exit 1
    fi

    ALVO=$1
    MODO=${2:-full}
    OUTPUT_DIR=$(criar_output "$ALVO")

    echo -e "  ${BOLD}Alvo  :${RESET} $ALVO"
    echo -e "  ${BOLD}Modo  :${RESET} $MODO"
    echo -e "  ${BOLD}Output:${RESET} $OUTPUT_DIR"

    case $MODO in
        rapido)
            fase1_descoberta "$ALVO" "$OUTPUT_DIR"
            fase2_top1000    "$ALVO" "$OUTPUT_DIR"
            fase4_versoes    "$ALVO" "$OUTPUT_DIR" ""
            ;;
        vuln)
            fase1_descoberta "$ALVO" "$OUTPUT_DIR"
            PORTAS=$(fase3_full_scan "$ALVO" "$OUTPUT_DIR")
            fase5_scripts    "$ALVO" "$OUTPUT_DIR" "$PORTAS"
            ;;
        full|*)
            fase1_descoberta "$ALVO" "$OUTPUT_DIR"
            fase2_top1000    "$ALVO" "$OUTPUT_DIR"
            PORTAS=$(fase3_full_scan "$ALVO" "$OUTPUT_DIR")
            fase4_versoes    "$ALVO" "$OUTPUT_DIR" "$PORTAS"
            fase5_scripts    "$ALVO" "$OUTPUT_DIR" "$PORTAS"
            fase6_udp        "$ALVO" "$OUTPUT_DIR"
            ;;
    esac

    relatorio_final "$ALVO" "$OUTPUT_DIR"

    echo -e "\n  ${YELLOW}⚠  Use apenas em alvos autorizados — Lei 12.737/2012${RESET}\n"
}

main "$@"