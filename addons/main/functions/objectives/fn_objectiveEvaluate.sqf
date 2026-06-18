if (!isServer) exitWith {};

private _t0 = diag_tickTime;
private _presence = [] call FLO_fnc_objectiveCollectPresence;
private _presenceMs = (diag_tickTime - _t0) * 1000;
private _bucketT0 = diag_tickTime;

[_presence] call FLO_fnc_objectiveUpdatePresenceCounts;

private _bucketMs = (diag_tickTime - _bucketT0) * 1000;
private _resolutionT0 = diag_tickTime;
private _dirtyCellIds = createHashMap;
private _dirtyObjectiveIds = createHashMap;
private _eastOwnedCells = 0;
private _westOwnedCells = 0;
private _ownerByCell = createHashMap;

FLO_ObjectivePressureDirtyIds = createHashMap;

{
    private _cell = FLO_ObjectiveCells get _x;
    private _owner = _cell get "owner";

    _ownerByCell set [_x, _owner];

    if (_owner isEqualTo east) then {
        _eastOwnedCells = _eastOwnedCells + 1;
    };

    if (_owner isEqualTo west) then {
        _westOwnedCells = _westOwnedCells + 1;
    };
} forEach FLO_ObjectiveGridCellIds;

{
    private _cell = FLO_ObjectiveCells get _x;

    if ([_cell, _eastOwnedCells, _westOwnedCells, _ownerByCell] call FLO_fnc_objectiveEvaluateCell) then {
        _dirtyCellIds set [_x, true];
    };
} forEach FLO_ObjectiveGridCellIds;

{
    _dirtyCellIds set [_x, true];
} forEach ([_ownerByCell] call FLO_fnc_objectiveEvaluateGridInfluence);

{
    private _objective = FLO_Objectives get _x;

    if ([_objective, _ownerByCell] call FLO_fnc_objectivePressureTick) then {
        _dirtyObjectiveIds set [_x, true];
    };
} forEach keys FLO_Objectives;

{
    _dirtyObjectiveIds set [_x, true];
} forEach keys FLO_ObjectivePressureDirtyIds;

{
    private _objective = FLO_Objectives get _x;

    if ([_objective] call FLO_fnc_objectiveResolveObjective) then {
        _dirtyObjectiveIds set [_x, true];
    };

    if ([_objective] call FLO_fnc_objectiveFinalizeDueUpgrade) then {
        _dirtyObjectiveIds set [_x, true];
    };
} forEach keys FLO_Objectives;

private _changedCellIds = keys _dirtyCellIds;
private _changedObjectiveIds = keys _dirtyObjectiveIds;
private _cellsChanged = count _changedCellIds;
private _objectivesChanged = count _changedObjectiveIds;
private _resolutionMs = (diag_tickTime - _resolutionT0) * 1000;
private _publishT0 = diag_tickTime;

[false, _changedCellIds, _changedObjectiveIds] call FLO_fnc_objectivePublishSnapshot;

if ((_cellsChanged > 0) || {_objectivesChanged > 0}) then {
    ["objectiveChanged"] call FLO_fnc_persistenceScheduleSave;
};

private _publishMs = (diag_tickTime - _publishT0) * 1000;
private _totalMs = (diag_tickTime - _t0) * 1000;

FLO_ObjectiveLastDiagnostics = createHashMapFromArray [
    ["objectiveCount", count (keys FLO_Objectives)],
    ["cellCount", count (keys FLO_ObjectiveCells)],
    ["playersConsidered", count _presence],
    ["cellsChanged", _cellsChanged],
    ["objectivesChanged", _objectivesChanged],
    ["publicationsSent", FLO_ObjectivePublicationsSent],
    ["evalMsTotal", _totalMs],
    ["evalMsPresence", _presenceMs],
    ["evalMsBucketing", _bucketMs],
    ["evalMsResolution", _resolutionMs],
    ["evalMsPublish", _publishMs]
];

if (_totalMs > FLO_ObjectivePerfLogThresholdMs) then {
    diag_log format [
        "[FLO][PERF] Objective eval took %1 ms objectives=%2 cells=%3 players=%4 cellsChanged=%5 objectivesChanged=%6 bucketMs=%7 publishMs=%8",
        _totalMs,
        count (keys FLO_Objectives),
        count FLO_ObjectiveGridCellIds,
        count _presence,
        _cellsChanged,
        _objectivesChanged,
        _bucketMs,
        _publishMs
    ];
};
