params ["_uid", "_owner", ["_attempt", 0, [0]]];

if (!isServer) exitWith {};
if (_uid isEqualTo "") exitWith {};

private _player = objNull;

{
    if ((getPlayerUID _x) isEqualTo _uid) exitWith {
        _player = _x;
    };
} forEach allPlayers;

if (isNull _player) exitWith {
    if (_attempt < 20) then {
        [
            {
                params ["_uid", "_owner", "_attempt"];
                [_uid, _owner, _attempt + 1] call FLO_fnc_commandSyncConnectedPlayer;
            },
            [_uid, _owner, _attempt],
            0.5
        ] call CBA_fnc_waitAndExecute;
    };
};

[_player] call FLO_fnc_commandApplyPlayerRoles;
[_player, 0, _owner] call FLO_fnc_commandRequestSnapshot;
