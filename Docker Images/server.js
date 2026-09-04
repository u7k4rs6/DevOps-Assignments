const express = require("express");

const app = express();
const PORT = process.env.PORT || 8080;

const PAGE = `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Hello World from Docker multi-stage build</title><style>body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;display:grid;place-items:center;height:100vh;margin:0;background:#0b1020;color:#e2e8f0}
.card{text-align:center;padding:2rem 3rem;border:1px solid #23304d;border-radius:12px;background:#111a2e;box-shadow:0 10px 40px rgba(0,0,0,.4)}
h1{margin:0 0 .75rem;font-size:1.6rem}
.meta{color:#8b9bbd;font-size:.9rem;line-height:1.7}
code{background:#0b1020;padding:.1rem .4rem;border-radius:4px;color:#93c5fd}</style></head><body><div class="card"><h1>Hello World from Docker multi-stage build</h1><div class="meta">Served from <code>multi-stage-hello</code> on container port <code>8080</code><br>Built with a two-stage Dockerfile on <code>node:20-alpine</code><br>Utkarsh Bahuguna &middot; 10161</div></div></body></html>`;

app.get("/", (req, res) => {
  res.type("html").send(PAGE);
});

app.get("/health", (req, res) =>
  res.json({ status: "ok", build: "multi-stage", node: process.version })
);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
