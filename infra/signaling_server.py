import http.server
import json
import threading

# ============================================================================
# ExoTalk WebRTC Signaling Relay
#
# This is a lightweight, in-memory HTTP server designed to facilitate the
# initial WebRTC handshake (SDP offer/answer exchange) between the browser-based
# Wasm client and the rust-based Conscia Beacon.
# 
# In a true P2P mesh, signaling is often the hardest bootstrap problem. This
# script serves as a temporary, centralized "introducer" to hole-punch NATs.
# ============================================================================

# In-memory store for pending signaling messages. 
# Key: target node identifier, Value: list of message payloads.
messages = {}

class SignalingHandler(http.server.BaseHTTPRequestHandler):
    
    # Handle CORS preflight requests necessary for browser-to-server communication
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    # Handle incoming WebRTC offers/answers from peers
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        
        # Route message to the specific target or 'global' broadcast queue
        target = data.get('target', 'global')
        if target not in messages:
            messages[target] = []
        messages[target].append(data)
        
        # Acknowledge receipt
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"status": "sent"}).encode())

    # Allow peers to poll for incoming messages addressed to them
    def do_GET(self):
        # Uses long-polling (or direct fetch) to retrieve queued signaling data
        target = self.path.strip('/') or 'global'
        
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        # Retrieve and immediately clear the pending message queue for the target
        pending = messages.get(target, [])
        messages[target] = [] # Clear after read to prevent duplicate processing
        
        self.wfile.write(json.dumps(pending).encode())

def run_server():
    # Bind to all interfaces on port 8080.
    # This port must match the configuration expected by the zrok tunnel.
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, SignalingHandler)
    
    print("Sovereign Signaling Relay running on port 8080...")
    print("Expose this via zrok: 'zrok reserve public --backend-mode proxy http://localhost:8080'")
    
    # Keep the server running indefinitely
    httpd.serve_forever()

if __name__ == "__main__":
    run_server()
