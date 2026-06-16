if (!hasInterface) exitWith {};

private _control = uiNamespace getVariable ["FLO_DeployControl", controlNull];

if (isNull _control) exitWith {};
if (!FLO_FOBDeployBrowserReady) exitWith {};

private _snapshot = [] call FLO_fnc_fobBuildDeploySnapshot;
private _renderKey = format [
    "%1|%2|%3|%4|%5|%6|%7|%8",
    _snapshot get "sideKey",
    _snapshot get "grid",
    _snapshot get "alive",
    _snapshot get "onWater",
    _snapshot get "hasAuthority",
    _snapshot get "balance",
    _snapshot get "factionName",
    _snapshot get "commanderName"
];

if (FLO_FOBDeployRenderKey isEqualTo _renderKey) exitWith {};
FLO_FOBDeployRenderKey = _renderKey;

private _script = format [
    "if (window.FOOFDeploy) { window.FOOFDeploy.applySnapshot(%1); }",
    toJSON _snapshot
];

[_control, ["ExecJS", _script]] call FLO_fnc_fobDeployWebAction;
