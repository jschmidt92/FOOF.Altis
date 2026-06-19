params ["_side"];

if (!isServer) exitWith {};

private _sideKey = [_side] call FLO_fnc_resourceSideKey;
private _state = FLO_CommandSideState get _sideKey;

if (_state get "initialVoteStarted") exitWith { false };

_state set ["initialVoteStarted", true];

private _openedCommander = false;
private _openedFaction = false;

if ((_state get "commanderUid") isEqualTo "") then {
    [_sideKey, "commander", "initial", FLO_CommandInitialVoteDuration] call FLO_fnc_commandStartVoteWindow;
    _openedCommander = true;
};

if ((_state get "factionClass") isEqualTo "") then {
    [_sideKey, "faction", "initial", FLO_CommandInitialVoteDuration] call FLO_fnc_commandStartVoteWindow;
    _openedFaction = true;
};

diag_log format [
    "[FLO][Command] %1 initial vote window opened commander=%2 faction=%3",
    _sideKey,
    _openedCommander,
    _openedFaction
];

_openedCommander || {_openedFaction}
