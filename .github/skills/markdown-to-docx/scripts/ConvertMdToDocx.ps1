<#
.SYNOPSIS
    Converte un file .md in un documento Word .docx e lo salva nella cartella Docs/.

.PARAMETER MdPath
    Percorso assoluto o relativo del file .md da convertire.

.PARAMETER OutputPath
    Percorso assoluto del file .docx di output. Se omesso, viene calcolato automaticamente
    cercando la cartella Docs/ allo stesso livello di src/ (o accanto al .md).

.EXAMPLE
    .\ConvertMdToDocx.ps1 -MdPath "C:\Repos\MyProject\Docs\analisi.md"
    .\ConvertMdToDocx.ps1 -MdPath "analisi.md" -OutputPath "C:\Repos\MyProject\Docs\analisi.docx"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$MdPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeToc
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Risolvi percorso assoluto del markdown ---
$MdPath = Resolve-Path $MdPath | Select-Object -ExpandProperty Path

if (-not (Test-Path $MdPath)) {
    Write-Error "File non trovato: $MdPath"
    exit 1
}

$mdBaseName = [System.IO.Path]::GetFileNameWithoutExtension($MdPath)
$mdDir      = [System.IO.Path]::GetDirectoryName($MdPath)

# --- Determina OutputPath se non fornito ---
if (-not $OutputPath) {
    # Cerca Docs/ risalendo dall'attuale directory di lavoro
    $searchRoot = $PWD.Path
    $docsFolder = $null

    # Prima prova: cerca Docs/ vicino a src/
    $srcFolder = Get-ChildItem -Path $searchRoot -Filter "src" -Directory -Recurse -ErrorAction SilentlyContinue |
                 Select-Object -First 1

    if ($srcFolder) {
        $candidateDocs = Join-Path $srcFolder.Parent.FullName "Docs"
        if (Test-Path $candidateDocs) {
            $docsFolder = $candidateDocs
        } else {
            $docsFolder = $candidateDocs
        }
    }

    if (-not $docsFolder) {
        # Fallback: stessa cartella del .md
        $docsFolder = $mdDir
    }

    $OutputPath = Join-Path $docsFolder "${mdBaseName}.docx"
}

# --- Crea cartella Docs se non esiste ---
$outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Cartella creata: $outputDir"
}

# --- Cerca reference doc per stile aziendale (pandoc) ---
# Priorità: 1) template_lodestar.docx nella cartella reference/ accanto allo script
#            2) reference.docx nella cartella Docs/ di output
$referenceDoc = $null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lodestarRef = Join-Path $scriptDir "..\reference\template_lodestar.docx"
$lodestarRef = [System.IO.Path]::GetFullPath($lodestarRef)
if (Test-Path $lodestarRef) {
    $referenceDoc = $lodestarRef
    Write-Host "Trovato template aziendale: $referenceDoc"
} else {
    $candidateRef = Join-Path $outputDir "reference.docx"
    if (Test-Path $candidateRef) {
        $referenceDoc = $candidateRef
        Write-Host "Trovato reference.docx per stile: $referenceDoc"
    }
}

# --- Conversione ---
$pandocAvailable = $null -ne (Get-Command pandoc -ErrorAction SilentlyContinue)

if ($pandocAvailable) {
    Write-Host "Conversione con pandoc..."

    # Se esiste un template con copertina, pandoc genera prima un _body.docx temporaneo,
    # poi Word COM fa il merge: copertina del template + body generato da pandoc.
    $useCoverMerge = $null -ne $referenceDoc -and (Test-Path $referenceDoc)
    $pandocTarget  = if ($useCoverMerge) {
        [System.IO.Path]::Combine($outputDir, "${mdBaseName}_body.docx")
    } else {
        $OutputPath
    }

    $pandocArgs = @(
        $MdPath,
        "--from=markdown",
        "--to=docx",
        "--output=$pandocTarget",
        "--wrap=none",
        "--toc",
        "--toc-depth=4"
    )

    if ($referenceDoc) {
        $pandocArgs += "--reference-doc=$referenceDoc"
    }

    & pandoc @pandocArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Pandoc ha restituito un errore (exit code $LASTEXITCODE)."
        exit $LASTEXITCODE
    }

    # --- Merge copertina template + body pandoc via Word COM ---
    if ($useCoverMerge) {
        Write-Host "Merge copertina template con body generato..."
        $word = $null
        try {
            $word = New-Object -ComObject Word.Application
            $word.Visible = $false

            # Apri il template (diventa il documento base con la copertina)
            $docFinal = $word.Documents.Open($referenceDoc, $false, $true)  # ReadOnly=false, AddToRecentFiles=true

            # Vai alla fine del documento (dopo la copertina)
            $sel = $word.Selection
            $sel.EndKey(6) | Out-Null  # 6 = wdStory

            # Inserisci un'interruzione di pagina solo se l'ultimo carattere non è già un'interruzione
            # (il template potrebbe già avere la pagina finale con salto)
            $sel.InsertBreak(7) | Out-Null  # 7 = wdPageBreak

            # Apri il body generato da pandoc e copia tutto il suo contenuto
            $docBody = $word.Documents.Open($pandocTarget, $false, $true)
            $docBody.Content.Copy()
            $docBody.Close($false)

            # Incolla nel documento finale (mantieni formattazione sorgente)
            $sel.PasteAndFormat(16) | Out-Null  # 16 = wdFormatOriginalFormatting

            # Salva come nuovo file .docx
            $docFinal.SaveAs2($OutputPath, 16)  # 16 = wdFormatXMLDocument
            $docFinal.Close($false)

        } finally {
            if ($word) {
                $word.Quit()
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
            }
        }

        # Rimuovi il file body temporaneo
        Remove-Item -Path $pandocTarget -Force -ErrorAction SilentlyContinue
        Write-Host "File temporaneo rimosso: $pandocTarget"
    }

} else {
    Write-Host "pandoc non trovato. Uso Microsoft Word via COM..."

    $word = $null
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false

        # Leggi il contenuto Markdown
        $mdContent = Get-Content -Path $MdPath -Encoding UTF8 -Raw

        # Crea un nuovo documento Word
        $doc = $word.Documents.Add()
        $sel = $word.Selection

        # Mappa degli stili Word (italiano/inglese)
        $styleMap = @{
            "# "    = "Titolo 1"
            "## "   = "Titolo 2"
            "### "  = "Titolo 3"
            "#### " = "Titolo 4"
        }

        # Stili normalizzati (fallback inglese)
        $styleMapEn = @{
            "# "    = "Heading 1"
            "## "   = "Heading 2"
            "### "  = "Heading 3"
            "#### " = "Heading 4"
        }

        function Set-WordStyle {
            param($Selection, $StyleName, $StyleMapFallback)
            try {
                $Selection.Style = $StyleName
            } catch {
                try {
                    $Selection.Style = $StyleMapFallback
                } catch {
                    # Ignora se lo stile non esiste, usa normale
                }
            }
        }

        $lines = $mdContent -split "`n"
        $inCodeBlock = $false
        $codeLines   = [System.Collections.Generic.List[string]]::new()
        $inTable     = $false
        $tableLines  = [System.Collections.Generic.List[string]]::new()

        foreach ($rawLine in $lines) {
            $line = $rawLine.TrimEnd("`r")

            # --- Gestione blocco codice ---
            if ($line -match '^```') {
                if ($inCodeBlock) {
                    # Fine blocco codice
                    $inCodeBlock = $false
                    $codeText = $codeLines -join "`n"
                    $codeLines.Clear()
                    $sel.TypeText($codeText)
                    $sel.TypeParagraph()
                } else {
                    # Inizio blocco codice
                    $inCodeBlock = $true
                }
                continue
            }

            if ($inCodeBlock) {
                $codeLines.Add($line)
                continue
            }

            # --- Riga vuota ---
            if ([string]::IsNullOrWhiteSpace($line)) {
                if ($inTable) {
                    $inTable = $false
                    $tableLines.Clear()
                }
                $sel.TypeParagraph()
                continue
            }

            # --- Tabelle (gestione semplificata) ---
            if ($line -match '^\|') {
                if (-not $inTable) { $inTable = $true }
                # Salta la riga separatore |---|---|
                if ($line -match '^\|[\s\-:]+\|') {
                    continue
                }
                # Estrai celle
                $cells = $line -split '\|' | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }
                $rowText = $cells -join "   |   "
                $sel.Style  = "Normale"
                $sel.TypeText($rowText)
                $sel.TypeParagraph()
                continue
            } else {
                $inTable = $false
            }

            # --- Intestazioni ---
            $headingApplied = $false
            foreach ($prefix in @("#### ", "### ", "## ", "# ")) {
                if ($line.StartsWith($prefix)) {
                    $text = $line.Substring($prefix.Length).Trim()
                    # Rimuovi inline markdown
                    $text = $text -replace '\*\*(.+?)\*\*', '$1' -replace '\*(.+?)\*', '$1' -replace '`(.+?)`', '$1'
                    $italicStyle = $styleMapEn[$prefix]
                    Set-WordStyle $sel $styleMap[$prefix] $italicStyle
                    $sel.TypeText($text)
                    $sel.TypeParagraph()
                    $headingApplied = $true
                    break
                }
            }
            if ($headingApplied) { continue }

            # --- Liste puntate ---
            if ($line -match '^(\s*[-*+])\s+(.+)') {
                $text = $Matches[2].Trim()
                $text = $text -replace '\*\*(.+?)\*\*', '$1' -replace '\*(.+?)\*', '$1' -replace '`(.+?)`', '$1'
                try { $sel.Style = "Elenco puntato" } catch { try { $sel.Style = "List Bullet" } catch {} }
                $sel.TypeText($text)
                $sel.TypeParagraph()
                continue
            }

            # --- Liste numerate ---
            if ($line -match '^\s*\d+\.\s+(.+)') {
                $text = $Matches[1].Trim()
                $text = $text -replace '\*\*(.+?)\*\*', '$1' -replace '\*(.+?)\*', '$1' -replace '`(.+?)`', '$1'
                try { $sel.Style = "Elenco numerato" } catch { try { $sel.Style = "List Number" } catch {} }
                $sel.TypeText($text)
                $sel.TypeParagraph()
                continue
            }

            # --- Separatore orizzontale ---
            if ($line -match '^---+$' -or $line -match '^===+$') {
                try { $sel.Style = "Normale" } catch {}
                $sel.TypeText("—————————————————————————————")
                $sel.TypeParagraph()
                continue
            }

            # --- Paragrafo normale ---
            $text = $line -replace '\*\*(.+?)\*\*', '$1' -replace '\*(.+?)\*', '$1' -replace '`(.+?)`', '$1'
            $text = $text -replace '\[(.+?)\]\(.+?\)', '$1'  # Rimuovi link markdown
            try { $sel.Style = "Normale" } catch {}
            $sel.TypeText($text)
            $sel.TypeParagraph()
        }

        # Salva come docx
        $doc.SaveAs2($OutputPath, 16)  # 16 = wdFormatXMLDocument (.docx)
        $doc.Close($false)

    } finally {
        if ($word) {
            $word.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
        }
    }
}

# --- Verifica output ---
if (Test-Path $OutputPath) {
    $fileSize = (Get-Item $OutputPath).Length
    Write-Host ""
    Write-Host "✅ Conversione completata!" -ForegroundColor Green
    Write-Host "   Input  : $MdPath"
    Write-Host "   Output : $OutputPath"
    Write-Host "   Size   : $([math]::Round($fileSize / 1KB, 1)) KB"
} else {
    Write-Error "Il file di output non è stato creato: $OutputPath"
    exit 1
}
