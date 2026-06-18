if (!hasInterface) exitWith {};

private _control = uiNamespace getVariable ["FLO_ObjectiveAreaControl", controlNull];

if (isNull _control) exitWith {};
if (!FLO_ObjectiveAreaBrowserReady) exitWith {};
if !(FLO_ObjectiveAreaActiveId in FLO_ObjectiveClientObjectiveRecords) exitWith {};

private _record = FLO_ObjectiveClientObjectiveRecords get FLO_ObjectiveAreaActiveId;

_record params [
    "_objectiveId",
    "_name",
    "_position",
    "_ownerKey",
    "_objectiveState",
    "_eastWeight",
    "_westWeight",
    "_totalWeight",
    "_cells",
    "_resourceWeight",
    "_locationType",
    "_displayRadius",
    "_level",
    "_levelName",
    "_incomePer15",
    "_upgradeCost",
    "_maxLevel",
    ["_pendingUpgradeLevel", 0],
    ["_pendingUpgradeRemaining", 0],
    ["_capturedRestoreOwnerKey", "NONE"],
    ["_capturedRestoreLevel", 0],
    ["_capturedRestoreRemaining", 0],
    ["_frontline", false],
    ["_pressureWest", 0],
    ["_pressureEast", 0],
    ["_vulnerableSideKey", "NONE"],
    ["_vulnerableRemaining", 0]
];

private _playerSide = side group player;
private _playerSideKey = "NONE";

if (_playerSide in [west, east]) then {
    _playerSideKey = [_playerSide] call FLO_fnc_resourceSideKey;
};
private _balance = 0;

{
    if ((_x isEqualType []) && {(count _x) >= 3} && {(_x # 0) isEqualTo _playerSideKey}) exitWith {
        _balance = _x # 2;
    };
} forEach FLO_ResourceSnapshot;

private _ownerName = switch (_ownerKey) do {
    case "WEST": { "BLUFOR" };
    case "EAST": { "OPFOR" };
    default { "Neutral" };
};
private _attackerPressure = 0;
private _attackerName = "Enemy";

if (_ownerKey isEqualTo "WEST") then {
    _attackerPressure = _pressureEast;
    _attackerName = "OPFOR";
};

if (_ownerKey isEqualTo "EAST") then {
    _attackerPressure = _pressureWest;
    _attackerName = "BLUFOR";
};

private _pressureState = "Rear";

if (_frontline) then {
    _pressureState = "Frontline";
};

if (_attackerPressure > 0) then {
    _pressureState = "Pressured";
};

if (_vulnerableSideKey isNotEqualTo "NONE" && {_vulnerableRemaining > 0}) then {
    _pressureState = "Vulnerable";
};

if (_objectiveState isEqualTo "contested") then {
    _pressureState = "Contested";
};

private _hasAuthority = [player, "build"] call FLO_fnc_commandPlayerHasAuthority;
private _canUpgrade = (_playerSideKey isEqualTo _ownerKey) &&
    {_objectiveState isEqualTo "held"} &&
    {_level < _maxLevel} &&
    {_pendingUpgradeLevel <= 0} &&
    {_hasAuthority};
private _upgradeReason = "";
private _upgradeStatus = "";

if (_pendingUpgradeLevel > 0) then {
    _upgradeStatus = format ["Upgrading to Level %1", _pendingUpgradeLevel];
};

if (_playerSideKey isNotEqualTo _ownerKey) then {
    _upgradeReason = "Your side does not control this AO.";
} else {
    if (_objectiveState isNotEqualTo "held") then {
        _upgradeReason = "AO must be uncontested.";
    } else {
        if (_level >= _maxLevel) then {
            _upgradeReason = "AO is fully upgraded.";
        } else {
            if (_pendingUpgradeLevel > 0) then {
                _upgradeReason = "AO upgrade already in progress.";
            } else {
                if (!_hasAuthority) then {
                    _upgradeReason = "Commander or delegated build authority required.";
                };
            };
        };
    };
};

private _payload = createHashMapFromArray [
    ["id", _objectiveId],
    ["name", _name],
    ["owner", _ownerName],
    ["ownerKey", _ownerKey],
    ["state", _objectiveState],
    ["level", _level],
    ["levelName", _levelName],
    ["incomePer15", _incomePer15],
    ["upgradeCost", _upgradeCost],
    ["maxLevel", _maxLevel],
    ["balance", _balance],
    ["canUpgrade", _canUpgrade],
    ["upgradeReason", _upgradeReason],
    ["upgradeStatus", _upgradeStatus],
    ["pendingUpgradeLevel", _pendingUpgradeLevel],
    ["pendingUpgradeRemaining", _pendingUpgradeRemaining],
    ["capturedRestoreOwner", _capturedRestoreOwnerKey],
    ["capturedRestoreLevel", _capturedRestoreLevel],
    ["capturedRestoreRemaining", _capturedRestoreRemaining],
    ["frontline", _frontline],
    ["pressureState", _pressureState],
    ["attackerName", _attackerName],
    ["attackerPressure", _attackerPressure],
    ["pressureThreshold", FLO_ObjectivePressureThreshold],
    ["vulnerableSide", _vulnerableSideKey],
    ["vulnerableRemaining", _vulnerableRemaining]
];

private _script = format [
    "if (window.FOOFObjective) { window.FOOFObjective.receive(%1); }",
    toJSON _payload
];

[_control, ["ExecJS", _script]] call FLO_fnc_objectiveAreaWebAction;
