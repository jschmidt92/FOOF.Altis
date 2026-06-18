if (!isServer) exitWith {};

private _snapshot = [] call FLO_fnc_persistenceLoad;

if (_snapshot isNotEqualTo []) then {
    [_snapshot] call FLO_fnc_persistenceApplySnapshot;
} else {
    diag_log format ["[FLO][Persistence] No saved snapshot found key=%1", FLO_PersistenceKey];
};

FLO_PersistenceHandleDisconnectEh = [
    "FLO_eventHandleDisconnect",
    {
        params ["_unit", "_id", "_uid", "_name"];

        if (!isNull _unit) then {
            [_unit, false] call FLO_fnc_persistenceSavePlayer;
            ["disconnect"] call FLO_fnc_persistenceScheduleSave;
        };
    }
] call CBA_fnc_addEventHandler;

FLO_PersistencePlayerConnectedEh = [
    "FLO_eventPlayerConnected",
    {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [
            {
                params ["_uid", "_owner"];
                [_uid, _owner, 0] call FLO_fnc_persistenceRetryApplyPlayerToOwner;
            },
            [_uid, _owner],
            4
        ] call CBA_fnc_waitAndExecute;
    }
] call CBA_fnc_addEventHandler;

[] call FLO_fnc_persistenceStartLoop;

{
    [getPlayerUID _x, owner _x, 0] call FLO_fnc_persistenceRetryApplyPlayerToOwner;
} forEach allPlayers;

diag_log format [
    "[FLO][Persistence] Persistence initialized key=%1 interval=%2 delay=%3",
    FLO_PersistenceKey,
    FLO_PersistenceSaveInterval,
    FLO_PersistenceEventSaveDelay
];
