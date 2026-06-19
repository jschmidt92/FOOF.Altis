params ["_sideKey", "_kind", "_reason", "_duration"];

if (!isServer) exitWith {};

private _state = FLO_CommandSideState get _sideKey;

if ((_kind isEqualTo "faction") && {(_state get "factionClass") isNotEqualTo ""}) exitWith { "" };

private _endsAt = diag_tickTime + _duration;
private _promptId = format ["%1:%2:%3:%4", _sideKey, _kind, _reason, floor (_endsAt * 1000)];

switch (_kind) do {
    case "commander": {
        _state set ["commanderVoteOpen", true];
        _state set ["commanderVoteReason", _reason];
        _state set ["commanderVoteEndsAt", _endsAt];
        _state set ["commanderVotePromptId", _promptId];
        _state set ["commanderVotes", createHashMap];
    };
    case "faction": {
        _state set ["factionVoteOpen", true];
        _state set ["factionVoteReason", _reason];
        _state set ["factionVoteEndsAt", _endsAt];
        _state set ["factionVotePromptId", _promptId];
        _state set ["factionVotes", createHashMap];
    };
};

FLO_CommandRevision = FLO_CommandRevision + 1;

[
    {
        params ["_sideKey", "_kind", "_promptId"];
        [_sideKey, _kind, _promptId] call FLO_fnc_commandExpireVoteWindow;
    },
    [_sideKey, _kind, _promptId],
    _duration
] call CBA_fnc_waitAndExecute;

_promptId
