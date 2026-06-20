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

private _isFobObj = false;
if (_originalNetId isNotEqualTo "") then {
    private _existingEntity = objectFromNetId _originalNetId;
    if (!isNull _existingEntity && {(_existingEntity getVariable ["FLO_FOB_Id", ""]) isNotEqualTo ""}) then {
        _isFobObj = true;
    };
};

private _entityConfig = [];
if (!_isFobObj) then {
    _entityConfig = [_className] call IDS_Logistics_fnc_getEntityConfig;
};

if (!_isFobObj && {(count _entityConfig) isEqualTo 0}) exitWith {
    [false, format ["%1 is not a configured logistics object.", _className]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _entityClassName = _className;
private _entityCategory = "";
private _entityCost = 0;

if (!_isFobObj) then {
    _entityConfig params ["_cfgClass", "_cfgCategory", "_cfgCost"];
    _entityClassName = _cfgClass;
    _entityCategory = _cfgCategory;
    _entityCost = _cfgCost;
};

private _placementBase = createHashMap;

if (!_isFobObj) then {
    _placementBase = [_side, _finalPos] call FLO_fnc_fobBuildBaseAt;
};

if (!_isFobObj && {(count _placementBase) isEqualTo 0}) exitWith {
    [false, "Logistics objects must be placed inside a friendly base build radius."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _allowedCategories = [];

if (!_isFobObj) then {
    _allowedCategories = _placementBase get "logisticsCategories";
};

if (!_isFobObj && {_allowedCategories isNotEqualTo []} && {!(_entityCategory in _allowedCategories)}) exitWith {
    [false, format ["%1s can only build light logistics categories.", _placementBase get "type"]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

if (_originalNetId isNotEqualTo "") then {
    private _existingEntity = objectFromNetId _originalNetId;

    if (isNull _existingEntity) exitWith {
        [false, "The selected logistics object no longer exists."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if (!_isFobObj && {!(_existingEntity getVariable ["IDS_Logistics_isPlacedEntity", false])}) exitWith {
        [false, "That object is not managed by IDS Logistics."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    private _entitySideKey = _existingEntity getVariable ["IDS_Logistics_SideKey", ""];
    if (_entitySideKey isEqualTo "") then {
        _entitySideKey = _existingEntity getVariable ["FLO_FOB_SideKey", ""];
    };

    if (_entitySideKey isNotEqualTo _sideKey) exitWith {
        [false, "You cannot move the other faction's logistics objects."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if ((_player distance2D _existingEntity) > 90) exitWith {
        [false, "The selected logistics object is too far away to move."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    if (_isFobObj) then {
        private _anchorPosASL = _existingEntity getVariable ["FLO_FOB_AnchorPosASL", getPosASL _existingEntity];
        private _buildRadius = _existingEntity getVariable ["FLO_FOB_BuildRadius", 0];

        if (((ASLToAGL _anchorPosASL) distance2D _finalPosAGL) > _buildRadius) exitWith {
            _existingEntity hideObjectGlobal false;
            _existingEntity enableSimulationGlobal true;
            [false, "FOBs and COPs can only be rearranged inside their original build radius."] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
        };
    };

    _existingEntity setPosASL _finalPos;
    _existingEntity setDir _finalDir;
    _existingEntity setVectorUp _vectorUp;
    _existingEntity hideObjectGlobal false;
    _existingEntity enableSimulationGlobal true;

    private _message = format ["Moved %1.", _entityClassName];

    if (!_isFobObj) then {
        IDS_Logistics_PlacedEntities pushBackUnique _existingEntity;
        ["idsMove"] call FLO_fnc_persistenceScheduleSave;
    } else {
        private _fobType = _existingEntity getVariable ["FLO_FOB_Type", "FOB"];
        _message = format ["Moved %1.", _fobType];
        ["baseRegister"] call FLO_fnc_persistenceScheduleSave;
        [_existingEntity] remoteExecCall ["FLO_fnc_fobSyncClientMarker", 0, _existingEntity];
    };

    [true, _message] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
} else {
    if (!([_side, _entityCost, format ["IDS Logistics %1", _entityClassName]] call FLO_fnc_resourceSpend)) exitWith {
        [false, format ["Not enough faction currency. %1 cost: %2.", _entityClassName, _entityCost]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
    };

    private _entity = [_entityClassName, _finalPos, _finalDir, _vectorUp] call IDS_Logistics_fnc_spawnEntity;
    _entity setVariable ["IDS_Logistics_EntityCost", _entityCost, true];
    _entity setVariable ["IDS_Logistics_Category", _entityCategory, true];
    _entity setVariable ["IDS_Logistics_SideKey", _sideKey, true];
    _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];

    IDS_Logistics_PlacedEntities pushBack _entity;
    ["idsPlace"] call FLO_fnc_persistenceScheduleSave;

    [true, format ["Placed %1 for $%2.", _entityClassName, _entityCost]] remoteExecCall ["IDS_Logistics_fnc_receivePlacementResult", _owner];
};
