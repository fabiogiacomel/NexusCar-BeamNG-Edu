
# Script de Automação de Build e Execução para NexusCar Server
# Autor: DevOps Automation Expert
# Objetivo: Compilar server.cpp via Docker e executar no Host Windows

$ErrorActionPreference = "Stop"

function Check-Docker {
    Write-Host "🔍 Verificando estado do Docker..." -ForegroundColor Cyan
    try {
        $dockerInfo = docker info 2>&1 | Out-Null
        Write-Host "✅ Docker está rodando." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERRO: O Docker não parece estar rodando ou não está instalado." -ForegroundColor Red
        Write-Host "Por favor, inicie o Docker Desktop e tente novamente."
        exit 1
    }
}

function Clean-Build {
    Write-Host "🧹 Limpando builds anteriores..." -ForegroundColor Cyan
    if (Test-Path "server.exe") {
        Remove-Item "server.exe" -Force
        Write-Host "✅ server.exe removido." -ForegroundColor Gray
    }
    else {
        Write-Host "   Nenhum arquivo antigo encontrado." -ForegroundColor Gray
    }
}

function Build-Image {
    Write-Host "🐳 Construindo imagem do compilador (beamng-builder)..." -ForegroundColor Cyan
    # Redirecionando output para null para manter limpo, a menos que falhe
    try {
        docker build -t beamng-builder . | Out-Null
        Write-Host "✅ Imagem Docker construída com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERRO ao construir a imagem Docker." -ForegroundColor Red
        Write-Host $_
        exit 1
    }
}

function Compile-Artifact {
    Write-Host "🔨 Compilando server.cpp (Cross-compilation Linux -> Windows)..." -ForegroundColor Cyan
    
    # Monta o diretório atual em /src e compila
    # Nota: Usamos ${PWD} que no PowerShell retorna o caminho atual
    $cmd = "x86_64-w64-mingw32-g++ server.cpp -o server.exe -static -lws2_32"
    
    try {
        docker run --rm -v "${PWD}:/src" beamng-builder sh -c $cmd
    }
    catch {
        Write-Host "❌ ERRO durante a execução do container de compilação." -ForegroundColor Red
        exit 1
    }

    if (Test-Path "server.exe") {
        Write-Host "✅ Compilação BEM SUCEDIDA! 'server.exe' criado." -ForegroundColor Green
    }
    else {
        Write-Host "❌ ERRO: O arquivo 'server.exe' não foi gerado. Verifique o código fonte." -ForegroundColor Red
        exit 1
    }
}

function Check-Firewall {
    $Port = 65432
    Write-Host "🛡️ Verificando regras de Firewall para porta $Port..." -ForegroundColor Cyan
    
    $ruleName = "NexusCar-Server-TCP-$Port"
    $ruleExists = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    if ($ruleExists) {
        Write-Host "✅ Regra de firewall já existe." -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Regra não encontrada. Tentando criar..." -ForegroundColor Yellow
        
        # Verifica se é Admin
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            try {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
                Write-Host "✅ Regra de firewall criada com sucesso." -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Falha ao criar regra de firewall: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "❌ AVISO: Não é possível criar a regra de firewall automaticamente sem privilégios de Administrador." -ForegroundColor Red
            Write-Host "   O servidor pode não ser acessível por outros dispositivos na rede." -ForegroundColor Red
            Write-Host "   Execute este script como Administrador para corrigir isso automaticamente." -ForegroundColor Yellow
        }
    }
}

function Run-Server {
    Write-Host "🚀 Iniciando Servidor NexusCar..." -ForegroundColor Magenta
    Write-Host "   Pressione Ctrl+C para parar." -ForegroundColor Gray
    
    # Inicia o servidor no console atual
    .\server.exe
}

# --- Fluxo Principal ---
Clear-Host
Write-Host "==========================================" -ForegroundColor White
Write-Host "   NexusCar - Automação de Build & Run    " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor White

Check-Docker
Clean-Build
Build-Image
Compile-Artifact
Check-Firewall
Run-Server
