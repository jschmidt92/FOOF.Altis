if (!isServer) exitWith {};

FLO_CommandRevision = 0;
FLO_CommandSideState = createHashMap;
FLO_CommandFactionOptions = createHashMapFromArray [
    ["WEST", [west] call FLO_fnc_commandBuildFactionOptions],
    ["EAST", [east] call FLO_fnc_commandBuildFactionOptions]
];

{
    private _sideKey = _x;

    FLO_CommandSideState set [
        _sideKey,
        createHashMapFromArray [
            ["initialVoteStarted", false],
            ["commanderVoteOpen", false],
            ["commanderVoteReason", ""],
            ["commanderVoteEndsAt", 0],
            ["commanderVotePromptId", ""],
            ["commanderUid", ""],
            ["commanderName", ""],
            ["commanderVotes", createHashMap],
            ["factionVoteOpen", false],
            ["factionVoteReason", ""],
            ["factionVoteEndsAt", 0],
            ["factionVotePromptId", ""],
            ["factionClass", ""],
            ["factionName", ""],
            ["factionVotes", createHashMap],
            ["permissionGrants", createHashMapFromArray [
                ["build", []],
                ["fob", []],
                ["garage", []],
                ["logistics", []],
                ["store", []]
            ]],
            ["roleAssignments", createHashMapFromArray [
                ["deputy", []],
                ["medic", []],
                ["doctor", []],
                ["engineer", []]
            ]]
        ]
    ];
} forEach ["WEST", "EAST"];

FLO_CommandPlayerConnectedEh = addMissionEventHandler [
    "PlayerConnected",
    {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [
            {
                params ["_uid", "_owner"];
                [_uid, _owner] call FLO_fnc_commandSyncConnectedPlayer;
            },
            [_uid, _owner],
            3
        ] call CBA_fnc_waitAndExecute;
    }
];

FLO_CommandPlayerDisconnectedEh = addMissionEventHandler [
    "PlayerDisconnected",
    {
        params ["_id", "_uid", "_name"];

        {
            private _sideKey = _x;
            private _state = FLO_CommandSideState get _sideKey;
            private _side = [west, east] select (_sideKey isEqualTo "EAST");

            if ((_state get "commanderUid") isEqualTo _uid) then {
                _state set ["commanderUid", ""];
                _state set ["commanderName", ""];

                [_sideKey, "commander", "commanderDisconnected", FLO_CommandReplacementVoteDuration] call FLO_fnc_commandStartVoteWindow;
                [_side] call FLO_fnc_commandScheduleBroadcastSide;
                ["commanderDisconnected"] call FLO_fnc_persistenceScheduleSave;

                diag_log format [
                    "[FLO][Command] %1 commander %2 disconnected; replacement commander vote opened",
                    _sideKey,
                    _name
                ];
            };

            private _changedSides = [_uid, _sideKey] call FLO_fnc_commandClearUidRoles;

            if (_changedSides isNotEqualTo []) then {
                FLO_CommandRevision = FLO_CommandRevision + 1;
                [_side] call FLO_fnc_commandScheduleBroadcastSide;
                ["commandRoleDisconnect"] call FLO_fnc_persistenceScheduleSave;
            };
        } forEach ["WEST", "EAST"];
    }
];

FLO_CommandEntityRespawnedEh = addMissionEventHandler [
    "EntityRespawned",
    {
        params ["_newEntity", "_oldEntity"];

        if (isPlayer _newEntity) then {
            [_newEntity] call FLO_fnc_commandApplyPlayerRoles;
        };
    }
];

diag_log format [
    "[FLO][Command] Command voting initialized westFactions=%1 eastFactions=%2",
    count (FLO_CommandFactionOptions get "WEST"),
    count (FLO_CommandFactionOptions get "EAST")
];
