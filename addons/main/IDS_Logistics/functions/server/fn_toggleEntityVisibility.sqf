params [
    ["_netId", "", [""]],
    ["_hide", true, [true]],
    ["_player", objNull, [objNull]]
];

if (!isServer) exitWith {};
if (_netId isEqualTo "") exitWith {};
if (isNull _player || {!alive _player}) exitWith {};

private _owner = owner _player;

if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    diag_log format [
        "[IDS_Logistics] Rejected visibility request from owner %1 for owner %2",
        remoteExecutedOwner,
        _owner
    ];
};

private _entity = objectFromNetId _netId;

if (isNull _entity) exitWith {};

private _side = side group _player;
if !(_side in [west, east]) exitWith {
    [false, "Only BLUFOR and OPFOR can move logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

if (!([_player, "logistics"] call FLO_fnc_commandPlayerHasAuthority)) exitWith {
    [false, "Only the elected side commander can use FOB logistics right now."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

private _entitySideKey = _entity getVariable ["IDS_Logistics_SideKey", ""];
if (_entitySideKey isEqualTo "") then {
    _entitySideKey = _entity getVariable ["FLO_FOB_SideKey", ""];
};

if (_entitySideKey isNotEqualTo _sideKey) exitWith {
    [false, "You cannot move the other faction's logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

if (!([_side, getPosASL _player] call FLO_fnc_fobCanBuildAt)) exitWith {
    [false, "You must be inside a friendly FOB build radius to move logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

if (!([_side, getPosASL _entity] call FLO_fnc_fobCanBuildAt)) exitWith {
    [false, "Logistics objects can only be moved inside a friendly FOB build radius."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

if ((_player distance2D _entity) > 90) exitWith {
    [false, "The selected logistics object is too far away to move."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

_entity hideObjectGlobal _hide;
_entity enableSimulationGlobal !_hide;
