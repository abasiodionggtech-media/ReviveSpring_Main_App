param(
  [Parameter(Mandatory = $true)]
  [string] $Source,

  [Parameter(Mandatory = $true)]
  [string] $ResRoot,

  [string] $IosIconRoot
)

Add-Type -AssemblyName System.Drawing

$sizes = @{
  'mipmap-mdpi' = 48
  'mipmap-hdpi' = 72
  'mipmap-xhdpi' = 96
  'mipmap-xxhdpi' = 144
  'mipmap-xxxhdpi' = 192
}

$iosSizes = @{
  'Icon-App-20x20@1x.png' = 20
  'Icon-App-20x20@2x.png' = 40
  'Icon-App-20x20@3x.png' = 60
  'Icon-App-29x29@1x.png' = 29
  'Icon-App-29x29@2x.png' = 58
  'Icon-App-29x29@3x.png' = 87
  'Icon-App-40x40@1x.png' = 40
  'Icon-App-40x40@2x.png' = 80
  'Icon-App-40x40@3x.png' = 120
  'Icon-App-60x60@2x.png' = 120
  'Icon-App-60x60@3x.png' = 180
  'Icon-App-76x76@1x.png' = 76
  'Icon-App-76x76@2x.png' = 152
  'Icon-App-83.5x83.5@2x.png' = 167
  'Icon-App-1024x1024@1x.png' = 1024
}

function Save-ResizedIcon {
  param(
    [System.Drawing.Image] $Image,
    [string] $Target,
    [int] $Size
  )

  $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

  try {
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.DrawImage($Image, 0, 0, $Size, $Size)
    $bitmap.Save($Target, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
}

$sourceImage = [System.Drawing.Image]::FromFile($Source)

try {
  foreach ($entry in $sizes.GetEnumerator()) {
    $target = Join-Path (Join-Path $ResRoot $entry.Key) 'ic_launcher.png'
    Save-ResizedIcon -Image $sourceImage -Target $target -Size $entry.Value
  }

  if ($IosIconRoot) {
    foreach ($entry in $iosSizes.GetEnumerator()) {
      $target = Join-Path $IosIconRoot $entry.Key
      Save-ResizedIcon -Image $sourceImage -Target $target -Size $entry.Value
    }
  }
} finally {
  $sourceImage.Dispose()
}
