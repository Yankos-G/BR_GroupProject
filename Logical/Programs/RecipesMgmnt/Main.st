
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
	
	
	// RECIPES
	gMpRecipeRegPar_0.MpLink := 	ADR(gRecipeXml);
	gMpRecipeRegPar_0.Enable :=		TRUE;
	gMpRecipeRegPar_0.PVName := 	ADR('gSorting');
	
	gMpRecipeXML_0.MpLink := 		ADR(gRecipeXml);
	gMpRecipeXML_0.Enable := 		TRUE;
	gMpRecipeXML_0.DeviceName :=	ADR('CF'); 
	gMpRecipeXML_0.FileName := 		ADR('Recipies'); 
	
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

