#!/usr/bin/env python3
"""
Generate crisp, official Android mobile launcher icons for Tomorrow's You.
Outputs:
- assets/icons/icon_192x192.png (Standard launcher icon)
- assets/icons/icon_adaptive_background_432x432.png (Android adaptive background)
- assets/icons/icon_adaptive_foreground_432x432.png (Android adaptive foreground)
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "assets/icons"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Hi-res supersampling factor
SCALE = 4

def create_adaptive_background(size=432):
    s = size * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background radial gradient
    center = s // 2
    max_r = int(math.hypot(center, center))

    # Base background fill
    for r in range(max_r, 0, -SCALE * 2):
        t = r / max_r
        # Dark navy #070A14 at edge to #111B35 at center
        r_col = int(7 * t + 17 * (1.0 - t))
        g_col = int(10 * t + 27 * (1.0 - t))
        b_col = int(20 * t + 53 * (1.0 - t))
        draw.ellipse([center - r, center - r, center + r, center + r], fill=(r_col, g_col, b_col, 255))

    # 2. Subtle central temporal aura
    aura = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura)
    aura_draw.ellipse([center - 450, center - 450, center + 450, center + 450], fill=(24, 75, 110, 80))
    aura = aura.filter(ImageFilter.GaussianBlur(radius=60))
    img.alpha_composite(aura)

    # 3. Subtle concentric radar/chrono rings
    draw = ImageDraw.Draw(img)
    for radius, width, alpha in [(320 * SCALE, 2 * SCALE, 40), (240 * SCALE, 3 * SCALE, 60), (160 * SCALE, 2 * SCALE, 40)]:
        r_box = [center - radius // 2, center - radius // 2, center + radius // 2, center + radius // 2]
        draw.ellipse(r_box, outline=(50, 80, 120, alpha), width=width)

    # Downsample with high-quality Lanczos
    res = img.resize((size, size), Image.Resampling.LANCZOS)
    return res

def create_adaptive_foreground(size=432):
    s = size * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    center = s // 2

    # Glowing temporal ring
    # Arc radius fits comfortably inside 264x264 Android adaptive safe-zone
    # In 432px space, safe zone is central 264px (radius 132px).
    # Ring radius = 95px * SCALE = 380px radius in supersampled space
    ring_radius = int(95 * SCALE)
    ring_width = int(14 * SCALE)

    glow_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)

    # Cyan arc (Player: 45 to 225 degrees)
    glow_draw.arc([center - ring_radius, center - ring_radius, center + ring_radius, center + ring_radius],
                  start=45, end=225, fill=(84, 230, 234, 180), width=ring_width + int(12 * SCALE))

    # Violet arc (Echo: 225 to 405 degrees)
    glow_draw.arc([center - ring_radius, center - ring_radius, center + ring_radius, center + ring_radius],
                  start=225, end=405, fill=(167, 139, 250, 180), width=ring_width + int(12 * SCALE))

    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=16 * SCALE))
    img.alpha_composite(glow_layer)

    # Sharp arcs
    draw = ImageDraw.Draw(img)

    # Cyan arc
    draw.arc([center - ring_radius, center - ring_radius, center + ring_radius, center + ring_radius],
             start=48, end=222, fill=(84, 230, 234, 255), width=ring_width)

    # Violet arc
    # Create dashed echo resonance
    for angle_start in range(230, 395, 24):
        draw.arc([center - ring_radius, center - ring_radius, center + ring_radius, center + ring_radius],
                 start=angle_start, end=angle_start + 14, fill=(196, 181, 253, 255), width=ring_width)

    # Node dots at conjunctions
    dot_r = int(10 * SCALE)
    for angle_deg, color in [(45, (84, 230, 234, 255)), (225, (167, 139, 250, 255))]:
        rad = math.radians(angle_deg)
        nx = center + int(ring_radius * math.cos(rad))
        ny = center + int(ring_radius * math.sin(rad))
        draw.ellipse([nx - dot_r, ny - dot_r, nx + dot_r, ny + dot_r], fill=color)

    # Center Chrono Core: Glowing amber diamond
    core_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    core_draw = ImageDraw.Draw(core_layer)
    core_half = int(24 * SCALE)
    diamond = [
        (center, center - core_half),
        (center + core_half, center),
        (center, center + core_half),
        (center - core_half, center)
    ]
    core_draw.polygon(diamond, fill=(255, 190, 85, 220))
    core_layer = core_layer.filter(ImageFilter.GaussianBlur(radius=8 * SCALE))
    img.alpha_composite(core_layer)

    # Sharp diamond core
    draw = ImageDraw.Draw(img)
    draw.polygon(diamond, fill=(255, 190, 85, 255))

    inner_half = int(12 * SCALE)
    inner_diamond = [
        (center, center - inner_half),
        (center + inner_half, center),
        (center, center + inner_half),
        (center - inner_half, center)
    ]
    draw.polygon(inner_diamond, fill=(255, 251, 235, 255))

    res = img.resize((size, size), Image.Resampling.LANCZOS)
    return res

def create_standard_icon(bg_img, fg_img, size=192):
    # Compose 432x432 first
    composed = bg_img.copy()
    composed.alpha_composite(fg_img)

    # Resize to target
    res = composed.resize((size, size), Image.Resampling.LANCZOS)
    return res

def main():
    print("Generating Android icons...")
    bg = create_adaptive_background(432)
    bg.save(os.path.join(OUTPUT_DIR, "icon_adaptive_background_432x432.png"))
    print("Saved icon_adaptive_background_432x432.png")

    fg = create_adaptive_foreground(432)
    fg.save(os.path.join(OUTPUT_DIR, "icon_adaptive_foreground_432x432.png"))
    print("Saved icon_adaptive_foreground_432x432.png")

    std = create_standard_icon(bg, fg, 192)
    std.save(os.path.join(OUTPUT_DIR, "icon_192x192.png"))
    print("Saved icon_192x192.png")

    # Also save standard project icon
    std_512 = create_standard_icon(bg, fg, 512)
    std_512.save(os.path.join(OUTPUT_DIR, "icon_512x512.png"))
    print("Saved icon_512x512.png")

if __name__ == "__main__":
    main()

