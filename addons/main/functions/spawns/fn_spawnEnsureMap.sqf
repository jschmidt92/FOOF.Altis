params [["_unit", player, [objNull]]];

if (!hasInterface) exitWith {};
if (!local _unit) exitWith {};
if ("ItemMap" in assignedItems _unit) exitWith {};

_unit linkItem "ItemMap";
