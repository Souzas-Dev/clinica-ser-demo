# ==========================================================
# CLÍNICA SER — REFINOS V2
# Sem backup. Execute na RAIZ do projeto.
#
# Mantém:
# /index.html
# /css/style.css
# /js/script.js
# /assets/img/logo-ser.png
# ==========================================================

$Root = (Get-Location).Path

$IndexPath = Join-Path $Root "index.html"
$CssPath   = Join-Path $Root "css\style.css"
$JsPath    = Join-Path $Root "js\script.js"
$LogoPath  = Join-Path $Root "assets\img\logo-ser.png"

$Required = @($IndexPath, $CssPath, $JsPath, $LogoPath)

foreach ($Path in $Required) {
    if (-not (Test-Path $Path)) {
        Write-Host "ERRO: arquivo não encontrado: $Path" -ForegroundColor Red
        Write-Host "Execute este script na raiz do projeto." -ForegroundColor Yellow
        exit 1
    }
}

# ----------------------------------------------------------
# 1. RECORTA A LOGO ATUAL SOMENTE SE AINDA ESTIVER GRANDE
# ----------------------------------------------------------

Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile($LogoPath)

if ($img.Width -gt 1000) {

    $x = [int][Math]::Round($img.Width  * 0.1356)
    $y = [int][Math]::Round($img.Height * 0.2671)

    $right  = [int][Math]::Round($img.Width  * 0.8453)
    $bottom = [int][Math]::Round($img.Height * 0.7815)

    $cropWidth  = $right - $x
    $cropHeight = $bottom - $y

    $bitmap = New-Object System.Drawing.Bitmap($cropWidth, $cropHeight)

    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $dest = New-Object System.Drawing.Rectangle(0, 0, $cropWidth, $cropHeight)
    $src  = New-Object System.Drawing.Rectangle($x, $y, $cropWidth, $cropHeight)

    $graphics.DrawImage(
        $img,
        $dest,
        $src,
        [System.Drawing.GraphicsUnit]::Pixel
    )

    $img.Dispose()
    $graphics.Dispose()

    $TempLogo = "$LogoPath.tmp.png"

    $bitmap.Save(
        $TempLogo,
        [System.Drawing.Imaging.ImageFormat]::Png
    )

    $bitmap.Dispose()

    Move-Item $TempLogo $LogoPath -Force

    Write-Host "Logo otimizada." -ForegroundColor Green
}
else {
    $img.Dispose()
    Write-Host "Logo já está otimizada. Nenhum novo recorte aplicado." -ForegroundColor Cyan
}


# ----------------------------------------------------------
# 2. TROCA A FOTO REPETIDA DA SEÇÃO SOBRE
# ----------------------------------------------------------

$html = Get-Content $IndexPath -Raw -Encoding UTF8

$NovaFotoSobre = "https://images.pexels.com/photos/5793653/pexels-photo-5793653.jpeg?auto=compress&cs=tinysrgb&w=1200"

$html = [regex]::Replace(
    $html,
    '(<img\s+class="about-photo"\s+src=")[^"]+(")',
    ('$1' + $NovaFotoSobre + '$2'),
    1
)

$html = [regex]::Replace(
    $html,
    '(class="about-photo"[\s\S]*?alt=")[^"]+(")',
    '$1Profissional auxiliando paciente durante atendimento de fisioterapia$2',
    1
)

[System.IO.File]::WriteAllText(
    $IndexPath,
    $html,
    [System.Text.UTF8Encoding]::new($false)
)


# ----------------------------------------------------------
# 3. REFINOS DE CSS
# ----------------------------------------------------------

$css = Get-Content $CssPath -Raw -Encoding UTF8

$Inicio = "/* ===== SOUZAS DEV | REFINOS V2 | INICIO ===== */"
$Fim    = "/* ===== SOUZAS DEV | REFINOS V2 | FIM ===== */"

$Pattern = [regex]::Escape($Inicio) +
           '(?s).*?' +
           [regex]::Escape($Fim)

$css = [regex]::Replace(
    $css,
    $Pattern,
    ""
)

$Refinos = @'

/* ===== SOUZAS DEV | REFINOS V2 | INICIO ===== */

/* Logo: arquivo recortado, mais legível sem aumentar o header */
.brand-logo {
  width: 78px;
  height: 56px;
  flex: 0 0 78px;
  object-fit: contain;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
}

.brand:hover .brand-logo {
  transform: translateY(-1px) scale(1.02);
  box-shadow: none;
}

.site-header .brand-logo {
  max-height: 56px;
}

.brand-logo-footer {
  width: 86px;
  height: 62px;
  flex-basis: 86px;
}

/* Aproxima os serviços do Hero */
.trust-strip {
  margin-top: 54px;
}

.services {
  padding-top: 70px;
}

/* Enquadramento da nova foto do Sobre */
.about-photo {
  object-position: center 48%;
}

/* Final da página mais compacto */
.contact {
  padding-bottom: 54px;
}

.site-footer {
  padding-top: 24px;
  padding-bottom: 38px;
}

@media (max-width: 980px) {
  .brand-logo {
    width: 74px;
    height: 54px;
    flex-basis: 74px;
  }

  .services {
    padding-top: 66px;
  }

  .contact {
    padding-bottom: 48px;
  }
}

@media (max-width: 700px) {
  .brand-logo {
    width: 68px;
    height: 50px;
    flex-basis: 68px;
  }

  .brand-logo-footer {
    width: 78px;
    height: 58px;
    flex-basis: 78px;
  }

  .trust-strip {
    margin-top: 44px;
  }

  .services {
    padding-top: 58px;
  }

  .contact {
    padding-bottom: 38px;
  }

  .site-footer {
    padding-top: 20px;
    padding-bottom: 32px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .brand:hover .brand-logo {
    transform: none;
  }
}

/* ===== SOUZAS DEV | REFINOS V2 | FIM ===== */

'@

$cssFinal = $css.TrimEnd() + "`r`n`r`n" + $Refinos

[System.IO.File]::WriteAllText(
    $CssPath,
    $cssFinal,
    [System.Text.UTF8Encoding]::new($false)
)


# ----------------------------------------------------------
# RESULTADO
# ----------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host " CLÍNICA SER — REFINOS V2 APLICADOS" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Aplicado:" -ForegroundColor Cyan
Write-Host "  - Logo recortada e mais legível"
Write-Host "  - Espaço Hero -> Serviços reduzido"
Write-Host "  - Foto repetida da seção Sobre substituída"
Write-Host "  - Espaço Contato -> Footer reduzido"
Write-Host ""
Write-Host "Mantidos:" -ForegroundColor Cyan
Write-Host "  /index.html"
Write-Host "  /css/style.css"
Write-Host "  /js/script.js"
Write-Host "  /assets/img/logo-ser.png"
Write-Host ""
Write-Host "Nenhum backup foi criado." -ForegroundColor Green
