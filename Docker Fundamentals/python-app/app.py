from flask import Flask, jsonify

app = Flask(__name__)

PAGE = """<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Hello World from Python!</title><style>body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;display:grid;place-items:center;height:100vh;margin:0;background:#0b1020;color:#e2e8f0}
.card{text-align:center;padding:2rem 3rem;border:1px solid #23304d;border-radius:12px;background:#111a2e;box-shadow:0 10px 40px rgba(0,0,0,.4)}
h1{margin:0 0 .75rem;font-size:1.6rem}
.meta{color:#8b9bbd;font-size:.9rem;line-height:1.7}
code{background:#0b1020;padding:.1rem .4rem;border-radius:4px;color:#93c5fd}</style></head><body><div class="card"><h1>Hello World from Python!</h1><div class="meta">Served by Flask on <code>python:3.12</code><br>Container port <code>5000</code> &rarr; host port <code>5001</code><br>Utkarsh Bahuguna &middot; 10161</div></div></body></html>"""


@app.route("/")
def hello():
    return PAGE


@app.route("/health")
def health():
    return jsonify(status="ok", stack="python")


if __name__ == "__main__":
    # 0.0.0.0 is mandatory inside a container: binding to 127.0.0.1 would
    # only listen on the container's own loopback and -p would never reach it.
    app.run(host="0.0.0.0", port=5000)
