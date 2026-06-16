params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";

switch (_event) do {
    case "deploy::ready": {
        uiNamespace setVariable ["FLO_DeployControl", _control];
        FLO_FOBDeployBrowserReady = true;
        FLO_FOBDeployRenderKey = "";
        [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];
        [player] remoteExecCall ["FLO_fnc_resourceRequestSnapshot", 2];
        [] call FLO_fnc_fobUpdateDeployDialog;
    };
    case "deploy::refresh": {
        FLO_FOBDeployRenderKey = "";
        [player] remoteExecCall ["FLO_fnc_commandRequestSnapshot", 2];
        [player] remoteExecCall ["FLO_fnc_resourceRequestSnapshot", 2];
        [] call FLO_fnc_fobUpdateDeployDialog;
    };
    case "deploy::requestFOB": {
        [player] remoteExecCall ["FLO_fnc_fobRequestDeploy", 2];
    };
    case "deploy::requestCOP": {
        [player, "COP"] remoteExecCall ["FLO_fnc_fobRequestDeploy", 2];
    };
    case "deploy::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][FOB] Unhandled deployment UI event: %1", _event];
    };
};

true
