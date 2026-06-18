params [
    ["_vehicle", objNull, [objNull]],
    ["_sideKey", "", [""]],
    ["_fobId", "", [""]],
    ["_className", "", [""]],
    ["_category", "", [""]],
    ["_originalPrice", 0, [0]],
    ["_assetId", "", [""]]
];

if (!isServer) exitWith { "" };
if (isNull _vehicle) then {
    throw "[FLO][Store] Cannot register null purchased vehicle";
};

if (_assetId isEqualTo "") then {
    FLO_StorePurchasedVehicleCounter = FLO_StorePurchasedVehicleCounter + 1;
    _assetId = format ["store_asset_%1_%2", floor (diag_tickTime * 1000), FLO_StorePurchasedVehicleCounter];
};

_vehicle setVariable ["FLO_Store_AssetId", _assetId, true];
_vehicle setVariable ["FLO_Store_PurchasedSideKey", _sideKey, true];
_vehicle setVariable ["FLO_Store_SourceFobId", _fobId, true];

FLO_StorePurchasedVehicles set [
    _assetId,
    createHashMapFromArray [
        ["id", _assetId],
        ["object", _vehicle],
        ["sideKey", _sideKey],
        ["fobId", _fobId],
        ["className", _className],
        ["category", _category],
        ["originalPrice", floor _originalPrice],
        ["sold", false],
        ["createdAt", diag_tickTime]
    ]
];

_assetId
