"""PKHosting sample app - served by gunicorn behind nginx."""
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify, request

app = Flask(__name__)

PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PKHosting - Provisioned by Code</title>
<style>
 body{font-family:system-ui,sans-serif;max-width:640px;margin:10vh auto;padding:0 1rem;color:#1a2a1a}
 h1{color:#01411C} .ok{background:#e8f5e9;border-left:4px solid #01411C;padding:1rem}
 code{background:#f2f2f2;padding:2px 5px;border-radius:3px}
</style></head><body>
<h1>PKHosting</h1>
<div class="ok"><strong>Server provisioned automatically</strong> with Terraform + Ansible.</div>
<p>Host: <code>{host}</code><br>Time (UTC): <code>{now}</code><br>
Scheme seen by app: <code>{scheme}</code> (via nginx reverse proxy)</p>
<p>Endpoints: <code>/health</code>, <code>/api/info</code></p>
</body></html>"""


@app.get("/")
def index():
    scheme = request.headers.get("X-Forwarded-Proto", request.scheme)
    return PAGE.format(host=socket.gethostname(),
                       now=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
                       scheme=scheme)


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/info")
def info():
    return jsonify(service="pkhosting-sample", host=socket.gethostname(),
                   proto=request.headers.get("X-Forwarded-Proto", request.scheme))


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000)
