params ["_itemsByCategory", "_seen", "_className", "_entryKind", "_category"];

if (_className isEqualTo "") exitWith {};
if (_category isEqualTo "") exitWith {};

private _validClass = switch (_category) do {
    case "tickets": { _entryKind isEqualTo "ticket" };
    case "ammo": { isClass (configFile >> "CfgMagazines" >> _className) };
    case "mines": { isClass (configFile >> "CfgMagazines" >> _className) };
    case "misc": { (isClass (configFile >> "CfgWeapons" >> _className)) || {isClass (configFile >> "CfgMagazines" >> _className)} };
    case "backpacks": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "cars": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "armor": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "helis": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "planes": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "naval": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "static": { isClass (configFile >> "CfgVehicles" >> _className) };
    case "other": { isClass (configFile >> "CfgVehicles" >> _className) };
    default { isClass (configFile >> "CfgWeapons" >> _className) };
};

if (!_validClass) exitWith {};

private _key = format ["%1:%2", _entryKind, toLower _className];

if (_key in _seen) exitWith {};

private _item = [_className, _entryKind, _category] call FLO_fnc_storeBuildCatalogItem;
private _bucket = _itemsByCategory get _category;

_bucket pushBack _item;
_seen set [_key, true];
