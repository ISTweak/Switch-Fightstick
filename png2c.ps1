Param( $filename )
Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile($filename)
if ( $img.Width -ne 320 -or $img.Height -ne 120 ) {
	Write-Host "ERROR: Image must be 320px by 120px!"
	$img.Dispose()
	exit
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

echo "{} converted with original colormap and saved to image.c $filename"