params ["_player", ["_factionClass", "", [""]]];

if (!isServer) exitWith {};
if (isNull _player) exitWith {};

private _owner = owner _player;

if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    diag_log format [
        "[FLO][Command] Rejected faction vote from owner %1 for owner %2",
        remoteExecutedOwner,
        _owner
    ];
};

private _side = side group _player;

if !(_side in [west, east]) exitWith {};
if (_factionClass isEqualTo "") exitWith {};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;
private _state = FLO_CommandSideState get _sideKey;

if ((_state get "factionClass") isNotEqualTo "") exitWith {
    [_player] call FLO_fnc_commandSendSnapshot;
};

if !(_state get "factionVoteOpen") exitWith {
    [_player] call FLO_fnc_commandSendSnapshot;
};

if (diag_tickTime >= (_state get "factionVoteEndsAt")) exitWith {
    [_sideKey, "faction", _state get "factionVotePromptId"] call FLO_fnc_commandExpireVoteWindow;
};

private _validFaction = ((FLO_CommandFactionOptions get _sideKey) findIf {
    (_x get "class") isEqualTo _factionClass
}) isNotEqualTo -1;

if (!_validFaction) exitWith {
    [_player] call FLO_fnc_commandSendSnapshot;
};

private _votes = _state get "factionVotes";
private _playerUid = getPlayerUID _player;
private _currentVote = "";

if (_playerUid in _votes) then {
    _currentVote = _votes get _playerUid;
};

if (_currentVote isEqualTo _factionClass) exitWith {
    [_player] call FLO_fnc_commandSendSnapshot;
};

_votes set [_playerUid, _factionClass];

FLO_CommandRevision = FLO_CommandRevision + 1;
[_side] call FLO_fnc_commandResolveFactionVote;
[_player] call FLO_fnc_commandSendSnapshot;
[_side] call FLO_fnc_commandScheduleBroadcastSide;
