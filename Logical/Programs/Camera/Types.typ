
TYPE
	Camera_enum_color : 	STRUCT 
		Enable : BOOL;
		NumSearchMax : USINT;
		RegionFeatures : BOOL;
		EnhancedBlobInfo : BOOL;
		Alignment : USINT;
		Input_1 : DINT;
		Input_2 : DINT;
		Input_3 : INT;
		Input_4 : DINT;
		Input_5 : DINT;
		ModuleOK : BOOL;
		ImageAcq : BOOL;
		Set_Focus : UINT;
		Set_Expo : UDINT;
		FlashColor : USINT;
		FlashSegments : USINT;
	END_STRUCT;
	Camera_enum_logo : 	STRUCT 
		ModuleOK : BOOL;
		LED_OPC : USINT;
		PhotoTaken : USINT;
		ReadFocus : USINT;
		ReadExpo : USINT;
		SetFocus : UINT;
		SetExpo : UDINT;
		FlashColor : USINT;
		FlashSegments : USINT;
		ImgProcessingActive : USINT;
		ImageAcq : BOOL;
		Enable : BOOL;
		NumSearchMax : USINT;
		MIN_SCORE : USINT;
		MAX_OVERLAP : USINT;
		NumberMatches : USINT;
		RecognizedModel : USINT;
		MatchScore : USINT;
	END_STRUCT;
END_TYPE
