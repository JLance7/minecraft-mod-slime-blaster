param([string]$Output)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$manifest = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'SlimeGun_BP/manifest.json') | ConvertFrom-Json
$version = $manifest.header.version -join '.'
$bundleName = "Slime-Gun-Bedrock-$version.mcaddon"
if (!$Output) {
    $Output = Join-Path $PSScriptRoot "dist/$bundleName"
}
$outputPath = [IO.Path]::GetFullPath($Output)
$tempPath = Join-Path ([IO.Path]::GetTempPath()) ('slime-addon-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $tempPath, (Split-Path $outputPath -Parent) -Force | Out-Null
try {
    foreach ($pack in @('SlimeGun_BP', 'SlimeGun_RP')) {
        [IO.Compression.ZipFile]::CreateFromDirectory(
            (Join-Path $PSScriptRoot $pack), (Join-Path $tempPath "$pack.mcpack"))
    }
    $bundle = Join-Path $tempPath $bundleName
    $archive = [IO.Compression.ZipFile]::Open($bundle, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($pack in @('SlimeGun_BP.mcpack', 'SlimeGun_RP.mcpack')) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $tempPath $pack), $pack) | Out-Null
        }
    } finally { $archive.Dispose() }
    Copy-Item -LiteralPath $bundle -Destination $outputPath -Force
    Write-Output $outputPath
} finally {
    $resolvedTemp = (Resolve-Path -LiteralPath $tempPath).Path
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolvedTemp.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $resolvedTemp -Leaf) -like 'slime-addon-*') {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
