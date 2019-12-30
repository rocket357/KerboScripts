// Contains code from https://ksp-kos.github.io/KOS/tutorials/quickstart.html#step-7-putting-it-all-together

GLOBAL MYSTATUS IS "PRELAUNCH".
GLOBAL MYHEADING IS 0. // NORTH = 0, EAST = 90, SOUTH = etc...
GLOBAL MYORBIT IS 250000. // ORBIT ALTITUDE IN METERS
GLOBAL MYPITCH IS 90. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN

function check_threshold {
	parameter metric.
	parameter tolerance.
	parameter target.
	
	PRINT "check_threshold: " + metric + " " + tolerance + " " + target AT (0,1).
	
	IF metric * (1 + tolerance / 100) < target AND metric * (1 - tolerance / 100) > target {
		RETURN 1.
	}.
	
	RETURN 0.
}.

function update_screen {
	IF SHIP:PERIAPSIS < 70000 {
		SET MYPERIAPSIS TO "Sub-orbital flight.".
	} ELSE {
		SET MYPERIAPSIS TO ROUND(SHIP:PERIAPSIS,0).
	}.
	CLEARSCREEN.
	
	PRINT "STATUS:    " + MYSTATUS AT (0,11).
	PRINT "THROTTLE:  " + ROUND(THROTTLE * 100,0) + " % " AT (0,12).
	PRINT "HEADING:   " + MYHEADING at (0,13).
    PRINT "PITCH:     " + MYPITCH + " degrees" AT(0,14).
	
	PRINT "ALTITUDE:  " + ROUND(SHIP:ALTITUDE,0) AT (0,16).
    PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,17).
	PRINT "PERIAPSIS: " + MYPERIAPSIS AT (0,18).
}.

GLOBAL boostereject IS 0.
LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}

CLEARSCREEN.

//This is a trigger that constantly checks to see if our thrust is zero.
WHEN MAXTHRUST = 0 THEN {
    IF boostereject = 0 AND SHIP:ALTITUDE > 1000 {
		SET MYSTATUS TO "MAIN STAGE!".
        SET boostereject TO 1.
		//SET SHIP:CONTROL:ROLL TO 1.0. // build up some rotation to throw boosters lulz Warn onboard kerbals first.
		WAIT 2.
        STAGE.  // launch the boosters into the abyss.
		WAIT 2.
		SET SHIP:CONTROL:ROLL TO 0.
    } ELSE {
		SET MYSTATUS TO "BOOSTER STAGE!".
		STAGE.
	}.
	update_screen().	
    PRESERVE.
}.


//This will be our main control loop for the ascent. 
// Adjusted for my rocket.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL SHIP:APOAPSIS > MYORBIT { //Remember, all altitudes will be in meters, not kilometers

    // Set pitch to a percentage of desired altitude.  i.e.
    // 90 on ground, 45 halfway to MYORBIT, and 0 at MYORBIT
    // This will have the effect of rolling the aircraft gently
    // rather than abruptly.  May need adjustment at very high
    // or very low values of MYORBIT.
    SET MYPITCH TO ROUND(90*((MYORBIT - SHIP:ALTITUDE) / MYORBIT), 0).
	
    SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
    update_screen().
    WAIT 1.
}.

SET MYSTATUS TO "Target APOAPSIS reached, throttle down".
LOCK THROTTLE TO 0.

// We need to hit ~90% of the target apoapsis
SET TARGETAPO TO MYORBIT * 0.9.
UNTIL SHIP:ALTITUDE > TARGETAPO {
    update_screen().
    WAIT 1.
}.

// set heading and throttle to achieve orbital speed
SET MYPITCH TO -5.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK THROTTLE TO 1.0.
SET MYSTATUS TO "Building Orbital Speed.".
update_screen().

WAIT 2. // let heading/pitch stabilize

UNTIL SHIP:PERIAPSIS > MYORBIT * 0.9 {
	// Keep the APOAPSIS as close as we can to MYORBIT
	IF SHIP:VERTICALSPEED < 0 {
		SET MYPITCH TO 5.
	} ELSE IF SHIP:VERTICALSPEED > 0 {
		SET MYPITCH TO -5.
	}.
    SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
    update_screen().
    WAIT 5.
}.

// NORMALIZE MYORBIT
// check that we're within 5% of PERIAPSIS
IF check_threshold(SHIP:ALTITUDE, 5, SHIP:PERIAPSIS) {
	SAS ON.
	SET SASMODE TO "RETROGRADE".
	LOCK THROTTLE TO 0.25.
	UNTIL SHIP:APOAPSIS * 0.98 < MYORBIT {
		WAIT 0.1.
	}.
	LOCK THROTTLE TO 0.
	SET SASMODE TO "PROGRADE".
	SAS OFF.
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

FOR f IN SHIP:MODULESNAMED("ModuleProceduralFairing") { f:DOEVENT("deploy"). }.
WAIT 5.
FOR a in SHIP:PARTSDUBBED("HighGainAntenna5") { a:DOEVENT("deploy"). }.
SET PANELS TO TRUE. // deploy solar panels

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SET MYSTATUS TO "Returning Control to Pilot.".
update_screen().
// :wq
