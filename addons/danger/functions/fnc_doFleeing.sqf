#include "script_component.hpp"
/*
 * Author: nkenny
 * Adds debug and unique behaviour on unit fleeing
 *
 * Arguments:
 * 0: Unit fleeing <OBJECT>
 *
 * Return Value:
 * boolean
 *
 * Example:
 * [bob] call lambs_danger_fnc_fleeing;
 *
 * Public: No
*/
params ["_unit", ["_distance", 55]];

// check disabled
if (
    _unit getVariable [QGVAR(disableAI), false]
    || {!(_unit checkAIFeature "PATH")}
    || {!(_unit checkAIFeature "MOVE")}
    || {GVAR(disableAIFleeing)}
) exitWith {false};

// check for vehicle
private _onFoot = isNull (objectParent _unit);

// variable
_unit setVariable [QGVAR(currentTask), ["Fleeing (vehicle)", "Fleeing"] select _onFoot, EGVAR(main,debug_functions)];
_unit setVariable [QGVAR(currentTarget), objNull, EGVAR(main,debug_functions)];

// eventhandler
[QGVAR(OnFleeing), [_unit, group _unit]] call EFUNC(main,eventCallback);

// enemy
private _enemy = _unit findNearestEnemy _unit;

// Abandon vehicles in need!
if (RND(0.5) && {!_onFoot} && {canUnloadInCombat vehicle _unit} && {speed vehicle _unit < 3} && {isTouchingGround vehicle _unit}) exitWith {
    [_unit] orderGetIn false;
    _unit setSuppression 1;  // prevents instant laser aim - nkenny
    false
};

// no further action in vehicle
if (!_onFoot) exitWith {false};

// get destination
private _pos = expectedDestination _unit select 0;

// on foot and seen by enemy
if (_unit distance2D _enemy < 100 || {!(terrainIntersectASL [ eyePos _unit, eyePos _enemy])}) then {

    // callout
    if (RND(0.4) && {getSuppression _unit > 0.5}) then {
        [_unit, "Stealth", "panic", 55] call EFUNC(main,doCallout);
    };

    // inside or under cover!
    if (lineIntersects [eyePos _unit, (eyePos _unit) vectorAdd [0, 0, 10], _unit]) exitWith {
        doStop _unit;
    };

    // update pos
    private _cover = nearestTerrainObjects [_unit getPos [GVAR(searchForHide) + 4, _enemy getDir _unit], [], GVAR(searchForHide), false, true];
    if !(_cover isEqualTo []) then {_pos = _cover select 0;};

    // force anim
    private _direction = _unit getRelDir _pos;
    private _relPos = _unit getRelPos [5, 0];
    private _anim = call {
        if (_unit distance2D _pos < 1) exitWith {["Down"];};
        if (_direction > 315) exitWith {_relPos = _unit getRelPos [5, -15];["SlowF", "SlowLF"]};
        if (_direction > 225) exitWith {_relPos = _unit getRelPos [5, -60];["SlowL", "SlowLF"]};
        if (_direction > 135) exitWith {_relPos = _unit getRelPos [6, 180];["SlowB"]};
        if (_direction > 45) exitWith {_relPos = _unit getRelPos [6, 60];["SlowR", "SlowRF"]};
        _relPos = _unit getRelPos [6, 15];
        ["SlowF", "SlowRF"]
    };
    _unit setDestination [_relPos, "FORMATION PLANNED", false];
    [_unit, selectRandom _anim, true] call EFUNC(main,doGesture);

    // hide
    private _buildings = [_unit, GVAR(searchForHide), true, true] call EFUNC(main,findBuildings);
    if !(_buildings isEqualTo []) then {

        // move
        _unit doMove (_buildings select 0);

    };

};

// debug
if (EGVAR(main,debug_functions)) then {format ["%1 Fleeing! (%2m)", side _unit,round (_unit distance (expectedDestination _unit select 0))] call EFUNC(main,debugLog);};

// end
true