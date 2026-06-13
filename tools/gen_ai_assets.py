#!/usr/bin/env python3
"""Generate REAL game art via an image-generation API and drop it straight into
game/assets/ (correct filenames, sizes, transparent character cut-outs).

This is the "upgrade from placeholders" step. It does NOT use OpenAI Codex —
Codex only writes code; image generation needs an *image* model. Supported
providers (pick with --provider, or set IMG_PROVIDER):

  openai     gpt-image-1            env: OPENAI_API_KEY     (best transparency)
  gemini     imagen-3.0-generate   env: GEMINI_API_KEY
  stability  stable-image core     env: STABILITY_API_KEY  (no transparent chars)

Usage (run on a machine that has the API key + network access):
    pip install Pillow
    export OPENAI_API_KEY=sk-...
    python3 tools/gen_ai_assets.py                 # all, skip existing
    python3 tools/gen_ai_assets.py --only char     # just characters
    python3 tools/gen_ai_assets.py --force         # overwrite
    python3 tools/gen_ai_assets.py --list          # offline: show prompts only

The network policy of the Claude-on-the-web sandbox may block these API hosts;
in that case run this script locally. Everything except the HTTP call is
sandbox-safe and can be verified here with --list.
"""
import argparse
import base64
import io
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG_DIR = os.path.join(ROOT, "game", "assets", "bg")
CHAR_DIR = os.path.join(ROOT, "game", "assets", "char")

STYLE = ("Chinese xianxia cultivation fantasy, donghua anime style, "
         "cinematic lighting, highly detailed, masterpiece, no text, no watermark")

# name -> scene description (background)
BACKGROUNDS = {
    "title": "epic immortal mountain peak above a sea of clouds, a lone sword cultivator silhouette gazing afar, purple-gold mystical glow, grand title-screen composition",
    "valley": "small peaceful hidden valley (Van Ha Coc), stream, bamboo chair, white clouds drifting across, where a hermit master secludes",
    "sect_gate": "ancient cultivation sect gate on a misty mountain, daytime, mossy, slightly run-down yet dignified",
    "hall": "ancient wooden grand hall inside a sect, warm candlelight, dragon-carved pillars, solemn",
    "courtyard": "stone cultivation courtyard, old great tree, clear daytime",
    "courtyard_night": "sect courtyard at night, cold moonlight, tense ominous atmosphere",
    "night_sky": "starry night sky over a mountain range, faint mist, eerie stillness",
    "sunrise_mountain": "golden-orange sunrise over a sea of clouds and immortal peaks, hopeful, majestic",
    "town": "bustling ancient Chinese town at the foot of a mountain, tiled roofs, red lanterns",
    "forest": "spirit-energy ancient/bamboo forest, light rays through the canopy, slightly mysterious",
    "arena": "stone duel arena in a sect plaza, spectator stands, imposing tournament mood",
    "demonic_altar": "demonic cult sacrificial altar, glowing red blood circle, evil aura, red smoke",
}

# id -> character description (transparent cut-out)
CHARACTERS = {
    "co_huyen": "Master Co Huyen, a calm lazy-looking man whose aura is unfathomably deep, simple blue robe, holding a tea cup, deep eyes hiding the heavens",
    "lang_thien": "eldest disciple Lang Thien, a hot-blooded arrogant young swordsman, orange-brown robe, holding a longsword, white sword-qi",
    "to_tuyet": "second disciple To Tuyet, a girl with Profound Yin Ice Body, white-blue robe, cold icy elegant aura, snow swirling around her",
    "linh_nhi": "youngest disciple Linh Nhi, a cute ~8-year-old girl with an All-Spirits Heart, pink robe, holding a snow rabbit, small spirit creatures around her",
    "bach_truong": "Elder Bach of Profound Heaven Sect, an arrogant middle-aged sword cultivator, dark green robe, holding a longsword",
    "ma_ton": "Blood Demon Ancestor, the villain, red-black robe, demonic aura, red eyes, blood energy swirling around him",
}


# --- provider calls: each returns raw image bytes -----------------------------

def _post_json(url, payload, headers):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={**headers, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode())


def gen_openai(prompt, transparent):
    key = os.environ["OPENAI_API_KEY"]
    payload = {
        "model": "gpt-image-1",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1536" if transparent else "1536x1024",
        "quality": "high",
    }
    if transparent:
        payload["background"] = "transparent"
    data = _post_json("https://api.openai.com/v1/images/generations", payload,
                      {"Authorization": f"Bearer {key}"})
    return base64.b64decode(data["data"][0]["b64_json"])


def gen_gemini(prompt, transparent):
    key = os.environ["GEMINI_API_KEY"]
    url = ("https://generativelanguage.googleapis.com/v1beta/models/"
           f"imagen-3.0-generate-002:predict?key={key}")
    payload = {"instances": [{"prompt": prompt}],
               "parameters": {"sampleCount": 1,
                              "aspectRatio": "3:4" if transparent else "16:9"}}
    data = _post_json(url, payload, {})
    return base64.b64decode(data["predictions"][0]["bytesBase64Encoded"])


def gen_stability(prompt, transparent):
    import uuid
    key = os.environ["STABILITY_API_KEY"]
    boundary = uuid.uuid4().hex
    fields = {"prompt": prompt, "output_format": "png",
              "aspect_ratio": "3:4" if transparent else "16:9"}
    body = b""
    for k, v in fields.items():
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\""
                 f"\r\n\r\n{v}\r\n").encode()
    body += f"--{boundary}--\r\n".encode()
    req = urllib.request.Request(
        "https://api.stability.ai/v2beta/stable-image/generate/core", data=body,
        headers={"Authorization": f"Bearer {key}", "Accept": "image/*",
                 "Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return r.read()


PROVIDERS = {"openai": (gen_openai, "OPENAI_API_KEY"),
             "gemini": (gen_gemini, "GEMINI_API_KEY"),
             "stability": (gen_stability, "STABILITY_API_KEY")}


# --- post-processing ----------------------------------------------------------

def save_bg(raw, path):
    from PIL import Image
    img = Image.open(io.BytesIO(raw)).convert("RGB")
    tw, th = 1280, 720
    scale = max(tw / img.width, th / img.height)
    img = img.resize((round(img.width * scale), round(img.height * scale)))
    left, top = (img.width - tw) // 2, (img.height - th) // 2
    img.crop((left, top, left + tw, top + th)).save(path)


def save_char(raw, path):
    from PIL import Image
    img = Image.open(io.BytesIO(raw)).convert("RGBA")
    bbox = img.getbbox()           # trim transparent margins if present
    if bbox:
        img = img.crop(bbox)
    h = 700
    img = img.resize((round(img.width * h / img.height), h))
    img.save(path)


# --- driver -------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", default=os.environ.get("IMG_PROVIDER", "openai"),
                    choices=list(PROVIDERS))
    ap.add_argument("--only", default="all", choices=["all", "bg", "char"])
    ap.add_argument("--force", action="store_true", help="overwrite existing files")
    ap.add_argument("--list", action="store_true", help="print prompts and exit (offline)")
    args = ap.parse_args()

    jobs = []
    if args.only in ("all", "bg"):
        for n, d in BACKGROUNDS.items():
            jobs.append(("bg", n, os.path.join(BG_DIR, n + ".png"),
                         f"{d}. {STYLE}. Wide cinematic scenery, leave the lower third uncluttered.", False))
    if args.only in ("all", "char"):
        for n, d in CHARACTERS.items():
            jobs.append(("char", n, os.path.join(CHAR_DIR, n + ".png"),
                         f"{d}. {STYLE}. Full-body, standing, centered, isolated on a plain transparent background, clean edges.", True))

    if args.list:
        for kind, name, _, prompt, _ in jobs:
            print(f"\n[{kind}] {name}\n  {prompt}")
        print(f"\n{len(jobs)} assets. Provider would be: {args.provider}")
        return

    gen, env = PROVIDERS[args.provider]
    if env not in os.environ:
        sys.exit(f"Missing {env}. export {env}=... (or use --list to preview offline).")

    os.makedirs(BG_DIR, exist_ok=True)
    os.makedirs(CHAR_DIR, exist_ok=True)
    for kind, name, path, prompt, transparent in jobs:
        if os.path.exists(path) and not args.force:
            print(f"skip (exists): {kind}/{name}")
            continue
        print(f"gen {kind}/{name} ...", flush=True)
        try:
            raw = gen(prompt, transparent)
            (save_char if transparent else save_bg)(raw, path)
            print(f"  -> {path}")
        except Exception as e:  # keep going; one failure shouldn't abort the batch
            print(f"  !! failed: {e}")
    print("Done.")


if __name__ == "__main__":
    main()
