# Alimento

A SwiftUI iOS app for managing your kitchen: track inventory, plan meals, log dishes, manage grocery lists, and get AI-powered suggestions—all in one place.

## Features

- **Dashboard** — Summary cards for low stock, expiring items, today’s meals, and quick actions (AI suggestions, add inventory, log dish, plan meal, insights).
- **Inventory** — Add, edit, and track pantry items; mark consumption and see expiring-soon items.
- **Cook Log** — Record dishes you’ve made, view history, and see dish details and ingredients.
- **Planner** — Weekly meal plan with a calendar view; add, edit, and remove planned meals.
- **Grocery** — Create and manage grocery lists; generate lists from plans and add items to inventory.
- **AI** — Meal suggestions, weekly meal plan ideas, and grocery suggestions via Google Gemini (through the backend proxy).
- **Assistant** — Chat assistant with tools that can query inventory, dishes, and plans.
- **Insights** — View analytics and insights from your data.
- **Settings** — Privacy and AI-related options.

Data is stored locally with **SwiftData**; the app uses a small **Node.js backend** only to call the Gemini API so your API key stays server-side.

## Tech Stack

| Layer | Stack |
|-------|--------|
| **iOS** | Swift 5, SwiftUI, SwiftData, TipKit |
| **Backend** | Node.js (≥18), plain `http` server |
| **AI** | Google Gemini (via backend proxy) |

## Project Structure

```
Alimento/
├── Alimento/                 # iOS app
│   ├── AlimentoApp.swift     # App entry, SwiftData + TipKit setup
│   ├── ContentView.swift     # Main tab bar (Dashboard, Inventory, Cook Log, Planner, Grocery)
│   └── Info.plist
├── Configuration/            # Backend URL, AI config
├── Features/                 # Feature modules (Dashboard, Inventory, Cook Log, Planner, Grocery, AI, Assistant, Insights, Settings, Onboarding)
├── Models/                   # SwiftData & domain models
├── Services/                 # Protocols, implementations, networking (Gemini client), tool executors
├── Shared/                   # Error handling, haptics, domain errors
├── Resources/                # AI fixtures (JSON)
├── AlimentoTests/            # Unit tests
└── backend/                  # Gemini API proxy (Node.js)
    ├── server.js
    ├── package.json
    └── .env.example
```

## Requirements

- **Xcode** (current stable, with an iOS SDK that matches the project’s deployment target)
- **Node.js** ≥ 18 (for the backend)
- **Gemini API key** from [Google AI Studio](https://makersuite.google.com/app/apikey) (for AI features)

## Setup

### 1. Clone and open the app

```bash
git clone <repo-url>
cd Alimento
open Alimento.xcodeproj
```

Build and run the app in the Simulator or on a device.

### 2. Backend (for AI and Assistant)

AI features (meal suggestions, weekly plan, grocery suggestions, Assistant) call the Gemini API through a small proxy so the API key never lives in the app.

1. **Get a Gemini API key**  
   [Google AI Studio](https://makersuite.google.com/app/apikey) → Create API key → copy it (e.g. `AIza...`).

2. **Configure the backend**

   ```bash
   cd backend
   cp .env.example .env
   ```

   Edit `backend/.env` and set:

   ```
   GEMINI_API_KEY=your-api-key-here
   ```

   Optional: set `PORT` (default is `3000`).

3. **Install and start the server**

   ```bash
   npm install
   npm start
   ```

   The proxy runs at `http://localhost:3000` (or your chosen `PORT`).

4. **Point the app at the backend**

   Edit `Configuration/BackendConfig.swift` and set `baseURL`:

   - **Simulator:** `http://localhost:3000`
   - **Physical device (same Wi‑Fi):** `http://YOUR_MACHINE_IP:3000` (e.g. `http://192.168.1.100:3000`)
   - **Production:** your deployed backend URL (HTTPS recommended)

If the backend isn’t running or the URL is wrong, AI and Assistant features will fail; the rest of the app works without the backend.

## Backend API

The proxy exposes one endpoint:

- **POST** `/api/generate`  
  Body: `{ "prompt": "...", "systemInstruction": "..." }` (optional)  
  Response: `{ "text": "..." }`

See `backend/README.md` for more detail and production notes.

## Running tests

Open the project in Xcode and run the test suite (⌘U), or use the Test navigator to run individual tests in `AlimentoTests/`.

## License

See the repository for license information.
