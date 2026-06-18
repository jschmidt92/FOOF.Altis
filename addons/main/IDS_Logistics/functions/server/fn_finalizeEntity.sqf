params [
    ["_originalNetId", "", [""]],
    ["_className", "", [""]],
    ["_finalPos", [0, 0, 0], [[]]],
    ["_finalDir", 0, [0]],
    ["_vectorUp", [0, 0, 1], [[]]],
    ["_player", objNull, [objNull]],
    ["_centerHeight", 0, [0]]
];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _owner = owner _player;

if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    diag_log format [
        "[IDS_Logistics] Rejected finalize request from owner %1 for owner %2",
        remoteExecutedOwner,
        _owner
    ];
};

private _side = side group _player;

if !(_side in [west, east]) exitWith {
    [false, "Only BLUFOR and OPFOR can place logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

if (!([_player, "logistics"] call FLO_fnc_commandPlayerHasAuthority)) exitWith {
    [false, "Only the elected side commander can use base logistics right now."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _playerBase = [_side, getPosASL _player] call FLO_fnc_fobBuildBaseAt;

if ((count _playerBase) isEqualTo 0) exitWith {
    [false, "You must be inside a friendly base build radius to place logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _finalPosAGL = ASLToAGL _finalPos;
if ((_player distance2D _finalPosAGL) > 90) exitWith {
    [false, "Logistics placement is too far from your current position."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _entityConfig = [_className] call IDS_Logistics_fnc_getEntityConfig;

if ((count _entityConfig) isEqualTo 0) exitWith {
    [false, format ["%1 is not a configured logistics object.", _className]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

_entityConfig params ["_entityClassName", "_entityCategory", "_entityCost"];

private _placementBase = [_side, _finalPos] call FLO_fnc_fobBuildBaseAt;

if ((count _placementBase) isEqualTo 0) exitWith {
    [false, "Logistics objects must be placed inside a friendly base build radius."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _allowedCategories = _placementBase get "logisticsCategories";

if ((_allowedCategories isNotEqualTo []) && {!(_entityCategory in _allowedCategories)}) exitWith {
    [false, format ["%1s can only build light logistics categories.", _placementBase get "type"]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

if (_originalNetId isNotEqualTo "") then {
    private _existingEntity = objectFromNetId _originalNetId;

    if (isNull _existingEntity) exitWith {
        [false, "The selected logistics object no longer exists."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if !(_existingEntity getVariable ["IDS_Logistics_isPlacedEntity", false]) exitWith {
        [false, "That object is not managed by IDS Logistics."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if ((_existingEntity getVariable ["IDS_Logistics_SideKey", ""]) isNotEqualTo _sideKey) exitWith {
        [false, "You cannot move the other faction's logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if ((_player distance2D _existingEntity) > 90) exitWith {
        [false, "The selected logistics object is too far away to move."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    _existingEntity setPosASL _finalPos;
    _existingEntity setDir _finalDir;
    _existingEntity setVectorUp _vectorUp;
    _existingEntity hideObjectGlobal false;
    _existingEntity enableSimulationGlobal true;

    IDS_Logistics_PlacedEntities pushBackUnique _existingEntity;
    ["idsMove"] call FLO_fnc_persistenceScheduleSave;

    [true, format ["Moved %1.", _entityClassName]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
} else {
    if (!([_side, _entityCost, format ["IDS Logistics %1", _entityClassName]] call FLO_fnc_resourceSpend)) exitWith {
        [false, format ["Not enough faction currency. %1 cost: %2.", _entityClassName, _entityCost]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    private _entity = createVehicle [_entityClassName, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _entity setPosASL _finalPos;
    _entity setDir _finalDir;
    _entity setVectorUp _vectorUp;
    _entity setVariable ["IDS_Logistics_EntityCost", _entityCost, true];
    _entity setVariable ["IDS_Logistics_Category", _entityCategory, true];
    _entity setVariable ["IDS_Logistics_SideKey", _sideKey, true];
    _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];

    IDS_Logistics_PlacedEntities pushBack _entity;
    ["idsPlace"] call FLO_fnc_persistenceScheduleSave;

    [true, format ["Placed %1 for $%2.", _entityClassName, _entityCost]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};
