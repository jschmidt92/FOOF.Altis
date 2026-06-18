params ["_cell", "_captureSide"];

private _seconds = FLO_ObjectiveCellBaseCaptureSeconds;
private _owner = _cell get "owner";

if !(_owner in [west, east]) exitWith { _seconds };
if (_captureSide isEqualTo _owner) exitWith { _seconds };

private _objectiveId = _cell get "objectiveId";

if (_objectiveId isEqualTo "") exitWith { _seconds };

private _objective = FLO_Objectives get _objectiveId;

if ((_objective get "owner") isNotEqualTo _owner) exitWith { _seconds };

private _level = floor (_objective get "level");

if (_level <= 0) exitWith { _seconds };

private _multiplier = [_objective, _captureSide] call FLO_fnc_objectivePressureMultiplier;

_seconds + (_level * FLO_ObjectiveCellCaptureSecondsPerLevel * _multiplier)
