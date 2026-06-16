FLO_FOBDeployCost = 1500;
FLO_FOBBuildRadius = 100;
FLO_FOBMinDistance = 500;

FLO_COPDeployCost = 600;
FLO_COPBuildRadius = 60;
FLO_COPMinDistance = 300;
FLO_COPMaxPerSide = 4;
FLO_COPEnemyDisableRadius = 200;

FLO_BaseRespawnCheckInterval = 10;

FLO_FOBSideClasses = createHashMapFromArray [
    ["WEST", "Land_Cargo_HQ_V1_F"],
    ["EAST", "Land_Cargo_HQ_V3_F"]
];

FLO_COPSideClasses = createHashMapFromArray [
    ["WEST", "Land_Cargo_House_V1_F"],
    ["EAST", "Land_Cargo_House_V3_F"]
];

FLO_FOBBuildClasses = [
    "Land_Cargo_HQ_V1_F",
    "Land_Cargo_HQ_V3_F",
    "Land_Cargo_HQ_V4_F",
    "Land_Medevac_HQ_V1_F",
    "Land_Cargo_House_V1_F",
    "Land_Cargo_House_V3_F",
    "Land_Cargo_House_V4_F"
];

FLO_COPLogisticsCategories = [
    "Fortification",
    "Logistics"
];

FLO_FOBDeployDialogIdd = 9900;
FLO_FOBDeployBrowserIdc = 9901;
FLO_FOBDeployBrowserReady = false;
FLO_FOBDeployRenderKey = "";
FLO_FOBDeployWebActionInvoker = compile "params ['_control', '_args']; _control ctrlWebBrowserAction _args;";
