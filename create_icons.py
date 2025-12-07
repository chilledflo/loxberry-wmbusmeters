#!/usr/bin/env python3
"""
Create professional WMBusMeters icons with meter/gauge design
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size):
    """Create a WMBusMeters icon with meter gauge design"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    bg_color = (41, 128, 185)  # Professional blue
    meter_color = (255, 255, 255, 255)  # White
    accent_color = (231, 76, 60)  # Red accent
    shadow_color = (0, 0, 0, 50)  # Semi-transparent black
    
    # Margins
    margin = size // 10
    
    # Draw rounded rectangle background with shadow
    shadow_offset = size // 40
    draw.rounded_rectangle(
        [margin + shadow_offset, margin + shadow_offset, size - margin + shadow_offset, size - margin + shadow_offset],
        radius=size // 8,
        fill=shadow_color
    )
    
    # Draw main background
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 8,
        fill=bg_color
    )
    
    # Draw meter gauge
    center_x = size // 2
    center_y = size // 2 + size // 10
    radius = size // 3
    
    # Outer circle (meter rim)
    draw.ellipse(
        [center_x - radius, center_y - radius, center_x + radius, center_y + radius],
        outline=meter_color,
        width=max(2, size // 40)
    )
    
    # Draw gauge segments
    import math
    num_segments = 8
    for i in range(num_segments):
        angle = math.pi + (i * math.pi / (num_segments - 1))
        x1 = center_x + (radius - size // 20) * math.cos(angle)
        y1 = center_y + (radius - size // 20) * math.sin(angle)
        x2 = center_x + (radius - size // 10) * math.cos(angle)
        y2 = center_y + (radius - size // 10) * math.sin(angle)
        
        width = max(1, size // 80)
        draw.line([x1, y1, x2, y2], fill=meter_color, width=width)
    
    # Draw needle (pointing to middle-right)
    needle_angle = math.pi * 0.75  # 45 degrees from horizontal
    needle_length = radius - size // 15
    needle_x = center_x + needle_length * math.cos(needle_angle)
    needle_y = center_y + needle_length * math.sin(needle_angle)
    
    # Draw needle shadow
    draw.line(
        [center_x + 2, center_y + 2, needle_x + 2, needle_y + 2],
        fill=shadow_color,
        width=max(2, size // 50)
    )
    
    # Draw needle
    draw.line(
        [center_x, center_y, needle_x, needle_y],
        fill=accent_color,
        width=max(2, size // 50)
    )
    
    # Draw center dot
    dot_radius = size // 20
    draw.ellipse(
        [center_x - dot_radius, center_y - dot_radius, 
         center_x + dot_radius, center_y + dot_radius],
        fill=accent_color,
        outline=meter_color,
        width=max(1, size // 100)
    )
    
    # Draw "WMBus" text at top if icon is large enough
    if size >= 128:
        try:
            font_size = size // 8
            # Use default font
            from PIL import ImageFont
            try:
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            except:
                font = ImageFont.load_default()
            
            text = "WMBus"
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            text_x = (size - text_width) // 2
            text_y = margin + size // 15
            
            # Draw text shadow
            draw.text((text_x + 1, text_y + 1), text, font=font, fill=shadow_color)
            # Draw text
            draw.text((text_x, text_y), text, font=font, fill=meter_color)
        except:
            pass
    
    # Draw radio waves (wireless symbol) in corner
    if size >= 64:
        wave_x = size - margin - size // 8
        wave_y = margin + size // 8
        wave_size = size // 12
        
        for i in range(3):
            r = wave_size * (i + 1) // 2
            draw.arc(
                [wave_x - r, wave_y - r, wave_x + r, wave_y + r],
                start=200, end=340,
                fill=meter_color,
                width=max(1, size // 100)
            )
    
    return img

# Create all required sizes
sizes = [64, 128, 256, 512]
script_dir = os.path.dirname(os.path.abspath(__file__))
icons_dir = os.path.join(script_dir, 'icons')

print("Creating WMBusMeters icons...")
for size in sizes:
    icon = create_icon(size)
    output_path = os.path.join(icons_dir, f'icon_{size}.png')
    icon.save(output_path, 'PNG')
    print(f"Created {output_path}")

print("Done! All icons created successfully.")
