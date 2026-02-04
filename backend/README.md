# Alimento Gemini Proxy

Backend proxy that keeps the Gemini API key server-side. The iOS app sends prompts to this server, which forwards them to Google's Gemini API.

## Setup

### 1. Get a Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Copy it (starts with `AIza...`)

### 2. Create .env File

```bash
cd backend
cp .env.example .env
```

Edit `.env` and add your API key:

```
GEMINI_API_KEY=your-api-key-here
```

The `.env` file is gitignored and will not be committed.

### 3. Start the Server

```bash
npm install
npm start
```

The server runs at `http://localhost:3000` by default. Use `PORT` to override:

```bash
PORT=8080 node server.js
```

### 4. Configure the iOS App

Edit `Configuration/BackendConfig.swift` and set the base URL:

- **Simulator**: `http://localhost:3000`
- **Physical device** (same network): `http://YOUR_MACHINE_IP:3000` (e.g. `http://192.168.1.100:3000`)

## API

### POST /api/generate

Request body:

```json
{
  "prompt": "Your prompt text",
  "systemInstruction": "Optional system instruction"
}
```

Response:

```json
{
  "text": "Model response text"
}
```

## Production

For production:

1. Deploy this server (e.g. Railway, Render, Fly.io, your own VPS)
2. Set `GEMINI_API_KEY` in the deployment environment
3. Use HTTPS for the deployed URL
4. Update `BackendConfig.baseURL` in the app to your production URL

Consider adding authentication (API keys, JWT) to protect your proxy from unauthorized use.
