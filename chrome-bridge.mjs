/**
 * HTTP/WebSocket bridge for Chrome DevTools Protocol
 *
 * Chrome rejects requests with non-localhost Host headers.
 * This bridge listens on 0.0.0.0:9222 and proxies to Chrome
 * on 127.0.0.1:9223, rewriting Host headers to "localhost".
 */

import http from "http";
import net from "net";

const LISTEN_PORT = 9222;
const CHROME_HOST = "127.0.0.1";
const CHROME_PORT = 9223;

// Proxy HTTP requests (for /json/version, /json/list, etc.)
const server = http.createServer((req, res) => {
  const options = {
    hostname: CHROME_HOST,
    port: CHROME_PORT,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: `localhost:${CHROME_PORT}` },
  };

  const proxy = http.request(options, (proxyRes) => {
    let body = "";
    proxyRes.on("data", (chunk) => (body += chunk));
    proxyRes.on("end", () => {
      const reqHost = req.headers.host || `localhost:${LISTEN_PORT}`;
      const rewritten = body
        .replace(/127\.0\.0\.1:9223/g, reqHost)
        .replace(/localhost:9223/g, reqHost);
      const headers = { ...proxyRes.headers };
      delete headers["content-length"];
      headers["content-length"] = Buffer.byteLength(rewritten);
      res.writeHead(proxyRes.statusCode, headers);
      res.end(rewritten);
    });
  });

  proxy.on("error", (e) => {
    res.writeHead(502);
    res.end(`Bridge error: ${e.message}`);
  });

  req.pipe(proxy);
});

// Proxy WebSocket upgrades (for DevTools protocol)
server.on("upgrade", (req, socket, head) => {
  const conn = net.connect(CHROME_PORT, CHROME_HOST, () => {
    const headers = { ...req.headers, host: `localhost:${CHROME_PORT}` };
    const headerLines = Object.entries(headers)
      .map(([k, v]) => `${k}: ${v}`)
      .join("\r\n");

    conn.write(
      `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n${headerLines}\r\n\r\n`
    );
    if (head.length) conn.write(head);

    conn.pipe(socket);
    socket.pipe(conn);
  });

  conn.on("error", () => socket.destroy());
  socket.on("error", () => conn.destroy());
});

server.listen(LISTEN_PORT, "0.0.0.0", () => {
  console.log(`Chrome bridge listening on 0.0.0.0:${LISTEN_PORT} → ${CHROME_HOST}:${CHROME_PORT}`);
});
