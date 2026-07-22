# nblbnk-usarmy

**Militaerjob fuer FiveM — laeuft auf ESX und QBCore aus einer einzigen
Installation.**

Ein vollstaendiger Rollenspiel-Job rund um eine Militaereinheit: acht
US-Dienstgrade, gestaffelte Waffenkammer, Fahrzeugausgabe fuer Land und
Luft, Kommandozentrale zur Personalverwaltung, Festnahme mit Transport und
ein ueberwachtes Sperrgebiet.

Jobname in der Datenbank: **`usarmy`**

---

## Ein Job, beide Frameworks

Es gibt keine ESX-Fassung und keine QBCore-Fassung. Die Ressource stellt
beim Start selbst fest, was auf dem Server laeuft, und richtet sich danach.
Dasselbe gilt fuer Inventar, Menue, Interaktion und Kleidung — die
Ressource nutzt, was vorhanden ist, statt es vorauszusetzen.

| Bereich | Wird erkannt | Wenn nichts davon da ist |
| :--- | :--- | :--- |
| **Framework** | `es_extended`, `qb-core` | Ressource bleibt inaktiv und meldet es |
| **Inventar** | `ox_inventory`, `qb-inventory` | Standardinventar des Frameworks |
| **Menue** | `ox_lib`, `qb-menu` | ESX-Standardmenue |
| **Interaktion** | `ox_target`, `qb-target` | Marker mit Taste **E** |
| **Kleidung** | `illenium-appearance`, `qb-clothing`, `esx_skin` | Komponenten aus der Konfiguration |
| **Gesellschaftskasse** | `esx_addonaccount`, `qb-management` | Kassenstand 0, Personalverwaltung laeuft weiter |

Jede Erkennung laesst sich in der `config.lua` uebersteuern, falls ein
Server eine Sonderkonstellation faehrt. Keine dieser Ressourcen ist eine
Pflichtabhaengigkeit — fehlt eine, greift die jeweilige Rueckfallebene,
ohne dass etwas ausfaellt.

---

## Dienstgrade

Acht Stufen, an der US-Struktur orientiert. Jeder Rang steuert, welche
Waffen und Fahrzeuge zugaenglich sind.

| Grad | Kuerzel | Bezeichnung | Sold | Schaltet frei |
| ---: | :--- | :--- | ---: | :--- |
| 0 | **PVT** | Private | 50 | Messer, Pistole, Weste, Verbandszeug, Crusader |
| 1 | **SPC** | Specialist | 75 | Handschellen, Festnahme und Transport |
| 2 | **SGT** | Sergeant | 100 | Schrotflinte, Barracks |
| 3 | **SSG** | Staff Sergeant | 125 | Karabiner |
| 4 | **SFC** | Sergeant First Class | 150 | Sturmgewehr, Insurgent |
| 5 | **LT** | Lieutenant | 200 | Scharfschuetzengewehr, Buzzard |
| 6 | **CPT** | Captain | 250 | Leichtes MG, Barrage, Valkyrie, Cargobob, **Kommandozentrale** |
| 7 | **COL** | Colonel | 325 | hoechster Dienstgrad |

Die Grenzen fuer Kommandozentrale und Festnahme liegen in
`Config.BossGrade` und `Config.ArrestGrade`. Die Rangliste selbst steht in
`Config.Ranks` und laesst sich erweitern, kuerzen oder umbenennen — die
Datenbankeintraege muessen dann mitgezogen werden.

---

## Was drin ist

### Dienst

An- und Abmeldung an einem festen Punkt oder per `/armyduty`. Der
Dienstzustand wird serverseitig gefuehrt, weil ESX serverseitig keinen
kennt. Laeuft QBCore, wird er zusaetzlich nach `job.onduty` gespiegelt,
damit andere Ressourcen ihn sehen. Waffenkammer, Fahrzeuge und Festnahme
funktionieren ausschliesslich im Dienst.

### Umkleide

Dienst- und Zivilkleidung. Ist eine Kleidungsressource vorhanden, wird
deren Menue geoeffnet; sonst werden die Komponenten aus der Konfiguration
gesetzt.

### Waffenkammer

Ausruestung und Waffen, jeweils ab einem Dienstgrad freigegeben. Was ein
Spieler noch nicht entnehmen darf, bleibt sichtbar, ist aber ausgegraut und
nennt den benoetigten Rang — so ist der Aufstiegsweg im Spiel erkennbar,
statt einfach zu fehlen.

### Fahrzeugausgabe

Getrennte Ausgabe fuer Land- und Luftfahrzeuge; ein Helikopter laesst sich
nicht an der Landgarage anfordern. Fahrzeuge entstehen serverseitig,
bekommen ein Kennzeichen im Format `ARMYnnnn` und werden als Dienstfahrzeug
markiert. Die Rueckgabe akzeptiert ausschliesslich so markierte Fahrzeuge.
Vor der Ausgabe wird geprueft, ob die Ausgabeposition frei ist.

### Kommandozentrale

Ab Captain, per `/armyboss`. Personal einsehen, Personen in der Naehe
einstellen, entlassen, befoerdern und degradieren sowie Geld aus der
Gesellschaftskasse entnehmen. Rangaenderungen sind nach oben begrenzt:
niemand kann jemanden auf oder ueber den eigenen Rang heben oder
Gleichrangige veraendern.

### Festnahme und Transport

Fesseln, eskortieren, ins Fahrzeug setzen — `/cuff`, `/escort`, `/putin`.
Gefesselte Spieler verlieren Angriff, Zielen, Sprint, Sprung und
Waffenwechsel und spielen eine passende Animation, die auch nach einer
Unterbrechung wieder gesetzt wird. Wer geloest wird, wird zugleich aus der
Eskorte entlassen.

### Sperrgebiet

Ein Militaergelaende mit Radius und Kartenmarkierung. Zivilisten werden beim
Betreten gewarnt, Dienstpersonal erhaelt eine Meldung samt kurzzeitiger
Markierung des Meldeorts. Ein Sperrintervall verhindert Dauerfeuer durch
dieselbe Person.

---

## Installation

1. Ordner nach `resources/nblbnk-usarmy` kopieren.

2. Job in der Datenbank anlegen:

   - **ESX:** `sql/usarmy_esx.sql` einspielen. Legt Job, acht Dienstgrade
     und das Gesellschaftskonto an.
   - **QBCore:** den Eintrag aus `sql/qbcore_jobs.lua` in
     `qb-core/shared/jobs.lua` uebernehmen.

3. In der `server.cfg` eintragen:

   ```cfg
   ensure nblbnk-usarmy
   ```

4. **Koordinaten pruefen.** Die Standorte in `config.lua` liegen im Bereich
   Fort Zancudo, sind aber Naeherungswerte und im Spiel zu ueberpruefen.

5. Server neu starten. Beim Start meldet die Konsole, welches Framework,
   welches Inventar und welches Menuesystem erkannt wurden.

## Bedienung

| Eingabe | Wirkung |
| :--- | :--- |
| Interaktionspunkt | Dienst, Umkleide, Waffenkammer, Fahrzeuge |
| `/armyduty` | Dienst an- oder abmelden |
| `/armyboss` | Kommandozentrale (ab Captain) |
| `/cuff` | naechste Person fesseln oder loesen |
| `/escort` | gefesselte Person eskortieren |
| `/putin` | gefesselte Person ins Fahrzeug setzen |

Alle Kommandos sind ueber **Einstellungen > Tastenbelegung > FiveM** frei
auf Tasten legbar. Ab Werk ist bewusst keine Taste vorbelegt, damit nichts
mit bestehenden Bindungen kollidiert.

## Konfiguration

Es gibt keine im Code fest verdrahteten Positionen, Items, Fahrzeuge oder
Texte. Alles steht kommentiert in der `config.lua`: Jobname, Gesellschaft,
Dienstgrade mit Sold, Standorte, Waffenkammer, Fahrzeuge, Uniform,
Sperrgebiete, Kartenmarkierung und saemtliche Bildschirmtexte.

---

## Sicherheit

Der Client stellt dar, der Server entscheidet. Vor jeder Wirkung prueft der
Server erneut:

- **Job, Dienstgrad und Dienstzustand** werden bei jedem Ereignis frisch
  aus dem Framework gelesen, nie aus einer Angabe des Clients.
- **Abstaende berechnet der Server selbst** ueber `GetEntityCoords` des
  jeweiligen Peds. Eine vom Client mitgesendete Position wird an keiner
  Stelle uebernommen — auch nicht beim Alarm aus dem Sperrgebiet, wo der
  Server die Meldung anhand der ihm bekannten Position gegenprueft.
- **Listenindizes** aus Menues werden auf Typ, Ganzzahligkeit und
  Wertebereich geprueft, bevor sie als Tabellenindex dienen.
- **Fahrzeuge entstehen serverseitig.** Die Markierung als Dienstfahrzeug
  liegt in einem serverseitig gesetzten StateBag und ist damit vom Client
  nicht faelschbar.
- **Kein unnoetiges Netz-Event.** Rein interne Ereignisse sind als lokale
  Handler registriert, damit sie nicht vom Netz ausloesbar sind.

## Stand der Pruefung

Ehrlich benannt, damit niemand ueberrascht wird.

**Geprueft.** Alle Lua-Dateien gegen die Grammatik geparst — fehlerfrei.
Statische Auswertung auf versehentlich globale Bezeichner — global
geschrieben werden ausschliesslich `Config` und `Army`. Vollstaendiger
Abgleich aller Ereignisnamen zwischen Client und Server — kein Ereignis
ohne Empfaenger, kein Empfaenger ohne Ausloeser.

**Nicht geprueft.** Kein Testlauf auf einem FXServer, weder gegen ESX noch
gegen QBCore. Die Koordinaten sind nicht im Spiel verifiziert. Die
Verteilung von Raengen und Ausruestung ist gesetzt, aber nicht erprobt.

## Bekannte Grenzen

- Die **Kommandozentrale zeigt nur verbundene Spieler.** Offline-Personal
  braeuchte direkten Datenbankzugriff, der sich zwischen ESX und QBCore
  unterscheidet.
- Die **Uniform-Rueckfallebene ist unvollstaendig.** Ohne Kleidungsressource
  laesst sich die Zivilkleidung nicht wiederherstellen, weil der
  Ausgangszustand nirgends gespeichert wird.
- **Kein eigenes Soldsystem.** Die Sold-Werte stehen in der Jobdefinition
  und werden vom Framework ausgezahlt.
- **Fahrzeuge werden bei der Rueckgabe geloescht**, nicht in eine
  persistente Garage uebernommen.

---

## Urheber und Lizenz

Copyright (C) 2026 **NebelRebell** — <https://github.com/NebelRebell>

Vollstaendige Eigenentwicklung. Jede Zeile dieser Ressource wurde fuer sie
geschrieben; es wurde kein Code aus anderen Job-Ressourcen uebernommen,
angepasst oder abgeleitet.

Veroeffentlicht unter der **GNU General Public License Version 3 oder
spaeter**, vollstaendiger Text in [`LICENSE`](LICENSE). Wer die Ressource
weitergibt — veraendert oder unveraendert — muss sie ebenfalls unter der
GPL-3.0 stellen, den Quelltext mitliefern und die Urhebervermerke erhalten.
Eine Verwendung in einem verschluesselten oder sonst geschlossenen
Skriptpaket ist ausgeschlossen.
