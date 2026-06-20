params [["_fob", objNull, [objNull]]];

if (!hasInterface) exitWith {};

if (isNull _fob) exitWith {
    ["Base is no longer available.", "error", "Build Menu"] call FLO_fnc_notify;
};

private _side = side group player;

if !(_side in [west, east]) exitWith {
    ["Only BLUFOR and OPFOR can use base logistics.", "warning", "Build Menu"] call FLO_fnc_notify;
};

if (!([player, "logistics"] call FLO_fnc_commandPlayerHasAuthority)) exitWith {
    ["Only the side commander can use base logistics right now.", "warning", "Build Menu"] call FLO_fnc_notify;
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

if ((_fob getVariable ["FLO_FOB_SideKey", ""]) isNotEqualTo _sideKey) exitWith {
    ["This base belongs to the other faction.", "error", "Build Menu"] call FLO_fnc_notify;
};

private _buildRadius = _fob getVariable ["FLO_FOB_BuildRadius", FLO_FOBBuildRadius];

if ((player distance2D _fob) > _buildRadius) exitWith {
    [format ["Move within %1m of this base to build.", _buildRadius], "warning", "Build Menu"] call FLO_fnc_notify;
};

missionNamespace setVariable ["FLO_LogisticsActiveBaseId", _fob getVariable ["FLO_FOB_Id", ""]];
missionNamespace setVariable ["FLO_LogisticsActiveCategories", +(_fob getVariable ["FLO_FOB_LogisticsCategories", []])];

[player, false, _buildRadius] call IDS_Logistics_fnc_initBuildCamera;
