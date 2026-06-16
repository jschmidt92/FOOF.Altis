if (!hasInterface) exitWith { createHashMap };

private _side = side group player;
private _sideKey = "";
private _sideName = "UNASSIGNED";

if (_side in [west, east]) then {
    _sideKey = [_side] call FLO_fnc_resourceSideKey;
    _sideName = ["BLUFOR", "OPFOR"] select (_side isEqualTo east);
};

private _balance = 0;
private _income = 0;
private _cellIncome = 0;
private _objectiveIncome = 0;
private _resourceSnapshot = missionNamespace getVariable ["FLO_ResourceSnapshot", []];

{
    if ((_x isEqualType []) && {count _x >= 6} && {(_x # 0) isEqualTo _sideKey}) exitWith {
        _balance = _x # 2;
        _income = _x # 3;
        _cellIncome = _x # 4;
        _objectiveIncome = _x # 5;
    };
} forEach _resourceSnapshot;

private _factionName = "";
private _commanderName = "";
private _playerIsCommander = false;

if ("sideKey" in FLO_CommandSnapshot) then {
    if ((FLO_CommandSnapshot get "sideKey") isEqualTo _sideKey) then {
        _factionName = FLO_CommandSnapshot get "factionName";
        _commanderName = FLO_CommandSnapshot get "commanderName";
        _playerIsCommander = FLO_CommandSnapshot get "playerIsCommander";
    };
};

private _pos = getPosATL player;

createHashMapFromArray [
    ["sideKey", _sideKey],
    ["sideName", _sideName],
    ["grid", mapGridPosition player],
    ["alive", alive player],
    ["onWater", surfaceIsWater _pos],
    ["hasAuthority", [player, "fob"] call FLO_fnc_commandPlayerHasAuthority],
    ["playerIsCommander", _playerIsCommander],
    ["factionName", _factionName],
    ["commanderName", _commanderName],
    ["balance", _balance],
    ["income", _income],
    ["cellIncome", _cellIncome],
    ["objectiveIncome", _objectiveIncome],
    ["fobCost", FLO_FOBDeployCost],
    ["fobRadius", FLO_FOBBuildRadius],
    ["fobMinDistance", FLO_FOBMinDistance],
    ["copCost", FLO_COPDeployCost],
    ["copRadius", FLO_COPBuildRadius],
    ["copMinDistance", FLO_COPMinDistance],
    ["copMaxPerSide", FLO_COPMaxPerSide],
    ["copEnemyDisableRadius", FLO_COPEnemyDisableRadius],
    ["keybind", "Ctrl+Shift+D"]
]
