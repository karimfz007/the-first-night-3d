import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve } from "node:path";

const requestedRoot = process.argv[2] ?? "builds/web";
const root = resolve(requestedRoot);
const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon"
};

const server = createServer((request, response) => {
  const url = new URL(request.url ?? "/", "http://127.0.0.1");
  const relative = normalize(decodeURIComponent(url.pathname)).replace(/^([/\\])+/, "") || "index.html";
  const candidate = join(root, relative);
  if (!candidate.startsWith(root) || !existsSync(candidate) || !statSync(candidate).isFile()) {
    response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    response.end("Not found");
    return;
  }
  response.writeHead(200, {
    "content-type": mime[extname(candidate).toLowerCase()] ?? "application/octet-stream",
    "cache-control": "no-store",
    "cross-origin-resource-policy": "same-origin"
  });
  createReadStream(candidate).pipe(response);
});

server.listen(4173, "127.0.0.1", () => {
  console.log(`Serving ${root} on http://127.0.0.1:4173`);
});
