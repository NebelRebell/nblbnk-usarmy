# nblbnk-usarmy

**A military job for FiveM — one install, runs on both ESX and QBCore.**

A complete roleplay job built around a military unit: eight US ranks, a
rank-gated armory, separate ground and air vehicle issue, a command centre for
staff management, restraint with transport, and a monitored restricted area.

Job name in the database: **`usarmy`**

Shipped languages: **English** and **German**, switchable in one line.

---

## One job, both frameworks

There is no ESX build and no QBCore build. The resource works out for itself
what the server is running and adapts. The same applies to inventory, menus,
interaction and clothing — it uses whatever is there instead of demanding it.

| Area | Detected | If none of them is present |
| :--- | :--- | :--- |
| **Framework** | `es_extended`, `qb-core` | resource stays inactive and says so |
| **Inventory** | `ox_inventory`, `qb-inventory` | the framework's stock inventory |
| **Menu** | `ox_lib`, `qb-menu` | the stock ESX menu |
| **Interaction** | `ox_target`, `qb-target` | markers with the **E** key |
| **Clothing** | `illenium-appearance`, `qb-clothing`, `esx_skin` | components from the config |
| **Society account** | `esx_addonaccount`, `qb-management` | balance 0, staff management still works |

Detection runs once at start-up through `GetResourceState` and can be
overridden in `config.lua` for unusual setups. **None of these resources is a
hard dependency** — when one is missing, the matching fallback takes over and
nothing breaks.

---

## Ranks

Eight tiers modelled on the US structure. Every rank controls which weapons
and vehicles are reachable.

| Grade | Short | Rank | Pay | Unlocks |
| ---: | :--- | :--- | ---: | :--- |
| 0 | **PVT** | Private | 50 | knife, pistol, body armour, bandages, Crusader |
| 1 | **SPC** | Specialist | 75 | handcuffs, restraint and transport |
| 2 | **SGT** | Sergeant | 100 | shotgun, Barracks |
| 3 | **SSG** | Staff Sergeant | 125 | carbine rifle |
| 4 | **SFC** | Sergeant First Class | 150 | assault rifle, Insurgent |
| 5 | **LT** | Lieutenant | 200 | sniper rifle, Buzzard |
| 6 | **CPT** | Captain | 250 | light machine gun, Barrage, Valkyrie, Cargobob, **command centre** |
| 7 | **COL** | Colonel | 325 | highest rank |

The thresholds for the command centre and for restraint live in
`Config.BossGrade` and `Config.ArrestGrade`. The rank list itself is
`Config.Ranks` and can be extended, shortened or renamed — the database
entries have to follow.

---

## What is in it

### Duty

Clock in and out at a fixed point or with `/armyduty`. The duty state is kept
server side, because ESX has no server side equivalent. On QBCore it is
additionally mirrored into `job.onduty` so other resources can see it. Armory,
vehicles and restraint only work while on duty.

### Locker room

Uniform and civilian clothing. When a clothing resource is present its own
menu opens; otherwise the components from the configuration are applied.

### Armory

Equipment and weapons, each released from a given rank. Anything a player
cannot take yet stays visible but greyed out and names the rank required — so
the progression is readable in game instead of simply being absent.

### Vehicle issue

Separate issue points for ground and air; a helicopter cannot be requested at
the ground garage. Vehicles are created server side, get a plate in the format
`ARMYnnnn` and are flagged as service vehicles. Returning only accepts
vehicles carrying that flag. The issue position is checked for obstructions
first.

### Command centre

From Captain upwards, via `/armyboss`. Review staff, hire nearby people,
dismiss, promote and demote, and withdraw from the society account. Rank
changes are capped: nobody can lift anyone to or above their own rank, or
touch an equal.

### Restraint and transport

Restrain, escort, put into a vehicle — `/cuff`, `/escort`, `/putin`.
Restrained players lose attack, aim, sprint, jump and weapon switching, and
play a matching animation that is re-applied if something interrupts it.
Releasing someone also ends the escort.

### Restricted area

A military zone with a radius and a map overlay. Civilians are warned on
entry, on-duty personnel get an alert with a temporary marker at the reported
position. A cooldown stops the same person triggering it repeatedly.

---

## Languages

Two locales ship with the resource: `locales/en.lua` and `locales/de.lua`.
Switch with one line in `config.lua`:

```lua
Config.Locale = 'en'   -- or 'de'
```

Nothing user-facing is hardcoded — messages, menu titles, point names and
armory entries all come from the locale files. Missing keys fall back to
English, so a partial translation never produces blank text.

**Adding a language:** copy `locales/en.lua` to `locales/<code>.lua`, translate
the values, add the file to `fxmanifest.lua` and set `Config.Locale`.

Rank names, vehicle models and place names stay untranslated on purpose —
they are proper nouns.

Messages sent by the server travel as locale keys, not as finished text, so
each player reads them in the language their own client is set to.

---

## Installation

1. Copy the folder to `resources/nblbnk-usarmy`.

2. Create the job in the database:

   - **ESX:** import `sql/usarmy_esx.sql`. Creates the job, the eight ranks
     and the society account.
   - **QBCore:** copy the entry from `sql/qbcore_jobs.lua` into
     `qb-core/shared/jobs.lua`.

3. Add to your `server.cfg`:

   ```cfg
   ensure nblbnk-usarmy
   ```

4. **Check the coordinates.** The locations in `config.lua` sit around Fort
   Zancudo but are approximations and need verifying in game.

5. Restart the server. On start-up the console reports which framework,
   inventory, menu system and locale were detected.

## Usage

| Input | Effect |
| :--- | :--- |
| Interaction point | duty, locker room, armory, vehicles |
| `/armyduty` | clock in or out |
| `/armyboss` | command centre (Captain and above) |
| `/cuff` | restrain or release the nearest person |
| `/escort` | escort a restrained person |
| `/putin` | put a restrained person into a vehicle |

All commands can be bound to keys under **Settings > Key Bindings > FiveM**.
No key is bound by default, deliberately, so nothing collides with existing
bindings.

## Configuration

No positions, items, vehicles or texts are hardcoded. Everything is commented
in `config.lua`: locale, job name, society, ranks with pay, locations, armory,
vehicles, uniform, restricted zones and the map blip.

---

## Security

The client presents, the server decides. Before anything takes effect the
server re-checks:

- **Job, rank and duty state** are read fresh from the framework on every
  event, never from a client claim.
- **Distances are computed by the server** from `GetEntityCoords` of the ped
  in question. A position sent by the client is not used anywhere — including
  the restricted area alert, where the server verifies the report against the
  position it knows.
- **List indices** from menus are validated for type, integerness and range
  before being used as a table index.
- **Vehicles are created server side.** The service vehicle flag lives in a
  state bag written by the server and cannot be forged by a client.
- **No unnecessary net events.** Purely internal events are registered as
  local handlers so they cannot be triggered over the network.

## Testing status

Stated plainly so nobody is caught out.

**Verified.** All Lua files parse cleanly against the grammar. Static analysis
for accidental globals: the only globals written are `Config`, `Army` and
`Locales`. Full cross-check of every event name between client and server: no
event without a receiver, no receiver without a sender. Both locale files
checked for key parity.

**Not verified.** No test run on a live FXServer, against neither ESX nor
QBCore. The coordinates have not been confirmed in game. The distribution of
ranks and equipment is set but untested in play.

## Known limits

- The **command centre only lists connected players.** Offline staff would
  require direct database access, which differs between ESX and QBCore.
- The **uniform fallback is incomplete.** Without a clothing resource the
  civilian outfit cannot be restored, because the original state is never
  stored.
- **No pay system of its own.** The pay values live in the job definition and
  are paid out by the framework.
- **Returned vehicles are deleted**, not moved into a persistent garage.

---

## Author and licence

Copyright (C) 2026 **NebelRebell** — <https://github.com/NebelRebell>

Entirely original work. Every line of this resource was written for it; no
code was taken, adapted or derived from any other job resource.

Released under the **GNU General Public License version 3 or later**, full
text in [`LICENSE`](LICENSE). Anyone redistributing this resource — modified
or not — must also release it under the GPL-3.0, ship the source, and keep the
copyright notices intact. Bundling it into an encrypted or otherwise closed
script package is not permitted.
