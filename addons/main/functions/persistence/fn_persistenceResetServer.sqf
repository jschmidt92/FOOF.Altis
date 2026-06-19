params [
    ["_broadcastNotice", true, [false]],
    ["_reason", "manual", [""]]
];

if (!isServer) exitWith { false };

FLO_PersistenceEnabled = false;
FLO_PersistenceDirty = false;
FLO_PersistenceSaveScheduled = false;
FLO_PersistenceLoaded = false;
FLO_PersistencePlayerRecords = createHashMap;

if (FLO_PersistenceLoopHandle isNotEqualTo -1) then {
    [FLO_PersistenceLoopHandle] call CBA_fnc_removePerFrameHandler;
    FLO_PersistenceLoopHandle = -1;
};

missionProfileNamespace setVariable [FLO_PersistenceKey, nil];
saveMissionProfileNamespace;

FLO_PersistenceResetPending = true;
publicVariable "FLO_PersistenceResetPending";

private _postReadMissing = isNil { missionProfileNamespace getVariable FLO_PersistenceKey };

diag_log format [
    "[FLO][Persistence] Wiped mission persistence key=%1 reason=%2 storage=missionProfileNamespace postReadMissing=%3 serverProcessRestartRequired=true",
    FLO_PersistenceKey,
    _reason,
    _postReadMissing
];

if (_broadcastNotice) then {
    [createHashMapFromArray [
        ["mode", "announce"],
        ["title", "Persistence Reset"],
        ["message", "Mission state wiped. Restart the dedicated server process to complete the reset."],
        ["type", "warning"],
        ["duration", 8]
    ]] call FLO_fnc_notificationBroadcast;
};

true
