
import socket
import time

class Carro:
    """
    Classe Cliente (SDK) para controlar o carro no BeamNG.drive via servidor TCP.
    
    Esta biblioteca facilita o envio de comandos para o servidor C++ que interage
    diretamente com o jogo.
    """

    def __init__(self, ip="127.0.0.1", porta=65432):
        """
        Inicializa a conexão com o servidor do carro.
        
        Args:
            ip (str): Endereço IP do servidor (padrão: localhost).
            porta (int): Porta TCP do servidor.
        """
        self.ip = ip
        self.porta = porta
        self.sock = None
        
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.ip, self.porta))
            print(f"✅ Conectado ao servidor em {self.ip}:{self.porta}")
        except Exception as e:
            print(f"❌ Falha na conexão: {e}")
            raise e

    def _enviar(self, comando):
        """Método interno para enviar strings ao servidor."""
        if self.sock:
            try:
                self.sock.sendall((comando + "\n").encode('utf-8'))
            except Exception as e:
                print(f"⚠️ Erro de comunicação: {e}")

    def _executar(self, cmd_press, cmd_release, segundos):
        """
        Mantém um comando pressionado por X segundos.
        
        Args:
            cmd_press (str): Comando de pressionar tecla via protocolo.
            cmd_release (str): Comando de soltar tecla.
            segundos (float): Tempo de duração.
        """
        if segundos is None:
            self._enviar(cmd_press)
            return

        # Loop de keep-alive para evitar o watchdog do servidor (500ms)
        inicio = time.time()
        while (time.time() - inicio) < segundos:
            self._enviar(cmd_press)
            time.sleep(0.1)
        
        self._enviar(cmd_release)

    def acelerar(self, segundos=None):
        """
        Acelera o carro (W).
        
        Args:
            segundos (float): Tempo em segundos para manter acelerado.
        """
        self._executar("FWD_DN", "FWD_UP", segundos)

    def frear(self, segundos=None):
        """
        Freia ou dá ré no carro (S).
        
        Args:
            segundos (float): Tempo em segundos para frear.
        """
        self._executar("BCK_DN", "BCK_UP", segundos)

    def esquerda(self, segundos=None):
        """
        Vira para a esquerda (A).
        
        Args:
            segundos (float): Tempo mantendo a direção virada.
        """
        self._executar("LFT_DN", "LFT_UP", segundos)

    def direita(self, segundos=None):
        """
        Vira para a direita (D).
        
        Args:
            segundos (float): Tempo mantendo a direção virada.
        """
        self._executar("RGT_DN", "RGT_UP", segundos)

    def freio_mao(self, segundos=None):
        """
        Aciona o freio de mão (Espaço).
        
        Args:
            segundos (float): Tempo em segundos para manter o freio de mão puxado.
        """
        self._executar("HND_DN", "HND_UP", segundos)

    def parar(self):
        """Solta todas as teclas imediatamente."""
        self._enviar("FWD_UP")
        self._enviar("BCK_UP")
        self._enviar("LFT_UP")
        self._enviar("RGT_UP")
        self._enviar("BRK_UP")
        self._enviar("HND_UP")
        print("🛑 Comandos de parada enviados.")

    def desconectar(self):
        """Fecha o socket TCP."""
        if self.sock:
            self.sock.close()

    # --- Telemetry Sections ---
    _telemetry_callback = None

    def set_telemetry_source(self, callback_func):
        """Define a função que retorna o dicionário com dados de telemetria."""
        self._telemetry_callback = callback_func

    @property
    def velocidade(self):
        """Retorna a velocidade atual em km/h."""
        if self._telemetry_callback:
            data = self._telemetry_callback()
            return data.get('speed', 0.0)
        return 0.0

    @property
    def rpm(self):
        """Retorna a rotação atual do motor (RPM)."""
        if self._telemetry_callback:
            data = self._telemetry_callback()
            return data.get('rpm', 0.0)
        return 0.0
