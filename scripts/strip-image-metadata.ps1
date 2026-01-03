param(
    [string]$Path = "images/hamster",
    [switch]$Recurse,
    [int]$JpegQuality = 92
)

# Re-encode images to strip metadata. This overwrites the originals.
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Path not found: $Path"
}

$extensions = @(".jpg", ".jpeg", ".png")
$items = if ($Recurse) {
    Get-ChildItem -LiteralPath $Path -Recurse -File
} else {
    Get-ChildItem -LiteralPath $Path -File
}

foreach ($item in $items) {
    if ($extensions -notcontains $item.Extension.ToLowerInvariant()) {
        continue
    }

    $tempPath = "$($item.FullName).tmp"
    $img = $null
    $bmp = $null
    $gfx = $null

    try {
        $img = [System.Drawing.Image]::FromFile($item.FullName)
        $bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.DrawImage($img, 0, 0, $img.Width, $img.Height)

        if ($item.Extension.ToLowerInvariant() -in @(".jpg", ".jpeg")) {
            $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                Where-Object { $_.MimeType -eq "image/jpeg" }
            $qualityParam = New-Object System.Drawing.Imaging.EncoderParameter(
                [System.Drawing.Imaging.Encoder]::Quality,
                [long]$JpegQuality
            )
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = $qualityParam
            $bmp.Save($tempPath, $encoder, $encoderParams)
        } else {
            $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
    }
    finally {
        if ($gfx) { $gfx.Dispose() }
        if ($bmp) { $bmp.Dispose() }
        if ($img) { $img.Dispose() }
    }

    Move-Item -LiteralPath $tempPath -Destination $item.FullName -Force
}

Write-Host "Stripped metadata from images under: $Path"
