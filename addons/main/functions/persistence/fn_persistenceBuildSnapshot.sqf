if (!isServer) exitWith { [] };

{
    [_x, false] call FLO_fnc_persistenceSavePlayer;
} forEach allPlayers;

private _resources = [
    ["revision", FLO_ResourceRevision],
    ["tickCount", FLO_ResourceTickCount],
    ["balances", [
        ["WEST", FLO_ResourceBalances get "WEST"],
        ["EAST", FLO_ResourceBalances get "EAST"]
    ]],
    ["income", [
        ["WEST", FLO_ResourceIncome get "WEST"],
        ["EAST", FLO_ResourceIncome get "EAST"]
    ]],
    ["cellIncome", [
        ["WEST", FLO_ResourceCellIncomeLast get "WEST"],
        ["EAST", FLO_ResourceCellIncomeLast get "EAST"]
    ]],
    ["objectiveIncome", [
        ["WEST", FLO_ResourceObjectiveIncomeLast get "WEST"],
        ["EAST", FLO_ResourceObjectiveIncomeLast get "EAST"]
    ]],
    ["earnedTotal", [
        ["WEST", FLO_ResourceEarnedTotal get "WEST"],
        ["EAST", FLO_ResourceEarnedTotal get "EAST"]
    ]],
    ["spentTotal", [
        ["WEST", FLO_ResourceSpentTotal get "WEST"],
        ["EAST", FLO_ResourceSpentTotal get "EAST"]
    ]]
];

private _tickets = [
    ["revision", FLO_TicketRevision],
    ["balances", [
        ["WEST", FLO_TicketBalances get "WEST"],
        ["EAST", FLO_TicketBalances get "EAST"]
    ]],
    ["purchasedTotal", [
        ["WEST", FLO_TicketPurchasedTotal get "WEST"],
        ["EAST", FLO_TicketPurchasedTotal get "EAST"]
    ]],
    ["consumedTotal", [
        ["WEST", FLO_TicketConsumedTotal get "WEST"],
        ["EAST", FLO_TicketConsumedTotal get "EAST"]
    ]]
];

private _commandSides = [];

{
    private _sideKey = _x;
    private _state = FLO_CommandSideState get _sideKey;
    private _grants = [];
    private _roles = [];

    {
        _grants pushBack [_x, +_y];
    } forEach (_state get "permissionGrants");

    {
        _roles pushBack [_x, +_y];
    } forEach (_state get "roleAssignments");

    _commandSides pushBack [
        ["sideKey", _sideKey],
        ["initialVoteStarted", _state get "initialVoteStarted"],
        ["commanderUid", _state get "commanderUid"],
        ["commanderName", _state get "commanderName"],
        ["factionClass", _state get "factionClass"],
        ["factionName", _state get "factionName"],
        ["permissionGrants", _grants],
        ["roleAssignments", _roles]
    ];
} forEach ["WEST", "EAST"];

private _command = [
    ["revision", FLO_CommandRevision],
    ["sides", _commandSides]
];

private _cellRecords = [];

{
    private _cell = FLO_ObjectiveCells get _x;

    _cellRecords pushBack [
        ["id", _x],
        ["owner", [_cell get "owner"] call FLO_fnc_persistenceSideKey],
        ["state", _cell get "state"],
        ["progress", _cell get "progress"],
        ["progressSide", [_cell get "progressSide"] call FLO_fnc_persistenceSideKey],
        ["influenceEast", _cell get "influenceEast"],
        ["influenceWest", _cell get "influenceWest"]
    ];
} forEach FLO_ObjectiveGridCellIds;

private _objectiveLevelRecords = [];

{
    private _objective = FLO_Objectives get _x;
    private _pendingUpgradeRemaining = 0;
    private _capturedRestoreRemaining = 0;

    if ((_objective get "pendingUpgradeLevel") > 0) then {
        _pendingUpgradeRemaining = ((_objective get "pendingUpgradeCompleteAt") - diag_tickTime) max 0;
    };

    if ((_objective get "capturedRestoreOwner") in [west, east]) then {
        _capturedRestoreRemaining = ((_objective get "capturedRestoreExpiresAt") - diag_tickTime) max 0;
    };

    _objectiveLevelRecords pushBack [
        ["id", _x],
        ["owner", [_objective get "owner"] call FLO_fnc_persistenceSideKey],
        ["level", _objective get "level"],
        ["lastLevelChanged", _objective get "lastLevelChanged"],
        ["capturedRestoreOwner", [_objective get "capturedRestoreOwner"] call FLO_fnc_persistenceSideKey],
        ["capturedRestoreLevel", _objective get "capturedRestoreLevel"],
        ["capturedRestoreRemaining", _capturedRestoreRemaining],
        ["frontline", _objective get "frontline"],
        ["pressureWest", _objective get "pressureWest"],
        ["pressureEast", _objective get "pressureEast"],
        ["pressureWestLastAgo", diag_tickTime - (_objective get "pressureWestLastAt")],
        ["pressureEastLastAgo", diag_tickTime - (_objective get "pressureEastLastAt")],
        ["vulnerableSide", [_objective get "vulnerableSide"] call FLO_fnc_persistenceSideKey],
        ["vulnerableRemaining", ((_objective get "vulnerableExpiresAt") - diag_tickTime) max 0],
        ["pendingUpgradeLevel", _objective get "pendingUpgradeLevel"],
        ["pendingUpgradeStartedAt", _objective get "pendingUpgradeStartedAt"],
        ["pendingUpgradeRemaining", _pendingUpgradeRemaining]
    ];
} forEach keys FLO_Objectives;

private _deploymentRecords = [];

{
    private _zone = FLO_DeploymentZones get _x;

    _deploymentRecords pushBack [
        ["sideKey", _x],
        ["cellId", _zone get "cellId"],
        ["entryCellIds", +(_zone get "entryCellIds")],
        ["position", _zone get "position"],
        ["spawnASL", _zone get "spawnASL"],
        ["dir", _zone get "dir"],
        ["pairScore", _zone get "pairScore"]
    ];
} forEach keys FLO_DeploymentZones;

private _objectives = [
    ["cells", _cellRecords],
    ["levels", _objectiveLevelRecords],
    ["deploymentZones", _deploymentRecords]
];

private _fobRecords = [];

{
    private _record = FLO_FOBs get _x;
    private _fob = _record get "object";

    if ((!isNull _fob) && {alive _fob}) then {
        private _objectRecord = [_fob] call FLO_fnc_persistenceSerializeObject;
        _objectRecord pushBack ["id", _record get "id"];
        _objectRecord pushBack ["type", _record get "type"];
        _objectRecord pushBack ["sideKey", _record get "sideKey"];
        _objectRecord pushBack ["ownerUid", _record get "ownerUid"];
        _objectRecord pushBack ["buildRadius", _record get "buildRadius"];
        _fobRecords pushBack _objectRecord;
    };
} forEach keys FLO_FOBs;

private _fobs = [
    ["nextId", FLO_FOBNextId],
    ["starterUsed", [
        ["WEST", FLO_FOBStarterUsed get "WEST"],
        ["EAST", FLO_FOBStarterUsed get "EAST"]
    ]],
    ["records", _fobRecords]
];

private _idsRecords = [];

{
    if ((!isNull _x) && {alive _x}) then {
        private _objectRecord = [_x] call FLO_fnc_persistenceSerializeObject;
        _objectRecord pushBack ["sideKey", _x getVariable ["IDS_Logistics_SideKey", ""]];
        _objectRecord pushBack ["category", _x getVariable ["IDS_Logistics_Category", ""]];
        _objectRecord pushBack ["cost", _x getVariable ["IDS_Logistics_EntityCost", 0]];
        _idsRecords pushBack _objectRecord;
    };
} forEach IDS_Logistics_PlacedEntities;

private _pendingVehicleRecords = [];

{
    _pendingVehicleRecords pushBack [
        ["id", _x get "id"],
        ["className", _x get "className"],
        ["name", _x get "name"],
        ["category", _x get "category"],
        ["priceValue", _x get "priceValue"],
        ["sideKey", _x get "sideKey"],
        ["owner", _x get "owner"],
        ["playerUid", _x get "playerUid"],
        ["fobNetId", _x get "fobNetId"],
        ["fobId", _x get "fobId"]
    ];
} forEach FLO_StorePendingVehicles;

private _store = [
    ["pendingVehicleCounter", FLO_StorePendingVehicleCounter],
    ["purchasedVehicleCounter", FLO_StorePurchasedVehicleCounter],
    ["pendingVehicles", _pendingVehicleRecords]
];

private _vehicleRecords = [];

{
    if (
        (!isNull _x)
        && {alive _x}
        && {!(_x isKindOf "Man")}
        && {!(_x getVariable ["IDS_Logistics_isPlacedEntity", false])}
        && {(_x getVariable ["FLO_FOB_Id", ""]) isEqualTo ""}
    ) then {
        private _objectRecord = [_x] call FLO_fnc_persistenceSerializeObject;

        private _assetId = _x getVariable ["FLO_Store_AssetId", ""];

        if ((_assetId isNotEqualTo "") && {_assetId in FLO_StorePurchasedVehicles}) then {
            private _asset = FLO_StorePurchasedVehicles get _assetId;

            if ((_asset get "object") isEqualTo _x) then {
                _objectRecord pushBack ["storeAssetId", _assetId];
                _objectRecord pushBack ["storeSideKey", _asset get "sideKey"];
                _objectRecord pushBack ["storeSourceFobId", _asset get "fobId"];
                _objectRecord pushBack ["storeCategory", _asset get "category"];
                _objectRecord pushBack ["storeOriginalPrice", _asset get "originalPrice"];
            };
        };

        _vehicleRecords pushBack _objectRecord;
    };
} forEach vehicles;

private _playerRecords = [];

{
    _playerRecords pushBack (FLO_PersistencePlayerRecords get _x);
} forEach keys FLO_PersistencePlayerRecords;

[
    ["version", FLO_PersistenceVersion],
    ["worldName", worldName],
    ["savedAt", systemTimeUTC],
    ["resources", _resources],
    ["tickets", _tickets],
    ["command", _command],
    ["objectives", _objectives],
    ["fobs", _fobs],
    ["idsLogistics", _idsRecords],
    ["store", _store],
    ["vehicles", _vehicleRecords],
    ["players", _playerRecords]
]
