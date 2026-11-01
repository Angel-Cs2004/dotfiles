#!/usr/bin/env python3
"""
Paleta estética a partir del fondo de pantalla.

matugen elige el color de acento de la imagen; de él solo se toma el TONO (hue)
y una intensidad limitada. El resto se construye en OKLCH (espacio perceptual)
con niveles de luz fijos, así cualquier fondo da colores igual de equilibrados:

  - imagen muy saturada  -> intensidad con techo (no chilla)
  - imagen apagada       -> intensidad con piso (no queda sosa)
  - imagen casi gris     -> tema monocromo con un leve tinte
  - amarillos/verdes     -> un poco más de luz (en oscuro se ven turbios)

Uso: palette.py IMAGEN  -> imprime JSON para `matugen --import-json`
"""
import json
import math
import subprocess
import sys

# ---- Ajustes de estilo (aquí se afina el gusto) ----------------------------
CHROMA_MAX = 0.50     # techo de intensidad del acento
CHROMA_MIN = 0.06     # piso de intensidad (si la imagen tiene color)
CHROMA_SCALE = 0.9    # cuánto de la intensidad original se conserva
GRAY_LIMIT = 0.035    # por debajo de esto la imagen se considera gris
MONO_CHROMA = 0.015   # intensidad del tinte en modo monocromo
HUE2_SHIFT = 35       # grados hacia el segundo color (análogo, combina)
FALLBACK = "#c41047"  # si no se puede leer la imagen: tu carmesí original


# ---- Conversión sRGB <-> OKLCH ---------------------------------------------
def _to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def hex_to_oklch(h):
    r, g, b = (_to_lin(int(h[i:i + 2], 16) / 255) for i in (1, 3, 5))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360


def oklch_to_rgb(L, C, H):
    """Devuelve (r,g,b) 0-255; reduce la intensidad si el color no cabe en sRGB."""
    while True:
        a = C * math.cos(math.radians(H))
        b = C * math.sin(math.radians(H))
        l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
        m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
        s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
        rgb = (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
               -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
               -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
        if all(-1e-4 <= x <= 1 + 1e-4 for x in rgb) or C < 1e-3:
            return tuple(round(max(0, min(1, _to_srgb(x))) * 255) for x in rgb)
        C *= 0.95


def luminance(rgb):
    return 0.2126 * _to_lin(rgb[0] / 255) + 0.7152 * _to_lin(rgb[1] / 255) + 0.0722 * _to_lin(rgb[2] / 255)


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# ---- Color base de la imagen ------------------------------------------------
def source_color(image):
    try:
        out = subprocess.run(
            ["matugen", "image", image, "-m", "dark", "--prefer", "saturation",
             "--fallback-color", FALLBACK, "--dry-run", "-j", "hex"],
            capture_output=True, text=True, timeout=60).stdout
        return json.loads(out)["colors"]["source_color"]["default"]["color"]
    except Exception:
        return FALLBACK


def colorful_fraction(image):
    """Fracción de píxeles con color real (no gris). None si no se puede medir."""
    try:
        from PIL import Image
        im = Image.open(image).convert("RGB")
        im.thumbnail((128, 128))
        px = list(im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata())
        n = sum(1 for r, g, b in px if hex_to_oklch("#%02x%02x%02x" % (r, g, b))[1] > 0.05)
        return n / len(px)
    except Exception:
        return None


def build(image):
    src = source_color(image)
    _, src_c, hue = hex_to_oklch(src)

    frac = colorful_fraction(image)
    # Gris si el color base es apagado o si casi ningún píxel tiene color
    # (matugen devuelve el color de respaldo cuando no encuentra ninguno)
    mono = src_c < GRAY_LIMIT or (frac is not None and frac < 0.002)
    if mono and src.lower() == FALLBACK:
        hue = 260  # sin color en la imagen: gris ligeramente frío, neutro
    c = MONO_CHROMA if mono else max(min(src_c, CHROMA_MIN), min(CHROMA_MAX, src_c * CHROMA_SCALE))
    # Amarillos y verdes amarillentos se ven turbios en tonos medios: más luz
    lift = 0.06 if (not mono and 70 <= hue <= 140) else 0.0
    hue2 = (hue + HUE2_SHIFT) % 360

    def col(L, C, H=hue):
        return oklch_to_rgb(min(0.97, L), C, H)

    dark_text = col(0.20, min(c, 0.04))
    white = (255, 255, 255)

    def text_on(bg):
        return white if contrast(white, bg) >= contrast(dark_text, bg) else dark_text

    p = {
        # Acentos
        "accent":       col(0.74 + lift, c),            # texto destacado, workspace activo
        "border":       col(0.62 + lift, c * 0.85),     # bordes de módulos / notificaciones
        "accent2":      col(0.72 + lift, c * 0.85, hue2),
        "grad_a":       col(0.62 + lift, c * 0.9),      # degradado de bordes de ventana
        "grad_b":       col(0.50 + lift, c * 0.8, hue2),
        # Fondos (casi neutros, solo un toque del tono)
        "bg":           col(0.17, min(c, 0.018)),
        "bg2":          col(0.21, min(c, 0.022)),
        "bg3":          col(0.27, min(c, 0.028)),
        # Texto
        "fg":           col(0.94, min(c, 0.012)),
        "fg_dim":       col(0.80, min(c, 0.025)),
        "outline":      col(0.50, min(c, 0.035)),
        "selection":    col(0.40, c * 0.6),
        # Prompt (izquierda)
        "p10k_user":    col(0.56 + lift, c * 0.9),
        "p10k_dir":     col(0.72 + lift, c * 0.8),
        "p10k_vcs":     col(0.72 + lift, c * 0.75, hue2),
    }
    # Prompt (derecha): degradado oscuro -> claro
    for i, L in enumerate((0.48, 0.55, 0.62, 0.69, 0.76, 0.83), 1):
        p[f"r{i}"] = col(L + lift / 2, c * 0.8)

    out = {}
    for k, rgb in list(p.items()):
        h = "#%02x%02x%02x" % rgb
        out[k] = h
        out[k + "_s"] = h[1:]
        out[k + "_rgb"] = "%d, %d, %d" % rgb
        if k.startswith(("p10k_", "r")):
            t = text_on(rgb)
            out[k + "_fg"] = "#%02x%02x%02x" % t
    out["source"] = src
    out["mode"] = "mono" if mono else "color"
    return {"pal": out}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Uso: palette.py IMAGEN")
    print(json.dumps(build(sys.argv[1]), indent=1))
