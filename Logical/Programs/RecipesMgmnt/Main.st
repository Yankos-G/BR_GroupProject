
PROGRAM _INIT

	 
END_PROGRAM

PROGRAM _CYCLIC

	// AUDIT
	MpAuditTrailUI_0(MpLink := ADR(gAuditTrail), Enable := TRUE, UISetup := AuditUISetup, UIConnect := ADR(AuditUIConnect) );
	MpAuditTrail_0(MpLink := ADR(gAuditTrail), Enable := TRUE, DeviceName := ADR('CF_Au'));
	IF ClearAudit THEN
		MpAuditClearBuffer(MpLink := gAuditTrail);
	END_IF;
	
	// FILE MANAGEMENT
	MpFileManagerUI_0(MpLink := ADR(gFileManageUI), Enable := TRUE , UISetup := FileUISetup, UIConnect := ADR(FileUIConnect) );
	FileUIConnect.DeviceList.DeviceNames[0] := 'EF'; 
	i := 0;
	FOR i := 0 TO 15 DO
		FileName[i] := FileUIConnect.File.List.Items[i].Name;
		FileLastModified[i] := FileUIConnect.File.List.Items[i].LastModified;
		FileSize[i] := FileUIConnect.File.List.Items[i].Size;
	END_FOR;
	
	FileUIConnect.File.List.Items[idx].IsSelected := TRUE;
	CurrentFile := FileUIConnect.File.List.Items[idx].Name;
	
	CASE Filter_sort_type OF
		0:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_NAME_ASC;
		1:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_NAME_DESC;
		2:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_SIZE_ASC;
		3:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_SIZE_DES;
		4:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_MOD_TIME_ASC;
		5:
			FileUIConnect.File.SortOrder := mpFILE_SORT_BY_MOD_TIME_DESC;
	END_CASE;
	

	IF EDGENEG(gUIConnect.Status = mpRECIPE_UI_STATUS_CREATE) THEN
		gContainer[gUIConnect.Recipe.List.MaxSelection] := gSorting;
		g := 0;
		FOR g := 0 TO gUIConnect.Recipe.List.MaxSelection DO
			gContainer[g].RecipeName := gUIConnect.Recipe.List.Names[g];
		END_FOR;
	END_IF;
	IF EDGEPOS(gUIConnect.Status = mpRECIPE_UI_STATUS_DELETE) THEN
		gContainer[gUIConnect.Recipe.List.SelectedIndex] := CLEAR_RECIPE;
		z := gUIConnect.Recipe.List.SelectedIndex;
		FOR z := gUIConnect.Recipe.List.SelectedIndex TO (gUIConnect.Recipe.List.MaxSelection+1) DO
			gContainer[z] := gContainer[z+1];
		END_FOR;
	END_IF;
	IF EDGEPOS(gUIConnect.Status = mpRECIPE_UI_STATUS_RENAME) THEN
		gContainer[gUIConnect.Recipe.List.SelectedIndex] := gSorting;
		FOR g := 0 TO gUIConnect.Recipe.List.MaxSelection DO
			gContainer[g].RecipeName := gUIConnect.Recipe.List.Names[g];
		END_FOR;
	END_IF;
	IF EDGENEG(gUIConnect.Status = mpRECIPE_UI_STATUS_SAVE) THEN
		gContainer[gUIConnect.Recipe.List.SelectedIndex] := gSorting;

	END_IF;
//	FOR e := 0 TO gUIConnect.Recipe.List.MaxSelection DO
//		gTempContainter[e] := gContainer[e];
//	END_FOR;
//	f := gUIConnect.Recipe.List.SelectedIndex;
//	gUIConnect.Recipe.Refresh := TRUE;
//	IF EDGENEG(gUIConnect.Status = mpRECIPE_UI_STATUS_REFRESH) THEN
//		gContainer[f] := gTempContainter[f];
//	END_IF;
	// RECIPES
	gMpRecipeRegPar_0.MpLink := 	ADR(gRecipeXml);
	gMpRecipeRegPar_0.Enable :=		TRUE;
	gMpRecipeRegPar_0.PVName := 	ADR('gSorting');
	
	gMpRecipeXML_0.MpLink := 		ADR(gRecipeXml);
	gMpRecipeXML_0.Enable := 		TRUE;
	gMpRecipeXML_0.DeviceName :=	ADR('CF');  
	
	gMpRecipeUI_0.MpLink :=			ADR(gRecipeXml);
	gMpRecipeUI_0.Enable := 		TRUE;
	gMpRecipeUI_0.UISetup := 		gUISetup;
	gMpRecipeUI_0.UIConnect := 		ADR(gUIConnect);
	gUIConnect.Recipe.SortOrder := mpRECIPE_UI_SORT_DATE_ASCENDING;
	
	gMpRecipeRegPar_0();
	gMpRecipeXML_0();
	gMpRecipeUI_0();
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

