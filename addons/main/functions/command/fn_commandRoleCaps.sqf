params ["_side"];

private _playerCount = count ([_side] call FLO_fnc_commandSidePlayers);
private _scale = FLO_CommandRoleScalePlayers max 1;
private _scaledSlots = FLO_CommandRoleBaseSlots max (ceil (_playerCount / _scale));

createHashMapFromArray [
    ["deputy", 1],
    ["medic", _scaledSlots],
    ["doctor", FLO_CommandDoctorMaxSlots min _scaledSlots],
    ["engineer", _scaledSlots]
]
