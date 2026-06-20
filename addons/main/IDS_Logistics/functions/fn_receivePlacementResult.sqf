params ["_success", "_message"];

if (!hasInterface) exitWith {};
if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    diag_log format ["[IDS_Logistics] Rejected placement result from owner %1", remoteExecutedOwner];
};

private _content = if (_success) then {
    _message
} else {
    format ["<t color='#FF4444'>ERROR</t><br/>%1", _message]
};

if (isNil "IDS_Logistics_Cam" || {isNull IDS_Logistics_Cam}) then {
    [_message, ["error", "success"] select _success, "Logistics"] call FLO_fnc_notify;
} else {
    [_content, [3, 2] select _success] call IDS_Logistics_fnc_cameraHint;
};
