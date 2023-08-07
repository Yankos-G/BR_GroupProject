
TYPE
	ModelEnum : 
		(
		BR := 1, (*%ID of B&R logo model*)
		AS := 2, (*%ID of AS logo model*)
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
		RecognisedModel : ModelEnum; (*Model rozpoznany*)
		ItemWeightChoosen : USINT := 10;
		SortLeftMin : BOOL := FALSE; (*Mniejsze detale sortowane s¹ na lewo gdy 1, a wieksze na prawo gdy 1.*)
		SortLeftBR : BOOL := FALSE; (*Gdy ustawiona na 1 sortuje BR na lewo, a AS na prawo*)
		SortChoice : SortChoiceEnum := WEIGHT;
		SortLeftGrey : BOOL := FALSE; (*Gdy ustawiona na 1 sortuje Szary na lewo, pomarancz na prawo*)
	END_STRUCT;
	SortChoiceEnum : 
		(
		WEIGHT := 0,
		OPTIC_LOGO := 1,
		OPTIC_COLOR := 2
		);
END_TYPE
