params [
    ["_player", objNull, [objNull]],
    ["_broadcastNotice", true, [false]]
];

if (!isServer) exitWith { false };

private _requestOwner = remoteExecutedOwner;
private _owner = owner _player;

if ((isNull _player) || {!isPlayer _player}) exitWith {
    diag_log format ["[FLO][Persistence] Rejected reset request from owner %1: invalid player", _requestOwner];
    false
};

if ((_requestOwner > 2) && {_owner isNotEqualTo _requestOwner}) exitWith {
    diag_log format [
        "[FLO][Persistence] Rejected reset request from owner %1 for owner %2",
        _requestOwner,
        _owner
    ];
    false
};

if ((_requestOwner > 2) && {admin _requestOwner isEqualTo 0}) exitWith {
    diag_log format [
        "[FLO][Persistence] Rejected reset request from non-admin %1 uid=%2",
        name _player,
        getPlayerUID _player
    ];
    false
};

[
    _broadcastNotice,
    format ["admin=%1 uid=%2", name _player, getPlayerUID _player]
] call FLO_fnc_persistenceResetServer
