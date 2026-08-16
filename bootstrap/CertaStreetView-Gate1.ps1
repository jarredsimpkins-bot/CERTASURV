[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][double]$Latitude,
  [Parameter(Mandatory=$true)][double]$Longitude,
  [double]$Fov = 80,
  [int]$RenderMs = 8000
)

$ErrorActionPreference='Stop'
if($Latitude -lt -90 -or $Latitude -gt 90){ throw 'Latitude out of range.' }
if($Longitude -lt -180 -or $Longitude -gt 180){ throw 'Longitude out of range.' }

$edgeCandidates=@(
  "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
)
$edge=$edgeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if(-not $edge){ throw 'Microsoft Edge executable not found.' }

$root='C:\Certa4010\StreetViewGate1'
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$out=Join-Path $root $stamp
$imgDir=Join-Path $out 'frames'
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null

$headings=@()
for($h=0.0; $h -lt 360.0; $h += 22.5){ $headings += $h }
$pitches=@(-30,0,30)
$rows=@()

Add-Type -AssemblyName System.Drawing

function Measure-Image([string]$Path){
  $bmp=[System.Drawing.Bitmap]::FromFile($Path)
  try {
    $sum=0.0; $sum2=0.0; $count=0
    $stepX=[Math]::Max(1,[int]($bmp.Width/80))
    $stepY=[Math]::Max(1,[int]($bmp.Height/45))
    for($y=0;$y -lt $bmp.Height;$y+=$stepY){
      for($x=0;$x -lt $bmp.Width;$x+=$stepX){
        $c=$bmp.GetPixel($x,$y)
        $v=0.2126*$c.R+0.7152*$c.G+0.0722*$c.B
        $sum += $v; $sum2 += $v*$v; $count++
      }
    }
    if($count -eq 0){ return [pscustomobject]@{Mean=0;Std=0;Pass=$false} }
    $mean=$sum/$count
    $var=[Math]::Max(0,($sum2/$count)-($mean*$mean))
    $std=[Math]::Sqrt($var)
    $pass=($mean -gt 12 -and $mean -lt 246 -and $std -gt 8)
    [pscustomobject]@{Mean=[Math]::Round($mean,2);Std=[Math]::Round($std,2);Pass=$pass}
  }
  finally { $bmp.Dispose() }
}

$idx=0
foreach($pitch in $pitches){
  foreach($heading in $headings){
    $idx++
    $hText=('{0:0.0}' -f $heading)
    $file=Join-Path $imgDir ("SV_{0:D2}_H{1}_P{2}.png" -f $idx,($hText -replace '\.','p'),$pitch)
    $latText=$Latitude.ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $lonText=$Longitude.ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)
    $url="https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latText%2C$lonText&heading=$hText&pitch=$pitch&fov=$Fov"
    $args=@(
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--window-size=1280,720',
      "--virtual-time-budget=$RenderMs",
      "--screenshot=$file",
      $url
    )
    & $edge @args | Out-Null
    $ok=Test-Path -LiteralPath $file
    if($ok){
      $m=Measure-Image $file
      $rows += [pscustomobject]@{Index=$idx;Heading=$heading;Pitch=$pitch;File=[IO.Path]::GetFileName($file);Mean=$m.Mean;Std=$m.Std;Pass=$m.Pass;Url=$url}
    } else {
      $rows += [pscustomobject]@{Index=$idx;Heading=$heading;Pitch=$pitch;File=[IO.Path]::GetFileName($file);Mean=0;Std=0;Pass=$false;Url=$url}
    }
  }
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $out 'FRAME_QC.csv')

$thumbW=320; $thumbH=180; $labelH=28; $cols=4
$rowsCount=[Math]::Ceiling($rows.Count/$cols)
$sheetW=$cols*$thumbW
$sheetH=$rowsCount*($thumbH+$labelH)
$sheet=New-Object System.Drawing.Bitmap $sheetW,$sheetH
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::Black)
$font=New-Object System.Drawing.Font('Segoe UI',9)
$white=[System.Drawing.Brushes]::White
$bad=[System.Drawing.Brushes]::OrangeRed
try {
  for($i=0;$i -lt $rows.Count;$i++){
    $r=$rows[$i]
    $col=$i % $cols
    $row=[Math]::Floor($i/$cols)
    $x=$col*$thumbW; $y=$row*($thumbH+$labelH)
    $path=Join-Path $imgDir $r.File
    if(Test-Path -LiteralPath $path){
      $src=[System.Drawing.Image]::FromFile($path)
      try { $g.DrawImage($src,$x,$y,$thumbW,$thumbH) } finally { $src.Dispose() }
    }
    $brush=if($r.Pass){$white}else{$bad}
    $label=("H {0:0.0}  P {1:+0;-0;0}  mean {2} std {3}  {4}" -f $r.Heading,$r.Pitch,$r.Mean,$r.Std,$(if($r.Pass){'PASS'}else{'REVIEW'}))
    $g.DrawString($label,$font,$brush,$x+4,$y+$thumbH+5)
  }
  $sheetPath=Join-Path $out 'REVIEW_CONTACT_SHEET.jpg'
  $sheet.Save($sheetPath,[System.Drawing.Imaging.ImageFormat]::Jpeg)
}
finally {
  $font.Dispose(); $g.Dispose(); $sheet.Dispose()
}

$good=@($rows | Where-Object Pass).Count
$htmlRows=$rows | ForEach-Object {
  $class=if($_.Pass){'ok'}else{'bad'}
  "<tr class='$class'><td>$($_.Index)</td><td>$($_.Heading)</td><td>$($_.Pitch)</td><td>$($_.Mean)</td><td>$($_.Std)</td><td>$($_.Pass)</td><td><a href='frames/$($_.File)'>$($_.File)</a></td></tr>"
}
$html=@"
<!doctype html><meta charset='utf-8'><title>CertaSurv Street View Gate 1</title>
<style>body{font-family:Segoe UI,Arial;margin:24px;background:#111;color:#eee}table{border-collapse:collapse}td,th{border:1px solid #555;padding:5px 8px}.bad{background:#4b1717}.ok{background:#17351f}a{color:#8dc7ff}img{max-width:100%}</style>
<h1>CertaSurv Street View Gate 1</h1>
<p>Viewpoint: $Latitude, $Longitude | Frames: $($rows.Count) | QC-pass: $good</p>
<p><strong>STOP GATE:</strong> Review this contact sheet before any 3-station or corridor run.</p>
<img src='REVIEW_CONTACT_SHEET.jpg'>
<table><tr><th>#</th><th>Heading</th><th>Pitch</th><th>Mean</th><th>Std</th><th>QC</th><th>Frame</th></tr>$($htmlRows -join "`n")</table>
"@
$html | Set-Content -LiteralPath (Join-Path $out 'REVIEW.html') -Encoding UTF8

$manifest=[ordered]@{
  timestamp=(Get-Date).ToString('o')
  mode='GATE1_ONE_VIEWER_STATION'
  latitude=$Latitude
  longitude=$Longitude
  headings=$headings
  pitches=$pitches
  fov=$Fov
  frame_count=$rows.Count
  qc_pass=$good
  edge=$edge
  output=$out
  next_gate='HUMAN_REVIEW_REQUIRED'
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'manifest.json') -Encoding UTF8

Start-Process -FilePath (Join-Path $out 'REVIEW_CONTACT_SHEET.jpg')
Start-Process -FilePath (Join-Path $out 'REVIEW.html')
Write-Output "CERTA_STREETVIEW_GATE1_DONE $out frames=$($rows.Count) pass=$good"
