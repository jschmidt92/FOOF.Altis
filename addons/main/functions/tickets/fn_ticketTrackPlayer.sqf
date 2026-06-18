params ["_unit"];

if (!isServer) exitWith {};
if (isNull _unit) exitWith {};

private _uid = getPlayerUID _unit;

if (_uid isEqualTo "") exitWith {};

private _side = side group _unit;

if !(_side in [west, east]) exitWith {
    private _storedSideKey = _unit getVariable ["FLO_TicketSideKey", ""];

    if (_storedSideKey in ["WEST", "EAST"]) then {
        FLO_TicketPlayerSides set [_uid, _storedSideKey];
    };
};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;

FLO_TicketPlayerSides set [_uid, _sideKey];

_unit setVariable ["FLO_TicketPlayerUid", _uid, true];
_unit setVariable ["FLO_TicketSideKey", _sideKey, true];
