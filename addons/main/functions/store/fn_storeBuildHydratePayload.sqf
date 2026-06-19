params ["_access"];

private _sideKey = _access get "sideKey";
private _state = FLO_CommandSideState get _sideKey;
private _playerUid = getPlayerUID (_access get "player");
private _canBuyTickets = (_state get "commanderUid") isEqualTo _playerUid;
private _deploymentFund = [_playerUid] call FLO_fnc_storeEnsureDeploymentFund;
private _catalog = [
    _sideKey,
    _access get "factionClass",
    _access get "factionName"
] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _categories = [];
private _firstCategory = "";

{
    private _category = _x select 0;
    private _label = _x select 1;
    private _count = count (_itemsByCategory get _category);

    _categories pushBack createHashMapFromArray [
        ["id", _category],
        ["label", _label],
        ["count", _count]
    ];

    if ((_firstCategory isEqualTo "") && {_count > 0}) then {
        _firstCategory = _category;
    };
} forEach FLO_StoreCategories;

createHashMapFromArray [
    ["success", true],
    ["message", ""],
    ["sideKey", _sideKey],
    ["sideName", ["BLUFOR", "OPFOR"] select (_sideKey isEqualTo "EAST")],
    ["factionClass", _catalog get "factionClass"],
    ["factionName", _catalog get "factionName"],
    ["balance", FLO_ResourceBalances get _sideKey],
    ["deploymentFund", _deploymentFund],
    ["deploymentFundAmount", FLO_StoreDeploymentFundAmount],
    ["tickets", FLO_TicketBalances get _sideKey],
    ["canBuyTickets", _canBuyTickets],
    ["categories", _categories],
    ["firstCategory", _firstCategory],
    ["fobNetId", _access get "fobNetId"],
    ["pendingVehicles", [_access] call FLO_fnc_storePendingVehiclesForAccess]
]
