params ["_name"];

if (!hasInterface) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Saved kits are client-local."],
        ["kits", []]
    ]
};

if ((typeName _name) isNotEqualTo "STRING") exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Invalid kit data."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

if (_name isEqualTo "") exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Name the kit first."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

if ((count _name) > 40) then {
    _name = _name select [0, 40];
};

private _items = [] call FLO_fnc_storeCurrentLoadoutKitItems;

if (((count _items) < 1) || {(count _items) > 60}) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Equipped kit item count is invalid."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

private _sanitized = [];

for "_i" from 0 to ((count _items) - 1) do {
    private _entry = _items select _i;

    if ((typeName _entry) isNotEqualTo "HASHMAP") then { continue };
    if (!(("className" in _entry) && {"entryKind" in _entry} && {"category" in _entry} && {"name" in _entry})) then { continue };

    private _className = _entry get "className";
    private _entryKind = _entry get "entryKind";
    private _category = _entry get "category";
    private _displayName = _entry get "name";

    if (((typeName _className) isNotEqualTo "STRING") || {((typeName _entryKind) isNotEqualTo "STRING") || {((typeName _category) isNotEqualTo "STRING") || {((typeName _displayName) isNotEqualTo "STRING")}}}) then { continue };

    private _quantity = 1;
    if ("quantity" in _entry) then {
        _quantity = _entry get "quantity";
    };

    if ((typeName _quantity) isNotEqualTo "SCALAR") then {
        _quantity = 1;
    };

    _quantity = floor _quantity;

    if ((_quantity < 1) || {_quantity > 50}) then { continue };

    private _priceValue = 0;
    if ("priceValue" in _entry) then {
        _priceValue = _entry get "priceValue";
    };

    if ((typeName _priceValue) isNotEqualTo "SCALAR") then {
        _priceValue = 0;
    };

    private _container = "auto";
    if ("container" in _entry) then {
        _container = _entry get "container";
    };

    if (((typeName _container) isNotEqualTo "STRING") || {!(_container in FLO_StoreGearContainers)}) then {
        _container = "auto";
    };

    _sanitized pushBack createHashMapFromArray [
        ["className", _className],
        ["entryKind", _entryKind],
        ["category", _category],
        ["name", _displayName],
        ["priceValue", _priceValue],
        ["quantity", _quantity],
        ["container", _container]
    ];
};

if (_sanitized isEqualTo []) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Equipped kit has no usable Store items."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

private _kits = [] call FLO_fnc_storeSavedKitsLoad;
private _id = "";
private _next = [];
private _nameLower = toLower _name;

{
    if ((toLower (_x get "name")) isEqualTo _nameLower) then {
        _id = _x get "id";
    } else {
        _next pushBack _x;
    };
} forEach _kits;

if (_id isEqualTo "") then {
    _id = format ["kit_%1_%2", getPlayerUID player, floor (diag_tickTime * 1000)];
};

_next pushBack createHashMapFromArray [
    ["id", _id],
    ["name", _name],
    ["items", _sanitized],
    ["updatedAt", floor diag_tickTime]
];

profileNamespace setVariable ["FLO_StoreSavedKits", _next];
saveProfileNamespace;

createHashMapFromArray [
    ["success", true],
    ["message", format ["Saved kit: %1.", _name]],
    ["kits", [] call FLO_fnc_storeSavedKitsLoad]
]
