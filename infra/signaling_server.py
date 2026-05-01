import http.server
import json
import threading

# Simple in-memory message relay for WebRTC signaling
messages = {}

class SignalingHandler(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        
        target = data.get('target', 'global')
        if target not in messages:
            messages[target] = []
        messages[target].append(data)
        
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"status": "sent"}).encode())

    def do_GET(self):
        # Very simple long-polling or direct fetch
        target = self.path.strip('/') or 'global'
        
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        pending = messages.get(target, [])
        messages[target] = [] # Clear after read
        self.wfile.write(json.dumps(pending).encode())

def run_server():
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, SignalingHandler)
    print("Sovereign Signaling Relay running on port 8080...")
    print("Expose this via zrok: 'zrok reserve public --backend-mode proxy http://localhost:8080'")
    httpd.serve_forever()

if __name__ == "__main__":
    run_server()
