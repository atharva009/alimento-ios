/**
 * Alimento Gemini API Proxy
 *
 * Keeps the Gemini API key server-side. The iOS app sends prompts here,
 * and this server forwards them to Google's Gemini API.
 *
 * Setup:
 *   1. Copy backend/.env.example to backend/.env
 *   2. Add your Gemini API key to .env
 *   3. npm install && npm start
 *   4. Configure the app to use http://localhost:3000 (or your deployed URL)
 */

require('dotenv').config();
const http = require('http');

const PORT = parseInt(process.env.PORT || '3000', 10);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const MAX_BODY_SIZE = 1024 * 1024; // 1MB

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_SIZE) {
        req.destroy();
        reject(new Error('Request body too large'));
        return;
      }
      body += chunk;
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(new Error('Invalid JSON'));
      }
    });
    req.on('error', reject);
  });
}

async function callGemini(prompt, systemInstruction) {
  const contents = [];
  if (systemInstruction) {
    contents.push({
      role: 'user',
      parts: [{ text: systemInstruction }],
    });
  }
  contents.push({
    role: 'user',
    parts: [{ text: prompt }],
  });

  const url = `${GEMINI_URL}?key=${GEMINI_API_KEY}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ contents }),
  });

  const data = await response.json();

  if (!response.ok) {
    const err = new Error(data.error?.message || `HTTP ${response.statusCode}`);
    err.status = response.statusCode;
    err.code = data.error?.code;
    throw err;
  }

  const candidates = data.candidates;
  if (!candidates?.length) {
    throw new Error('No response from model');
  }

  const parts = candidates[0].content?.parts;
  if (!parts?.length) {
    throw new Error('Empty response');
  }

  return parts[0].text || '';
}

function logRequest(method, url, statusCode, durationMs) {
  const msg = `${method} ${url} ${statusCode} ${durationMs}ms`;
  if (statusCode >= 400) {
    console.error(msg);
  } else {
    console.log(msg);
  }
}

const server = http.createServer(async (req, res) => {
  const start = Date.now();
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    logRequest(req.method, req.url, 204, Date.now() - start);
    return;
  }

  // Health check: no Gemini call, for probes and load balancers
  if (req.method === 'GET' && (req.url === '/health' || req.url === '/')) {
    res.writeHead(200);
    res.end(JSON.stringify({ ok: true, service: 'alimento-gemini-proxy' }));
    logRequest(req.method, req.url, 200, Date.now() - start);
    return;
  }

  if (req.method !== 'POST' || req.url !== '/api/generate') {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
    logRequest(req.method, req.url, 404, Date.now() - start);
    return;
  }

  try {
    const body = await parseJsonBody(req);
    const { prompt, systemInstruction } = body;

    if (!prompt || typeof prompt !== 'string') {
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'Missing or invalid "prompt"' }));
      logRequest(req.method, req.url, 400, Date.now() - start);
      return;
    }

    const text = await callGemini(prompt, systemInstruction || null);
    res.writeHead(200);
    res.end(JSON.stringify({ text }));
    logRequest(req.method, req.url, 200, Date.now() - start);
  } catch (err) {
    const status = err.status || 500;
    const message = err.message || 'Internal server error';
    res.writeHead(status);
    res.end(JSON.stringify({ error: message }));
    logRequest(req.method, req.url, status, Date.now() - start);
  }
});

server.listen(PORT, () => {
  if (!GEMINI_API_KEY) {
    console.warn('⚠️  GEMINI_API_KEY not set. Set it before making requests.');
  }
  console.log(`Gemini proxy running at http://localhost:${PORT}`);
  console.log('  GET /health - health check');
  console.log('  POST /api/generate { "prompt": "...", "systemInstruction": "..." }');
});
