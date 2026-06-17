params ["_player"];

private _side = side group _player;
private _sideKey = [_side] call FLO_fnc_resourceSideKey;
private _state = FLO_CommandSideState get _sideKey;
private _players = [_side] call FLO_fnc_commandSidePlayers;
private _playerUid = getPlayerUID _player;
private _commanderVotes = _state get "commanderVotes";
private _factionVotes = _state get "factionVotes";
private _commanderUid = _state get "commanderUid";
private _roleAssignments = _state get "roleAssignments";
private _roleCaps = [_side] call FLO_fnc_commandRoleCaps;
private _roleLabels = createHashMapFromArray [
    ["deputy", "Deputy Commander"],
    ["medic", "Medic"],
    ["doctor", "Doctor"],
    ["engineer", "Engineer"]
];
private _activeUids = createHashMap;
private _playerCommanderVote = "";
private _playerFactionVote = "";
private _now = diag_tickTime;
private _commanderVoteOpen = _state get "commanderVoteOpen";
private _factionVoteOpen = _state get "factionVoteOpen";
private _votePromptParts = [];

if (_commanderVoteOpen) then {
    _votePromptParts pushBack (_state get "commanderVotePromptId");
};

if (_factionVoteOpen) then {
    _votePromptParts pushBack (_state get "factionVotePromptId");
};

if (_playerUid in _commanderVotes) then {
    _playerCommanderVote = _commanderVotes get _playerUid;
};

if (_playerUid in _factionVotes) then {
    _playerFactionVote = _factionVotes get _playerUid;
};

{
    _activeUids set [getPlayerUID _x, true];
} forEach _players;

private _candidates = [];

{
    private _candidateUid = getPlayerUID _x;
    private _voteCount = 0;
    private _candidateRoles = [];

    {
        if (_y isEqualTo _candidateUid) then {
            _voteCount = _voteCount + 1;
        };
    } forEach _commanderVotes;

    {
        if (_candidateUid in (_roleAssignments get _x)) then {
            _candidateRoles pushBack _x;
        };
    } forEach FLO_CommandRoleOrder;

    _candidates pushBack createHashMapFromArray [
        ["uid", _candidateUid],
        ["name", name _x],
        ["votes", _voteCount],
        ["isSelf", _candidateUid isEqualTo _playerUid],
        ["isCommander", _candidateUid isEqualTo _commanderUid],
        ["roles", _candidateRoles]
    ];
} forEach _players;

_candidates = [_candidates, [], { _x get "name" }, "ASCEND"] call BIS_fnc_sortBy;

private _roleSlots = [];

{
    private _role = _x;
    private _activeAssigned = [];

    {
        if (_x in _activeUids) then {
            _activeAssigned pushBack _x;
        };
    } forEach (_roleAssignments get _role);

    _roleSlots pushBack createHashMapFromArray [
        ["role", _role],
        ["label", _roleLabels get _role],
        ["assigned", count _activeAssigned],
        ["cap", _roleCaps get _role]
    ];
} forEach FLO_CommandRoleOrder;

private _factions = [];

{
    private _factionClass = _x get "class";
    private _voteCount = 0;

    {
        if (_y isEqualTo _factionClass) then {
            _voteCount = _voteCount + 1;
        };
    } forEach _factionVotes;

    _factions pushBack createHashMapFromArray [
        ["class", _factionClass],
        ["displayName", _x get "displayName"],
        ["unitCount", _x get "unitCount"],
        ["vehicleCount", _x get "vehicleCount"],
        ["groupCount", _x get "groupCount"],
        ["compatibility", _x get "compatibility"],
        ["votes", _voteCount],
        ["selected", _factionClass isEqualTo (_state get "factionClass")]
    ];
} forEach (FLO_CommandFactionOptions get _sideKey);

private _playerIsCommander = _commanderUid isEqualTo _playerUid;
private _playerRoles = [];

{
    if (_playerUid in (_roleAssignments get _x)) then {
        _playerRoles pushBack _x;
    };
} forEach FLO_CommandRoleOrder;

private _playerIsDeputy = "deputy" in _playerRoles;
private _permissionGrants = _state get "permissionGrants";
private _permissions = createHashMap;

{
    private _permission = _x;
    private _granted = _playerIsCommander;

    if (!_granted && {_permission in _permissionGrants}) then {
        _granted = _playerUid in (_permissionGrants get _permission);
    };

    _permissions set [_permission, _granted];
} forEach ["build", "fob", "garage", "logistics", "store"];

createHashMapFromArray [
    ["revision", FLO_CommandRevision],
    ["sideKey", _sideKey],
    ["sideName", ["BLUFOR", "OPFOR"] select (_side isEqualTo east)],
    ["playerUid", _playerUid],
    ["playerIsCommander", _playerIsCommander],
    ["playerIsDeputy", _playerIsDeputy],
    ["playerRoles", _playerRoles],
    ["shouldPromptVote", _commanderVoteOpen || {_factionVoteOpen}],
    ["votePromptId", _votePromptParts joinString "|"],
    ["commanderVoteOpen", _commanderVoteOpen],
    ["commanderVoteReason", _state get "commanderVoteReason"],
    ["commanderVotePromptId", _state get "commanderVotePromptId"],
    ["commanderVoteSecondsRemaining", 0 max (ceil ((_state get "commanderVoteEndsAt") - _now))],
    ["commanderUid", _commanderUid],
    ["commanderName", _state get "commanderName"],
    ["playerCommanderVote", _playerCommanderVote],
    ["candidates", _candidates],
    ["roleSlots", _roleSlots],
    ["factionVoteOpen", _factionVoteOpen],
    ["factionVoteReason", _state get "factionVoteReason"],
    ["factionVotePromptId", _state get "factionVotePromptId"],
    ["factionVoteSecondsRemaining", 0 max (ceil ((_state get "factionVoteEndsAt") - _now))],
    ["factionClass", _state get "factionClass"],
    ["factionName", _state get "factionName"],
    ["playerFactionVote", _playerFactionVote],
    ["factions", _factions],
    ["requiredVotes", (floor ((count _players) / 2)) + 1],
    ["playerCount", count _players],
    ["permissions", _permissions]
]
