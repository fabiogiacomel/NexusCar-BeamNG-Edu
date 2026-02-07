# 🚗 NexusCar: BeamNG Education Platform

> **Do Tik-Tok para o Python:** Transformando o celular na sala de aula de distração em ferramenta de engenharia.

![Status](https://img.shields.io/badge/Status-Beta%20v0.1-blue)
![Focus](https://img.shields.io/badge/Education-STEM-green)
![Tech](https://img.shields.io/badge/Python-Docker-orange)

## 🎯 O Problema
A escassez de laboratórios de informática e o uso excessivo de celulares para redes sociais são dois dos maiores desafios da educação moderna. O aluno tem um supercomputador no bolso, mas o usa apenas para consumo passivo.

## 💡 A Solução NexusCar
O **NexusCar** é uma plataforma "Zero-Install" para alunos. O professor projeta a simulação (BeamNG.drive) no telão, e o aluno usa seu próprio celular para programar a inteligência do carro em tempo real.

**Como funciona:**
1. O Professor roda o Servidor (Simulação + Física).
2. Um QR Code é gerado no telão.
3. O Aluno scaneia com o celular e acessa um Editor de Código Web (IDE).
4. O Aluno escreve scripts em Python (Lógica, Repetição, Condicionais).
5. O código roda na nuvem local (Docker) e controla o carro no telão via TCP/UDP.

## 🏆 Benefícios Pedagógicos
* **Inclusão Digital (BYOD):** Dispensa laboratórios caros. Se o aluno tem celular, ele tem um computador de desenvolvimento.
* **Feedback Visual Imediato:** O erro de lógica não é um texto vermelho, é o carro batendo no muro. O aprendizado é instantâneo.
* **Interdisciplinaridade:** Ensina Física (Cinemática), Matemática (Lógica Booleana) e Inglês técnico simultaneamente.
* **Trabalho em Equipe:** O sistema de filas incentiva a colaboração e a discussão de estratégias (Algoritmos) enquanto um colega "pilota".

## 🛠️ Arquitetura Técnica
O sistema utiliza uma arquitetura de microsserviços moderna:
* **Backend:** Docker Container rodando Python FastAPI (Gerenciamento de Fila e Sandbox de Execução).
* **Frontend:** Web App Responsivo (HTML5/JS) acessível via Mobile.
* **Driver:** Servidor C++ standalone que injeta inputs via Win32 API e lê telemetria via OutGauge UDP.
* **Simulação:** BeamNG.drive (Soft-body physics engine).

## 🚀 Como Usar (Para Professores)

### Pré-requisitos
* PC com Windows 10/11 (Para rodar o jogo).
* BeamNG.drive instalado.
* Docker Desktop instalado.

### Passo a Passo
1.  Clone este repositório.
2.  Execute o script mestre:
    ```powershell
    .\MASTER_RUN.ps1
    ```
3.  Abra o navegador em `http://localhost:8000/projector` e projete o QR Code.
4.  Peça para os alunos escanearem e começarem a codar!

## 📚 Exemplo de Código do Aluno
O aluno não precisa configurar nada, apenas focar na lógica:

```python
# Desafio: Atravessar a ponte sem cair
print("Iniciando travessia...")

carro.acelerar(tempo=3) # Ganha inércia
carro.freio_mao(tempo=0.5) # Corrige a derrapagem

# Lógica de decisão
if carro.velocidade > 80:
    carro.frear(1)
else:
    carro.acelerar(1)
