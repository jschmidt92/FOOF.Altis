params [
    ["_player", objNull, [objNull]],
    ["_targetUid", "", [""]],
    ["_role", "", [""]]
];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _owner = owner _player;
private _requestOwner = remoteExecutedOwner;

if (_requestOwner <= 2) then {
    _requestOwner = _owner;
};

if ((_requestOwner > 2) && {_owner isNotEqualTo _requestOwner}) exitWith {
    diag_log format [
        "[FLO][Command] Rejected spoofed role clear player=%1 requestOwner=%2 actualOwner=%3 role=%4 target=%5",
        name _player,
        _requestOwner,
        _owner,
        _role,
        _targetUid
    ];
};

if !(_role in FLO_CommandRoleOrder) exitWith {};
if (_targetUid isEqualTo "") exitWith {};

private _side = side group _player;

if !(_side in [west, east]) exitWith {};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;
private _state = FLO_CommandSideState get _sideKey;
private _playerUid = getPlayerUID _player;

private _notify = {
    params ["_message", ["_type", "info"]];

    [_player, createHashMapFromArray [
        ["mode", "notify"],
        ["type", _type],
        ["title", "Command Roles"],
        ["message", _message],
        ["duration", 4]
    ]] call FLO_fnc_notificationSendPlayer;
};

if ((_state get "commanderUid") isNotEqualTo _playerUid) exitWith {
    ["Only the elected commander can clear command roles.", "warning"] call _notify;
};

private _roleAssignments = _state get "roleAssignments";
private _assigned = +(_roleAssignments get _role);

if !(_targetUid in _assigned) exitWith {};

_assigned = _assigned - [_targetUid];
_roleAssignments set [_role, _assigned];
[_sideKey] call FLO_fnc_commandSyncRoleGrants;

{
    [_x] call FLO_fnc_commandApplyPlayerRoles;
} forEach ([_side] call FLO_fnc_commandSidePlayers);

FLO_CommandRevision = FLO_CommandRevision + 1;
[_side] call FLO_fnc_commandScheduleBroadcastSide;
["commandRoleClear"] call FLO_fnc_persistenceScheduleSave;

diag_log format [
    "[FLO][Command] %1 commander %2 cleared role=%3 targetUid=%4",
    _sideKey,
    name _player,
    _role,
    _targetUid
];
