params [
    ["_title", "", [""]],
    ["_message", "", [""]],
    ["_type", "announcement", [""]],
    ["_duration", FLO_AnnouncementDefaultDuration, [0]]
];

if (!hasInterface) exitWith { "" };
if (_title isEqualTo "") exitWith { "" };

if (_duration <= 0) then {
    _duration = FLO_AnnouncementDefaultDuration;
};

private _display = uiNamespace getVariable ["FLO_AnnouncementDisplay", displayNull];

if (isNull _display) exitWith {
    FLO_AnnouncementLayer cutRsc ["FLO_AnnouncementTitle", "PLAIN"];

    [
        {
            params ["_title", "_message", "_type", "_duration"];

            [_title, _message, _type, _duration] call FLO_fnc_announce;
        },
        [_title, _message, _type, _duration],
        FLO_NotificationRenderRetryDelay
    ] call CBA_fnc_waitAndExecute;

    ""
};

{
    if (!isNull _x) then {
        ctrlDelete _x;
    };
} forEach FLO_AnnouncementControls;

private _style = [_type] call FLO_fnc_notificationStyle;
private _accentColor = _style get "accent";
private _backgroundColor = _style get "background";
private _accentHtml = _style get "accentHtml";
private _token = format ["FLO_ANNOUNCEMENT_%1_%2", diag_tickTime, floor random 1000000];

FLO_AnnouncementToken = _token;

private _w = 0.46 * safeZoneW;
private _h = 0.092 * safeZoneH;
private _x = safeZoneX + ((safeZoneW - _w) / 2);
private _y = safeZoneY + (0.030 * safeZoneH);
private _padX = 0.014 * safeZoneW;

private _group = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
private _bg = _display ctrlCreate ["RscText", -1, _group];
private _topLine = _display ctrlCreate ["RscText", -1, _group];
private _bottomLine = _display ctrlCreate ["RscText", -1, _group];
private _sideLine = _display ctrlCreate ["RscText", -1, _group];
private _rightLine = _display ctrlCreate ["RscText", -1, _group];
private _header = _display ctrlCreate ["RscStructuredText", -1, _group];
private _body = _display ctrlCreate ["RscStructuredText", -1, _group];

FLO_AnnouncementControls = [_group, _bg, _topLine, _bottomLine, _sideLine, _rightLine, _header, _body];

_group ctrlSetPosition [_x, _y, _w, _h];
_group ctrlSetFade 1;
_group ctrlCommit 0;

_bg ctrlSetPosition [0, 0, _w, _h];
_bg ctrlSetBackgroundColor _backgroundColor;
_bg ctrlCommit 0;

_topLine ctrlSetPosition [0, 0, _w, 0.003 * safeZoneH];
_topLine ctrlSetBackgroundColor _accentColor;
_topLine ctrlCommit 0;

_bottomLine ctrlSetPosition [0.018 * safeZoneW, _h - (0.002 * safeZoneH), _w - (0.036 * safeZoneW), 0.002 * safeZoneH];
_bottomLine ctrlSetBackgroundColor _accentColor;
_bottomLine ctrlCommit 0;

_sideLine ctrlSetPosition [0, 0, 0.0045 * safeZoneW, _h];
_sideLine ctrlSetBackgroundColor _accentColor;
_sideLine ctrlCommit 0;

_rightLine ctrlSetPosition [_w - (0.002 * safeZoneW), 0.008 * safeZoneH, 0.002 * safeZoneW, _h - (0.016 * safeZoneH)];
_rightLine ctrlSetBackgroundColor _accentColor;
_rightLine ctrlCommit 0;

_header ctrlSetPosition [_padX, 0.012 * safeZoneH, _w - (_padX * 2), 0.030 * safeZoneH];
_header ctrlSetStructuredText (parseText format [
    "<t color='%1' size='1.00'>%2</t>",
    _accentHtml,
    toUpper _title
]);
_header ctrlCommit 0;

_body ctrlSetPosition [_padX, 0.046 * safeZoneH, _w - (_padX * 2), 0.038 * safeZoneH];
_body ctrlSetStructuredText (parseText format [
    "<t color='#F2F7FA' size='0.82'>%1</t><br/><t color='%2' size='0.56'>%3</t>",
    _message,
    _accentHtml,
    _style get "label"
]);
_body ctrlCommit 0;

_group ctrlSetFade 0;
_group ctrlCommit 0.16;

[
    {
        params ["_token"];

        [_token] call FLO_fnc_notificationClearAnnouncement;
    },
    [_token],
    _duration
] call CBA_fnc_waitAndExecute;

_token
