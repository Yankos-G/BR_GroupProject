
PROGRAM _INIT
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _CYCLIC
	(* Insert code here *)
	MpAlarmXCore_0.Enable := TRUE;
	MpAlarmXCore_0.MpLink := ADR(gAlarmXCore);
	MpAlarmXCore_0();
	
	MpAlarmXHistory_0.Enable := TRUE;
	MpAlarmXHistory_0.MpLink := ADR(gAlarmXHistory);
	MpAlarmXHistory_0();
	
	MpUserXConfig_0.Enable := TRUE;
	MpUserXConfig_0.Configuration := ADR(MpUserXConfigType_0);
	MpUserXConfig_0();
	
	redIconTimer.PT := T#500ms;
	redIconTimer();

	// HARDWARE ALARM DETECTION
	IF NOT ModuleOkActuators OR NOT ModuleOkEncoder OR NOT ModuleOkInverter OR NOT ModuleOkPLC_PLK OR NOT ModuleOkPneu_X67BC OR NOT ModuleOkScale THEN
		gAlarmHardware := TRUE;
	ELSE 
		gAlarmHardware := FALSE;
	END_IF;
	
	//isAcknowledged := MpAlarmXCheckState(gAlarmXCore, 'test_alarm', mpALARMX_STATE_ACKNOWLEDGED);
	IF (MpAlarmXCheckState(gAlarmXCore, 'Unrecognized object', mpALARMX_STATE_ACKNOWLEDGED) AND
		MpAlarmXCheckState(gAlarmXCore, 'Left box is full', mpALARMX_STATE_ACKNOWLEDGED) AND
		MpAlarmXCheckState(gAlarmXCore, 'Hardware error', mpALARMX_STATE_ACKNOWLEDGED) AND
		MpAlarmXCheckState(gAlarmXCore, 'Motor error', mpALARMX_STATE_ACKNOWLEDGED) AND
		MpAlarmXCheckState(gAlarmXCore, 'Right box is full', mpALARMX_STATE_ACKNOWLEDGED)) AND
		MpAlarmXCheckState(gAlarmXCore, 'Incorrect max left value', mpALARMX_STATE_ACKNOWLEDGED) AND
		MpAlarmXCheckState(gAlarmXCore, 'Incorrect min left value', mpALARMX_STATE_ACKNOWLEDGED) THEN
		isAcknowledged := TRUE;
	ELSE
		isAcknowledged := FALSE;
	END_IF;


	IF (MpAlarmXCore_0.PendingAlarms > 0) THEN
		pendingAlarms := TRUE;
	ELSE
		pendingAlarms := FALSE;
	END_IF;
	
	IF (MpAlarmXCore_0.ActiveAlarms = 0 AND MpAlarmXCore_0.PendingAlarms > 0) THEN
		enableYellowIcon := TRUE;
	ELSE
		enableYellowIcon := FALSE;
	END_IF;
	
	IF (MpAlarmXCore_0.ActiveAlarms > 0) THEN
		gAlarmExist := TRUE;
		IF (NOT(isAcknowledged)) THEN
			//blinking
			IF (redIconTimer.IN = FALSE) THEN
				redIconTimer.IN := TRUE;
			ELSIF (redIconTimer.Q) THEN
				timerCycle := NOT timerCycle;
				redIconTimer.IN := FALSE;
			END_IF;
			enableRedIcon := timerCycle;
		ELSE
			//static
			enableRedIcon := TRUE;
		END_IF;
	ELSE
		gAlarmExist := FALSE;
		enableRedIcon := FALSE;
	END_IF;
		
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

