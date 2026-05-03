import http.server
import json
import threading

# ============================================================================
# ExoTalk WebRTC Signaling Relay
#
# 🧠 EDUCATIONAL CONTEXT:
# In a true Peer-to-Peer (P2P) mesh, signaling is the hardest problem to solve.
# Before two peers can talk directly, they must exchange "Signaling Data" 
# (SDP offers/answers) to negotiate their connection.
#
# This script serves as a temporary, centralized "introducer" that allows 
# browser-based Wasm clients and Rust-based Conscia Beacons to find each other
# and hole-punch through NATs. Once the connection is established, this relay 
# is no longer used for data transport.
# ============================================================================

# In-memory store for pending signaling messages. 
# 💡 PATTERN: The introducer pattern.
# We use a simple dictionary to hold messages until the target peer polls for them.
# Key: target node identifier, Value: list of message payloads.
messages = {}

class SignalingHandler(http.server.BaseHTTPRequestHandler):
    
    # 🛡️ SECURITY: CORS (Cross-Origin Resource Sharing)
    # Browsers block scripts from making requests to different domains for security.
    # Because our Wasm node might be on 'exotalk.tech' but the relay is on zrok,
    # we MUST explicitly allow these cross-origin requests.
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    # 📤 UPLOAD: Handling incoming WebRTC offers/answers
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

    # 📥 DOWNLOAD: Polling for incoming messages
    # 🧠 CONCEPT: Long-Polling vs WebSockets
    # To keep the relay lightweight, we use a simple GET request. Peers poll 
    # this endpoint periodically to see if anyone is trying to "handshake" with them.
    def do_GET(self):
        # Retrieve queued signaling data for the target (e.g., /my-node-id)
        target = self.path.strip('/') or 'global'
        
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        # 💡 TRICK: "Read once, clear once"
        # We retrieve and immediately clear the pending message queue for the target.
        # This prevents the same signaling offer from being processed multiple times.
        pending = messages.get(target, [])
        messages[target] = [] 
        
        self.wfile.write(json.dumps(pending).encode())

def run_server():
    # Bind to all interfaces on port 8080.
    # 🔧 INFRASTRUCTURE NOTE:
    # Port 8080 is the default target for our 'zrok' public relay.
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, SignalingHandler)
    
    print("Sovereign Signaling Relay running on port 8080...")
    print("Expose this via zrok: 'zrok reserve public --backend-mode proxy http://localhost:8080'")
    
    httpd.serve_forever()

if __name__ == "__main__":
    run_server()
