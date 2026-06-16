if (!hasInterface) exitWith { false };

private _side = side group player;

if !(_side in [west, east]) exitWith {
    hint "Deployment is only available to BLUFOR and OPFOR.";
    false
};

private _display = findDisplay FLO_FOBDeployDialogIdd;

if (!isNull _display) exitWith {
    FLO_FOBDeployRenderKey = "";
    [] call FLO_fnc_fobUpdateDeployDialog;
    true
};

createDialog "FLO_DeployDialog";
_display = findDisplay FLO_FOBDeployDialogIdd;

if (isNull _display) exitWith { false };

FLO_FOBDeployBrowserReady = false;
FLO_FOBDeployRenderKey = "";

private _control = _display displayCtrl FLO_FOBDeployBrowserIdc;
uiNamespace setVariable ["FLO_DeployControl", _control];

[_control] call FLO_fnc_fobAddDeployWebEventHandler;
[_control, ["LoadFile", "\z\foof\addons\main\ui\deploy\index.html"]] call FLO_fnc_fobDeployWebAction;

true
