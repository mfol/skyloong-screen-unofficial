# SKYLOONG 4.0 Screen — Web Console (unofficial)

**🌐 Idioma / Language:** [Português](README.md) · **English**

An alternative frontend, in a **single HTML file**, for the **SKYLOONG 4.0 Screen** keyboard
(a keyboard with a built-in LCD screen and Wi‑Fi). It replaces the factory interface served by
the keyboard itself at `http://<keyboard-ip>/`, talking **directly** to the device's HTTP API —
no build, no server, no dependencies to install.

> ⚠️ Independent project, obtained by **reverse-engineering** the official UI. Not affiliated
> with SKYLOONG. Use at your own risk, only on your own device.

---

## Table of contents

- [What the device is](#what-the-device-is)
  - [Tested hardware](#tested-hardware)
- [How to use](#how-to-use)
  - [Configure Wi‑Fi from the screen (V4)](#configure-wi-fi-from-the-screen-v4)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [Device API (reverse-engineered)](#device-api-reverse-engineered)
- [How video conversion works](#how-video-conversion-works)
- [Project structure](#project-structure)
- [Technical notes](#technical-notes)

---

## What the device is

The **SKYLOONG 4.0 Screen** is a mechanical keyboard with a small **320×240 (4:3) LCD** screen
and Wi‑Fi connectivity. It runs an **embedded HTTP server** that ships an SPA
(Vue + Tailwind + axios + ffmpeg.wasm) to configure the screen: upload images/videos, enable
widgets (weather, typing speed, system info), switch themes, etc.

Relevant characteristics of the embedded server:

| Item | Value |
|---|---|
| Screen resolution | **320 × 240** (4:3) |
| Storage | ~**5.8 MB** (`total` ≈ 6,094,848 bytes) |
| CORS | open (`Access-Control-Allow-Origin: *`) |
| Connections | **1 at a time** (`Connection: close`) — requests must be serialized |
| IP in station mode | assigned by your network (e.g. `192.168.100.11` — just an example; yours will differ) |
| IP in AP mode (fallback) | `192.168.4.1` (captive portal at `/wifi`) |

### Tested hardware

This project was **tested** with the **SKYLOONG GK104 Pro** (wireless Bluetooth mechanical
keyboard, full-size 100%, RGB backlight, PBT keycaps, low-noise hot-swap switches), running
**screen version 4.0**.

> 💡 **Other screen versions:** configuring Wi‑Fi from the screen itself
> (see [Configure Wi‑Fi from the screen](#configure-wi-fi-from-the-screen-v4)) and this console
> **may also work on older screens** (e.g. 3.0). **I can't test this**, since I only own the
> **4.0** — if you try it on another version, please open an _issue_ with the result.

---

## How to use

1. Make sure your PC is on the **same Wi‑Fi network** as the keyboard.
2. Find the keyboard's IP (shown on the screen itself / in your router). The `192.168.100.11`
   value seen throughout this project is **just an example** (it was the IP the author's network
   assigned) — **yours will be different**. See
   [Configure Wi‑Fi from the screen](#configure-wi-fi-from-the-screen-v4) to find yours under the
   **Web Server** section of the screen.
3. **Serve the page over `http://`** (recommended) — **double-click `serve.bat`**.
   It starts `server.py` (which enables the **SQLite database** of thumbnails/nicknames) and opens
   `http://localhost:8000/skyloong-ui.html` in the browser.
   Manual alternative, from the project folder:
   ```bash
   python server.py            # with SQLite database (recommended)
   # or, without the database (thumbnails in the browser only):
   # python -m http.server 8000
   # then open http://localhost:8000/skyloong-ui.html
   ```
   > Tip: the server listens on `0.0.0.0`, so you can open it from your **phone** on the same
   > network: `http://<pc-ip>:8000/skyloong-ui.html`.
4. At the top of the page, adjust the keyboard's **IP** if needed and click **Connect**.

> ### Why not open the file directly (`file://`)?
> Opening via `file://` gives the page a "null/opaque" origin, and the browser **blocks** the
> creation of Web Workers and cross‑origin `import()` of modules — which is what breaks
> **video conversion** (worker error). Served over `http://`, the page gets a real origin and
> everything works. The Dashboard and most actions do work via `file://`, but video conversion
> does **not** — so prefer `serve.bat`.
>
> **Never** use `https://`: the keyboard is `http://` and the browser would block it as
> "mixed content". Use `http://` (localhost) or, at most, `file://`.

The entered address is saved in `localStorage` for next time.

### Configure Wi‑Fi from the screen (V4)

Before you can talk to the keyboard over the network, it needs to be **connected to your Wi‑Fi**.
This is done **directly on the keyboard's little screen**, no PC required:

1. **Open the screen menu:** press and hold **FN + Menu** at the same time (the keys to the right
   of **FN**, or between **FN** and **Ctrl**) for **at least ~3 seconds**, with the LCD screen mounted/on.
2. On the first item, press **Enter** on the **scan** button to search for Wi‑Fi networks.
3. Select your network and **type the password** using the **arrow keys** (to pick characters) and **Enter** (to confirm).
4. Once connected, press the **down arrow** a few times until you see the **Web Server** section — that's where the keyboard's **IP address** is shown (e.g. `192.168.xx.yy`).
5. Use that IP in the field at the top of this console (or in the browser's address bar) to reach the keyboard.

> On some screen versions, to **display** an uploaded photo/video just press **FN + the
> corresponding key** on the screen itself.

> 🙏 **Credits:** the step-by-step for configuring Wi‑Fi from the screen was based on the report
> by user **AliExpress Shopper** (review from Jul 4, 2025) on the product listing:
> <https://pt.aliexpress.com/item/1005006890321000.html>. Thanks for documenting the process!

---

## Features

| Tab | What it does |
|---|---|
| **Dashboard** | Device state (IP, SSID, timezone, language), status of each widget, a **memory-usage bar**, and a preview (with nickname) of the active image. |
| **Images** | Upload with **automatic rescale to 320×240 JPEG** (_cover_ crop, centered); gallery with **thumbnail + editable nickname** per file; toggle **Fixed image ↔ Slideshow**; adjust the **interval** (2–12 s); enable/disable; set which image shows on the screen; delete. |
| **Video / GIF** | Upload a video (mp4/webm/mkv/avi) or GIF, **converted in the browser itself** (ffmpeg.wasm) to the screen's format; gallery with **thumbnail (1st frame) + nickname**; removal; enable/disable the video app. |
| **Screen Apps** | Toggles for the widgets shown on the keyboard: **Weather**, **APS** (typing speed), **System info** (CPU/RAM), **Video/GIF** and **Slideshow**. |
| **WiFi** | Scans nearby networks (with **signal strength**) and sends new credentials to the keyboard. |
| **Settings** | **Theme** (0/1/2), **timezone**, **city** + **weather API key**, and **custom text** shown on the screen. |

Robustness details:

- **Serial request queue** — respects the embedded server's 1-connection limit.
- **Heartbeat** every 8 s — detects connection drop/recovery and reconnects on its own.
- **Thumbnails + nicknames in SQLite** — the keyboard saves everything with a numeric name
  (e.g. `1781402560644.mpeg`) and **does not return** the files' contents. So you know "who is
  who", `server.py` stores, per file, a **thumbnail** and a **nickname** in a **SQLite** database
  (see [Thumbnail database](#thumbnail-database-sqlite)). When you **delete** a file on the
  keyboard, the record is removed from the database too. Without `server.py` (e.g. opened via
  `file://`), it falls back to `localStorage` automatically.

---

## Troubleshooting

### `Refused to cross-origin redirects of the top-level worker script`
This happened while loading the video conversion engine (ffmpeg.wasm). The `new Worker(...)`
pointed to a CDN URL that **redirects** to another origin, and the browser **refuses a
cross-origin redirect on a worker script**.

**Fixed (part 1):** the ffmpeg worker is now always loaded as a **`blob:`** — `fetch()` follows
the redirect internally and the `Worker` receives a _same-origin_ blob, with no redirect.
The console first tries the **keyboard's own** files (`/ffmpeg.js` + `/assets/worker-*.js`) and,
if that fails, falls back to **unpkg with a pinned version**.

**Root cause (part 2):** the error mostly shows up when the page is opened via **`file://`**, where
the browser blocks Workers and cross‑origin imports. **Solution:** run it over **`http://`**
(use **`serve.bat`** / `python -m http.server`). See [How to use](#how-to-use).

### `DELETE ... blocked by CORS policy: Redirect is not allowed for a preflight request`
Deleting used `DELETE` directly on the keyboard from `http://localhost:8000` (a different origin).
Methods like `DELETE` trigger a **preflight `OPTIONS`**, and the embedded server answers the
preflight with a **redirect** (→ `/wifi` portal) — the browser forbids redirects on a preflight.
(Adding didn't error because `POST multipart/form-data` is a "simple request", no preflight.)
The factory app doesn't suffer from this because it runs **on the same origin** as the keyboard.

**Fixed:** when `server.py` is running, **all** calls to the keyboard go through it
(`/dev/<host>/<path>`). The page talks only to `localhost` (same origin ⇒ no CORS/preflight) and
Python forwards to the keyboard. Without `server.py`, calls go directly (the `DELETE` may fail).

### Requests fail / "offline"
- Confirm the **IP** at the top and that you're on the **same network**.
- Open via **`file://`** or **`http://`** (never `https://`).
- Video conversion needs **the internet** (it downloads the ffmpeg.wasm core from unpkg) — the
  rest works **with the local network only**.

### Thumbnails don't show up for old images
Expected: the device doesn't serve the files back. There's only a preview for images uploaded from
this same browser.

---

## Device API (reverse-engineered)

Base = `http://<ip>`. All paths are relative to the keyboard's IP.

### Reads
| Method | Endpoint | Returns |
|---|---|---|
| `GET` | `/info` | `{mode, ssid, ip, theme, aps_enable, weather_enable, sysinfo_enable, gif_enable, jpg_enable, time_roll, jpg_mode, jpg_file, timezone, language, keytone, keytone_file}` |
| `GET` | `/config.json` | `{ip, port, weather, city, userdata}` |
| `GET` | `/list?dir=/` | `{size: used, total: bytes, data: [{type, name, size}]}` |
| `GET` | `/scan_networks` | `{networks: [{ssid, rssi}]}` |

### Writes / configuration
| Method | Endpoint | Notes |
|---|---|---|
| `POST` | `/config_wifi` | `multipart/form-data` with `ssid` and `password` fields |
| `POST` | `/config_app_weather?enable=<bool>` | enable/disable the weather widget |
| `POST` | `/config_app_aps?enable=<bool>` | enable/disable APS (typing speed) |
| `POST` | `/config_app_sysinfo?enable=<bool>` | enable/disable CPU/RAM info |
| `POST` | `/config_app_gif?enable=<bool>` | enable/disable the video/GIF app |
| `POST` | `/config_app_jpg?enable=<bool>&time_roll=<2000..12000>&jpg_mode=roll\|fixed&jpg_file=<name>` | controls the slideshow |
| `POST` | `/config_theme?theme=0\|1\|2` | screen theme |
| `POST` | `/config_timezone?timezone=<n>` | timezone (UTC+n) |
| `POST` | `/config_keytone?keytone=<0..4>&keytone_file=<name>` | key sound |
| `POST` | `/config.json` | JSON body `{ip, port, weather, city, userdata}` |
| `POST` | `/edit` | file upload — `multipart/form-data`, field **`data`** = File |
| `DELETE` | `/edit?filename=/<name>` | deletes a file |

### Important gotchas
- The server **does not serve back** the uploaded files: any unknown path responds with
  **302 → `http://192.168.4.1/wifi`** (portal). Only the **build assets**
  (`/index.js`, `/index.css`, `/ffmpeg.js`, `/assets/*.js`, `*.svg`, `*.png`, `favicon.ico`)
  are served.
- The server accepts **one connection at a time** — fire requests serially.
- `enable` is sent as a string (`true`/`false`).
- Limits: an image becomes a **320×240 JPEG**; a key-sound file is **≤ 300 KB** (`.wav`/`.mp3`).

---

## How video conversion works

Just like the factory UI: the video is transcoded **in the browser** with **ffmpeg.wasm** to
**MPEG‑1**, at the screen's size. Equivalent command:

```
ffmpeg -i input \
  -vf "scale=w=320:h=240:force_original_aspect_ratio=decrease,fps=23.98" \
  -c:v mpeg1video -b:v 500k -maxrate 800k -an -f mpeg out.mpeg
```

- The `FFmpeg` class (ESM) and the **worker** come from the **keyboard itself** (`/ffmpeg.js`,
  `/assets/worker-*.js`); fallback to `unpkg @ffmpeg/ffmpeg@0.12.15`.
- The **core** (`ffmpeg-core.js` + `.wasm`) comes from `unpkg @ffmpeg/core@0.12.6/dist/esm`.
- Everything is loaded via **`blob:`** to avoid cross‑origin worker blocks.
- The result (`.mpeg`) is sent to the keyboard via `POST /edit`.

---

## Thumbnail database (SQLite)

`server.py` uses **only the Python standard library** (`http.server` + `sqlite3`) — **nothing to
install**. It serves the static files **and** exposes a small API to store, per keyboard file, a
**thumbnail** (JPEG data URL) and a **nickname**. So the gallery no longer shows just
`1781402560644.mpeg` and instead shows the image + the name you gave it.

**Database:** `thumbnails.sqlite` (created next to `server.py`, in WAL mode). Not committed to git.

**Table:**

```sql
CREATE TABLE thumbs(
  name  TEXT PRIMARY KEY,  -- file name on the keyboard (e.g. 1781402560644.mpeg)
  label TEXT,              -- nickname you set
  type  TEXT,              -- image | video | gif
  size  INTEGER,           -- bytes
  thumb TEXT,              -- thumbnail as a data URL (JPEG)
  ts    INTEGER            -- last-update timestamp
);
```

**API (same origin as the page):**

| Method | Endpoint | Function |
|---|---|---|
| `GET` | `/api/health` | check (`{"ok":true}`) — the frontend uses it to detect the database |
| `GET` | `/api/thumbs` | returns `{ "<name>": {label,type,size,thumb,ts}, ... }` |
| `PUT`/`POST` | `/api/thumb` | upsert `{name, label?, type?, size?, thumb?}` (missing fields are preserved) |
| `DELETE` | `/api/thumb?name=...` | removes the record |

**Synchronization:** when uploading an image/video, the frontend generates the thumbnail and does a
`PUT`; when **deleting** the file on the keyboard, it does a `DELETE`. Renaming (editing the
nickname in the gallery) does a `PUT` with just the `label`. If `server.py` isn't running (e.g.
the page was opened via `file://`), all of this falls back to the browser's `localStorage` — no
error.

### Proxy to the keyboard

Besides thumbnails, `server.py` also acts as a **proxy** to the keyboard:

| Method | Endpoint | Function |
|---|---|---|
| `* (any)` | `/dev/<host>/<path>` | forwards the request to `http://<host>/<path>` |

When the frontend detects the local server, it routes **all** device calls through here
(e.g. `/dev/192.168.100.11/edit?...`). Since the page now talks only to the **same origin**
(`localhost`), the browser doesn't fire a CORS preflight — which fixes the `DELETE` error
(see [Troubleshooting](#delete--blocked-by-cors-policy-redirect-is-not-allowed-for-a-preflight-request)).

---

## Project structure

```
skyloong/
├── skyloong-ui.html      ← the console (the main page)
├── server.py             ← local server + SQLite thumbnail API (stdlib)
├── serve.bat             ← starts server.py and opens the browser (recommended)
├── thumbnails.sqlite     ← database generated at runtime (git-ignored)
├── README.md             ← Portuguese docs
├── README.en.md          ← this document (English)
└── reverse/              ← reverse-engineering artifacts (reference)
    ├── index.js          ← keyboard's original bundle (minified)
    ├── index.pretty.js   ← same bundle, formatted (readable)
    ├── index.css         ← original CSS
    ├── ffmpeg.js         ← keyboard's @ffmpeg/ffmpeg ESM wrapper
    └── dev-worker.js     ← ffmpeg worker served by the keyboard
```

---

## Technical notes

- **No build / no dependencies**: HTML + CSS + _vanilla_ JS (the browser's native ES modules).
- **Dark theme**, responsive, with notifications (toasts) and drag‑and‑drop.
- The base IP is auto-detected when the page is **served by the keyboard itself** (same origin);
  otherwise it uses the IP you set at the top of the page (the `192.168.100.11` shown pre-filled is
  **just an example** — replace it with yours).
- Possible evolution: **host this HTML on the keyboard itself** (via `POST /edit`) to replace the
  factory UI and run everything _same-origin_ — but it's risky (it may break the original
  interface) and should be done carefully/with a backup.

---

### License

Distributed under the **MIT** license — see [LICENSE](LICENSE).

The software is provided **"AS IS", without warranty**, and the author **assumes no liability**
for damage, loss, or bricking of the device resulting from its use. Use it at your own risk, only
on your own device. "SKYLOONG" is a trademark of its respective owners; this project is independent
and **unofficial**.
