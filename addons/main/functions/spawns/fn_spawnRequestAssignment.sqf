params ["_player", ["_attempt", 0], ["_requestOwner", remoteExecutedOwner]];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _owner = owner _player;

if ((_requestOwner > 2) && {_owner isNotEqualTo _requestOwner}) exitWith {
    if ((_owner <= 2) && {_attempt < 20}) exitWith {
        [
            {
                params ["_player", "_attempt", "_requestOwner"];
                [_player, _attempt + 1, _requestOwner] call FLO_fnc_spawnRequestAssignment;
            },
            [_player, _attempt, _requestOwner],
            0.5
        ] call CBA_fnc_waitAndExecute;
    };

    diag_log format [
        "[FLO][Spawn] Rejected spawn assignment request from owner %1 for owner %2",
        _requestOwner,
        _owner
    ];
};

private _side = side group _player;

if !(_side in [west, east]) exitWith {
    if (_attempt < 20) exitWith {
        [
            {
                params ["_player", "_attempt", "_requestOwner"];
                [_player, _attempt + 1, _requestOwner] call FLO_fnc_spawnRequestAssignment;
            },
            [_player, _attempt, _requestOwner],
            0.5
        ] call CBA_fnc_waitAndExecute;
    };
};

if (!FLO_SpawnAssignmentReady) exitWith {
    if (_attempt < 120) exitWith {
        [
            {
                params ["_player", "_attempt", "_requestOwner"];
                [_player, _attempt + 1, _requestOwner] call FLO_fnc_spawnRequestAssignment;
            },
            [_player, _attempt, _requestOwner],
            0.5
        ] call CBA_fnc_waitAndExecute;
    };

    diag_log format [
        "[FLO][Spawn] Timed out assigning deployment spawn for %1 owner=%2; deployment zones are not ready",
        name _player,
        _owner
    ];
};

private _ticketBalance = [_side] call FLO_fnc_ticketSideBalance;
private _ticketLocked = _ticketBalance <= 0;

[_player, _ticketLocked, ""] call FLO_fnc_ticketSyncPlayer;

private _uid = getPlayerUID _player;
private _restoredPersistence = false;
private _sideKey = [_side] call FLO_fnc_objectiveSideKey;

if ((_uid isNotEqualTo "") && {_uid in FLO_PersistencePlayerRecords}) then {
    _restoredPersistence = [_uid, _owner] call FLO_fnc_persistenceApplyPlayerToOwner;
};

if (_restoredPersistence) exitWith {
    diag_log format [
        "[FLO][Spawn] Restored persisted state for %1 player %2 instead of assigning deployment slot",
        [_side] call FLO_fnc_objectiveSideKey,
        name _player
    ];
};

if ((_uid isNotEqualTo "") && {_uid in FLO_SpawnPlayerAssignments}) exitWith {
    private _payload = FLO_SpawnPlayerAssignments get _uid;

    if ((_payload # 2) isNotEqualTo _sideKey) then {
        FLO_SpawnPlayerAssignments deleteAt _uid;
        _player setVariable ["FLO_Spawn_ResetBeforeAssignment", true];

        diag_log format [
            "[FLO][Spawn] Cleared stale %1 deployment assignment for player %2 now on %3",
            _payload # 2,
            name _player,
            _sideKey
        ];

        [_player, _attempt + 1, _requestOwner] call FLO_fnc_spawnRequestAssignment;
    } else {
        private _resetPlayerState = _player getVariable ["FLO_Spawn_ResetBeforeAssignment", false];
        private _uniformClass = [_sideKey] call FLO_fnc_spawnSideStoreUniform;
        private _clientPayload = +_payload;
        _clientPayload pushBack _resetPlayerState;
        _clientPayload pushBack _uniformClass;

        _player setVariable ["FLO_Spawn_AssignedCellId", _payload # 3, true];
        _clientPayload remoteExecCall ["FLO_fnc_spawnApplyAssignment", _owner];

        diag_log format [
            "[FLO][Spawn] Resent deployment assignment for %1 player %2 cell=%3",
            _sideKey,
            name _player,
            _payload # 3
        ];
    };
};

if !(_sideKey in FLO_DeploymentZones) then {
    throw format ["[FLO][Spawn] Missing deployment zone for side %1; zones=%2", _sideKey, keys FLO_DeploymentZones];
};

if !(_sideKey in FLO_SpawnSideAssignmentCounts) then {
    throw format ["[FLO][Spawn] Missing spawn assignment counter for side %1", _sideKey];
};

private _zone = FLO_DeploymentZones get _sideKey;
private _slot = FLO_SpawnSideAssignmentCounts get _sideKey;
FLO_SpawnSideAssignmentCounts set [_sideKey, _slot + 1];

private _cellId = _zone get "cellId";

if !(_cellId in FLO_ObjectiveCells) then {
    throw format ["[FLO][Spawn] Deployment cell %1 for side %2 does not exist", _cellId, _sideKey];
};

private _cell = FLO_ObjectiveCells get _cellId;
private _spawnATL = [_cell, _slot, typeOf _player, true] call FLO_fnc_spawnFindLandPositionInCell;
private _spawnASL = ATLToASL _spawnATL;
private _dir = _zone get "dir";
private _payload = [_spawnASL, _dir, _sideKey, _cellId];
private _resetPlayerState = _player getVariable ["FLO_Spawn_ResetBeforeAssignment", false];
private _uniformClass = [_sideKey] call FLO_fnc_spawnSideStoreUniform;
private _clientPayload = +_payload;
_clientPayload pushBack _resetPlayerState;
_clientPayload pushBack _uniformClass;

_player setVariable ["FLO_Spawn_AssignedCellId", _cellId, true];

if (_uid isNotEqualTo "") then {
    FLO_SpawnPlayerAssignments set [_uid, _payload];
};

_clientPayload remoteExecCall ["FLO_fnc_spawnApplyAssignment", _owner];

diag_log format [
    "[FLO][Spawn] Assigned %1 player %2 to deployment cell %3 slot=%4 pos=%5",
    _sideKey,
    name _player,
    _cellId,
    _slot,
    _spawnATL
];
