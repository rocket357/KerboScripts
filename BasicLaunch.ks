// Contains code from https://ksp-kos.github.io/KOS/tutorials/quickstart.html#step-7-putting-it-all-together

GLOBAL MYSTATUS IS "PRELAUNCH"
GLOBAL MYHEADING IS 0. // NORTH = 0, EAST = 90, SOUTH = etc...
GLOBAL MYORBIT IS 100000. // ORBIT ALTITUDE IN METERS
GLOBAL MYPITCH IS 90. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN

function update_screen {
	CLEARSCREEN.
	PRINT "THROTTLE:  " + THROTTLE AT (0,11).
	PRINT "STATUS:    " + MYSTATUS AT (0,12).
	PRINT "HEADING:   " + MYHEADING at (0,14).
        PRINT "PITCH:     " + MYPITCH + " degrees" AT(0,15).
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
	PRINT "PERIAPSIS: " + ROUND(SHIP:PERIAPSIS,0) AT (0,17).
}.

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
    SET MYSTATUS TO "Staging...".
    update_screen().
    STAGE.
    PRESERVE.
}.

SET boostereject TO 0.

//This will be our main control loop for the ascent. 
// Adjusted for my rocket.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL SHIP:APOAPSIS > MYORBIT { //Remember, all altitudes will be in meters, not kilometers
    SET MYSTATUS TO "Gaining altitude.".

    IF boostereject = 0 AND STAGE:SOLIDFUEL < 0.1 {
        SET boostereject TO 1.
        STAGE.  // could be dangerous if not using a solid fuel booster setup!
    }

    //For the initial ascent, we want our steering to be straight
    //up and rolled to MYHEADING
    IF SHIP:VELOCITY:SURFACE:MAG >= 400 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        SET MYPITCH TO 80.
        LOCK THROTTLE TO 0.82.
		
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 600 {
	SET MYPITCH TO 70.
        LOCK THROTTLE TO 0.67.

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 600 AND SHIP:VELOCITY:SURFACE:MAG < 700 {
	SET MYPITCH TO 60.
        LOCK THROTTLE TO 0.5.

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 700 AND SHIP:VELOCITY:SURFACE:MAG < 800 {
	SET MYPITCH TO 50.
        LOCK THROTTLE TO 0.33.

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 800 {
	SET MYPITCH TO 40.
    }.

    SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
    update_screen().
    WAIT 1.
}.

PRINT "100km apoapsis reached, cutting throttle".

//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.

// while we're waiting, let the pilot/RCS maintain heading.
SET MYPITCH TO -10.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
update_screen().
SAS ON.
RCS ON.

// wait until we hit 90km
UNTIL SHIP:ALTITUDE > 90000 {
    update_screen().
    WAIT 1.
}.

// set heading and throttle to achieve orbital speed
SAS OFF.
RCS OFF.
SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK THROTTLE TO 1.0.
SET MYSTATUS = "Building Orbital Speed.".
update_screen().

// do this until the orbital min altitude hits 75km
UNTIL SHIP:PERIAPSIS > 75000 {
    update_screen().
    WAIT 1.
}.

// we're in orbit, dammit
LOCK THROTTLE TO 0.0.
WAIT 10.  // simmah down!

// let the pilot take over with RCS and stuff
// to hold "head down" towards Kerbin.
// May crash the program if the pilot 
// isn't high enough level to understand 
// "RADIALIN"
// SASMODE Valid strings are "PROGRADE", "RETROGRADE", "NORMAL", "ANTINORMAL", "RADIALOUT", "RADIALIN", 
// "TARGET", "ANTITARGET", "MANEUVER", "STABILITYASSIST", and "STABILITY". 
SET SASMODE TO "STABILITY". 
SAS ON.
RCS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
// :wq
