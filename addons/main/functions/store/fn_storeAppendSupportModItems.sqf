params ["_itemsByCategory", "_seen"];

private _sources = FLO_StoreSupportModSources select {
    [_x] call FLO_fnc_storeSupportSourceLoaded
};

if (_sources isEqualTo []) exitWith {};

{
    private _cfg = _x;
    private _className = configName _cfg;
    private _scope = getNumber (_cfg >> "scope");
    private _scopeArsenal = getNumber (_cfg >> "scopeArsenal");

    if ((_scope < 1) && {_scopeArsenal < 1}) then { continue };
    if ((getText (_cfg >> "displayName")) isEqualTo "") then { continue };
    if ([_className] call FLO_fnc_storeSupportClassRejected) then { continue };

    private _category = [_className] call FLO_fnc_storeCategoryForWeapon;
    private _isMedicalItem = (getNumber (_cfg >> "ACE_isMedicalItem")) isEqualTo 1;

    if ((_category isEqualTo "") && {_isMedicalItem}) then {
        _category = "misc";
    };

    if (_category isNotEqualTo "misc") then { continue };

    private _sourceIndex = _sources findIf {
        (_category in (_x select 5)) && {[_cfg, _x] call FLO_fnc_storeSupportConfigMatchesSource}
    };

    if (_sourceIndex < 0) then { continue };

    [_itemsByCategory, _seen, _className, "gear", _category] call FLO_fnc_storeAppendCatalogItem;
} forEach ("true" configClasses (configFile >> "CfgWeapons"));

{
    private _cfg = _x;
    private _className = configName _cfg;
    private _scope = getNumber (_cfg >> "scope");
    private _scopeArsenal = getNumber (_cfg >> "scopeArsenal");

    if ((_scope < 1) && {_scopeArsenal < 1}) then { continue };
    if ((getText (_cfg >> "displayName")) isEqualTo "") then { continue };
    if ([_className] call FLO_fnc_storeSupportClassRejected) then { continue };

    private _sourceIndex = _sources findIf {
        (("misc" in (_x select 5)) || {"ammo" in (_x select 5)})
            && {[_cfg, _x] call FLO_fnc_storeSupportConfigMatchesSource}
    };

    if (_sourceIndex < 0) then { continue };

    private _category = ["ammo", "misc"] select ([_cfg] call FLO_fnc_storeIsItemBackedMagazine);
    [_itemsByCategory, _seen, _className, "gear", _category] call FLO_fnc_storeAppendCatalogItem;
} forEach ("true" configClasses (configFile >> "CfgMagazines"));

{
    private _cfg = _x;
    private _className = configName _cfg;
    private _scope = getNumber (_cfg >> "scope");
    private _scopeArsenal = getNumber (_cfg >> "scopeArsenal");
    private _category = "backpacks";

    if ((getNumber (_cfg >> "isBackpack")) isNotEqualTo 1) then { continue };
    if ((_scope < 2) && {_scopeArsenal < 2}) then { continue };
    if ((getText (_cfg >> "displayName")) isEqualTo "") then { continue };
    if ([_className] call FLO_fnc_storeSupportClassRejected) then { continue };

    private _sourceIndex = _sources findIf {
        (_category in (_x select 5)) && {[_cfg, _x] call FLO_fnc_storeSupportConfigMatchesSource}
    };

    if (_sourceIndex < 0) then { continue };

    [_itemsByCategory, _seen, _className, "gear", _category] call FLO_fnc_storeAppendCatalogItem;
} forEach ("true" configClasses (configFile >> "CfgVehicles"));
