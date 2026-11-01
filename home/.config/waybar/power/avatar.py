#!/usr/bin/env python3
"""Genera el avatar redondo (con aro del color de acento) para el menú de energía.

Usa ~/.face si existe; si no, el logo de fastfetch. El aro toma el color de la
paleta actual (~/.cache/theme/palette.json), así cambia con el fondo.
Imprime la ruta del PNG generado, o nada si no hay imagen de origen.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

SIZE = 220          # px del PNG (se muestra a la mitad: nítido en pantallas HiDPI)
RING = 7            # grosor del aro
HOME = os.path.expanduser("~")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", HOME + "/.cache"), "theme")
SOURCES = (HOME + "/.face", HOME + "/.face.icon", HOME + "/.config/fastfetch/logos/milesmorales.png")


def accent():
    try:
        with open(os.path.join(CACHE, "palette.json")) as f:
            h = json.load(f)["pal"]["accent"].lstrip("#")
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    except (OSError, KeyError, ValueError):
        return (255, 255, 255, 255)


def main():
    src = next((p for p in SOURCES if os.path.isfile(p)), None)
    if not src:
        return
    color = accent()
    out = os.path.join(CACHE, "avatar-%02x%02x%02x.png" % color[:3])
    if os.path.isfile(out) and os.path.getmtime(out) >= os.path.getmtime(src):
        print(out)
        return

    im = Image.open(src).convert("RGBA")
    side = min(im.size)                       # recorte cuadrado centrado
    left, top = (im.width - side) // 2, (im.height - side) // 2
    inner = SIZE - 2 * RING
    im = im.crop((left, top, left + side, top + side)).resize((inner, inner), Image.LANCZOS)

    big = SIZE * 4                            # máscara a 4x para bordes suaves
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse((RING * 4, RING * 4, big - RING * 4, big - RING * 4), fill=255)
    mask = mask.resize((SIZE, SIZE), Image.LANCZOS)

    ring = Image.new("L", (big, big), 0)
    ImageDraw.Draw(ring).ellipse((0, 0, big - 1, big - 1), fill=255)
    ring = ring.resize((SIZE, SIZE), Image.LANCZOS)

    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(Image.new("RGBA", (SIZE, SIZE), color), (0, 0), ring)
    photo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    photo.paste(im, (RING, RING))
    canvas.paste(photo, (0, 0), mask)

    os.makedirs(CACHE, exist_ok=True)
    canvas.save(out)
    print(out)


if __name__ == "__main__":
    sys.exit(main())
