params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "command::ready": {
        uiNamespace setVariable ["FLO_CommandVoteControl", _control];
        FLO_CommandVoteBrowserReady = true;
        FLO_CommandVoteRenderKey = "";

        if ("sideKey" in FLO_CommandSnapshot) then {
            [] call FLO_fnc_commandUpdateVoteDialog;
        } else {
            [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];
        };
    };
    case "command::voteCommander": {
        [player, _data get "uid"] remoteExecCall ["FLO_fnc_commandVoteCommander", 2];
    };
    case "command::voteFaction": {
        [player, _data get "class"] remoteExecCall ["FLO_fnc_commandVoteFaction", 2];
    };
    case "command::assignRole": {
        [player, _data get "uid", _data get "role"] remoteExecCall ["FLO_fnc_commandAssignRole", 2];
    };
    case "command::clearRole": {
        [player, _data get "uid", _data get "role"] remoteExecCall ["FLO_fnc_commandClearRole", 2];
    };
    case "command::refresh": {
        FLO_CommandVoteRenderKey = "";
        [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];
    };
    case "command::close": {
        if ("votePromptId" in FLO_CommandSnapshot) then {
            FLO_CommandVoteDismissedPromptId = FLO_CommandSnapshot get "votePromptId";
        };

        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Command] Unhandled command vote UI event: %1", _event];
    };
};

true
