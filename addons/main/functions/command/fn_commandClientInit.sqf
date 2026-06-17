if (!hasInterface) exitWith {};

[
    { [] call FLO_fnc_commandCanOpenVoteDialog },
    {
        [
            "FOOF",
            "openCommandPanel",
            ["Open Command Panel", "Open the command voting and role management panel."],
            { [] call FLO_fnc_commandOpenVoteDialog; true },
            {},
            [46, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];

        FLO_CommandClientSnapshotRetryHandle = [
            {
                if ([] call FLO_fnc_commandClientNeedsSnapshot) then {
                    [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];
                } else {
                    [FLO_CommandClientSnapshotRetryHandle] call CBA_fnc_removePerFrameHandler;
                    FLO_CommandClientSnapshotRetryHandle = -1;
                };
            },
            2,
            []
        ] call CBA_fnc_addPerFrameHandler;

        diag_log "[FLO][Command] Client command panel initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
