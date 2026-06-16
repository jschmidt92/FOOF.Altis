params ["_snapshot"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    diag_log format ["[FLO][Command] Rejected command snapshot from owner %1", remoteExecutedOwner];
};

FLO_CommandSnapshot = _snapshot;

if (_snapshot get "shouldPromptVote") then {
    private _promptId = _snapshot get "votePromptId";
    private _display = findDisplay FLO_CommandVoteDialogIdd;
    private _isNewPrompt = FLO_CommandLastVotePromptId isNotEqualTo _promptId;
    FLO_CommandVoteCloseRevision = -1;

    if (_isNewPrompt) then {
        FLO_CommandLastVotePromptId = _promptId;
        FLO_CommandVoteDismissedPromptId = "";
        FLO_CommandVoteRenderKey = "";

        if ((_snapshot get "commanderVoteReason") isEqualTo "commanderDisconnected") then {
            hint format [
                "%1 commander left. Vote for a replacement in the next 2 minutes.",
                _snapshot get "sideName"
            ];
        };
    };

    if ((isNull _display) && {FLO_CommandVoteDismissedPromptId isNotEqualTo _promptId}) then {
        [] call FLO_fnc_commandOpenVoteDialog;
    };
} else {
    private _display = findDisplay FLO_CommandVoteDialogIdd;

    if (!isNull _display) then {
        private _revision = _snapshot get "revision";

        if (FLO_CommandVoteCloseRevision isNotEqualTo _revision) then {
            FLO_CommandVoteCloseRevision = _revision;

            [
                {
                    params ["_revision"];

                    if (FLO_CommandVoteCloseRevision isEqualTo _revision) then {
                        private _display = findDisplay FLO_CommandVoteDialogIdd;

                        if (!isNull _display) then {
                            _display closeDisplay 0;
                            uiNamespace setVariable ["FLO_CommandVoteControl", controlNull];
                        };
                    };
                },
                [_revision],
                5
            ] call CBA_fnc_waitAndExecute;
        };
    };
};

[] call FLO_fnc_commandUpdateVoteDialog;

if (!isNull (uiNamespace getVariable ["FLO_DeployControl", controlNull])) then {
    FLO_FOBDeployRenderKey = "";
    [] call FLO_fnc_fobUpdateDeployDialog;
};
