# 生成 App 图标（1024x1024，深色渐变底 + 2x2 彩色圆角方块）
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File tools/gen-icon.ps1 <输出png路径>
param(
    [Parameter(Mandatory = $true)]
    [string]$OutPath
)

Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'

# 深色渐变背景
$rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 24, 24, 28),
    [System.Drawing.Color]::FromArgb(255, 48, 48, 58),
    45.0)
$g.FillRectangle($bg, $rect)

function New-RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# 2x2 方块（iOS 系统色）
$colors = @('#0A84FF', '#30D158', '#FF9F0A', '#BF5AF2')
$margin = 170
$gap = 60
$tile = ($size - 2 * $margin - $gap) / 2
$positions = @(
    @{ x = $margin;               y = $margin },
    @{ x = $margin + $tile + $gap; y = $margin },
    @{ x = $margin;               y = $margin + $tile + $gap },
    @{ x = $margin + $tile + $gap; y = $margin + $tile + $gap }
)

for ($i = 0; $i -lt 4; $i++) {
    $c = [System.Drawing.ColorTranslator]::FromHtml($colors[$i])
    $brush = New-Object System.Drawing.SolidBrush($c)
    $path = New-RoundRect $positions[$i].x $positions[$i].y $tile $tile 70
    $g.FillPath($brush, $path)
    $brush.Dispose()
    $path.Dispose()
}

$g.Dispose()

$dir = Split-Path -Parent $OutPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "Icon saved: $OutPath"
