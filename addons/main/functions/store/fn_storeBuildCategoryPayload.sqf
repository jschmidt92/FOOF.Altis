params ["_access", "_category"];

private _valid = false;
private _label = _category;

{
    if ((_x select 0) isEqualTo _category) then {
        _valid = true;
        _label = _x select 1;
    };
} forEach FLO_StoreCategories;

if (!_valid) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Unknown store category: %1", _category]],
        ["category", _category],
        ["label", _label],
        ["items", []]
    ]
};

private _catalog = [
    _access get "sideKey",
    _access get "factionClass",
    _access get "factionName"
] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _state = FLO_CommandSideState get (_access get "sideKey");
private _playerUid = getPlayerUID (_access get "player");
private _canBuyTickets = (_state get "commanderUid") isEqualTo _playerUid;
private _deploymentFund = [_playerUid] call FLO_fnc_storeEnsureDeploymentFund;

createHashMapFromArray [
    ["success", true],
    ["message", ""],
    ["category", _category],
    ["label", _label],
    ["items", _itemsByCategory get _category],
    ["balance", FLO_ResourceBalances get (_access get "sideKey")],
    ["deploymentFund", _deploymentFund],
    ["deploymentFundAmount", FLO_StoreDeploymentFundAmount],
    ["tickets", FLO_TicketBalances get (_access get "sideKey")],
    ["canBuyTickets", _canBuyTickets]
]
