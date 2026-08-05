<#
Generates _data/photos.json by extracting EXIF Date Taken from JPG files
Place this script in the repository root and run it locally on Windows.
#>
Add-Type -AssemblyName System.Drawing

$fulls = Join-Path -Path $PSScriptRoot -ChildPath "images/fulls"
$thumbsRel = "/photography/images/thumbs/"
$fullsRel = "/photography/images/fulls/"

$items = Get-ChildItem -Path $fulls -Filter *.jpg -File -Recurse | ForEach-Object {
    $name = $_.Name
    $dateTaken = $null
    $prop = $null
    try {
        $img = [System.Drawing.Image]::FromFile($_.FullName)
        # EXIF tag 36867 = DateTimeOriginal, 306 = DateTime
        if ($img.PropertyIdList -contains 36867) { $prop = $img.GetPropertyItem(36867) } 
        elseif ($img.PropertyIdList -contains 306) { $prop = $img.GetPropertyItem(306) }
        if ($prop) {
            $raw = [System.Text.Encoding]::ASCII.GetString($prop.Value).Trim([char]0)
            # Convert EXIF date 'YYYY:MM:DD HH:MM:SS' to 'YYYY-MM-DD HH:MM:SS'
            $dateTaken = $raw -replace '^([0-9]{4}):([0-9]{2}):([0-9]{2})','$1-$2-$3'
        }
        $img.Dispose()
    } catch {
        $dateTaken = $null
    }

    if ([string]::IsNullOrWhiteSpace($dateTaken)) {
        # Fall back to file Date Modified (LastWriteTime) when EXIF Date Taken is unavailable
        $fileInfo = Get-Item $_.FullName
        $dateTaken = $fileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    }

    [PSCustomObject]@{
        name = $name
        date_taken = $dateTaken
        full_path = "$fullsRel$name"
        thumb_path = "$thumbsRel$name"
    }
}

$sorted = $items | Sort-Object @{Expression = { [datetime]$_.date_taken }; Descending = $true }, @{Expression = { $_.name }; Descending = $false }

$outDir = Join-Path -Path $PSScriptRoot -ChildPath "_data"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$outFile = Join-Path -Path $outDir -ChildPath "photos.json"
$sorted | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $outFile

Write-Host "Wrote $outFile (`$($sorted.Count) items)"
