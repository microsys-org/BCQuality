---
name: markdown-to-docx
description: "Converti un file .md in un documento Word .docx e salvalo nella cartella Docs/. Usa questa skill quando devi esportare documentazione funzionale Markdown in formato Word, generare un .docx da un _plan.md o da un documento funzionale, oppure quando l'utente richiede la documentazione in formato Word/DOCX."
argument-hint: "Percorso assoluto o relativo del file .md da convertire"
---

# Markdown to Docx

## Scopo

Converti un file `.md` in un documento Word `.docx`, salvandolo nella cartella `Docs/` allo stesso livello di `src/`.  
Se la cartella `Docs/` non esiste, viene creata automaticamente.

## Quando Usare

- L'utente richiede la documentazione funzionale in formato Word
- Devi esportare un `_plan.md`, un `_doc_funzionale.md` o qualsiasi `.md` prodotto in sessione
- L'utente chiede di generare un `.docx` da un file Markdown esistente
- Dopo la generazione di documentazione funzionale tramite `MSY al-doc-funzionale`, l'agent `MSY al-smart-dev` deve produrre anche il `.docx`

## Procedura

### 1. Individua il file .md sorgente

- Se l'utente fornisce un percorso, usalo direttamente.
- Se viene invocata dopo la generazione di documentazione, usa il percorso del file `.md` appena creato in `Docs/`.
- Se viene fornito solo il nome file, cercalo nella cartella `Docs/` del progetto.

### 2. Determina il percorso di destinazione

- Trova la cartella `Docs/` nel progetto corrente (usa `file_search` o `list_dir`).
- La cartella `Docs/` si trova **allo stesso livello di `src/`**.
- Esempio: se `src/` è in `C:\Repos\MyProject\src\`, allora `Docs/` sarà `C:\Repos\MyProject\Docs\`.
- Il file di output sarà: `Docs\{nomefile_senza_estensione}.docx`
  - Esempio: `Docs\syncMasterData_doc_funzionale.md` → `Docs\syncMasterData_doc_funzionale.docx`
- **Non** aggiungere suffissi: il nome del `.docx` è identico al `.md` con estensione cambiata.

### 3. Verifica pandoc disponibile

Esegui nel terminale:
```powershell
Get-Command pandoc -ErrorAction SilentlyContinue
```
- Se pandoc **è disponibile**, viene usato come motore di conversione primario.
- Se pandoc **non è installato**, lo script usa Microsoft Word via COM come fallback.

### 4. Crea la cartella Docs se mancante

```powershell
$docsPath = "<percorso_src>\..\Docs"
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath | Out-Null
}
```

### 5. Esegui la conversione

Usa [scripts/ConvertMdToDocx.ps1](./scripts/ConvertMdToDocx.ps1) passando:
- `-MdPath`: percorso assoluto del file `.md` sorgente
- `-OutputPath`: percorso assoluto del file `.docx` di destinazione (opzionale)

```powershell
& ".\scripts\ConvertMdToDocx.ps1" -MdPath "C:\...\Docs\documento.md" -OutputPath "C:\...\Docs\documento.docx"
```

**Percorso dello script:** `.github\skills\markdown-to-docx\scripts\ConvertMdToDocx.ps1`

### 6. Verifica e mostra il risultato

- Conferma che il file `.docx` è stato creato.
- Mostra il percorso completo del file generato.
- Chiedi all'utente se vuole aprire il file.

## Criteri di Completamento

- [ ] File `.md` trovato e leggibile
- [ ] Cartella `Docs/` esistente allo stesso livello di `src/`
- [ ] File `.docx` creato in `Docs/` con lo stesso nome base del `.md`
- [ ] Documento Word apribile e con formattazione corretta (intestazioni, paragrafi, tabelle)
- [ ] Percorso del file `.docx` mostrato all'utente

## Note

- Il nome del file output usa la **stessa base** del file `.md`: `doc_funzionale.md` → `doc_funzionale.docx`
- Se `src/` non è presente nel progetto, salva il `.docx` nella stessa cartella del `.md`
- Per la migliore qualità di formattazione (tabelle, codice, immagini), pandoc è fortemente raccomandato
- Con pandoc viene usato `--reference-doc` per applicare lo stile Word aziendale; la priorità è: 1) `reference/template_lodestar.docx` accanto allo script, 2) `Docs/reference.docx` nel progetto
- La conversione via Word COM produce un documento più grezzo ma funzionante anche senza pandoc
