params ["_sideKey"];

if (!isServer) exitWith { "" };

private _faction = [_sideKey] call FLO_fnc_storeSelectedFaction;

if !(_faction get "selected") exitWith { "" };

private _catalog = [
    _sideKey,
    _faction get "class",
    _faction get "name"
] call FLO_fnc_storeBuildCatalog;

private _uniforms = (_catalog get "itemsByCategory") get "uniforms";

if (_uniforms isEqualTo []) exitWith { "" };

(_uniforms select 0) get "className"
