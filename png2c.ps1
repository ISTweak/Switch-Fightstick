Param( $filename )
Add-Type -AssemblyName System.Drawing

function Conv1bpp() {
	param ($img)
	
	$newImg = New-Object System.Drawing.Bitmap($img.Width, $img.Height, [System.Drawing.Imaging.PixelFormat]::Format1bppIndexed)
	$bmpDate = $newImg.LockBits((New-Object System.Drawing.Rectangle(0, 0, $newImg.Width, $newImg.Height)), [System.Drawing.Imaging.ImageLockMode]::WriteOnly, $newImg.PixelFormat)
	$errors = @((New-Object float[] ($bmpDate.Width + 1)), (New-Object float[] ($bmpDate.Width + 1)))
	$pixels = New-Object byte[] ($bmpDate.Stride * $bmpDate.Height)

	for ( $y = 0; $y -lt $bmpDate.Height; $y++ ) {
		for ( $x = 0; $x -lt $bmpDate.Width; $x++ ) {
			$err = $img.GetPixel($x, $y).GetBrightness() + $errors[0][$x]
			if ( 0.5 -le $err ) {
				$pos = [int](($x -shr 3) + ($bmpDate.Stride * $y))
				$pixels[$pos] = $pixels[$pos] -bor [byte](0x80 -shr ($x -band 0x7))
				$err -= 1.0
			}
			$errors[0][$x + 1] += $err * 7.0 / 16.0
			if ( $x -gt 0 ) {
				$errors[1][$x - 1] += $err * 3.0 / 16.0
			}
			$errors[1][$x] += $err * 5.0 / 16.0
			$errors[1][$x + 1] += $err * 1.0 / 16.0
		}
		$errors[0] = $errors[1]
		$errors[1] = New-Object float[] $errors[0].Length
	}

	$ptr = $bmpDate.Scan0
	[System.Runtime.InteropServices.Marshal]::Copy($pixels, 0, $ptr, $pixels.Length)
	$newImg.UnlockBits($bmpDate)
	
	return $newImg
}

$img = [System.Drawing.Image]::FromFile($filename)
if ( $img.Width -ne 320 -or $img.Height -ne 120 ) {
	Write-Host "ERROR: Image must be 320px by 120px!"
	$img.Dispose()
	exit
}

if ( $img.PixelFormat -ne "Format1bppIndexed" ) {
	$img = Conv1bpp $img
}

$data = New-Object System.Collections.ArrayList
for($i = 0; $i -lt $img.Height; $i++)
{
    for($j = 0; $j -lt $img.Width; $j++)
    {
        if ( $img.GetPixel($j, $i).R -eq 255 ) {
			[void]$data.Add(0)
		} else {
			[void]$data.Add(1)
		}
	}
}
$img.Dispose()

$txt = New-Object System.IO.StreamWriter("$PSScriptRoot\image.c", $false, [System.Text.Encoding]::GetEncoding("Shift_JIS"))
$txt.WriteLine("#include <stdint.h>")
$txt.WriteLine("#include <avr/pgmspace.h>")
$txt.WriteLine("")

$txt.Write("const uint8_t image_data[0x12c1] PROGMEM = {")
for($i = 0; $i -lt 4800; $i++)
{
	$val = 0
	for($j =0; $j -lt 9; $j++)
	{
		$val = $val -bor $data[($i * 8) + $j] -shl $j
	}
	$val = $val -band 255
	$txt.Write("0x" + $val.ToString("x") + ", ")
}
$txt.WriteLine("0x0};")
$txt.Close()

echo "$filename converted with original colormap and saved to image.c"