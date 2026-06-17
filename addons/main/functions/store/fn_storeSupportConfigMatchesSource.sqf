params ["_cfg", "_source"];

_source params ["_sourceName", "_patches", "_addons", "_prefixes", "_contains", "_categories"];

private _candidates = [
    configName _cfg,
    configSourceMod _cfg
];

_candidates append (configSourceAddonList _cfg);

(_candidates findIf {
    ([_x, _addons, "prefix"] call FLO_fnc_storeStringMatchesPatterns) ||
    {[_x, _prefixes, "prefix"] call FLO_fnc_storeStringMatchesPatterns} ||
    {[_x, _contains, "contains"] call FLO_fnc_storeStringMatchesPatterns}
}) >= 0
