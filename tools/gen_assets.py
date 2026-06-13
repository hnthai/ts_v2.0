#!/usr/bin/env python3
"""Generate placeholder art + audio for the visual novel.

These are intentionally simple, atmospheric stand-ins so the game runs and is
fully playable BEFORE real (AI-generated) assets are dropped in. Each output
filename matches a reference used by the story JSON, so swapping a placeholder
for a finished asset is just "overwrite the file".

Run from the repo root:  python3 tools/gen_assets.py
Backgrounds -> game/assets/bg/    Characters -> game/assets/char/
Music/SFX   -> game/assets/music/
"""
import math
import os
import struct
import wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG_DIR = os.path.join(ROOT, "game", "assets", "bg")
CHAR_DIR = os.path.join(ROOT, "game", "assets", "char")
MUSIC_DIR = os.path.join(ROOT, "game", "assets", "music")
W, H = 1280, 720


def _font(size):
    for path in [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(top, bottom):
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        c = _lerp(top, bottom, y / H)
        for x in range(W):
            px[x, y] = c
    return img


def mountains(img, color, base_y, jag, alpha=255):
    """Draw a silhouette mountain range."""
    d = ImageDraw.Draw(img, "RGBA")
    pts = [(0, H)]
    x = 0
    import random
    random.seed(base_y + jag)
    y = base_y
    while x <= W:
        y = base_y + random.randint(-jag, jag)
        pts.append((x, y))
        x += random.randint(80, 180)
    pts.append((W, H))
    d.polygon(pts, fill=color + (alpha,))


def glow(img, xy, radius, color):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([xy[0] - radius, xy[1] - radius, xy[0] + radius, xy[1] + radius],
              fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    img.alpha_composite(layer)


# scene name -> (top color, bottom color, builder)
SCENES = {
    "title":            ((24, 16, 48), (70, 30, 60)),
    "sect_gate":        ((120, 150, 190), (210, 200, 170)),
    "hall":             ((60, 45, 40), (110, 80, 60)),
    "courtyard":        ((150, 180, 200), (200, 210, 180)),
    "courtyard_night":  ((20, 22, 45), (50, 30, 40)),
    "night_sky":        ((10, 12, 35), (40, 20, 30)),
    "sunrise_mountain": ((250, 200, 140), (255, 150, 120)),
    "town":             ((180, 190, 200), (200, 180, 150)),
    "forest":           ((40, 70, 50), (90, 120, 70)),
    "arena":            ((90, 80, 110), (160, 150, 140)),
    "demonic_altar":    ((40, 8, 12), (110, 10, 20)),
}


def build_bg(name, top, bottom):
    img = gradient(top, bottom).convert("RGBA")
    if name in ("title", "night_sky", "courtyard_night"):
        import random
        random.seed(hash(name) & 0xffff)
        d = ImageDraw.Draw(img)
        for _ in range(160):
            x, y = random.randint(0, W), random.randint(0, int(H * 0.6))
            r = random.choice([1, 1, 2])
            d.ellipse([x, y, x + r, y + r], fill=(255, 255, 240, 220))
    if name == "demonic_altar":
        glow(img, (W // 2, H // 2), 260, (200, 0, 30, 90))
    if name == "sunrise_mountain":
        glow(img, (W // 2, int(H * 0.45)), 220, (255, 230, 160, 120))
    # layered mountains for outdoor scenes
    if name in ("sect_gate", "sunrise_mountain", "night_sky", "forest",
                "courtyard_night", "town"):
        mountains(img, _lerp(top, bottom, 0.6), int(H * 0.55), 70, 180)
        mountains(img, _lerp(bottom, (0, 0, 0), 0.3), int(H * 0.7), 50, 230)
    # caption tag (small, corner) — easy to spot which placeholder this is
    d = ImageDraw.Draw(img)
    d.text((24, H - 40), f"[BG: {name}]", font=_font(20), fill=(255, 255, 255, 120))
    img.convert("RGB").save(os.path.join(BG_DIR, name + ".png"))


# character id -> (name, robe color)
CHARS = {
    "diep_tran":   ("Diệp Trần", (90, 150, 220)),
    "su_phu":      ("Vân Lão", (200, 190, 150)),
    "lam_uyen":    ("Lâm Uyển", (235, 150, 200)),
    "trieu_phong": ("Triệu Phong", (235, 165, 90)),
    "bach_truong": ("Trưởng lão Bách", (150, 230, 160)),
    "ma_ton":      ("Huyết Ma Tôn", (210, 60, 60)),
}


def build_char(cid, name, color):
    img = Image.new("RGBA", (480, 720), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = 240
    dark = _lerp(color, (0, 0, 0), 0.45)
    light = _lerp(color, (255, 255, 255), 0.25)
    # robe (trapezoid body)
    d.polygon([(cx - 60, 240), (cx + 60, 240), (cx + 150, 700), (cx - 150, 700)],
              fill=color + (255,))
    # robe shading
    d.polygon([(cx, 240), (cx + 60, 240), (cx + 150, 700), (cx, 700)],
              fill=dark + (255,))
    # sleeves
    d.polygon([(cx - 60, 250), (cx - 150, 470), (cx - 90, 480), (cx - 30, 300)],
              fill=light + (255,))
    d.polygon([(cx + 60, 250), (cx + 150, 470), (cx + 90, 480), (cx + 30, 300)],
              fill=light + (255,))
    # head
    skin = (245, 222, 195)
    d.ellipse([cx - 52, 110, cx + 52, 230], fill=skin + (255,))
    # hair
    d.pieslice([cx - 56, 95, cx + 56, 200], 180, 360, fill=dark + (255,))
    d.rectangle([cx - 56, 140, cx - 40, 210], fill=dark + (255,))
    d.rectangle([cx + 40, 140, cx + 56, 210], fill=dark + (255,))
    # collar accent
    d.polygon([(cx - 40, 240), (cx + 40, 240), (cx, 320)], fill=light + (255,))
    # name plate
    f = _font(30)
    bbox = d.textbbox((0, 0), name, font=f)
    tw = bbox[2] - bbox[0]
    d.rounded_rectangle([cx - tw // 2 - 16, 50, cx + tw // 2 + 16, 95],
                        radius=10, fill=(10, 8, 20, 200))
    d.text((cx - tw // 2, 56), name, font=f, fill=(255, 212, 94, 255))
    img.save(os.path.join(CHAR_DIR, cid + ".png"))


# --- audio --------------------------------------------------------------------
RATE = 22050


def _write_wav(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples)
        w.writeframes(frames)


def tone_loop(path, freqs, seconds, vol=0.25):
    """A gentle layered pad that loops seamlessly (integer # of cycles)."""
    n = int(RATE * seconds)
    samples = []
    for i in range(n):
        t = i / RATE
        s = 0.0
        for f in freqs:
            s += math.sin(2 * math.pi * f * t)
        s /= len(freqs)
        # slow tremolo for a 'cultivation ambience' feel
        s *= 0.7 + 0.3 * math.sin(2 * math.pi * 0.2 * t)
        samples.append(s * vol)
    _write_wav(path, samples)


def impact(path, seconds, base=140, noise=0.6):
    import random
    random.seed(int(base))
    n = int(RATE * seconds)
    samples = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-6 * t)
        s = math.sin(2 * math.pi * base * t) * (1 - noise)
        s += (random.random() * 2 - 1) * noise
        samples.append(s * env * 0.6)
    _write_wav(path, samples)


def chime(path):
    n = int(RATE * 1.2)
    samples = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-3 * t)
        s = (math.sin(2 * math.pi * 880 * t) + 0.5 * math.sin(2 * math.pi * 1320 * t))
        samples.append(s * env * 0.3)
    _write_wav(path, samples)


def build_audio():
    tone_loop(os.path.join(MUSIC_DIR, "theme_title.wav"), [196, 261, 329], 8)
    tone_loop(os.path.join(MUSIC_DIR, "theme_calm.wav"), [220, 277, 330], 8)
    tone_loop(os.path.join(MUSIC_DIR, "theme_tense.wav"), [146, 174, 233], 6, 0.22)
    tone_loop(os.path.join(MUSIC_DIR, "theme_battle.wav"), [110, 164, 220], 4, 0.28)
    tone_loop(os.path.join(MUSIC_DIR, "theme_sad.wav"), [174, 207, 261], 8, 0.20)
    tone_loop(os.path.join(MUSIC_DIR, "theme_victory.wav"), [261, 329, 392], 6, 0.28)
    impact(os.path.join(MUSIC_DIR, "boom.wav"), 0.8, base=70, noise=0.8)
    impact(os.path.join(MUSIC_DIR, "clash.wav"), 0.5, base=520, noise=0.5)
    chime(os.path.join(MUSIC_DIR, "chime.wav"))


def main():
    for d in (BG_DIR, CHAR_DIR, MUSIC_DIR):
        os.makedirs(d, exist_ok=True)
    for name, (top, bottom) in SCENES.items():
        build_bg(name, top, bottom)
        print("bg :", name)
    for cid, (name, color) in CHARS.items():
        build_char(cid, name, color)
        print("char:", cid)
    build_audio()
    print("audio: themes + sfx")
    print("Done.")


if __name__ == "__main__":
    main()
