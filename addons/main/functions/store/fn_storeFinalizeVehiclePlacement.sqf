params [
    ["_purchaseId", "", [""]],
    ["_className", "", [""]],
    ["_finalPos", [0, 0, 0], [[]]],
    ["_finalDir", 0, [0]],
    ["_vectorUp", [0, 0, 1], [[]]],
    ["_player", objNull, [objNull]]
];

if (!isServer) exitWith {};

private _send = {
    params ["_owner", "_payload"];

    if (_owner <= 0) exitWith {
        if (hasInterface) then {
            [_payload] call FLO_fnc_storeReceivePlacementResult;
        };
    };

    [_payload] remoteExecCall ["FLO_fnc_storeReceivePlacementResult", _owner];
};

if (isNull _player) exitWith {};

private _owner = owner _player;
private _requestOwner = remoteExecutedOwner;

if (_requestOwner <= 2) then {
    _requestOwner = _owner;
};

if ((_requestOwner > 2) && {_owner isNotEqualTo _requestOwner}) exitWith {
    diag_log format [
        "[FLO][Store] Rejected spoofed vehicle placement player=%1 requestOwner=%2 actualOwner=%3",
        name _player,
        _requestOwner,
        _owner
    ];
};

private _index = -1;
private _pending = createHashMap;

for "_i" from 0 to ((count FLO_StorePendingVehicles) - 1) do {
    private _entry = FLO_StorePendingVehicles select _i;

    if ((_entry get "id") isEqualTo _purchaseId) exitWith {
        _index = _i;
        _pending = _entry;
    };
};

private _fail = {
    params ["_message"];

    [_owner, createHashMapFromArray [
        ["success", false],
        ["message", _message],
        ["id", _purchaseId]
    ]] call _send;

    false;
};

if (_index < 0) exitWith {
    ["Vehicle purchase is no longer pending."] call _fail;
};

if ((_pending get "className") isNotEqualTo _className) exitWith {
    ["Vehicle placement class mismatch."] call _fail;
};

if ((_pending get "playerUid") isNotEqualTo (getPlayerUID _player)) exitWith {
    ["This vehicle purchase belongs to another player."] call _fail;
};

if (!alive _player) exitWith {
    ["You must be alive to place a purchased vehicle."] call _fail;
};

private _side = side group _player;

if !(_side in [west, east]) exitWith {
    ["Only BLUFOR and OPFOR can place purchased vehicles."] call _fail;
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

if (_sideKey isNotEqualTo (_pending get "sideKey")) exitWith {
    ["This purchased vehicle belongs to another side."] call _fail;
};

private _fob = objectFromNetId (_pending get "fobNetId");

if (isNull _fob) exitWith {
    ["The purchase FOB no longer exists."] call _fail;
};

if (!alive _fob) exitWith {
    ["The purchase FOB is destroyed."] call _fail;
};

private _fobId = _pending get "fobId";

if !(_fobId in FLO_FOBs) exitWith {
    ["The purchase FOB is no longer registered."] call _fail;
};

private _fobRecord = FLO_FOBs get _fobId;

if ((_fobRecord get "sideKey") isNotEqualTo _sideKey) exitWith {
    ["The purchase FOB belongs to another side."] call _fail;
};

if !(_fobRecord get "vehicleStoreEnabled") exitWith {
    ["Purchased vehicles can only be placed from a FOB purchase."] call _fail;
};

private _finalPosAGL = ASLToAGL _finalPos;
private _buildRadius = _fobRecord get "buildRadius";

if ((_fob distance2D _finalPosAGL) > _buildRadius) exitWith {
    ["Purchased vehicles must be placed inside the purchase FOB build radius."] call _fail;
};

if ((_player distance2D _finalPosAGL) > 90) exitWith {
    ["Vehicle placement is too far from your current position."] call _fail;
};

private _needsWater = _className isKindOf "Ship";

if (_needsWater isNotEqualTo (surfaceIsWater _finalPosAGL)) exitWith {
    if (_needsWater) then {
        ["Naval vehicles must be placed on water."] call _fail;
    } else {
        ["Land and air vehicles must be placed on land."] call _fail;
    };
};

private _vehicle = [_className, _finalPos, _finalDir, _vectorUp] call IDS_Logistics_fnc_spawnEntity;
if (isNull _vehicle) exitWith { ["Vehicle placement failed."] call _fail; };

_vehicle lock 0;

[
    _vehicle,
    _sideKey,
    _fob getVariable ["FLO_FOB_Id", ""],
    _className,
    _pending get "category",
    _pending get "priceValue"
] call FLO_fnc_storeRegisterPurchasedVehicle;

FLO_StorePendingVehicles deleteAt _index;
["storeVehiclePlaced"] call FLO_fnc_persistenceScheduleSave;

[_owner, createHashMapFromArray [
    ["success", true],
    ["message", format ["Placed %1.", _pending get "name"]],
    ["id", _purchaseId],
    ["netId", netId _vehicle]
]] call _send;

true;
