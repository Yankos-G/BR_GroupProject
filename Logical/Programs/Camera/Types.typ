
TYPE
	Camera_enum_color : 	STRUCT 
		LED : USINT;
		ModuleOK : BOOL;
		Enable : BOOL;
		NumSearchMax : USINT;
		RegionFeatures : BOOL;
		EnhancedBlobInfo : BOOL;
		Alignment : USINT;
		ImageAcq : BOOL;
		FlashColor : USINT;
		FlashSegments : USINT;
		SetFocus : UINT;
		SetExpo : UDINT;
		ReadFocus : UINT;
		ReadExpo : UDINT;
		Model_ID : USINT;
		ResultsMatch : USINT;
		PhotoTaken : USINT;
		ImgProcessingActive : BOOL;
	END_STRUCT;
	Camera_enum_logo : 	STRUCT 
		ModuleOK : BOOL;
		LED : USINT;
		PhotoTaken : USINT;
		ReadFocus : UINT;
		ReadExpo : UDINT;
		SetFocus : UINT;
		SetExpo : UDINT;
		FlashColor : USINT;
		FlashSegments : USINT;
		ImgProcessingActive : BOOL;
		ImageAcq : BOOL;
		Enable : BOOL;
		NumSearchMax : USINT;
		MIN_SCORE : USINT;
		MAX_OVERLAP : USINT;
		NumberMatches : USINT;
		Model_ID : USINT;
		MatchScore : USINT;
	END_STRUCT;
END_TYPE
