if (!isServer) exitWith {};

FLO_ResourceInitialBalance = 5000;

FLO_ResourceBalances = createHashMapFromArray [
    ["WEST", FLO_ResourceInitialBalance],
    ["EAST", FLO_ResourceInitialBalance]
];
FLO_ResourceIncome = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_ResourceCellIncomeLast = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_ResourceObjectiveIncomeLast = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_ResourceEarnedTotal = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_ResourceSpentTotal = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
FLO_ResourceSnapshot = [];
FLO_ResourceVehicleRecoveryMetaCache = createHashMap;
FLO_ResourceTickCount = 0;
FLO_ResourceRevision = 0;
FLO_ResourceSystemRunning = false;
FLO_ResourceLoopHandle = -1;
FLO_ResourceSnapshotScheduled = false;

FLO_ResourceTickInterval = 60;
FLO_ResourceCellIncome = 2;
FLO_ResourceVehicleSellbackRate = 0.45;
FLO_ResourceSnapshotBroadcastDelay = 0.5;

private _income = [] call FLO_fnc_resourceCalculateIncome;
FLO_ResourceCellIncomeLast = _income get "cellIncome";
FLO_ResourceObjectiveIncomeLast = _income get "objectiveIncome";
FLO_ResourceIncome = _income get "totalIncome";

[0] call FLO_fnc_resourceSendSnapshot;
[] call FLO_fnc_resourceStartLoop;

diag_log format [
    "[FLO][Resource] Resource system initialized initialBalance=%1 tickInterval=%2 cellIncome=%3",
    FLO_ResourceInitialBalance,
    FLO_ResourceTickInterval,
    FLO_ResourceCellIncome
];
