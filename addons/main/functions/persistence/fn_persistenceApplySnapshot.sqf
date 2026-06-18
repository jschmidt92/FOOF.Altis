params ["_snapshotData"];

if (!isServer) exitWith { false };
if (_snapshotData isEqualTo []) exitWith { false };

private _snapshot = createHashMapFromArray _snapshotData;

if !(("version" in _snapshot) && {"worldName" in _snapshot}) exitWith {
    diag_log "[FLO][Persistence] Ignored malformed persistence snapshot";
    false
};

if ((_snapshot get "worldName") isNotEqualTo worldName) exitWith {
    diag_log format [
        "[FLO][Persistence] Ignored snapshot for world %1 while running %2",
        _snapshot get "worldName",
        worldName
    ];
    false
};

if ("resources" in _snapshot) then {
    private _resources = createHashMapFromArray (_snapshot get "resources");

    if ("revision" in _resources) then {
        FLO_ResourceRevision = _resources get "revision";
    };

    if ("tickCount" in _resources) then {
        FLO_ResourceTickCount = _resources get "tickCount";
    };

    if ("balances" in _resources) then {
        private _balances = createHashMapFromArray (_resources get "balances");
        FLO_ResourceBalances set ["WEST", _balances get "WEST"];
        FLO_ResourceBalances set ["EAST", _balances get "EAST"];
    };

    if ("income" in _resources) then {
        FLO_ResourceIncome = createHashMapFromArray (_resources get "income");
    };

    if ("cellIncome" in _resources) then {
        FLO_ResourceCellIncomeLast = createHashMapFromArray (_resources get "cellIncome");
    };

    if ("objectiveIncome" in _resources) then {
        FLO_ResourceObjectiveIncomeLast = createHashMapFromArray (_resources get "objectiveIncome");
    };

    if ("earnedTotal" in _resources) then {
        FLO_ResourceEarnedTotal = createHashMapFromArray (_resources get "earnedTotal");
    };

    if ("spentTotal" in _resources) then {
        FLO_ResourceSpentTotal = createHashMapFromArray (_resources get "spentTotal");
    };
};

if ("tickets" in _snapshot) then {
    private _tickets = createHashMapFromArray (_snapshot get "tickets");

    if ("revision" in _tickets) then {
        FLO_TicketRevision = _tickets get "revision";
    };

    if ("balances" in _tickets) then {
        private _balances = createHashMapFromArray (_tickets get "balances");
        FLO_TicketBalances set ["WEST", _balances get "WEST"];
        FLO_TicketBalances set ["EAST", _balances get "EAST"];
    };

    if ("purchasedTotal" in _tickets) then {
        FLO_TicketPurchasedTotal = createHashMapFromArray (_tickets get "purchasedTotal");
    };

    if ("consumedTotal" in _tickets) then {
        FLO_TicketConsumedTotal = createHashMapFromArray (_tickets get "consumedTotal");
    };

    if ((FLO_TicketBalances get "WEST") <= 0) then {
        [west, true, "BLUFOR has no respawn tickets."] call FLO_fnc_ticketBroadcastRespawnLock;
    };

    if ((FLO_TicketBalances get "EAST") <= 0) then {
        [east, true, "OPFOR has no respawn tickets."] call FLO_fnc_ticketBroadcastRespawnLock;
    };
};

if ("command" in _snapshot) then {
    private _command = createHashMapFromArray (_snapshot get "command");

    if ("revision" in _command) then {
        FLO_CommandRevision = _command get "revision";
    };

    if ("sides" in _command) then {
        {
            private _record = createHashMapFromArray _x;
            private _sideKey = _record get "sideKey";

            if (_sideKey in FLO_CommandSideState) then {
                private _state = FLO_CommandSideState get _sideKey;
                private _commanderUid = _record get "commanderUid";
                private _factionClass = _record get "factionClass";

                _state set ["initialVoteStarted", (_commanderUid isNotEqualTo "") && {_factionClass isNotEqualTo ""}];
                _state set ["commanderVoteOpen", false];
                _state set ["commanderVoteReason", ""];
                _state set ["commanderVoteEndsAt", 0];
                _state set ["commanderVotePromptId", ""];
                _state set ["commanderUid", _commanderUid];
                _state set ["commanderName", _record get "commanderName"];
                _state set ["commanderVotes", createHashMap];
                _state set ["factionVoteOpen", false];
                _state set ["factionVoteReason", ""];
                _state set ["factionVoteEndsAt", 0];
                _state set ["factionVotePromptId", ""];
                _state set ["factionClass", _factionClass];
                _state set ["factionName", _record get "factionName"];
                _state set ["factionVotes", createHashMap];

                private _permissionGrants = createHashMapFromArray [
                    ["build", []],
                    ["fob", []],
                    ["garage", []],
                    ["logistics", []],
                    ["store", []]
                ];
                private _roleAssignments = createHashMapFromArray [
                    ["deputy", []],
                    ["medic", []],
                    ["doctor", []],
                    ["engineer", []]
                ];

                if ("permissionGrants" in _record) then {
                    {
                        _permissionGrants set [_x select 0, +(_x select 1)];
                    } forEach (_record get "permissionGrants");
                };

                if ("roleAssignments" in _record) then {
                    {
                        _roleAssignments set [_x select 0, +(_x select 1)];
                    } forEach (_record get "roleAssignments");
                };

                _state set ["permissionGrants", _permissionGrants];
                _state set ["roleAssignments", _roleAssignments];
                [_sideKey] call FLO_fnc_commandSyncRoleGrants;
            };
        } forEach (_command get "sides");
    };
};

if ("objectives" in _snapshot) then {
    private _objectives = createHashMapFromArray (_snapshot get "objectives");

    if ("cells" in _objectives) then {
        {
            private _record = createHashMapFromArray _x;
            private _cellId = _record get "id";

            if (_cellId in FLO_ObjectiveCells) then {
                private _cell = FLO_ObjectiveCells get _cellId;
                _cell set ["owner", [_record get "owner"] call FLO_fnc_persistenceSideFromKey];
                _cell set ["state", _record get "state"];
                _cell set ["progress", _record get "progress"];
                _cell set ["progressSide", [_record get "progressSide"] call FLO_fnc_persistenceSideFromKey];

                if ("influenceEast" in _record) then {
                    _cell set ["influenceEast", _record get "influenceEast"];
                };

                if ("influenceWest" in _record) then {
                    _cell set ["influenceWest", _record get "influenceWest"];
                };
            };
        } forEach (_objectives get "cells");
    };

    if ("deploymentZones" in _objectives) then {
        private _deploymentZones = [];
        private _frontlineCells = createHashMap;

        {
            private _record = createHashMapFromArray _x;
            private _sideKey = _record get "sideKey";
            private _side = [_sideKey] call FLO_fnc_persistenceSideFromKey;

            if (_side in [west, east]) then {
                private _entryCellIds = +(_record get "entryCellIds");

                _deploymentZones pushBack [
                    _sideKey,
                    createHashMapFromArray [
                        ["side", _side],
                        ["sideKey", _sideKey],
                        ["cellId", _record get "cellId"],
                        ["entryCellIds", _entryCellIds],
                        ["position", _record get "position"],
                        ["spawnASL", _record get "spawnASL"],
                        ["dir", _record get "dir"],
                        ["pairScore", _record get "pairScore"]
                    ]
                ];

                _frontlineCells set [_sideKey, _entryCellIds];
            };
        } forEach (_objectives get "deploymentZones");

        if ((count _deploymentZones) isEqualTo 2) then {
            FLO_DeploymentZones = createHashMapFromArray _deploymentZones;
            FLO_ObjectiveInitialFrontlineCellIds = _frontlineCells;
        };
    };

    {
        [FLO_Objectives get _x] call FLO_fnc_objectiveResolveObjective;
    } forEach keys FLO_Objectives;

    if ("levels" in _objectives) then {
        {
            private _record = createHashMapFromArray _x;
            private _objectiveId = _record get "id";

            if (_objectiveId in FLO_Objectives) then {
                private _objective = FLO_Objectives get _objectiveId;
                private _savedOwner = [_record get "owner"] call FLO_fnc_persistenceSideFromKey;

                if ((_savedOwner in [west, east]) && {(_objective get "owner") isEqualTo _savedOwner}) then {
                    _objective set ["level", ((_record get "level") min FLO_ObjectiveMaxLevel) max 0];

                    if ("lastLevelChanged" in _record) then {
                        _objective set ["lastLevelChanged", _record get "lastLevelChanged"];
                    };

                    if ("capturedRestoreOwner" in _record) then {
                        private _capturedRestoreOwner = [_record get "capturedRestoreOwner"] call FLO_fnc_persistenceSideFromKey;
                        private _capturedRestoreLevel = 0;
                        private _capturedRestoreRemaining = 0;

                        if ("capturedRestoreLevel" in _record) then {
                            _capturedRestoreLevel = _record get "capturedRestoreLevel";
                        };

                        if ("capturedRestoreRemaining" in _record) then {
                            _capturedRestoreRemaining = _record get "capturedRestoreRemaining";
                        };

                        _objective set ["capturedRestoreOwner", _capturedRestoreOwner];
                        _objective set ["capturedRestoreLevel", (_capturedRestoreLevel min FLO_ObjectiveMaxLevel) max 0];
                        _objective set ["capturedRestoreExpiresAt", diag_tickTime + (_capturedRestoreRemaining max 0)];
                    };

                    if ("pressureWest" in _record) then {
                        _objective set ["pressureWest", ((_record get "pressureWest") max 0) min FLO_ObjectivePressureThreshold];
                    };

                    if ("pressureEast" in _record) then {
                        _objective set ["pressureEast", ((_record get "pressureEast") max 0) min FLO_ObjectivePressureThreshold];
                    };

                    if ("pressureWestLastAgo" in _record) then {
                        _objective set ["pressureWestLastAt", diag_tickTime - ((_record get "pressureWestLastAgo") max 0)];
                    };

                    if ("pressureEastLastAgo" in _record) then {
                        _objective set ["pressureEastLastAt", diag_tickTime - ((_record get "pressureEastLastAgo") max 0)];
                    };

                    if ("vulnerableSide" in _record) then {
                        private _vulnerableSide = [_record get "vulnerableSide"] call FLO_fnc_persistenceSideFromKey;
                        private _vulnerableRemaining = 0;

                        if ("vulnerableRemaining" in _record) then {
                            _vulnerableRemaining = _record get "vulnerableRemaining";
                        };

                        _objective set ["vulnerableSide", _vulnerableSide];
                        _objective set ["vulnerableExpiresAt", diag_tickTime + (_vulnerableRemaining max 0)];
                    };

                    if ("pendingUpgradeLevel" in _record) then {
                        private _pendingUpgradeLevel = ((_record get "pendingUpgradeLevel") min FLO_ObjectiveMaxLevel) max 0;
                        private _pendingUpgradeRemaining = 0;

                        if ("pendingUpgradeRemaining" in _record) then {
                            _pendingUpgradeRemaining = _record get "pendingUpgradeRemaining";
                        };

                        _objective set ["pendingUpgradeLevel", _pendingUpgradeLevel];

                        if (_pendingUpgradeLevel > 0) then {
                            _objective set ["pendingUpgradeStartedAt", diag_tickTime];
                            _objective set ["pendingUpgradeCompleteAt", diag_tickTime + (_pendingUpgradeRemaining max 0)];
                        } else {
                            _objective set ["pendingUpgradeStartedAt", 0];
                            _objective set ["pendingUpgradeCompleteAt", 0];
                        };
                    };
                };
            };
        } forEach (_objectives get "levels");
    };

    [true] call FLO_fnc_objectivePublishSnapshot;
};

if ("fobs" in _snapshot) then {
    private _fobs = createHashMapFromArray (_snapshot get "fobs");

    {
        [_x, true, false] call FLO_fnc_fobUnregister;
    } forEach keys FLO_FOBs;

    FLO_FOBs = createHashMap;

    if ("starterUsed" in _fobs) then {
        FLO_FOBStarterUsed = createHashMapFromArray (_fobs get "starterUsed");
    };

    if ("records" in _fobs) then {
        {
            private _record = createHashMapFromArray _x;
            private _className = _record get "className";

            if (isClass (configFile >> "CfgVehicles" >> _className)) then {
                private _side = [_record get "sideKey"] call FLO_fnc_persistenceSideFromKey;

                if (_side in [west, east]) then {
                    private _type = ["FOB", _record get "type"] select ("type" in _record);
                    private _fob = createVehicle [_className, [0, 0, 0], [], 0, "CAN_COLLIDE"];
                    [_fob, _x] call FLO_fnc_persistenceRestoreObjectState;
                    private _fobId = [_fob, _side, _record get "ownerUid", _record get "id", _record get "buildRadius", _type] call FLO_fnc_fobRegister;
                };
            };
        } forEach (_fobs get "records");
    };

    if ("nextId" in _fobs) then {
        FLO_FOBNextId = _fobs get "nextId";
    };
};

if ("idsLogistics" in _snapshot) then {
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach IDS_Logistics_PlacedEntities;

    IDS_Logistics_PlacedEntities = [];

    {
        private _record = createHashMapFromArray _x;
        private _className = _record get "className";

        if (isClass (configFile >> "CfgVehicles" >> _className)) then {
            private _entity = createVehicle [_className, [0, 0, 0], [], 0, "CAN_COLLIDE"];
            [_entity, _x] call FLO_fnc_persistenceRestoreObjectState;
            _entity setVariable ["IDS_Logistics_EntityCost", _record get "cost", true];
            _entity setVariable ["IDS_Logistics_Category", _record get "category", true];
            _entity setVariable ["IDS_Logistics_SideKey", _record get "sideKey", true];
            _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];

            IDS_Logistics_PlacedEntities pushBack _entity;
        };
    } forEach (_snapshot get "idsLogistics");
};

if ("store" in _snapshot) then {
    private _store = createHashMapFromArray (_snapshot get "store");

    if ("pendingVehicleCounter" in _store) then {
        FLO_StorePendingVehicleCounter = _store get "pendingVehicleCounter";
    };

    if ("purchasedVehicleCounter" in _store) then {
        FLO_StorePurchasedVehicleCounter = _store get "purchasedVehicleCounter";
    };

    FLO_StorePendingVehicles = [];

    if ("pendingVehicles" in _store) then {
        {
            private _record = createHashMapFromArray _x;
            private _sideKey = _record get "sideKey";
            private _fobId = _record get "fobId";
            private _fobNetId = _record get "fobNetId";

            if (_fobId in FLO_FOBs) then {
                private _fobRecord = FLO_FOBs get _fobId;
                _fobNetId = netId (_fobRecord get "object");
            };

            FLO_StorePendingVehicles pushBack createHashMapFromArray [
                ["id", _record get "id"],
                ["className", _record get "className"],
                ["name", _record get "name"],
                ["category", _record get "category"],
                ["priceValue", [0, _record get "priceValue"] select ("priceValue" in _record)],
                ["side", [_sideKey] call FLO_fnc_persistenceSideFromKey],
                ["sideKey", _sideKey],
                ["owner", _record get "owner"],
                ["playerUid", _record get "playerUid"],
                ["fobNetId", _fobNetId],
                ["fobId", _fobId],
                ["createdAt", diag_tickTime]
            ];
        } forEach (_store get "pendingVehicles");
    };
};

if ("vehicles" in _snapshot) then {
    {
        private _record = createHashMapFromArray _x;
        private _className = _record get "className";

        if (isClass (configFile >> "CfgVehicles" >> _className)) then {
            private _vehicle = createVehicle [_className, ASLToAGL (_record get "posASL"), [], 0, "CAN_COLLIDE"];
            [_vehicle, _x] call FLO_fnc_persistenceRestoreObjectState;

            if (("storeSideKey" in _record) && {(_record get "storeSideKey") isNotEqualTo ""}) then {
                _vehicle setVariable ["FLO_Store_PurchasedSideKey", _record get "storeSideKey", true];
            };

            if (("storeSourceFobId" in _record) && {(_record get "storeSourceFobId") isNotEqualTo ""}) then {
                _vehicle setVariable ["FLO_Store_SourceFobId", _record get "storeSourceFobId", true];
            };

            if (("storeAssetId" in _record) && {("storeSideKey" in _record) && {(_record get "storeSideKey") isNotEqualTo ""}}) then {
                private _storeCategory = [_className] call FLO_fnc_storeCategoryForVehicle;
                private _storeOriginalPrice = [_className, _storeCategory] call FLO_fnc_storePriceVehicle;
                private _storeAssetId = _record get "storeAssetId";

                if ("storeCategory" in _record) then {
                    _storeCategory = _record get "storeCategory";
                };

                if ("storeOriginalPrice" in _record) then {
                    _storeOriginalPrice = _record get "storeOriginalPrice";
                };

                [
                    _vehicle,
                    _record get "storeSideKey",
                    _record get "storeSourceFobId",
                    _className,
                    _storeCategory,
                    _storeOriginalPrice,
                    _storeAssetId
                ] call FLO_fnc_storeRegisterPurchasedVehicle;
            };
        };
    } forEach (_snapshot get "vehicles");
};

if ("players" in _snapshot) then {
    FLO_PersistencePlayerRecords = createHashMap;

    {
        private _record = createHashMapFromArray _x;
        private _uid = _record get "uid";

        if (_uid isNotEqualTo "") then {
            FLO_PersistencePlayerRecords set [_uid, _x];
        };
    } forEach (_snapshot get "players");
};

FLO_PersistenceLoaded = true;
FLO_PersistenceDirty = false;

[0] call FLO_fnc_resourceSendSnapshot;
{ [[west, east] select (_x isEqualTo "EAST")] call FLO_fnc_commandBroadcastSide; } forEach ["WEST", "EAST"];

private _loadedCellCount = 0;
private _loadedFobCount = 0;
private _loadedPendingVehicleCount = 0;
private _loadedIdsCount = 0;
private _loadedVehicleCount = 0;
private _loadedPlayerCount = 0;

if ("objectives" in _snapshot) then {
    private _objectivesLog = createHashMapFromArray (_snapshot get "objectives");

    if ("cells" in _objectivesLog) then {
        _loadedCellCount = count (_objectivesLog get "cells");
    };
};

if ("fobs" in _snapshot) then {
    private _fobsLog = createHashMapFromArray (_snapshot get "fobs");

    if ("records" in _fobsLog) then {
        _loadedFobCount = count (_fobsLog get "records");
    };
};

if ("store" in _snapshot) then {
    private _storeLog = createHashMapFromArray (_snapshot get "store");

    if ("pendingVehicles" in _storeLog) then {
        _loadedPendingVehicleCount = count (_storeLog get "pendingVehicles");
    };
};

if ("idsLogistics" in _snapshot) then {
    _loadedIdsCount = count (_snapshot get "idsLogistics");
};

if ("vehicles" in _snapshot) then {
    _loadedVehicleCount = count (_snapshot get "vehicles");
};

if ("players" in _snapshot) then {
    _loadedPlayerCount = count (_snapshot get "players");
};

diag_log format [
    "[FLO][Persistence] Loaded snapshot key=%1 cells=%2 fobs=%3 ids=%4 pendingVehicles=%5 vehicles=%6 players=%7",
    FLO_PersistenceKey,
    _loadedCellCount,
    _loadedFobCount,
    _loadedIdsCount,
    _loadedPendingVehicleCount,
    _loadedVehicleCount,
    _loadedPlayerCount
];

true
