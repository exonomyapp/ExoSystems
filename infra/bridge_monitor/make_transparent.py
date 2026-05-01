import sys
from PIL import Image

def make_transparent(input_path, output_path, fuzz_percent=12):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    newData = []
    for item in datas:
        # Check if pixel is close to white
        if item[0] > 255 * (1 - fuzz_percent/100) and item[1] > 255 * (1 - fuzz_percent/100) and item[2] > 255 * (1 - fuzz_percent/100):
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
    img.putdata(newData)
    img.save(output_path, "PNG")
    print(f"Saved transparent: {output_path}")

if __name__ == "__main__":
    make_transparent(sys.argv[1], sys.argv[2])
