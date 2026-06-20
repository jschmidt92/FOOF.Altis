params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "store::ready": {
        uiNamespace setVariable ["FLO_StoreControl", _control];
        [player, FLO_StoreActiveFobNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
        ["store::savedKits", createHashMapFromArray [
            ["success", true],
            ["message", ""],
            ["kits", [] call FLO_fnc_storeSavedKitsLoad]
        ]] call FLO_fnc_storeUpdateDialog;
    };
    case "store::category": {
        [player, FLO_StoreActiveFobNetId, _data get "category"] remoteExecCall ["FLO_fnc_storeRequestCategory", 2];
    };
    case "store::checkout": {
        [player, FLO_StoreActiveFobNetId, _data get "items"] remoteExecCall ["FLO_fnc_storeRequestCheckout", 2];
    };
    case "store::refresh": {
        [player, FLO_StoreActiveFobNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
        ["store::savedKits", createHashMapFromArray [
            ["success", true],
            ["message", ""],
            ["kits", [] call FLO_fnc_storeSavedKitsLoad]
        ]] call FLO_fnc_storeUpdateDialog;
    };
    case "store::kitSave": {
        private _payload = [_data get "name"] call FLO_fnc_storeSavedKitsSave;
        ["store::savedKits", _payload] call FLO_fnc_storeUpdateDialog;
    };
    case "store::kitDelete": {
        private _payload = [_data get "id"] call FLO_fnc_storeSavedKitsDelete;
        ["store::savedKits", _payload] call FLO_fnc_storeUpdateDialog;
    };
    case "store::vehiclePlace": {
        [_data get "id"] call FLO_fnc_storeStartVehiclePlacement;
    };
    case "store::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Store] Unhandled store UI event: %1", _event];
    };
};

true
