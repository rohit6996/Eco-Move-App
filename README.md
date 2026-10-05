<div align="center">

# 🌿 Eco-Move Nagpur
### *Smart, Multimodal & Sustainable Urban Transit for Nagpur City*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![n8n](https://img.shields.io/badge/n8n-AI_Workflows-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

---

**Eco-Move** is a next-generation urban mobility mobile application designed specifically for the city of Nagpur. It unifies **Maha Metro (Orange & Aqua lines)**, **Aapli Bus (837+ city routes, 3,487 stops)**, **EV Feeder Cabs**, and **First/Last Mile Micro-mobility** into a single seamless, eco-friendly transit experience.

</div>

---

## 🚀 Key Features

### 🗺️ 1. Real Interactive Nagpur Map & Transit Layers
- **Dual High-Performance Basemaps**: Smooth switching between **Carto Voyager** vector tiles and **Google Maps**.
- **Real Transit Overlays**:
  - **Nagpur Metro Lines**: Complete track geometries & station overlays for **Orange Line** (Khapri ⇄ Automotive Sq) and **Aqua Line** (Prajapati Nagar ⇄ Lokmanya Nagar).
  - **Aapli Bus Network**: 837 city routes with 3,487 mapped stops.
- **Unified Places & Transit Search**:
  - Powered by **Google Places API (New)** strictly restricted to Nagpur (35km radius) with dual **OpenStreetMap Nominatim** & **Photon** fallbacks.
  - Automatic phonetic normalization for vernacular Nagpur names (e.g. *Sitabuldi*, *Dharampeth*, *Khamla*, *GMC*, *Futala*).
  - Dynamic map camera tracking & destination pin placement with instant Journey Planner integration.

### 🧭 2. Multimodal Journey Planner
- Combines Metro, Aapli EV Buses, Walking, and Shared Mobility.
- Smart trip optimization modes:
  - ⭐ **Fastest Route**
  - 💰 **Cheapest Route**
  - 🌿 **Max CO₂ Saved** (Green Transit)
- Transparent fare calculation with **MahaCard** discounts and step-by-step transfer instructions.

### 🚌 3. Live Fleet & "Know Your Bus"
- Real-time GPS vehicle tracking and ETA predictions powered by live transit feeds.
- Corridor search by bus route number (e.g., Route 10, 135, 42) and live arrival schedules for every stop in Nagpur.

### 🎟️ 4. Unified QR Ticketing & Digital Passes
- Instant digital QR tickets and smart passes for both Metro and Aapli Bus.
- Backed by **Supabase** realtime synchronization and secure payment processing.

### 🌱 5. Eco-Points & Carbon Tracker
- Calculates carbon emissions saved for every green trip vs. personal petrol vehicles.
- Gamified commuter tiers, milestone badges, and redeemable vouchers for local Nagpur transit discounts.

### 🤖 6. SafarBot (AI Transit Mitra)
- Context-aware transit chatbot integrated via **n8n AI Webhooks**.
- Delivers real-time Nagpur transit guidance, fare estimates, and bilingual assistance in English, Hindi, and Marathi.

---

## 🛠️ Architecture & Tech Stack

```
                                  ┌────────────────────────┐
                                  │   Eco-Move Mobile App  │
                                  │     (Flutter / Dart)   │
                                  └───────────┬────────────┘
                                              │
         ┌──────────────────┬─────────────────┼──────────────────┬──────────────────┐
         │                  │                 │                  │                  │
         ▼                  ▼                 ▼                  ▼                  ▼
┌─────────────────┐ ┌───────────────┐ ┌───────────────┐ ┌─────────────────┐ ┌───────────────┐
│ Carto & Google  │ │ Google Places │ │   Supabase    │ │ n8n AI Workflows│ │ Chalo / Maha  │
│    Tile Maps    │ │ & OSM Photon  │ │ (DB, Realtime)│ │   (SafarBot)    │ │ Transit Data  │
└─────────────────┘ └───────────────┘ └───────────────┘ └─────────────────┘ └───────────────┘
```

| Component | Technology / Service |
| :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart 3.x) |
| **Map Rendering** | [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2) |
| **Database & Auth** | [Supabase](https://supabase.com) (PostgreSQL & Realtime) |
| **AI Assistant** | [n8n](https://n8n.io) Autonomous Webhook Workflows + LLM |
| **Geocoding & Search** | Google Places API (New) + Nominatim + Photon |
| **Configuration** | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) (`.env`) |

---

## 📁 Project Structure

```
eco_move/
├── android/                   # Android native configuration
├── assets/
│   └── data/                  # Real Nagpur transit datasets
│       ├── bus_fares.json
│       ├── bus_schedules.json
│       ├── chalo_routes_index.json
│       ├── lineGeometries.json
│       ├── metro_fares.json
│       └── network.json
├── ios/                       # iOS native configuration
├── lib/
│   ├── main.dart              # Application entry point & service initialization
│   ├── mock_data/             # Mock route options & rewards data
│   ├── models/                # App data models (tickets, routes, rewards)
│   ├── screens/               # Main UI screens
│   │   ├── cabs_screen.dart           # Cabs & first-last mile booking
│   │   ├── eco_rewards_screen.dart    # Eco-Points & green rewards
│   │   ├── landing_map_screen.dart    # Interactive Nagpur map & search
│   │   ├── live_fleet_screen.dart     # Know Your Bus live tracking
│   │   ├── map_plan_screen.dart       # Multimodal journey planner
│   │   ├── profile_screen.dart        # User profile & settings
│   │   ├── safarbot_screen.dart       # SafarBot AI transit assistant
│   │   └── tickets_screen.dart        # QR ticket booking & active passes
│   ├── services/              # Core business logic & backend integrations
│   │   ├── backend_config.dart        # Secure environment configuration
│   │   ├── live_bus_service.dart      # Live bus telemetry integration
│   │   ├── multimodal_routing_service.dart # Smart transit algorithm
│   │   ├── n8n_ai_service.dart        # SafarBot AI webhook connector
│   │   ├── nagpur_places_service.dart # Unified Google Places & transit search
│   │   ├── supabase_service.dart      # Supabase DB & auth client
│   │   └── transit_data_service.dart  # 837 bus routes & metro geometries
│   ├── theme/                 # App design system, tokens & typography
│   └── widgets/               # Reusable UI components & bottom sheets
├── test/                      # Unit & widget test suites
├── .env.example               # Environment variables template
├── .gitignore                 # Git ignore rules for secrets & build outputs
└── pubspec.yaml               # Project dependencies & asset definitions
```

---

## ⚡ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0` or higher)
- [Android Studio](https://developer.android.com/studio) / [Xcode](https://developer.apple.com/xcode/) (with command-line tools)
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/eco_move.git
cd eco_move
```

### 2. Configure Environment Variables
Copy the `.env.example` template to create your private `.env` file:
```bash
cp .env.example .env
```
Open `.env` and configure your API keys:
```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GOOGLE_MAPS_API_KEY=your-google-places-api-key
CARTO_API_KEY=your-carto-maps-api-key
ORS_API_KEY=your-openrouteservice-key
N8N_WEBHOOK_URL=https://your-n8n-instance.cloud/webhook/explain-route
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
```bash
# Run on connected Android device / emulator
flutter run

# Run on specific target
flutter run -d android
flutter run -d chrome
```

---

## 🧪 Testing & Code Quality

Run static analysis to verify code health:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

---

## 🔒 Security & Privacy
- **No Hardcoded Keys**: All sensitive API keys, Supabase credentials, and webhooks are loaded at runtime from `.env`.
- `.env` is strictly ignored by `.gitignore` to prevent secret leakage.
- Use `.env.example` as a template for CI/CD and open-source contributions.

---

## 👥 Authors & Acknowledgements
- **Eco-Move Nagpur Team** — *Final Year Engineering Capstone Project*
- Special thanks to **Nagpur Maha Metro Rail Corporation Limited (MMRCL)** and **Nagpur Mahanagar Parivahan Limited (NMPL - Aapli Bus)** for transit network references.

---

<div align="center">
  <sub>Built with ❤️ for a Cleaner, Greener & Smarter Nagpur 🌱</sub>
</div>
