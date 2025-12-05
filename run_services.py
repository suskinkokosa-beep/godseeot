#!/usr/bin/env python3
"""
Main entry point for Isleborn Online - serves web_frontend and API services
"""
import os
import sys
import subprocess
import threading
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
import signal


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
    try:
        subprocess.run(
            [sys.executable, 'island_service/app.py'],
            env=env,
            cwd=os.getcwd()
        )
    except Exception as e:
        print(f"[Error] Island Service: {e}")


def start_godot_ws_server():
    """Start the placeholder WebSocket server (emulating Godot server)"""
    print("[Starting] Godot WebSocket Server on port 8090...")
    try:
        subprocess.run(
            [sys.executable, 'godot_server/placeholder_ws.py'],
            cwd=os.getcwd()
        )
    except Exception as e:
        print(f"[Error] Godot WS: {e}")


def main():
    print("=" * 60)
    print("  Isleborn Online - Starting All Services")
    print("=" * 60)
    
    # Start backend services in threads
    t1 = threading.Thread(target=start_island_service, daemon=True)
    t1.start()
    time.sleep(1)
    
    t2 = threading.Thread(target=start_godot_ws_server, daemon=True)
    t2.start()
    time.sleep(1)
    
    # Start the main web frontend server on port 5000
    print("\n[Starting] Web Frontend on port 5000...")
    print("=" * 60)
    print("  Services running:")
    print("  - Web Frontend:    http://0.0.0.0:5000")
    print("  - Island Service:  http://localhost:5001")
    print("  - Godot WS:        ws://localhost:8090")
    print("=" * 60)
    
    httpd = HTTPServer(('0.0.0.0', 5000), CORSHTTPRequestHandler)
    
    def signal_handler(sig, frame):
        print("\nShutting down...")
        httpd.shutdown()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")


if __name__ == '__main__':
    main()
