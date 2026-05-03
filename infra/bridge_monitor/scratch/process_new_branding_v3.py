import sys
from PIL import Image, ImageOps, ImageFilter, ImageChops

def process_branding_v3(input_path, output_dir):
    ARABIC_GREEN = (0, 173, 67) # 00AD43
    
    # Load high-res
    img = Image.open(input_path).convert("RGBA")
    original_width, original_height = img.size
    
    # 1. Create a Mask based on "Distance from White"
    # We want to remove anything that is very close to white.
    # To handle "white snow", we invert the image so white becomes black (0).
    # Then we can use the brightness of the inverted image as the alpha.
    
    # Convert to grayscale and invert
    gray = img.convert("L")
    inverted = ImageOps.invert(gray)
    
    # Now, the white background is 0 (black/transparent).
    # The dandelion (which was dark gray/tan) is now light.
    # The seeds (which were light) are now dark.
    
    # Wait, the seeds are white too! 
    # If I invert, white seeds become black (transparent). 
    # This is the "white snow" problem: the dandelion is almost the same color as the background.
    
    # NEW STRATEGY: 
    # The background is a CLEAN white. 
    # We use a very tight threshold on the RGB sum.
    datas = img.getdata()
    new_data = []
    for item in datas:
        r, g, b, a = item
        # If the pixel is very bright, it's likely background.
        # But we need to be careful not to kill the seeds.
        # Seeds in the original are slightly darker than the pure white background.
        
        # Calculate "Whiteness"
        whiteness = (r + g + b) / 3
        
        if whiteness > 248: # Very aggressive threshold for background
            new_data.append((r, g, b, 0))
        elif whiteness > 240:
            # Transition zone for smoother edges
            alpha = int((248 - whiteness) / (248 - 240) * 255)
            new_data.append((r, g, b, max(0, alpha)))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    # 2. Crop to square (Centered on the dandelion head)
    # The head is roughly in the center-left.
    # We'll calculate a square that includes the blowing seeds.
    width, height = img.size
    # Dandelion head is usually around 30% from the left
    left_offset = int(width * 0.1)
    right_offset = int(width * 0.9)
    top_offset = int(height * 0.1)
    bottom_offset = int(height * 0.9)
    
    # For now, just square crop center
    size = min(width, height)
    left = (width - size) / 2
    top = (height - size) / 2
    right = (width + size) / 2
    bottom = (height + size) / 2
    img = img.crop((left, top, right, bottom))
    
    # High-res resize
    final_res = 2048 # High res as requested
    img = img.resize((final_res, final_res), Image.LANCZOS)
    
    # 3. Clean up specs (Median filter on Alpha)
    r, g, b, a = img.split()
    a = a.filter(ImageFilter.MedianFilter(size=3))
    img = Image.merge("RGBA", (r, g, b, a))
    
    # SAVE COLOR VERSION
    img.save(f"{output_dir}/exotalk_pappus_color.png", "PNG")
    
    # 4. Create WHITE version
    white_img = Image.new("RGBA", (final_res, final_res), (255, 255, 255, 0))
    white_img.paste((255, 255, 255, 255), mask=a)
    white_img.save(f"{output_dir}/exotalk_pappus_realistic.png", "PNG")
    
    # 5. Create ARABIC GREEN version
    green_img = Image.new("RGBA", (final_res, final_res), (0, 0, 0, 0))
    green_img.paste((*ARABIC_GREEN, 255), mask=a)
    green_img.save(f"{output_dir}/exotalk_pappus_arabic_green.png", "PNG")
    
    print(f"Branding assets processed (v3) at {final_res}px successfully.")

if __name__ == "__main__":
    src = sys.argv[1]
    dest = sys.argv[2]
    process_branding_v3(src, dest)
