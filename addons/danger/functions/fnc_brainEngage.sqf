#include "script_component.hpp"
/*
 * Author: nkenny
 * handles responses while engaging
 *
 * Arguments:
 * 0: unit doing the avaluation <OBJECT>
 * 1: yype of data <NUMBER>
 * 2: yarget <OBJECT>
 * 3: distance to target <NUMBER>
 *
 * Return Value:
 * number, timeout
 *
 * Example:
 * [bob, 0, angryBob, 100] call lambs_danger_fnc_brainEngage;
 *
 * Public: No
*/

/*
    Engage actions 
    0 Enemy detected (but near)
    1 Fire
    3 Enemy near
    8 CanFire
*/

params ["_unit", ["_type", 0], ["_target", objNull]];

// timeout
private _timeout = time + 4;

// check
if (isNull _target) exitWith {
    _unit forceSpeed 1;
    _timeout
};

// look at_this 
if (_unit knowsAbout _target > 3.5) then {
    _unit lookAt _target; 
};

// distance
private _distance = _unit distance2D _target;

// near, go for CQB
if (_distance < GVAR(CQB_range)) exitWith {

    [_unit, _target] call FUNC(doAssault);
    _timeout

};

// far, try to suppress
if (_type in [0, 8] && {needReload _unit < 0.6}) exitWith {

    [_unit, eyePos _target] call FUNC(doSuppress);
    _timeout + 1

};

// end
_timeout