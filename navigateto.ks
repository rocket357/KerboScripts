GLOBAL MYSTATUS IS "PREFLIGHT".
GLOBAL MYHEADING IS 90. // NORTH = 0, EAST = 90, SOUTH = etc...
GLOBAL STARTALT IS SHIP:ALTITUDE. // initial/starting altitude
GLOBAL MYALTITUDE IS 4000. // TARGET ALTITUDE IN METERS
GLOBAL MYPITCH IS 2. // PITCH ABOVE/BELOW HORIZON.  90 is VERTICAL UP, -90 IS VERTICAL DOWN

WHEN SHIP:ALTITUDE > (MYALTITUDE * 1.10) THEN {
	SET MYPITCH TO -2.
    PRESERVE.
}.

WHEN SHIP:ALTITUDE < (MYALTITUDE * 0.90) AND SHIP:ALTITUDE > (MYALTITUDE * 0.80) THEN {
	SET MYPITCH TO 2.
    PRESERVE.
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
	RETURN MOD(MYBEARING + 360, 360).
}.

function check_threshold {
	parameter metric.
	parameter tolerance.
	parameter target.
	
	// DEBUG
	//PRINT "check_threshold: " + metric + " " + tolerance + " " + target AT (10,3).
	
	IF metric * (1 + tolerance / 100) < target AND metric * (1 - tolerance / 100) > target {
		RETURN 1.  // within tolerance
	} ELSE IF metric * (1 + tolerance / 100) < target {
		RETURN -1.  // below threshold
	} ELSE {
		RETURN 2.  // over threshold
	}.
}.

function navigate_to {
	parameter LAT.
	parameter LNG.
	
	SET ERROR TO 5. // 5% allowable error
	
	until check_threshold(SHIP:LATITUDE,ERROR,LAT) = 1 AND check_threshold(SHIP:LONGITUDE,ERROR,LNG) = 1 { // until we're ERROR% within LAT/LNG
		SET DSTHEADING TO ROUND(get_bearing(LAT,LNG),2).
		
		IF MYHEADING > DSTHEADING +1 {
			SET MYHEADING TO MYHEADING - 1.
		} ELSE IF MYHEADING < DSTHEADING - 1 {
			SET MYHEADING TO MYHEADING + 1.
		} ELSE {
			SET MYHEADING TO ROUND(DSTHEADING,1).
		}.
		
		SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
		update_screen().
		WAIT 0.1.
	}.
}.

function update_screen {
	CLEARSCREEN.
	
	//PRINT "GEOPOSITION: " + SHIP:GEOPOSITION AT (0,0).
	PRINT "BODY:        " + SHIP:BODY AT (0,1).
	PRINT "FACING:      " + SHIP:FACING AT (0,2).
	PRINT "LATITUDE:    " + SHIP:LATITUDE AT (0,3).
	PRINT "LONGITUDE:   " + SHIP:LONGITUDE AT (0,4).
	
	PRINT "STATUS:      " + SHIP:STATUS AT (0,11).
	PRINT "THROTTLE:    " + ROUND(THROTTLE * 100,0) + " % " AT (0,12).
	PRINT "HEADING:     " + MYHEADING at (0,13).
    PRINT "PITCH:       " + MYPITCH + " degrees" AT(0,14).
	
	PRINT "ALTITUDE:    " + ROUND(SHIP:ALTITUDE,0) AT (0,16).
	PRINT "CALCULATED BEARING:  " + ROUND(get_bearing(40,0),2) AT (0,17).
}.

update_screen().



SET MYSTEER TO HEADING(MYHEADING,MYPITCH).
LOCK STEERING TO MYSTEER.

CLEARSCREEN.

SAS OFF.
RCS OFF.

navigate_to(40,0).
