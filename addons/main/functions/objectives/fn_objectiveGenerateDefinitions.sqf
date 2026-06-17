/*
    Generates objective topology from world locations.

    FOOF should not require players or server operators to hand-edit
    objective definition files. This function turns map locations into
    named objectives linked to generated map grid cells.
*/

private _generationT0 = diag_tickTime;
private _center = [worldSize / 2, worldSize / 2, 0];
private _locationConfigs = [
    ["NameCityCapital", 100, 5, 1.50, 900, 2200, 360],
    ["Airport", 95, 4, 1.50, 850, 2200, 340],
    ["NameCity", 80, 3, 1.30, 700, 1800, 300],
    ["Strategic", 72, 3, 1.20, 650, 1600, 280],
    ["NameVillage", 60, 2, 1.20, 550, 1300, 220],
    ["NameLocal", 48, 1, 1.00, 400, 900, 160],
    ["NameMarine", 42, 1, 1.00, 350, 900, 320]
];
private _locationTypes = [];
private _locationConfigByType = createHashMap;
private _candidates = [];

{
    _x params ["_type"];

    _locationTypes pushBack _type;
    _locationConfigByType set [_type, _x];
} forEach _locationConfigs;

{
    private _location = _x;
    private _type = type _location;
    private _config = _locationConfigByType get _type;

    _config params [
        "_type",
        "_priority",
        "_resourceWeight",
        "_sizeMultiplier",
        "_minRadius",
        "_maxRadius",
        "_displayRadius"
    ];

    private _name = text _location;

    if (_name isNotEqualTo "") then {
        private _rawPosition = locationPosition _location;
        private _position = [_rawPosition # 0, _rawPosition # 1, 0];
        private _size = size _location;
        private _sizedRadius = (((_size # 0) max (_size # 1)) * _sizeMultiplier);

        if (_sizedRadius <= 0) then {
            _sizedRadius = _minRadius;
        };

        private _objectiveGridRadius = round (((_sizedRadius max _minRadius) min _maxRadius));

        _candidates pushBack [
            -_priority,
            _name,
            _position,
            _type,
            _objectiveGridRadius,
            _displayRadius,
            _resourceWeight,
            _minRadius
        ];
    };
} forEach nearestLocations [_center, _locationTypes, worldSize];

{
    private _candidateIndex = _forEachIndex;
    private _candidate = _x;
    private _position = _candidate # 2;
    private _radius = _candidate # 4;
    private _minRadius = _candidate # 7;
    private _nearestDistance = worldSize * 2;

    {
        if (_forEachIndex isNotEqualTo _candidateIndex) then {
            private _distance = _position distance2D (_x # 2);

            if (_distance < _nearestDistance) then {
                _nearestDistance = _distance;
            };
        };
    } forEach _candidates;

    if (_nearestDistance < (worldSize * 2)) then {
        private _densityCap = round (((_nearestDistance * 0.70) max _minRadius) min _radius);

        if (_densityCap < _radius) then {
            _candidate set [4, _densityCap];
            _candidates set [_candidateIndex, _candidate];
        };
    };
} forEach _candidates;

_candidates sort true;

private _definitions = [];
private _acceptedFootprints = [];
private _usedIds = createHashMap;
private _claimedCellIds = createHashMap;
private _maxObjectives = FLO_ObjectiveGeneratedMaxObjectives;
private _requiredRatio = FLO_ObjectiveGeneratedRequiredWeightRatio;
private _overlapFactor = FLO_ObjectiveGeneratedOverlapFactor;
private _marineMaxLandDistance = FLO_ObjectiveGeneratedMarineMaxLandDistance;
private _index = 0;
private _skippedMax = 0;
private _skippedOverlap = 0;
private _skippedAnchorClaimed = 0;
private _skippedMarineWater = 0;
private _totalLinkedCells = 0;
private _minLinkedCells = 999999;
private _maxLinkedCells = 0;

{
    if ((count _definitions) >= _maxObjectives) exitWith {
        _skippedMax = _skippedMax + 1;
    };

    _x params [
        "_sortPriority",
        "_name",
        "_position",
        "_type",
        "_objectiveGridRadius",
        "_displayRadius",
        "_resourceWeight"
    ];

    private _anchorCellId = "";

    if (_type isEqualTo "NameMarine") then {
        private _xIndex = floor ((_position # 0) / FLO_ObjectiveGridCellSize);
        private _yIndex = floor ((_position # 1) / FLO_ObjectiveGridCellSize);

        _xIndex = (_xIndex max 0) min (FLO_ObjectiveGridWidth - 1);
        _yIndex = (_yIndex max 0) min (FLO_ObjectiveGridHeight - 1);

        private _maxRing = ceil (_marineMaxLandDistance / FLO_ObjectiveGridCellSize) + 1;
        private _bestDistance = _marineMaxLandDistance + FLO_ObjectiveGridCellSize;

        for "_ring" from 0 to _maxRing do {
            for "_dx" from -_ring to _ring do {
                for "_dy" from -_ring to _ring do {
                    if ((abs _dx isEqualTo _ring) || {abs _dy isEqualTo _ring}) then {
                        private _candidateX = _xIndex + _dx;
                        private _candidateY = _yIndex + _dy;

                        if ((_candidateX >= 0) && {_candidateX < FLO_ObjectiveGridWidth} && {_candidateY >= 0} && {_candidateY < FLO_ObjectiveGridHeight}) then {
                            private _candidateId = [_candidateX, _candidateY] call FLO_fnc_objectiveGridCellId;

                            if (_candidateId in FLO_ObjectiveGridCellIdSet) then {
                                private _candidateCell = FLO_ObjectiveCells get _candidateId;
                                private _distance = _position distance2D (_candidateCell get "position");

                                if (_distance < _bestDistance) then {
                                    _bestDistance = _distance;
                                    _anchorCellId = _candidateId;
                                };
                            };
                        };
                    };
                };
            };
        };

        if ((_anchorCellId isEqualTo "") || {_bestDistance > _marineMaxLandDistance}) then {
            _skippedMarineWater = _skippedMarineWater + 1;
            continue;
        };
    } else {
        _anchorCellId = ([_position] call FLO_fnc_objectiveGridCellAtPosition) get "id";
    };

    if (_anchorCellId in _claimedCellIds) then {
        _skippedAnchorClaimed = _skippedAnchorClaimed + 1;
        continue;
    };

    private _anchorCell = FLO_ObjectiveCells get _anchorCellId;
    private _objectivePosition = _position;

    if (_type isEqualTo "NameMarine") then {
        _objectivePosition = +(_anchorCell get "position");
    };

    private _overlaps = false;

    {
        _x params ["_acceptedPosition", "_acceptedRadius"];

        if ((_objectivePosition distance2D _acceptedPosition) < ((_objectiveGridRadius + _acceptedRadius) * _overlapFactor)) exitWith {
            _overlaps = true;
        };
    } forEach _acceptedFootprints;

    if (_overlaps) then {
        _skippedOverlap = _skippedOverlap + 1;
        continue;
    };

    private _anchorX = _anchorCell get "gridX";
    private _anchorY = _anchorCell get "gridY";
    private _cellRange = ceil (_objectiveGridRadius / FLO_ObjectiveGridCellSize);
    private _minX = (_anchorX - _cellRange) max 0;
    private _maxX = (_anchorX + _cellRange) min (FLO_ObjectiveGridWidth - 1);
    private _minY = (_anchorY - _cellRange) max 0;
    private _maxY = (_anchorY + _cellRange) min (FLO_ObjectiveGridHeight - 1);
    private _cellIds = [];

    for "_xIndex" from _minX to _maxX do {
        for "_yIndex" from _minY to _maxY do {
            private _cellId = [_xIndex, _yIndex] call FLO_fnc_objectiveGridCellId;

            if ((_cellId in FLO_ObjectiveGridCellIdSet) && {!(_cellId in _claimedCellIds)}) then {
                private _cell = FLO_ObjectiveCells get _cellId;

                if (((_cell get "position") distance2D _objectivePosition) <= _objectiveGridRadius) then {
                    _cellIds pushBack _cellId;
                };
            };
        };
    };

    if !(_anchorCellId in _cellIds) then {
        _cellIds pushBack _anchorCellId;
    };

    {
        _claimedCellIds set [_x, true];
    } forEach _cellIds;

    private _linkedCellCount = count _cellIds;

    _totalLinkedCells = _totalLinkedCells + _linkedCellCount;
    _minLinkedCells = _minLinkedCells min _linkedCellCount;
    _maxLinkedCells = _maxLinkedCells max _linkedCellCount;

    private _fallbackId = format ["objective_%1", _index];
    private _id = [_name, _fallbackId] call FLO_fnc_objectiveSanitizeId;

    if (_id in (keys _usedIds)) then {
        _id = format ["%1_%2", _id, _index];
    };

    _usedIds set [_id, true];
    _acceptedFootprints pushBack [_objectivePosition, _objectiveGridRadius];
    _index = _index + 1;

    _definitions pushBack createHashMapFromArray [
        ["id", _id],
        ["name", _name],
        ["position", _objectivePosition],
        ["locationType", _type],
        ["resourceWeight", _resourceWeight],
        ["displayRadius", _displayRadius],
        ["requiredWeightRatio", _requiredRatio],
        ["anchorCellId", _anchorCellId],
        ["cellIds", _cellIds]
    ];
} forEach _candidates;

private _clusterCandidates = [];
private _clusterTerrainScans = 0;
private _clusterAcceptedStructuresTotal = 0;
private _clusterStructuresTotal = 0;
private _clusterMaxStructures = 0;
private _clusterMs = 0;

if (FLO_ObjectiveGeneratedClusterEnabled && {(count _definitions) < _maxObjectives}) then {
    private _clusterT0 = diag_tickTime;
    private _clusterCellRefs = [];

    {
        private _cell = FLO_ObjectiveCells get _x;
        private _gridX = _cell get "gridX";
        private _gridY = _cell get "gridY";
        private _spreadKey = ((_gridX * 73856093) + (_gridY * 19349663)) mod 1000000;

        _clusterCellRefs pushBack [_spreadKey, _x];
    } forEach FLO_ObjectiveGridCellIds;

    _clusterCellRefs sort true;

    {
        if (_clusterTerrainScans >= FLO_ObjectiveGeneratedClusterScanBudget) exitWith {};

        _x params ["_spreadKey", "_cellId"];

        if (_cellId in _claimedCellIds) then {
            continue;
        };

        private _cell = FLO_ObjectiveCells get _cellId;
        private _position = _cell get "position";
        private _nearExisting = false;

        {
            _x params ["_acceptedPosition", "_acceptedRadius"];

            if ((_position distance2D _acceptedPosition) < ((_acceptedRadius + FLO_ObjectiveGeneratedClusterObjectiveGridRadius) * _overlapFactor)) exitWith {
                _nearExisting = true;
            };
        } forEach _acceptedFootprints;

        if (_nearExisting) then {
            continue;
        };

        _clusterTerrainScans = _clusterTerrainScans + 1;

        private _structures = nearestTerrainObjects [_position, ["HOUSE", "BUILDING"], FLO_ObjectiveGeneratedClusterScanRadius, false];
        private _structureCount = count _structures;
        _clusterStructuresTotal = _clusterStructuresTotal + _structureCount;
        _clusterMaxStructures = _clusterMaxStructures max _structureCount;

        if (_structureCount >= FLO_ObjectiveGeneratedClusterMinBuildings) then {
            _clusterAcceptedStructuresTotal = _clusterAcceptedStructuresTotal + _structureCount;
            _clusterCandidates pushBack [-_structureCount, _cellId, _position, _structureCount];
        };
    } forEach _clusterCellRefs;

    _clusterMs = (diag_tickTime - _clusterT0) * 1000;
};

_clusterCandidates sort true;

private _acceptedClusters = 0;

{
    if ((count _definitions) >= _maxObjectives) exitWith {};
    if (_acceptedClusters >= FLO_ObjectiveGeneratedMaxClusterObjectives) exitWith {};

    _x params ["_sortWeight", "_anchorCellId", "_position", "_structureCount"];

    if (_anchorCellId in _claimedCellIds) then {
        continue;
    };

    private _nearExisting = false;

    {
        _x params ["_acceptedPosition", "_acceptedRadius"];

        if ((_position distance2D _acceptedPosition) < ((_acceptedRadius + FLO_ObjectiveGeneratedClusterObjectiveGridRadius) * _overlapFactor)) exitWith {
            _nearExisting = true;
        };
    } forEach _acceptedFootprints;

    if (_nearExisting) then {
        continue;
    };

    private _anchorCell = FLO_ObjectiveCells get _anchorCellId;
    private _anchorX = _anchorCell get "gridX";
    private _anchorY = _anchorCell get "gridY";
    private _cellRange = ceil (FLO_ObjectiveGeneratedClusterObjectiveGridRadius / FLO_ObjectiveGridCellSize);
    private _minX = (_anchorX - _cellRange) max 0;
    private _maxX = (_anchorX + _cellRange) min (FLO_ObjectiveGridWidth - 1);
    private _minY = (_anchorY - _cellRange) max 0;
    private _maxY = (_anchorY + _cellRange) min (FLO_ObjectiveGridHeight - 1);
    private _cellIds = [];

    for "_xIndex" from _minX to _maxX do {
        for "_yIndex" from _minY to _maxY do {
            private _cellId = [_xIndex, _yIndex] call FLO_fnc_objectiveGridCellId;

            if ((_cellId in FLO_ObjectiveGridCellIdSet) && {!(_cellId in _claimedCellIds)}) then {
                private _cell = FLO_ObjectiveCells get _cellId;

                if (((_cell get "position") distance2D _position) <= FLO_ObjectiveGeneratedClusterObjectiveGridRadius) then {
                    _cellIds pushBack _cellId;
                };
            };
        };
    };

    if !(_anchorCellId in _cellIds) then {
        _cellIds pushBack _anchorCellId;
    };

    {
        _claimedCellIds set [_x, true];
    } forEach _cellIds;

    private _linkedCellCount = count _cellIds;

    _totalLinkedCells = _totalLinkedCells + _linkedCellCount;
    _minLinkedCells = _minLinkedCells min _linkedCellCount;
    _maxLinkedCells = _maxLinkedCells max _linkedCellCount;
    _acceptedClusters = _acceptedClusters + 1;

    private _name = format ["Built-up Area %1", _index + 1];
    private _fallbackId = format ["built_up_area_%1", _index];
    private _id = [_name, _fallbackId] call FLO_fnc_objectiveSanitizeId;

    if (_id in (keys _usedIds)) then {
        _id = format ["%1_%2", _id, _index];
    };

    _usedIds set [_id, true];
    _acceptedFootprints pushBack [_position, FLO_ObjectiveGeneratedClusterObjectiveGridRadius];
    _index = _index + 1;

    _definitions pushBack createHashMapFromArray [
        ["id", _id],
        ["name", _name],
        ["position", _position],
        ["locationType", "BuiltUpArea"],
        ["resourceWeight", 1],
        ["displayRadius", FLO_ObjectiveGeneratedClusterDisplayRadius],
        ["requiredWeightRatio", _requiredRatio],
        ["anchorCellId", _anchorCellId],
        ["cellIds", _cellIds]
    ];
} forEach _clusterCandidates;

if (_minLinkedCells isEqualTo 999999) then {
    _minLinkedCells = 0;
};

private _generationMs = (diag_tickTime - _generationT0) * 1000;
private _clusterAvgStructures = [0, _clusterStructuresTotal / _clusterTerrainScans] select (_clusterTerrainScans > 0);

diag_log format [
    "[FLO][Objective] Generated %1 objectives from %2 world locations and %3 built-up candidates acceptedClusters=%4 scans=%5 totalMs=%6 clusterMs=%7 clusterAvgStructures=%8 clusterMaxStructures=%9 clusterAcceptedStructures=%10 cellsTotal=%11 cellsMin=%12 cellsMax=%13 skipped max=%14 overlap=%15 claimed=%16 marineWater=%17 clusterEnabled=%18 clusterBudget=%19 clusterRadius=%20 clusterMinBuildings=%21 clusterMaxObjectives=%22",
    count _definitions,
    count _candidates,
    count _clusterCandidates,
    _acceptedClusters,
    _clusterTerrainScans,
    _generationMs,
    _clusterMs,
    _clusterAvgStructures,
    _clusterMaxStructures,
    _clusterAcceptedStructuresTotal,
    _totalLinkedCells,
    _minLinkedCells,
    _maxLinkedCells,
    _skippedMax,
    _skippedOverlap,
    _skippedAnchorClaimed,
    _skippedMarineWater,
    FLO_ObjectiveGeneratedClusterEnabled,
    FLO_ObjectiveGeneratedClusterScanBudget,
    FLO_ObjectiveGeneratedClusterScanRadius,
    FLO_ObjectiveGeneratedClusterMinBuildings,
    FLO_ObjectiveGeneratedMaxClusterObjectives
];

_definitions
