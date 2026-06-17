if (!isServer) exitWith {};

FLO_Objectives = createHashMap;
FLO_ObjectiveCells = createHashMap;
FLO_ObjectiveSnapshot = [];
FLO_ObjectiveGridSnapshot = [];
FLO_ObjectiveSnapshotDelta = [];
FLO_ObjectiveGridSnapshotDelta = [];
FLO_ObjectivePendingGridCellIds = createHashMap;
FLO_ObjectivePendingObjectiveIds = createHashMap;
FLO_DeploymentZones = createHashMap;
FLO_DeploymentPairDiagnostics = createHashMap;
FLO_ObjectivePresenceCellIds = [];
FLO_ObjectiveLastPublishAt = -9999;
FLO_ObjectiveLastFullSnapshotAt = -9999;
FLO_ObjectivePublicationsSent = 0;
FLO_ObjectiveSystemRunning = false;
FLO_ObjectiveLoopHandle = -1;
FLO_ObjectiveLastDiagnostics = createHashMap;

FLO_ObjectiveUpdateInterval = 5;
FLO_ObjectiveSnapshotHeartbeat = 30;
FLO_ObjectivePublishMinInterval = 2;
FLO_ObjectiveMinCapturePlayers = 1;
FLO_ObjectiveCellCaptureRate = 0.035 / 2;
FLO_ObjectiveCellDecayRate = 0.01;
FLO_ObjectiveGridCellSize = 1000;
FLO_ObjectiveGridMinLandSamples = 1;
FLO_ObjectiveGridInfluenceRate = 0.008 / 3;
FLO_ObjectiveGridEncirclementRate = 0.012 / 3;
FLO_ObjectiveGridAoEMinOwnedNeighbors = 2;
FLO_ObjectiveGridEncircleMinOwnedNeighbors = 5;
FLO_ObjectivePerfLogThresholdMs = 20;
FLO_ObjectiveGeneratedMaxObjectives = 80;
FLO_ObjectiveGeneratedRequiredWeightRatio = 0.55;
FLO_ObjectiveGeneratedOverlapFactor = 0.45;
FLO_ObjectiveGeneratedMarineMaxLandDistance = 1600;
FLO_ObjectiveGeneratedClusterEnabled = true;
FLO_ObjectiveGeneratedClusterScanBudget = 40;
FLO_ObjectiveGeneratedClusterScanRadius = 350;
FLO_ObjectiveGeneratedClusterMinBuildings = 14;
FLO_ObjectiveGeneratedMaxClusterObjectives = 6;
FLO_ObjectiveGeneratedClusterObjectiveGridRadius = 700;
FLO_ObjectiveGeneratedClusterDisplayRadius = 170;
FLO_ObjectiveDeploymentEdgeBufferCells = 1;
FLO_ObjectiveDeploymentMinCardinalNeighbors = 3;
FLO_ObjectiveDeploymentRoadRadius = 800;
FLO_ObjectiveDeploymentMinObjectiveDistance = 1200;
FLO_ObjectiveDeploymentMinCenterDistanceRatio = 0.22;
FLO_ObjectiveDeploymentMinPairDistanceRatio = 0.45;
FLO_ObjectiveDeploymentTargetPairDistanceRatio = 0.65;
FLO_ObjectiveDeploymentMaxOppositionDot = -0.25;
FLO_ObjectiveDeploymentMaxObjectiveAccessDelta = 0.45;
FLO_ObjectiveDeploymentMinSurfaceNormalZ = 0.82;
FLO_ObjectiveDeploymentTopPairCount = 8;

{
    FLO_ObjectiveCells set [_x get "id", _x];
} forEach ([] call FLO_fnc_objectiveGenerateGridCells);

private _definitions = [] call FLO_fnc_objectiveGenerateDefinitions;

{
    [_x] call FLO_fnc_objectiveRegister;
} forEach _definitions;

[] call FLO_fnc_objectiveSeedInitialFrontlines;
[] call FLO_fnc_spawnInitServer;

{
    [FLO_Objectives get _x] call FLO_fnc_objectiveResolveObjective;
} forEach keys FLO_Objectives;

[true] call FLO_fnc_objectivePublishSnapshot;

FLO_ObjectivePlayerConnectedEh = addMissionEventHandler [
    "PlayerConnected",
    {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [
            {
                params ["_owner"];

                if (isServer) then {
                    [_owner] call FLO_fnc_objectiveSendFullSnapshot;
                };
            },
            [_owner],
            3
        ] call CBA_fnc_waitAndExecute;
    }
];

if ((keys FLO_ObjectiveCells) isNotEqualTo []) then {
    [] call FLO_fnc_objectiveStartLoop;
} else {
    diag_log "[FLO][Objective] No objective grid cells generated; objective loop not started";
};

[] call FLO_fnc_resourceInitServer;

diag_log format [
    "[FLO][Objective] Objective system initialized objectives=%1 cells=%2",
    count (keys FLO_Objectives),
    count (keys FLO_ObjectiveCells)
];
