PROGRAM _INIT

END_PROGRAM

PROGRAM _CYCLIC
	SelectedAuto := (gMode = 0);
	NotSelectedAuto := NOT SelectedAuto;
	SemiAutoModeSelected := (gMode=2);
	// CODE WORKS ONLY WHEN AUTO OR SEMIAUTO IS ACTIVE
	IF  SelectedAuto OR SemiAutoModeSelected THEN
				
		// MOTOR MANAGEMENT	
		gMotorBeltAxisBasic.Enable 		:= TRUE;
		gMotorBeltAxisBasic.MpLink 		:= ADR(gAxis_1);
		gMotorBeltAxisBasic.Parameters 	:= ADR(gMotorBeltParType);
		MotorMoveDone 					:= gMotorBeltAxisBasic.MoveDone;
		gMotorBeltAxisBasic.Power 		:= MotorPower;
		gMotorBeltAxisBasic.Home 		:= MotorHome;
		gMotorBeltAxisBasic();
		
		// STORAGES OVER LIMIT ACTION
		IF gQuantityLeftStorage >= gMaxLeftStorage THEN
			LeftLimit := TRUE;
		ELSIF gQuantityLeftStorage < gMaxLeftStorage THEN
			LeftLimit := FALSE;
		END_IF;
		IF gQuantityRightStorage >= gMaxRightStorage THEN
			RightLimit := TRUE;
		ELSIF gQuantityRightStorage < gMaxRightStorage THEN
			RightLimit := FALSE;
		END_IF;
		
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
		// delay after photo
		TimerTONShowPhoto.IN := gProgCamera.ImageAcq;
		TimerTONShowPhoto.PT := TIME_TON_SHOW_PHOTO;
		ShowPhoto := TimerTONShowPhoto.Q;
		TimerTONShowPhoto();
		// timer too long detection
		// delay after photo
		TON_TooLongDetect.IN := TooLongDetect;
		TON_TooLongDetect.PT := TIME_TON_HOW_LONG_DETECT;
		TimerTooLongDetect := TON_TooLongDetect.Q;
		TON_TooLongDetect();
		
	END_IF; 
		
	// ALARM OR STOP OR AUTO NOT ACTIVE
	IF gAlarmHardware THEN	
		IF NOT (State = ERROR) THEN
			State := ERROR;
		END_IF;
	ELSIF Stop OR gMode = 1 OR gAlarmExist THEN 
		Stop := FALSE;
		State := STOP;
	END_IF; 
	
	// PROGRAM AUTO
	CASE State OF

		STOP:
			State := STOP;
			IF SelectedAuto OR SemiAutoModeSelected THEN
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
			Approval 			:= FALSE;
			Detect 				:= FALSE;
			State 				:= START;
			
		START: 
			Approval := FALSE;
			IF ItemDetected THEN
				ItemWeightMeasured 	:= RESET_ITEM_MEM_WEIGHT;
				gRecognisedModel := 0; // NOWE W KODZIE 
				State := DETECTION;
			END_IF;
			
		DETECTION:
			MotorHome 	:= FALSE;
			Approval := FALSE;
			TooLongDetect := TRUE;
			IF TimerAfterDetect THEN
				Detect := TRUE;
				ItemWeightMeasured := ItemWeight;
				State := CATEGORIZATION;
			ELSIF TimerTooLongDetect THEN
				TooLongDetect := FALSE;
				State := START;
			END_IF;
		
			
		CATEGORIZATION:
			IF SelectedAuto THEN
				IF gSorting.SortChoice = WEIGHT THEN
					State := CHOOSE_SORT_MODE;
				ELSE
					State := TAKE_PICT_CAMERA;
				END_IF;
			ELSIF SemiAutoModeSelected AND Approval THEN
				IF gSorting.SortChoice = WEIGHT THEN
					Approval := FALSE;
					State := CHOOSE_SORT_MODE;
				ELSE
					Approval := FALSE;
					State := TAKE_PICT_CAMERA;
				END_IF;
			END_IF;
			
		TAKE_PICT_CAMERA:
			gProgCamera.ImageAcq 	:= TRUE;
			State := TAKE_PICT_CAMERA_2;

		TAKE_PICT_CAMERA_2:
			IF SelectedAuto THEN
				IF NOT gProgCamera.ImageProcessingActive AND TimerCameraPicDone THEN
					gProgCamera.DisplayPhoto := TRUE;
					IF gPhotoShowed THEN
						gPhotoShowed := FALSE;
						IF gRecognisedModel = 0 THEN 						
							gProgCamera.ImageAcq  := FALSE;
							State 				  := UNRECOGNISED_PIC;
						ELSE 
							State 				  := CHOOSE_SORT_MODE;
						END_IF;
					END_IF;
				END_IF;	
			ELSIF SemiAutoModeSelected THEN
				IF NOT gProgCamera.ImageProcessingActive AND TimerCameraPicDone THEN
					gProgCamera.DisplayPhoto := TRUE;
					IF gPhotoShowed AND Approval THEN
						gPhotoShowed := FALSE;
						IF gRecognisedModel = 0 THEN 						
							gProgCamera.ImageAcq  := FALSE;
							Approval := FALSE;
							State 				  := UNRECOGNISED_PIC;
						ELSE 
							Approval := FALSE;
							State 				  := CHOOSE_SORT_MODE;
						END_IF;
					END_IF;
				END_IF;
			END_IF;
			
		CHOOSE_SORT_MODE:
			IF gSorting.SortChoice = OPTIC_LOGO THEN
				State := SORT_OPTIC_LOGO;
			ELSIF gSorting.SortChoice = OPTIC_COLOR THEN
				State := SORT_OPTIC_COLOR; 
			ELSIF gSorting.SortChoice = WEIGHT THEN
				State := SORT_WEIGHT;
			ELSIF gSorting.SortChoice = ADVANCED THEN
				State := SORT_ADVANCED;
			END_IF;
			
			//LONG IF TO PREVENT PROGRAMO KAPUTO
		SORT_WEIGHT:
			IF NOT gSorting.Threshold THEN
				IF (ItemWeightMeasured >= gSorting.ItemWeightLeftMin AND ItemWeightMeasured <= gSorting.ItemWeightLeftMax) AND NOT (ItemWeightMeasured >= gSorting.ItemWeightRightMin AND ItemWeightMeasured <= gSorting.ItemWeightRightMax)  THEN
					IF gSorting.SortLeftMin THEN
						Sort_left := TRUE;
						State := DROP;
					ELSE 
						Sort_right := TRUE;
						State := DROP;
					END_IF;
				ELSIF (ItemWeightMeasured >= gSorting.ItemWeightRightMin AND ItemWeightMeasured <= gSorting.ItemWeightRightMax) AND NOT (ItemWeightMeasured >= gSorting.ItemWeightLeftMin AND ItemWeightMeasured <= gSorting.ItemWeightLeftMax) THEN 
					IF gSorting.SortLeftMin THEN
						Sort_right := TRUE;
						State := DROP;
					ELSE 
						Sort_left := TRUE;
						State := DROP;
					END_IF;
				ELSE 
					State := UNRECOGNISED_PIC;
				END_IF;
			ELSE
				IF ItemWeightMeasured < gSorting.ItemWeightBorderWeight THEN
					IF gSorting.SortLeftMin THEN
						Sort_left := TRUE;
						State := DROP;
					ELSE
						Sort_right := TRUE;
						State := DROP;
					END_IF;
				ELSIF ItemWeightMeasured >= gSorting.ItemWeightBorderWeight THEN 
					IF gSorting.SortLeftMin THEN
						Sort_right := TRUE;
						State := DROP;
					ELSE
						Sort_left := TRUE;
						State := DROP;
					END_IF;
				END_IF;
			END_IF;
			
		SORT_OPTIC_LOGO:
			IF gRecognisedModel = 1 THEN	
				gProgCamera.ImageAcq 			  := FALSE;					//1
				IF gSorting.SortLeftBR THEN
					Sort_left := TRUE;
					State := DROP;
				ELSE
					Sort_right := TRUE;
					State := DROP;
				END_IF;
			ELSIF gRecognisedModel = 2 THEN						
				gProgCamera.ImageAcq 			  := FALSE;						//2
				IF gSorting.SortLeftBR THEN
					Sort_right := TRUE;
					State := DROP;
				ELSE
					Sort_left := TRUE;
					State := DROP;
				END_IF;
			END_IF;
			
		SORT_OPTIC_COLOR:
			IF gRecognisedModel = 1 THEN	
				gProgCamera.ImageAcq 			  := FALSE;						//1
				IF gSorting.SortLeftGrey THEN
					Sort_left := TRUE;
					State := DROP;
				ELSE
					Sort_right := TRUE;
					State := DROP;
				END_IF;
			ELSIF gRecognisedModel = 2 THEN						
				gProgCamera.ImageAcq 			  := FALSE;					//2
				IF gSorting.SortLeftGrey THEN
					Sort_right := TRUE;
					State := DROP;
				ELSE
					Sort_left := TRUE;
					State := DROP;
				END_IF;
			END_IF;
				
		SORT_ADVANCED:
			gProgCamera.ImageAcq  := FALSE;
			CASE State_ADV OF
				WAIT:
					IF gSorting.LeftCriteria.AS OR gSorting.LeftCriteria.BR OR gSorting.RightCriteria.AS OR gSorting.RightCriteria.BR THEN
						State_ADV := LOGO;
					ELSIF gSorting.LeftCriteria.Grey OR gSorting.LeftCriteria.Orange OR gSorting.RightCriteria.Grey OR gSorting.RightCriteria.Orange THEN
						State_ADV := COLOR;
					ELSIF (((gSorting.LeftCriteria.Heavy OR gSorting.LeftCriteria.Light) AND (gSorting.LeftCriteria.Threshold OR gSorting.LeftCriteria.Range)) OR ((gSorting.RightCriteria.Heavy OR gSorting.RightCriteria.Light) AND (gSorting.RightCriteria.Threshold OR gSorting.RightCriteria.Range))) THEN
						State_ADV := ADV_WEIGHT;
					ELSE 
						State := UNRECOGNISED_PIC;
					END_IF;
					
				LOGO:
					//--------------------LEFT----------------------
					IF gSorting.LeftCriteria.BR AND gRecognisedModel = 1 THEN
						IF gSorting.LeftCriteria.Threshold THEN
							State_ADV := THRESHOLD_LEFT;
						ELSIF gSorting.LeftCriteria.Range THEN
							State_ADV := RANGE_LEFT;
						ELSE
							Sort_left := TRUE;
							State := DROP;
						END_IF;
					ELSIF gSorting.LeftCriteria.AS AND gRecognisedModel = 2 THEN
						IF gSorting.LeftCriteria.Threshold THEN
							State_ADV := THRESHOLD_LEFT;
						ELSIF gSorting.LeftCriteria.Range THEN
							State_ADV := RANGE_LEFT;
						ELSE
							Sort_left := TRUE;
							State := DROP;
						END_IF;
						//--------------------RIGHT----------------------
					ELSIF gSorting.RightCriteria.BR AND gRecognisedModel = 1 THEN
						IF gSorting.RightCriteria.Threshold THEN
							State_ADV := THRESHOLD_RIGHT;
						ELSIF gSorting.RightCriteria.Range THEN
							State_ADV := RANGE_RIGHT;
						ELSE
							Sort_right := TRUE;
							State := DROP;
						END_IF;
					ELSIF gSorting.RightCriteria.AS AND gRecognisedModel = 2 THEN
						IF gSorting.RightCriteria.Threshold THEN
							State_ADV := THRESHOLD_RIGHT;
						ELSIF gSorting.RightCriteria.Range THEN
							State_ADV := RANGE_RIGHT;
						ELSE
							Sort_right := TRUE;
							State := DROP;
						END_IF;
					ELSE 
						State := UNRECOGNISED_PIC;
					END_IF;
					
				COLOR:
					//--------------------LEFT----------------------
					IF gSorting.LeftCriteria.Grey AND gRecognisedModel = 1 THEN
						IF gSorting.LeftCriteria.Threshold THEN
							State_ADV := THRESHOLD_LEFT;
						ELSIF gSorting.LeftCriteria.Range THEN
							State_ADV := RANGE_LEFT;
						ELSE
							Sort_left := TRUE;
							State := DROP;
						END_IF;
					ELSIF gSorting.LeftCriteria.Orange AND gRecognisedModel = 2 THEN
						IF gSorting.LeftCriteria.Threshold THEN
							State_ADV := THRESHOLD_LEFT;
						ELSIF gSorting.LeftCriteria.Range THEN
							State_ADV := RANGE_LEFT;
						ELSE
							Sort_left := TRUE;
							State := DROP;
						END_IF;
						//--------------------RIGHT----------------------
					ELSIF gSorting.RightCriteria.Grey AND gRecognisedModel = 1 THEN
						IF gSorting.RightCriteria.Threshold THEN
							State_ADV := THRESHOLD_RIGHT;
						ELSIF gSorting.RightCriteria.Range THEN
							State_ADV := RANGE_RIGHT;
						ELSE
							Sort_right := TRUE;
							State := DROP;
						END_IF;
					ELSIF gSorting.RightCriteria.Orange AND gRecognisedModel = 2 THEN
						IF gSorting.RightCriteria.Threshold THEN
							State_ADV := THRESHOLD_RIGHT;
						ELSIF gSorting.RightCriteria.Range THEN
							State_ADV := RANGE_RIGHT;
						ELSE
							Sort_right := TRUE;
							State := DROP;
						END_IF;
					ELSE 
						State := UNRECOGNISED_PIC;
					END_IF;
					
				ADV_WEIGHT:
					IF gSorting.RightCriteria.Threshold THEN
						State_ADV := THRESHOLD_RIGHT;
					ELSIF gSorting.RightCriteria.Range THEN
						State_ADV := RANGE_RIGHT;
					ELSIF gSorting.LeftCriteria.Threshold THEN
						State_ADV := THRESHOLD_LEFT;
					ELSIF gSorting.LeftCriteria.Range THEN
						State_ADV := RANGE_LEFT;	
					END_IF;
					
				THRESHOLD_LEFT:
					IF ItemWeightMeasured < gSorting.LeftCriteria.WeightBorder THEN
						IF gSorting.LeftCriteria.Light THEN
							Sort_left := TRUE;
							State := DROP;
						ELSE 
							State := UNRECOGNISED_PIC;
						END_IF;
					ELSIF ItemWeightMeasured >= gSorting.LeftCriteria.WeightBorder THEN 
						IF gSorting.LeftCriteria.Heavy THEN
							Sort_left := TRUE;
							State := DROP;
						ELSE 
							State := UNRECOGNISED_PIC;
						END_IF;
					END_IF;
				
				THRESHOLD_RIGHT:
					IF ItemWeightMeasured < gSorting.RightCriteria.WeightBorder THEN
						IF gSorting.RightCriteria.Light THEN
							Sort_right := TRUE;
							State := DROP;
						ELSE 
							State := UNRECOGNISED_PIC;
						END_IF;
					ELSIF ItemWeightMeasured >= gSorting.RightCriteria.WeightBorder THEN 
						IF gSorting.RightCriteria.Heavy THEN
							Sort_right := TRUE;
							State := DROP;
						ELSE 
							State := UNRECOGNISED_PIC;
						END_IF;
					END_IF;	
					
				RANGE_LEFT:
					IF (ItemWeightMeasured >= gSorting.LeftCriteria.WeightMin AND ItemWeightMeasured <= gSorting.LeftCriteria.WeightMax) THEN
						Sort_left := TRUE;
						State := DROP;
					ELSE
						State := UNRECOGNISED_PIC;
					END_IF;
			
				RANGE_RIGHT:
					IF (ItemWeightMeasured >= gSorting.RightCriteria.WeightMin AND ItemWeightMeasured <= gSorting.LeftCriteria.WeightMax) THEN 
						Sort_right := TRUE;
						State := DROP;
					ELSE
						State := UNRECOGNISED_PIC;
					END_IF;
				
			END_CASE;
		
		DROP:
			IF (Sort_left AND LeftLimit) THEN
				AlarmLeft := TRUE;
			ELSIF (Sort_right AND RightLimit) THEN
				AlarmRight := TRUE;
			ELSE
				State_ADV := WAIT;
				ActuatorPushing := TRUE;
				IF SelectedAuto THEN
					IF TimerActuatorOut THEN
						ActuatorPushing := FALSE;
						State := DECIDE_WHERE;
					END_IF;
				ELSIF SemiAutoModeSelected THEN
					IF TimerActuatorOut AND Approval THEN
						ActuatorPushing := FALSE;
						Approval := FALSE;
						State := DECIDE_WHERE;
					END_IF;
				END_IF;
			END_IF;
			
		DECIDE_WHERE:
			IF Sort_left THEN
				Sort_left := FALSE;
				State := GO_STORAGE_LEFT;
			ELSIF Sort_right THEN
				Sort_right := FALSE;
				State := GO_STORAGE_RIGHT;
			ELSE
				State := UNRECOGNISED_PIC;
			END_IF;
			
		GO_STORAGE_LEFT:
			IF SelectedAuto THEN
				MotorReqPosition := MOTOR_DIST_LEFT;
				MotorMoveAbsolute := TRUE;
				IF MotorInPosition AND MotorMoveDone THEN
					State := SORT_STORAGE_LEFT;
				END_IF;
			ELSIF SemiAutoModeSelected AND Approval THEN		
				MotorReqPosition := MOTOR_DIST_LEFT;
				MotorMoveAbsolute := TRUE;
				IF MotorInPosition AND MotorMoveDone THEN
					Approval := FALSE;
					State := SORT_STORAGE_LEFT;
				END_IF;
			END_IF;
			
		GO_STORAGE_RIGHT:
			IF SelectedAuto THEN
				MotorReqPosition  := MOTOR_DIST_RIGHT;
				MotorMoveAbsolute := TRUE;
				IF MotorInPosition AND MotorMoveDone THEN
					State := SORT_STORAGE_RIGHT;				
				END_IF;
			ELSIF SemiAutoModeSelected AND Approval THEN
				MotorReqPosition  := MOTOR_DIST_RIGHT;
				MotorMoveAbsolute := TRUE;
				IF MotorInPosition AND MotorMoveDone THEN
					Approval := FALSE;
					State := SORT_STORAGE_RIGHT;				
				END_IF;
			END_IF;
			
		SORT_STORAGE_LEFT:
			IF SelectedAuto THEN
				MotorMoveAbsolute := FALSE;
				ActuatorSorting   := TRUE;
				gAddToLeft 		  := TRUE;
				IF TimerActuatorOut THEN
					State := INIT;
				END_IF;
			ELSIF SemiAutoModeSelected THEN
				MotorMoveAbsolute := FALSE;
				IF TimerActuatorOut AND Approval THEN
					Approval := FALSE;
					State := INIT;
				END_IF;
				IF Approval THEN
					ActuatorSorting   := TRUE;
					gAddToLeft 		  := TRUE;
					Approval 		  := FALSE;
				END_IF;
			END_IF;
		
		SORT_STORAGE_RIGHT:
			IF SelectedAuto THEN
				gAddToRight := TRUE;
				MotorMoveAbsolute := FALSE;
				State := INIT;
			ELSIF SemiAutoModeSelected AND Approval THEN
				Approval := FALSE;
				gAddToRight := TRUE;
				MotorMoveAbsolute := FALSE;
				State := INIT;
			END_IF;

		UNRECOGNISED_PIC:
			State_ADV := WAIT;
			gPicNotRecognised := TRUE; 
			State := STOP;
			
		ERROR: 
				MotorPower 		  := FALSE;
				MotorMoveAbsolute := FALSE;
				MotorHome 		  := FALSE;
				MotorPos := 0;
			MotorVel := 0;
			TimerTonActuatorIn 	  := FALSE;
			ActuatorSorting 	  := FALSE;
			ActuatorPushing  	  := FALSE;
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
		IF SelectedAuto THEN
			IF TimerActuatorOut THEN
				ActuatorPushing := FALSE;
			END_IF;
		ELSIF SemiAutoModeSelected THEN
			IF TimerActuatorOut AND Approval THEN
				Approval := FALSE;
				ActuatorPushing := FALSE;
			END_IF;
		END_IF;
	ELSIF ActuatorSorting THEN
		ActuatorByte := ACTUATOR_BYTE_SORT;
		IF SelectedAuto THEN
			IF TimerActuatorOut THEN
				ActuatorSorting := FALSE;
			END_IF;
		ELSIF SemiAutoModeSelected THEN
			IF TimerActuatorOut AND Approval  THEN
				Approval := FALSE;
				ActuatorSorting := FALSE;
			END_IF;
		END_IF;
	ELSE
		ActuatorByte := ACTUATOR_BYTE_NOT_ACTIV; 
	END_IF;
	
	// COUNTERS
	gCTU_QuantityLeft(CU := gAddToLeft, RESET := gCTU_Reset_Left, PV := gMaxLeftStorage);
	gCTU_QuantityRight(CU := gAddToRight, RESET := gCTU_Reset_Right, PV := gMaxRightStorage);
	gQuantityLeftStorage  := gCTU_QuantityLeft.CV;
	gQuantityRightStorage := gCTU_QuantityRight.CV;
	
	gCTU_QuantityLeft();
	gCTU_QuantityRight();
	
	IF gCTU_Reset_Left THEN
		AlarmLeft := FALSE;
	END_IF;
	IF gCTU_Reset_Right THEN
		AlarmRight := FALSE;
	END_IF;
	
	
	// HMI GUYS WANTED SOME VARIABLES
	IF gSorting.SortChoice <> WEIGHT THEN
		gSortChoiceView := TRUE;
		IF gSorting.SortChoice = ADVANCED THEN
			ShowDetectedLabel := FALSE;
		ELSE
			ShowDetectedLabel := TRUE;
		END_IF;
		ShowLightLeft 	:= FALSE;
		ShowLightRight 	:= FALSE;
		ShowRange 		:= FALSE;
		ShowThreshold 	:= FALSE;
		IF gSorting.SortLeftBR THEN
			ShowBRLeft	:= TRUE;
			ShowBRRight := FALSE;
		ELSE
			ShowBRRight := TRUE;
			ShowBRLeft 	:= FALSE;
		END_IF;	
	ELSIF gSorting.SortChoice = WEIGHT THEN
		ShowDetectedLabel := FALSE;
		gSortChoiceView := FALSE;
		ShowBRLeft 		:= FALSE;
		ShowBRRight 	:= FALSE;
		IF gSorting.Threshold THEN
			ShowRange 		:= FALSE;
			ShowThreshold := TRUE;
		ELSE
			ShowRange := TRUE;
			ShowThreshold := FALSE;
		END_IF;
		
		IF gSorting.SortLeftMin THEN
			ShowLightLeft := TRUE;
			ShowLightRight := FALSE;
		ELSE
			ShowLightRight := TRUE;
			ShowLightLeft := FALSE;
		END_IF;
	END_IF;
	
	SortLeftMin_USINT := BOOL_TO_USINT(gSorting.SortLeftMin);
	SortLeftBR_USINT := BOOL_TO_USINT(gSorting.SortLeftBR); 
	SortLeftGrey_USINT := BOOL_TO_USINT(gSorting.SortLeftGrey);
	
	//OPC UA - Threshold
	ItemWeighRightMinBorder := gSorting.ItemWeightLeftMax + 1;
	ItemWeighLeftMaxBorder := gSorting.ItemWeightRightMin - 1;	
	
	ActuatorNotSorting := NOT ActuatorSorting;
	ActuatorNotPushing 	:= NOT ActuatorPushing;
	
	IF Start THEN
		Start := FALSE;
	END_IF;	
	
	//SERVICE PAGE
	//SCALE WEIGHT RESET
	IF HMI_ScaleTare THEN
		ScaleTare := 2#1000;
	ELSE
		ScaleTare := 2#0000;
	END_IF;
	
END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

