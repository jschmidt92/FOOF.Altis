params ["_control", "_args"];

// HEMTT's SQF parser does not know ctrlWebBrowserAction yet, so preInit compiles this wrapper once.
// [_control, _args] call FLO_CommandWebActionInvoker;

_control ctrlWebBrowserAction _args;
