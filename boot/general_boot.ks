// testing bootscript unification

log_message("test").

WAIT 5. // let physics/ship fully load

// ***********************
// GLOBAL VARS
// ***********************


// FUEL INFO
GLOBAL MAXLFUEL IS STAGE:LIQUIDFUEL.
GLOBAL MAXOFUEL IS STAGE:OXIDIZER.
GLOBAL MAXSFUEL IS STAGE:SOLIDFUEL.

// SHIP INFO
GLOBAL SHIPTYPE IS SHIP:TYPE.
GLOBAL OLDSTAGE IS STAGE:NUMBER.

// NAVIGATION INFO
GLOBAL MYORBIT IS 120000.  // orbit, in meters, might get overridden later
GLOBAL MYALTITUDE IS 4000. // flight altitude, in meters, might get overridden later
GLOBAL STARTALT IS SHIP:ALTITUDE. // initial/starting altitude
GLOBAL MYHEADING IS 90. // NORTH = 0, EAST = 90, SOUTH = 180, WEST = 270
GLOBAL MYPITCH IS 90. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN

// MISSION INFO
GLOBAL MYWAYPOINTS IS ALLWAYPOINTS().
GLOBAL WPIDX IS 0.


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
WHEN LAUNCHINPROGRESS = 1 AND MAXSFUEL > 0 AND STAGE:SOLIDFUEL = 0 THEN {
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

WHEN INFLIGHT = 1 AND ALT:RADAR > (MYALTITUDE * 1.01) AND MYPITCH > -2 THEN {
	SET MYPITCH TO 0.
    PRESERVE.
}.

WHEN INFLIGHT = 1 AND ALT:RADAR < (MYALTITUDE * 0.99) AND MYPITCH < 2  AND SHIP:ALTITUDE > (MYALTITUDE * 0.95) THEN {
	SET MYPITCH TO 2.
    PRESERVE.
}.

WHEN INFLIGHT = 1 AND ALT:RADAR < (MYALTITUDE * 0.99) AND MYPITCH >= 2  AND SHIP:ALTITUDE > (MYALTITUDE * 0.95) THEN {
	SET MYPITCH TO 4.
    PRESERVE.
}.
// ***********************
// END TRIGGERS
// ***********************



// ***********************
// HELPER FUNCTIONS
// ***********************

// DEBUG is sometimes helpful =)
function log_message {
	parameter message.
	
	LOG KUNIVERSE:REALTIME + " - " + message TO boot.log.
}.

function get_bearing {
	// from https://www.movable-type.co.uk/scripts/latlong.html
	// Formula:	θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
	// where	φ1,λ1 is the start point, φ2,λ2 the end point (Δλ is the difference in longitude)
	parameter DSTLAT.
	parameter DSTLNG.
	
	SET SRCLAT TO SHIP:LATITUDE.
	SET DELTALNG TO DSTLNG - SHIP:LONGITUDE.
	
	SET MYBEARING TO ARCTAN2(SIN(DELTALNG) * COS(DSTLAT), COS(SRCLAT) * SIN(DSTLAT) - SIN(SRCLAT) * COS(DSTLAT) * COS(DELTALNG)).
	RETURN ROUND(MOD(MYBEARING + 360, 360),0).
}.

function get_distance {
	// from https://www.movable-type.co.uk/scripts/latlong.html
	// Law of cosines:	d = acos( sin φ1 ⋅ sin φ2 + cos φ1 ⋅ cos φ2 ⋅ cos Δλ ) ⋅ R
	parameter DSTLAT.
	parameter DSTLNG.
	
	SET SRCLAT TO SHIP:LATITUDE * constant:DegToRad.
	SET DSTLAT TO DSTLAT  * constant:DegToRad.
	SET DELTALNG TO (ABS(DSTLNG - SHIP:LONGITUDE) * constant:DegToRad).
	
	RETURN ARCCOS((SIN(SRCLAT) * SIN(DSTLAT)) + (COS(SRCLAT) * COS(DSTLAT) * COS(DELTALNG))) * SHIP:BODY:RADIUS / 1000.  // value in km
}.

function check_threshold {
	parameter metric.
	parameter tolerance.
	parameter target.
	
	IF metric * (1 + tolerance / 100) < target AND metric * (1 - tolerance / 100) > target {
		RETURN 1.  // within tolerance
	} ELSE IF metric * (1 + tolerance / 100) < target {
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
	IF SHIP:TYPE = "Plane" {
		PRINT "  TARGET ALTITUDE: " + MYALTITUDE AT (0,1).
	} ELSE {
		PRINT "  TARGET ORBIT:    " + MYORBIT AT (0,1).
	}.
	
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
		SET OLDSTAGE TO STAGE:NUMBER.
	}.
	
	SET ECTOTAL TO 0.
	SET ECCURR TO 0.
	SET MPTOTAL TO 0.
	SET MPCURR TO 0.
	SET SFTOTAL TO 0.
	SET SFCURR TO 0.
	SET LFTOTAL TO 0.
	SET LFCURR TO 0.
	SET OXTOTAL TO 0.
	SET OXCURR TO 0.
	
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
	
	PRINT "MISSION INFORMATION:" AT (0,11).
	PRINT "  SOI:           " + SHIP:BODY:NAME + "   CEILING: " + SHIP:BODY:ATM:HEIGHT AT (0,12).
	PRINT "  LAT/LNG (Deg): " + ROUND(SHIP:LATITUDE,4) + "/" + ROUND(SHIP:LONGITUDE,4) AT (0,13).
	PRINT "  LAT/LNG (Rad): " + ROUND(SHIP:LATITUDE*constant:DegToRad,4) + "/" + ROUND(SHIP:LONGITUDE*constant:DegToRad,4) AT (0,14).
	PRINT "  SEA ALTITUDE:  " + ROUND(SHIP:ALTITUDE,0) AT (0,15).
	PRINT "(" + 100 * ROUND(SHIP:BODY:ATM:ALTITUDEPRESSURE(SHIP:ALTITUDE),8) + " % ATM)" AT (30,15).
	PRINT "  APOAPSIS:      " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
	PRINT TTA + " seconds" AT (30,16).
	PRINT "  PERIAPSIS:     " + MYPERIAPSIS AT (0,17).
	PRINT ROUND(ETA:PERIAPSIS,0) + " seconds" AT (30,17).
	
	PRINT "SHIP DETAILS:" AT (0,19).
	PRINT "  TYPE:          " + SHIPTYPE AT (0,20).
	
	LIST RESOURCES IN resList.
	FOR res IN resList {
		IF res:NAME = "ELECTRICCHARGE" {
			SET ECCURR TO res:AMOUNT.
			SET ECTOTAL TO res:CAPACITY.
		} ELSE IF res:NAME = "LIQUIDFUEL" {
			SET LFCURR TO res:AMOUNT.
			SET LFTOTAL TO res:CAPACITY.			
		} ELSE IF res:NAME = "SOLIDFUEL" {
			SET SFCURR TO res:AMOUNT.
			SET SFTOTAL TO res:CAPACITY.
		} ELSE IF res:NAME = "OXIDIZER" {
			SET OXCURR TO res:AMOUNT.
			SET OXTOTAL TO res:CAPACITY.
		} ELSE IF res:NAME = "MONOPROPELLANT" {
			SET MPCURR TO res:AMOUNT.
			SET MPTOTAL TO res:CAPACITY.
		}.
	}.
	
	PRINT "POWER/FUEL SYSTEMS:" AT (0,22).
	PRINT "  SHIP MASS TONS:  " + ROUND(SHIP:MASS,2) AT (0,23).
	PRINT "  ELECTRIC CHARGE: " + ROUND(ECCURR,2) AT (0,24).
	IF ECTOTAL > 0 {
		PRINT ROUND((100*ECCURR)/ECTOTAL,2) + "% REMAINING" AT (30,24).
	}.
	PRINT "  MONOPROPELLANT:  " + ROUND(MPCURR,2) AT (0,25).
	IF MPTOTAL > 0 {
		PRINT ROUND((100*MPCURR)/MPTOTAL,2) + "% REMAINING" AT (30,25).
	}.
	PRINT "  STAGE:           " + STAGE:NUMBER AT (0,26).
	PRINT "    SOLID FUEL:    " + ROUND(STAGE:SOLIDFUEL,2) AT (0,27).
	PRINT SFUELPERC + "% REMAINING" AT (30,27).
	PRINT "    LIQUID FUEL:   " + ROUND(STAGE:LIQUIDFUEL,2) AT (0,28).
	PRINT LFUELPERC + "% REMAINING" AT (30,28).
	PRINT "    OXIDIZER:      " + ROUND(STAGE:OXIDIZER,2) AT (0,29).
	PRINT OFUELPERC + "% REMAINING" AT (30,29).
	
	IF MYWAYPOINTS:LENGTH > 0 {
		PRINT "TARGET WAYPOINT:  " + MYWAYPOINTS[WPIDX]:NAME AT (0,33).
		PRINT "TARGET LAT/LNG:   " + MYWAYPOINTS[WPIDX]:GEOPOSITION:LAT * constant:DegToRad + ", " + MYWAYPOINTS[WPIDX]:GEOPOSITION:LNG * constant:DegToRad AT (0,34).
		SET DIST TO ROUND(get_distance(MYWAYPOINTS[WPIDX]:GEOPOSITION:LAT, MYWAYPOINTS[WPIDX]:GEOPOSITION:LNG),3).
		PRINT "TARGET DISTANCE:  " + DIST + " km" AT (0,35).
		PRINT "ETA: " + ROUND((DIST*1000/SHIP:GROUNDSPEED)/60,2) + " minutes" AT (30,35).
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
	parameter MYCUSTOMHEADING.
	GLOBAL MYORBIT IS MYCUSTOMORBIT.
	GLOBAL MYHEADING IS MYCUSTOMHEADING.
	
	SET LAUNCHINPROGRESS TO 1.

	LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.
	SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
	LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER

	UNTIL SHIP:APOAPSIS > MYORBIT { // get apoapsis up to MYORBIT
	
		// from 0 to 10km we want to aggressively pitch down to 45 degrees.
		UNTIL SHIP:ALTITUDE > 10000 {
			SET MYPITCH TO 45 + ROUND(45*(10000 - SHIP:ALTITUDE) / 10000, 1).
			SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
			update_screen().
			WAIT 0.1.
		}.
		
		// from 10km to MYORBIT pitch the remaining way until 10 degrees.
		UNTIL SHIP:APOAPSIS > MYORBIT {
			SET MYPITCH TO ROUND(45*(MYORBIT - (SHIP:ALTITUDE - 10000) ) / MYORBIT, 1).
			SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
			update_screen().
			WAIT 0.1.
		}.
		update_screen().
		WAIT 0.1.
	}.
	LOCK THROTTLE TO 0.
	
	// create a maneuver node to circularize orbit.
	SET V_CUR TO SQRT(SHIP:BODY:MU * (2/(MYORBIT + SHIP:BODY:RADIUS) - 2/(SHIP:PERIAPSIS + MYORBIT + 2*SHIP:BODY:RADIUS))).
	SET V_NEW TO SQRT(SHIP:BODY:MU * (2/(MYORBIT + SHIP:BODY:RADIUS) - 2/(2*MYORBIT + 2*SHIP:BODY:RADIUS))).
	SET DV_PROGRADE TO V_NEW - V_CUR.
	SET X TO NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, DV_PROGRADE). // Time, Radial, Normal, Prograde
	ADD X.
	
	run execnode. // execute the node
	
	LOCK THROTTLE TO 0.0.
	update_screen().

	SET SASMODE TO "STABILITY". 
	SAS ON.
	RCS ON.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	
	SET LAUNCHINPROGRESS TO 0.
	
	// we're in orbit, let's do typical in-orbit stuff
	FOR f IN SHIP:MODULESNAMED("ModuleProceduralFairing") { f:DOEVENT("deploy"). }.
	WAIT 1.0.
	SET PANELS TO TRUE.
	
}.

function takeoff {
	parameter MYCUSTOMALTITUDE.
	
	GLOBAL MYALTITUDE IS MYCUSTOMALTITUDE.
	GLOBAL MYHEADING IS 90. // assuming takeoff from KSC
	GLOBAL MYPITCH IS 5.
	
	SET MYSTEER TO LOOKDIRUP(HEADING(MYHEADING,MYPITCH):FOREVECTOR,SHIP:UP:FOREVECTOR).
	LOCK STEERING TO MYSTEER.

	// for stability in takeoff.
	SAS ON.
	RCS OFF.

	LOCK THROTTLE TO 1.0.
	SET BRAKES TO FALSE.
	SET LIGHTS TO TRUE.
	STAGE.  // fire the engines!

	UNTIL SHIP:ALTITUDE > STARTALT + 10 {
		WAIT 1.
		update_screen().
	}.

	SAS OFF.
	RCS OFF.
	SET GEAR TO FALSE.

	UNTIL SHIP:ALTITUDE >= MYALTITUDE {
		UNTIL MYPITCH >= 25 {
			SET MYPITCH TO MYPITCH + 2.
			// control roll
			SET MYSTEER TO LOOKDIRUP(HEADING(MYHEADING,MYPITCH):FOREVECTOR,SHIP:UP:FOREVECTOR).
			WAIT 1.
		}.
		update_screen().
		WAIT 1.
	}.
	SET INFLIGHT TO 1.  // enable altitude hold triggers
	
	IF MYWAYPOINTS:LENGTH > 0 {
		SET WPIDX TO 0.
		FOR WAYPOINT IN MYWAYPOINTS {
			navigate_to(WAYPOINT:GEOPOSITION:LAT,WAYPOINT:GEOPOSITION:LNG).
			SET WPIDX TO WPIDX + 1.
			WAIT 1.
		}.
	}.
}.

function navigate_to {
	parameter LAT.
	parameter LNG.
	
	SET ERROR TO 3. // 3% allowable error
	
	until check_threshold(SHIP:LATITUDE,ERROR,LAT) = 1 AND check_threshold(SHIP:LONGITUDE,ERROR,LNG) = 1 { // until we're ERROR% within LAT/LNG
		SET DSTHEADING TO ROUND(get_bearing(LAT,LNG),2).
		
		IF DSTHEADING - MYHEADING > -1 AND DSTHEADING - MYHEADING < 1 {
			// pretty much on point here...
			SET MYHEADING TO ROUND(DSTHEADING,1).
		} ELSE IF ABS(DSTHEADING - MYHEADING) >= 180 {
			SET MYHEADING TO MYHEADING - 1.
			IF MYHEADING < 0 {
				SET MYHEADING TO 360.
			}.
		} ELSE IF ABS(DSTHEADING - MYHEADING) < 180 {
			IF DSTHEADING > MYHEADING {
				SET MYHEADING TO MYHEADING + 1.
			} ELSE {
				SET MYHEADING TO MYHEADING - 1.
			}.
		}.
		
		IF SHIP:TYPE = "Rover" {
			LOCK WHEELSTEERING TO MYHEADING.
		} ELSE {
			IF DSTHEADING - MYHEADING > -1 AND DSTHEADING - MYHEADING < 1 {
				SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
			} ELSE {
				// control roll
				SET MYSTEER TO LOOKDIRUP(HEADING(MYHEADING,MYPITCH):FOREVECTOR,SHIP:UP:FOREVECTOR).
			}.
		}.
		update_screen().
		WAIT 0.1.
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
	takeoff(MYALTITUDE).
} ELSE {
	// do ship stuff
	IF SHIP:BODY:NAME = "Kerbin" AND SHIP:ALTITUDE < 1000 {
		launch(MYORBIT,MYHEADING).
	}.
}.

