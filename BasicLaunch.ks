// Contains code from https://ksp-kos.github.io/KOS/tutorials/quickstart.html#step-7-putting-it-all-together

//hellolaunch

//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.

//Next, we'll lock our throttle to 100%.
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
    PRINT "Staging".
    STAGE.
    PRESERVE.
}.

SET boostereject TO 0.

//This will be our main control loop for the ascent. 
// Adjusted for my rocket.
SET MYSTEER TO HEADING(90,90).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL SHIP:APOAPSIS > 100000 { //Remember, all altitudes will be in meters, not kilometers

    IF boostereject = 0 AND STAGE:SOLIDFUEL < 0.1 {
        SET boostereject TO 1.
        STAGE.  // could be dangerous if not using a solid fuel booster setup!
    }

    //For the initial ascent, we want our steering to be straight
    //up and rolled due east
    IF SHIP:VELOCITY:SURFACE:MAG < 100 {
        //This sets our steering 90 degrees up and yawed to the compass
        //heading of 90 degrees (east)
        SET MYSTEER TO HEADING(90,90).

    //Once we pass 100m/s, we want to pitch down ten degrees
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 100 AND SHIP:VELOCITY:SURFACE:MAG < 200 {
        SET MYSTEER TO HEADING(90,90).
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    //Each successive IF statement checks to see if our velocity
    //is within a 100m/s block and adjusts our heading down another
    //ten degrees if so
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 200 AND SHIP:VELOCITY:SURFACE:MAG < 300 {
        SET MYSTEER TO HEADING(90,90).
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 300 AND SHIP:VELOCITY:SURFACE:MAG < 400 {
        SET MYSTEER TO HEADING(90,90).
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 400 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        SET MYSTEER TO HEADING(90,80).
        PRINT "Pitching to 80 degrees" AT(0,15).
        LOCK THROTTLE TO 0.82.
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 600 {
        SET MYSTEER TO HEADING(90,70).
        PRINT "Pitching to 70 degrees" AT(0,15).
        LOCK THROTTLE TO 0.67.
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 600 AND SHIP:VELOCITY:SURFACE:MAG < 700 {
        SET MYSTEER TO HEADING(90,60).
        PRINT "Pitching to 60 degrees" AT(0,15).
        LOCK THROTTLE TO 0.5.
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 700 AND SHIP:VELOCITY:SURFACE:MAG < 800 {
        SET MYSTEER TO HEADING(90,50).
        PRINT "Pitching to 50 degrees" AT(0,15).
        LOCK THROTTLE TO 0.33.
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).

    //Beyond 800m/s, we can keep facing towards 10 degrees above the horizon and wait
    //for the main loop to recognize that our apoapsis is above 100km
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 800 {
        SET MYSTEER TO HEADING(90,40).
        PRINT "Pitching to 40 degrees" AT(0,15).
        LOCK THROTTLE TO 0.17.
        PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
    }.
}.

PRINT "100km apoapsis reached, cutting throttle".

//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.

// while we're waiting, let the pilot/RCS maintain heading.
SET MYSTEER TO HEADING(90,-10).
SAS ON.
RCS ON.

// wait until we hit 90km
UNTIL SHIP:ALTITUDE > 90000 {
    PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
    WAIT 1.
}.

// set heading and throttle to achieve orbital speed
SAS OFF.
RCS OFF.
SET MYSTEER TO HEADING(90,-10).
LOCK THROTTLE TO 1.0.
PRINT "Building orbital speed" AT (0,15).

// do this until the orbital min altitude hits 75km
UNTIL SHIP:PERIAPSIS > 75000 {
    PRINT "APOAPSIS:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
    PRINT "PERIAPSIS: " + ROUND(SHIP:PERIAPSIS,0) AT (0,17).
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
SET SASMODE TO "RADIALIN". 
SAS ON.
RCS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
