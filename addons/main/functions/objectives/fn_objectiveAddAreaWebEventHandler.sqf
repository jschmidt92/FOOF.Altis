params ["_control"];

// HEMTT does not know the CT_WEBBROWSER JSDialog event yet.
// [_control] call compile "params ['_control']; _control ctrlAddEventHandler ['JSDialog', { params ['_control', '_isConfirmDialog', '_message']; [_control, _isConfirmDialog, _message] call FLO_fnc_objectiveHandleAreaUiEvent; }];";

_control ctrlAddEventHandler ["JSDialog", { 
    params ['_control', '_isConfirmDialog', '_message'];
    [_control, _isConfirmDialog, _message] call FLO_fnc_objectiveHandleAreaUiEvent;
}];
