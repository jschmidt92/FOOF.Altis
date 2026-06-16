class CfgPatches {
    class foof_main {
        name = "FOOF";
        author = "Angel";
        requiredVersion = 2.18;
        requiredAddons[] = {
            "cba_main"
        };
        units[] = {};
        weapons[] = {};
    };
};

class CfgFunctions {
    class FLO {
        tag = "FLO";

        #include "functions\tickets\CfgFunctions.hpp"
        #include "functions\command\CfgFunctions.hpp"
        #include "functions\objectives\CfgFunctions.hpp"
        #include "functions\resources\CfgFunctions.hpp"
        #include "functions\fob\CfgFunctions.hpp"
        #include "functions\spawns\CfgFunctions.hpp"
        #include "functions\store\CfgFunctions.hpp"
        #include "functions\persistence\CfgFunctions.hpp"
    };

    #include "IDS_Logistics\IDS_Logistics_Functions.hpp"
};

#include "IDS_Logistics\CfgLogistics.hpp"
#include "IDS_Logistics\dialogs\BuildMenuDialog.hpp"
#include "ui\command\CommandVoteDialog.hpp"
#include "ui\deploy\DeployDialog.hpp"
#include "ui\store\StoreDialog.hpp"

class CfgRemoteExec {
    class Functions {
        mode = 1;
        jip = 0;

        class FLO_fnc_objectiveReceiveGridSnapshot {
            allowedTargets = 0;
            jip = 0;
        };

        class FLO_fnc_objectiveReceiveSnapshot {
            allowedTargets = 0;
            jip = 0;
        };

        class FLO_fnc_objectiveRequestSnapshot {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_resourceReceiveSnapshot {
            allowedTargets = 0;
            jip = 0;
        };

        class FLO_fnc_resourceRequestSnapshot {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_commandReceiveSnapshot {
            allowedTargets = 1;
            jip = 0;
        };

        class FLO_fnc_commandRequestSnapshot {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_commandVoteCommander {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_commandVoteFaction {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_fobRequestDeploy {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_fobAddClientAction {
            allowedTargets = 0;
            jip = 1;
        };

        class FLO_fnc_fobReceiveDeployResult {
            allowedTargets = 0;
            jip = 0;
        };

        class FLO_fnc_spawnRequestAssignment {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_spawnApplyAssignment {
            allowedTargets = 0;
            jip = 0;
        };

        class FLO_fnc_storeApplyKit {
            allowedTargets = 1;
            jip = 0;
        };

        class FLO_fnc_storeReceiveResponse {
            allowedTargets = 1;
            jip = 0;
        };

        class FLO_fnc_storeReceivePlacementResult {
            allowedTargets = 1;
            jip = 0;
        };

        class FLO_fnc_storeFinalizeVehiclePlacement {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_storeRequestHydrate {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_storeRequestCategory {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_storeRequestCheckout {
            allowedTargets = 2;
            jip = 0;
        };

        class FLO_fnc_persistenceApplyPlayerState {
            allowedTargets = 1;
            jip = 0;
        };

        class FLO_fnc_ticketApplyRespawnLock {
            allowedTargets = 1;
            jip = 0;
        };

        class IDS_Logistics_fnc_finalizeEntity {
            allowedTargets = 2;
            jip = 0;
        };

        class IDS_Logistics_fnc_deleteEntity {
            allowedTargets = 2;
            jip = 0;
        };

        class IDS_Logistics_fnc_toggleEntityVisibility {
            allowedTargets = 2;
            jip = 0;
        };

        class IDS_Logistics_fnc_receivePlacementResult {
            allowedTargets = 0;
            jip = 0;
        };
    };
};
