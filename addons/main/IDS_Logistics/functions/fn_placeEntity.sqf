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
private _camera = missionNamespace getVariable ["IDS_LOGISTICS_CAM", objNull];
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
if (!isNil "IDS_Logistics_scrollHandler") then { (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler]; };
if (!isNil "IDS_Logistics_keyDownHandler") then { (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler]; };
if (!isNil "IDS_Logistics_keyUpHandler") then { (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler]; };
if (!isNil "IDS_Logistics_dirUpdateEH") then { [IDS_Logistics_dirUpdateEH] call CBA_fnc_removePerFrameHandler; };

// Reset global state variables
IDS_Logistics_isHolding = false;
IDS_Logistics_currentEntity = objNull;
