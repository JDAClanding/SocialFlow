"""SOCIALFLOW backend — the Flask API the Flutter/web wizard talks to.

Quick start:
    pip install -r requirements.txt
    python server.py
The app defaults to http://localhost:8080 (lib/api.dart). To point it at a
deployed copy instead: flutter run --dart-define=API_URL=https://your-host

Everything works with zero configuration (free DuckDuckGo-based search/
image-search, and a local placeholder image generator). Copy .env.example
to .env and fill in provider keys to unlock real AI image generation and
the official Meta Ad Library API — see README-HOSTING.md.
"""
import base64
import io
import ipaddress
import json
import os
import re
import socket
import textwrap
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import parse_qs, unquote, urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from flask import Flask, Response, jsonify, request, send_from_directory
from flask_cors import CORS
from PIL import Image, ImageDraw, ImageFont

load_dotenv()

APP_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(APP_DIR, 'data')
PROJECTS_DIR = os.path.join(DATA_DIR, 'projects')
GENERATED_DIR = os.path.join(DATA_DIR, 'generated')
os.makedirs(PROJECTS_DIR, exist_ok=True)
os.makedirs(GENERATED_DIR, exist_ok=True)

app = Flask(__name__)
CORS(app)

UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36')
HEADERS = {
    'User-Agent': UA,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

# cloudscraper solves Cloudflare's "I'm Under Attack" JS challenge, which is
# why plain requests gets a 403 from some sites even with a real browser's
# User-Agent. Falls back to a plain session if it's not installed, or if a
# site's protection is stronger than that (Turnstile/managed challenges) —
# nothing short of a real browser gets past those, so a clear error is the
# best we can do there.
try:
    import cloudscraper
    SESSION = cloudscraper.create_scraper(
        browser={'browser': 'chrome', 'platform': 'windows', 'desktop': True})
except Exception:
    SESSION = requests.Session()
    SESSION.headers.update(HEADERS)

JOBS = {}  # job_id -> {status, url?, model_name?, price?, error?}


# ------------------------------------------------------------------ utils --

def err(message, status=200):
    return jsonify({'error': message}), status


def safe_get(url, **kw):
    kw.setdefault('timeout', 12)
    return SESSION.get(url, **kw)


def is_private_host(hostname):
    """Blocks SSRF against internal/loopback/link-local addresses."""
    try:
        infos = socket.getaddrinfo(hostname, None)
    except Exception:
        return True
    for info in infos:
        try:
            addr = ipaddress.ip_address(info[4][0])
        except ValueError:
            continue
        if addr.is_private or addr.is_loopback or addr.is_link_local or addr.is_reserved:
            return True
    return False


def validate_public_url(url):
    try:
        p = urlparse(url)
    except Exception:
        return False
    if p.scheme not in ('http', 'https') or not p.hostname:
        return False
    return not is_private_host(p.hostname)


PID_RE = re.compile(r'^[0-9a-f]{6,32}$')


# ------------------------------------------------------------- web search --
# Free, no-key DuckDuckGo scraping. Best-effort: DDG's HTML can change
# without notice. Swap in a paid search API here for production reliability.

def unwrap_ddg_link(href):
    if not href:
        return href
    if href.startswith('//'):
        href = 'https:' + href
    try:
        p = urlparse(href)
        if 'duckduckgo.com' in p.netloc and p.path.startswith('/l/'):
            real = parse_qs(p.query).get('uddg', [None])[0]
            if real:
                return unquote(real)
    except Exception:
        pass
    return href


def ddg_text_search(query, max_results=8):
    try:
        r = safe_get('https://html.duckduckgo.com/html/', params={'q': query})
        soup = BeautifulSoup(r.text, 'html.parser')
        out = []
        for res in soup.select('div.result')[:max_results]:
            a = res.select_one('a.result__a')
            if not a:
                continue
            snippet_el = res.select_one('.result__snippet')
            out.append({
                'title': a.get_text(strip=True),
                'url': unwrap_ddg_link(a.get('href', '')),
                'snippet': snippet_el.get_text(strip=True) if snippet_el else '',
            })
        return out
    except Exception:
        return []


def ddg_vqd(query):
    try:
        r = safe_get('https://duckduckgo.com/', params={'q': query})
        m = re.search(r"vqd=(['\"]?)([\d-]+)\1", r.text) or re.search(r'vqd=([\d-]+)', r.text)
        return m.group(m.lastindex) if m else None
    except Exception:
        return None


def ddg_image_search(query, max_results=8):
    try:
        vqd = ddg_vqd(query)
        if not vqd:
            return []
        headers = dict(HEADERS, Referer='https://duckduckgo.com/')
        r = safe_get('https://duckduckgo.com/i.js', headers=headers,
                      params={'l': 'us-en', 'o': 'json', 'q': query, 'vqd': vqd, 'f': ',,,', 'p': '1'})
        results = r.json().get('results', [])[:max_results]
        return [{
            'image': item.get('image'),
            'thumb': item.get('thumbnail'),
            'title': item.get('title', ''),
            'source': item.get('url', ''),
        } for item in results]
    except Exception:
        return []


@app.get('/api/search')
def api_search():
    q = request.args.get('q', '').strip()
    if not q:
        return err('Missing q')
    return jsonify({'results': ddg_text_search(q, 10)})


# ---------------------------------------------------------- site scraping --

@app.get('/api/siteimages')
def api_siteimages():
    url = request.args.get('url', '').strip()
    if not url:
        return err('Missing url')
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    if not validate_public_url(url):
        return err("Can't reach that website (invalid address)")
    try:
        r = safe_get(url, timeout=20)
        r.raise_for_status()
    except requests.exceptions.SSLError:
        return err(f"Couldn't load {url} — its SSL certificate is invalid or expired")
    except requests.exceptions.Timeout:
        return err(f"Couldn't load {url} — the site took too long to respond")
    except requests.exceptions.ConnectionError as e:
        print(f'[siteimages] connection error for {url}: {e}')
        return err(f"Couldn't load {url} — couldn't connect (check the domain, or the site may be blocking this server's IP)")
    except requests.exceptions.HTTPError as e:
        return err(f"Couldn't load {url} — the site returned HTTP {e.response.status_code} "
                    "(it may be blocking automated requests)")
    except Exception as e:
        print(f'[siteimages] unexpected error for {url}: {e!r}')
        return err(f"Couldn't load {url} — {type(e).__name__}")

    soup = BeautifulSoup(r.text, 'html.parser')
    title = soup.title.get_text(strip=True) if soup.title else ''
    desc_el = soup.find('meta', attrs={'name': 'description'}) or \
        soup.find('meta', attrs={'property': 'og:description'})
    desc = (desc_el.get('content', '') if desc_el else '').strip()
    body_text = ' '.join(soup.get_text(' ', strip=True).split())
    text = ' — '.join(t for t in (title, desc) if t)
    text = f'{text} {body_text}'.strip()

    images, seen = [], set()
    og_img = soup.find('meta', attrs={'property': 'og:image'})
    if og_img and og_img.get('content'):
        full = urljoin(url, og_img['content'])
        images.append(full)
        seen.add(full)
    for img in soup.find_all('img'):
        src = img.get('src') or img.get('data-src') or img.get('data-lazy-src')
        if not src:
            continue
        full = urljoin(url, src)
        low = full.lower()
        if full in seen or not full.startswith(('http://', 'https://')):
            continue
        if any(x in low for x in ('logo', 'icon', 'sprite', '.svg', '1x1', 'pixel.')):
            continue
        seen.add(full)
        images.append(full)
        if len(images) >= 24:
            break
    return jsonify({'text': text[:4000], 'images': images})


@app.get('/api/img')
def api_img():
    u = request.args.get('u', '')
    if not validate_public_url(u):
        return err('Invalid image URL', 400)
    try:
        r = requests.get(u, headers=HEADERS, timeout=12)
        r.raise_for_status()
    except Exception:
        return err('Could not fetch image', 502)
    return Response(r.content, content_type=r.headers.get('Content-Type', 'image/jpeg'))


# ------------------------------------------------------------- competitor --

SOCIAL_PLATFORMS = {
    'instagram': 'instagram.com',
    'tiktok': 'tiktok.com',
    'facebook': 'facebook.com',
    'twitter': 'x.com',
    'youtube': 'youtube.com',
    'linkedin': 'linkedin.com',
}

FOLLOWER_RE = re.compile(r'([\d.,]+\s?[KMB]?)\s+Followers', re.I)
SKIP_SLUGS = {'p', 'reel', 'watch', 'explore', 'hashtag', 'share', 'video', 'shorts', 'company'}


def extract_handle(u, domain):
    try:
        slug = urlparse(u).path.strip('/').split('/')[0]
    except Exception:
        return None
    if not slug or slug.lower() in SKIP_SLUGS:
        return None
    return f'@{slug}' if domain in ('instagram.com', 'tiktok.com', 'x.com') else slug


def scrape_followers(u):
    try:
        r = safe_get(u, timeout=8)
        soup = BeautifulSoup(r.text, 'html.parser')
        desc_el = soup.find('meta', attrs={'property': 'og:description'}) or \
            soup.find('meta', attrs={'name': 'description'})
        m = FOLLOWER_RE.search(desc_el.get('content', '') if desc_el else '')
        return m.group(1) if m else None
    except Exception:
        return None


def analyze_platform(name, platform, domain):
    results = ddg_text_search(f'site:{domain} {name}', max_results=3)
    url = next((r['url'] for r in results if domain in r['url']), None)
    if not url:
        return platform, None, None
    return platform, extract_handle(url, domain), scrape_followers(url)


@app.get('/api/analyze')
def api_analyze():
    name = request.args.get('name', '').strip()
    if not name:
        return err('Missing name')
    handles, followers = {}, {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = [ex.submit(analyze_platform, name, p, d) for p, d in SOCIAL_PLATFORMS.items()]
        for fut in futs:
            platform, handle, count = fut.result()
            if handle:
                handles[platform] = handle
            if count:
                followers[platform] = count
    return jsonify({'report': {'name': name, 'handles': handles, 'followers': followers}})


SUGGEST_QUERIES = {
    'campaigns': '{name} marketing campaign',
    'stats': '{name} brand statistics revenue',
    'ugc': '{name} user generated content customers',
    'trends': '{name} social media trend',
    'memes': '{name} meme viral',
}


@app.get('/api/suggest')
def api_suggest():
    base = request.args.get('base', '').strip()
    cats = [c for c in request.args.get('cats', '').split(',') if c]
    if not base or not cats:
        return err('Missing base or cats')
    out = {}
    with ThreadPoolExecutor(max_workers=len(cats)) as ex:
        futs = {ex.submit(ddg_text_search, SUGGEST_QUERIES.get(c, f'{base} {c}').format(name=base), 6): c
                for c in cats}
        for fut, c in futs.items():
            out[c] = fut.result()
    return jsonify({'categories': out})


GRAPHIC_QUERIES = {
    'Campaigns': '{name} advertising campaign',
    'Social posts': '{name} instagram post',
    'Product': '{name} product photography',
    'Packaging': '{name} packaging design',
}


@app.get('/api/graphics')
def api_graphics():
    name = request.args.get('name', '').strip()
    if not name:
        return err('Missing name')
    graphics = []
    with ThreadPoolExecutor(max_workers=len(GRAPHIC_QUERIES)) as ex:
        futs = {ex.submit(ddg_image_search, q.format(name=name), 6): cat
                for cat, q in GRAPHIC_QUERIES.items()}
        for fut, cat in futs.items():
            for item in fut.result():
                graphics.append({**item, 'category': cat})
    return jsonify({'graphics': graphics})


@app.get('/api/metaads')
def api_metaads():
    name = request.args.get('name', '').strip()
    if not name:
        return err('Missing name')
    token = os.environ.get('FB_ACCESS_TOKEN')
    if token:
        try:
            r = safe_get('https://graph.facebook.com/v19.0/ads_archive', timeout=15, params={
                'search_terms': name,
                'ad_reached_countries': "['US']",
                'ad_active_status': 'ALL',
                'limit': 20,
                'access_token': token,
                'fields': 'ad_creative_bodies,ad_creative_link_titles,ad_delivery_start_time,'
                          'ad_delivery_stop_time,page_name,publisher_platforms',
            })
            data = r.json()
            if 'data' in data:
                ads = [{
                    'page': a.get('page_name', ''),
                    'title': (a.get('ad_creative_link_titles') or [''])[0],
                    'body': (a.get('ad_creative_bodies') or [''])[0],
                    'start': a.get('ad_delivery_start_time', ''),
                    'stop': a.get('ad_delivery_stop_time', ''),
                    'platforms': ', '.join(a.get('publisher_platforms') or []),
                    'image': '', 'thumb': '',
                } for a in data['data']]
                return jsonify({'ads': ads, 'mode': 'api', 'countries': ['US']})
        except Exception:
            pass  # fall through to search mode
    images = ddg_image_search(f'{name} facebook ad sponsored', 10)
    ads = [{
        'page': name, 'title': img.get('title', ''), 'body': '',
        'start': '', 'stop': '', 'platforms': '',
        'image': img.get('image', ''), 'thumb': img.get('thumb', ''),
    } for img in images]
    return jsonify({'ads': ads, 'mode': 'search'})


# ------------------------------------------------------- image generation --
# Model 'key' values match the provider fields already hardcoded in the
# Flutter app's Studio settings panel (lib/screens/studio_screen.dart).

MODELS = [
    {'id': 'placeholder', 'name': 'Placeholder (offline)', 'provider': 'local',
     'price': 0, 'key': None, 'refs': False,
     'note': 'No API key needed — draws a labeled placeholder so the whole flow works.'},
    {'id': 'fal', 'name': 'FLUX (fal.ai)', 'provider': 'fal.ai',
     'price': 0.003, 'key': 'FAL_KEY', 'refs': True, 'note': 'Fast, cheap, supports a reference image.'},
    {'id': 'replicate', 'name': 'FLUX (Replicate)', 'provider': 'Replicate',
     'price': 0.003, 'key': 'REPLICATE_API_TOKEN', 'refs': True, 'note': 'Supports a reference image.'},
    {'id': 'gemini', 'name': 'Imagen 3 (Google)', 'provider': 'Google',
     'price': 0.02, 'key': 'GEMINI_API_KEY', 'refs': False, 'note': ''},
    {'id': 'stability', 'name': 'Stable Diffusion 3.5', 'provider': 'Stability AI',
     'price': 0.035, 'key': 'STABILITY_API_KEY', 'refs': False, 'note': ''},
    {'id': 'openai', 'name': 'gpt-image-1', 'provider': 'OpenAI',
     'price': 0.04, 'key': 'OPENAI_API_KEY', 'refs': False, 'note': 'Highest quality text rendering.'},
]

RATIO_PX = {'1:1': (1024, 1024), '9:16': (896, 1600), '16:9': (1600, 896)}


def model_ready(model):
    return model['key'] is None or bool(os.environ.get(model['key']))


@app.get('/api/models')
def api_models():
    return jsonify({'models': [{**m, 'ready': model_ready(m)} for m in MODELS]})


def gen_placeholder(prompt, ratio):
    w, h = RATIO_PX.get(ratio, (1024, 1024))
    img = Image.new('RGB', (w, h), (233, 224, 210))
    draw = ImageDraw.Draw(img)
    draw.rectangle([20, 20, w - 20, h - 20], outline=(122, 78, 42), width=4)
    try:
        title_font = ImageFont.truetype('DejaVuSans-Bold.ttf', 30)
        body_font = ImageFont.truetype('DejaVuSans.ttf', 18)
    except Exception:
        title_font = body_font = ImageFont.load_default()
    draw.text((w / 2, h / 2 - 40), 'PLACEHOLDER IMAGE', fill=(122, 78, 42),
               font=title_font, anchor='mm')
    draw.multiline_text((w / 2, h / 2 + 10), textwrap.fill(prompt, width=42),
                         fill=(90, 74, 58), font=body_font, anchor='ma', align='center')
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return buf.getvalue(), 'image/png'


def gen_fal(prompt, ratio, api_key, refs):
    image_size = {'1:1': 'square_hd', '9:16': 'portrait_16_9', '16:9': 'landscape_16_9'}.get(ratio, 'square_hd')
    if refs:
        endpoint, payload = 'https://fal.run/fal-ai/flux/dev/image-to-image', \
            {'prompt': prompt, 'image_url': refs[0]}
    else:
        endpoint, payload = 'https://fal.run/fal-ai/flux/schnell', \
            {'prompt': prompt, 'image_size': image_size}
    r = requests.post(endpoint, timeout=90,
                       headers={'Authorization': f'Key {api_key}', 'Content-Type': 'application/json'},
                       json=payload)
    r.raise_for_status()
    img_url = r.json()['images'][0]['url']
    ir = requests.get(img_url, timeout=60)
    return ir.content, ir.headers.get('Content-Type', 'image/png')


def gen_replicate(prompt, ratio, api_key, refs):
    aspect = {'1:1': '1:1', '9:16': '9:16', '16:9': '16:9'}.get(ratio, '1:1')
    payload = {'input': {'prompt': prompt, 'aspect_ratio': aspect}}
    if refs:
        payload['input']['image'] = refs[0]
    r = requests.post('https://api.replicate.com/v1/models/black-forest-labs/flux-schnell/predictions',
                       timeout=90, json=payload,
                       headers={'Authorization': f'Bearer {api_key}', 'Content-Type': 'application/json',
                                'Prefer': 'wait'})
    r.raise_for_status()
    output = r.json().get('output')
    img_url = output[0] if isinstance(output, list) else output
    ir = requests.get(img_url, timeout=60)
    return ir.content, ir.headers.get('Content-Type', 'image/png')


def gen_gemini(prompt, ratio, api_key):
    aspect = {'1:1': '1:1', '9:16': '9:16', '16:9': '16:9'}.get(ratio, '1:1')
    r = requests.post(
        f'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key={api_key}',
        timeout=90,
        json={'instances': [{'prompt': prompt}], 'parameters': {'sampleCount': 1, 'aspectRatio': aspect}},
    )
    r.raise_for_status()
    b64 = r.json()['predictions'][0]['bytesBase64Encoded']
    return base64.b64decode(b64), 'image/png'


def gen_stability(prompt, ratio, api_key):
    aspect = {'1:1': '1:1', '9:16': '9:16', '16:9': '16:9'}.get(ratio, '1:1')
    r = requests.post('https://api.stability.ai/v2beta/stable-image/generate/sd3', timeout=90,
                       headers={'Authorization': f'Bearer {api_key}', 'Accept': 'image/*'},
                       files={'none': (None, '')},
                       data={'prompt': prompt, 'aspect_ratio': aspect, 'output_format': 'png'})
    r.raise_for_status()
    return r.content, 'image/png'


def gen_openai(prompt, ratio, api_key):
    size = {'1:1': '1024x1024', '9:16': '1024x1792', '16:9': '1792x1024'}.get(ratio, '1024x1024')
    r = requests.post('https://api.openai.com/v1/images/generations', timeout=90,
                       headers={'Authorization': f'Bearer {api_key}', 'Content-Type': 'application/json'},
                       json={'model': 'gpt-image-1', 'prompt': prompt, 'size': size, 'n': 1})
    r.raise_for_status()
    data = r.json()['data'][0]
    if data.get('b64_json'):
        return base64.b64decode(data['b64_json']), 'image/png'
    ir = requests.get(data['url'], timeout=60)
    return ir.content, ir.headers.get('Content-Type', 'image/png')


def run_job(job_id, prompt, ratio, model_id, refs, client_keys, base_url):
    model = next((m for m in MODELS if m['id'] == model_id), MODELS[0])
    JOBS[job_id]['model_name'] = model['name']
    try:
        api_key = os.environ.get(model['key']) or (client_keys or {}).get(model['key']) if model['key'] else None
        if model['id'] == 'fal':
            content, ctype = gen_fal(prompt, ratio, api_key, refs)
        elif model['id'] == 'replicate':
            content, ctype = gen_replicate(prompt, ratio, api_key, refs)
        elif model['id'] == 'gemini':
            content, ctype = gen_gemini(prompt, ratio, api_key)
        elif model['id'] == 'stability':
            content, ctype = gen_stability(prompt, ratio, api_key)
        elif model['id'] == 'openai':
            content, ctype = gen_openai(prompt, ratio, api_key)
        else:
            content, ctype = gen_placeholder(prompt, ratio)
        fname = f"{job_id}.{'png' if 'png' in ctype else 'jpg'}"
        with open(os.path.join(GENERATED_DIR, fname), 'wb') as f:
            f.write(content)
        JOBS[job_id].update({'status': 'done', 'url': f'{base_url}/generated/{fname}', 'price': model['price']})
    except Exception as e:
        JOBS[job_id].update({'status': 'error', 'error': f'{model["name"]} failed: {e}'})


@app.post('/api/genimage')
def api_genimage_start():
    body = request.get_json(force=True, silent=True) or {}
    prompt = (body.get('prompt') or '').strip()
    if not prompt:
        return err('Missing prompt')
    ratio = body.get('ratio') or '1:1'
    model_id = body.get('model') or 'auto'
    refs = body.get('reference_image_urls') or []
    client_keys = body.get('keys') or {}

    if model_id == 'auto':
        ready = [m for m in MODELS if model_ready(m) or client_keys.get(m['key'] or '')]
        model_id = min(ready, key=lambda m: m['price'])['id'] if ready else 'placeholder'

    job_id = uuid.uuid4().hex[:12]
    JOBS[job_id] = {'status': 'processing'}
    base_url = request.host_url.rstrip('/')
    threading.Thread(target=run_job, daemon=True,
                      args=(job_id, prompt, ratio, model_id, refs, client_keys, base_url)).start()
    return jsonify({'job': job_id})


@app.get('/api/genimage/<job_id>')
def api_genimage_status(job_id):
    job = JOBS.get(job_id)
    if not job:
        return err('Unknown job', 404)
    return jsonify(job)


@app.get('/generated/<path:fname>')
def serve_generated(fname):
    return send_from_directory(GENERATED_DIR, fname)


# --------------------------------------------------------------- projects --

@app.post('/api/project')
def api_save_project():
    body = request.get_json(force=True, silent=True) or {}
    pid = uuid.uuid4().hex[:10]
    with open(os.path.join(PROJECTS_DIR, f'{pid}.json'), 'w') as f:
        json.dump({'name': body.get('name') or 'Campaign', 'data': body.get('data') or {},
                    'created': time.time()}, f)
    return jsonify({'path': f'/p/{pid}'})


def load_project(pid):
    if not PID_RE.match(pid or ''):
        return None
    path = os.path.join(PROJECTS_DIR, f'{pid}.json')
    if not os.path.isfile(path):
        return None
    with open(path) as f:
        return json.load(f)


@app.get('/api/project/<pid>')
def api_get_project(pid):
    payload = load_project(pid)
    if payload is None:
        return err('Project not found', 404)
    return jsonify(payload)


@app.get('/p/<pid>')
def share_project(pid):
    return api_get_project(pid)


@app.get('/')
def index():
    return jsonify({'ok': True, 'service': 'socialflow-server'})


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=os.environ.get('DEBUG', '').lower() == 'true')
