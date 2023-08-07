
TYPE
	ModelEnum : 
		(
		BR_Szary := 1, (*%ID of B&R logo model*)
		AS_Oranz := 2, (*%ID of AS logo model*)
		Unrecognised := 0 (*%case of nothing recognised*)
		);
	CofeeType : 	STRUCT 
		Sugar : USINT;
		Water : REAL;
		Powder : USINT;
		Temperature : REAL;
		Milk : REAL;
	END_STRUCT;
	SortingType : 	STRUCT 
		ItemWeightChoosen : USINT;
		SortLeftMin : BOOL; (*Mniejsze detale sortowane s¹ na lewo gdy 1, a wieksze na prawo gdy 1.*)
		SortLeftBR : BOOL; (*Gdy ustawiona na 1 sortuje BR na lewo, a AS na prawo*)
		SortChoice : SortChoiceEnum;
		SortLeftGrey : BOOL; (*Gdy ustawiona na 1 sortuje Szary na lewo, pomarancz na prawo*)
		ItemWeightLeftMin : USINT;
		ItemWeightLeftMax : USINT;
		ItemWeightRightMin : USINT;
		ItemWeightRightMax : USINT;
	END_STRUCT;
	SortChoiceEnum : 
		(
		WEIGHT := 0,
		OPTIC_LOGO := 1,
		OPTIC_COLOR := 2
		);
	Camera_enum_main : 	STRUCT 
		ModuleOK : BOOL;
		LED : USINT;
		Model_ID : USINT;
		PhotoTaken : USINT;
		SetFocus : UINT;
		SetExpo : UDINT;
		ReadFocus : UINT;
		ReadExpo : UDINT;
		ImageAcq : BOOL;
		DisplayPhoto : BOOL;
	END_STRUCT;
END_TYPE
