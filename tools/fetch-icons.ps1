# Fetch REAL app icons from iTunes Search API (Apple official).
# 1) Downloads to Shared/AppIcons/ for widget bundle
# 2) Injects base64 JSON into the preview HTML (replaces /*APP_ICONS*/)
# Keys are ASCII; the preview maps them to Chinese display names.
param(
    [string]$PreviewHtml = "C:\Users\hellobabe\.zcode\v2\visualizations\8e08e16c8f514a0af91bd9e32b92ff3ca68673e0303151c31f97a53efa9b9ff4\widget-preview-lab.html",
    [string]$OutDir = "C:\Users\hellobabe\widgets\Shared\AppIcons"
)

$apps = @(
    @{ key = "weixin";   term = "WeChat";              country = "cn" },
    @{ key = "zhifubao"; term = "Alipay";              country = "cn" },
    @{ key = "taobao";   term = "Taobao";              country = "cn" },
    @{ key = "bilibili"; term = "bilibili";            country = "cn" },
    @{ key = "wangyiyun";term = "NetEase Cloud Music"; country = "cn" },
    @{ key = "douyin";   term = "Douyin";              country = "cn" },
    @{ key = "xhs";      term = "Xiaohongshu";         country = "cn" },
    @{ key = "pdd";      term = "Pinduoduo";           country = "cn" },
    @{ key = "meituan";  term = "Meituan";             country = "cn" },
    @{ key = "jd";       term = "JD";                  country = "cn" },
    @{ key = "weibo";    term = "Weibo";               country = "cn" },
    @{ key = "qq";       term = "QQ";                  country = "cn" },
    @{ key = "gaode";    term = "Amap";                country = "cn" },
    @{ key = "youtube";  term = "YouTube";             country = "us" },
    @{ key = "telegram"; term = "Telegram";            country = "us" },
    @{ key = "spotify";  term = "Spotify";             country = "us" }
)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$icons = @{}
$ok = 0; $fail = 0

foreach ($app in $apps) {
    try {
        $term = [Uri]::EscapeDataString($app.term)
        $url = "https://itunes.apple.com/search?term=$term&entity=software&country=$($app.country)&limit=1"
        $raw = Invoke-WebRequest -Uri $url -TimeoutSec 20 -UseBasicParsing
        $resp = $raw.Content | ConvertFrom-Json
        if (-not $resp.results -or $resp.results.Count -eq 0) { throw "not found" }
        $art = $resp.results[0].artworkUrl512
        if (-not $art) { $art = $resp.results[0].artworkUrl100 }
        $art = $art -replace "100x100", "150x150"
        $png = Invoke-WebRequest -Uri $art -TimeoutSec 20 -UseBasicParsing
        $file = Join-Path $OutDir ("icon_" + $app.key + ".png")
        [IO.File]::WriteAllBytes($file, $png.Content)
        $icons[$app.key] = "data:image/png;base64," + [Convert]::ToBase64String($png.Content)
        $ok++
        Write-Output ("OK   " + $app.key + " -> " + $resp.results[0].trackName)
    } catch {
        $fail++
        Write-Output ("FAIL " + $app.key + " : " + $_.Exception.Message)
    }
}

# Inject into preview HTML
$html = [IO.File]::ReadAllText($PreviewHtml)
$json = $icons | ConvertTo-Json -Compress
$block = "var APP_ICONS = " + $json + ";"
if ($html -match "/\*APP_ICONS\*/") {
    $html = $html -replace "/\*APP_ICONS\*/", $block
} elseif ($html -match "var APP_ICONS = \{[^}]*\};") {
    $html = $html -replace "var APP_ICONS = \{[^}]*\};", $block
} else {
    $html = $html -replace "var DEFAULTS = \[", ($block + "`n  var DEFAULTS = [")
}
[IO.File]::WriteAllText($PreviewHtml, $html)

Write-Output ("=== done: ok $ok / fail $fail ===")
