params ["_control", "_args"];

// HEMTT's SQF parser does not know ctrlWebBrowserAction yet, so keep the new command behind runtime compilation.
[_control, _args] call FLO_FOBDeployWebActionInvoker;
