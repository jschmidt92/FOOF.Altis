FLO_IntelDialogIdd = 9600;
FLO_IntelBrowserIdc = 9601;

FLO_IntelSearchDistance = 3;
FLO_IntelDropChance = 0.32;
FLO_IntelBaseChance = 0.08;

FLO_IntelPlayerSearchRadius = 2500;
FLO_IntelPlayerMarkerRadius = 900;

FLO_IntelBaseRadiusStart = 4000;
FLO_IntelBaseRadiusStep = 750;
FLO_IntelBaseRadiusMin = 1000;

FLO_IntelMarkerTtl = 300;
FLO_IntelSearchActionText = "<t size='1.35' color='#25D7FF' font='RobotoCondensedBold'>Search Intel</t>";

FLO_IntelActiveBodyNetId = "";
FLO_IntelBrowserReady = false;
FLO_IntelLastPayload = createHashMap;
FLO_IntelMarkers = [];
FLO_IntelEntityKilledEh = -1;

FLO_IntelBodies = createHashMap;
FLO_IntelBaseFinds = createHashMapFromArray [
    ["WEST", 0],
    ["EAST", 0]
];
