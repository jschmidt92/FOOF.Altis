params ["_sideKey", "_factionClass", "_factionName"];

if (!isServer) exitWith {
    throw "[FLO][Store] Catalogs are server-owned";
};

private _cacheKey = format ["%1:%2", _sideKey, toLower _factionClass];

if (_cacheKey in FLO_StoreCatalogCache) exitWith {
    FLO_StoreCatalogCache get _cacheKey
};

private _itemsByCategory = createHashMap;

{
    _itemsByCategory set [_x select 0, []];
} forEach FLO_StoreCategories;

private _seen = createHashMap;
private _factionLower = toLower _factionClass;
private _factionUsesVanillaGear = [_factionClass] call FLO_fnc_storeFactionUsesVanillaGear;

{
    private _unitCfg = _x;
    private _unitClass = configName _unitCfg;

    if ((toLower (getText (_unitCfg >> "faction"))) isNotEqualTo _factionLower) then { continue };
    if ((getNumber (_unitCfg >> "scope")) < 2) then { continue };
    if !(_unitClass isKindOf "CAManBase") then { continue };

    private _weapons = [];
    _weapons append getArray (_unitCfg >> "weapons");
    _weapons append getArray (_unitCfg >> "respawnWeapons");

    {
        [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearWeapon;
    } forEach _weapons;

    private _linkedItems = [];
    _linkedItems append getArray (_unitCfg >> "linkedItems");
    _linkedItems append getArray (_unitCfg >> "respawnLinkedItems");
    _linkedItems append getArray (_unitCfg >> "items");
    _linkedItems append getArray (_unitCfg >> "respawnItems");

    {
        if (!_factionUsesVanillaGear && {[_x] call FLO_fnc_storeIsVanillaDefaultNvg}) then { continue };

        [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearWeapon;
    } forEach _linkedItems;

    private _magazines = [];
    _magazines append getArray (_unitCfg >> "magazines");
    _magazines append getArray (_unitCfg >> "respawnMagazines");

    {
        [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearMagazine;
    } forEach _magazines;

    [_itemsByCategory, _seen, _unitCfg] call FLO_fnc_storeAppendContainerCargoItems;

    private _uniform = getText (_unitCfg >> "uniformClass");
    [_itemsByCategory, _seen, _uniform, "gear", "uniforms"] call FLO_fnc_storeAppendCatalogItem;

    private _backpack = getText (_unitCfg >> "backpack");
    [_itemsByCategory, _seen, _backpack, "gear", "backpacks"] call FLO_fnc_storeAppendCatalogItem;

    if ((_backpack isNotEqualTo "") && {isClass (configFile >> "CfgVehicles" >> _backpack)}) then {
        [_itemsByCategory, _seen, configFile >> "CfgVehicles" >> _backpack] call FLO_fnc_storeAppendContainerCargoItems;
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

{
    private _vehicleCfg = _x;
    private _vehicleClass = configName _vehicleCfg;

    if ((toLower (getText (_vehicleCfg >> "faction"))) isNotEqualTo _factionLower) then { continue };
    if ((getNumber (_vehicleCfg >> "scope")) < 2) then { continue };
    if ((_vehicleClass isKindOf "CAManBase") || {(getNumber (_vehicleCfg >> "isBackpack")) isEqualTo 1}) then { continue };

    private _category = [_vehicleClass] call FLO_fnc_storeCategoryForVehicle;
    [_itemsByCategory, _seen, _vehicleClass, "vehicle", _category] call FLO_fnc_storeAppendCatalogItem;
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

[_itemsByCategory, _seen] call FLO_fnc_storeAppendSupportItems;

{
    _x params ["_className", "_name", "_ticketCount", "_price"];

    (_itemsByCategory get "tickets") pushBack createHashMapFromArray [
        ["className", _className],
        ["name", _name],
        ["category", "tickets"],
        ["entryKind", "ticket"],
        ["deploymentFundEligible", false],
        ["ticketCount", _ticketCount],
        ["priceValue", _price],
        ["price", format ["%1", _price]],
        ["image", ""]
    ];
} forEach FLO_StoreTicketPacks;

{
    private _category = _x select 0;
    private _items = _itemsByCategory get _category;

    _items = [_items, [], { _x get "name" }, "ASCEND"] call BIS_fnc_sortBy;
    _itemsByCategory set [_category, _items];
} forEach FLO_StoreCategories;

private _catalog = createHashMapFromArray [
    ["sideKey", _sideKey],
    ["factionClass", _factionClass],
    ["factionName", _factionName],
    ["itemsByCategory", _itemsByCategory],
    ["createdAt", diag_tickTime]
];

FLO_StoreCatalogCache set [_cacheKey, _catalog];

diag_log format [
    "[FLO][Store] Built catalog side=%1 faction=%2 gearPrimary=%3 vehicles=%4",
    _sideKey,
    _factionClass,
    count (_itemsByCategory get "primary"),
    (count (_itemsByCategory get "cars")) + (count (_itemsByCategory get "armor")) + (count (_itemsByCategory get "helis")) + (count (_itemsByCategory get "planes")) + (count (_itemsByCategory get "naval")) + (count (_itemsByCategory get "static")) + (count (_itemsByCategory get "other"))
];

_catalog
