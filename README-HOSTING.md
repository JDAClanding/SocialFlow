# SOCIALFLOW server — setup & hosting

Flask backend for the SOCIALFLOW Flutter app (`lib/api.dart`). Implements every
endpoint the app calls: site scraping, competitor research, image search, Meta
ad lookups, AI image generation, and project save/share links.

## Run locally

```bash
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env   # optional — see "API keys" below
python server.py
```

Server listens on `http://localhost:8080` by default (matches the app's
built-in default in `lib/api.dart`). Then just run the app:

```bash
flutter run -d chrome
```

No `.env` needed to try the whole wizard end-to-end: web search and image
search use free DuckDuckGo scraping, and AI image generation falls back to a
local "placeholder" model (a labeled rectangle) so every screen works without
any account.

## API keys (optional, unlocks real features)

| Env var | Unlocks |
|---|---|
| `FAL_KEY` | Real AI images via fal.ai (FLUX) — cheapest real option |
| `REPLICATE_API_TOKEN` | Real AI images via Replicate (FLUX) |
| `GEMINI_API_KEY` | Real AI images via Google Imagen 3 |
| `STABILITY_API_KEY` | Real AI images via Stable Diffusion 3.5 |
| `OPENAI_API_KEY` | Real AI images via gpt-image-1 |
| `FB_ACCESS_TOKEN` | Official Meta Ad Library API (otherwise `/api/metaads` returns an image-search approximation, `mode: "search"`) |

Set any of these on the server and every device gets a "ready" model with no
per-user setup. The app's Studio screen also lets a user paste their **own**
key on their device (Settings → API keys) — it's sent only with that
person's own generation requests, never stored server-side.

`auto` mode always picks the cheapest *ready* model, so once you add any one
image-gen key, generations upgrade automatically from the placeholder.

## Known limitations (read before relying on this in production)

- **Search & image search are free scrapers (DuckDuckGo HTML/image endpoints), not a paid API.** They're the same trick the popular `duckduckgo_search` library uses. It's reliable enough for demos but DuckDuckGo can change markup or rate-limit without notice. For production traffic, swap `ddg_text_search` / `ddg_image_search` in `server.py` for a paid provider (Bing Web Search, SerpApi, Serper, etc.) — same function signature, just change the implementation.
- **Follower counts** (`/api/analyze`) are scraped from public profile meta tags (`og:description`). Instagram/TikTok often omit this for logged-out requests, so followers may come back empty even when the handle is found — that's expected, not a bug.
- **Image generation** requires a real provider key for real AI output; without one, every image is the offline placeholder (clearly labeled as such) so the flow still works for demos/testing.
- Generated images and saved projects are stored on local disk under `data/` — on most free hosts (e.g. Render's free tier) this is **ephemeral** and clears on redeploy/restart. For anything persistent, swap in S3/Cloud Storage and a real database.
- CORS is wide open (`flask-cors` default) since the app has no login. Lock this down if you add auth.

## Deploy (Render, free tier example)

1. Push this repo (or just the server files) to GitHub.
2. New → Web Service on [render.com](https://render.com), connect the repo.
3. Build command: `pip install -r requirements.txt`
4. Start command: `python server.py`
5. Add any API keys from the table above as environment variables.
6. Once deployed, build the app pointed at it:
   ```bash
   flutter build web --dart-define=API_URL=https://your-app.onrender.com
   ```

Railway, Fly.io, or any host that runs a long-lived Python process work the
same way — just set `PORT` (most hosts inject it automatically) and the same
env vars.
