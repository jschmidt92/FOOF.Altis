params ["_unit", "_killer", "_instigator", "_useEffects"];

if (!isServer) exitWith {};
if (isNull _unit) exitWith {};

private _uid = getPlayerUID _unit;

if (_uid isEqualTo "") then {
    _uid = _unit getVariable ["FLO_TicketPlayerUid", ""];
};

if (_uid isEqualTo "") exitWith {
    if (isPlayer _unit) then {
        diag_log format [
            "[FLO][Tickets] Death ignored: missing uid unit=%1 currentSide=%2",
            _unit,
            side group _unit
        ];
    };
};

private _sideKey = _unit getVariable ["FLO_TicketSideKey", ""];
private _side = sideUnknown;
private _currentSide = side group _unit;

if (_sideKey isEqualTo "") then {
    if (_uid in FLO_TicketPlayerSides) then {
        _sideKey = FLO_TicketPlayerSides get _uid;
    };
};

if (_sideKey isEqualTo "") then {
    if (_currentSide in [west, east]) then {
        _sideKey = [_currentSide] call FLO_fnc_resourceSideKey;
    };
};

_side = switch (_sideKey) do {
    case "WEST": { west };
    case "EAST": { east };
    default { sideUnknown };
};

if !(_side in [west, east]) exitWith {
    private _storedSideForLog = "";

    if (_uid in FLO_TicketPlayerSides) then {
        _storedSideForLog = FLO_TicketPlayerSides get _uid;
    };

    diag_log format [
        "[FLO][Tickets] Death ignored: unresolved side uid=%1 sideKey=%2 currentSide=%3 storedSide=%4 unit=%5",
        _uid,
        _sideKey,
        _currentSide,
        _storedSideForLog,
        _unit
    ];
};

if ((_currentSide isEqualTo civilian) && {_sideKey in ["WEST", "EAST"]}) then {
    diag_log format [
        "[FLO][Tickets] Death resolved from civilian/downed unit uid=%1 ticketSide=%2 unit=%3",
        _uid,
        _sideKey,
        _unit
    ];
};

if (_unit getVariable ["FLO_TicketDeathHandled", false]) exitWith {};
_unit setVariable ["FLO_TicketDeathHandled", true];

private _state = "charged";
private _locked = false;
private _message = "";

FLO_PersistencePlayerRecords deleteAt _uid;

if !([_side, FLO_TicketRespawnCost, format ["death %1", _uid]] call FLO_fnc_ticketConsume) then {
    _state = "denied";
    _locked = true;
    _message = format ["%1 has no respawn tickets.", _sideKey];
    [_side, true, "No respawn tickets remain. Hold until command buys reinforcements."] call FLO_fnc_ticketBroadcastRespawnLock;
} else {
    private _balance = [_side] call FLO_fnc_ticketSideBalance;
    _locked = _balance <= 0;
    _message = if (_locked) then {
        "Respawn ticket consumed. No tickets remain."
    } else {
        format ["Respawn ticket consumed. %1 tickets remain.", _balance]
    };
};

FLO_TicketDeathStates set [
    _uid,
    createHashMapFromArray [
        ["sideKey", _sideKey],
        ["state", _state],
        ["locked", _locked],
        ["message", _message],
        ["unitNetId", netId _unit]
    ]
];

_unit setVariable ["FLO_TicketDeathState", _state];
_unit setVariable ["FLO_TicketDeathSideKey", _sideKey];

[_unit, _locked, _message] call FLO_fnc_ticketSyncPlayer;
["playerDeathTicket"] call FLO_fnc_persistenceScheduleSave;

diag_log format [
    "[FLO][Tickets] Player death uid=%1 side=%2 state=%3 killer=%4 instigator=%5",
    _uid,
    _sideKey,
    _state,
    _killer,
    _instigator
];
