from PIL import Image

for name in ["patriot_truck_horizontal.png", "patriot_truck_vertical.png"]:
    im = Image.open(f"assets/images/{name}")
    print(f"{name} - Format: {im.format}, Size: {im.size}, Mode: {im.mode}")
