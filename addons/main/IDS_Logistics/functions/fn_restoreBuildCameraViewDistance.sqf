if (!hasInterface) exitWith {};

if (!isNil "IDS_Logistics_PreviousViewDistance") then {
    setViewDistance IDS_Logistics_PreviousViewDistance;
    IDS_Logistics_PreviousViewDistance = nil;
};

if (!isNil "IDS_Logistics_PreviousObjectViewDistance") then {
    setObjectViewDistance IDS_Logistics_PreviousObjectViewDistance;
    IDS_Logistics_PreviousObjectViewDistance = nil;
};

IDS_Logistics_CameraViewDistanceLimit = nil;

true
