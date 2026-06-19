params ["_itemsByCategory", "_seen", "_className"];

if !(isClass (configFile >> "CfgWeapons" >> _className)) exitWith {};
if (_className in ["Throw", "Put"]) exitWith {};

private _category = [_className] call FLO_fnc_storeCategoryForWeapon;
[_itemsByCategory, _seen, _className, "gear", _category] call FLO_fnc_storeAppendCatalogItem;
