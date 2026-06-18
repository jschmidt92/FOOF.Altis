params ["_cell", "_eastOwnedCells", "_westOwnedCells", "_ownerByCell"];

private _owner = _cell get "owner";
private _state = _cell get "state";
private _progress = _cell get "progress";
private _progressSide = _cell get "progressSide";
private _oldOwner = _owner;
private _oldState = _state;
private _oldProgress = _progress;
private _oldProgressSide = _progressSide;
private _eastCount = _cell get "influenceEast";
private _westCount = _cell get "influenceWest";

private _captureSide = sideUnknown;
private _eastPresent = _eastCount > 0;
private _westPresent = _westCount > 0;
private _decayStep = FLO_ObjectiveCellDecayRate * FLO_ObjectiveUpdateInterval;
private _passiveTargetSide = sideUnknown;

if (!_eastPresent && {!_westPresent}) then {
    _passiveTargetSide = [_cell, _ownerByCell] call FLO_fnc_objectivePassiveTargetSide;
};

if (_eastPresent && _westPresent) then {
    _state = "contested";
} else {
    if (_eastCount >= FLO_ObjectiveMinCapturePlayers) then {
        _captureSide = east;
    };

    if (_westCount >= FLO_ObjectiveMinCapturePlayers) then {
        _captureSide = west;
    };

    if (_captureSide isEqualTo sideUnknown) then {
        if (_owner isEqualTo sideUnknown) then {
            if ((_state isEqualTo "capturing") && {_progressSide isEqualTo _passiveTargetSide} && {_passiveTargetSide isNotEqualTo sideUnknown}) then {
                _state = "capturing";
            } else {
                _progress = (_progress - _decayStep) max 0;
                _state = ["neutral", "capturing"] select (_progress > 0);
            };
        } else {
            if ((_state isEqualTo "capturing") && {_progressSide isNotEqualTo _owner}) then {
                if ((_progressSide isEqualTo _passiveTargetSide) && {_passiveTargetSide isNotEqualTo sideUnknown}) then {
                    _state = "capturing";
                } else {
                    _progress = (_progress - _decayStep) max 0;

                    if (_progress <= 0) then {
                        _progress = 1;
                        _progressSide = _owner;
                        _state = "held";
                    } else {
                        _state = "capturing";
                    };
                };
            } else {
                _progress = 1;
                _progressSide = _owner;
                _state = "held";
            };
        };
    } else {
        if (_owner isEqualTo _captureSide) then {
            _progress = 1;
            _progressSide = _captureSide;
            _state = "held";
        } else {
            private _friendlyNeighborCount = {
                (_ownerByCell get _x) isEqualTo _captureSide
            } count (_cell get "cardinalNeighborIds");
            private _ownedCellCount = [_westOwnedCells, _eastOwnedCells] select (_captureSide isEqualTo east);
            private _captureSideKey = [_captureSide] call FLO_fnc_objectiveSideKey;
            private _initialEntryCapture = (_owner isEqualTo sideUnknown) &&
                {_ownedCellCount isEqualTo 0} &&
                {(_cell get "id") in (FLO_ObjectiveInitialFrontlineCellIds get _captureSideKey)};
            private _frontlineCapture = ((_friendlyNeighborCount > 0) && {_ownedCellCount > 0}) || {_initialEntryCapture};

            if (_frontlineCapture) then {
                private _captureSeconds = [_cell, _captureSide] call FLO_fnc_objectiveCellCaptureSeconds;
                private _captureStep = FLO_ObjectiveUpdateInterval / _captureSeconds;

                if (_progressSide isNotEqualTo _captureSide) then {
                    _progress = 0;
                    _progressSide = _captureSide;
                };

                _progress = (_progress + _captureStep) min 1;
                _state = "capturing";

                if (_progress >= 1) then {
                    _owner = _captureSide;
                    _state = "held";

                    private _objectiveId = _cell get "objectiveId";

                    if (_objectiveId isNotEqualTo "") then {
                        private _amount = [FLO_ObjectivePressureSupportCapture, FLO_ObjectivePressureAnchorCapture] select ((_cell get "role") isEqualTo "anchor");

                        [_objectiveId, _captureSide, _amount, "cellCapture"] call FLO_fnc_objectivePressureAdd;
                    };
                };
            } else {
                if (_owner isEqualTo sideUnknown) then {
                    _progress = (_progress - _decayStep) max 0;
                    _state = ["neutral", "capturing"] select (_progress > 0);
                } else {
                    _progress = 1;
                    _progressSide = _owner;
                    _state = "held";
                };
            };
        };
    };
};

_cell set ["owner", _owner];
_cell set ["state", _state];
_cell set ["progress", _progress];
_cell set ["progressSide", _progressSide];
_cell set ["lastEvaluated", diag_tickTime];

(_oldOwner isNotEqualTo _owner) ||
{ _oldState isNotEqualTo _state } ||
{ _oldProgressSide isNotEqualTo _progressSide } ||
{ (abs (_oldProgress - _progress)) >= 0.01 }
