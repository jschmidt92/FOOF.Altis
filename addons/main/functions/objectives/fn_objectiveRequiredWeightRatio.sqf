params ["_objective"];

private _baseRatio = _objective get "requiredWeightRatio";
private _owner = _objective get "owner";

if !(_owner in [west, east]) exitWith { _baseRatio };

private _level = floor (_objective get "level");
private _attackerSide = [west, east] select (_owner isEqualTo west);
private _multiplier = [_objective, _attackerSide] call FLO_fnc_objectivePressureMultiplier;

(_baseRatio + (_level * FLO_ObjectiveRequiredWeightRatioPerLevel * _multiplier)) min FLO_ObjectiveRequiredWeightRatioMax
