params ["_source"];

_source params ["_sourceName", "_patches", "_addons", "_prefixes", "_contains", "_categories"];

if (_patches isEqualTo []) exitWith {
    true
};

private _loaded = false;

{
    if (isClass (configFile >> "CfgPatches" >> _x)) exitWith {
        _loaded = true;
    };
} forEach _patches;

_loaded
