$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.HttpListener

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:8000/")
$listener.Start()

$root = "C:\Users\Nicolina\Downloads\dm-landingpage"

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $requestPath = $context.Request.Url.AbsolutePath.TrimStart("/")

    if ([string]::IsNullOrWhiteSpace($requestPath)) {
      $requestPath = "index.html"
    }

    $filePath = Join-Path $root $requestPath

    if ((Test-Path $filePath) -and -not (Get-Item $filePath).PSIsContainer) {
      $bytes = [System.IO.File]::ReadAllBytes($filePath)

      switch ([System.IO.Path]::GetExtension($filePath).ToLowerInvariant()) {
        ".html" { $context.Response.ContentType = "text/html; charset=utf-8" }
        ".css" { $context.Response.ContentType = "text/css; charset=utf-8" }
        ".js" { $context.Response.ContentType = "application/javascript; charset=utf-8" }
        ".png" { $context.Response.ContentType = "image/png" }
        ".jpg" { $context.Response.ContentType = "image/jpeg" }
        ".jpeg" { $context.Response.ContentType = "image/jpeg" }
        ".svg" { $context.Response.ContentType = "image/svg+xml; charset=utf-8" }
        default { $context.Response.ContentType = "application/octet-stream" }
      }

      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $context.Response.StatusCode = 404
    }

    $context.Response.OutputStream.Close()
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
