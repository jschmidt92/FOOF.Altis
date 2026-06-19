params ["_className", "_category", "_entryKind"];

private _base = switch (_category) do {
    case "primary": { 250 };
    case "handgun": { 80 };
    case "secondary": { 650 };
    case "uniforms": { 40 };
    case "vests": { 120 };
    case "headgear": { 40 };
    case "facewear": { 20 };
    case "backpacks": { 80 };
    case "attachments": { 75 };
    case "ammo": { 10 };
    case "mines": { 140 };
    case "misc": { 25 };
    case "cars": { 800 };
    case "armor": { 3500 };
    case "helis": { 4500 };
    case "planes": { 8000 };
    case "naval": { 1200 };
    case "static": { 700 };
    default { 1000 };
};

if (_entryKind isEqualTo "vehicle") exitWith {
    [_className, _category] call FLO_fnc_storePriceVehicle
};

private _mass = 0;
private _minePriceAdd = 0;
private _weaponCfg = configNull;
private _itemKind = "";

if (isClass (configFile >> "CfgWeapons" >> _className)) then {
    _weaponCfg = configFile >> "CfgWeapons" >> _className;
    _mass = getNumber (_weaponCfg >> "ItemInfo" >> "mass");

    if (_mass <= 0) then {
        _mass = getNumber (_weaponCfg >> "WeaponSlotsInfo" >> "mass");
    };

    private _itemType = _className call BIS_fnc_itemType;
    _itemKind = _itemType param [1, ""];
};

if (isClass (configFile >> "CfgMagazines" >> _className)) then {
    private _cfg = configFile >> "CfgMagazines" >> _className;
    _mass = getNumber (_cfg >> "mass");

    if (_category isEqualTo "mines") then {
        private _ammoClass = getText (_cfg >> "ammo");
        private _ammoCfg = configFile >> "CfgAmmo" >> _ammoClass;

        if (isClass _ammoCfg) then {
            private _simulation = toLower getText (_ammoCfg >> "simulation");
            private _hit = getNumber (_ammoCfg >> "hit");
            private _indirectHit = getNumber (_ammoCfg >> "indirectHit");
            private _indirectRange = getNumber (_ammoCfg >> "indirectHitRange");
            private _blastScore = (_hit * 0.25) + (_indirectHit * 0.35) + (_indirectRange * 7);

            _minePriceAdd = _minePriceAdd + (ceil (_blastScore / 5) * 5);

            if (_simulation isEqualTo "shotdirectionalbomb") then {
                _minePriceAdd = _minePriceAdd + 80;
            };
        };
    };
};

if (isClass (configFile >> "CfgVehicles" >> _className)) then {
    private _cfg = configFile >> "CfgVehicles" >> _className;
    _mass = getNumber (_cfg >> "maximumLoad");
};

private _price = _base + (ceil (_mass / 6));

if (_minePriceAdd > 0) then {
    _price = _price + _minePriceAdd;
};

if (!isNull _weaponCfg) then {
    private _visionTraits = [_className] call FLO_fnc_storeGearVisionTraits;
    private _hasNvg = _visionTraits get "hasNvg";
    private _hasThermal = _visionTraits get "hasThermal";
    private _thermalModeCount = _visionTraits get "thermalModeCount";
    private _hasThermalResolution = _visionTraits get "hasThermalResolution";

    if (_itemKind isEqualTo "NVGoggles") then {
        _price = _price max 300;
    };

    if (_hasNvg && {_itemKind isNotEqualTo "NVGoggles"}) then {
        _price = _price + 250;
    };

    if (_hasThermal) then {
        private _thermalBase = switch (true) do {
            case (_itemKind isEqualTo "NVGoggles"): { 3500 };
            case (_category isEqualTo "attachments"): { 3000 };
            default { 2800 };
        };
        private _thermalModeAdd = ((_thermalModeCount max 1) min 5) * 250;
        private _thermalResolutionAdd = [0, 600] select _hasThermalResolution;

        _price = (_price max 300) + _thermalBase + _thermalModeAdd + _thermalResolutionAdd;
    };
};

5 max ((ceil (_price / 5)) * 5)
