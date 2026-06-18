# FOOF

## About

A PvP-focused Arma 3 milsim gamemode for realistic whole-map terrain control, maneuver, and team-driven combat.

## Project Status

FOOF is in early foundation development.

The current foundation is a server-authoritative objective system with a generated land-only sector grid. Major locations act as high-value objectives while surrounding grid cells create a tug-of-war layer for flanks, approaches, defensive depth, encirclement, and spearhead movement.

FOOF currently requires CBA_A3.

## Features

- Server-authoritative objective state.
- Generated land-only square control grid.
- Player-facing map visualizer for sectors, ownership, contesting, and capture pressure.
- Area objectives generated from map labels including capitals, cities, villages, local places, airfields, strategic locations, and coastal/marine labels when they resolve to playable land.
- AO generation uses map label footprint sizes and overlap-aware grid claims so nearby places like towns, terminals, ports, and villages can coexist instead of being deleted by a flat spacing rule.
- Capped built-up-area enrichment is enabled to promote dense unlabeled compounds into low-value AOs without requiring player-edited objective files; the first-pass profile is deliberately conservative and logs startup timing/scan diagnostics.
- Quiet AO map layer with ownership halos and level-only objective labels so Arma's native town labels stay readable.
- Frontline-only sector capture: enemy sectors must be adjacent to friendly control before they can flip.
- Randomized fair deployment zones choose opposing BLUFOR/OPFOR starts from valid generated grid cells each match.
- Initial legal entry cells are derived from those deployment zones so the first frontline begins from the generated starts.
- Initial player deployment waits for generated deployment zones to be ready on the server before teleporting clients.
- Deployment assignment searches for a dry position inside the generated staging cell, so editor-placed playable units are only temporary mission placeholders.
- Dedicated clients retry initial deployment until the server assignment or persisted player restore is actually applied, and the server also resyncs spawn assignment after player connect.
- Fresh deployment and normal respawn always give the player a map if they do not already have one, plus a uniform from the side's selected Store faction when available; persisted player kits restore exactly as saved.
- Generated BLUFOR/OPFOR staging cells are registered as temporary respawn positions until that side places its first FOB/COP.
- Respawn uses Arma `MenuPosition` with server-registered staging, FOB, and active COP positions; staging remains as a fallback whenever a side has no active base respawn.
- Slow spearhead-style pressure from captured cells.
- Slow encirclement pressure against isolated owned cells.
- Player-driven sector capture is tuned around one minute under uncontested pressure; natural spread and encirclement are deliberately slower so players remain the primary way to move the frontline.
- Server-owned BLUFOR/OPFOR currency starts at `$5000` and is generated from controlled grid cells and upgraded high-value objectives.
- Captured AOs have levels from `0` to `5`; commander-authorized players can start timed upgrades on friendly uncontested AOs from inside the AO.
- AO upgrades harden linked sectors: capturing a linked sector takes `60s + 30s` per defending AO level, and attackers must control a larger share of linked sectors to flip upgraded AOs.
- Frontline AO pressure adds a siege layer: sustained enemy presence in linked cells and captured support/anchor cells slowly build pressure; at full pressure the AO becomes vulnerable for 45 minutes and upgrade hardening is weakened.
- AO pressure reports stay minimal: normal players are notified when an AO reaches the contact line and when an assault window opens or closes. Exact pressure values stay in the AO panel.
- Enemy capture or destabilization reduces an AO by one level instead of wiping it. If the previous owner recaptures it within 30 minutes, the original level is restored.
- A compact in-world AO panel opens with `Ctrl+Shift+O` while standing inside an AO and shows owner, level, income per 15 minutes, upgrade cost, upgrade timer, and upgrade availability.
- Server-authoritative commander and faction voting for BLUFOR and OPFOR with timed startup and replacement commander vote windows.
- Startup commander/faction votes resolve to a deterministic fallback on expiry so a side cannot leave opening votes without command or faction setup.
- HTML command panel using Arma's web browser control for commander/faction voting and commander-managed side roles.
- Command panel can be reopened with `Ctrl+Shift+C`; elected commanders can assign one deputy commander plus scaling medic, doctor, and engineer slots.
- Command roles are server-owned, persisted, and reapplied on reconnect/respawn; ACE medical and repair role variables are applied as effects for assigned medics, doctors, and engineers.
- Command voting opens after players enter the mission view, not during the post-lobby Continue screen.
- Dedicated clients retry command snapshot requests until their real BLUFOR/OPFOR side snapshot arrives, and the server resyncs command state after player connect so initial votes open reliably for both sides.
- First FOB per BLUFOR/OPFOR side is placed by the elected side commander; later FOBs spend faction currency.
- Commander-deployed COPs provide cheaper forward combat outposts with limited build categories and conditional respawn support.
- Custom deployment panel for FOB/COP placement opens through the CBA keybind `Ctrl+Shift+D` by default.
- IDS Logistics build menu attached to friendly base buildings for commander-authorized construction.
- Server-validated logistics placement, movement, and deletion inside friendly base build areas.
- Store attached to friendly FOB buildings for same-side faction equipment and vehicle purchases.
- Store catalogs are generated from the selected faction's loaded config classes; no player-edited store definition files are required.
- Store catalogs also append optional support gear without player-edited definitions: reviewed vanilla GPS and cTab/NSWDG device classes plus source-filtered ACRE/TFAR radio and ACE/KAT/ACM support items when those mods are loaded. Optional support mods follow a Forge-style model: detect the loaded `CfgPatches` entry, then include visible classes whose class/source tokens match that mod.
- Vanilla Arma chat and voice channels are disabled addon-side for all clients. When ACRE is loaded, FOOF enables side-separated Babel languages and side-separated radio frequencies so BLUFOR and OPFOR start on isolated comms.
- Store uses a cinematic tactical armory UI with item previews, equipment/cart summaries, personal saved kits, and clickable cart targets for putting ammo/items into uniform, vest, or backpack during checkout.
- Store vehicle checkout creates a pending vehicle placement; the player places the purchased vehicle with the IDS camera inside the purchase FOB build radius.
- Empty Store-purchased friendly vehicles and captured enemy vehicles can be recovered at friendly bases for partial money returns.
- Server-owned BLUFOR/OPFOR ticket pools control respawn allowance; respawns spend one side ticket.
- Commanders can buy reinforcement ticket packs from the Store with faction currency; ticket packs are commander-only.
- Native notification and announcement framework replaces ad hoc hints for player-facing feedback.
- Announcements render as compact top-center command banners, while normal notifications stack as smaller right-side tactical cards.
- Objective pressure alerts are state-change driven and side-specific so players only get meaningful contact-line and assault-window reports.
- Central CBA event adapter normalizes player connect/disconnect, disconnect handling, entity death, and entity respawn into shared `FLO_event*` events so gameplay systems do not each install raw Bohemia mission handlers.
- Dead enemy player bodies can be searched through a compact HTML intel panel; the server decides whether the body has no intel, enemy movement intel, or rare FOB/COP radius intel.
- Recovered intel creates temporary local map-radius markers instead of exact enemy positions.
- Server-authenticated objective updates for normal play, with full snapshots for startup and reconnects.

## Development

- Addon root: `addons/main`
- Addon config: `addons/main/config.cpp`
- Event adapter: `addons/main/functions/events/`
- Command/faction voting: `addons/main/functions/command/`
- Objective system: `addons/main/functions/objectives/`
- Resource system: `addons/main/functions/resources/`
- FOB/COP base system: `addons/main/functions/fob/`
- Spawn/deployment system: `addons/main/functions/spawns/`
- Store system: `addons/main/functions/store/`
- Ticket system: `addons/main/functions/tickets/`
- Notification system: `addons/main/functions/notifications/`
- Intel system: `addons/main/functions/intel/`
- IDS Logistics: `addons/main/IDS_Logistics/`
- Command vote UI: `addons/main/ui/command/`
- Deployment UI: `addons/main/ui/deploy/`
- Intel UI: `addons/main/ui/intel/`
- Store UI: `addons/main/ui/store/`
- AO info UI: `addons/main/ui/objective/`
- Startup: addon `postInit` during normal missions; Arma engine intro missions are skipped.
- Dev test mission: `missions/FOOF_Test.Altis`

Gameplay systems should subscribe to CBA `FLO_event*` events instead of adding their own raw Bohemia mission event handlers. The only raw mission event adapter should live in `addons/main/functions/events/`. UI display input handlers may still use Arma display handlers where that is the correct UI API.

## Building and Testing

Use HEMTT to build or launch the FOOF addon with CBA_A3. The default launch profile opens the included Altis test mission shell, but the addon systems are registered from `addons/main` and are not tied to root mission files.

Any playable mission shell used to host FOOF needs respawn configured as custom positions with `MenuPosition`, respawn dialog enabled, and respawn on start disabled; the included test shell and root dev shell both include those settings.

HEMTT project config is included for local addon checks and launch workflow.

```powershell
.\.tools\hemtt\hemtt.exe check
.\.tools\hemtt\hemtt.exe build --no-bin --no-rap
.\.tools\hemtt\hemtt.exe launch
```

## Known Issues

FOOF is not gameplay-complete yet. Respawn waves, victory rules, external persistence backends, and full match flow are still foundation work.
