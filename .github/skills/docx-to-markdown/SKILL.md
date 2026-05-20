---
name: docx-to-markdown
description: "Converti un file .docx in Markdown e salvalo nella cartella docs come {nomefile}_plan.md. Usa questa skill quando devi convertire un documento Word in markdown, creare un file _plan.md da un .docx, trasformare analisi funzionale Word in piano markdown, oppure quando ricevi un file .docx da elaborare come piano di sviluppo."
argument-hint: "Percorso assoluto o relativo del file .docx da convertire"
---

# Docx to Markdown Plan

## Scopo

Converti un file `.docx` in un file Markdown strutturato, salvandolo nella cartella `docs/` allo stesso livello di `src/` con il nome `{nomefile}_plan.md`.  
Se la cartella `docs/` non esiste, viene creata automaticamente.

## Quando Usare

- Ricevi un file `.docx` allegato o come argomento e devi produrre un piano `.md`
- L'utente richiede di convertire un'analisi funzionale Word in Markdown
- Devi preparare un `_plan.md` da un documento Word per il progetto

## Procedura

### 1. Individua il file .docx

- Se l'utente allega un file, usa il suo percorso assoluto.
- Se fornisce solo il nome, cercalo nella cartella corrente o chiedi conferma.

### 2. Determina il percorso di destinazione

- Trova la cartella `src/` nel progetto corrente (usa `file_search` o `list_dir`).
- La cartella `docs/` va creata **allo stesso livello di `src/`**.
- Esempio: se `src/` è in `C:\Repos\MyProject\src\`, allora `docs/` sarà `C:\Repos\MyProject\docs\`.
- Il file di output sarà: `docs\{nomefile_senza_estensione}_plan.md`

### 3. Verifica pandoc disponibile

Esegui nel terminale:
```powershell
Get-Command pandoc -ErrorAction SilentlyContinue
```
- Se pandoc **non è installato**, usa lo [script PowerShell fallback](./scripts/ConvertDocxToMd.ps1) che estrae il testo tramite COM Word.
- Se pandoc **è disponibile**, usa il [script di conversione pandoc](./scripts/ConvertDocxToMd.ps1).

### 4. Crea la cartella docs se mancante

```powershell
$docsPath = "<percorso_src>\..\docs"
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath | Out-Null
}
```

### 5. Esegui la conversione

Usa [scripts/ConvertDocxToMd.ps1](./scripts/ConvertDocxToMd.ps1) passando:
- `-DocxPath`: percorso assoluto del file `.docx`
- `-OutputPath`: percorso assoluto del file `_plan.md` di destinazione

```powershell
.\ConvertDocxToMd.ps1 -DocxPath "C:\...\documento.docx" -OutputPath "C:\...\docs\documento_plan.md"
```

### 6. Verifica e mostra il risultato

- Conferma che il file `_plan.md` è stato creato.
- Mostra il percorso completo del file generato.
- Chiedi all'utente se vuole aprire o rivedere il file generato.

## Criteri di Completamento

- [ ] File `.docx` trovato e leggibile
- [ ] Cartella `docs/` esistente allo stesso livello di `src/`
- [ ] File `{nomefile}_plan.md` creato in `docs/`
- [ ] Contenuto Markdown leggibile e strutturato
- [ ] Percorso del file mostrato all'utente

## Note

- Il nome del file output usa `_plan.md` come suffisso, non `_plan.md` aggiunto alla fine dell'estensione originale: `analisi_funzionale.docx` → `analisi_funzionale_plan.md`
- Se `src/` non è presente nel progetto, salva `docs/` nella stessa cartella del file `.docx`
- Per conversioni con formattazione avanzata (tabelle, immagini) è fortemente raccomandato pandoc
