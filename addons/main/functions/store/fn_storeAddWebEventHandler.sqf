params ["_control"];

_control ctrlAddEventHandler ["JSDialog", { 
    params ['_control', '_isConfirmDialog', '_message'];
    [_control, _isConfirmDialog, _message] call FLO_fnc_storeHandleUiEvent;
}];
