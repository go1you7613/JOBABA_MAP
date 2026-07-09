from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1] / "backend" / "src" / "main" / "resources" / "static"
BACKEND = "http://127.0.0.1:8080"
PORT = 8082


class MapProxyHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        if self.path.startswith("/api/"):
            self.proxy_api()
            return
        super().do_GET()

    def proxy_api(self):
        target = BACKEND + self.path
        try:
            req = Request(target, headers={"Accept": self.headers.get("Accept", "application/json")})
            with urlopen(req, timeout=10) as resp:
                body = resp.read()
                self.send_response(resp.status)
                self.send_header("Content-Type", resp.headers.get("Content-Type", "application/json"))
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
        except HTTPError as exc:
            body = exc.read()
            self.send_response(exc.code)
            self.send_header("Content-Type", exc.headers.get("Content-Type", "text/plain"))
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except URLError as exc:
            body = ("Backend proxy failed: " + str(exc.reason)).encode("utf-8")
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", PORT), MapProxyHandler)
    print(f"Serving JOBABA MAP at http://127.0.0.1:{PORT}/map/index.html")
    print(f"Proxying /api/* to {BACKEND}")
    server.serve_forever()
