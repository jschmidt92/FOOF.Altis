if (!isServer) exitWith {};

FLO_StoreCatalogCache = createHashMap;
FLO_StorePendingVehicles = [];
FLO_StorePendingVehicleCounter = 0;
FLO_StorePurchasedVehicles = createHashMap;
FLO_StorePurchasedVehicleCounter = 0;
FLO_StoreDeploymentFunds = createHashMap;
FLO_StorePendingVehicleTtl = 900;
FLO_StoreVehicleSpawnRadius = 40;

FLO_StorePurchasedVehicleKilledEh = [
    "FLO_eventEntityKilled",
    {
        params ["_vehicle"];

        private _assetId = _vehicle getVariable ["FLO_Store_AssetId", ""];

        if (_assetId isNotEqualTo "") then {
            FLO_StorePurchasedVehicles deleteAt _assetId;
            ["storePurchasedVehicleKilled"] call FLO_fnc_persistenceScheduleSave;
        };
    }
] call CBA_fnc_addEventHandler;

diag_log "[FLO][Store] Store system initialized";
