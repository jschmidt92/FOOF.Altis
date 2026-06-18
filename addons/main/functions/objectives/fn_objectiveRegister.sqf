params ["_definition"];

private _id = _definition get "id";
private _name = _definition get "name";
private _position = _definition get "position";
private _locationType = _definition get "locationType";
private _requiredWeightRatio = _definition get "requiredWeightRatio";
private _resourceWeight = _definition get "resourceWeight";
private _displayRadius = _definition get "displayRadius";
private _cellIds = +(_definition get "cellIds");
private _anchorCellId = _definition get "anchorCellId";

if (_id in (keys FLO_Objectives)) then {
    throw format ["[FLO][Objective] Duplicate objective id: %1", _id];
};

if !(_anchorCellId in _cellIds) then {
    throw format ["[FLO][Objective] Objective %1 anchor cell is not inside linked grid cells", _id];
};

FLO_Objectives set [
    _id,
    createHashMapFromArray [
        ["id", _id],
        ["name", _name],
        ["position", _position],
        ["locationType", _locationType],
        ["resourceWeight", _resourceWeight],
        ["displayRadius", _displayRadius],
        ["requiredWeightRatio", _requiredWeightRatio],
        ["cellIds", _cellIds],
        ["anchorCellId", _anchorCellId],
        ["owner", sideUnknown],
        ["state", "neutral"],
        ["level", 0],
        ["eastWeight", 0],
        ["westWeight", 0],
        ["totalWeight", 0],
        ["lastChanged", 0],
        ["lastLevelChanged", 0],
        ["capturedRestoreOwner", sideUnknown],
        ["capturedRestoreLevel", 0],
        ["capturedRestoreExpiresAt", 0],
        ["frontline", false],
        ["pressureWest", 0],
        ["pressureEast", 0],
        ["pressureWestLastAt", 0],
        ["pressureEastLastAt", 0],
        ["pressureWestReportState", "none"],
        ["pressureEastReportState", "none"],
        ["vulnerableSide", sideUnknown],
        ["vulnerableExpiresAt", 0],
        ["pendingUpgradeLevel", 0],
        ["pendingUpgradeStartedAt", 0],
        ["pendingUpgradeCompleteAt", 0]
    ]
];

{
    private _cell = FLO_ObjectiveCells get _x;
    private _role = ["support", "anchor"] select (_x isEqualTo _anchorCellId);

    _cell set ["objectiveId", _id];
    _cell set ["role", _role];
} forEach _cellIds;

diag_log format [
    "[FLO][Objective] Registered objective %1 (%2) with %3 cells",
    _id,
    _name,
    count _cellIds
];
