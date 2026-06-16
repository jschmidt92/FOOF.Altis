if (!hasInterface) exitWith {};

[
    { !isNull player },
    {
        [
            "FOOF",
            "openDeploymentPanel",
            ["Open Deployment Panel", "Open the FOOF FOB/COP deployment panel."],
            { [] call FLO_fnc_fobOpenDeployDialog; true },
            {},
            [32, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        {
            private _className = _x;

            {
                if ((_x getVariable ["FLO_FOB_Id", ""]) isNotEqualTo "") then {
                    [_x] call FLO_fnc_fobAddClientAction;
                };
            } forEach allMissionObjects _className;
        } forEach FLO_FOBBuildClasses;

        diag_log "[FLO][FOB] Client base actions and deployment keybind initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
