params ["_sideKey"];

private _side = [west, east] select (_sideKey isEqualTo "EAST");
private _state = FLO_CommandSideState get _sideKey;
private _roleAssignments = _state get "roleAssignments";
private _caps = [_side] call FLO_fnc_commandRoleCaps;
private _activeUids = createHashMap;
private _commanderUid = _state get "commanderUid";
private _changed = false;
private _doctorUids = createHashMap;

{
    _activeUids set [getPlayerUID _x, true];
} forEach ([_side] call FLO_fnc_commandSidePlayers);

{
    private _role = _x;
    private _current = +(_roleAssignments get _role);
    private _next = [];
    private _cap = _caps get _role;

    {
        private _uid = _x;
        private _allowed = (_uid isNotEqualTo "") && {_uid in _activeUids} && {!(_uid in _next)};

        if (_allowed && {_role isEqualTo "deputy"} && {_uid isEqualTo _commanderUid}) then {
            _allowed = false;
        };

        if (_allowed && {_role isEqualTo "medic"} && {_uid in _doctorUids}) then {
            _allowed = false;
        };

        if (_allowed) then {
            _next pushBack _uid;
        };
    } forEach _current;

    while {(count _next) > _cap} do {
        _next deleteAt ((count _next) - 1);
    };

    if (_role isEqualTo "doctor") then {
        {
            _doctorUids set [_x, true];
        } forEach _next;
    };

    if (_next isNotEqualTo _current) then {
        _roleAssignments set [_role, _next];
        _changed = true;
    };
} forEach ["deputy", "doctor", "medic", "engineer"];

if (_changed) then {
    [_sideKey] call FLO_fnc_commandSyncRoleGrants;
};

_changed
