params ["_gearEntries"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2}) exitWith {
    diag_log format ["[FLO][Store] Rejected store kit application from owner %1", remoteExecutedOwner];
};

if ((typeName _gearEntries) isNotEqualTo "ARRAY") exitWith {};

{
    private _targetCategory = _x;

    {
        if ((typeName _x) isNotEqualTo "HASHMAP") then { continue };
        if (!(("className" in _x) && {"category" in _x})) then { continue };

        private _className = _x get "className";
        private _category = _x get "category";

        if (_category isNotEqualTo _targetCategory) then { continue };

        private _quantity = 1;
        private _container = "auto";

        if ("quantity" in _x) then {
            _quantity = floor (_x get "quantity");
        };

        if ("container" in _x) then {
            _container = _x get "container";
        };

        if !(_container in FLO_StoreGearContainers) then {
            _container = "auto";
        };

        if (_quantity < 1) then { continue };

        switch (_category) do {
            case "uniforms": {
                removeUniform player;
                player forceAddUniform _className;
            };
            case "vests": {
                removeVest player;
                player addVest _className;
            };
            case "backpacks": {
                removeBackpack player;
                player addBackpack _className;
            };
            case "headgear": {
                removeHeadgear player;
                player addHeadgear _className;
            };
            case "facewear": {
                removeGoggles player;
                player addGoggles _className;
            };
            case "primary": {
                if ((primaryWeapon player) isNotEqualTo "") then {
                    player removeWeapon (primaryWeapon player);
                };

                player addWeapon _className;
            };
            case "handgun": {
                if ((handgunWeapon player) isNotEqualTo "") then {
                    player removeWeapon (handgunWeapon player);
                };

                player addWeapon _className;
            };
            case "secondary": {
                if ((secondaryWeapon player) isNotEqualTo "") then {
                    player removeWeapon (secondaryWeapon player);
                };

                player addWeapon _className;
            };
            case "ammo";
            case "mines": {
                for "_i" from 1 to _quantity do {
                    [player, _className, _container] call FLO_fnc_storeAddInventoryItem;
                };
            };
            default {
                private _itemType = _className call BIS_fnc_itemType;
                private _kind = _itemType select 1;

                if (_kind in ["GPS", "Map", "Compass", "Watch", "Radio", "NVGoggles", "Terminal"]) then {
                    player linkItem _className;
                } else {
                    for "_i" from 1 to _quantity do {
                        [player, _className, _container] call FLO_fnc_storeAddInventoryItem;
                    };
                };
            };
        };
    } forEach _gearEntries;
} forEach ["uniforms", "vests", "backpacks", "headgear", "facewear", "primary", "handgun", "secondary", "attachments", "misc", "ammo", "mines"];

["Purchased kit applied.", "success", "Store"] call FLO_fnc_notify;
