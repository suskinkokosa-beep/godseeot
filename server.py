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

# Get the Replit domain for proper WebSocket connections
REPLIT_DOMAIN = os.environ.get('REPL_SLUG', 'localhost')
REPLIT_OWNER = os.environ.get('REPL_OWNER', '')

class CORSHTTPRequestHandler(SimpleHTTPRequestHandler):
    """HTTP handler with CORS support and no caching"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory='web_frontend', **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[WebFrontend] {args[0]}")


def start_island_service():
    """Start the Island Service Flask app"""
    print("[Starting] Island Service on port 5001...")
    env = os.environ.copy()
    env['PORT'] = '5001'
    env['REDIS_ENABLED'] = 'false'
    subprocess.run(
        [sys.executable, 'island_service/app.py'],
        env=env,
        cwd=os.getcwd()
    )


def start_payment_service():
    """Start the Payment Service Flask app"""
    print("[Starting] Payment Service on port 8081...")
    env = os.environ.copy()
    env['PORT'] = '8081'
    subprocess.run(
        [sys.executable, 'payment_service/app.py'],
        env=env,
        cwd=os.getcwd()
    )


def start_godot_ws_server():
    """Start the placeholder WebSocket server (emulating Godot server)"""
    print("[Starting] Godot WebSocket Server on port 8090...")
    subprocess.run(
        [sys.executable, 'godot_server/placeholder_ws.py'],
        cwd=os.getcwd()
    )


def start_gateway():
    """Start the Gateway Go server"""
    print("[Starting] Gateway on port 8080...")
    env = os.environ.copy()
    env['WORLD_WS'] = 'ws://localhost:8090/ws'
    env['USE_REDIS_RATE'] = 'false'
    
    # First build the Go binary
    gateway_dir = os.path.join(os.getcwd(), 'gateway')
    subprocess.run(['go', 'build', '-o', 'gateway', '.'], cwd=gateway_dir, env=env)
    
    # Then run it
    subprocess.run(['./gateway'], cwd=gateway_dir, env=env)


def main():
    print("=" * 60)
    print("  Isleborn Online - Starting All Services")
    print("=" * 60)
    
    # Start backend services in threads
    services = [
        ("Island Service", start_island_service),
        ("Payment Service", start_payment_service),
        ("Godot WS Server", start_godot_ws_server),
        ("Gateway", start_gateway),
    ]
    
    threads = []
    for name, func in services:
        t = threading.Thread(target=func, name=name, daemon=True)
        t.start()
        threads.append(t)
        time.sleep(1)  # Give each service time to start
    
    # Start the main web frontend server on port 5000
    print("\n[Starting] Web Frontend on port 5000...")
    print("=" * 60)
    print("  Services running:")
    print("  - Web Frontend:    http://0.0.0.0:5000")
    print("  - Island Service:  http://localhost:5001")
    print("  - Payment Service: http://localhost:8081")
    print("  - Gateway:         http://localhost:8080")
    print("  - Godot WS:        ws://localhost:8090")
    print("=" * 60)
    
    httpd = HTTPServer(('0.0.0.0', 5000), CORSHTTPRequestHandler)
    
    def signal_handler(sig, frame):
        print("\nShutting down...")
        httpd.shutdown()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    httpd.serve_forever()


if __name__ == '__main__':
    main()
