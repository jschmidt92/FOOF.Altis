params [
    ["_className", "", [""]],
    ["_finalPos", [0, 0, 0], [[]]],
    ["_finalDir", 0, [0]],
    ["_vectorUp", [0, 0, 1], [[]]]
];

if (!isServer || { _className isEqualTo "" }) exitWith { objNull };

private _spawnPosAGL = ASLToAGL _finalPos;
private _entity = createVehicle [_className, _spawnPosAGL, [], 0, "CAN_COLLIDE"];

_entity allowDamage false;
_entity enableSimulationGlobal false;
_entity setPosASL _finalPos;
_entity setDir _finalDir;
_entity setVectorUp _vectorUp;
_entity setVelocity [0, 0, 0];
_entity enableSimulationGlobal true;

[_entity] spawn {
    params ["_entity"];

    sleep 5;
    _entity allowDamage true;
};

_entity
