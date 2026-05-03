import sys
from PIL import Image, ImageOps, ImageFilter

def process_branding_v2(input_path, output_dir):
    ARABIC_GREEN = (0, 173, 67) # 00AD43
    
    img = Image.open(input_path).convert("RGBA")
    
    # 1. Extract Alpha Channel from "Whiteness"
    # The background is off-white/gray-white.
    # We'll use a mask where we identify the background.
    
    # Create a grayscale version to identify brightness
    gray = img.convert("L")
    
    # We want to keep anything that is NOT the background.
    # The background is the brightest part.
    # However, the dandelion seeds are also bright.
    
    # Better approach: The background is around (240, 240, 240) to (255, 255, 255).
    # We'll use a simple threshold but with a bit of a margin.
    
    datas = img.getdata()
    new_data = []
    for item in datas:
        r, g, b, a = item
        # Calculate how close to white it is
        # If r,g,b are all very high, it's likely background
        if r > 235 and g > 235 and b > 235:
            # It's background. Make it transparent.
            new_data.append((r, g, b, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    # Smooth the alpha channel slightly to remove noise
    alpha = img.split()[-1]
    alpha = alpha.filter(ImageFilter.MedianFilter(size=3))
    r, g, b, _ = img.split()
    img = Image.merge("RGBA", (r, g, b, alpha))
    
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
    
    # 3. Create WHITE version
    white_img = Image.new("RGBA", (1024, 1024), (255, 255, 255, 0))
    # We use the alpha from the color image
    white_img.paste((255, 255, 255, 255), mask=img.split()[-1])
    white_img.save(f"{output_dir}/exotalk_pappus_realistic.png", "PNG")
    
    # 4. Create ARABIC GREEN version
    green_img = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    green_img.paste((*ARABIC_GREEN, 255), mask=img.split()[-1])
    green_img.save(f"{output_dir}/exotalk_pappus_arabic_green.png", "PNG")
    
    print("Branding assets processed (v2) successfully.")

if __name__ == "__main__":
    src = sys.argv[1]
    dest = sys.argv[2]
    process_branding_v2(src, dest)
