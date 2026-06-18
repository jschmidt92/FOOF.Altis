params ["_objective", "_attackerSide"];

private _vulnerableSide = _objective get "vulnerableSide";
private _vulnerableExpiresAt = _objective get "vulnerableExpiresAt";

if ((_vulnerableSide isEqualTo _attackerSide) && {diag_tickTime < _vulnerableExpiresAt}) exitWith {
    FLO_ObjectivePressureVulnerableHardeningMultiplier
};

1
