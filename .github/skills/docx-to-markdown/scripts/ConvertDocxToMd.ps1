<#
.SYNOPSIS
    Converte un file .docx in Markdown e lo salva come {nomefile}_plan.md nella cartella docs/.

.PARAMETER DocxPath
    Percorso assoluto o relativo del file .docx da convertire.

.PARAMETER OutputPath
    Percorso assoluto del file .md di output. Se omesso, viene calcolato automaticamente
    cercando la cartella docs/ allo stesso livello di src/ (o accanto al .docx).

.EXAMPLE
    .\ConvertDocxToMd.ps1 -DocxPath "C:\Repos\MyProject\docs\analisi.docx"
    .\ConvertDocxToMd.ps1 -DocxPath "analisi.docx" -OutputPath "C:\Repos\MyProject\docs\analisi_plan.md"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DocxPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Risolvi percorso assoluto del docx ---
$DocxPath = Resolve-Path $DocxPath | Select-Object -ExpandProperty Path

if (-not (Test-Path $DocxPath)) {
    Write-Error "File non trovato: $DocxPath"
    exit 1
}

$docxBaseName = [System.IO.Path]::GetFileNameWithoutExtension($DocxPath)
$docxDir      = [System.IO.Path]::GetDirectoryName($DocxPath)

# --- Determina OutputPath se non fornito ---
if (-not $OutputPath) {
    # Cerca src/ risalendo dall'attuale directory di lavoro
    $searchRoot = $PWD.Path
    $srcFolder  = Get-ChildItem -Path $searchRoot -Filter "src" -Directory -Recurse -ErrorAction SilentlyContinue |
                  Select-Object -First 1

    if ($srcFolder) {
        $docsFolder = Join-Path $srcFolder.Parent.FullName "docs"
    } else {
        # Fallback: docs/ accanto al docx
        $docsFolder = Join-Path $docxDir "docs"
    }

    $OutputPath = Join-Path $docsFolder "${docxBaseName}_plan.md"
}

# --- Crea cartella docs se non esiste ---
$outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Cartella creata: $outputDir"
}

# --- Conversione ---
$pandocAvailable = $null -ne (Get-Command pandoc -ErrorAction SilentlyContinue)

if ($pandocAvailable) {
    Write-Host "Conversione con pandoc..."
    & pandoc $DocxPath `
        --from=docx `
        --to=markdown_github `
        --wrap=none `
        --output=$OutputPath
} else {
    Write-Host "pandoc non trovato. Uso Microsoft Word via COM..."

    $word = $null
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false

        $doc = $word.Documents.Open($DocxPath, $false, $true)

        # Estrae il testo paragrafo per paragrafo con formattazione base
        $mdLines = [System.Collections.Generic.List[string]]::new()

        foreach ($para in $doc.Paragraphs) {
            $style = $para.Style.NameLocal
            $text  = $para.Range.Text.TrimEnd("`r", "`n", [char]11, [char]13)

            if ([string]::IsNullOrWhiteSpace($text)) {
                $mdLines.Add("")
                continue
            }

            switch -Wildcard ($style) {
                "Titolo 1"   { $mdLines.Add("# $text") }
                "Titolo 2"   { $mdLines.Add("## $text") }
                "Titolo 3"   { $mdLines.Add("### $text") }
                "Titolo 4"   { $mdLines.Add("#### $text") }
                "Heading 1"  { $mdLines.Add("# $text") }
                "Heading 2"  { $mdLines.Add("## $text") }
                "Heading 3"  { $mdLines.Add("### $text") }
                "Heading 4"  { $mdLines.Add("#### $text") }
                "Elenco *"   { $mdLines.Add("- $text") }
                "List *"     { $mdLines.Add("- $text") }
                default      { $mdLines.Add($text) }
            }
        }

        $doc.Close($false)
        $mdLines | Set-Content -Path $OutputPath -Encoding UTF8
    }
    finally {
        if ($word) {
            $word.Quit()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        }
    }
}

if (Test-Path $OutputPath) {
    Write-Host "✔ File generato: $OutputPath"
} else {
    Write-Error "Conversione fallita: il file di output non è stato creato."
    exit 1
}
