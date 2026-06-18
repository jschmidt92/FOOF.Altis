params ["_objective", "_oldOwner", "_newOwner"];

private _oldLevel = floor (_objective get "level");
private _restoreOwner = _objective get "capturedRestoreOwner";
private _restoreLevel = floor (_objective get "capturedRestoreLevel");
private _restoreExpiresAt = _objective get "capturedRestoreExpiresAt";
private _now = diag_tickTime;

_objective set ["pendingUpgradeLevel", 0];
_objective set ["pendingUpgradeStartedAt", 0];
_objective set ["pendingUpgradeCompleteAt", 0];

if (
    (_newOwner in [west, east]) &&
    {_newOwner isEqualTo _restoreOwner} &&
    {_restoreLevel > _oldLevel} &&
    {_now <= _restoreExpiresAt}
) exitWith {
    _objective set ["level", _restoreLevel min FLO_ObjectiveMaxLevel];
    _objective set ["capturedRestoreOwner", sideUnknown];
    _objective set ["capturedRestoreLevel", 0];
    _objective set ["capturedRestoreExpiresAt", 0];
    _objective set ["lastLevelChanged", _now];

    diag_log format [
        "[FLO][Objective] AO %1 recaptured by %2 within restore window; level restored to %3",
        _objective get "id",
        [_newOwner] call FLO_fnc_objectiveSideKey,
        _objective get "level"
    ];
};

if ((_oldOwner in [west, east]) && {_newOwner in [west, east]} && {_oldOwner isNotEqualTo _newOwner}) exitWith {
    _objective set ["level", (_oldLevel - 1) max 0];
    _objective set ["capturedRestoreOwner", _oldOwner];
    _objective set ["capturedRestoreLevel", _oldLevel];
    _objective set ["capturedRestoreExpiresAt", _now + FLO_ObjectiveRestoreWindow];
    _objective set ["lastLevelChanged", _now];

    diag_log format [
        "[FLO][Objective] AO %1 captured by %2 from %3; level reduced from %4 to %5 restoreWindow=%6",
        _objective get "id",
        [_newOwner] call FLO_fnc_objectiveSideKey,
        [_oldOwner] call FLO_fnc_objectiveSideKey,
        _oldLevel,
        _objective get "level",
        FLO_ObjectiveRestoreWindow
    ];
};

if ((_oldOwner in [west, east]) && {_newOwner isEqualTo sideUnknown}) exitWith {
    _objective set ["level", (_oldLevel - 1) max 0];
    _objective set ["capturedRestoreOwner", _oldOwner];
    _objective set ["capturedRestoreLevel", _oldLevel];
    _objective set ["capturedRestoreExpiresAt", _now + FLO_ObjectiveRestoreWindow];
    _objective set ["lastLevelChanged", _now];

    diag_log format [
        "[FLO][Objective] AO %1 destabilized from %2; level reduced from %3 to %4 restoreWindow=%5",
        _objective get "id",
        [_oldOwner] call FLO_fnc_objectiveSideKey,
        _oldLevel,
        _objective get "level",
        FLO_ObjectiveRestoreWindow
    ];
};

if (_newOwner isEqualTo sideUnknown) exitWith {
    _objective set ["lastLevelChanged", _now];
};
