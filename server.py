#!/usr/bin/env python3
"""
Main server for Isleborn Online - serves web_frontend and starts all backend services
"""
import os
import sys
import subprocess
import threading
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
import signal
import json
from urllib.parse import parse_qs, urlparse

class IslebornHTTPHandler(SimpleHTTPRequestHandler):
    """HTTP handler with CORS support, API routing and no caching"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory='web_frontend', **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                'status': 'ok',
                'services': {
                    'web_frontend': True,
                    'island_service': check_service_health(5001),
                    'payment_service': check_service_health(8081),
                    'websocket_server': True
                }
            }).encode())
            return
        
        if parsed.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'ok', 'service': 'main_server'}).encode())
            return
        
        if parsed.path.startswith('/api/auth/'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/api/payment/'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/api/user/'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/api/packages'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/island'):
            self.proxy_to_service('localhost', 5001, parsed.path)
            return
        
        super().do_GET()
    
    def do_POST(self):
        parsed = urlparse(self.path)
        
        if parsed.path.startswith('/api/auth/'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/api/payment/'):
            self.proxy_to_service('localhost', 8081, parsed.path)
            return
        
        if parsed.path.startswith('/island'):
            self.proxy_to_service('localhost', 5001, parsed.path)
            return
        
        self.send_response(404)
        self.end_headers()
    
    def do_PUT(self):
        parsed = urlparse(self.path)
        
        if parsed.path.startswith('/island'):
            self.proxy_to_service('localhost', 5001, parsed.path)
            return
        
        self.send_response(404)
        self.end_headers()
    
    def proxy_to_service(self, host, port, path):
        import http.client
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None
            
            conn = http.client.HTTPConnection(host, port, timeout=10)
            headers = {k: v for k, v in self.headers.items() if k.lower() not in ['host', 'connection']}
            
            conn.request(self.command, path, body=body, headers=headers)
            response = conn.getresponse()
            
            self.send_response(response.status)
            for k, v in response.getheaders():
                if k.lower() not in ['transfer-encoding', 'connection']:
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(response.read())
            conn.close()
        except Exception as e:
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Service unavailable', 'detail': str(e)}).encode())
    
    def log_message(self, format, *args):
        print(f"[WebFrontend] {args[0]}")


def check_service_health(port):
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(('localhost', port))
        s.close()
        return True
    except:
        return False


def start_island_service():
    """Start the Island Service Flask app"""
    print("[Starting] Island Service on port 5001...")
    env = os.environ.copy()
    env['PORT'] = '5001'
    env['REDIS_ENABLED'] = 'false'
    try:
        subprocess.run(
            [sys.executable, 'island_service/app.py'],
            env=env,
            cwd=os.getcwd()
        )
    except Exception as e:
        print(f"[Error] Island Service failed: {e}")


def start_payment_service():
    """Start the Payment Service Flask app"""
    print("[Starting] Payment Service on port 8081...")
    env = os.environ.copy()
    env['PORT'] = '8081'
    try:
        subprocess.run(
            [sys.executable, 'payment_service/app.py'],
            env=env,
            cwd=os.getcwd()
        )
    except Exception as e:
        print(f"[Error] Payment Service failed: {e}")


def start_godot_ws_server():
    """Start the placeholder WebSocket server (emulating Godot server)"""
    print("[Starting] Godot WebSocket Server on port 8090...")
    try:
        subprocess.run(
            [sys.executable, 'godot_server/placeholder_ws.py'],
            cwd=os.getcwd()
        )
    except Exception as e:
        print(f"[Error] WebSocket Server failed: {e}")


def main():
    print("=" * 60)
    print("  Isleborn Online - Starting All Services")
    print("=" * 60)
    
    services = [
        ("Island Service", start_island_service),
        ("Payment Service", start_payment_service),
        ("Godot WS Server", start_godot_ws_server),
    ]
    
    threads = []
    for name, func in services:
        t = threading.Thread(target=func, name=name, daemon=True)
        t.start()
        threads.append(t)
        time.sleep(0.5)
    
    print("\n[Starting] Web Frontend on port 5000...")
    print("=" * 60)
    print("  Services running:")
    print("  - Web Frontend:    http://0.0.0.0:5000")
    print("  - Island Service:  http://localhost:5001")
    print("  - Payment Service: http://localhost:8081")
    print("  - Godot WS:        ws://localhost:8090")
    print("=" * 60)
    
    httpd = HTTPServer(('0.0.0.0', 5000), IslebornHTTPHandler)
    
    def signal_handler(sig, frame):
        print("\nShutting down...")
        httpd.shutdown()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    httpd.serve_forever()


if __name__ == '__main__':
    main()
