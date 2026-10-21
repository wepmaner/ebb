"""Renders the app icon (same shapes as icon.svg) to a 1024x1024 PNG with Pillow.

Usage: python -I design/render-icon.py <out.png>
"""
import math
import sys

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersampling
W = SIZE * SS


def hex_rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (1, 3, 5))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def background():
    img = Image.new("RGB", (W, W))
    px = img.load()
    c0, c1, c2 = hex_rgb("#0A1B22"), hex_rgb("#0E2630"), hex_rgb("#182A2C")
    for y in range(W):
        t = y / (W - 1)
        col = lerp(c0, c1, t / 0.55) if t < 0.55 else lerp(c1, c2, (t - 0.55) / 0.45)
        for x in range(W):
            px[x, y] = col
    # soft glow top-left: per-pixel radial falloff at low resolution, then smooth upscale
    small = 256
    glow = Image.new("RGBA", (small, small), (0, 0, 0, 0))
    gp = glow.load()
    g = hex_rgb("#174650")
    cx, cy, r = small * 0.25, small * 0.15, small * 0.6
    for y in range(small):
        for x in range(small):
            d = math.hypot(x - cx, y - cy) / r
            a = max(0.0, 1.0 - d) ** 2
            gp[x, y] = g + (int(230 * a),)
    glow = glow.resize((W, W), Image.BICUBIC)
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    return img


def wave(y_base, amp, color, alpha):
    """Band whose top edge is a cosine wave: crest at x=0 and x=W, trough at centre."""
    pts = []
    for x in range(0, W + 1, SS):
        t = x / W
        y = y_base - amp * math.cos(2 * math.pi * t) * -1  # trough at centre
        pts.append((x, y))
    pts += [(W, W), (0, W)]
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(pts, fill=hex_rgb(color) + (int(255 * alpha),))
    return layer


def main(out):
    img = background()
    for y_base, amp, color, alpha in [
        (0.575, 0.055, "#4FC3B5", 0.95),
        (0.685, 0.05, "#8AE3D7", 0.9),
        (0.81, 0.035, "#E3C488", 0.9),
    ]:
        img = Image.alpha_composite(img, wave(y_base * W, amp * W, color, alpha))
    img.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS).save(out, "PNG")
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1])
