params ["_entryKind", "_category", "_priceValue"];

if (_entryKind isNotEqualTo "gear") exitWith { false };
if !(_category in FLO_StoreDeploymentFundCategories) exitWith { false };

_priceValue <= FLO_StoreDeploymentFundMaxItemPrice
