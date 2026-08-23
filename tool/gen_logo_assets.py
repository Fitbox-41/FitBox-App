"""Builds every logo asset in the app from the one source vector.

    python tool/gen_logo_assets.py          # then: dart run flutter_launcher_icons

Run this instead of editing the PNGs by hand — the light-theme mark and the
launcher layers are derived from `assets/brand/logo.svg`, so hand-edits get
overwritten and the variants drift apart.

Three things this handles that a plain export does not:

**Debanding.** The supplied vector is an auto-trace of a raster: the silhouettes
are crisp, but the metallic and red gradients arrive as ~300 flat facets. The
artwork is rendered far larger than needed and its *interior* colour smoothed
without touching the alpha, so the banding goes but the edges stay exactly as
traced.

**A light-theme variant.** The new logo's "Fit Sports" half is light silver
(luminance 0.6–0.9), which all but disappears on the light theme's #F2F4F8
backdrop. That half is remapped to graphite for the light mark — the same split
the previous artwork used (charcoal on light, white on dark), applied to a
gradient rather than a flat colour. The red is left alone; it reads on both.

**A dark launcher icon.** For the same reason the icon sits on the app's own
near-black rather than white — a white icon background would hide the silver
exactly the way the light theme does.

Requires: pip install cairosvg pillow numpy
"""

import os

import cairosvg
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "brand", "logo.svg")
IMAGES = os.path.join(ROOT, "assets", "images")
LAUNCHER = os.path.join(ROOT, "launcher")
WEB = os.path.join(ROOT, "web")

# Render width before downsampling. Large enough that the 1024 px icon is a
# reduction rather than an enlargement.
SUPER = 4400

# The icon plate: FitBoxColors.bgTopDark, so the icon and the app's first frame
# are the same black.
ICON_BG = (18, 22, 26, 255)

# Fraction of the square canvas the wordmark spans.
MARK_FRAC = 0.96      # in-app marks — matches the previous assets exactly
ICON_FRAC = 0.90      # legacy / iOS icon
ADAPTIVE_FRAC = 0.80  # Android adaptive layers, see below
MASKABLE_FRAC = 0.70  # PWA maskable icons, whose safe zone is the middle 80%


def render():
    """The source at `SUPER` px, cropped to its ink."""
    tmp = os.path.join(LAUNCHER, "_render.png")
    os.makedirs(LAUNCHER, exist_ok=True)
    cairosvg.svg2png(url=SRC, write_to=tmp, output_width=SUPER)
    im = Image.open(tmp).convert("RGBA")
    im = im.crop(im.split()[3].getbbox())
    os.remove(tmp)
    return im


def deband(im, radius):
    """Blur the colour without touching the shape.

    Transparent pixels carry no meaningful colour, so blurring RGB directly
    would drag whatever sits under them into the edge. Blur the *premultiplied*
    colour and divide the blurred alpha back out — that floods colour outwards
    instead of inwards — then restore the original alpha unchanged, leaving the
    silhouette pixel-identical to the trace.
    """
    a = np.asarray(im.split()[3], dtype=np.float32) / 255.0
    rgb = np.asarray(im.convert("RGB"), dtype=np.float32) / 255.0

    def blur(plane):
        return np.asarray(
            Image.fromarray((np.clip(plane, 0, 1) * 255).astype(np.uint8))
            .filter(ImageFilter.GaussianBlur(radius)),
            dtype=np.float32,
        ) / 255.0

    premult = np.dstack([blur(rgb[..., i] * a) for i in range(3)])
    alpha_blur = blur(a)
    smoothed = np.where(
        alpha_blur[..., None] > 0.004,
        premult / np.maximum(alpha_blur[..., None], 1e-4),
        rgb,
    )
    return Image.fromarray(
        np.dstack([np.clip(smoothed, 0, 1) * 255, a * 255]).astype(np.uint8), "RGBA"
    )


def graphite(im, out_lo=0.13, out_hi=0.58, src_lo=0.58, src_hi=0.90):
    """Drop the silver half into graphite so it reads on a light backdrop.

    Only low-saturation pixels move, so the red keeps its own colour and its own
    shading. Luminance is *rescaled*, not flattened, so the metal still looks
    like lit metal rather than a grey cut-out.
    """
    arr = np.asarray(im, dtype=np.float32) / 255.0
    rgb, alpha = arr[..., :3], arr[..., 3]
    mx, mn = rgb.max(2), rgb.min(2)
    lum = (mx + mn) / 2
    sat = np.where(
        mx - mn < 1e-6,
        0.0,
        (mx - mn) / np.where(lum < 0.5, mx + mn + 1e-6, 2 - mx - mn + 1e-6),
    )

    target = out_lo + np.clip((lum - src_lo) / (src_hi - src_lo), 0, 1) * (out_hi - out_lo)
    # Feather the metal/red hand-over, or the anti-aliased pixels between them
    # form a visible seam.
    metalness = np.clip((0.30 - sat) / 0.12, 0, 1)
    scale = 1 + (target / np.maximum(lum, 1e-4) - 1) * metalness
    return Image.fromarray(
        np.dstack([np.clip(rgb * scale[..., None], 0, 1) * 255, alpha * 255]).astype(
            np.uint8
        ),
        "RGBA",
    )


def square(logo, size, width_frac, bg=None):
    """A square canvas with the wordmark centred — the shape every caller expects.

    The in-app marks keep the previous artwork's square canvas and 96% width on
    purpose: every existing `LogoBadge(width: …)` then renders at exactly the
    size it does today, so swapping the logo changes the artwork and not a
    single layout.
    """
    w = round(size * width_frac)
    h = round(w * logo.height / logo.width)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0) if bg is None else bg)
    canvas.alpha_composite(logo.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
    return canvas


def main():
    os.makedirs(LAUNCHER, exist_ok=True)
    art = deband(render(), radius=SUPER / 420)
    written = []

    def save(img, path, rgb=False):
        (img.convert("RGB") if rgb else img).save(path, optimize=True)
        written.append(path)

    # In-app marks, chosen by theme in `LogoBadge`.
    save(square(art, 600, MARK_FRAC), os.path.join(IMAGES, "logo_mark_dark.png"))
    save(square(graphite(art), 600, MARK_FRAC), os.path.join(IMAGES, "logo_mark.png"))

    # iOS icon and the Android legacy icon: opaque, on the app's black.
    save(square(art, 1024, ICON_FRAC, bg=ICON_BG),
         os.path.join(LAUNCHER, "ic_launcher.png"), rgb=True)

    # Android adaptive foreground. Two multipliers stack before this reaches a
    # home screen, and both bite:
    #
    #   * flutter_launcher_icons wraps the layer in a 16% inset, so only 0.68 of
    #     what's drawn here lands on the 108dp canvas — don't pre-shrink it as
    #     well, or the mark comes out half the size it should be;
    #   * the launcher then shows roughly the middle 72dp and may round it to a
    #     circle. A 2.5:1 wordmark reaches further into the corners than its
    #     width suggests: at width w its tips sit at 0.537w from the centre.
    #
    # 0.80 here lands the mark at ~0.54 of the canvas, so its tips fall ~4dp
    # inside the mask. 0.90 was tried first and the X clipped on a real phone.
    save(square(art, 1024, ADAPTIVE_FRAC),
         os.path.join(LAUNCHER, "ic_launcher_foreground.png"))

    # Android 13 themed icons. Supplying a silhouette is worth it because the
    # fallback is the system flattening the real icon into a grey blob.
    alpha = np.asarray(square(art, 1024, ADAPTIVE_FRAC).split()[3])
    save(
        Image.fromarray(
            np.dstack([np.full(alpha.shape, 255, np.uint8)] * 3 + [alpha]), "RGBA"
        ),
        os.path.join(LAUNCHER, "ic_launcher_monochrome.png"),
    )

    # Web/PWA. The app doesn't ship on the web, but these were branded with the
    # previous logo, and leaving one stale copy behind is how a logo change ends
    # up being done twice.
    save(square(art, 64, ICON_FRAC, bg=ICON_BG), os.path.join(WEB, "favicon.png"))
    for size in (192, 512):
        save(square(art, size, ICON_FRAC, bg=ICON_BG),
             os.path.join(WEB, "icons", f"Icon-{size}.png"), rgb=True)
        save(square(art, size, MASKABLE_FRAC, bg=ICON_BG),
             os.path.join(WEB, "icons", f"Icon-maskable-{size}.png"), rgb=True)

    for path in written:
        print(f"  {os.path.relpath(path, ROOT):46} "
              f"{Image.open(path).size[0]}px  {os.path.getsize(path) / 1024:.0f} KB")
    print("\nNow run:  dart run flutter_launcher_icons")


if __name__ == "__main__":
    main()
