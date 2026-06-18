params [
    "_objective",
    "_event",
    ["_attackerSide", sideUnknown, [sideUnknown]]
];

private _name = _objective get "name";
private _owner = _objective get "owner";
private _defenderPayload = createHashMap;
private _attackerPayload = createHashMap;

switch (_event) do {
    case "frontline": {
        if (_owner in [west, east]) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "AO"],
                ["message", format ["%1 is now on the line of contact.", _name]],
                ["type", "info"],
                ["duration", 6]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;

            private _enemySide = [east, west] select (_owner isEqualTo east);
            _attackerPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "Command"],
                ["message", format ["Command marks %1 as a viable pressure point.", _name]],
                ["type", "info"],
                ["duration", 6]
            ];
            [_enemySide, _attackerPayload] call FLO_fnc_notificationSendSide;
        };
    };
    case "rear": {
        if (_owner in [west, east]) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "AO"],
                ["message", format ["Reports around %1 have gone quiet.", _name]],
                ["type", "success"],
                ["duration", 5]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;
        };
    };
    case "pressure": {
        if ((_owner in [west, east]) && {_attackerSide in [west, east]}) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "AO"],
                ["message", format ["Reports indicate sustained enemy movement around %1.", _name]],
                ["type", "warning"],
                ["duration", 7]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;

            _attackerPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "Command"],
                ["message", format ["Forward elements are gaining momentum near %1.", _name]],
                ["type", "info"],
                ["duration", 7]
            ];
            [_attackerSide, _attackerPayload] call FLO_fnc_notificationSendSide;
        };
    };
    case "vulnerable": {
        if ((_owner in [west, east]) && {_attackerSide in [west, east]}) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "announce"],
                ["title", "Command"],
                ["message", format ["%1 defenses are exposed. Reinforce immediately.", _name]],
                ["type", "warning"],
                ["duration", 8]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;

            _attackerPayload = createHashMapFromArray [
                ["mode", "announce"],
                ["title", "Command"],
                ["message", format ["%1 is exposed. Assault window open.", _name]],
                ["type", "announcement"],
                ["duration", 8]
            ];
            [_attackerSide, _attackerPayload] call FLO_fnc_notificationSendSide;
        };
    };
    case "windowClosed": {
        if ((_owner in [west, east]) && {_attackerSide in [west, east]}) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "AO"],
                ["message", format ["The exposure around %1 has passed.", _name]],
                ["type", "success"],
                ["duration", 6]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;

            _attackerPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "Command"],
                ["message", format ["The assault window at %1 has closed.", _name]],
                ["type", "warning"],
                ["duration", 6]
            ];
            [_attackerSide, _attackerPayload] call FLO_fnc_notificationSendSide;
        };
    };
    case "stalled": {
        if ((_owner in [west, east]) && {_attackerSide in [west, east]}) then {
            _defenderPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "AO"],
                ["message", format ["Enemy pressure near %1 has broken.", _name]],
                ["type", "success"],
                ["duration", 6]
            ];
            [_owner, _defenderPayload] call FLO_fnc_notificationSendSide;

            _attackerPayload = createHashMapFromArray [
                ["mode", "notify"],
                ["title", "Command"],
                ["message", format ["Momentum near %1 has stalled.", _name]],
                ["type", "warning"],
                ["duration", 6]
            ];
            [_attackerSide, _attackerPayload] call FLO_fnc_notificationSendSide;
        };
    };
};
