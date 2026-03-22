#!/usr/bin/env python3
# ============================================
# Footprinting Tool - Educacional
# Autor: Felipe Diassis
# GitHub: github.com/felipeds-cdc
# ============================================
# AVISO: Use apenas em alvos autorizados.
# Lei 12.737/2012
# ============================================

import socket
import subprocess
import sys
import json
import datetime
import urllib.request
import urllib.error

RED    = "\033[31m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

def banner():
    print(f"""
{CYAN}{BOLD}
╔══════════════════════════════════════════════╗
║           FOOTPRINTING TOOL v1.0             ║
║        github.com/felipeds-cdc               ║
║   ⚠  Apenas para fins educacionais  ⚠        ║
╚══════════════════════════════════════════════╝
{RESET}""")

def titulo(texto):
    print(f"\n{CYAN}{BOLD}{'═'*50}")
    print(f"  {texto}")
    print(f"{'═'*50}{RESET}")

def ok(texto):
    print(f"  {GREEN}[+]{RESET} {texto}")

def info(texto):
    print(f"  {YELLOW}[*]{RESET} {texto}")

def erro(texto):
    print(f"  {RED}[!]{RESET} {texto}")

def salvar_resultado(alvo, dados):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    nome_arquivo = f"footprint_{alvo}_{timestamp}.txt"
    with open(nome_arquivo, "w") as f:
        f.write(f"FOOTPRINTING REPORT\n")
        f.write(f"Alvo    : {alvo}\n")
        f.write(f"Data    : {datetime.datetime.now()}\n")
        f.write(f"{'='*50}\n\n")
        for secao, conteudo in dados.items():
            f.write(f"\n[{secao}]\n")
            if isinstance(conteudo, list):
                for item in conteudo:
                    f.write(f"  {item}\n")
            else:
                f.write(f"  {conteudo}\n")
    return nome_arquivo

# 1. RESOLUÇÃO DE IP
def resolver_ip(alvo):
    titulo("1. RESOLUÇÃO DE IP")
    resultados = []
    try:
        ip = socket.gethostbyname(alvo)
        ok(f"Hostname : {alvo}")
        ok(f"IP       : {ip}")
        resultados.append(f"Hostname: {alvo}")
        resultados.append(f"IP: {ip}")

        # Reverse DNS
        try:
            reverse = socket.gethostbyaddr(ip)[0]
            ok(f"Reverse  : {reverse}")
            resultados.append(f"Reverse DNS: {reverse}")
        except:
            info("Reverse DNS não encontrado")

        return ip, resultados
    except socket.gaierror as e:
        erro(f"Não foi possível resolver: {alvo}")
        return None, resultados

# 2. WHOIS
def whois(alvo):
    titulo("2. WHOIS")
    resultados = []
    try:
        resultado = subprocess.run(
            ["whois", alvo],
            capture_output=True, text=True, timeout=15
        )
        linhas_uteis = []
        campos = [
            "registrar", "creation date", "expiration date",
            "updated date", "name server", "registrant",
            "org:", "country", "dnssec"
        ]
        for linha in resultado.stdout.splitlines():
            for campo in campos:
                if campo.lower() in linha.lower() and linha.strip():
                    ok(linha.strip())
                    linhas_uteis.append(linha.strip())
                    break

        resultados = linhas_uteis if linhas_uteis else ["Whois não retornou dados relevantes"]
    except FileNotFoundError:
        erro("whois não instalado. Execute: sudo apt install whois")
    except subprocess.TimeoutExpired:
        erro("Whois timeout")
    return resultados

# 3. DNS ENUMERATION
def dns_enum(alvo):
    titulo("3. DNS ENUMERATION")
    resultados = []
    tipos = ["A", "MX", "NS", "TXT", "CNAME", "AAAA"]

    for tipo in tipos:
        try:
            resultado = subprocess.run(
                ["dig", "+short", tipo, alvo],
                capture_output=True, text=True, timeout=10
            )
            saida = resultado.stdout.strip()
            if saida:
                ok(f"{tipo:<6} → {saida}")
                resultados.append(f"{tipo}: {saida}")
            else:
                info(f"{tipo:<6} → sem resultado")
        except FileNotFoundError:
            erro("dig não instalado. Execute: sudo apt install dnsutils")
            break
        except subprocess.TimeoutExpired:
            erro(f"Timeout no tipo {tipo}")

    return resultados

# 4. SUBDOMÍNIOS
def subdominios(alvo):
    titulo("4. SUBDOMÍNIOS COMUNS")
    resultados = []
    subs = [
        "www", "mail", "ftp", "admin", "portal",
        "vpn", "remote", "webmail", "dev", "test",
        "api", "app", "blog", "shop", "secure",
        "mx", "smtp", "pop", "imap", "ns1", "ns2"
    ]

    encontrados = 0
    for sub in subs:
        host = f"{sub}.{alvo}"
        try:
            ip = socket.gethostbyname(host)
            ok(f"{host:<35} → {ip}")
            resultados.append(f"{host} → {ip}")
            encontrados += 1
        except socket.gaierror:
            pass

    if encontrados == 0:
        info("Nenhum subdomínio comum encontrado")
    else:
        info(f"Total encontrado: {encontrados}")

    return resultados

# 5. HEADERS HTTP
def http_headers(alvo):
    titulo("5. HEADERS HTTP")
    resultados = []

    for protocolo in ["https", "http"]:
        url = f"{protocolo}://{alvo}"
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "Mozilla/5.0"}
            )
            resposta = urllib.request.urlopen(req, timeout=10)
            ok(f"URL     : {url}")
            ok(f"Status  : {resposta.status}")
            resultados.append(f"URL: {url}")
            resultados.append(f"Status: {resposta.status}")

            # Headers relevantes para segurança
            headers_seg = [
                "Server", "X-Powered-By", "X-Frame-Options",
                "Content-Security-Policy", "X-XSS-Protection",
                "Strict-Transport-Security", "X-Content-Type-Options",
                "Set-Cookie", "Location", "Via"
            ]
            for h in headers_seg:
                valor = resposta.headers.get(h)
                if valor:
                    ok(f"{h:<35}: {valor}")
                    resultados.append(f"{h}: {valor}")
                else:
                    info(f"{h:<35}: ausente")
            break
        except Exception as e:
            info(f"{protocolo.upper()} falhou: {e}")

    return resultados

# 6. GEO-IP
def geo_ip(ip):
    titulo("6. GEOLOCALIZAÇÃO DO IP")
    resultados = []
    try:
        url = f"https://ipinfo.io/{ip}/json"
        req = urllib.request.Request(
            url, headers={"User-Agent": "Mozilla/5.0"}
        )
        resposta = urllib.request.urlopen(req, timeout=10)
        dados = json.loads(resposta.read().decode())

        campos = {
            "IP"      : dados.get("ip", "N/A"),
            "Hostname": dados.get("hostname", "N/A"),
            "Cidade"  : dados.get("city", "N/A"),
            "Região"  : dados.get("region", "N/A"),
            "País"    : dados.get("country", "N/A"),
            "Org/ASN" : dados.get("org", "N/A"),
            "Timezone": dados.get("timezone", "N/A"),
        }
        for chave, valor in campos.items():
            ok(f"{chave:<10}: {valor}")
            resultados.append(f"{chave}: {valor}")
    except Exception as e:
        erro(f"Geo-IP falhou: {e}")

    return resultados

# 7. PORTAS ABERTAS (scan básico)
def scan_portas_basico(ip):
    titulo("7. SCAN DE PORTAS BÁSICO")
    resultados = []
    portas_comuns = {
        21: "FTP",    22: "SSH",   23: "Telnet",
        25: "SMTP",   53: "DNS",   80: "HTTP",
        110: "POP3",  143: "IMAP", 443: "HTTPS",
        445: "SMB",   3306: "MySQL", 3389: "RDP",
        5900: "VNC",  8080: "HTTP-Alt", 8443: "HTTPS-Alt"
    }

    info(f"Verificando {len(portas_comuns)} portas comuns...")
    abertas = 0
    for porta, servico in portas_comuns.items():
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            resultado = sock.connect_ex((ip, porta))
            sock.close()
            if resultado == 0:
                ok(f"Porta {porta:<6} ABERTA  → {servico}")
                resultados.append(f"Porta {porta} aberta: {servico}")
                abertas += 1
        except:
            pass

    info(f"Total de portas abertas: {abertas}")
    return resultados

# MAIN
def main():
    banner()

    if len(sys.argv) < 2:
        print(f"  {BOLD}USO:{RESET}")
        print(f"    python3 footprinting_tool.py <alvo>")
        print(f"\n  {BOLD}EXEMPLOS:{RESET}")
        print(f"    python3 footprinting_tool.py exemplo.com")
        print(f"    python3 footprinting_tool.py 192.168.1.1\n")
        sys.exit(1)

    alvo = sys.argv[1].replace("https://", "").replace("http://", "").rstrip("/")
    dados = {}

    print(f"\n  {BOLD}Alvo   :{RESET} {alvo}")
    print(f"  {BOLD}Início :{RESET} {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Executa módulos
    ip, dados["IP"] = resolver_ip(alvo)

    if not ip:
        erro("Não foi possível continuar sem resolver o IP.")
        sys.exit(1)

    dados["WHOIS"]       = whois(alvo)
    dados["DNS"]         = dns_enum(alvo)
    dados["SUBDOMINIOS"] = subdominios(alvo)
    dados["HTTP"]        = http_headers(alvo)
    dados["GEO_IP"]      = geo_ip(ip)
    dados["PORTAS"]      = scan_portas_basico(ip)

    # Salva relatório
    titulo("RELATÓRIO")
    arquivo = salvar_resultado(alvo, dados)
    ok(f"Relatório salvo: {arquivo}")
    print(f"\n  {YELLOW}⚠  Use apenas em alvos autorizados — Lei 12.737/2012{RESET}\n")

if __name__ == "__main__":
    main()