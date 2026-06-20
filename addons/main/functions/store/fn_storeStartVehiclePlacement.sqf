params ["_purchaseId"];

if (!hasInterface) exitWith { false };
if ((typeName _purchaseId) isNotEqualTo "STRING") exitWith { false };

private _entry = createHashMap;

{
    if ((_x get "id") isEqualTo _purchaseId) exitWith {
        _entry = _x;
    };
} forEach FLO_StoreClientPendingVehicles;

if ((count _entry) isEqualTo 0) exitWith {
    ["Vehicle placement is unavailable.", "error", "Vehicle Placement"] call FLO_fnc_notify;
    false
};

private _fob = objectFromNetId (_entry get "fobNetId");

if (isNull _fob) exitWith {
    ["Vehicle placement FOB is unavailable.", "error", "Vehicle Placement"] call FLO_fnc_notify;
    false
};

closeDialog 0;

private _activeCamera = missionNamespace getVariable ["IDS_Logistics_Cam", objNull];
private _buildRadius = _fob getVariable ["FLO_FOB_BuildRadius", FLO_FOBBuildRadius];

if (isNull _activeCamera) then {
    [_fob, true, _buildRadius] call IDS_Logistics_fnc_initBuildCamera;
} else {
    IDS_Logistics_BuildMenuDisabled = true;
};

[_entry get "className", _purchaseId] call IDS_Logistics_fnc_startPlacement;

[format ["Placing %1.", _entry get "name"], "info", "Vehicle Placement"] call FLO_fnc_notify;

true
