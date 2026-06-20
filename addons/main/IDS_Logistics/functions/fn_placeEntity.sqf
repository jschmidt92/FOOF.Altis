/**
 * @name IDS_Logistics_fnc_placeEntity
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Finalizes the placement of the currently held entity.
 * Camera-based building system only - player-based functionality removed.
 * Handles cleanup of temporary objects and event handlers.
 *
 * @param {None} - Uses globally stored IDS_Logistics_currentEntity
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_placeEntity
 */

// Validate current holding state
if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith { ["No entity to place.", 2] call IDS_Logistics_fnc_cameraHint; };

// Ensure camera mode is active
private _camera = missionNamespace getVariable ["IDS_Logistics_Cam", objNull];
if (isNull _camera) exitWith { ["Camera mode is not active.", 2] call IDS_Logistics_fnc_cameraHint; };

// Extract entity properties before deletion
private _entity = IDS_Logistics_currentEntity;
private _className = typeOf _entity;
private _finalPos = getPosASL _entity;
private _finalDir = getDir _entity;
private _vectorUp = vectorUp _entity;

// Get the center height stored on the entity
private _centerHeight = _entity getVariable ["IDS_Logistics_CenterHeight", 0];

// Get original netId if this was a picked-up entity
private _originalNetId = _entity getVariable ["IDS_Logistics_OriginalNetId", ""];
private _storePurchaseId = _entity getVariable ["FLO_Store_PendingPurchaseId", ""];

["Placement requested: " + _className, 1] call IDS_Logistics_fnc_cameraHint;

// Remove the local preview entity
deleteVehicle _entity;

if (_storePurchaseId isNotEqualTo "") then {
    [_storePurchaseId, _className, _finalPos, _finalDir, _vectorUp, player] remoteExecCall ["FLO_fnc_storeFinalizeVehiclePlacement", 2];
} else {
    // Finalize entity on the server - works for both new and existing entities
    // Include the center height information to prevent sinking
    [_originalNetId, _className, _finalPos, _finalDir, _vectorUp, player, _centerHeight] remoteExecCall ["IDS_Logistics_fnc_finalizeEntity", 2];
};

// Clean up event handlers
private _scroll = missionNamespace getVariable ["IDS_Logistics_scrollHandler", -1];
if (_scroll isNotEqualTo -1) then { (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", _scroll]; IDS_Logistics_scrollHandler = nil; };
private _keyDownEH = missionNamespace getVariable ["IDS_Logistics_keyDownHandler", -1];
if (_keyDownEH isNotEqualTo -1) then { (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyDownEH]; IDS_Logistics_keyDownHandler = nil; };
private _keyUpEH = missionNamespace getVariable ["IDS_Logistics_keyUpHandler", -1];
if (_keyUpEH isNotEqualTo -1) then { (findDisplay 46) displayRemoveEventHandler ["KeyUp", _keyUpEH]; IDS_Logistics_keyUpHandler = nil; };
private _dirUpdate = missionNamespace getVariable ["IDS_Logistics_dirUpdateEH", -1];
if (_dirUpdate isNotEqualTo -1) then { [_dirUpdate] call CBA_fnc_removePerFrameHandler; IDS_Logistics_dirUpdateEH = nil; };

// Reset global state variables
IDS_Logistics_isHolding = false;
IDS_Logistics_currentEntity = objNull;

// If placing a new object (not a pickup and not a store purchase), automatically start placement again
if (_originalNetId isEqualTo "" && _storePurchaseId isEqualTo "") then {
    [_className] call IDS_Logistics_fnc_startPlacement;
};
