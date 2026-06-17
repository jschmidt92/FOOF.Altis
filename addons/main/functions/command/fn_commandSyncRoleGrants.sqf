params ["_sideKey"];

private _state = FLO_CommandSideState get _sideKey;
private _roleAssignments = _state get "roleAssignments";
private _deputies = +(_roleAssignments get "deputy");
private _grants = _state get "permissionGrants";

{
    _grants set [_x, +_deputies];
} forEach ["build", "fob", "garage", "logistics", "store"];

_state set ["permissionGrants", _grants];
