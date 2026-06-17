if (!isServer) exitWith {};

FLO_TicketBalances = createHashMapFromArray [
    ["WEST", FLO_TicketInitialBalance],
    ["EAST", FLO_TicketInitialBalance]
];

FLO_TicketPurchasedTotal = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];

FLO_TicketConsumedTotal = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];

FLO_TicketDeathStates = createHashMap;
FLO_TicketRevision = 0;

{
    [_x] call FLO_fnc_ticketTrackPlayer;
} forEach allPlayers;

FLO_TicketPlayerConnectedEh = addMissionEventHandler [
    "PlayerConnected",
    {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [
            {
                {
                    if ((getPlayerUID _x) isEqualTo _this) exitWith {
                        [_x] call FLO_fnc_ticketTrackPlayer;
                    };
                } forEach allPlayers;
            },
            _uid,
            3
        ] call CBA_fnc_waitAndExecute;
    }
];

FLO_TicketEntityKilledEh = addMissionEventHandler [
    "EntityKilled",
    {
        params ["_unit", "_killer", "_instigator", "_useEffects"];
        [_unit, _killer, _instigator, _useEffects] call FLO_fnc_ticketHandleDeath;
    }
];

FLO_TicketEntityRespawnedEh = addMissionEventHandler [
    "EntityRespawned",
    {
        params ["_newEntity", "_oldEntity"];
        [_newEntity] call FLO_fnc_ticketTrackPlayer;
        [_newEntity, _oldEntity] call FLO_fnc_ticketHandleRespawn;
    }
];

diag_log format [
    "[FLO][Tickets] Ticket system initialized initialBalance=%1 respawnCost=%2",
    FLO_TicketInitialBalance,
    FLO_TicketRespawnCost
];
