#include "script_component.hpp"
/*
 * Author: nkenny
 * Special CQB attack pattern clearing building by building
 *
 * Arguments:
 * 0: Unit assault cover <OBJECT>
 * 1: Enemy <OBJECT> or <ARRAY>
 *
 * Return Value:
 * boolean
 *
 * Example:
 * [bob, angryJoe] call lambs_danger_fnc_assaultCQB;
 *
 * Public: No
*/
params ["_unit", ["_target", objNull], ["_range", 20]];

// check if stopped or busy
if (
    stopped _unit
    || {!(_unit checkAIFeature "PATH")}
    || {!(_unit checkAIFeature "MOVE")}
    || {currentCommand _unit in ["GET IN", "ACTION", "HEAL", "ATTACK"]}
) exitWith {false};

// settings
_unit setUnitPosWeak "UP";

// variables
_unit setVariable [QGVAR(currentTarget), objNull, EGVAR(main,debug_functions)];
_unit setVariable [QGVAR(currentTask), "Assault Building", EGVAR(main,debug_functions)];

// get buildings
private _buildings = (group _unit) getVariable [QGVAR(inCQB), []];
_buildings = _buildings select {count (_x getVariable [QGVAR(CQB_cleared_) + str (side _unit), [0, 0]]) > 0};

// exit on no buildings -- middle unit pos
if (_buildings isEqualTo []) exitWith {

    _unit doFollow leader _unit;

};

// define building
private _building = _buildings select 0;

// find spots
private _buildingPos = _building getVariable [QGVAR(CQB_cleared_) + str (side _unit), (_building buildingPos -1) select {lineIntersects [AGLToASL _x, (AGLToASL _x) vectorAdd [0, 0, 4]]}];
private _buildingPosSelected = _buildingPos select 0;

if (isNil "_buildingPosSelected") then {
    _buildingPosSelected = _building modelToWorld [0,0,0];
};

// move to position
_unit doMove (_buildingPosSelected vectorAdd [0.5 - random 1, 0.5 - random 1, 0]);

// debug
if (EGVAR(main,debug_functions)) then {
    private _arrow = createSimpleObject ["Sign_Arrow_Large_F", AGLtoASL _buildingPosSelected, true];
    _arrow setObjectTexture [0, [_unit] call EFUNC(main,debugObjectColor)];
    [{deleteVehicle _this}, _arrow, 20] call CBA_fnc_waitAndExecute;
};

// speed
_unit forceSpeed ([_unit, _buildingPosSelected] call FUNC(assaultSpeed));

// Close range cleanups
if (RND(0.95) || {_unit distance _buildingPosSelected < 1.6}) then {

    // remove buildingpos
    _buildingPos deleteAt 0;

    // update variable
    _building setVariable [QGVAR(CQB_cleared_) + str (side _unit), _buildingPos];

} else {
    // distant units crouch
    if (_unit distance _building > 30) then {
        _unit setUnitPosWeak "MIDDLE";
    };
};

// update group variable
if (_buildingPos isEqualTo []) then {
    (group _unit) setVariable [QGVAR(inCQB), _buildings - [_building]];
};

// debug
if (EGVAR(main,debug_functions) && {leader _unit isEqualTo _unit}) then {
    format ["%1 assaulting building (%2 @ %3m - %4x spots left)",
        side _unit,
        name _unit,
        round (_unit distance _buildingPosSelected),
        count _buildingPos
    ] call EFUNC(main,debugLog);
};

// repeat

// end
true