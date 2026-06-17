params [
    ["_uid", "", [""]],
    ["_sideKeyFilter", "", [""]]
];

if (!isServer) exitWith { [] };
if (_uid isEqualTo "") exitWith { [] };

private _changedSides = [];
private _sideKeys = ["WEST", "EAST"];

if (_sideKeyFilter isNotEqualTo "") then {
    _sideKeys = [_sideKeyFilter];
};

{
    private _sideKey = _x;

    if (_sideKey in FLO_CommandSideState) then {
        private _state = FLO_CommandSideState get _sideKey;
        private _roleAssignments = _state get "roleAssignments";
        private _changed = false;

        {
            private _assigned = +(_roleAssignments get _x);

            if (_uid in _assigned) then {
                _roleAssignments set [_x, _assigned - [_uid]];
                _changed = true;
            };
        } forEach FLO_CommandRoleOrder;

        if (_changed) then {
            [_sideKey] call FLO_fnc_commandSyncRoleGrants;
            _changedSides pushBack _sideKey;
        };
    };
} forEach _sideKeys;

_changedSides
