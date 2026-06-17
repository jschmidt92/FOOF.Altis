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
        "[FLO][Command] Rejected spoofed role assignment player=%1 requestOwner=%2 actualOwner=%3 role=%4 target=%5",
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
    ["Only the elected commander can assign command roles.", "warning"] call _notify;
};

private _target = objNull;

{
    if ((getPlayerUID _x) isEqualTo _targetUid) exitWith {
        _target = _x;
    };
} forEach ([_side] call FLO_fnc_commandSidePlayers);

if (isNull _target) exitWith {
    ["Target player is no longer active on your side.", "warning"] call _notify;
};

[_sideKey] call FLO_fnc_commandPruneRoleAssignments;

if ((_role isEqualTo "deputy") && {_targetUid isEqualTo (_state get "commanderUid")}) exitWith {
    ["Commander cannot also be deputy commander.", "warning"] call _notify;
};

private _roleAssignments = _state get "roleAssignments";
private _caps = [_side] call FLO_fnc_commandRoleCaps;
private _assigned = +(_roleAssignments get _role);
private _oldDeputy = [];
private _changed = false;

if (_role isEqualTo "deputy") then {
    _oldDeputy = +_assigned;
    _assigned = [_targetUid];
    _changed = true;
} else {
    if !(_targetUid in _assigned) then {
        if ((count _assigned) >= (_caps get _role)) then {
            [
                format ["No %1 slots available for your current player count.", toUpper _role],
                "warning"
            ] call _notify;
        } else {
            _assigned pushBack _targetUid;
            _changed = true;
        };
    };
};

if (!_changed) exitWith {};

if (_role isEqualTo "doctor") then {
    private _medics = +(_roleAssignments get "medic");
    _medics = _medics - [_targetUid];
    _roleAssignments set ["medic", _medics];
};

if (_role isEqualTo "medic") then {
    private _doctors = +(_roleAssignments get "doctor");
    _doctors = _doctors - [_targetUid];
    _roleAssignments set ["doctor", _doctors];
};

_roleAssignments set [_role, _assigned];
[_sideKey] call FLO_fnc_commandSyncRoleGrants;

{
    [_x] call FLO_fnc_commandApplyPlayerRoles;
} forEach ([_side] call FLO_fnc_commandSidePlayers);

FLO_CommandRevision = FLO_CommandRevision + 1;
[_side] call FLO_fnc_commandScheduleBroadcastSide;
["commandRoleAssign"] call FLO_fnc_persistenceScheduleSave;

diag_log format [
    "[FLO][Command] %1 commander %2 assigned role=%3 target=%4 previousDeputy=%5",
    _sideKey,
    name _player,
    _role,
    name _target,
    _oldDeputy
];
