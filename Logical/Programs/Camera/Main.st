PROGRAM _INIT	
	//init variables for displaying taken photo in HMI visualization
	URL := '<image x=$'0$' y=$'0$' width=$'320px$' height=$'256px$' href=$'data:application/octet-stream;base64,';
END_PROGRAM

PROGRAM _CYCLIC
	LED_GREEN; //not used, just for some changes
	
	// MANAGEMENT OF MODE IN CHEAP CAMERA (NO OTHER WAY TO DO THAT :)) )
	IF Logo.ModuleOK THEN
		CameraMode := 'Logo';
		IF gSorting.SortChoice = 2 THEN
			gSorting.SortChoice := 1;
		END_IF;
		gCamera_0L_1C := 0;
		Camera_LOGO := 1;
		Camera_COLOR := 0;
		IF gProgCamera.SetFocus <> oldFocus  THEN
			Logo.SetFocus := gProgCamera.SetFocus;			
		END_IF;
		IF gProgCamera.SetExpo <> oldExpo THEN
			Logo.SetExpo := gProgCamera.SetExpo;
		END_IF;
		oldFocus := gProgCamera.SetFocus;
		oldExpo := gProgCamera.SetExpo;
		
		gProgCamera.ReadExpo := Logo.ReadExpo;
		gProgCamera.ReadFocus := Logo.ReadFocus;
		
		Logo.LED := gProgCamera.LED; 
		Logo.ImageAcq := gProgCamera.ImageAcq;
		gProgCamera.ModuleOK := Logo.ModuleOK;
		gProgCamera.PhotoTaken := Logo.PhotoTaken;
		gProgCamera.Model_ID := Logo.Model_ID;
		gProgCamera.ImageProcessingActive := Logo.ImgProcessingActive;
	ELSIF Color.ModuleOK THEN
		CameraMode := 'Color';
		IF gSorting.SortChoice = 1 THEN
			gSorting.SortChoice := 2;
		END_IF;
		Camera_LOGO := 0;
		Camera_COLOR := 1;
		gCamera_0L_1C := 1;
		IF gProgCamera.SetFocus <> oldFocusColor  THEN
			Color.SetFocus := gProgCamera.SetFocus;			
		END_IF;
		IF gProgCamera.SetExpo <> oldExpoColor THEN
			Color.SetExpo := gProgCamera.SetExpo;
		END_IF;
		oldFocusColor := gProgCamera.SetFocus;
		oldExpoColor := gProgCamera.SetExpo;
		
		gProgCamera.ReadExpo := Color.ReadExpo;
		gProgCamera.ReadFocus := Color.ReadFocus;
		
		Color.LED := gProgCamera.LED; 
		Color.ImageAcq := gProgCamera.ImageAcq;
		gProgCamera.ModuleOK := Color.ModuleOK;
		gProgCamera.PhotoTaken := Color.PhotoTaken;
		gRecognisedModel := Color.Model_ID;
		gProgCamera.Model_ID := Color.Model_ID;
		gProgCamera.ImageProcessingActive := Color.ImgProcessingActive;
	END_IF;
	
	
	//-------------CAMERA LED--Blinking-Auto-And-Semiauto-----------//
	//0 - PLC State
	//1 - Nothing
	//2 - Green
	//3 - Red
	//4 - Blue

	IF gMode <> 1 THEN
		IF gAlarmHardware AND NOT gAlarmHardAck THEN
			gStopBlink := FALSE;
			TimerTonCameraLED.PT := TIMER_TIME_BLINK_100MS;
			TimerTonCameraLED_2.PT := TIMER_TIME_BLINK_100MS;
			CameraLED 	:= LED_RED;
			CameraLED_2 := LED_NOTHING;
		ELSIF gAlarmExist THEN
			gStopBlink := FALSE;
			TimerTonCameraLED.PT := TIMER_TIME_BLINK_500MS;
			TimerTonCameraLED_2.PT := TIMER_TIME_BLINK_500MS;
			CameraLED 	:= LED_RED;
			CameraLED_2 := LED_NOTHING;	
		ELSIF gPicNotRecognised THEN
			gStopBlink := FALSE;
			TimerTonCameraLED.PT := TIMER_TIME_BLINK_500MS;
			TimerTonCameraLED_2.PT := TIMER_TIME_BLINK_500MS;
			CameraLED 	:= LED_BLUE;
			CameraLED_2 := LED_NOTHING;
		ELSIF gWeightDetected AND NOT gStopState AND NOT gErrorState THEN
			TimerTonCameraLED.PT := TIMER_TIME_BLINK_500MS;
			TimerTonCameraLED_2.PT := TIMER_TIME_BLINK_500MS;
			gStopBlink := FALSE;
			CameraLED 	:= LED_RED;
			CameraLED_2 := LED_BLUE;
		ELSE
			gStopBlink := TRUE;
		END_IF;
	ELSE
		gStopBlink := TRUE;
	END_IF;

	IF gStopBlink THEN
		gProgCamera.LED   := LED_PLC_STATUS;
	ELSE
		TimerTonCameraLED.IN := TRUE;
		gProgCamera.LED := CameraLED;
		IF TimerTonCameraLED.Q THEN
			TimerTonCameraLED_2.IN := TRUE;
			gProgCamera.LED := CameraLED_2; 
			IF TimerTonCameraLED_2.Q THEN
				TimerTonCameraLED.IN := FALSE; 				//1 TIMER
				TimerTonCameraLED_2.IN := FALSE;			//2 TIMER
			END_IF;
		END_IF;
	END_IF;

	TimerTonCameraLED();
	TimerTonCameraLED_2();

	//-----------------TEST--CAMERA--LIGHT--------------------//

	ATON1();
	ATON2();
	ATON3();
	IF gMode = 1 THEN
		CASE sStep OF
			0:	
				ATON1.PT := TIME_LAMP_TEST;
				ATON2.PT := TIME_LAMP_TEST;
				ATON3.PT := TIME_LAMP_TEST;
				gProgCamera.LED := 0;
		
				ATON1.IN := FALSE;
				IF (gMode = 1) AND ManualLampTest THEN
					gProgCamera.LED := 1;
					ManualLampTest := 0;
					ATON1.IN := TRUE;
					ATON2.IN := FALSE;
					sStep := 1;
				END_IF;
		
			1:
				gProgCamera.LED := 2;
				IF ATON1.Q THEN
					ATON2.IN := TRUE;
					ATON3.IN := FALSE;
					sStep := 2;
				END_IF;
		
			2:
				gProgCamera.LED := 3;
				IF ATON2.Q THEN
					sStep := 3;
				END_IF;
		
			3:
				gProgCamera.LED := 4;
				ATON3.IN := TRUE;
				ATON2.IN := FALSE;
				IF ATON3.Q THEN
					sStep := 0;
				END_IF;
		END_CASE;
	END_IF;


	//setting variable for recognised model with acknowledgement of 2 different types of B&R logos
	IF (gProgCamera.Model_ID=1) OR (gProgCamera.Model_ID=3) THEN
		gRecognisedModel := 1;
	ELSE
		gRecognisedModel := gProgCamera.Model_ID;
	END_IF

	//displaying last taken photo
	CASE ImageProcess OF	// state machine to process the picture to different destinations
		0:	// state to wait for commands and set next steps in process
			IF gProgCamera.DisplayPhoto THEN
				gProgCamera.DisplayPhoto := FALSE;
				ImageProcess := 1;
			END_IF
								
		1:	// get the image which is saved on the camera
			IF Logo.ModuleOK THEN
				ViBaseGetImage_0.MpLink := ADR(gCamera);
			ELSIF Color.ModuleOK THEN
				ViBaseGetImage_0.MpLink := ADR(gCamera_C); 
			END_IF;
			ViBaseGetImage_0.Type := viBASE_IMAGE_TYPE_JPG;
			ViBaseGetImage_0.QualityLevel := VIBASE_GETIMG_QUALITY;
			ViBaseGetImage_0.Buffer := ADR(ViBaseBuffer);
			ViBaseGetImage_0.BufferSize := SIZEOF(ViBaseBuffer);
			ViBaseGetImage_0.Execute := TRUE;

			IF ViBaseGetImage_0.Done THEN
				Base64srcLen := ViBaseGetImage_0.BufferLen;	// save length of buffer on a local variable
				ViBaseGetImage_0.Execute := FALSE;
				
				ImageProcess := 2;
			END_IF
			
		2:	// transfer buffer to Base64 and merge the string to a valid SVG input
			IF NewEncodeReq THEN
				URL := '<image x=$'0$' y=$'0$' width=$'320px$' height=$'256px$' href=$'data:application/octet-stream;base64,';
				Base64Buffer := '';
				NewEncodeReq := FALSE;
			END_IF;
			
			httpEncodeBase64_0.pDest := ADR(Base64Buffer) + strlen(ADR(Base64Buffer));
			httpEncodeBase64_0.destSize := SIZEOF(Base64Buffer) - strlen(ADR(Base64Buffer)) - strlen(ADR('$' />'));
			httpEncodeBase64_0.pSrc := ADR(ViBaseBuffer);
			httpEncodeBase64_0.srcLen := Base64srcLen;
			httpEncodeBase64_0.enable := TRUE;
			httpEncodeBase64_0();
			
			URLLength := strlen(ADR(URL));
			
			IF NOT(httpEncodeBase64_0.destLen=0) THEN
				gPhotoShowed := TRUE;
				strcat(ADR(Base64Buffer), ADR('$' />')) ; // Abschluss des Image Elements
				strcat(ADR(URL), ADR(Base64Buffer));
				
				NewEncodeReq := TRUE;
				URLLength := strlen(ADR(URL));
				httpEncodeBase64_0.enable := FALSE;
				
				ImageProcess := 0;
			END_IF;

	END_CASE;
	ViBaseGetImage_0();	// call FUB
	;	// call FUB
	
END_PROGRAM

PROGRAM _EXIT

END_PROGRAM

