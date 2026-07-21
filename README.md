# Network Interface Hardware in VHDL

Questo repository contiene l'implementazione e la simulazione in VHDL di un'interfaccia di rete hardware (Network Interface) dedicata alla manipolazione, serializzazione, deserializzazione e routing di flussi di dati strutturati a pacchetti su parole a 32-bit (word). Il progetto include la validazione tramite testbench dedicati e l'implementazione fisica su FPGA Xilinx.

---

## 📌 Indice
- [Descrizione del Progetto](#descrizione-del-progetto)
- [Architettura del Sistema](#architettura-del-sistema)
  - [Struttura del Pacchetto](#struttura-del-pacchetto)
  - [Blocco di Trasmissione (TX Block)](#blocco-di-trasmissione-tx-block)
  - [Blocco di Ricezione (RX Block)](#blocco-di-ricezione-rx-block)
  - [Top Level](#top-level)
- [Implementazione Hardware su FPGA](#implementazione-hardware-su-fpga)
- [Struttura del Repository](#struttura-del-repository)
- [Sviluppi Futuri](#sviluppi-futuri)
- [Autore e Contesto](#autore-e-contesto)

---

## 📖 Descrizione del Progetto

L'obiettivo principale del progetto è realizzare un'interfaccia di rete in grado di gestire l'intero ciclo di vita di un pacchetto dati:
1. **Immagazzinamento locale:** Ricezione dei dati da un generatore e scrittura in un buffer FIFO locale per gestire differenze di clock e disponibilità del canale.
2. **Serializzazione:** Conversione del pacchetto parallelo in un flusso seriale a singola linea (1-bit) per simulare la trasmissione efficiente su lunga distanza.
3. **Deserializzazione e Smistamento:** Ricostruzione del pacchetto seriale in formato parallelo e instradamento verso la corretta FIFO di destinazione finale.

La validazione dell'architettura è stata condotta seguendo un approccio incrementale, testando i singoli moduli tramite simulazione prima dell'integrazione nel modulo finale TOP.

---

## 🏗️ Architettura del Sistema

### 📦 Struttura del Pacchetto
I dati trasmessi sono organizzati in pacchetti composti da due sezioni principali:
* **Header (32 bit):** Contiene le informazioni di controllo necessarie alla gestione del pacchetto, tra cui la lunghezza del messaggio e i campi di indirizzamento della destinazione. Le posizioni di questi campi sono specificate nel file `performance_type_pkg`.
* **Payload:** Rappresenta il contenuto informativo effettivo composto da parole a 32-bit.

---

### 📤 Blocco di Trasmissione (TX Block)
Il blocco di trasmissione si compone dei seguenti moduli:
* **Packet Generator:** Inizializza i dati secondo `performance_type_pkg` e interagisce con il sistema tramite un protocollo di handshake sincrono basato sui segnali `dt_valid` e `dt_ready`.
* **FSM1 (Immagazzinamento e Handshake):**
  * Gestisce la comunicazione tra il Packet Generator e la memoria FIFO.
  * Nello stato **IDLE**, attende un dato valido e decodifica dall'Header la lunghezza del Payload.
  * Nello stato **PAYLOAD**, carica le word di dati nella FIFO decrementando un contatore interno fino al completamento del pacchetto.
  * Congela la trasmissione abbassando `dt_ready` se la FIFO risulta piena (`fifo_full = '1'`).
* **FIFO Buffer:** Memoria intermedia con meccanismo *First-Word-Fall-Through* (FWFT) per azzerare i cicli di clock di latenza in lettura.
* **FSM2 (Serializzazione):**
  * Estrae i dati dalla FIFO e li serializza bit a bit (da MSB a LSB) su una singola linea.
  * Si articola in quattro stati: `READ_HEADER`, `SERIALIZE_HEADER`, `READ_PAYLOAD` e `SERIALIZE_PAYLOAD`.
  * Genera il segnale `valid_out` per indicare al modulo ricevitore la presenza di dati seriali validi.

---

### 📥 Blocco di Ricezione (RX Block)
Il blocco di ricezione si occupa della ricostruzione dei dati seriali:
* **FSM3 (Deserializzazione e Routing):**
  * Progettata per l'acquisizione continua dei dati senza segnale di controllo di flusso (ready) verso FSM2.
  * Nello stato `READ_HEADER`, deserializza l'Header ed estrae la lunghezza del Payload e l'indirizzo della FIFO di destinazione (`dest_fifo_reg` tramite i bit da 31 a 29).
  * Nello stato `READ_PAYLOAD`, deserializza le word del Payload e le invia alla FIFO selezionata.
* **FIFO di Destinazione:** Due memorie FIFO che immagazzinano i pacchetti ricostruiti in parallelo in base all'indirizzamento
---

### 🔝 Top Level
Il modulo `TOP` connette l'intera catena di elaborazione (Packet Generator → TX Block → RX Block)[cite: 1]. Il sistema include due istanze del modulo **Packet Checker**, che verificano la corrispondenza dei dati ricevuti rispetto a quelli generati fornendo un esito positivo tramite i segnali `test_ok_1` e `test_ok_2`

---

## ⚙️ Implementazione Hardware su FPGA

L'implementazione fisica è stata eseguita nell'ambiente di sviluppo **Xilinx Vivado** presso i laboratori APE dell'Università Sapienza:
* **IP Core utilizzate:** Generatore di memoria FIFO e **Clocking Wizard** per la gestione di domini di clock asincroni.
* **Simulazione:** Preventivamente verificata tramite il simulatore **GHDL**
* **Debug On-Chip:** Monitoraggio dei segnali interni mediante modulo **ILA (Integrated Logic Analyzer)** su Vivado Hardware Manager.
* **Pin esterni impiegati:** `clk_p`, `clk_n`, `reset`, `test_ok_1` e `test_ok_2`

---

## 📁 Struttura del Repository

```text
.
├── src/                    # Codici sorgente VHDL (FSM1, FSM2, FSM3, Top Level, Pkg)
├── tb/                     # TestBench per simulazione e Packet Checker
├── fpga/                   # File di vincolo (.xdc) e IP Core Vivado
├── docs/                   # Documentazione di progetto
├── .gitignore              # Filtro per file temporanei Vivado/GHDL
└── README.md               # Documentazione principale del repository
