# FOOF

## About

A PvP-focused Arma 3 milsim gamemode for realistic whole-map terrain control, maneuver, and team-driven combat.

## Project Status

FOOF is in early foundation development.

The current foundation is a server-authoritative objective system with a generated land-only sector grid. Major locations act as high-value objectives while surrounding grid cells create a tug-of-war layer for flanks, approaches, defensive depth, encirclement, and spearhead movement.

FOOF currently requires CBA_A3.

## License and Reuse

FOOF is public for visibility, development tracking, and official release access, but it is not open source.

Forward Offensive, also known as FOOF, is proprietary and all rights are reserved by Frontline Operations Development Group. No permission is granted to copy, modify, redistribute, reupload, repack, host, sell, sublicense, or create derivative versions of this project without prior written permission.

Official public releases may be downloaded and used only for playing Forward Offensive through authorized releases, servers, or events.

See `LICENSE.md` for the full license terms.

## Features

- Persistent 24/7 PvP campaign state
- Grid-based territory control across the map
- Major AO system for towns, villages, ports, terminals, capitals, and strategic areas
- Frontline-focused capture rules
- AO pressure and assault windows
- FOB and COP deployment systems
- Commander voting and faction selection
- Faction-based Store with weapons, gear, vehicles, kits, tickets, and support items
- Faction currency and income from controlled territory
- AO upgrade levels that increase value and defensive strength
- Ticket-based respawns
- Friendly FOB/COP respawn network
- Intel system for searching enemy bodies
- Notification and announcement framework

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

### Resetting Persistence

FOOF persistence lives under the server's `missionProfileNamespace` key for the active world. Deleting profile files while the mission is running can fail because the live server state may save itself again.

From a server-side console:

```sqf
[true, "admin reset"] call FLO_fnc_persistenceResetServer;
```

From a logged-in admin client debug console:

```sqf
[player, true] remoteExecCall ["FLO_fnc_persistenceRequestReset", 2];
```

Both forms disable persistence, stop the persistence save loop, clear the active save key, flush `missionProfileNamespace`, and notify players when the first argument is `true`. Complete the wipe by restarting the dedicated server process from the host panel. Arma's in-game `#restart` only restarts the mission and can reload stale mission-profile state.

## Known Issues

FOOF is not gameplay-complete yet. Respawn waves, victory rules, external persistence backends, and full match flow are still foundation work.
