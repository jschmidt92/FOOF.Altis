/**
 * @name IDS_Logistics_fnc_initBuildCamera
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Initializes the IDS Logistics build camera system.
 * This camera allows players to view and place construction objects from different angles.
 * Features include different vision modes (normal, NVG, thermal), color correction filters,
 * and key bindings for camera control.
 *
 * Key Controls:
 * - N: Toggle vision modes (Normal, NVG, Thermal White Hot, Thermal Black Hot)
 * - Numpad Decimal: Reset to last position
 * - B: Open build menu (if not disabled)
 *
 * @param {Object|Array} _this - This can be:
 *  - Object: The object to center the camera on (defaults to player vehicle if undefined)
 *  - Array: [object, buildMenuDisabled] where:
 *      - object: The object to center camera on
 *      - buildMenuDisabled (boolean): Whether to disable the build menu (default: false)
 *
 * @return {Nothing}
 *
 * @example
 * [player] call IDS_Logistics_fnc_initBuildCamera                // Enable camera with build menu
 * [player, true] call IDS_Logistics_fnc_initBuildCamera          // Enable camera without build menu
 */

// ---- CAMERA CONFIGURATION SETUP ----

// Parse parameters
private _targetObject = objNull;
private _buildMenuDisabled = false;

if (typeName _this isEqualTo "ARRAY") then {
    if (count _this > 0) then {
        _targetObject = _this select 0;
        if (count _this > 1) then {
            _buildMenuDisabled = _this select 1;
        };
    };
} else {
    _targetObject = _this;
};

// Set global variable for build menu status
IDS_Logistics_BuildMenuDisabled = _buildMenuDisabled;

//--- Is FLIR available
if (isNil "IDS_Logistics_BuildCamIsFLIR") then { IDS_Logistics_BuildCamIsFLIR = isClass (configFile >> "CfgPatches" >> "A3_Data_F"); };

IDS_Logistics_CamVision = 0;
IDS_Logistics_CamColor = ppEffectCreate ["colorCorrections", 1600];

// Initialize terrain snap variable only if it doesn't exist
if (isNil "IDS_Logistics_CameraTerrainSnap") then { IDS_Logistics_CameraTerrainSnap = false; };

// Initialize center cursor variable
if (isNil "IDS_Logistics_ShowCenterCursor") then { IDS_Logistics_ShowCenterCursor = false; };

IDS_Logistics_MouseClicks = [];

// ---- CAMERA INITIALIZATION ----

//--- Use provided object or default to player's vehicle
if (typeName _targetObject != typeName objNull) then { _targetObject = cameraOn };

//--- Ensure simulation runs at minimum speed (camera needs time to advance)
setAccTime (accTime max (1 / 128));

private _ppos = getPosASL _targetObject;
private _pX = _ppos select 0;
private _pY = _ppos select 1;
private _pZ = _ppos select 2;

//--- Adjust height if below sea level
private _pHeight = getTerrainHeightASL [_pX, _pY];
if (_pHeight < 0) then { _pZ = _pZ + _pHeight };

//--- Create camera slightly above target
private _local = "camconstruct" camCreate [_pX, _pY, _pZ + 2];

IDS_Logistics_Cam = _local;
_local camCommand "MANUAL ON";
_local cameraEffect ["INTERNAL", "BACK"];
showCinemaBorder false;
IDS_Logistics_Cam setDir direction (vehicle player);

// Store initial camera position for range limitation
IDS_Logistics_CamInitialPos = [_pX, _pY, _pZ + 2];
IDS_Logistics_CamMaxDistance = 50; // Maximum distance in meters
IDS_Logistics_CamAtLimit = false;  // Flag to prevent spam notifications

// Add visual boundary system
IDS_Logistics_BoundaryEH = [
    {
    if (!isNil "IDS_Logistics_Cam" && {!isNull IDS_Logistics_Cam}) then {
        private _center = IDS_Logistics_CamInitialPos;
        private _radius = IDS_Logistics_CamMaxDistance;
        private _segments = 64; // Number of segments in the circle
        private _height = 0.5; // Height of the boundary lines
        
        // Draw the boundary circle
        for "_i" from 0 to (_segments - 1) do {
            private _angle1 = (_i / _segments) * 360;
            private _angle2 = ((_i + 1) / _segments) * 360;
            
            private _pos1 = [
                (_center select 0) + (_radius * sin _angle1),
                (_center select 1) + (_radius * cos _angle1),
                _height
            ];
            
            private _pos2 = [
                (_center select 0) + (_radius * sin _angle2),
                (_center select 1) + (_radius * cos _angle2),
                _height
            ];
            
            // Draw the line segment
            drawLine3D [_pos1, _pos2, [0.5, 0.1, 0.1, 0.5]];
        };
        
        // Draw vertical lines at cardinal points for better depth perception
        private _cardinalPoints = [0, 90, 180, 270];
        {
            private _angle = _x;
            private _pos = [
                (_center select 0) + (_radius * sin _angle),
                (_center select 1) + (_radius * cos _angle),
                _height
            ];
            drawLine3D [_pos, [_pos select 0, _pos select 1, 0], [0.5, 0.1, 0.1, 0.3]];
        } forEach _cardinalPoints;
        
        // Draw center cursor if enabled
        if (!isNil "IDS_Logistics_ShowCenterCursor" && { IDS_Logistics_ShowCenterCursor }) then {
            private _camPos = getPosASL IDS_Logistics_Cam;
            private _camDir = vectorDir IDS_Logistics_Cam;
            
            // If vectorDir fails, try other methods
            if (_camDir isEqualTo [0,0,0]) then {
                _camDir = getCameraViewDirection IDS_Logistics_Cam;
            };
            
            if (_camDir isEqualTo [0,0,0]) then {
                private _camDirection = getDir IDS_Logistics_Cam;
                _camDir = [sin _camDirection, cos _camDirection, 0];
            };
            
            private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);
            private _intersections = lineIntersectsSurfaces [
                _camPos, 
                _targetPos, 
                IDS_Logistics_Cam, 
                objNull, 
                true, 
                1, 
                "VIEW", 
                "FIRE"
            ];
            
            if (count _intersections > 0) then {
                private _intersectPos = (_intersections select 0) select 0;
                private _intersectObj = (_intersections select 0) select 2;
                private _parentObj = (_intersections select 0) select 3;
                private _color = [1, 1, 1, 0.8]; // White cursor by default
                
                // Change color if looking at a placeable entity (check both intersected object and parent object)
                private _targetObj = objNull;
                {
                    if (!isNull _x && {(_x getVariable ["IDS_Logistics_isPlacedEntity", false]) || {(_x getVariable ["FLO_FOB_Id", ""]) isNotEqualTo ""}}) exitWith {
                        _targetObj = _x;
                    };
                } forEach [_intersectObj, _parentObj];

                if (!isNull _targetObj) then {
                    _color = [0, 1, 0, 0.8]; // Green for placeable entities
                };

                // Create cursor arrow only if it doesn't exist
                if (isNil "IDS_Logistics_CursorArrow") then {
                    IDS_Logistics_CursorArrow = "Sign_Arrow_F" createVehicleLocal [0,0,0];
                };
                
                // Update cursor arrow position and color
                IDS_Logistics_CursorArrow setPosASL _intersectPos;
                IDS_Logistics_CursorArrow setVectorUp ((_intersections select 0) select 1);
                
                // Set material color based on whether looking at placeable entity
                if (_color isEqualTo [0, 1, 0, 0.8]) then {
                    IDS_Logistics_CursorArrow setObjectTexture [0, "#(rgb,8,8,3)color(0,1,0,0.8)"];
                } else {
                    IDS_Logistics_CursorArrow setObjectTexture [0, "#(rgb,8,8,3)color(1,1,1,0.8)"];
                };
            } else {
                // Delete cursor arrow if it exists and cursor is disabled
                if (!isNil "IDS_Logistics_CursorArrow") then {
                    deleteVehicle IDS_Logistics_CursorArrow;
                    IDS_Logistics_CursorArrow = nil;
                };
            };
        };

        // Create or update cardinal direction arrows
        private _cardinalDirections = [0, 90, 180, 270];
        
        {
            private _angle = _x;
            private _arrowPos = [
                (_center select 0) + (_radius * sin _angle),
                (_center select 1) + (_radius * cos _angle),
                0.5
            ];
            
            // Create arrow if it doesn't exist
            if (isNil format ["IDS_Logistics_BoundaryArrow_%1", _angle]) then {
                private _arrow = "Sign_Arrow_Direction_F" createVehicleLocal _arrowPos;
                missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _angle], _arrow];
            };
            
            // Update arrow position and direction
            private _arrow = missionNamespace getVariable format ["IDS_Logistics_BoundaryArrow_%1", _angle];
            _arrow setPosASL [_arrowPos select 0, _arrowPos select 1, getTerrainHeightASL [_arrowPos select 0, _arrowPos select 1] + 0.5];
            _arrow setDir _angle; // Point outward (removed the +180)
            _arrow setObjectTexture [0, "#(rgb,8,8,3)color(0.5,0.1,0.1,0.5)"];
        } forEach _cardinalDirections;
    };
    },
    0,
    []
] call CBA_fnc_addPerFrameHandler;

// Add range limitation check (50 meter radius from initial position)
IDS_Logistics_DistanceCheckEH = [
    {
    if (!isNil "IDS_Logistics_Cam" && {!isNull IDS_Logistics_Cam}) then {
        private _currentPos = getPosASL IDS_Logistics_Cam;
        private _initialPos = IDS_Logistics_CamInitialPos;

        // Calculate 2D distance manually using x and y coordinates only
        private _deltaX = (_currentPos select 0) - (_initialPos select 0);
        private _deltaY = (_currentPos select 1) - (_initialPos select 1);
        private _distance = sqrt(_deltaX^2 + _deltaY^2);

        // If camera exceeds the limit, move it back to the boundary
        if (_distance > IDS_Logistics_CamMaxDistance) then {
            // Calculate direction vector from initial position to current position (2D only)
            private _dir = [_deltaX, _deltaY, 0];

            // Normalize the direction vector
            private _dirLength = sqrt((_dir select 0)^2 + (_dir select 1)^2);
            if (_dirLength > 0) then {
                _dir = [(_dir select 0) / _dirLength, (_dir select 1) / _dirLength, 0];

                // Calculate new position at the boundary
                private _newPos = [
                    (_initialPos select 0) + (_dir select 0) * IDS_Logistics_CamMaxDistance,
                    (_initialPos select 1) + (_dir select 1) * IDS_Logistics_CamMaxDistance,
                    _currentPos select 2
                ];

                // Move camera to the boundary
                IDS_Logistics_Cam setPosASL _newPos;

                // Show notification if not already at limit
                if (!IDS_Logistics_CamAtLimit) then {
                    ["<t color='#FF8844'>Maximum camera distance reached (50m)</t>", 2] call IDS_Logistics_fnc_cameraHint;
                    IDS_Logistics_CamAtLimit = true;
                };
            };
        } else {
            // Reset the limit flag when back within bounds
            if (IDS_Logistics_CamAtLimit && _distance < (IDS_Logistics_CamMaxDistance - 1)) then { IDS_Logistics_CamAtLimit = false; };
        };
    };
    },
    0,
    []
] call CBA_fnc_addPerFrameHandler;

// Add mouse click handlers for the camera
IDS_Logistics_MouseClicks pushBack ((findDisplay 46) displayAddEventHandler ["MouseButtonDown", {
    params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    // Left click - place entity or delete if shift is pressed
    if (_button == 0) then {
        // Use proper camera direction vector calculation
        private _camPos = getPosASL IDS_Logistics_Cam;

        // Get camera direction using vectorDir instead of getCameraViewDirection
        private _camDir = vectorDir IDS_Logistics_Cam;

        // If that's still zero, calculate from camera angles
        if (_camDir isEqualTo [0,0,0]) then {
            private _camDirection = getDir IDS_Logistics_Cam;
            _camDir = [sin _camDirection, cos _camDirection, 0];
        };

        private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);

        if (isNil "IDS_Logistics_Cam") exitWith {};
        private _intersections = lineIntersectsSurfaces [
            _camPos, 
            _targetPos, 
            IDS_Logistics_Cam, 
            objNull, 
            true, 
            1, 
            "VIEW", 
            "FIRE"
        ];

        private _centerObj = objNull;
        private _intersectPos = [];

        if (count _intersections > 0) then {
            _centerObj = (_intersections select 0) select 2;
            _intersectPos = (_intersections select 0) select 0;
        };

        // Function to check if any players are on the object
        private _hasPlayersOnObject = {
            params ["_object"];
            if (isNull _object) exitWith { false };
            
            private _objectPos = getPosASL _object;
            private _objectSize = boundingBoxReal _object;
            private _minZ = (_objectSize select 0) select 2;
            private _maxZ = (_objectSize select 1) select 2;
            private _height = _maxZ - _minZ;
            
            // Check all players within 10m radius (optimization)
            private _nearPlayers = _objectPos nearEntities ["CAManBase", 10];
            
            private _playersOnObject = false;
            {
                if (isPlayer _x) then {
                    private _playerPos = getPosASL _x;
                    private _relativeZ = (_playerPos select 2) - (_objectPos select 2);
                    
                    // Check if player is above the object and within its height bounds
                    if (_relativeZ > _minZ && _relativeZ <= (_maxZ + 2)) then {
                        // Check if player is within the object's 2D bounds
                        private _playerPosASL = getPosASL _x;
                        private _intersectASL = lineIntersectsSurfaces [
                            _playerPosASL vectorAdd [0,0,0.1],
                            _playerPosASL vectorAdd [0,0,-2],
                            _x,
                            objNull,
                            true,
                            1,
                            "GEOM",
                            "NONE"
                        ];
                        
                        if (count _intersectASL > 0) then {
                            if ((_intersectASL select 0) select 2 == _object) then {
                                _playersOnObject = true;
                            };
                        };
                    };
                };
                if (_playersOnObject) exitWith {};
            } forEach _nearPlayers;
            
            _playersOnObject
        };

        // SHIFT + Left click = Delete entity under center of screen
        if (_shift) then {
            private _parentObj = if (count _intersections > 0) then { (_intersections select 0) select 3 } else { objNull };
            private _targetObj = objNull;
            {
                if (!isNull _x && {_x getVariable ["IDS_Logistics_isPlacedEntity", false]}) exitWith {
                    _targetObj = _x;
                };
            } forEach [_centerObj, _parentObj];

            if (!isNull _targetObj) then {
                private _type = typeOf _targetObj;
                // Check if delete entity is disabled
                if (IDS_Logistics_BuildMenuDisabled) then {
                    ["Delete entity is disabled in this mode", 2] call IDS_Logistics_fnc_cameraHint;
                } else {
                    // Check for players on the object
                    if ([_targetObj] call _hasPlayersOnObject) then {
                        ["Cannot delete: Players are on the object", 2] call IDS_Logistics_fnc_cameraHint;
                    } else {
                        [netId _targetObj, player] remoteExecCall ["IDS_Logistics_fnc_deleteEntity", 2];
                        ["Delete requested: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
                    };
                };
            } else {
                ["No placeable object found at center of screen", 2] call IDS_Logistics_fnc_cameraHint;
            };
        } else {
            // CTRL + Left click = Pick up entity
            if (_ctrl) then {
                private _parentObj = if (count _intersections > 0) then { (_intersections select 0) select 3 } else { objNull };
                private _targetObj = objNull;
                {
                    if (!isNull _x && {(_x getVariable ["IDS_Logistics_isPlacedEntity", false]) || {(_x getVariable ["FLO_FOB_Id", ""]) isNotEqualTo ""}}) exitWith {
                        _targetObj = _x;
                    };
                } forEach [_centerObj, _parentObj];

                if (!isNull _targetObj) then {
                    // Check for players on the object
                    if ([_targetObj] call _hasPlayersOnObject) then {
                        ["Cannot pick up: Players are on the object", 2] call IDS_Logistics_fnc_cameraHint;
                    } else {
                        [_targetObj] call IDS_Logistics_fnc_pickupEntity;
                    };
                };
            } else {
                // Normal left click - place entity
                if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then { [] call IDS_Logistics_fnc_placeEntity; };
            };
        };
        true;
    };

    // Right click - Cancel placement or return picked up entity
    if (_button == 1) then {
        if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
            // Check if this is a picked up entity
            private _isPickedUp = false;
            private _originalNetId = "";
            
            // Safely get variables with default values
            {
                private _var = IDS_Logistics_currentEntity getVariable [_x, nil];
                if (!isNil "_var") then {
                    switch (_x) do {
                        case "IDS_Logistics_isPickedUp": { _isPickedUp = _var };
                        case "IDS_Logistics_OriginalNetId": { _originalNetId = _var };
                    };
                };
            } forEach ["IDS_Logistics_isPickedUp", "IDS_Logistics_OriginalNetId"];

            if (_isPickedUp && {_originalNetId != ""}) then {
                // Tell server to restore the original entity
                [_originalNetId, false, player] remoteExecCall ["IDS_Logistics_fnc_toggleEntityVisibility", 2];

                // Delete the local preview
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;

                ["Entity returned to original position", 2] call IDS_Logistics_fnc_cameraHint;
            } else {
                // This is a new entity being placed, delete it
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;
                ["Placement cancelled", 2] call IDS_Logistics_fnc_cameraHint;
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
        };
        true;
    };
    false;
}]);

// Add escape key handler for exiting build mode
_keyDown = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];

    // Escape key - Exit build mode
    if (_key == 1) then {
        if (!isNull IDS_Logistics_Cam) then {
            // Temporarily disable user input to prevent escape menu
            disableUserInput true;
            
            // Store last position before cleanup
            IDS_Logistics_CamLastPos = position IDS_Logistics_Cam;
            
            // Clean up any held entity
            if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;
            };

            // Clean up cursor arrow
            if (!isNil "IDS_Logistics_CursorArrow") then {
                deleteVehicle IDS_Logistics_CursorArrow;
                IDS_Logistics_CursorArrow = nil;
            };

            // Clean up boundary arrows
            {
                private _arrow = missionNamespace getVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], objNull];
                if (!isNull _arrow) then {
                    deleteVehicle _arrow;
                    missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], nil];
                };
            } forEach [0, 90, 180, 270];

            // Remove event handlers
            if (!isNil "IDS_Logistics_DistanceCheckEH") then { 
                [IDS_Logistics_DistanceCheckEH] call CBA_fnc_removePerFrameHandler;
                IDS_Logistics_DistanceCheckEH = nil;
            };
            if (!isNil "IDS_Logistics_BoundaryEH") then { 
                [IDS_Logistics_BoundaryEH] call CBA_fnc_removePerFrameHandler;
                IDS_Logistics_BoundaryEH = nil;
            };
            
            // Clean up camera and effects
            player cameraEffect ["TERMINATE", "BACK"];
            if (!isNil "IDS_Logistics_CamColor") then { 
                ppEffectDestroy IDS_Logistics_CamColor;
                IDS_Logistics_CamColor = nil;
            };
            camDestroy IDS_Logistics_Cam;
            
            // Reset all global variables
            IDS_Logistics_Cam = nil;
            IDS_Logistics_CamVision = nil;
            IDS_Logistics_HintVisible = nil;
            IDS_Logistics_isHolding = false;
            IDS_Logistics_currentEntity = objNull;
            IDS_Logistics_lastViewDir = nil;
            IDS_Logistics_ShowCenterCursor = nil;
            IDS_Logistics_CameraTerrainSnap = nil;
            IDS_Logistics_BuildMenuDisabled = nil;

            ["Build mode exited", 2] call IDS_Logistics_fnc_cameraHint;
            
            // Re-enable user input
            disableUserInput false;
            true;
        };
        true;
    };

    if (_key in (actionKeys 'nightvision')) then {
        IDS_Logistics_CamVision = IDS_Logistics_CamVision + 1;
        _vision = IDS_Logistics_CamVision % 2;
        switch (_vision) do {
            case 0: {
                camUseNVG false;
                ['Normal Vision', 2] call IDS_Logistics_fnc_cameraHint;
            };
            case 1: {
                camUseNVG true;
                ['Night Vision', 2] call IDS_Logistics_fnc_cameraHint;
            };
        };
    };

    if (_key == 83 && !isNil 'IDS_Logistics_CamLastPos') then { IDS_Logistics_Cam setPos IDS_Logistics_CamLastPos; };
    if (_key == 48) then { 
        if (!IDS_Logistics_BuildMenuDisabled) then {
            [] call IDS_Logistics_fnc_openBuildMenu;
        } else {
            ["Build menu is disabled in this mode", 2] call IDS_Logistics_fnc_cameraHint;
        };
    };
    if (_key == 20) then {
        IDS_Logistics_CameraTerrainSnap = !IDS_Logistics_CameraTerrainSnap;
        if (IDS_Logistics_CameraTerrainSnap) then {
            ['Terrain snapping: ENABLED', 2] call IDS_Logistics_fnc_cameraHint;
        } else {
            ['Terrain snapping: DISABLED', 2] call IDS_Logistics_fnc_cameraHint;
        };
    };
    
    // Add cursor toggle (C key)
    if (_key == 46) then {
        IDS_Logistics_ShowCenterCursor = !IDS_Logistics_ShowCenterCursor;
        
        // If disabling cursor, ensure it's deleted
        if (!IDS_Logistics_ShowCenterCursor && !isNil "IDS_Logistics_CursorArrow") then {
            deleteVehicle IDS_Logistics_CursorArrow;
            IDS_Logistics_CursorArrow = nil;
        };
        
        if (IDS_Logistics_ShowCenterCursor) then {
            ['Center cursor: ENABLED', 2] call IDS_Logistics_fnc_cameraHint;
        } else {
            ['Center cursor: DISABLED', 2] call IDS_Logistics_fnc_cameraHint;
        };
    };
    
    false;
}];

// ---- CAMERA CLEANUP HANDLER ----

//--- Wait until destroy is forced or camera auto-destroyed
[_local, _keyDown] spawn {
    params ["_local", "_keyDown"];
    
    waitUntil { isNull _local };

    // Store last position before cleanup
    if (!isNil "IDS_Logistics_Cam") then {
        IDS_Logistics_CamLastPos = position IDS_Logistics_Cam;
    };

    // Clean up any held entity
    if (!isNull IDS_Logistics_currentEntity) then { 
        deleteVehicle IDS_Logistics_currentEntity;
        IDS_Logistics_currentEntity = objNull;
    };

    // Clean up cursor arrow
    if (!isNil "IDS_Logistics_CursorArrow") then {
        deleteVehicle IDS_Logistics_CursorArrow;
        IDS_Logistics_CursorArrow = nil;
    };

    // Clean up boundary arrows
    {
        private _arrow = missionNamespace getVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], objNull];
        if (!isNull _arrow) then {
            deleteVehicle _arrow;
            missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], nil];
        };
    } forEach [0, 90, 180, 270];

    // Remove all event handlers
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyDown];
    
    if (!isNil "IDS_Logistics_MouseClicks") then {
        {
            (findDisplay 46) displayRemoveEventHandler ["MouseButtonDown", _x];
        } forEach IDS_Logistics_MouseClicks;
        IDS_Logistics_MouseClicks = nil;
    };

    private _scroll = missionNamespace getVariable ["IDS_Logistics_scrollHandler", -1];
    if (_scroll isNotEqualTo -1) then { 
        (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", _scroll];
        IDS_Logistics_scrollHandler = nil;
    };
    private _keyDownEH = missionNamespace getVariable ["IDS_Logistics_keyDownHandler", -1];
    if (_keyDownEH isNotEqualTo -1) then { 
        (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyDownEH];
        IDS_Logistics_keyDownHandler = nil;
    };
    private _keyUpEH = missionNamespace getVariable ["IDS_Logistics_keyUpHandler", -1];
    if (_keyUpEH isNotEqualTo -1) then { 
        (findDisplay 46) displayRemoveEventHandler ["KeyUp", _keyUpEH];
        IDS_Logistics_keyUpHandler = nil;
    };
    private _dirUpdate = missionNamespace getVariable ["IDS_Logistics_dirUpdateEH", -1];
    if (_dirUpdate isNotEqualTo -1) then {
        [_dirUpdate] call CBA_fnc_removePerFrameHandler;
        IDS_Logistics_dirUpdateEH = nil;
    };
    private _distanceCheck = missionNamespace getVariable ["IDS_Logistics_DistanceCheckEH", -1];
    if (_distanceCheck isNotEqualTo -1) then {
        [_distanceCheck] call CBA_fnc_removePerFrameHandler;
        IDS_Logistics_DistanceCheckEH = nil;
    };
    private _boundary = missionNamespace getVariable ["IDS_Logistics_BoundaryEH", -1];
    if (_boundary isNotEqualTo -1) then {
        [_boundary] call CBA_fnc_removePerFrameHandler;
        IDS_Logistics_BoundaryEH = nil;
    };

    // Clean up camera and effects
    player cameraEffect ["TERMINATE", "BACK"];
    if (!isNil "IDS_Logistics_CamColor") then { 
        ppEffectDestroy IDS_Logistics_CamColor;
        IDS_Logistics_CamColor = nil;
    };
    camDestroy _local;

    // Reset all global variables
    IDS_Logistics_Cam = nil;
    IDS_Logistics_CamVision = nil;
    IDS_Logistics_HintVisible = nil;
    IDS_Logistics_isHolding = false;
    IDS_Logistics_currentEntity = objNull;
    IDS_Logistics_lastViewDir = nil;
    IDS_Logistics_ShowCenterCursor = nil;
    IDS_Logistics_CameraTerrainSnap = nil;
    IDS_Logistics_BuildMenuDisabled = nil;
};

// Display camera controls info
private _bKeyText = [
    "<t>- <t color='#DDDDDD'>B key</t> - <t color='#888888'>Build menu disabled</t></t><br/>",
    "<t>- <t color='#DDDDDD'>B key</t> - Open build menu</t><br/>"
] select (!IDS_Logistics_BuildMenuDisabled);

private _shiftKeyText = [
    "<t>- <t color='#DDDDDD'>SHIFT + Left click</t> - <t color='#888888'>Delete entity disabled</t></t><br/>",
    "<t>- <t color='#DDDDDD'>SHIFT + Left click</t> - Delete entity</t><br/>"
] select (!IDS_Logistics_BuildMenuDisabled);

private _controlsInfo = format [
    "<t color='#AAFFAA' size='1.0'>CONTROLS</t><br/><t align='left'>" +
    "<t>- <t color='#DDDDDD'>N key</t> - Toggle normal/night vision</t><br/>" +
    "%1" +
    "<t>- <t color='#DDDDDD'>T key</t> - Toggle terrain snapping</t><br/>" +
    "<t>- <t color='#DDDDDD'>C key</t> - Toggle 3d cursor</t><br/>" +
    "<t>- <t color='#DDDDDD'>Q/Z key</t> - Raise/Lower camera</t><br/>" +
    "<t>- <t color='#DDDDDD'>Left click</t> - Place entity</t><br/>" +
    "<t>- <t color='#DDDDDD'>CTRL + Left click</t> - Pick up entity</t><br/>" +
    "%2" +
    "<t>- <t color='#DDDDDD'>Right click</t> - Cancel placement</t><br/>" +
    "<t>- <t color='#DDDDDD'>ESC key</t> - Exit build mode</t><br/>" +
    "<t>- <t color='#DDDDDD'>CTRL + scroll</t> - Adjust height</t><br/>" +
    "<t>- <t color='#DDDDDD'>SHIFT + scroll</t> - Rotate entity</t><br/>" +
    "<t>- <t color='#DDDDDD'>ALT + scroll</t> - Adjust distance</t>",
    _bKeyText,
    _shiftKeyText
];

[_controlsInfo, 0] call IDS_Logistics_fnc_cameraHint;

if (!isNull (findDisplay 9500)) exitWith { false };
