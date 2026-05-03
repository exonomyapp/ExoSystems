import sys
import math
from PIL import Image, ImageFilter, ImageOps

def process_branding_v5(input_path, output_dir):
    ARABIC_GREEN = (0, 173, 67) # 00AD43
    
    img = Image.open(input_path).convert("RGBA")
    final_res = 2048
    
    # 1. Square Crop and Resize
    width, height = img.size
    size = min(width, height)
    left = (width - size) / 2
    top = (height - size) / 2
    right = (width + size) / 2
    bottom = (height + size) / 2
    img = img.crop((left, top, right, bottom))
    img = img.resize((final_res, final_res), Image.LANCZOS)
    
    # 2. Extract Alpha via Aggressive Distance + Hard Threshold
    # We want to remove anything that is "light" or "near-white".
    datas = img.getdata()
    new_data = []
    
    # Aggressive tolerance: anything within 120 distance of white is potentially background.
    # We use a steeper curve to push more to transparent.
    tolerance = 130 
    
    for item in datas:
        r, g, b, a = item
        # Distance from pure white
        dist = math.sqrt((255-r)**2 + (255-g)**2 + (255-b)**2)
        
        if dist < 40:
            # Absolute background
            new_data.append((r, g, b, 0))
        elif dist < tolerance:
            # Transition - push harder towards transparent
            # Use a cubic falloff for a sharper transition
            norm_dist = (dist - 40) / (tolerance - 40)
            alpha = int(pow(norm_dist, 1.5) * 255)
            new_data.append((r, g, b, alpha))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    # 3. Clean up the mask with a Median filter and a Contrast boost
    r, g, b, a = img.split()
    # Boost contrast of alpha to kill the "haze"
    a = a.point(lambda x: 0 if x < 50 else (255 if x > 200 else x))
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
    
    print(f"Branding assets processed (v5) at {final_res}px successfully.")

if __name__ == "__main__":
    src = sys.argv[1]
    dest = sys.argv[2]
    process_branding_v5(src, dest)
