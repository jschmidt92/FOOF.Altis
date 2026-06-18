params ["_spawnASL", "_dir", "_sideKey", "_cellId", ["_resetPlayerState", false, [false]], ["_uniformClass", "", [""]]];

if (!hasInterface) exitWith {};
if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {};
if (isNull player) exitWith {};

FLO_SpawnClientAssigned = true;

if (_resetPlayerState) then {
    removeAllWeapons player;
    removeAllItems player;
    removeAllAssignedItems player;
    removeUniform player;
    removeVest player;
    removeBackpack player;
    removeHeadgear player;
    removeGoggles player;
    player setDamage 0;
    player setVariable ["FLO_Persistence_Loaded", false, true];
};

player setPosASL _spawnASL;
player setDir _dir;
player setVariable ["FLO_Spawn_Assigned", true];
player setVariable ["FLO_Spawn_AssignedCellId", _cellId];

[player, _uniformClass] call FLO_fnc_spawnEnsureFreshUniform;
[player] call FLO_fnc_spawnEnsureMap;

[getPlayerUID player, _sideKey, _cellId, _resetPlayerState] remoteExecCall ["FLO_fnc_spawnConfirmAssignment", 2];

if (_resetPlayerState) then {
    ["Side changed; old saved equipment was cleared.", "warning", "Persistence"] call FLO_fnc_notify;
};

[format ["Deployed to %1 staging area.", _sideKey], "success", "Deployment"] call FLO_fnc_notify;
