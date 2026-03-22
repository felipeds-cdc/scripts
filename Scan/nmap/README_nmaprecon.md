# 🗺️ nmap_recon.sh — Documentação Completa

**Autor:** Felipe Diassis  
**GitHub:** [github.com/felipeds-cdc](https://github.com/felipeds-cdc)  
**Versão:** 1.0  

> ⚠️ **AVISO LEGAL:** Este script é estritamente educacional.  
> Use apenas em sistemas e redes que você tem autorização para testar.  
> O uso não autorizado configura crime — **Lei 12.737/2012**.

---

## 📋 Índice

- [O que é o script](#-o-que-é-o-script)
- [Requisitos](#-requisitos)
- [Como instalar](#-como-instalar)
- [Como rodar](#-como-rodar)
- [Modos de execução](#-modos-de-execução)
- [Estrutura do código](#-estrutura-do-código)
- [Fases do scan](#-fases-do-scan)
- [Arquivos gerados](#-arquivos-gerados)
- [Como manter o código](#-como-manter-o-código)
- [Exemplos reais](#-exemplos-reais)
- [Solução de problemas](#-solução-de-problemas)

---

## 🔍 O que é o script

O `nmap_recon.sh` automatiza o processo de reconhecimento ativo de um alvo
usando o Nmap em múltiplas fases. Em vez de rodar comandos Nmap manualmente
um por um, o script executa tudo em sequência e salva os resultados organizados
em uma pasta com timestamp.

**Fluxo resumido:**
```
Alvo informado
    ↓
Fase 1: Host está online?
    ↓
Fase 2: Quais portas estão abertas? (top 1000)
    ↓
Fase 3: Scan completo de todas as 65535 portas
    ↓
Fase 4: Quais serviços e versões rodam nessas portas?
    ↓
Fase 5: Existem vulnerabilidades conhecidas?
    ↓
Fase 6: Portas UDP abertas?
    ↓
Relatório final consolidado
```

---

## 🖥️ Requisitos

| Requisito   | Versão mínima | Como verificar          |
|-------------|---------------|-------------------------|
| Bash        | 4.0+          | `bash --version`        |
| Nmap        | 7.0+          | `nmap --version`        |
| Linux/macOS | Qualquer      | —                       |
| Root/sudo   | Necessário    | Para scans SYN (-sS)    |

> **Importante:** O script usa `nmap -sS` (SYN scan) que exige privilégios
> de root. Sem root, o Nmap cai para TCP connect scan automaticamente,
> o que pode ser mais lento e menos preciso.

---

## 🔧 Como instalar

```bash
# 1. Baixar o script
git clone https://github.com/felipeds-cdc/cybersecurity-studies.git
cd cybersecurity-studies/nmap-recon

# 2. Dar permissão de execução
chmod +x nmap_recon.sh

# 3. Instalar dependências (se necessário)
sudo apt update
sudo apt install nmap -y

# 4. Verificar instalação
nmap --version
```

---

## 🚀 Como rodar

### Sintaxe
```bash
./nmap_recon.sh <alvo> [modo]
```

### Parâmetros
| Parâmetro | Obrigatório | Descrição                          |
|-----------|-------------|------------------------------------|
| `<alvo>`  | ✅ Sim       | IP ou domínio do alvo              |
| `[modo]`  | ❌ Não       | `full`, `rapido` ou `vuln`         |

### Exemplos rápidos
```bash
# Scan completo em IP local (mais comum no lab)
sudo ./nmap_recon.sh 192.168.1.100

# Scan rápido
sudo ./nmap_recon.sh 192.168.1.100 rapido

# Foco em vulnerabilidades
sudo ./nmap_recon.sh 192.168.1.100 vuln

# Alvo público autorizado para testes (nmap oficial)
sudo ./nmap_recon.sh scanme.nmap.org
```

> 💡 **Dica:** Use `scanme.nmap.org` para testar o script sem precisar de
> um alvo próprio. Esse servidor existe exatamente para testes de Nmap.

---

## ⚙️ Modos de execução

### `full` (padrão)
Executa todas as 6 fases. Mais completo, porém mais demorado.
Ideal para análise aprofundada de um alvo.

```bash
sudo ./nmap_recon.sh 192.168.1.1
# ou
sudo ./nmap_recon.sh 192.168.1.1 full
```

**Tempo estimado:** 5 a 30 minutos dependendo do alvo.

---

### `rapido`
Executa apenas as fases 1, 2 e 4. Ideal para uma visão geral rápida.

```bash
sudo ./nmap_recon.sh 192.168.1.1 rapido
```

**Fases executadas:** Descoberta → Top 1000 portas → Versões  
**Tempo estimado:** 1 a 3 minutos.

---

### `vuln`
Foca na descoberta de vulnerabilidades. Executa fases 1, 3 e 5.

```bash
sudo ./nmap_recon.sh 192.168.1.1 vuln
```

**Fases executadas:** Descoberta → Scan completo → Scripts NSE  
**Tempo estimado:** 10 a 40 minutos.

---

## 🏗️ Estrutura do código

O script é dividido em blocos independentes (funções). Cada função tem uma
responsabilidade única, facilitando manutenção e expansão.

```
nmap_recon.sh
│
├── Variáveis de cor          (linhas ~15-22)
│   └── Define cores para output no terminal
│
├── banner()                  (linhas ~25-35)
│   └── Exibe o cabeçalho visual do script
│
├── titulo() / ok() / info() / erro()   (linhas ~38-42)
│   └── Funções auxiliares de output colorido
│
├── verificar_deps()          (linhas ~45-52)
│   └── Verifica se o nmap está instalado antes de continuar
│
├── criar_output()            (linhas ~55-62)
│   └── Cria a pasta com timestamp para salvar os resultados
│
├── fase1_descoberta()        (linhas ~65-80)
│   └── Ping scan — verifica se o host está online
│
├── fase2_top1000()           (linhas ~83-98)
│   └── Scan das 1000 portas mais comuns
│
├── fase3_full_scan()         (linhas ~101-122)
│   └── Scan completo de todas as 65535 portas
│   └── Retorna lista de portas abertas para fases seguintes
│
├── fase4_versoes()           (linhas ~125-150)
│   └── Detecta versões de serviços e sistema operacional
│
├── fase5_scripts()           (linhas ~153-178)
│   └── Executa scripts NSE: default, vuln, auth
│   └── Destaca vulnerabilidades encontradas em vermelho
│
├── fase6_udp()               (linhas ~181-196)
│   └── Scan UDP nas 20 portas mais críticas
│
├── relatorio_final()         (linhas ~199-230)
│   └── Consolida todos os arquivos num relatório único
│
└── main()                    (linhas ~233-fim)
    └── Controla o fluxo e escolhe o modo de execução
```

---

## 📡 Fases do scan

### Fase 1 — Descoberta de Host
```bash
nmap -sn <alvo>
```
**O que faz:** Envia pacotes ICMP (ping) para verificar se o host responde.  
**Por que importa:** Evita perder tempo escaneando hosts offline.  
**Arquivo gerado:** `fase1_descoberta.txt`

---

### Fase 2 — Top 1000 Portas
```bash
nmap -sS -T4 --open <alvo>
```
**O que faz:** Escaneia as 1000 portas TCP mais usadas no mundo.  
**Flags usadas:**
- `-sS` → SYN scan (stealth, mais rápido, requer root)
- `-T4` → Velocidade agressiva
- `--open` → Mostra só portas abertas  

**Arquivo gerado:** `fase2_top1000.txt`

---

### Fase 3 — Scan Completo
```bash
nmap -sS -T4 -p- --open --min-rate 1000 <alvo>
```
**O que faz:** Escaneia todas as 65.535 portas TCP.  
**Flags usadas:**
- `-p-` → Todas as portas
- `--min-rate 1000` → Mínimo de 1000 pacotes/segundo  

**Por que importa:** Serviços mal configurados costumam rodar em portas
não padrão (ex: SSH na porta 2222 em vez de 22).  
**Arquivo gerado:** `fase3_fullscan.txt`

---

### Fase 4 — Versões e SO
```bash
nmap -sV -O --version-intensity 7 <alvo>
```
**O que faz:** Identifica a versão exata de cada serviço e o sistema
operacional do alvo.  
**Flags usadas:**
- `-sV` → Detecta versões de serviços
- `-O` → Detecta sistema operacional
- `--version-intensity 7` → Intensidade alta de detecção (0-9)

**Por que importa:** Versões específicas podem ter CVEs conhecidos.  
**Arquivo gerado:** `fase4_versoes.txt`

---

### Fase 5 — Scripts NSE
```bash
nmap -sV --script="default,vuln,auth" <alvo>
```
**O que faz:** Executa scripts automáticos do Nmap Scripting Engine (NSE)
para detectar vulnerabilidades, configurações fracas e autenticação padrão.  
**Scripts usados:**
- `default` → Scripts básicos de enumeração
- `vuln` → Busca CVEs e vulnerabilidades conhecidas
- `auth` → Testa credenciais padrão (admin/admin, etc.)

**Arquivo gerado:** `fase5_scripts.txt`

---

### Fase 6 — UDP Scan
```bash
nmap -sU --top-ports 20 -T4 <alvo>
```
**O que faz:** Escaneia as 20 portas UDP mais importantes.  
**Por que importa:** UDP é frequentemente ignorado em pentests, mas serviços
críticos como DNS (53), SNMP (161) e TFTP (69) rodam em UDP.  
**Arquivo gerado:** `fase6_udp.txt`

---

## 📁 Arquivos gerados

Após a execução, uma pasta é criada automaticamente:

```
nmap_results/
└── 192.168.1.100_20260321_143022/
    ├── fase1_descoberta.txt      ← host online?
    ├── fase2_top1000.txt         ← top 1000 portas
    ├── fase3_fullscan.txt        ← todas as portas
    ├── fase4_versoes.txt         ← versões e SO
    ├── fase5_scripts.txt         ← vulnerabilidades NSE
    ├── fase6_udp.txt             ← portas UDP
    └── RELATORIO_COMPLETO.txt    ← tudo consolidado
```

> 💡 O timestamp no nome da pasta (`20260321_143022`) garante que scans
> diferentes do mesmo alvo nunca sobrescrevem resultados anteriores.

---

## 🔧 Como manter o código

### Adicionar uma nova fase
Para adicionar uma Fase 7, siga o padrão existente:

```bash
# 1. Criar a função seguindo o padrão
fase7_minha_fase() {
    local alvo=$1
    local dir=$2
    titulo "FASE 7 — NOME DA FASE"
    info "Descrição do que está fazendo..."

    # Seu comando nmap aqui
    nmap <flags> "$alvo" -oN "${dir}/fase7_minha_fase.txt" 2>/dev/null

    # Exibir resultados
    grep "open" "${dir}/fase7_minha_fase.txt" | while read linha; do
        ok "$linha"
    done
}

# 2. Chamar a função no bloco main() dentro do case "full"
full|*)
    ...
    fase7_minha_fase "$ALVO" "$OUTPUT_DIR"  # ← adicionar aqui
    ;;
```

---

### Alterar velocidade do scan
Mude o valor de `-T` nas funções desejadas:

| Flag | Velocidade   | Quando usar                        |
|------|--------------|------------------------------------|
| `-T1`| Muito lento  | Evasão de IDS/firewall             |
| `-T2`| Lento        | Redes instáveis                    |
| `-T3`| Normal       | Padrão equilibrado                 |
| `-T4`| Rápido       | Redes locais (atual no script)     |
| `-T5`| Insano       | Só em redes muito estáveis         |

---

### Adicionar novo script NSE na Fase 5
```bash
# Linha atual na fase5_scripts():
--script="default,vuln,auth"

# Para adicionar scripts de SMB por exemplo:
--script="default,vuln,auth,smb-vuln*"

# Para HTTP específico:
--script="default,vuln,auth,http-enum,http-shellshock"
```

---

### Onde estão os scripts NSE do Nmap
```bash
ls /usr/share/nmap/scripts/         # Lista todos os scripts
ls /usr/share/nmap/scripts/ | grep vuln   # Só os de vulnerabilidade
nmap --script-help vuln             # Ajuda sobre categoria vuln
```

---

## 💡 Exemplos reais

### Lab com Metasploitable2
```bash
# Metasploitable geralmente fica em 192.168.x.x
# Descubra o IP dela com:
sudo netdiscover -r 192.168.1.0/24

# Rode o script completo
sudo ./nmap_recon.sh 192.168.1.105 full
```

### Alvo público autorizado
```bash
# scanme.nmap.org existe para testes
sudo ./nmap_recon.sh scanme.nmap.org rapido
```

### Scan de rede inteira (CIDR)
```bash
# Descobre todos os hosts e portas da rede local
sudo ./nmap_recon.sh 192.168.1.0/24 rapido
```

---

## 🛠️ Solução de problemas

**Erro: `nmap: command not found`**
```bash
sudo apt install nmap -y
```

**Erro: `Permission denied`**
```bash
chmod +x nmap_recon.sh
sudo ./nmap_recon.sh <alvo>
```

**Scan muito lento**
```bash
# Mude -T4 para -T5 nas funções ou use modo rapido
./nmap_recon.sh <alvo> rapido
```

**Host aparece offline mas está ligado**
```bash
# Alguns hosts bloqueiam ICMP — force com -Pn
# Edite fase1_descoberta() e adicione -Pn:
nmap -sn -Pn "$alvo"
```

**Fase 3 demorando demais**
```bash
# Aumente o --min-rate em fase3_full_scan():
# De: --min-rate 1000
# Para: --min-rate 5000
```

---

## 📚 Referências

- [Nmap Official Docs](https://nmap.org/docs.html)
- [Nmap NSE Scripts](https://nmap.org/nsedoc/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [HackTricks — Nmap](https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-network/nmap-summary-esp)

---

## ⚠️ Aviso Legal

```
Este script é desenvolvido exclusivamente para fins educacionais.
O uso em sistemas sem autorização expressa é crime no Brasil.
Lei nº 12.737/2012 — Delitos Informáticos.

Ambientes recomendados para prática:
  • Metasploitable2 (VM local)
  • HackTheBox (plataforma autorizada)
  • TryHackMe (plataforma autorizada)
  • scanme.nmap.org (autorizado pelo Nmap)
```
