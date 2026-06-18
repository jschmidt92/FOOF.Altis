if (!isServer) exitWith {};

FLO_EventPlayerConnectedEh = addMissionEventHandler [
    "PlayerConnected",
    {
        ["FLO_eventPlayerConnected", _this] call CBA_fnc_localEvent;
    }
];

FLO_EventPlayerDisconnectedEh = addMissionEventHandler [
    "PlayerDisconnected",
    {
        ["FLO_eventPlayerDisconnected", _this] call CBA_fnc_localEvent;
    }
];

FLO_EventHandleDisconnectEh = addMissionEventHandler [
    "HandleDisconnect",
    {
        ["FLO_eventHandleDisconnect", _this] call CBA_fnc_localEvent;
        false
    }
];

FLO_EventEntityKilledEh = addMissionEventHandler [
    "EntityKilled",
    {
        ["FLO_eventEntityKilled", _this] call CBA_fnc_localEvent;
    }
];

FLO_EventEntityRespawnedEh = addMissionEventHandler [
    "EntityRespawned",
    {
        ["FLO_eventEntityRespawned", _this] call CBA_fnc_localEvent;
    }
];

diag_log "[FLO][Events] CBA event adapter initialized";
