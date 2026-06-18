if (!isServer) exitWith {};

FLO_SpawnSideAssignmentCounts = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_SpawnPlayerAssignments = createHashMap;
FLO_SpawnStagingRespawnHandles = createHashMapFromArray [
    ["WEST", []],
    ["EAST", []]
];

private _westZone = FLO_DeploymentZones get "WEST";
private _eastZone = FLO_DeploymentZones get "EAST";

FLO_SpawnAssignmentReady = true;
[] call FLO_fnc_spawnSyncStagingRespawns;

FLO_SpawnPlayerConnectedEh = [
    "FLO_eventPlayerConnected",
    {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [
            {
                params ["_uid", "_owner"];
                [_uid, _owner] call FLO_fnc_spawnSyncConnectedPlayer;
            },
            [_uid, _owner],
            3
        ] call CBA_fnc_waitAndExecute;
    }
] call CBA_fnc_addEventHandler;

diag_log format [
    "[FLO][Spawn] Spawn assignment system initialized westCell=%1 eastCell=%2",
    _westZone get "cellId",
    _eastZone get "cellId"
];
