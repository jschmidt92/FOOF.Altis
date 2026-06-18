params [
    "_objectiveId",
    "_side",
    "_amount",
    ["_reason", "pressure", [""]]
];

if !(_objectiveId in FLO_Objectives) exitWith { false };
if !(_side in [west, east]) exitWith { false };
if (_amount <= 0) exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
private _owner = _objective get "owner";

if !(_owner in [west, east]) exitWith { false };
if (_side isEqualTo _owner) exitWith { false };
if !(_objective get "frontline") exitWith { false };

private _pressureKey = ["pressureWest", "pressureEast"] select (_side isEqualTo east);
private _lastKey = ["pressureWestLastAt", "pressureEastLastAt"] select (_side isEqualTo east);
private _reportKey = ["pressureWestReportState", "pressureEastReportState"] select (_side isEqualTo east);
private _oldPressure = _objective get _pressureKey;
private _newPressure = (_oldPressure + _amount) min FLO_ObjectivePressureThreshold;
private _changed = false;

if (_newPressure isNotEqualTo _oldPressure) then {
    _objective set [_pressureKey, _newPressure];
    _objective set [_lastKey, diag_tickTime];
    _changed = true;
};

if (
    (_newPressure >= (FLO_ObjectivePressureThreshold * FLO_ObjectivePressureReportRatio)) &&
    {(_objective get _reportKey) isEqualTo "none"}
) then {
    _objective set [_reportKey, "pressure"];
    [_objective, "pressure", _side] call FLO_fnc_objectivePressureReport;
};

if (
    (_newPressure >= FLO_ObjectivePressureThreshold) &&
    {(_objective get "vulnerableSide") isNotEqualTo _side || {diag_tickTime >= (_objective get "vulnerableExpiresAt")}}
) then {
    _objective set ["vulnerableSide", _side];
    _objective set ["vulnerableExpiresAt", diag_tickTime + FLO_ObjectivePressureVulnerableDuration];
    _objective set [_reportKey, "vulnerable"];
    _changed = true;

    [_objective, "vulnerable", _side] call FLO_fnc_objectivePressureReport;

    diag_log format [
        "[FLO][Objective] AO %1 vulnerable to %2 from pressure reason=%3 pressure=%4",
        _objectiveId,
        [_side] call FLO_fnc_objectiveSideKey,
        _reason,
        _newPressure
    ];
};

if (_changed) then {
    FLO_ObjectivePressureDirtyIds set [_objectiveId, true];
};

_changed
