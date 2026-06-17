params ["_unit"];

if (!isServer) exitWith {};
if (isNull _unit) exitWith {};

private _uid = getPlayerUID _unit;

if (_uid isEqualTo "") exitWith {};

private _side = side group _unit;

if !(_side in [west, east]) exitWith {};

_unit setVariable ["FLO_TicketPlayerUid", _uid, true];
_unit setVariable ["FLO_TicketSideKey", [_side] call FLO_fnc_resourceSideKey, true];
