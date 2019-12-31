function update_screen {
	IF SHIP:PERIAPSIS < 70000 { // assuming Kerbin!
		SET MYPERIAPSIS TO "Sub-orbital flight.".
	} ELSE {
		SET MYPERIAPSIS TO ROUND(SHIP:PERIAPSIS,0).
	}.
	CLEARSCREEN.
	
	PRINT "MISSION:" AT (0,0).
	PRINT "  TARGET ORBIT: UNSET" AT (0,1).
	PRINT "  STATUS:       " + SHIP:STATUS AT (0,2).
	PRINT "  DEBUG: OFF" AT (0,3).
	
	PRINT "NAVIGATION SETTINGS:" AT (0,6).
	PRINT "  THROTTLE:     " + ROUND(THROTTLE * 100,0) + " % " AT (0,7).
	PRINT "  HEADING:      " + SHIP:HEADING AT (0,8).
  PRINT "  PITCH:        " + SHIP:CONTROL:PITCH + " degrees" AT (0,9).
	PRINT "  YAW:          " + SHIP:CONTROL:YAW AT (0,10).
	PRINT "  ROLL:         " + SHIP:CONTROL:ROLL AT (0,11).
	
	PRINT "POSITION:" AT (0,15).
	PRINT "  ALTITUDE:     " + ROUND(SHIP:ALTITUDE,0) AT (0,16).
  PRINT "  APOAPSIS:     " + ROUND(SHIP:APOAPSIS,0) AT (0,17).
	PRINT "  PERIAPSIS:    " + MYPERIAPSIS AT (0,18).
	
	PRINT "FUEL SYSTEM:" AT (0,20).
	PRINT "  STAGE:        " + STAGE:NUMBER AT (0,21).
	PRINT "  SHIP MASS:    " + SHIP:MASS AT (0,22).
	PRINT "  SOLID FUEL:   " + STAGE:SOLIDFUEL AT (0,23).
	PRINT "  LIQUID FUEL:  " + STAGE:LIQUIDFUEL AT (0,24).
	PRINT "  OXIDIZER:     " + STAGE:OXIDIZER AT (0,25).
}.

UNTIL 1 < 0 {
	WAIT 1.
	update_screen().
}.
