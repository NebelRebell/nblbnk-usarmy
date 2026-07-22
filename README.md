# nblbnk_army

US-Army-Job fuer FiveM. Die Ressource erkennt selbst, ob **ESX** oder
**QBCore** auf dem Server laeuft, und passt sich ebenso an das vorhandene
Inventar-, Menue- und Interaktionssystem an. Es gibt keine getrennten
Fassungen je Framework.

Jobname in der Datenbank: **`usarmy`**

---

## Was die Ressource kann

**Dienst.** An- und Abmeldung an einem festen Punkt. Der Dienstzustand wird
serverseitig gefuehrt und bei QBCore zusaetzlich in `job.onduty`
gespiegelt, damit andere Ressourcen ihn sehen.

**Umkleide.** Dienst- und Zivilkleidung. Ist `illenium-appearance`,
`qb-clothing` oder `esx_skin` vorhanden, wird deren Menue verwendet;
andernfalls greifen die Komponenten aus der Konfiguration.

**Waffenkammer.** Ausruestung und Waffen, jeweils ab einem festgelegten
Dienstgrad. Was ein Spieler nicht entnehmen darf, erscheint ausgegraut mit
Angabe des benoetigten Rangs.

**Fahrzeugausgabe.** Getrennte Ausgabe fuer Land- und Luftfahrzeuge, je
Dienstgrad freigeschaltet. Fahrzeuge werden serverseitig erzeugt, mit
Kennzeichen `ARMYnnnn` versehen und als Dienstfahrzeug markiert. Die
Rueckgabe akzeptiert nur so markierte Fahrzeuge.

**Kommandozentrale.** Ab dem konfigurierten Rang: Personal einsehen,
einstellen, entlassen, befoerdern und degradieren sowie Geld aus der
Gesellschaftskasse entnehmen.

**Festnahme und Transport.** Fesseln, eskortieren und ins Fahrzeug setzen.
Gefesselte Spieler verlieren die relevanten Steuerungen und spielen eine
passende Animation.

**Sperrzone.** Ein Militaergelaende mit Radius. Zivilisten werden beim
Betreten gewarnt, Dienstpersonal erhaelt eine Meldung samt kurzzeitiger
Kartenmarkierung.

## Dienstgrade

| Grad | Kuerzel | Bezeichnung | Sold |
| ---: | :--- | :--- | ---: |
| 0 | PVT | Private | 50 |
| 1 | SPC | Specialist | 75 |
| 2 | SGT | Sergeant | 100 |
| 3 | SSG | Staff Sergeant | 125 |
| 4 | SFC | Sergeant First Class | 150 |
| 5 | LT | Lieutenant | 200 |
| 6 | CPT | Captain | 250 |
| 7 | COL | Colonel | 325 |

Ab **CPT** steht die Kommandozentrale offen, ab **SPC** die Festnahme.
Beides ist ueber `Config.BossGrade` und `Config.ArrestGrade` anpassbar.

---

## Unterstuetzte Umgebungen

Erkannt wird beim Start ueber `GetResourceState`, ohne Konfigurationsaufwand.
Jede Erkennung laesst sich in der `config.lua` uebersteuern.

| Bereich | Erkannt wird | Rueckfallebene |
| :--- | :--- | :--- |
| Framework | `es_extended`, `qb-core` | keine, die Ressource bleibt inaktiv |
| Inventar | `ox_inventory`, `qb-inventory` | Standardinventar des Frameworks |
| Menue | `ox_lib`, `qb-menu` | ESX-Standardmenue |
| Interaktion | `ox_target`, `qb-target` | Marker mit Taste **E** |
| Kleidung | `illenium-appearance`, `qb-clothing`, `esx_skin` | Komponenten aus der Konfiguration |
| Kasse | `esx_addonaccount`, `qb-management` | Kassenstand 0, Entnahme nicht moeglich |

Findet die Ressource weder `es_extended` noch `qb-core`, schreibt sie eine
Meldung in die Konsole und bleibt untaetig, statt mit Fehlern zu starten.

## Installation

1. Ordner nach `resources/nblbnk_army` kopieren.

2. Job in der Datenbank anlegen:
   - **ESX:** `sql/usarmy_esx.sql` einspielen.
   - **QBCore:** den Block aus `sql/qbcore_jobs.lua` nach
     `qb-core/shared/jobs.lua` uebernehmen.

3. In der `server.cfg` eintragen:

   ```cfg
   ensure nblbnk_army
   ```

4. **Koordinaten pruefen.** Die Standorte in `config.lua` liegen im Bereich
   Fort Zancudo, sind aber **Naeherungswerte** und im Spiel zu ueberpruefen.

5. Server neu starten.

## Bedienung

| Eingabe | Wirkung |
| :--- | :--- |
| Interaktionspunkt | Dienst, Umkleide, Waffenkammer, Fahrzeuge |
| `/armyduty` | Dienst an- oder abmelden |
| `/armyboss` | Kommandozentrale |
| `/cuff` | naechste Person fesseln oder loesen |
| `/escort` | gefesselte Person eskortieren |
| `/putin` | gefesselte Person ins Fahrzeug setzen |

`/cuff`, `/escort`, `/putin` und `/armyboss` sind ueber
**Einstellungen > Tastenbelegung > FiveM** frei auf Tasten legbar; ab Werk
ist keine Taste vorbelegt, um Konflikte zu vermeiden.

## Konfiguration

Alles liegt in `config.lua` und ist dort kommentiert: Jobname, Gesellschaft,
Dienstgrade mit Sold, Standorte, Waffenkammer, Fahrzeuge, Uniform,
Sperrzonen, Kartenmarkierung und saemtliche Texte.

---

## Sicherheitsmodell

Der Client stellt ausschliesslich dar. Jede Aktion wird serverseitig erneut
geprueft, bevor sie wirkt:

- **Jobzugehoerigkeit, Dienstgrad und Dienstzustand** werden bei jedem
  Ereignis frisch aus dem Framework gelesen, nicht aus einer
  zwischengespeicherten Angabe des Clients.
- **Naehe wird serverseitig berechnet**, ueber `GetEntityCoords` des
  jeweiligen Peds. Eine vom Client mitgesendete Position wird nirgends
  uebernommen. Das gilt auch fuer den Zonenalarm.
- **Listenindizes** aus Menues werden auf Typ, Ganzzahligkeit und
  Wertebereich geprueft, bevor sie als Index verwendet werden.
- **Fahrzeuge** entstehen serverseitig. Die Markierung als Dienstfahrzeug
  liegt in einem serverseitig gesetzten StateBag und ist damit nicht vom
  Client faelschbar.
- **Rangaenderungen** sind nach oben begrenzt: niemand kann jemanden auf
  oder ueber den eigenen Rang heben oder Gleichrangige veraendern.

## Bekannte Einschraenkungen

- **Die Koordinaten sind ungeprueft.** Sie wurden nicht im Spiel
  verifiziert und muessen vor dem produktiven Einsatz angepasst werden.
- **Die Ressource wurde nicht auf einem laufenden FXServer getestet.**
  Geprueft sind ausschliesslich Syntax und statische Konsistenz, siehe
  unten. Ein Testlauf gegen ESX und QBCore steht aus.
- **Das Boss-Menue zeigt nur verbundene Spieler.** Offline-Personal
  erfordert einen direkten Datenbankzugriff, der sich zwischen ESX und
  QBCore unterscheidet und bewusst nicht eingebaut wurde.
- **Die Uniform-Rueckfallebene ist unvollstaendig.** Ohne Kleidungsressource
  kann die Zivilkleidung nicht wiederhergestellt werden, weil der
  Ausgangszustand nirgends gespeichert wird.
- **Kein Soldsystem.** Die Sold-Werte stehen in der Datenbank und werden
  vom Framework ausgezahlt, nicht von dieser Ressource.
- **Fahrzeuge werden bei der Rueckgabe geloescht**, nicht in eine
  persistente Garage uebernommen.

## Pruefstand

Was tatsaechlich geprueft wurde:

- Alle 12 Lua-Dateien mit `luaparse` gegen die Grammatik geparst: fehlerfrei.
- AST-Auswertung auf globale Bezeichner: global geschrieben werden
  ausschliesslich `Config` und `Army`. Alle globalen Lesezugriffe sind
  FiveM-Natives oder die CitizenFX-Globals `vec3`, `vec4`, `exports`,
  `source`, `joaat`.
- Abgleich aller Event-Namen zwischen Client und Server: jedes per
  `TriggerServerEvent` ausgeloeste Ereignis hat einen serverseitigen
  Empfaenger und umgekehrt.

Was **nicht** geprueft wurde: Laufzeitverhalten, Koordinaten,
Framework-Integration, Inventar-Integration, Balance der Rangvergabe.

---

## Urheber und Lizenz

Copyright (C) 2026 NebelRebell, <https://github.com/NebelRebell>

Veroeffentlicht unter der **GNU General Public License Version 3 oder
spaeter**. Der vollstaendige Lizenztext liegt in [`LICENSE`](LICENSE).

Wer diese Ressource weitergibt - veraendert oder unveraendert - muss sie
ebenfalls unter der GPL-3.0 stellen, den Quelltext mitliefern und die
Urhebervermerke erhalten. Eine Verwendung in einem verschluesselten oder
sonst geschlossenen Skriptpaket ist damit ausgeschlossen.

Die Ressource ist eine Neuentwicklung. Sie enthaelt keinen Code aus
`esx_policejob` oder anderen bestehenden Job-Ressourcen.

### Vorgeschichte

Dieses Repository hiess urspruenglich `esx_armee` und war vollstaendig
leer: kein Commit, keine Datei, lediglich die Beschreibung *"FiveM
Roleplay-Job from esx_policejob to esx_armee (army)"*. Umbenannt und mit
diesem Neubau gefuellt am 2026-07-22.
