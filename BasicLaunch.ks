// Contains code from https://ksp-kos.github.io/KOS/tutorials/quickstart.html#step-7-putting-it-all-together

GLOBAL MYORBIT IS 150000. // ORBIT ALTITUDE IN METERS
GLOBAL MYHEADING IS 0. // NORTH = 0, EAST = 90, SOUTH = etc...

function check_threshold {
	parameter metric.
	parameter tolerance.
	parameter target.
	
	// DEBUG
	PRINT "check_threshold: " + metric + " " + tolerance + " " + target AT (10,3).
	
	IF metric * (1 + tolerance / 100) < target AND metric * (1 - tolerance / 100) > target {
		RETURN 1.  // within tolerance
	} ELSE IF metric * (1 + tolerance / 100) < target {
		RETURN -1.  // below threshold
	} ELSE {
		RETURN 2.  // over threshold
	}.
}.

function update_screen {
	IF SHIP:PERIAPSIS < SHIP:BODY:ATM:HEIGHT {
		SET MYPERIAPSIS TO "Sub-orbital flight.".
	} ELSE {
		SET MYPERIAPSIS TO ROUND(SHIP:PERIAPSIS,0).
	}.
	CLEARSCREEN.
	
	PRINT "MISSION:" AT (0,0).
	PRINT "  TARGET ORBIT: " + MYORBIT AT (0,1).
	PRINT "  STATUS:       " + SHIP:STATUS AT (0,2).
	PRINT "  DEBUG: " AT (0,3).
	
	PRINT "NAVIGATION SETTINGS:" AT (0,6).
	PRINT "  THROTTLE:     " + ROUND(THROTTLE * 100,0) + " % " AT (0,7).
	PRINT "  HEADING:      " + MYHEADING AT (0,8).
	PRINT "  PITCH:        " + MYPITCH + " degrees" AT (0,9).
	PRINT "  YAW:          " + SHIP:CONTROL:YAW AT (0,10).
	PRINT "  ROLL:         " + SHIP:CONTROL:ROLL AT (0,11).
}.

IF MYORBIT < SHIP:BODY:ATM:HEIGHT {
	PRINT "WARNING: Orbit set below atmosphere ceiling!" AT (0,0).
	PRINT "         This will *NOT* work as expected!" AT (0,1).
	PRINT 1 / 0.
}.

GLOBAL boostereject IS 0.
LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM { local countdown is 5. } UNTIL countdown = 0 STEP { SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}.

CLEARSCREEN.

//This is a trigger that constantly checks to see if our thrust is zero.
WHEN MAXTHRUST = 0 THEN {
    IF boostereject = 0 AND SHIP:ALTITUDE > 1000 {
        SET boostereject TO 1.
		SET SHIP:CONTROL:ROLL TO 1.0. // build up some rotation to throw boosters lulz Warn onboard kerbals first.
		WAIT 2.
        STAGE.  // launch the boosters into the abyss.
		WAIT 2.
		SET SHIP:CONTROL:ROLL TO 0.
    } ELSE {
		STAGE.
	}.
	update_screen().	
    PRESERVE.
}.

GLOBAL MYPITCH IS 90. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER

UNTIL SHIP:APOAPSIS > MYORBIT {

    // Set pitch to a percentage of desired altitude.  i.e.
    // 90 on ground, 45 halfway to MYORBIT, and 0 at MYORBIT
    // This will have the effect of rolling the aircraft gently
    // rather than abruptly.  May need adjustment at very high
    // or very low values of MYORBIT.
    SET MYPITCH TO ROUND(90*((MYORBIT - SHIP:ALTITUDE) / MYORBIT), 1).
	
    SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
    update_screen().
    WAIT 1.
}.

SET MYSTATUS TO "Target APOAPSIS reached".
LOCK THROTTLE TO 0.

UNTIL SHIP:ALTITUDE >= SHIP:BODY:ATM:HEIGHT { // 70k for Kerbin
	update_screen().
	WAIT 1.
}.

SET MYPITCH TO -10.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).


UNTIL SHIP:ALTITUDE >= ( MYORBIT * 0.9 ) {
	update_screen().
	WAIT 1.
}.

LOCK THROTTLE TO 1.

UNTIL SHIP:PERIAPSIS > ( MYORBIT * 0.98 ) {
	// Keep the APOAPSIS as close as we can to MYORBIT
	IF ETA:APOAPSIS < 200 AND ETA:APOAPSIS > 25 {
		IF SHIP:APOAPSIS > ( 1.01 * MYORBIT ) AND MYPITCH > -60 { 
			SET MYPITCH TO MYPITCH - 10.
		} ELSE IF SHIP:APOAPSIS < ( 0.99 * MYORBIT ) {
			SET MYPITCH TO 5.
		} ELSE {
			SET MYPITCH TO -5. // baseline
		}.
	} ELSE IF ETA:APOAPSIS > 200 {
		IF SHIP:APOAPSIS > ( 1.01 * MYORBIT ) {
			IF ETA:APOAPSIS > ETA:PERIAPSIS { // we've passed the APOAPSIS...catch up!
				SET MYPITCH TO 10.
			} ELSE {
				IF MYPITCH > -60 {
					SET MYPITCH TO MYPITCH - 1.
				}.
			}.
		} ELSE {
			SET MYPITCH to -5.
		}.
	} ELSE { // ETA:APOAPSIS is < 25 sec...we're getting close to APOAPSIS!
		IF SHIP:ALTITUDE >= MYORBIT {
			SET MYPITCH TO -2.
		} ELSE IF ETA:APOAPSIS < 5 {
			SET MYPITCH TO 10.
		} ELSE {
			IF SHIP:APOAPSIS > MYORBIT {
				SET MYPITCH TO -2.
			} ELSE {
				SET MYPITCH TO 2.
			}.
		}.
	}.
	SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
	update_screen().
	WAIT 0.1.
}.

// we're in orbit, dammit
LOCK THROTTLE TO 0.0.
update_screen().
WAIT 10.  // simmah down!

// SASMODE Valid strings are "PROGRADE", "RETROGRADE", "NORMAL", "ANTINORMAL", "RADIALOUT", "RADIALIN", 
// "TARGET", "ANTITARGET", "MANEUVER", "STABILITYASSIST", and "STABILITY". 
SET SASMODE TO "STABILITY". 
SAS ON.
RCS ON.


SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

SET MYSTATUS TO "Returning Control to Pilot.".
update_screen().
