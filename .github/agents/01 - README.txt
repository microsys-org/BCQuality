================================================================================
  AGENTI MSY - GUIDA RAPIDA ALL'UTILIZZO
  Business Central AL Development - Techbau TCB
================================================================================

Questo file descrive brevemente ogni agente "MSY" disponibile nel workspace,
indicando QUANDO utilizzarlo e in QUALE contesto.

================================================================================
FLUSSO CONSIGLIATO PER LO SVILUPPO COMPLETO
================================================================================

  [Analisi] → MSY analysis revisor
       ↓
  [Architettura] → MSY al-architect
       ↓
  [Sviluppo TDD] → MSY al-maestro V2  (orchestratore completo)
       ↓           oppure: MSY al-conductor → subagenti
  [Build/Qualita] → MSY al-code reviewer and build
       ↓
  [UAT] → MSY al-UAT Todo list Giorgione
       ↓
  [Documentazione] → MSY al-doc-funzionale / MSY al-doc-tecnica

================================================================================
AGENTI ORCHESTRATORI (punto d'ingresso principale)
================================================================================

MSY al-maestro V2
  QUANDO: Punto di ingresso per lo sviluppo end-to-end di una nuova feature.
          Accetta un file .md o .docx allegato oppure istruzioni nel prompt.
  DOVE:   Inizio di ogni nuovo sviluppo che richiede l'intero ciclo
          Design → Planning → Implementation (TDD) → Review → Build → Test.
  NOTA:   Delega automaticamente agli altri subagenti; non scrive codice.

MSY al-conductor
  QUANDO: Quando si ha gia' un'architettura definita o un documento di
          requisiti e si vuole orchestrare il ciclo Planning → Implement →
          Review → Commit con TDD.
  DOVE:   Preferire al Maestro quando l'architettura e' gia' decisa e si
          vuole controllare passo-passo ogni fase di implementazione.

================================================================================
AGENTI SPECIALISTICI - PROGETTAZIONE E ANALISI
================================================================================

MSY analysis revisor
  QUANDO: Prima di iniziare lo sviluppo, per validare un documento di analisi
          funzionale (.docx o .md). Anticipa criticita', domande e alternative.
  DOVE:   Review di analisi funzionali in fase pre-sviluppo. Output: file .md
          di revisione strutturata con lo stesso nome del documento originale.

MSY al-architect
  QUANDO: Per prendere decisioni architetturali strategiche: scelta dei pattern,
          modello dati, integrazione con BC, design di extensibility.
  DOVE:   Prima del Conductor/Maestro, quando la feature e' complessa e
          richiede un progetto architetturale documentato (file *-arch.md).

MSY al-planning-subagent
  QUANDO: Ricerca e raccolta contesto AL per un task specifico.
          Chiamato tipicamente dal Conductor, ma usabile anche direttamente.
  DOVE:   Fase di ricerca: analizza oggetti AL esistenti, eventi, dipendenze
          e restituisce i findings strutturati. Non scrive codice.

================================================================================
AGENTI SPECIALISTICI - IMPLEMENTAZIONE E BUILD
================================================================================

MSY al-developer
  QUANDO: Implementazione tattica di codice AL seguendo una specifica gia'
          definita. Ha accesso completo agli strumenti di build e test.
  DOVE:   Scrittura diretta di tabelle, pagine, codeunit, report, ecc.
          senza dover passare per l'orchestratore.

MSY al-implement-subagent
  QUANDO: Esecuzione di un singolo task di implementazione TDD nell'ambito
          di un ciclo orchestrato dal Conductor.
  DOVE:   Chiamato dal Conductor per implementare una singola fase del piano
          (RED → GREEN → REFACTOR). Non usare direttamente per feature complete.

MSY al-api
  QUANDO: Progettazione e implementazione di API REST, servizi OData o
          integrazioni web service per Business Central.
  DOVE:   Feature che espongono o consumano API: API Pages, OData v4,
          integrazioni con sistemi esterni (es. Zucchetti, portali web, ecc.).

MSY al-code optimizer
  QUANDO: Per ottimizzare codice AL esistente senza alterare le logiche di
          business: performance, stile, naming, label, pulizia codice morto.
  DOVE:   Su file AL gia' implementati per applicare SetLoadFields, filtraggio
          anticipato, sostituzione stringhe hardcoded con label, naming
          conventions e code style da instructions. Zero cambiamenti funzionali.

MSY al-code reviewer and build
  QUANDO: Dopo l'implementazione, per portare il progetto a 0 errori /
          0 warning / 0 info (obiettivo 0/0/0).
  DOVE:   Fase finale prima del collaudo: compila, analizza diagnostica
          CodeCop/AppSourceCop/UICop, assegna Object ID, ordina namespace.

================================================================================
AGENTI SPECIALISTICI - QUALITA' E TEST
================================================================================

MSY al-tester
  QUANDO: Creazione di test automatizzati AL, implementazione TDD,
          definizione della strategia di test per una feature.
  DOVE:   Scrittura di codeunit di test nel progetto .Test, setup di
          LibraryAssert, test di unita' e di integrazione BC.

MSY al-review-subagent
  QUANDO: Revisione della qualita' del codice dopo una fase di implementazione.
          Chiamato dal Conductor come gate di qualita'.
  DOVE:   Verifica che il codice implementato rispetti le best practice AL,
          la copertura dei test e i pattern BC. Non usare per build/compile.

MSY al-debugger
  QUANDO: Diagnosi e risoluzione di bug, analisi del flusso di esecuzione,
          troubleshooting di problemi in produzione o sviluppo.
  DOVE:   Debug con attach/snapshot debugger, profiling CPU, analisi
          problemi intermittenti. Ha accesso agli strumenti AL di debugging.

================================================================================
AGENTI SPECIALISTICI - DOCUMENTAZIONE E UAT
================================================================================

MSY al-doc-funzionale
  QUANDO: Produzione di documentazione destinata agli utenti finali:
          guide, release notes, FAQ, descrizione processi aziendali.
  DOVE:   Dopo il completamento di una feature, per generare documenti
          leggibili da chi usa BC senza conoscenze tecniche. Testo in italiano.

MSY al-doc-tecnica
  QUANDO: Produzione di documentazione tecnica per sviluppatori:
          commenti XML AL, specifiche API, catalogo eventi, README tecnici.
  DOVE:   Dopo l'implementazione, per documentare codeunit, API, publisher/
          subscriber e architettura dell'estensione. Testo in italiano.

MSY al-UAT Todo list Giorgione
  QUANDO: Al termine dello sviluppo, per generare la lista degli UAT
          funzionali necessari per accettare gli sviluppi.
  DOVE:   Analizza oggetti AL o cartelle allegati e produce un file .xlsx
          con colonne: Nr. UAT, Descrizione Feature, Esito Test, Note.

MSY al-copilot
  QUANDO: Sviluppo di funzionalita' Copilot AI-powered in Business Central
          (PromptDialog, Azure OpenAI, prompt engineering, assistenti).
  DOVE:   Feature che integrano AI: suggerimenti automatici, chat BC,
          generazione testi, analisi dati tramite LLM. Punto di partenza
          obbligatorio per qualsiasi feature Copilot in BC.

================================================================================
AGENTI DI MANUTENZIONE WORKSPACE
================================================================================

MSY Agent update
  QUANDO: Per aggiornare e ottimizzare gli agenti MSY del workspace:
          modello IA, toolset, e configurazione di ogni agente.
  DOVE:   Manutenzione periodica del parco agenti. Analizza tutti i file
          .agent.md con prefisso MSY, ottimizza modello e strumenti, testa
          ogni agente modificato prima di procedere. Produce un report finale.
  NOTA:   Opera esclusivamente sui file .agent.md con prefisso MSY.
          Non tocca mai agenti senza prefisso MSY.

MSY conver file to .md
  QUANDO: Per convertire qualsiasi tipo di file in un file Markdown (.md)
          ben strutturato e leggibile.
  DOVE:   Usa questo agente ogni volta che devi trasformare un file
          (Word, Excel, CSV, JSON, XML, AL, TXT, HTML, PDF, YAML, INI,
          script PowerShell, tabelle, codice sorgente) in formato Markdown.
  COME UTILIZZARLO:
    1. Apri la chat di Copilot (Ctrl+Alt+I) e seleziona l'agente
       "MSY conver file to .md" dal selettore agenti.
    2. Fornisci il file in uno di questi modi:
         a) Scrivi il percorso assoluto o relativo:
            "Converti C:\percorso\file.csv in Markdown"
         b) Scrivi solo il nome del file (l'agente lo cerca nel workspace):
            "Converti app.json in Markdown"
         c) Incolla il contenuto direttamente nel prompt:
            "Converti questo file in .md:" + testo incollato
    3. L'agente:
         - Identifica automaticamente il tipo di file
         - Applica le regole di conversione specifiche per quel formato
         - Salva il file .md nella stessa cartella dell'originale
           (es: report.csv → report.md)
         - Conferma il percorso del file creato e il numero di
           elementi convertiti
    4. Personalizzazioni opzionali:
         - "Salva in C:\altra\cartella\" per cambiare destinazione
         - "Converti tutti i .al della cartella src/" per batch
         - "Riorganizza questo README.md" per migliorare un .md esistente
  TIPI SUPPORTATI:
    .txt .csv .json .xml .xlf .yaml .yml .ini .config
    .html .al .ps1 .sh .md .pdf .docx .xlsx
  NOTA PDF:  L'estrazione da PDF richiede 'pdftotext' (Poppler) o
             iTextSharp installati. In assenza di strumenti, l'agente
             chiede di incollare il testo manualmente.
  NOTA FILE BINARI:  File come .exe, .dll, .png non sono convertibili;
             l'agente lo segnala e spiega il motivo.

================================================================================
TABELLA RIASSUNTIVA
================================================================================

Agente                         | Fase            | Scopo principale
-------------------------------|-----------------|----------------------------------
MSY analysis revisor           | Pre-sviluppo    | Revisione analisi funzionale
MSY al-architect               | Design          | Architettura e pattern AL
MSY al-maestro V2              | End-to-end      | Orchestrazione completa feature
MSY al-conductor               | Orchestrazione  | Ciclo TDD Planning→Commit
MSY al-planning-subagent       | Ricerca         | Context gathering AL (subagent)
MSY al-developer               | Implementazione | Codice AL tattico diretto
MSY al-implement-subagent      | Implementazione | Codice AL TDD (subagent)
MSY al-api                     | Implementazione | API REST / OData / web service
MSY al-code optimizer          | Build/Qualita   | Ottimizzazione performance e stile
MSY al-code reviewer and build | Build/Qualita   | 0/0/0 errori warning info
MSY al-tester                  | Testing         | Test automatizzati AL / TDD
MSY al-review-subagent         | Revisione       | Code review qualita' (subagent)
MSY al-debugger                | Debug           | Troubleshooting e profiling
MSY al-doc-funzionale          | Documentazione  | Doc utente finale (italiano)
MSY al-doc-tecnica             | Documentazione  | Doc tecnica sviluppatori (italiano)
MSY al-UAT Todo list Giorgione | Collaudo        | Generazione lista UAT (.xlsx)
MSY al-copilot                 | Implementazione | Feature AI Copilot in BC
MSY Agent update               | Manutenzione    | Aggiornamento e ottimizzazione agenti
MSY conver file to .md         | Utilita'        | Conversione file in formato Markdown

================================================================================
