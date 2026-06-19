params ["_uid"];

if (!isServer) exitWith { 0 };
if (_uid isEqualTo "") exitWith { 0 };

if !(_uid in FLO_StoreDeploymentFunds) then {
    FLO_StoreDeploymentFunds set [_uid, FLO_StoreDeploymentFundAmount];
    ["deploymentFundCreated"] call FLO_fnc_persistenceScheduleSave;
};

FLO_StoreDeploymentFunds get _uid
