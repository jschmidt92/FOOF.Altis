params ["_objective"];

private _oldOwner = _objective get "owner";
private _oldState = _objective get "state";
private _oldEastWeight = _objective get "eastWeight";
private _oldWestWeight = _objective get "westWeight";
private _oldTotalWeight = _objective get "totalWeight";
private _cellIds = _objective get "cellIds";
private _anchorCell = FLO_ObjectiveCells get (_objective get "anchorCellId");
private _anchorOwner = _anchorCell get "owner";
private _requiredWeightRatio = [_objective] call FLO_fnc_objectiveRequiredWeightRatio;
private _eastWeight = 0;
private _westWeight = 0;
private _totalWeight = 0;
private _contestedCells = 0;

{
    private _cell = FLO_ObjectiveCells get _x;
    private _weight = _cell get "weight";
    private _cellOwner = _cell get "owner";

    _totalWeight = _totalWeight + _weight;

    if (_cellOwner isEqualTo east) then {
        _eastWeight = _eastWeight + _weight;
    };

    if (_cellOwner isEqualTo west) then {
        _westWeight = _westWeight + _weight;
    };

    if ((_cell get "state") isEqualTo "contested") then {
        _contestedCells = _contestedCells + 1;
    };
} forEach _cellIds;

private _eastQualifies = (_anchorOwner isEqualTo east) && { _eastWeight >= (_totalWeight * _requiredWeightRatio) };
private _westQualifies = (_anchorOwner isEqualTo west) && { _westWeight >= (_totalWeight * _requiredWeightRatio) };
private _newOwner = _oldOwner;
private _newState = "neutral";

if (_eastQualifies) then {
    _newOwner = east;
};

if (_westQualifies) then {
    _newOwner = west;
};

if (!_eastQualifies && !_westQualifies) then {
    if ((_oldOwner isNotEqualTo sideUnknown) && {_anchorOwner isNotEqualTo _oldOwner}) then {
        _newOwner = sideUnknown;
    };
};

if (_newOwner isEqualTo sideUnknown) then {
    _newState = ["neutral", "contested"] select ((_eastWeight + _westWeight) > 0);
} else {
    _newState = "held";

    if (_contestedCells > 0) then {
        _newState = "contested";
    };

    if ((_newOwner isEqualTo east) && {_westWeight > 0}) then {
        _newState = "contested";
    };

    if ((_newOwner isEqualTo west) && {_eastWeight > 0}) then {
        _newState = "contested";
    };
};

_objective set ["owner", _newOwner];
_objective set ["state", _newState];
_objective set ["eastWeight", _eastWeight];
_objective set ["westWeight", _westWeight];
_objective set ["totalWeight", _totalWeight];

if (_oldOwner isNotEqualTo _newOwner) then {
    _objective set ["lastChanged", diag_tickTime];
    [_objective, _oldOwner, _newOwner] call FLO_fnc_objectiveResolveOwnerLevelTransition;
    diag_log format [
        "[FLO][Objective] Objective %1 owner changed from %2 to %3 level=%4",
        _objective get "id",
        [_oldOwner] call FLO_fnc_objectiveSideKey,
        [_newOwner] call FLO_fnc_objectiveSideKey,
        _objective get "level"
    ];
};

(_oldOwner isNotEqualTo _newOwner) ||
{_oldState isNotEqualTo _newState} ||
{_oldEastWeight isNotEqualTo _eastWeight} ||
{_oldWestWeight isNotEqualTo _westWeight} ||
{_oldTotalWeight isNotEqualTo _totalWeight}
