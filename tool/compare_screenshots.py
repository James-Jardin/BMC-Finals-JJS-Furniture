"""Normalize PDF renders and pair them with real browser captures for review."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root = Path(__file__).resolve().parents[1]
output = root / "docs" / "comparisons"
output.mkdir(parents=True, exist_ok=True)
names = ["shop", "details", "cart", "dashboard", "account"]
results = []
for page, name in enumerate(names, 1):
    ref = Image.open(root / "docs" / "reference" / ("page-%s.png" % page)).convert("RGB")
    ref = ref.resize((414, 896), Image.Resampling.LANCZOS)
    app = Image.open(root / "docs" / "screenshots" / ("414x896-%s.png" % name)).convert("RGB")
    panel = Image.new("RGB", (844, 926), "#e5dfd6")
    draw = ImageDraw.Draw(panel)
    draw.text((12, 9), "PDF page %s: %s" % (page, name), fill="black")
    draw.text((440, 9), "Flutter Web, 414 x 896 (fixture catalog)", fill="black")
    panel.paste(ref, (0,30)); panel.paste(app,(430,30))
    panel.save(output / (name + ".png"))
    # Only compare flat background tokens. Photographic pixel similarity would
    # conflate source raster compression, font antialiasing and actual layout.
    reference_pixel = ref.getpixel((5,500))
    app_pixel = app.getpixel((5,500))
    results.append({"screen":name,"reference_background":reference_pixel,
                    "app_background":app_pixel})
(output / "palette-check.json").write_text(json.dumps(results,indent=2))
print("Created five direct comparison panels in docs/comparisons.")

