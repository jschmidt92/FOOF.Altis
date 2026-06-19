params ["_side", ["_allowPlurality", false, [false]]];

if (!isServer) exitWith { false };

private _sideKey = [_side] call FLO_fnc_resourceSideKey;
private _state = FLO_CommandSideState get _sideKey;

if ((_state get "factionClass") isNotEqualTo "") exitWith {
    _state set ["factionVoteOpen", false];
    _state set ["factionVoteReason", ""];
    _state set ["factionVoteEndsAt", 0];
    _state set ["factionVotePromptId", ""];
    _state set ["factionVotes", createHashMap];
    false
};

private _players = [_side] call FLO_fnc_commandSidePlayers;
private _votes = _state get "factionVotes";
private _activeUids = createHashMap;
private _optionsByClass = createHashMap;

{
    _activeUids set [getPlayerUID _x, true];
} forEach _players;

{
    _optionsByClass set [_x get "class", _x];
} forEach (FLO_CommandFactionOptions get _sideKey);

{
    if !(_x in _activeUids) then {
        _votes deleteAt _x;
    };
} forEach keys _votes;

private _requiredVotes = (floor ((count _players) / 2)) + 1;
private _voteCounts = createHashMap;

{
    private _factionClass = _y;

    if (_factionClass in _optionsByClass) then {
        private _count = 0;
        if (_factionClass in _voteCounts) then {
            _count = _voteCounts get _factionClass;
        };

        _voteCounts set [_factionClass, _count + 1];
    };
} forEach _votes;

private _winnerClass = "";
private _winnerVotes = 0;
private _winnerTied = false;
private _fallback = false;

{
    if (_y > _winnerVotes) then {
        _winnerClass = _x;
        _winnerVotes = _y;
        _winnerTied = false;
    } else {
        if (_y isEqualTo _winnerVotes) then {
            _winnerTied = true;
        };
    };
} forEach _voteCounts;

if (_winnerTied && {_allowPlurality}) then {
    private _tiedClasses = [];

    {
        if (_y isEqualTo _winnerVotes) then {
            _tiedClasses pushBack _x;
        };
    } forEach _voteCounts;

    _tiedClasses sort true;
    _winnerClass = _tiedClasses # 0;
    _winnerTied = false;
    _fallback = true;
};

if ((_winnerClass isEqualTo "") && {_allowPlurality} && {(count _players) > 0}) then {
    private _options = FLO_CommandFactionOptions get _sideKey;

    if ((count _options) > 0) then {
        _winnerClass = (_options # 0) get "class";
        _winnerVotes = 0;
        _fallback = true;
    };
};

if (_winnerClass isEqualTo "") exitWith { false };
if ((_winnerVotes < _requiredVotes) && {!_allowPlurality}) exitWith { false };

private _winner = _optionsByClass get _winnerClass;
_state set ["factionClass", _winnerClass];
_state set ["factionName", _winner get "displayName"];
_state set ["factionVoteOpen", false];
_state set ["factionVoteReason", ""];
_state set ["factionVoteEndsAt", 0];
_state set ["factionVotePromptId", ""];

[_side] call FLO_fnc_spawnEquipFreshSideUniforms;

FLO_CommandRevision = FLO_CommandRevision + 1;
["factionResolved"] call FLO_fnc_persistenceScheduleSave;

diag_log format [
    "[FLO][Command] %1 faction selected class=%2 name=%3 votes=%4 required=%5 plurality=%6 fallback=%7",
    _sideKey,
    _winnerClass,
    _winner get "displayName",
    _winnerVotes,
    _requiredVotes,
    _allowPlurality,
    _fallback
];

true
