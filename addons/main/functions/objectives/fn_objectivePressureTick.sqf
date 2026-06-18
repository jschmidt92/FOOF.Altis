params ["_objective", "_ownerByCell"];

private _oldFrontline = _objective get "frontline";
private _oldPressureWest = _objective get "pressureWest";
private _oldPressureEast = _objective get "pressureEast";
private _oldVulnerableSide = _objective get "vulnerableSide";
private _oldVulnerableExpiresAt = _objective get "vulnerableExpiresAt";
private _owner = _objective get "owner";
private _frontline = false;
private _now = diag_tickTime;

if (_owner in [west, east]) then {
    {
        private _cell = FLO_ObjectiveCells get _x;

        {
            private _neighborOwner = _ownerByCell get _x;

            if ((_neighborOwner in [west, east]) && {_neighborOwner isNotEqualTo _owner}) exitWith {
                _frontline = true;
            };
        } forEach (_cell get "cardinalNeighborIds");

        if (_frontline) exitWith {};
    } forEach (_objective get "cellIds");
};

_objective set ["frontline", _frontline];

if (!_frontline) then {
    _objective set ["pressureWest", 0];
    _objective set ["pressureEast", 0];
    _objective set ["pressureWestReportState", "none"];
    _objective set ["pressureEastReportState", "none"];
    _objective set ["vulnerableSide", sideUnknown];
    _objective set ["vulnerableExpiresAt", 0];
} else {
    if ((_objective get "vulnerableSide") in [west, east] && {_now >= (_objective get "vulnerableExpiresAt")}) then {
        private _expiredSide = _objective get "vulnerableSide";
        private _expiredReportKey = ["pressureWestReportState", "pressureEastReportState"] select (_expiredSide isEqualTo east);

        [_objective, "windowClosed", _expiredSide] call FLO_fnc_objectivePressureReport;
        _objective set [_expiredReportKey, "pressure"];
        _objective set ["vulnerableSide", sideUnknown];
        _objective set ["vulnerableExpiresAt", 0];
    };

    {
        private _cell = FLO_ObjectiveCells get _x;

        if (_owner isEqualTo west && {(_cell get "influenceEast") > 0}) then {
            [_objective get "id", east, FLO_ObjectivePressurePresencePerTick, "presence"] call FLO_fnc_objectivePressureAdd;
        };

        if (_owner isEqualTo east && {(_cell get "influenceWest") > 0}) then {
            [_objective get "id", west, FLO_ObjectivePressurePresencePerTick, "presence"] call FLO_fnc_objectivePressureAdd;
        };
    } forEach (_objective get "cellIds");

    {
        _x params ["_pressureKey", "_lastKey"];

        private _pressure = _objective get _pressureKey;
        private _lastAt = _objective get _lastKey;

        if (_pressure > 0 && {(_now - _lastAt) > FLO_ObjectivePressureDecayGrace}) then {
            private _decay = FLO_ObjectivePressureDecayPerMinute * (FLO_ObjectiveUpdateInterval / 60);
            private _newPressure = (_pressure - _decay) max 0;

            _objective set [_pressureKey, _newPressure];

            if (_newPressure isEqualTo 0) then {
                private _reportKey = ["pressureWestReportState", "pressureEastReportState"] select (_pressureKey isEqualTo "pressureEast");
                private _attackerSide = [west, east] select (_pressureKey isEqualTo "pressureEast");

                if ((_objective get _reportKey) isNotEqualTo "none") then {
                    [_objective, "stalled", _attackerSide] call FLO_fnc_objectivePressureReport;
                    _objective set [_reportKey, "none"];
                };
            };
        };
    } forEach [
        ["pressureWest", "pressureWestLastAt"],
        ["pressureEast", "pressureEastLastAt"]
    ];
};

if (!_oldFrontline && {_objective get "frontline"}) then {
    [_objective, "frontline"] call FLO_fnc_objectivePressureReport;
};

if (_oldFrontline && {!(_objective get "frontline")}) then {
    [_objective, "rear"] call FLO_fnc_objectivePressureReport;
};

(_oldFrontline isNotEqualTo (_objective get "frontline")) ||
{_oldPressureWest isNotEqualTo (_objective get "pressureWest")} ||
{_oldPressureEast isNotEqualTo (_objective get "pressureEast")} ||
{_oldVulnerableSide isNotEqualTo (_objective get "vulnerableSide")} ||
{_oldVulnerableExpiresAt isNotEqualTo (_objective get "vulnerableExpiresAt")}
