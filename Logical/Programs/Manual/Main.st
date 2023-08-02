 
PROGRAM _INIT


END_PROGRAM

PROGRAM _CYCLIC
	
	
	//-------FUNCTION---BLOCK---CALL-------//
	gMotorBeltAxisBasic();
	ImageShootTON();
	ImageDisplayTON();
	
	//-------VAR---CALL-------//
	gAxis_1;
	gExposureTime;
	gSetFocus;
	ImageShootTON.PT := T#500ms;
	ImageDisplayTON.PT := T#500ms;
	
	//----------ALARM----------//
	IF gAlarmHardware THEN								//if module is not ok the error will occour and manual mode will be stopped
		gActuatorByte := 2#0000_0000_0000_0000;
		gMotorBeltAxisBasic.MoveVelocity := 0;
		gMotorBeltAxisBasic.MoveAdditive := 0;
		gMotorBeltAxisBasic.Home := 0;
		gMotorBeltAxisBasic.Power := 0;
	END_IF;
		

	
	//--------------DIRECTION---CHANGES--------------//
	IF DirectionChangeVelocity THEN						//changing the direction of the manual distance and manual velocity
		DirectionChangeVelocity := 0;
		ManualVelocity := (-1)*ManualVelocity;
	END_IF;
	
	IF DirectionChangeDistance THEN
		DirectionChangeDistance := 0;
		ManualDistance := (-1)*ManualDistance;
	END_IF;
	
	
	//---------AXIS---VARIABLES---ASSIGMENT----------//
	
	IF gMode = 1 THEN									//assigning variables value of distance and velocity
		gMotorBeltParType.Distance := ManualDistance;
		gMotorBeltParType.Velocity := ManualVelocity;
	END_IF;
	
	//-----------------MANUAL---STOP-----------------//
	IF ManualStop THEN									//machine stop
		ManualStop := 0;
		gActuatorByte := 2#0000_0000_0000_0000;
		gMotorBeltAxisBasic.MoveVelocity := 0;
		gMotorBeltAxisBasic.MoveAdditive := 0;
		gMotorBeltAxisBasic.Home := 0;
		gMotorBeltAxisBasic.Power := 0;
		ManualStep := MANUAL_WAIT;
		ManualStepAct := MANUAL_ACTUATOR_WAIT;
	END_IF;
	
	//----------------------MANUAL---MODE---CHECK---CONDITION----------------------//
	IF (gMode = 1) THEN
		
		//----------------------STATE---MACHINE---AXIS------------------------//
		CASE ManualStep OF
			
			MANUAL_WAIT:
				FlagVelAddOff := 1;
				FlagAdd := 0;
				FlagVel := 0;
				IF BeltMoveAdditive THEN				//choosing between axis movement modes; additive
					gMotorBeltAxisBasic.Home := 0;
					BeltMoveAdditive := 0;
					FlagVelAddOff := 0;
					FlagAdd := 1;
					ManualStep := MANUAL_BELT_SET_ADDITIVE;
				ELSIF BeltMoveVelocityOn THEN			//velocity
					gMotorBeltAxisBasic.Home := 0;
					BeltMoveVelocityOn := 0;
					FlagVelAddOff := 0;
					FlagVel := 1;
					ManualStep := MANUAL_BELT_SET_VELOCITY;
				END_IF;

			MANUAL_BELT_SET_ADDITIVE:
				ManualVelocity := ABS(ManualVelocity);	//to avoid error: velocity and distance cannot have a negative value at the same time)
				gMotorBeltAxisBasic.Power := 0;
				gMotorBeltAxisBasic.Power := 1;
				IF gMotorBeltAxisBasic.PowerOn THEN
					gMotorBeltAxisBasic.Home := 0;
					ManualStep := MANUAL_BELT_MOVE_ADDITIVE;	  
				END_IF;
			
			MANUAL_BELT_MOVE_ADDITIVE:
				gMotorBeltAxisBasic.MoveAdditive := 1;
				IF gMotorBeltAxisBasic.MoveDone THEN
					gMotorBeltAxisBasic.ErrorReset := 1;
					gMotorBeltAxisBasic.MoveAdditive := 0;
					ManualStep := MANUAL_BELT_MOVE_ADDITIVE1;
				END_IF;
			
			MANUAL_BELT_MOVE_ADDITIVE1:
				gMotorBeltAxisBasic.ErrorReset := 0;
				ManualStep := MANUAL_WAIT;
			
			MANUAL_BELT_SET_VELOCITY:
				gMotorBeltAxisBasic.Power := 0;
				gMotorBeltAxisBasic.Power := 1;
				IF gMotorBeltAxisBasic.PowerOn THEN
					gMotorBeltAxisBasic.MoveVelocity := 1;
					ManualStep := MANUAL_BELT_MOVE_VELOCITY;	  
				END_IF;
		
			MANUAL_BELT_MOVE_VELOCITY:
				IF gMotorBeltAxisBasic.InVelocity THEN
					IF BeltMoveVelocityOff THEN
						BeltMoveVelocityOff := 0;
						gMotorBeltAxisBasic.MoveVelocity := 0;
						ManualStep := MANUAL_WAIT;
					END_IF;
				END_IF;
				
		END_CASE;
		
		//-------------------STATE---MACHINE---ACTUATORS---------------------//
		CASE ManualStepAct OF
			MANUAL_ACTUATOR_WAIT:
				IF ManualActuatorDosing THEN					//monostable button for dosing actuator
					ManualActuatorDosing := 0;
					ManualStepAct := MANUAL_ACTUATOR_DOSING;
				ELSIF ManualActuatorSorting THEN				//monostable button for sorting actuator
					ManualActuatorSorting := 0;
					ManualStepAct := MANUAL_ACTUATOR_SORTING;
				ELSIF ManualActuatorBoth THEN					//monostable button for both actuators
					ManualActuatorBoth := 0;
					ManualStepAct := MANUAL_ACTUATOR_BOTH;
				ELSIF ManualActuatorNone THEN					//monostable button for dosing actuator
					ManualActuatorNone := 0;
					ManualStepAct := MANUAL_ACTUATOR_NONE;
				END_IF;
			
				//actuating actuator responsibile for DOSING an element
			MANUAL_ACTUATOR_DOSING:
				gActuatorByte := 2#0000_0000_0000_0000;
				gActuatorByte := 2#0000_0000_0000_0100;
				ManualStepAct := MANUAL_ACTUATOR_WAIT;
				
				//actuating actuator responsibile for sorting an element
			MANUAL_ACTUATOR_SORTING:
				gActuatorByte := 2#0000_0000_0000_0000;
				gActuatorByte := 2#0000_0000_0000_0001;	
				ManualStepAct := MANUAL_ACTUATOR_WAIT;
				
				//actuating both actuators 
			MANUAL_ACTUATOR_BOTH:
				gActuatorByte := 2#0000_0000_0000_0000;
				gActuatorByte := 2#0000_0000_0000_0101;
				ManualStepAct := MANUAL_ACTUATOR_WAIT;
				
				//disactuating both actuators 
			MANUAL_ACTUATOR_NONE:
				gActuatorByte := 2#0000_0000_0000_0000;
				ManualStepAct := MANUAL_ACTUATOR_WAIT;
			
		END_CASE;
		
		//------------END---OF---STATE---MACHINE---ACTUATORS---------------//
		
		IF AxisPowerOn THEN 											//monostable button enabling axis
			AxisPowerOn := 0;
			gMotorBeltAxisBasic.Power :=1;								//Axis power off is enabling by the button that is binded with stop step
		END_IF;
		
		IF FlagVelAddOff AND gMotorBeltAxisBasic.PowerOn THEN			//flag for visualisation purposes
			JogEnableVar := 1;
		ELSE
			JogEnableVar := 0;
		END_IF;
		
		//------------PHOTO---FUNCTIONS---------------//
		CASE sCamera OF
			CAMERA_INIT:	
				ImageShootTON.IN := 0;
				sCamera := CAMERA_PHOTO_SHOOT_WAIT;
			CAMERA_PHOTO_SHOOT_WAIT:
				IF PhotoShoot THEN	
					PhotoShoot :=0;
					gImageAcq 	:= 1;
					sCamera := CAMERA_PHOTO_DISPLAY_INIT;
				END_IF;
			CAMERA_PHOTO_DISPLAY_INIT: 
				ImageShootTON.IN := 1;
				IF ImageShootTON.Q THEN
					ImageShootTON.IN := 0;
					gImageAcq 	:= 0;
					sCamera := CAMERA_PHOTO_DISPLAY;
				END_IF;
			CAMERA_PHOTO_DISPLAY:
				ImageDisplayTON.IN := 1;
				IF ImageDisplayTON.Q THEN
					ImageDisplayTON.IN := 0;
					gImageAcq 	:= 0;
					gDisplayImg := TRUE;					
					sCamera := CAMERA_INIT;
				END_IF;
			
		END_CASE;
	
//		IF PhotoShow THEN					//displaying a photo
//			gDisplayImg := 1;
//		ELSE
//			gDisplayImg := 0;
//		END_IF;
		//---------END---OF---PHOTO---FUNCTIONS------------//
		
	END_IF;
	
	
	//----------------------------FLAG---SECTION----------------------------//	
	IF (FlagActDosing = FALSE AND FlagActDosingOff = FALSE) THEN 	//if the power of the axis is enabled
		FlagActDosingOff := TRUE;
	END_IF;
	
	IF (FlagActSorting = FALSE AND FlagActSortingOff = FALSE) THEN	//if the power of the axis is enabled
		FlagActSortingOff := TRUE;
	END_IF;
	
	
	IF gMotorBeltAxisBasic.PowerOn THEN								//if the power of the axis is enabled
		AxisPowerOff := 1;
	ELSE
		AxisPowerOff := 0;
	END_IF;
	
	IF gMode = 1 THEN												//flag for manual mode choosen
		FlagManual := 1;
		FlagNotManual := 0;
	ELSE
		FlagNotManual := 1;
		FlagManual := 0;
	END_IF;
	
	IF ManualStepAct = MANUAL_ACTUATOR_DOSING THEN					//flag for dosing actuator
		FlagActBoth := 0;
		FlagActBothOff := NOT(FlagActBoth);
		FlagActDosing := 1;
		FlagActDosingOff := NOT(FlagActDosing);
		FlagActNone := 0;
		FlagActNoneOff := NOT(FlagActNone);
		FlagActSorting := 0;
		FlagActSortingOff := NOT(FlagActSorting);
	ELSIF ManualStepAct = MANUAL_ACTUATOR_SORTING THEN				//flag for sorting actuator
		FlagActBoth := 0;
		FlagActBothOff := NOT(FlagActBoth);
		FlagActDosing := 0;
		FlagActDosingOff := NOT(FlagActDosing);
		FlagActNone := 0;
		FlagActNoneOff := NOT(FlagActNone);
		FlagActSorting := 1;
		FlagActSortingOff := NOT(FlagActSorting);
	ELSIF ManualStepAct = MANUAL_ACTUATOR_BOTH THEN					//flag for both actuators
		FlagActBoth := 1;
		FlagActBothOff := NOT(FlagActBoth);
		FlagActDosing := 1;
		FlagActDosingOff := NOT(FlagActDosing);
		FlagActNone := 0;
		FlagActNoneOff := NOT(FlagActNone);
		FlagActSorting := 1;
		FlagActSortingOff := NOT(FlagActSorting);
	ELSIF ManualStepAct = MANUAL_ACTUATOR_NONE THEN					//flag for none of actuators
		FlagActBoth := 0;
		FlagActBothOff := NOT(FlagActBoth);
		FlagActDosing := 0;
		FlagActDosingOff := NOT(FlagActDosing);
		FlagActNone := 1;
		FlagActNoneOff := NOT(FlagActNone);
		FlagActSorting := 0;
		FlagActSortingOff := NOT(FlagActSorting);
	END_IF;
	
	IF (((gMotorBeltParType.Distance < 0) AND gMotorBeltAxisBasic.MoveActive AND FlagAdd) OR ((gMotorBeltParType.Velocity <0) AND gMotorBeltAxisBasic.MoveActive AND FlagVel)) THEN		//flag for visibility of left arrow
		FlagArrowLeft := 1;
		FlagArrowRight := 0;
	ELSIF (((gMotorBeltParType.Distance > 0) AND gMotorBeltAxisBasic.MoveActive AND FlagAdd) OR ((gMotorBeltParType.Velocity > 0) AND gMotorBeltAxisBasic.MoveActive AND FlagVel)) THEN	//flag for visibility of right arrow
		FlagArrowRight := 1;
		FlagArrowLeft := 0;
	ELSE								//flag for visibility of none of arrows
		FlagArrowRight := 0;
		FlagArrowLeft := 0;
	END_IF;
	
	NotMoveActive := NOT(gMotorBeltAxisBasic.MoveActive);
	//----------------------END---OF---FLAG---SECTION----------------------------//
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

