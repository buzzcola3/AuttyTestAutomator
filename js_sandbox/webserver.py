import http.server
import socketserver
import os

PORT = 80  # Port number for the server

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Serve files from the directory where this script is located
        super().__init__(*args, directory=os.getcwd(), **kwargs)

def serve_files():
    handler = MyHandler
    with socketserver.TCPServer(("", PORT), handler) as httpd:
        print(f"Serving HTTP on port {PORT}")
        httpd.serve_forever()

# Call the function to start the server
serve_files()
