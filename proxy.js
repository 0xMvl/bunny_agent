const http = require('http');
const https = require('https');
const fs = require('fs');

const PORT = 4664;
const BUNNY_API = 'https://world.bunnyos.ai';
const API_KEY = 'bos_432b85674b64732783a51bc8efd9a6527f730d68f7b0208ce619519836813d49';
const LOG_FILE = '/root/bunny/play.log';

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Log endpoint
  if (req.url === '/api/log') {
    try {
      const logContent = fs.existsSync(LOG_FILE) ? fs.readFileSync(LOG_FILE, 'utf-8') : 'No log file yet.';
      const lines = logContent.split('\n').filter(l => l.trim());
      const last50 = lines.slice(-50).join('\n');
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(last50);
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'read_error', message: err.message }));
    }
    return;
  }

  // Proxy to bunnyOS API
  const apiPath = req.url.replace(/^\/api/, '');
  const url = new URL(apiPath, BUNNY_API);
  const options = {
    hostname: url.hostname,
    port: 443,
    path: url.pathname + url.search,
    method: req.method,
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
  };

  const proxyReq = https.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'proxy_error', message: err.message }));
  });

  req.pipe(proxyReq);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`bunnyOS proxy running on http://127.0.0.1:${PORT}`);
});
