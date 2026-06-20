if (!hasInterface) exitWith { [] };

private _itemsByKey = createHashMap;
private _order = [];

private _fnc_categoryForClass = {
    params ["_className"];

    if (_className isEqualTo "") exitWith { "" };

    if (isClass (configFile >> "CfgMagazines" >> _className)) exitWith {
        private _cfg = configFile >> "CfgMagazines" >> _className;

        if ([_cfg] call FLO_fnc_storeIsMineMagazine) exitWith { "mines" };

        ["ammo", "misc"] select ([_cfg] call FLO_fnc_storeIsItemBackedMagazine)
    };

    if (isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
        private _cfg = configFile >> "CfgVehicles" >> _className;

        ["", "backpacks"] select ((getNumber (_cfg >> "isBackpack")) isEqualTo 1)
    };

    if (isClass (configFile >> "CfgWeapons" >> _className)) exitWith {
        [_className] call FLO_fnc_storeCategoryForWeapon
    };

    ""
};

private _fnc_displayName = {
    params ["_className", "_category"];

    private _cfg = switch (_category) do {
        case "ammo";
        case "mines": {
            configFile >> "CfgMagazines" >> _className
        };
        case "misc": {
            if (isClass (configFile >> "CfgWeapons" >> _className)) then {
                configFile >> "CfgWeapons" >> _className
            } else {
                configFile >> "CfgMagazines" >> _className
            }
        };
        case "backpacks": {
            configFile >> "CfgVehicles" >> _className
        };
        default {
            configFile >> "CfgWeapons" >> _className
        };
    };

    private _name = getText (_cfg >> "displayName");

    if (_name isEqualTo "") then {
        _name = _className;
    };

    _name
};

private _fnc_addLine = {
    params ["_className", ["_container", "auto"], ["_quantity", 1]];

    if (((typeName _className) isNotEqualTo "STRING") || {_className isEqualTo ""}) exitWith {};

    if (((typeName _container) isNotEqualTo "STRING") || {!(_container in FLO_StoreGearContainers)}) then {
        _container = "auto";
    };

    if ((typeName _quantity) isNotEqualTo "SCALAR") then {
        _quantity = 1;
    };

    _quantity = floor _quantity;

    if (_quantity < 1) exitWith {};

    private _category = [_className] call _fnc_categoryForClass;

    if ((_category isEqualTo "") || {!(_category in FLO_StoreGearCategories)}) exitWith {};

    private _key = format ["%1:%2:%3", _category, _container, toLower _className];

    if (_key in _itemsByKey) exitWith {
        private _existing = _itemsByKey get _key;

        _existing set ["quantity", (_existing get "quantity") + _quantity];
    };

    private _displayName = [_className, _category] call _fnc_displayName;

    _itemsByKey set [_key, createHashMapFromArray [
        ["className", _className],
        ["entryKind", "gear"],
        ["category", _category],
        ["name", _displayName],
        ["priceValue", [_className, _category, "gear"] call FLO_fnc_storePriceClass],
        ["quantity", _quantity],
        ["container", _container]
    ]];

    _order pushBack _key;
};

private _fnc_addCargoPairs = {
    params ["_cargo", "_container"];

    if ((typeName _cargo) isNotEqualTo "ARRAY") exitWith {};

    private _classes = _cargo param [0, []];
    private _counts = _cargo param [1, []];

    if (((typeName _classes) isNotEqualTo "ARRAY") || {((typeName _counts) isNotEqualTo "ARRAY")}) exitWith {};

    for "_i" from 0 to ((count _classes) - 1) do {
        [_classes select _i, _container, _counts param [_i, 1]] call _fnc_addLine;
    };
};

{
    private _weapon = _x select 0;
    private _items = _x select 1;
    private _magazines = _x select 2;

    [_weapon, "auto", 1] call _fnc_addLine;

    {
        [_x, "auto", 1] call _fnc_addLine;
    } forEach _items;

    {
        [_x, "auto", 1] call _fnc_addLine;
    } forEach _magazines;
} forEach [
    [primaryWeapon player, primaryWeaponItems player, primaryWeaponMagazine player],
    [handgunWeapon player, handgunItems player, handgunMagazine player],
    [secondaryWeapon player, secondaryWeaponItems player, secondaryWeaponMagazine player]
];

{
    [_x, "auto", 1] call _fnc_addLine;
} forEach assignedItems player;

{
    [_x, "auto", 1] call _fnc_addLine;
} forEach [
    uniform player,
    vest player,
    backpack player,
    headgear player,
    binocular player
];

{
    _x params ["_containerObject", "_container"];

    if (isNull _containerObject) then { continue };

    [getItemCargo _containerObject, _container] call _fnc_addCargoPairs;
    [getMagazineCargo _containerObject, _container] call _fnc_addCargoPairs;
} forEach [
    [uniformContainer player, "uniform"],
    [vestContainer player, "vest"],
    [backpackContainer player, "backpack"]
];

private _items = [];

{
    private _entry = _itemsByKey get _x;
    _entry set ["quantity", (_entry get "quantity") min 50];
    _items pushBack _entry;
} forEach _order;

_items
