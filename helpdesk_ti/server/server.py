#!/usr/bin/env python3
"""
Servidor HTTP Simples para Hospedagem do APK e Verificação de Versão
Execute: python server.py
Acesse: http://SEU_IP:8080/version.json
"""

import http.server
import socketserver
import os
from pathlib import Path

# Configurações
PORT = 8080
DIRECTORY = Path(__file__).parent

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)
    
    def end_headers(self):
        # Habilitar CORS para permitir requisições do app
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

def get_local_ip():
    """Obtém o IP local da máquina"""
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

if __name__ == '__main__':
    # Mudar para o diretório do script
    os.chdir(DIRECTORY)
    
    local_ip = get_local_ip()
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║          SERVIDOR DE ATUALIZAÇÃO - PICHAU TI                 ║
╚══════════════════════════════════════════════════════════════╝

📡 Servidor iniciado com sucesso!

🌐 Endereços de acesso:
   • Local:  http://localhost:{PORT}
   • Rede:   http://{local_ip}:{PORT}

📋 Endpoints disponíveis:
   • Versão:    http://{local_ip}:{PORT}/version.json
   • Download:  http://{local_ip}:{PORT}/app-release.apk

📝 Instruções:
   1. Coloque o arquivo 'app-release.apk' nesta pasta
   2. Atualize 'version.json' com a nova versão
   3. No app, use o IP: {local_ip}

⚠️  IMPORTANTE:
   • Certifique-se que o firewall permite conexões na porta {PORT}
   • O celular deve estar na mesma rede WiFi
   • Atualize o IP no código do app para: {local_ip}

🛑 Para parar o servidor: Ctrl+C
╔══════════════════════════════════════════════════════════════╗
""")
    
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n🛑 Servidor encerrado pelo usuário.")
            httpd.shutdown()
