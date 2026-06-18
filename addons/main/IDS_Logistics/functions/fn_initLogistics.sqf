/**
 * @name IDS_Logistics_fnc_initLogistics
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Initializes the IDS Logistics system.
 * Sets up global variables used throughout the logistics framework
 * and prepares the system for operation.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_initLogistics
 */

IDS_Logistics_PlacedEntities = [];
IDS_Logistics_isHolding = false;
IDS_Logistics_currentEntity = objNull;
IDS_Logistics_scrollHandler = -1;
IDS_Logistics_keyDownHandler = -1;
IDS_Logistics_keyUpHandler = -1;
IDS_Logistics_dirUpdateEH = -1;
IDS_Logistics_entityKilledHandler = -1;

uiNamespace setVariable ["IDS_Logistics_shiftPressed", false];
uiNamespace setVariable ["IDS_Logistics_ctrlPressed", false];
uiNamespace setVariable ["IDS_Logistics_altPressed", false];

IDS_Logistics_Entities = [];
private _entitiesConfig = configFile >> "CfgLogistics" >> "Entities";

if (isServer) then {
    IDS_Logistics_entityKilledHandler = [
        "FLO_eventEntityKilled",
        {
            params ["_unit", "_killer", "_instigator", "_useEffects"];

            if (_unit getVariable ["IDS_Logistics_isPlacedEntity", false]) then {
                [_unit, _killer, _instigator, _useEffects] call IDS_Logistics_fnc_onEntityKilled;
            };
        }
    ] call CBA_fnc_addEventHandler;
};

// Iterate through all entity classes in the config
for "_i" from 0 to (count _entitiesConfig - 1) do {
    private _entityClass = _entitiesConfig select _i;
    
    if (isClass _entityClass) then {
        private _className = configName _entityClass;
        private _category = getText (_entityClass >> "category");
        private _cost = getNumber (_entityClass >> "cost");
        
        IDS_Logistics_Entities pushBack [_className, _category, _cost];
    };
};

diag_log "=== IDS Logistics Initialization ===";
diag_log format ["Loaded %1 buildable entities", count IDS_Logistics_Entities];
diag_log "IDS Logistics initialized.";
