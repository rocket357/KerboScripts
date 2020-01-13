// testing bootscript unification

log_message("test").

WAIT 5. // let physics/ship fully load

// ***********************
// GLOBAL VARS
// ***********************

// SHIP INFO
GLOBAL SHIPTYPE IS SHIP:TYPE.
GLOBAL OLDSTAGE IS STAGE:NUMBER.

// FUEL INFO
GLOBAL MAXLFUEL IS STAGE:LIQUIDFUEL.
GLOBAL MAXOFUEL IS STAGE:OXIDIZER.
GLOBAL MAXSFUEL IS STAGE:SOLIDFUEL.
GLOBAL MAXEC IS STAGE:ELECTRICCHARGE.

// NAVIGATION INFO
GLOBAL MYORBIT IS 150000.  // orbit, in meters, might get overridden later
GLOBAL MYALTITUDE IS 4000. // flight altitude, in meters, might get overridden later
GLOBAL MYHEADING IS 90. // NORTH = 0, EAST = 90, SOUTH = etc...
GLOBAL MYPITCH IS 90. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN


// SAFETY INFOS
GLOBAL boostereject IS 0.
GLOBAL LAUNCHINPROGRESS IS 0.  // launching a rocket
GLOBAL INFLIGHT IS 0.  // flying a plane

// ***********************
// END GLOBAL VARS
// ***********************



// ***********************
// TRIGGERS
// ***********************
// STAGE DURING LAUNCH, IF APPROPRIATE AND SAFE lulz.
WHEN LAUNCHINPROGRESS = 1 AND MAXTHRUST = 0 THEN {
	log_message("LAUNCHINPROGRESS THRUST TRIGGER...").
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

WHEN INFLIGHT = 1 AND SHIP:ALTITUDE > (MYALTITUDE * 1.01) THEN {
	SET MYPITCH TO -2.
    PRESERVE.
}.

WHEN INFLIGHT = 1 AND SHIP:ALTITUDE < (MYALTITUDE * 0.99) AND SHIP:ALTITUDE > (MYALTITUDE * 0.95) THEN {
	SET MYPITCH TO 2.
    PRESERVE.
}.
// ***********************
// END TRIGGERS
// ***********************



// ***********************
// HELPER FUNCTIONS
// ***********************

function log_message {
	parameter message.
	
	LOG KUNIVERSE:REALTIME + " - " + message TO boot.log.
}.

function check_threshold {
	parameter metric.
	parameter tolerance.
	parameter target.
	
	// DEBUG
	//PRINT "check_threshold: " + metric + " " + tolerance + " " + target AT (10,3).
	
	IF (metric * (1 + tolerance / 100)) < target AND (metric * (1 - tolerance / 100)) > target {
		RETURN 1.  // within tolerance
	} ELSE IF (metric * (1 + tolerance / 100)) < target {
		RETURN -1.  // below threshold
	} ELSE {
		RETURN 2.  // over threshold
	}.
}.

// ***********************
// END HELPER FUNCTIONS
// ***********************



// ***********************
// SCREEN FUNCTIONS
// ***********************

function update_screen {
	CLEARSCREEN.
	update_screen_common().
	update_screen_custom().
}.

function update_screen_custom {
	IF SHIP:PERIAPSIS < SHIP:BODY:ATM:HEIGHT {
		SET MYPERIAPSIS TO "Sub-orbital flight.".
	} ELSE {
		SET MYPERIAPSIS TO ROUND(SHIP:PERIAPSIS,0).
	}.
	
	PRINT "MISSION:" AT (0,0).
	PRINT "  TARGET ORBIT: " + MYORBIT AT (0,1).
	
	PRINT "NAVIGATION SETTINGS:" AT (0,3).
	PRINT "  THROTTLE:     " + ROUND(THROTTLE * 100,0) + " % " AT (0,4).
	PRINT "  HEADING:      " + MYHEADING AT (0,5).
	PRINT "  PITCH:        " + MYPITCH + " degrees" AT (0,6).
	PRINT "  YAW:          " + SHIP:CONTROL:YAW AT (0,7).
	PRINT "  ROLL:         " + SHIP:CONTROL:ROLL AT (0,8).
}.

function update_screen_common {

	IF STAGE:NUMBER < OLDSTAGE {
		SET MAXLFUEL TO STAGE:LIQUIDFUEL.
		SET MAXOFUEL TO STAGE:OXIDIZER.
		SET MAXSFUEL TO STAGE:SOLIDFUEL.
		SET MAXEC TO STAGE:ELECTRICCHARGE.
		SET OLDSTAGE TO STAGE:NUMBER.
	}.
	
	IF SHIP:PERIAPSIS < SHIP:BODY:ATM:HEIGHT {
		SET MYPERIAPSIS TO "Sub-orbital".
	} ELSE {
		SET MYPERIAPSIS TO ROUND(SHIP:PERIAPSIS,0).
	}.
	
	IF SHIP:APOAPSIS < 0 {
		SET TTA TO "Infinite".  // Time-to-apoapsis
	} ELSE {
		SET TTA TO ROUND(ETA:APOAPSIS,0).
	}.
	
	IF STAGE:LIQUIDFUEL = MAXLFUEL {
		SET LFUELPERC TO 100.0.
	} ELSE {
		SET LFUELPERC TO ROUND(100 * (1 - (MAXLFUEL - STAGE:LIQUIDFUEL) / MAXLFUEL),2).
	}.
	
	IF STAGE:OXIDIZER = MAXOFUEL {
		SET OFUELPERC TO 100.0.
	} ELSE {
		SET OFUELPERC TO ROUND(100 * (1 - (MAXOFUEL - STAGE:OXIDIZER) / MAXOFUEL),2).
	}.
	
	IF STAGE:SOLIDFUEL = MAXSFUEL {
		SET SFUELPERC TO 100.0.
	} ELSE {
		SET SFUELPERC TO ROUND(100 * (1 - (MAXSFUEL - STAGE:SOLIDFUEL) / MAXSFUEL),2).
	}.

	IF STAGE:ELECTRICCHARGE = MAXEC {
		SET ECPERC TO 100.0.
	} ELSE {
		SET ECPERC TO ROUND(100 * (1 - (MAXEC - STAGE:ELECTRICCHARGE) / MAXEC),2).
	}.
	
	PRINT "MISSION INFORMATION:" AT (0,11).
	PRINT "  SOI:           " + SHIP:BODY:NAME AT (0,12).
	PRINT "  LAT/LNG:       " + ROUND(SHIP:LATITUDE,4) + "/" + ROUND(SHIP:LONGITUDE,4) AT (0,13).
	PRINT "  ATM CEILING:   " + SHIP:BODY:ATM:HEIGHT AT (0,14).
	PRINT "  SEA ALTITUDE:  " + ROUND(SHIP:ALTITUDE,0) AT (0,15).
	PRINT "(" + 100 * ROUND(SHIP:BODY:ATM:ALTITUDEPRESSURE(SHIP:ALTITUDE),8) + " % ATM)" AT (30,15).
	PRINT "  APOAPSIS:      " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
	PRINT TTA + " seconds" AT (30,16).
	PRINT "  PERIAPSIS:     " + MYPERIAPSIS AT (0,17).
	PRINT ROUND(ETA:PERIAPSIS,0) + " seconds" AT (30,17).
	
	PRINT "SHIP DETAILS:" AT (0,19).
	PRINT "  TYPE:          " + SHIPTYPE AT (0,20).
	
	PRINT "FUEL SYSTEM:" AT (0,22).
	PRINT "  STAGE:           " + STAGE:NUMBER AT (0,23).
	PRINT "  SHIP MASS TONS:  " + ROUND(SHIP:MASS,2) AT (0,24).
	PRINT "  SOLID FUEL:      " + ROUND(STAGE:SOLIDFUEL,2) AT (0,25).
	IF STAGE:SOLIDFUEL < MAXSFUEL {
		PRINT SFUELPERC + "% REMAINING" AT (30,25).
	}.
	PRINT "  LIQUID FUEL:     " + ROUND(STAGE:LIQUIDFUEL,2) AT (0,26).
	IF STAGE:LIQUIDFUEL < MAXLFUEL {
		PRINT LFUELPERC + "% REMAINING" AT (30,26).
	}.
	PRINT "  OXIDIZER:        " + ROUND(STAGE:OXIDIZER,2) AT (0,27).
	IF STAGE:OXIDIZER < MAXOFUEL {
		PRINT OFUELPERC + "% REMAINING" AT (30,27).
	}.
	PRINT "  ELECTRIC CHARGE: " + ROUND(STAGE:ELECTRICCHARGE,2) AT (0,28).
	IF STAGE:ELECTRICCHARGE < MAXEC {
		PRINT ECPERC + "% REMAINING" AT (30,28).
	}.
	
}.

// ***********************
// END SCREEN FUNCTIONS
// ***********************



// ***********************
// SHIP-SPECIFIC FUNCTIONS
// ***********************

function launch {
	parameter MYCUSTOMORBIT.
	GLOBAL MYORBIT IS MYCUSTOMORBIT.
	
	SET LAUNCHINPROGRESS TO 1.

	LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.
	SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
	LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER

	UNTIL SHIP:APOAPSIS > MYORBIT { // get apoapsis up to MYORBIT
		SET MYPITCH TO ROUND(90*((MYORBIT - SHIP:ALTITUDE) / MYORBIT), 1).
		SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
		update_screen().
		WAIT 1.
	}.
	
	// wait until we're up out of the atmosphere, then set pitch and wait to hit 90% of MYORBIT
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
	
	// build orbital velocity
	LOCK THROTTLE TO 1.
	UNTIL SHIP:PERIAPSIS > ( MYORBIT * 0.98 ) {  // get periapsis up to MYORBIT
		// Keep the APOAPSIS as close as we can to MYORBIT
		IF ETA:APOAPSIS < 200 AND ETA:APOAPSIS > 25 {
			IF SHIP:APOAPSIS > ( 1.01 * MYORBIT ) AND MYPITCH > -60 { 
				SET MYPITCH TO MYPITCH - 5.
			} ELSE IF SHIP:APOAPSIS < ( 0.99 * MYORBIT ) {
				SET MYPITCH TO 5.
			} ELSE {
				SET MYPITCH TO -5. // baseline
			}.
		} ELSE IF ETA:APOAPSIS > 200 {
			IF SHIP:APOAPSIS > ( 1.01 * MYORBIT ) {
				IF ETA:APOAPSIS > ETA:PERIAPSIS { // we've passed the APOAPSIS...catch up!
					SET MYPITCH TO 20.
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
			} ELSE IF ETA:APOAPSIS < 10 {
				SET MYPITCH TO 10.
			} ELSE IF ETA:APOAPSIS < 5 {
				SET MYPITCH TO 20.
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
	
	LOCK THROTTLE TO 0.0.
	update_screen().

	SET SASMODE TO "STABILITY". 
	SAS ON.
	RCS ON.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	
	SET LAUNCHINPROGRESS TO 0.
}.

function takeoff {
	parameter MYCUSTOMALTITUDE.
	
	GLOBAL MYALTITUDE IS MYCUSTOMALTITUDE.
	GLOBAL MYHEADING IS 90. // assuming takeoff from KSC
	GLOBAL MYPITCH IS 5.
	
	SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
	LOCK STEERING TO MYSTEER.

	// for stability in takeoff.
	SAS ON.
	RCS ON.

	LOCK THROTTLE TO 1.0.
	SET BRAKES TO FALSE.
	SET LIGHTS TO TRUE.
	STAGE.  // fire the engines!

	UNTIL SHIP:ALTITUDE > STARTALT + 10 {
		WAIT 1.
		update_screen().
	}.

	SET GEAR TO FALSE.
	SAS ON.
	RCS ON.
	SET INFLIGHT TO 1.

	UNTIL SHIP:ALTITUDE >= MYALTITUDE {
		UNTIL MYPITCH >= 25 {
			SET MYPITCH TO MYPITCH + 2.
			SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
			WAIT 1.
		}.
		update_screen().
		WAIT 1.
	}.
}.

// ***********************
// END SHIP-SPECIFIC FUNCTIONS
// ***********************



// ***********************
// BEGIN EXECUTION HERE
// ***********************

// at least once, for prosperity.
update_screen().

IF SHIPTYPE = "Rover" {
	// do rover automation stuff.
} ELSE IF SHIPTYPE = "Plane" {
	// do plane automation stuff.
	takeoff(1000).
} ELSE IF SHIPTYPE = "Ship" OR SHIPTYPE = "Relay" {
	// do ship stuff
	launch(MYORBIT).
}.

