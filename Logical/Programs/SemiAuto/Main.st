// ALREADY WORKING
PROGRAM _INIT
	// NEED ONLY FOR WATCH
	gAxis_1;
	gMotorBeltParType;
	gMotorBeltAxisBasic;
END_PROGRAM

PROGRAM _CYCLIC
	//CODE WORKS ONLY WHEN MANUAL MODE IS OFF	
	SemiAutoModeSelected := (gMode=2);
	IF  SemiAutoModeSelected THEN
		
		// MOTOR MANAGEMENT
		gMotorBeltAxisBasic.Enable 		:= TRUE;
		gMotorBeltAxisBasic.MpLink 		:= ADR(gAxis_1);
		gMotorBeltAxisBasic.Parameters 	:= ADR(gMotorBeltParType);
		MotorMoveDone 					:= gMotorBeltAxisBasic.MoveDone;
		gMotorBeltAxisBasic.Power 		:= MotorPower;
		gMotorBeltAxisBasic.Home 		:= MotorHome;
		
		gMotorBeltAxisBasic();
		
		// IN STATE STOP VALUES DOESN'T FLUCTUATE
		IF gMotorBeltAxisBasic.Velocity > 15 THEN
			MotorVel := gMotorBeltAxisBasic.Velocity;
		ELSE
			MotorVel := 0;
		END_IF;
		IF gMotorBeltAxisBasic.Position > 5 THEN
			MotorPos := gMotorBeltAxisBasic.Position;
		ELSE
			MotorPos := 0;
		END_IF;
		
		// ASSIGNING MOTION PARAMETERS
		gMotorBeltParType.Acceleration 	:= MotorReqAcc; 
		gMotorBeltParType.Deceleration 	:= MotorReqDec; 
		gMotorBeltParType.Velocity 		:= MotorReqVel;
		gMotorBeltParType.Position 		:= MotorReqPosition;
	
		// ASSIGNING GLOBAL VARIABLES TO LOCAL VARIABLES
		gActuatorByte					 := ActuatorByte;
		gMotorBeltAxisBasic.Power 		 := MotorPower;
		gMotorBeltAxisBasic.MoveAbsolute := MotorMoveAbsolute;
		gStopState 						 := (State = 0);
		
		// ASSIGNING LOCAL VARIABLES TO GLOBAL VARIABLES
		MotorInPosition 				 := gMotorBeltAxisBasic.InPosition;
		ItemWeight 						 := gInWeightMeasure;							 

		// ITEM DETECTION CONDITION 
		ItemDetected := (ItemWeight > 1);
		gWeightDetected := ItemDetected;
		
		// TIMERS
		// actuator
		TimerTonActuator(IN := TimerTonActuatorIn, PT := TIME_TON_ACTUATOR);
		TimerActuatorOut := TimerTonActuator.Q;
		// camera
		TimerTonCamera(IN := gProgCamera.ImageAcq , PT := TIME_TON_CAMERA);
		TimerCameraPicDone := TimerTonCamera.Q;
		// delay after detection
		TimerTonDetect.IN := ItemDetected;
		TimerTonDetect.PT := TIME_TON_DETECT;
		TimerAfterDetect := TimerTonDetect.Q;
		TimerTonDetect();
		// delay 
		TimerTONShowPhoto.IN := gProgCamera.ImageAcq;
		TimerTONShowPhoto.PT := TIME_TON_SHOW_PHOTO;
		ShowPhoto := TimerTONShowPhoto.Q;
		TimerTONShowPhoto();
		

		
	END_IF; 
		
	
	// ALARM OR STOP OR AUTO NOT ACTIVE
	IF	gAlarmHardware THEN	
		IF NOT (State = ERROR) THEN
			State := ERROR;
		END_IF;
	ELSIF Stop OR gMode <> 0 OR gAlarmExist THEN 
		Stop := FALSE;
		State := STOP;
	END_IF; 
	
	// PROGRAM AUTO
	CASE State OF
		STOP:
			State := STOP;
			IF SemiAutoModeSelected THEN
				MotorPower 		  := FALSE;
				MotorMoveAbsolute := FALSE;
				MotorHome 		  := FALSE;
			END_IF;		
			MotorPos := 0;
			MotorVel := 0;
			TimerTonActuatorIn 	  := FALSE;
			ActuatorSorting 	  := FALSE;
			ActuatorPushing  	  := FALSE;
			IF Start THEN
				State := INIT;
			END_IF;
			
		INIT:
			Sort_left			:= FALSE;
			Sort_right 			:= FALSE;
			gAddToRight 		:= FALSE;
			gAddToLeft 			:= FALSE;
			TimerTonActuatorIn 	:= FALSE;
			ActuatorSorting 	:= FALSE;
			ActuatorPushing 	:= FALSE;
			MotorMoveAbsolute 	:= FALSE;
			MotorPower 			:= TRUE;
			MotorHome 			:= TRUE;
			gPicNotRecognised	:= FALSE;
			State 				:= START;
			
		START: 
			IF ItemDetected AND Approval THEN
				ItemWeightMeasured 	:= RESET_ITEM_MEM_WEIGHT;
				State := DETECTION;
			END_IF;
			
		DETECTION:
			MotorHome 	:= FALSE;
			IF TimerAfterDetect THEN
				ItemWeightMeasured := ItemWeight;
				State := CATEGORIZATION;
			END_IF;
				
		CATEGORIZATION: 
			IF gSorting.SortChoice = WEIGHT THEN
				IF NOT gSorting.Threshold AND NOT (ItemWeightMeasured >= gSorting.ItemWeightLeftMin AND ItemWeightMeasured <= gSorting.ItemWeightLeftMax) AND NOT (ItemWeightMeasured >= gSorting.ItemWeightRightMin AND ItemWeightMeasured <= gSorting.ItemWeightRightMax) THEN
					State := UNRECOGNISED_PIC;//POTEM TO PRZENIES
				ELSE 
					State := CHOOSE_SORT_MODE;
				END_IF;
			ELSE
				State := TAKE_PICT_CAMERA;
			END_IF;
			
		TAKE_PICT_CAMERA:
			StringState := 'Robienie zdjecia';
			gProgCamera.ImageAcq 	:= TRUE;
			IF TimerCameraPicDone AND Approval THEN
				gProgCamera.DisplayPhoto := TRUE;
				StringState := 'Zdjecie zrobione';
				Approval := 0;
				IF gRecognisedModel = 0 THEN 						//0
					gProgCamera.ImageAcq 			  := FALSE;
					StringRecognisedModel := 'Unrecognised';
					State 				  := UNRECOGNISED_PIC;
				ELSE 
					State 				  := DROP;
				END_IF;
			END_IF;
				
		DROP:
			StringState := 'Dozowanie detalu';
			ActuatorPushing := TRUE;
			IF TimerActuatorOut THEN
				ActuatorPushing := FALSE;
				IF gSorting.SortChoice = OPTIC_LOGO OR gSorting.SortChoice = OPTIC_COLOR THEN
					gSortChoiceView := TRUE;
					State := SORT_OPTIC;
				ELSIF gSorting.SortChoice = WEIGHT THEN
					gSortChoiceView := FALSE;
					State := SORT_WEIGHT;
				END_IF;
			END_IF;
			
		// ABOVE 1 TO ItemWeightChoosen ITEM FALL INTO THE LEFT, EQUAL AND ABOVE ItemWeightChoosen INTO THE RIGHT	
		SORT_WEIGHT: 
			IF (ItemWeightMeasured >= gSorting.ItemWeightLeftMin AND ItemWeightMeasured < gSorting.ItemWeightLeftMax) AND NOT (ItemWeightMeasured >= gSorting.ItemWeightRightMin AND ItemWeightMeasured < gSorting.ItemWeightRightMax)  THEN
				IF gSorting.SortLeftMin THEN
					State := GO_STORAGE_LEFT;
				ELSE
					State := GO_STORAGE_RIGHT;
				END_IF;
			ELSIF (ItemWeightMeasured >= gSorting.ItemWeightRightMin AND ItemWeightMeasured < gSorting.ItemWeightRightMax) AND NOT (ItemWeightMeasured >= gSorting.ItemWeightLeftMin AND ItemWeightMeasured < gSorting.ItemWeightLeftMax) THEN 
				IF gSorting.SortLeftMin THEN
					State := GO_STORAGE_RIGHT;
				ELSE
					State := GO_STORAGE_LEFT;
				END_IF;
			ELSE
				State := ERROR;
				//ALARM
			END_IF;
			
		SORT_OPTIC:
			StringState := 'Sortowanie optyczne';
			IF gRecognisedModel = 1 THEN	
				gProgCamera.ImageAcq 			  := FALSE;
				StringRecognisedModel := 'B&R';					//1
				IF gSorting.SortLeftBR AND Approval THEN
					Approval := 0;
					State := GO_STORAGE_LEFT;
				ELSE
					IF Approval THEN
						Approval := 0;
						State := GO_STORAGE_RIGHT;
					END_IF;
				END_IF;
			
			ELSIF gRecognisedModel = 2 THEN						//2
				gProgCamera.ImageAcq 			  := FALSE;
				StringRecognisedModel := 'AS';
				IF gSorting.SortLeftBR AND Approval THEN
					Approval := 0;
					State := GO_STORAGE_RIGHT;
				ELSE
					IF Approval THEN
						Approval := 0;
						State := GO_STORAGE_LEFT;
					END_IF;
				END_IF;
			END_IF;
			
			
		GO_STORAGE_LEFT:
			StringState := 'Transport detalu do lewego zbiornika';
			MotorReqPosition := MOTOR_DIST_LEFT;
			MotorMoveAbsolute := TRUE;
			IF MotorInPosition AND MotorMoveDone AND Approval THEN
				Approval := 0;
				State := SORT_STORAGE_LEFT;
			END_IF;

		GO_STORAGE_RIGHT:
			StringState := 'Transport detalu do prawego zbiornika';
			MotorReqPosition  := MOTOR_DIST_RIGHT;
			MotorMoveAbsolute := TRUE;
			IF MotorInPosition AND MotorMoveDone AND Approval THEN
				Approval := 0;
				State := SORT_STORAGE_RIGHT;				
			END_IF;
			
		SORT_STORAGE_LEFT:
			StringState := 'Zepchniecie detalu z tasmy do zbiornika lewego';
			MotorMoveAbsolute := FALSE;
			ActuatorSorting   := TRUE;
			gAddToLeft 		  := TRUE;
			IF TimerActuatorOut THEN
				State := INIT;
			END_IF;

		SORT_STORAGE_RIGHT:
			gAddToRight := TRUE;
			MotorMoveAbsolute := FALSE;
			State := INIT;
		
		UNRECOGNISED_PIC:
			StringState := 'Nie rozpoznano zdjecia';
			gPicNotRecognised := TRUE; 
			State := STOP;
			
		ERROR:
			StringState := 'Wystapil blad';
			gErrorState := TRUE;
			IF gAlarmHardAck THEN
				IF NOT gAlarmHardware THEN
					gAlarmHardAck := FALSE;
					gErrorState := FALSE;
					State := STOP;
				END_IF;
			END_IF;
		
	END_CASE;

	
	// TIMER INPUT TRIGGER TO DELAY ACTUATORS
	IF ActuatorPushing OR ActuatorSorting THEN
		TimerTonActuatorIn := TRUE;
	ELSE
		TimerTonActuatorIn := FALSE;
	END_IF;
	
	// OPERATION OF BYTE ACTUATORS WITH TIMER
	IF ActuatorPushing THEN
		ActuatorByte := ACTUATOR_BYTE_PUSH;	
		IF TimerActuatorOut THEN
			ActuatorPushing := FALSE;
		END_IF;
	ELSIF ActuatorSorting THEN
		ActuatorByte := ACTUATOR_BYTE_SORT;
		IF TimerActuatorOut THEN
			ActuatorSorting := FALSE;
		END_IF;
	ELSE
		ActuatorByte := ACTUATOR_BYTE_NOT_ACTIV;
	END_IF;
	
	// HMI GUYS WANTED SOME VARIABLES
	IF gSorting.SortChoice = OPTIC_LOGO OR gSorting.SortChoice = OPTIC_COLOR THEN
		gSortChoiceView := TRUE;
	ELSIF gSorting.SortChoice = WEIGHT THEN
		gSortChoiceView := FALSE;
	END_IF;
	
	ActuatorNotSorting := NOT ActuatorSorting;
	ActuatorNotPushing 	:= NOT ActuatorPushing;
	
	IF Start THEN
		Start := FALSE;
	END_IF;
	
	//Added by Jakub; Responsibler for changing machine state between English and Polish
	IF IsEnglishSelected THEN
		IF StringState = 'Inicjalizacja' THEN
			StringState := 'Initialization';
			
		ELSIF StringState = 'Zdjecie zrobione' THEN
			StringState := 'Picture taken';
			
		ELSIF StringState = 'Gotowy do startu' THEN
			StringState := 'Ready';
		
		ELSIF StringState = 'Wykrycie detalu' THEN
			StringState := 'Item detection';
			
		ELSIF StringState = 'Kategoryzacja detalu' THEN
			StringState := 'Item categorization';
			
		ELSIF StringState = 'Robienie zdjecia' THEN
			StringState := 'Taking a picture';
			
		ELSIF StringState = 'Dozowanie detalu' THEN
			StringState := 'Item dosing';
			
		ELSIF StringState = 'Sortowanie wagowe' THEN
			StringState := 'Sorting by weight';
			
		ELSIF StringState = 'Sortowanie optyczne' THEN
			StringState := 'Optical sorting';
			
		ELSIF StringState = 'Transport detalu do lewego zbiornika' THEN
			StringState := 'Item transport to the left tank';
			
		ELSIF StringState = 'Transport detalu do prawego zbiornika' THEN
			StringState := 'Item transport to the right tank';
			
		ELSIF StringState = 'Zepchniecie detalu z tasmy do zbiornika lewego' THEN
			StringState := 'Pushing the item from the belt to the left tank';
			
		ELSIF StringState = 'Nie rozpoznano zdjecia' THEN
			StringState := 'Photo not recognized';
			
		ELSIF StringState = 'Stop' THEN
			StringState := 'Stop';
			
		ELSIF StringState = 'Wystapil blad' THEN
			StringState := 'Error';
			
		ELSIF StringState = 'Gotowy do startu' THEN
			StringState := 'Ready to start';
		END_IF;
	END_IF;
	
		END_PROGRAM

PROGRAM _EXIT

	 
		END_PROGRAM

