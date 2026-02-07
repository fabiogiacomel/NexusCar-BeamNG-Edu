
import beamng_edu
import time

def main():
    print("🚀 Iniciando Teste de Piloto Automático...")
    
    try:
        # 1. Conectar ao carro (Localhost)
        carro = beamng_edu.Carro(ip="127.0.0.1")
        
        # 2. Executar sequência de comandos
        print("   Comando: Acelerar (2s)")
        carro.acelerar(2.0)
        
        time.sleep(0.5)
        
        print("   Comando: Direita (1s)")
        carro.direita(1.0)
        
        time.sleep(0.5)
        
        print("   Comando: Parar")
        carro.parar()
        
        # 3. Finalizar
        carro.desconectar()
        print("✅ Test Passed")
        
    except Exception as e:
        print(f"❌ Test Failed: {e}")
        exit(1)

if __name__ == "__main__":
    main()
