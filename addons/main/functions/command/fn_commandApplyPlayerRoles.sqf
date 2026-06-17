params ["_player"];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _roles = [];
private _medicalClass = 0;
private _engineerLevel = 0;
private _side = side group _player;

if (_side in [west, east]) then {
    private _sideKey = [_side] call FLO_fnc_resourceSideKey;
    private _state = FLO_CommandSideState get _sideKey;
    private _roleAssignments = _state get "roleAssignments";
    private _uid = getPlayerUID _player;

    {
        if (_uid in (_roleAssignments get _x)) then {
            _roles pushBack _x;
        };
    } forEach FLO_CommandRoleOrder;

    if (_uid in (_roleAssignments get "doctor")) then {
        _medicalClass = 2;
    } else {
        if (_uid in (_roleAssignments get "medic")) then {
            _medicalClass = 1;
        };
    };

    if (_uid in (_roleAssignments get "engineer")) then {
        _engineerLevel = 1;
    };
};

_player setVariable ["FLO_CommandRoles", _roles, true];
_player setVariable ["ace_medical_medicClass", _medicalClass, true];
_player setVariable ["ace_isEngineer", _engineerLevel, true];

_player setUnitTrait ["Medic", _medicalClass > 0];
_player setUnitTrait ["Engineer", _engineerLevel > 0];
