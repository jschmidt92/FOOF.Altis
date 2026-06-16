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
- Area objectives generated from capitals, cities, villages, local places, airfields, and strategic locations.
- Small AO type/status markers instead of oversized city markers or dense city outlines.
- Frontline-only sector capture: enemy sectors must be adjacent to friendly control before they can flip.
- Randomized fair deployment zones choose opposing BLUFOR/OPFOR starts from valid generated grid cells each match.
- Initial legal entry cells are derived from those deployment zones so the first frontline begins from the generated starts.
- Slow spearhead-style pressure from captured cells.
- Slow encirclement pressure against isolated owned cells.
- Server-owned BLUFOR/OPFOR currency generated from controlled grid cells and high-value objectives.
- Server-authoritative commander and faction voting for BLUFOR and OPFOR with timed startup and replacement commander vote windows.
- Simple HTML command vote dialog using Arma's web browser control.
- First FOB per BLUFOR/OPFOR side is placed by the elected side commander; later FOBs spend faction currency.
- Commander-deployed COPs provide cheaper forward combat outposts with limited build categories and conditional respawn support.
- Custom deployment panel for FOB/COP placement opens through the CBA keybind `Ctrl+Shift+D` by default.
- IDS Logistics build menu attached to friendly base buildings for commander-authorized construction.
- Server-validated logistics placement, movement, and deletion inside friendly base build areas.
- Store attached to friendly FOB buildings for commander-authorized faction equipment and vehicle purchases.
- Store catalogs are generated from the selected faction's loaded config classes; no player-edited store definition files are required.
- Store uses a cinematic tactical armory UI with item previews, equipment/cart summaries, personal saved kits, and clickable cart targets for putting ammo/items into uniform, vest, or backpack during checkout.
- Store vehicle checkout creates a pending vehicle placement; the player places the purchased vehicle with the IDS camera inside the purchase FOB build radius.
- Server-owned BLUFOR/OPFOR ticket pools control respawn allowance; respawns spend one side ticket.
- Commanders can buy reinforcement ticket packs from the Store with faction currency.
- Server-authenticated objective updates for normal play, with full snapshots for startup and reconnects.

## Development

- Addon root: `addons/main`
- Addon config: `addons/main/config.cpp`
- Command/faction voting: `addons/main/functions/command/`
- Objective system: `addons/main/functions/objectives/`
- Resource system: `addons/main/functions/resources/`
- FOB/COP base system: `addons/main/functions/fob/`
- Spawn/deployment system: `addons/main/functions/spawns/`
- Store system: `addons/main/functions/store/`
- Ticket system: `addons/main/functions/tickets/`
- IDS Logistics: `addons/main/IDS_Logistics/`
- Command vote UI: `addons/main/ui/command/`
- Deployment UI: `addons/main/ui/deploy/`
- Store UI: `addons/main/ui/store/`
- Startup: addon `postInit` during normal missions; Arma engine intro missions are skipped.
- Dev test mission: `missions/FOOF_Test.Altis`

## Building and Testing

Use HEMTT to build or launch the FOOF addon with CBA_A3. The default launch profile opens the included Altis test mission shell, but the addon systems are registered from `addons/main` and are not tied to root mission files.

HEMTT project config is included for local addon checks and launch workflow.

```powershell
.\.tools\hemtt\hemtt.exe check
.\.tools\hemtt\hemtt.exe build --no-bin --no-rap
.\.tools\hemtt\hemtt.exe launch
```

## Known Issues

FOOF is not gameplay-complete yet. Respawn waves, victory rules, commander-granted roles, external persistence backends, and full match flow are still foundation work.
