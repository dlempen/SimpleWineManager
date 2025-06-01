from PIL import Image, ImageDraw, ImageFont, ImageColor
import os

def create_wine_icon():
    # Create a new image with a white background
    size = (1024, 1024)
    background_color = (217, 37, 80)  # A wine red color
    image = Image.new('RGB', size, background_color)
    draw = ImageDraw.Draw(image)
    
    # Add the wine emoji as text
    try:
        # Create a white circle for the background
        circle_size = 900
        circle_pos = ((size[0] - circle_size) // 2, (size[1] - circle_size) // 2)
        circle_end = (circle_pos[0] + circle_size, circle_pos[1] + circle_size)
        draw.ellipse([circle_pos, circle_end], fill='white')
        
        # Draw the emoji text in a dark color
        text = "🍷"
        # Use Apple Color Emoji font if available
        font = ImageFont.truetype('/System/Library/Fonts/Apple Color Emoji.ttc', 512)
        
        # Get text size and center it
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size[0] - text_width) // 2
        y = (size[1] - text_height) // 2
        
        # Draw the emoji
        draw.text((x, y), text, font=font)
        
        # Save the image
        icon_path = 'SimpleWineManager/SimpleWineManager/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
        os.makedirs(os.path.dirname(icon_path), exist_ok=True)
        image.save(icon_path, 'PNG')
        print(f"Icon saved to {icon_path}")
        
    except Exception as e:
        print(f"Error creating icon: {e}")

if __name__ == "__main__":
    create_wine_icon()
