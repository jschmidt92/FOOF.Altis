params [
    ["_unit", player, [objNull]],
    ["_uniformClass", "", [""]]
];

if (!hasInterface) exitWith {};
if (!local _unit) exitWith {};
if (_uniformClass isEqualTo "") exitWith {};
if ((uniform _unit) isEqualTo _uniformClass) exitWith {};

removeUniform _unit;
_unit forceAddUniform _uniformClass;
