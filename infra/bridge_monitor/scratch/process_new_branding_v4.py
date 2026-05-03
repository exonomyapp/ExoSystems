import sys
import math
from PIL import Image, ImageFilter

def process_branding_v4(input_path, output_dir):
    ARABIC_GREEN = (0, 173, 67) # 00AD43
    
    img = Image.open(input_path).convert("RGBA")
    final_res = 2048
    
    # 1. Square Crop and Resize FIRST to work on clean pixels
    width, height = img.size
    size = min(width, height)
    left = (width - size) / 2
    top = (height - size) / 2
    right = (width + size) / 2
    bottom = (height + size) / 2
    img = img.crop((left, top, right, bottom))
    img = img.resize((final_res, final_res), Image.LANCZOS)
    
    # 2. Extract Alpha via Color Distance
    # Tolerance for "white": if distance from (255,255,255) is small, it's background.
    datas = img.getdata()
    new_data = []
    
    # Tolerance: 60 seems like a safe bet for "mostly white" background
    tolerance = 60
    
    for item in datas:
        r, g, b, a = item
        # Distance from pure white
        dist = math.sqrt((255-r)**2 + (255-g)**2 + (255-b)**2)
        
        if dist < tolerance:
            # Background
            # Use a quadratic falloff for smoother edges
            alpha = int((dist / tolerance) ** 2 * 255)
            new_data.append((r, g, b, alpha))
        else:
            # Foreground
            new_data.append(item)
            
    img.putdata(new_data)
    
    # 3. Median Filter on Alpha to remove isolated speckles
    r, g, b, a = img.split()
    a = a.filter(ImageFilter.MedianFilter(size=5))
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
    
    print(f"Branding assets processed (v4) at {final_res}px successfully.")

if __name__ == "__main__":
    src = sys.argv[1]
    dest = sys.argv[2]
    process_branding_v4(src, dest)
