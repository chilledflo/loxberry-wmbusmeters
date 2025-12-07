# PowerShell script to create WMBusMeters icons
# Creates PNG icons from SVG using built-in Windows capabilities

param(
    [string]$SvgPath = "icon_master.svg",
    [string]$OutputDir = "icons"
)

Write-Host "Creating WMBusMeters icons..." -ForegroundColor Green

# Check if Inkscape is available (common SVG to PNG converter)
$inkscape = Get-Command inkscape -ErrorAction SilentlyContinue

if ($inkscape) {
    Write-Host "Using Inkscape for conversion..." -ForegroundColor Cyan
    
    $sizes = @(64, 128, 256, 512)
    foreach ($size in $sizes) {
        $output = Join-Path $OutputDir "icon_$size.png"
        & inkscape -w $size -h $size $SvgPath -o $output
        Write-Host "Created icon_$size.png" -ForegroundColor Green
    }
} else {
    Write-Host "Inkscape not found. Attempting alternative method..." -ForegroundColor Yellow
    
    # Try using Windows built-in capabilities
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    
    # Create icons with GDI+
    $sizes = @(64, 128, 256, 512)
    
    foreach ($size in $sizes) {
        Write-Host "Creating ${size}x${size} icon..." -ForegroundColor Cyan
        
        # Create bitmap
        $bitmap = New-Object System.Drawing.Bitmap($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Colors
        $blue = [System.Drawing.Color]::FromArgb(41, 128, 185)
        $white = [System.Drawing.Color]::White
        $red = [System.Drawing.Color]::FromArgb(231, 76, 60)
        
        # Draw rounded background
        $margin = [int]($size / 10)
        $rectSize = $size - (2 * $margin)
        $radius = [int]($size / 8)
        
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $rect = New-Object System.Drawing.Rectangle($margin, $margin, $rectSize, $rectSize)
        
        # Create rounded rectangle path
        $path.AddArc($rect.X, $rect.Y, $radius * 2, $radius * 2, 180, 90)
        $path.AddArc($rect.Right - $radius * 2, $rect.Y, $radius * 2, $radius * 2, 270, 90)
        $path.AddArc($rect.Right - $radius * 2, $rect.Bottom - $radius * 2, $radius * 2, $radius * 2, 0, 90)
        $path.AddArc($rect.X, $rect.Bottom - $radius * 2, $radius * 2, $radius * 2, 90, 90)
        $path.CloseFigure()
        
        $brush = New-Object System.Drawing.SolidBrush($blue)
        $graphics.FillPath($brush, $path)
        
        # Draw meter gauge
        $centerX = $size / 2
        $centerY = $size / 2 + $size / 10
        $radius = $size / 3
        
        $pen = New-Object System.Drawing.Pen($white, [Math]::Max(2, $size / 40))
        $graphics.DrawEllipse($pen, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)
        
        # Draw gauge marks
        $markPen = New-Object System.Drawing.Pen($white, [Math]::Max(1, $size / 80))
        for ($i = 0; $i -lt 7; $i++) {
            $angle = [Math]::PI + ($i * [Math]::PI / 6)
            $x1 = $centerX + ($radius - $size / 20) * [Math]::Cos($angle)
            $y1 = $centerY + ($radius - $size / 20) * [Math]::Sin($angle)
            $x2 = $centerX + ($radius - $size / 10) * [Math]::Cos($angle)
            $y2 = $centerY + ($radius - $size / 10) * [Math]::Sin($angle)
            $graphics.DrawLine($markPen, $x1, $y1, $x2, $y2)
        }
        
        # Draw needle
        $needleAngle = [Math]::PI * 0.75
        $needleLength = $radius - $size / 15
        $needleX = $centerX + $needleLength * [Math]::Cos($needleAngle)
        $needleY = $centerY + $needleLength * [Math]::Sin($needleAngle)
        
        $needlePen = New-Object System.Drawing.Pen($red, [Math]::Max(2, $size / 50))
        $needlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $needlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $graphics.DrawLine($needlePen, $centerX, $centerY, $needleX, $needleY)
        
        # Draw center dot
        $dotRadius = $size / 20
        $redBrush = New-Object System.Drawing.SolidBrush($red)
        $graphics.FillEllipse($redBrush, $centerX - $dotRadius, $centerY - $dotRadius, $dotRadius * 2, $dotRadius * 2)
        
        # Draw white outline on dot
        $dotPen = New-Object System.Drawing.Pen($white, [Math]::Max(1, $size / 100))
        $graphics.DrawEllipse($dotPen, $centerX - $dotRadius, $centerY - $dotRadius, $dotRadius * 2, $dotRadius * 2)
        
        # Draw text if large enough
        if ($size -ge 128) {
            $font = New-Object System.Drawing.Font("Arial", [int]($size / 8), [System.Drawing.FontStyle]::Bold)
            $textBrush = New-Object System.Drawing.SolidBrush($white)
            $text = "WMBus"
            $textSize = $graphics.MeasureString($text, $font)
            $textX = ($size - $textSize.Width) / 2
            $textY = $margin + $size / 12
            $graphics.DrawString($text, $font, $textBrush, $textX, $textY)
        }
        
        # Add small "Meters" text at bottom for larger icons
        if ($size -ge 256) {
            $font2 = New-Object System.Drawing.Font("Arial", [int]($size / 16), [System.Drawing.FontStyle]::Regular)
            $textBrush2 = New-Object System.Drawing.SolidBrush($white)
            $text2 = "METERS"
            $textSize2 = $graphics.MeasureString($text2, $font2)
            $textX2 = ($size - $textSize2.Width) / 2
            $textY2 = $size - $margin - $size / 8
            $graphics.DrawString($text2, $font2, $textBrush2, $textX2, $textY2)
        }
        
        # Save
        $outputPath = Join-Path $OutputDir "icon_$size.png"
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Created $outputPath" -ForegroundColor Green
        
        # Cleanup
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

Write-Host "`nAll icons created successfully!" -ForegroundColor Green
