params [["_objectiveIds", keys FLO_Objectives]];

private _objectiveIds = +_objectiveIds;
_objectiveIds sort true;

private _snapshot = [];

{
    private _objective = FLO_Objectives get _x;
    private _cellSnapshot = [];
    private _cellIds = +(_objective get "cellIds");
    private _pendingUpgradeLevel = _objective get "pendingUpgradeLevel";
    private _pendingUpgradeRemaining = 0;
    private _restoreRemaining = 0;

    _cellIds sort true;

    if (_pendingUpgradeLevel > 0) then {
        _pendingUpgradeRemaining = ((_objective get "pendingUpgradeCompleteAt") - diag_tickTime) max 0;
    };

    if ((_objective get "capturedRestoreOwner") in [west, east]) then {
        _restoreRemaining = ((_objective get "capturedRestoreExpiresAt") - diag_tickTime) max 0;
    };

    {
        private _cell = FLO_ObjectiveCells get _x;
        private _progress = round ((_cell get "progress") * 20) / 20;
        private _role = _cell get "role";

        _cellSnapshot pushBack [
            _cell get "id",
            _role,
            _cell get "position",
            _cell get "radius",
            [_cell get "owner"] call FLO_fnc_objectiveSideKey,
            _cell get "state",
            _progress,
            [_cell get "progressSide"] call FLO_fnc_objectiveSideKey,
            _cell get "influenceEast",
            _cell get "influenceWest"
        ];
    } forEach _cellIds;

    _snapshot pushBack [
        _objective get "id",
        _objective get "name",
        _objective get "position",
        [_objective get "owner"] call FLO_fnc_objectiveSideKey,
        _objective get "state",
        _objective get "eastWeight",
        _objective get "westWeight",
        _objective get "totalWeight",
        _cellSnapshot,
        _objective get "resourceWeight",
        _objective get "locationType",
        _objective get "displayRadius",
        _objective get "level",
        [_objective get "level"] call FLO_fnc_objectiveLevelName,
        [_objective] call FLO_fnc_objectiveIncomePer15,
        [_objective] call FLO_fnc_objectiveUpgradeCost,
        FLO_ObjectiveMaxLevel,
        _pendingUpgradeLevel,
        round _pendingUpgradeRemaining,
        [_objective get "capturedRestoreOwner"] call FLO_fnc_objectiveSideKey,
        _objective get "capturedRestoreLevel",
        round _restoreRemaining,
        _objective get "frontline",
        round (_objective get "pressureWest"),
        round (_objective get "pressureEast"),
        [_objective get "vulnerableSide"] call FLO_fnc_objectiveSideKey,
        round (((_objective get "vulnerableExpiresAt") - diag_tickTime) max 0)
    ];
} forEach _objectiveIds;

_snapshot
