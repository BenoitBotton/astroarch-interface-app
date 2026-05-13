"""Genera icona Astroarch Interface (1024x1024 + foreground 1024x1024 trasparente).

Stile: sfondo notturno con punti stellari, stella centrale ambra con spike
di diffrazione (Newton-style), bordo morbido. Foreground per icona adattiva
Android: solo elementi centrali su trasparente, dentro safe-zone (66%).
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
OUT_DIR = Path(__file__).parent
random.seed(42)

# Palette
BG_OUTER = (8, 12, 22)
BG_INNER = (16, 24, 44)
STAR_COLOR = (245, 166, 35)    # ambra
STAR_HALO = (255, 200, 100)
STAR_CORE = (255, 240, 200)
DUST_COLOR = (90, 130, 200)


def _radial_bg(size: int) -> Image.Image:
    img = Image.new('RGB', (size, size), BG_OUTER)
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    max_r = int(size * 0.7)
    for r in range(max_r, 0, -2):
        t = r / max_r
        col = (
            int(BG_INNER[0] * (1 - t) + BG_OUTER[0] * t),
            int(BG_INNER[1] * (1 - t) + BG_OUTER[1] * t),
            int(BG_INNER[2] * (1 - t) + BG_OUTER[2] * t),
        )
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    return img


def _add_field_stars(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img, 'RGBA')
    for _ in range(140):
        x = random.randint(0, SIZE)
        y = random.randint(0, SIZE)
        r = random.choice([1, 1, 1, 1, 2, 2, 3])
        b = random.randint(140, 240)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(b, b, b + 15 if b < 240 else b, 240))


def _draw_central_star(img: Image.Image, with_glow: bool = True) -> None:
    """Stella centrale grande con croce di diffrazione."""
    cx, cy = SIZE // 2, SIZE // 2

    if with_glow:
        # Halo morbido
        glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        for r, alpha in [(380, 30), (300, 50), (220, 80), (160, 130)]:
            gdraw.ellipse([cx - r, cy - r, cx + r, cy + r],
                          fill=(*STAR_HALO, alpha))
        glow = glow.filter(ImageFilter.GaussianBlur(radius=20))
        img.alpha_composite(glow) if img.mode == 'RGBA' else img.paste(glow, (0, 0), glow)

    # Core
    star_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(star_layer)

    # Cross spikes (4 punte)
    spike_len = 380
    spike_w = 14
    sdraw.rectangle([cx - spike_w // 2, cy - spike_len, cx + spike_w // 2, cy + spike_len],
                    fill=(*STAR_CORE, 230))
    sdraw.rectangle([cx - spike_len, cy - spike_w // 2, cx + spike_len, cy + spike_w // 2],
                    fill=(*STAR_CORE, 230))
    # Spikes diagonali (più sottili)
    for ang in (math.pi / 4, -math.pi / 4):
        for t in range(-spike_len, spike_len):
            x = cx + int(t * math.cos(ang))
            y = cy + int(t * math.sin(ang))
            alpha = max(0, 200 - abs(t) // 2)
            sdraw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(*STAR_HALO, alpha))

    # Bulge centrale
    for r, alpha in [(120, 200), (90, 230), (60, 250), (35, 255), (15, 255)]:
        col = STAR_CORE if r <= 35 else STAR_COLOR
        sdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*col, alpha))

    star_layer = star_layer.filter(ImageFilter.GaussianBlur(radius=2))
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    img.alpha_composite(star_layer)


def _draw_orbit_ring(img: Image.Image) -> None:
    """Anello sottile ambra ad indicare l'osservatorio - tema 'orbit'."""
    layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = SIZE // 2, SIZE // 2
    r = 430
    # ellisse leggermente schiacciata
    for w, alpha in [(6, 60), (4, 110), (2, 180)]:
        draw.ellipse([cx - r, cy - int(r * 0.55), cx + r, cy + int(r * 0.55)],
                     outline=(*STAR_COLOR, alpha), width=w)
    layer = layer.filter(ImageFilter.GaussianBlur(radius=1))
    img.alpha_composite(layer) if img.mode == 'RGBA' else img.paste(layer, (0, 0), layer)


def make_full_icon() -> Image.Image:
    bg = _radial_bg(SIZE).convert('RGBA')
    _add_field_stars(bg)
    _draw_orbit_ring(bg)
    _draw_central_star(bg, with_glow=True)
    return bg


def make_foreground() -> Image.Image:
    """Foreground per icona adattiva: senza background, dentro safe zone (66%)."""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    # Disegna lo stesso star + ring ma più contenuti per la safe zone
    _draw_orbit_ring(img)
    _draw_central_star(img, with_glow=True)
    return img


def make_background() -> Image.Image:
    bg = _radial_bg(SIZE).convert('RGBA')
    _add_field_stars(bg)
    return bg


if __name__ == '__main__':
    full = make_full_icon()
    full.save(OUT_DIR / 'app_icon.png')
    print(f'Wrote {OUT_DIR / "app_icon.png"}')

    fg = make_foreground()
    fg.save(OUT_DIR / 'app_icon_foreground.png')
    print(f'Wrote {OUT_DIR / "app_icon_foreground.png"}')

    bgi = make_background()
    bgi.save(OUT_DIR / 'app_icon_background.png')
    print(f'Wrote {OUT_DIR / "app_icon_background.png"}')
