import sys
import random
import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def biological_thin(input_path, output_path, num_blobs=40, blob_size_range=(40, 100)):
    # Load the image
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Separate channels
    r, g, b, a = img.split()
    
    # Create a mask for 'biological' removal
    # Start with a white mask (keep everything)
    mask = Image.new("L", (width, height), 255)
    draw = ImageDraw.Draw(mask)
    
    # The 'center' of the dandelion head
    center_x, center_y = width // 2, height // 2
    
    # Randomly remove clusters of seedlings
    for _ in range(num_blobs):
        # Random angle and distance from center
        angle = random.uniform(0, 2 * math.pi)
        dist = random.uniform(80, 350)
        x = center_x + dist * math.cos(angle)
        y = center_y + dist * math.sin(angle)
        
        # Random blob size
        size = random.randint(*blob_size_range)
        
        # Draw a black feathered blob on the mask
        draw.ellipse([x - size, y - size, x + size, y + size], fill=0)
    
    # Blur the mask to make the removals feel more organic
    mask = mask.filter(ImageFilter.GaussianBlur(radius=20))
    
    # Multiply original alpha by our 'sparsity' mask
    new_a = ImageChops.multiply(a, mask)
    
    # Merge back and save
    result = Image.merge("RGBA", (r, g, b, new_a))
    result.save(output_path, "PNG")
    print(f"Biologically thinned image saved to {output_path}")

def make_monochrome(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        r, g, b, a = item
        if a > 0:
            new_data.append((255, 255, 255, a))
        else:
            new_data.append(item)
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 biological_thin.py <thin|mono> <src> <dest>")
        sys.exit(1)
        
    action = sys.argv[1]
    src = sys.argv[2]
    dest = sys.argv[3]
    
    if action == "thin":
        biological_thin(src, dest)
    elif action == "mono":
        make_monochrome(src, dest)
