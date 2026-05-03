import sys
from PIL import Image, ImageOps, ImageChops

def process_branding(input_path, output_dir):
    # Colors
    ARABIC_GREEN = (0, 173, 67) # 00AD43
    
    img = Image.open(input_path).convert("RGBA")
    
    # 1. Remove white background to make transparent
    # We use a threshold approach since it's a photorealistic image on white
    datas = img.getdata()
    new_data = []
    for item in datas:
        r, g, b, a = item
        # If it's very white, make it transparent
        # Threshold: if r, g, b are all > 240
        if r > 240 and g > 240 and b > 240:
            new_data.append((255, 255, 255, 0))
        else:
            # Keep original color but maybe adjust alpha based on "whiteness" for smoother edges
            # For simplicity, we just keep it
            new_data.append(item)
    
    img.putdata(new_data)
    
    # 2. Crop to square
    width, height = img.size
    size = min(width, height)
    left = (width - size) / 2
    top = (height - size) / 2
    right = (width + size) / 2
    bottom = (height + size) / 2
    img = img.crop((left, top, right, bottom))
    img = img.resize((1024, 1024), Image.LANCZOS)
    
    # SAVE COLOR VERSION
    img.save(f"{output_dir}/exotalk_pappus_color.png", "PNG")
    
    # 3. Create WHITE version (Monochrome)
    white_img = Image.new("RGBA", (1024, 1024), (255, 255, 255, 0))
    datas = img.getdata()
    new_white_data = []
    for item in datas:
        r, g, b, a = item
        if a > 0:
            new_white_data.append((255, 255, 255, a))
        else:
            new_white_data.append((255, 255, 255, 0))
    white_img.putdata(new_white_data)
    white_img.save(f"{output_dir}/exotalk_pappus_realistic.png", "PNG")
    
    # 4. Create ARABIC GREEN version
    green_img = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    new_green_data = []
    for item in datas:
        r, g, b, a = item
        if a > 0:
            new_green_data.append((*ARABIC_GREEN, a))
        else:
            new_green_data.append((0, 0, 0, 0))
    green_img.putdata(new_green_data)
    green_img.save(f"{output_dir}/exotalk_pappus_arabic_green.png", "PNG")
    
    print("Branding assets processed successfully.")

if __name__ == "__main__":
    src = sys.argv[1]
    dest = sys.argv[2]
    process_branding(src, dest)
