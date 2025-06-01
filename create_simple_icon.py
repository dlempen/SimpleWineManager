from PIL import Image, ImageDraw
import os

def create_icon():
    # Create a new image with a wine red background
    size = (1024, 1024)
    background_color = (145, 23, 31)  # Wine red
    image = Image.new('RGB', size, background_color)
    draw = ImageDraw.Draw(image)
    
    # Create a white circle
    margin = 100
    circle_bbox = [margin, margin, size[0]-margin, size[1]-margin]
    draw.ellipse(circle_bbox, fill='white')
    
    # Create the wine glass shape
    stem_width = 80
    bowl_width = 400
    stem_height = 350
    total_height = 700
    
    # Calculate positions
    center_x = size[0] // 2
    bottom_y = 700
    
    # Draw the wine glass stem
    stem_points = [
        (center_x - stem_width//2, bottom_y),
        (center_x + stem_width//2, bottom_y),
        (center_x + stem_width//2, bottom_y - stem_height),
        (center_x - stem_width//2, bottom_y - stem_height)
    ]
    draw.polygon(stem_points, fill=background_color)
    
    # Draw the wine glass bowl
    bowl_top = bottom_y - stem_height - 200
    bowl_points = [
        (center_x - bowl_width//2, bottom_y - stem_height),
        (center_x + bowl_width//2, bottom_y - stem_height),
        (center_x + bowl_width//3, bowl_top),
        (center_x - bowl_width//3, bowl_top)
    ]
    draw.polygon(bowl_points, fill=background_color)
    
    # Save the image
    output_path = 'SimpleWineManager/SimpleWineManager/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    image.save(output_path, 'PNG')
    print(f"Icon saved to {output_path}")

if __name__ == "__main__":
    create_icon()
