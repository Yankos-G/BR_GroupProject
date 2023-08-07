
PROGRAM _INIT

	 
END_PROGRAM

PROGRAM _CYCLIC

	gMpRecipeRegPar_0.MpLink := 	ADR(gRecipeXml);
	gMpRecipeRegPar_0.Enable :=		TRUE;
	gMpRecipeRegPar_0.PVName := 	ADR('gSorting');
	
	gMpRecipeXML_0.MpLink := 		ADR(gRecipeXml);
	gMpRecipeXML_0.Enable := 		TRUE;
	gMpRecipeXML_0.DeviceName :=	ADR('CF'); 
	gMpRecipeXML_0.FileName := 		ADR('Recipies'); 
	
	SelectedIndex;
	
	gMpRecipeUI_0.MpLink :=			ADR(gRecipeXml);
	gMpRecipeUI_0.Enable := 		TRUE;
	gMpRecipeUI_0.UISetup := 		gUISetup;
	gMpRecipeUI_0.UIConnect := 		ADR(gUIConnect);

	gSorting;
	
	gMpRecipeRegPar_0();
	gMpRecipeXML_0();
	gMpRecipeUI_0();
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

