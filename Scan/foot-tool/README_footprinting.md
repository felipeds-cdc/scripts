# 🔍 footprinting_tool.py — Documentação Completa

**Autor:** Felipe Diassis  
**GitHub:** [github.com/felipeds-cdc](https://github.com/felipeds-cdc)  
**Versão:** 1.0  
**Linguagem:** Python 3

> ⚠️ **AVISO LEGAL:** Este script é estritamente educacional.  
> Use apenas em sistemas e domínios que você tem autorização para analisar.  
> O uso não autorizado configura crime — **Lei 12.737/2012**.

---

## 📋 Índice

- [O que é o script](#-o-que-é-o-script)
- [Diferença entre Footprinting e Scanning](#-diferença-entre-footprinting-e-scanning)
- [Requisitos](#-requisitos)
- [Como instalar](#-como-instalar)
- [Como rodar](#-como-rodar)
- [Estrutura do código](#-estrutura-do-código)
- [Módulos explicados](#-módulos-explicados)
- [Arquivos gerados](#-arquivos-gerados)
- [Como manter o código](#-como-manter-o-código)
- [Exemplos reais](#-exemplos-reais)
- [Solução de problemas](#-solução-de-problemas)

---

## 🔍 O que é o script

O `footprinting_tool.py` automatiza a fase de **reconhecimento passivo e
semi-passivo** de um alvo. Ele coleta o máximo de informações públicas
disponíveis sobre um domínio ou IP antes de qualquer interação direta
mais agressiva.

**Fluxo resumido:**
```
Alvo informado (domínio ou IP)
        ↓
Módulo 1: Resolve o IP do domínio + Reverse DNS
        ↓
Módulo 2: WHOIS — quem é o dono do domínio?
        ↓
Módulo 3: DNS Enumeration — registros A, MX, NS, TXT...
        ↓
Módulo 4: Subdomínios comuns — www, mail, ftp, admin...
        ↓
Módulo 5: Headers HTTP — qual servidor? quais tecnologias?
        ↓
Módulo 6: Geo-IP — onde está o servidor?
        ↓
Módulo 7: Scan básico de portas conhecidas
        ↓
Relatório salvo em arquivo .txt
```

---

## 🎯 Diferença entre Footprinting e Scanning

É importante entender quando usar cada ferramenta:

| Característica     | Footprinting (este script) | Nmap Recon            |
|--------------------|----------------------------|-----------------------|
| Tipo               | Passivo / semi-passivo     | Ativo                 |
| Intrusividade      | Baixa                      | Alta                  |
| O que coleta       | Info pública do alvo       | Portas e serviços     |
| Detecção pelo alvo | Difícil                    | Fácil                 |
| Quando usar        | Fase inicial               | Após footprinting     |
| Analogia           | Pesquisar alguém no Google | Bater na porta        |

> 💡 **Regra geral:** Sempre comece pelo footprinting antes de partir
> para scans mais agressivos como o Nmap.

---

## 🖥️ Requisitos

| Requisito   | Versão mínima | Como verificar        |
|-------------|---------------|-----------------------|
| Python      | 3.6+          | `python3 --version`   |
| whois       | Qualquer      | `whois --version`     |
| dig         | Qualquer      | `dig -v`              |
| Conexão     | Necessária    | Para APIs externas    |

### Bibliotecas Python usadas
Todas são nativas do Python — **não precisa instalar nada via pip:**

| Biblioteca       | Para que serve no script              |
|------------------|---------------------------------------|
| `socket`         | Resolver IPs e escanear portas        |
| `subprocess`     | Executar whois e dig no terminal      |
| `sys`            | Ler argumentos da linha de comando    |
| `json`           | Processar resposta da API de Geo-IP   |
| `datetime`       | Gerar timestamp no relatório          |
| `urllib.request` | Fazer requisições HTTP (headers/GeoIP)|
| `urllib.error`   | Tratar erros de conexão HTTP          |

---

## 🔧 Como instalar

```bash
# 1. Clonar o repositório
git clone https://github.com/felipeds-cdc/cybersecurity-studies.git
cd cybersecurity-studies/footprinting

# 2. Instalar dependências do sistema (se necessário)
sudo apt update
sudo apt install whois dnsutils -y

# 3. Verificar Python
python3 --version

# 4. Verificar dependências
whois --version
dig -v
```

---

## 🚀 Como rodar

### Sintaxe
```bash
python3 footprinting_tool.py <alvo>
```

### Parâmetros
| Parâmetro | Obrigatório | Descrição                              |
|-----------|-------------|----------------------------------------|
| `<alvo>`  | ✅ Sim       | Domínio (ex: google.com) ou IP         |

> 💡 O script aceita URLs completas e remove automaticamente
> `https://` e `http://` — não precisa limpar antes de passar.

### Exemplos rápidos
```bash
# Com domínio
python3 footprinting_tool.py exemplo.com

# Com URL completa (script limpa automaticamente)
python3 footprinting_tool.py https://exemplo.com

# Com IP direto
python3 footprinting_tool.py 192.168.1.1

# Alvo público para testes
python3 footprinting_tool.py scanme.nmap.org
```

---

## 🏗️ Estrutura do código

O script é organizado em funções independentes, cada uma responsável
por um módulo de coleta. Isso facilita adicionar, remover ou modificar
qualquer módulo sem afetar os outros.

```
footprinting_tool.py
│
├── Constantes de cor              (linhas ~15-22)
│   └── Variáveis RED, GREEN, YELLOW, CYAN, BOLD, RESET
│   └── Usadas para colorir o output no terminal
│
├── banner()                       (linhas ~25-35)
│   └── Exibe o cabeçalho visual do script
│
├── titulo()                       (linhas ~38-40)
│   └── Imprime cabeçalho de seção com linha separadora
│
├── ok()                           (linha ~42)
│   └── Imprime resultado positivo em verde [+]
│
├── info()                         (linha ~43)
│   └── Imprime informação neutra em amarelo [*]
│
├── erro()                         (linha ~44)
│   └── Imprime erro em vermelho [!]
│
├── salvar_resultado()             (linhas ~47-62)
│   └── Recebe dicionário com todos os dados coletados
│   └── Gera arquivo .txt com timestamp no nome
│
├── resolver_ip()                  (linhas ~65-85)
│   └── MÓDULO 1: Resolve hostname → IP e faz Reverse DNS
│   └── Retorna o IP para os módulos seguintes usarem
│
├── whois()                        (linhas ~88-108)
│   └── MÓDULO 2: Executa comando whois e filtra campos úteis
│
├── dns_enum()                     (linhas ~111-133)
│   └── MÓDULO 3: Consulta registros DNS via dig
│
├── subdominios()                  (linhas ~136-160)
│   └── MÓDULO 4: Força bruta de subdomínios comuns
│
├── http_headers()                 (linhas ~163-195)
│   └── MÓDULO 5: Faz requisição HTTP e analisa headers
│
├── geo_ip()                       (linhas ~198-220)
│   └── MÓDULO 6: Consulta API ipinfo.io para localização
│
├── scan_portas_basico()           (linhas ~223-248)
│   └── MÓDULO 7: Testa conexão TCP nas portas mais comuns
│
└── main()                         (linhas ~251-fim)
    └── Valida argumentos, chama módulos e salva relatório
```

---

## 📦 Módulos explicados

### Módulo 1 — Resolução de IP
```python
def resolver_ip(alvo):
    ip = socket.gethostbyname(alvo)        # DNS lookup: dominio → IP
    reverse = socket.gethostbyaddr(ip)[0]  # Reverse DNS: IP → hostname
```
**O que faz:** Converte domínio em IP e tenta o caminho inverso (Reverse DNS).  
**Por que importa:** Revela se o alvo usa CDN (Cloudflare, Akamai) ou
aponta direto para o servidor real.  
**Retorna:** O IP resolvido, que é passado para os módulos seguintes.

---

### Módulo 2 — WHOIS
```python
def whois(alvo):
    resultado = subprocess.run(["whois", alvo], ...)
```
**O que faz:** Executa o comando `whois` do sistema e filtra apenas os
campos mais relevantes: registrador, datas, nameservers, país.  
**Por que importa:** Revela quem registrou o domínio, quando expira,
e quais nameservers usa — útil para mapear a infraestrutura.  
**Campos filtrados:** registrar, creation date, expiration date,
updated date, name server, org, country, dnssec.

---

### Módulo 3 — DNS Enumeration
```python
def dns_enum(alvo):
    tipos = ["A", "MX", "NS", "TXT", "CNAME", "AAAA"]
    resultado = subprocess.run(["dig", "+short", tipo, alvo], ...)
```
**O que faz:** Consulta 6 tipos de registro DNS para o alvo.  
**Por que importa:**

| Registro | O que revela                              |
|----------|-------------------------------------------|
| `A`      | IP do servidor principal                  |
| `MX`     | Servidores de email (possível alvo)       |
| `NS`     | Nameservers (onde o DNS é gerenciado)     |
| `TXT`    | SPF, DKIM, verificações do Google/outros  |
| `CNAME`  | Aliases — pode revelar subdomínios        |
| `AAAA`   | IPv6 do servidor                          |

---

### Módulo 4 — Subdomínios
```python
def subdominios(alvo):
    subs = ["www", "mail", "ftp", "admin", "portal", "vpn", ...]
    ip = socket.gethostbyname(f"{sub}.{alvo}")
```
**O que faz:** Tenta resolver uma lista de 21 subdomínios comuns.
Se o DNS responder, o subdomínio existe.  
**Por que importa:** Subdomínios como `admin.`, `dev.`, `test.` frequentemente
apontam para sistemas menos protegidos que o site principal.  
**Como expandir:** Para adicionar mais subdomínios, edite a lista `subs`:
```python
subs = [
    "www", "mail", "ftp", "admin",
    "staging",    # ← adicione aqui
    "homolog",    # ← e aqui
    ...
]
```

---

### Módulo 5 — Headers HTTP
```python
def http_headers(alvo):
    resposta = urllib.request.urlopen(req, timeout=10)
    valor = resposta.headers.get(h)
```
**O que faz:** Faz uma requisição HTTP/HTTPS e analisa os headers
da resposta, focando nos relacionados à segurança.  
**Por que importa:**

| Header                      | O que revela / indica                     |
|-----------------------------|-------------------------------------------|
| `Server`                    | Servidor web e versão (Apache, Nginx...)  |
| `X-Powered-By`              | Linguagem backend (PHP, ASP.NET...)       |
| `X-Frame-Options`           | Proteção contra Clickjacking              |
| `Content-Security-Policy`   | Política de segurança de conteúdo         |
| `X-XSS-Protection`          | Proteção XSS do navegador                 |
| `Strict-Transport-Security` | HSTS — força HTTPS                        |
| `Set-Cookie`                | Flags de segurança nos cookies            |

> 💡 Headers **ausentes** são tão importantes quanto os presentes —
> a falta de `X-Frame-Options` indica vulnerabilidade a Clickjacking.

---

### Módulo 6 — Geo-IP
```python
def geo_ip(ip):
    url = f"https://ipinfo.io/{ip}/json"
    dados = json.loads(resposta.read().decode())
```
**O que faz:** Consulta a API pública do `ipinfo.io` para obter
localização geográfica, provedor (ASN) e timezone do IP.  
**Por que importa:** Revela se o servidor está atrás de CDN, em
hosting compartilhado, ou em datacenter próprio.  
**API usada:** `ipinfo.io` — gratuita, sem necessidade de chave
para uso básico.

---

### Módulo 7 — Scan de Portas Básico
```python
def scan_portas_basico(ip):
    sock.connect_ex((ip, porta))  # Retorna 0 se porta aberta
```
**O que faz:** Tenta conexão TCP nas 15 portas mais comuns.
Diferente do Nmap, é um TCP connect simples e mais detectável.  
**Por que está aqui:** Dá uma visão inicial rápida sem precisar do Nmap.
Para análise aprofundada de portas, use o `nmap_recon.sh`.  
**Portas verificadas:**

| Porta | Serviço   | Porta | Serviço    |
|-------|-----------|-------|------------|
| 21    | FTP       | 443   | HTTPS      |
| 22    | SSH       | 445   | SMB        |
| 23    | Telnet    | 3306  | MySQL      |
| 25    | SMTP      | 3389  | RDP        |
| 53    | DNS       | 5900  | VNC        |
| 80    | HTTP      | 8080  | HTTP-Alt   |
| 110   | POP3      | 8443  | HTTPS-Alt  |
| 143   | IMAP      |       |            |

---

### Função salvar_resultado()
```python
def salvar_resultado(alvo, dados):
    nome_arquivo = f"footprint_{alvo}_{timestamp}.txt"
    for secao, conteudo in dados.items():
        f.write(f"\n[{secao}]\n")
```
**O que faz:** Recebe um dicionário `dados` com todos os resultados
dos módulos e salva em arquivo `.txt` formatado com timestamp.  
**Formato do arquivo:** Cada módulo vira uma seção `[NOME]` no arquivo.  
**Nome gerado:** `footprint_exemplo.com_20260321_143022.txt`

---

## 📁 Arquivos gerados

Após executar o script, um arquivo é criado na pasta atual:

```
footprint_exemplo.com_20260321_143022.txt
```

**Conteúdo do arquivo:**
```
FOOTPRINTING REPORT
Alvo    : exemplo.com
Data    : 2026-03-21 14:30:22
==================================================

[IP]
  Hostname: exemplo.com
  IP: 93.184.216.34
  Reverse DNS: 93.184.216.34.in-addr.arpa

[WHOIS]
  Registrar: ICANN
  Creation Date: 1995-08-14
  ...

[DNS]
  A: 93.184.216.34
  MX: mail.exemplo.com
  ...

[SUBDOMINIOS]
  www.exemplo.com → 93.184.216.34
  mail.exemplo.com → 93.184.216.35
  ...

[HTTP]
  URL: https://exemplo.com
  Status: 200
  Server: Apache/2.4.41
  ...

[GEO_IP]
  IP: 93.184.216.34
  Cidade: Los Angeles
  País: US
  Org/ASN: AS15133 Edgecast Inc.
  ...

[PORTAS]
  Porta 80 aberta: HTTP
  Porta 443 aberta: HTTPS
```

---

## 🔧 Como manter o código

### Adicionar um novo módulo
Siga o padrão das funções existentes:

```python
# 1. Criar a função com a mesma assinatura
def meu_modulo(alvo):
    titulo("8. NOME DO MEU MÓDULO")
    resultados = []         # lista que será salva no relatório
    
    try:
        # sua lógica aqui
        ok(f"Resultado: {valor}")
        resultados.append(f"Campo: {valor}")
    except Exception as e:
        erro(f"Módulo falhou: {e}")
    
    return resultados       # sempre retornar lista

# 2. Chamar na função main() e salvar no dicionário dados
dados["MEU_MODULO"] = meu_modulo(alvo)
```

---

### Adicionar mais subdomínios para testar
Edite a lista `subs` dentro de `subdominios()`:

```python
subs = [
    # já existentes
    "www", "mail", "ftp", "admin", "portal",
    # adicione aqui
    "staging", "homolog", "uat", "beta",
    "intranet", "internal", "corp", "git",
    "jenkins", "jira", "confluence", "kibana"
]
```

---

### Trocar a API de Geo-IP
A API atual (`ipinfo.io`) é gratuita mas tem limite de requisições.
Para trocar por outra:

```python
# Opção 1: ip-api.com (gratuita, sem chave)
url = f"http://ip-api.com/json/{ip}"

# Opção 2: ipgeolocation.io (precisa de chave gratuita)
url = f"https://api.ipgeolocation.io/ipgeo?apiKey=SUA_CHAVE&ip={ip}"
```

---

### Alterar timeout das conexões
Todas as conexões usam `timeout=10` (10 segundos). Para alterar:

```python
# Em http_headers() — linha da requisição HTTP
resposta = urllib.request.urlopen(req, timeout=15)  # aumenta para 15s

# Em scan_portas_basico() — linha do socket
sock.settimeout(2)   # aumenta de 1 para 2 segundos por porta
```

> ⚠️ Aumentar o timeout do scan de portas multiplica o tempo total.
> Com 15 portas e timeout de 1s = até 15 segundos.
> Com timeout de 2s = até 30 segundos.

---

### Salvar em JSON além de TXT
Para adicionar saída em JSON, modifique `salvar_resultado()`:

```python
def salvar_resultado(alvo, dados):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Salva TXT (já existe)
    nome_txt = f"footprint_{alvo}_{timestamp}.txt"
    # ... código atual ...
    
    # Adicionar: salva JSON
    nome_json = f"footprint_{alvo}_{timestamp}.json"
    with open(nome_json, "w") as f:
        json.dump(dados, f, indent=2, ensure_ascii=False)
    
    return nome_txt
```

---

## 💡 Exemplos reais

### Analisar seu próprio domínio
```bash
python3 footprinting_tool.py seudominio.com.br
```

### Analisar alvo do TryHackMe (dentro da VPN)
```bash
# Conecte na VPN do TryHackMe primeiro
# Depois rode contra o IP da máquina
python3 footprinting_tool.py 10.10.x.x
```

### Integrar com nmap_recon.sh
```bash
# Passo 1: Footprinting para coletar informações gerais
python3 footprinting_tool.py alvo.com

# Passo 2: Usar o IP descoberto no scan Nmap
sudo ./nmap_recon.sh <ip-encontrado> full
```

---

## 🛠️ Solução de problemas

**Erro: `whois: command not found`**
```bash
sudo apt install whois -y
```

**Erro: `dig: command not found`**
```bash
sudo apt install dnsutils -y
```

**Erro: `socket.gaierror: [Errno -2] Name or service not known`**
```
O domínio não pôde ser resolvido.
Verifique se o domínio existe e se há conexão com a internet.
```

**Geo-IP retornando erro**
```
A API ipinfo.io pode estar com limite atingido.
Aguarde alguns minutos ou troque a API conforme explicado acima.
```

**Nenhum subdomínio encontrado**
```
Normal para domínios pequenos.
Para uma busca mais completa use:
  subfinder -d dominio.com
  sublist3r -d dominio.com
```

**Script muito lento no módulo de portas**
```python
# Edite scan_portas_basico() e reduza o timeout:
sock.settimeout(0.5)   # De 1s para 0.5s por porta
```

---

## 📚 Referências

- [OSINT Framework](https://osintframework.com)
- [ipinfo.io API](https://ipinfo.io/developers)
- [DNS Record Types](https://www.cloudflare.com/learning/dns/dns-records)
- [OWASP — Information Gathering](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/01-Information_Gathering)
- [HackTricks — Footprinting](https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-network)

---

## ⚠️ Aviso Legal

```
Este script é desenvolvido exclusivamente para fins educacionais.
O uso em sistemas sem autorização expressa é crime no Brasil.
Lei nº 12.737/2012 — Delitos Informáticos.

Ambientes recomendados para prática:
  • Domínios próprios
  • HackTheBox (plataforma autorizada)
  • TryHackMe (plataforma autorizada)
  • scanme.nmap.org (autorizado pelo Nmap)
```
