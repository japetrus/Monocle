#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// Todo:
// 1. Fix SE for CellSpace
// 2. Test with Iolite 2
// 3. Fix some bugs with the colormap/scale changer.
// Some useful functions not accessible through the user interface:
// AreaOfROI
// CopyROI
// DeleteAllROIs
// DismantleROI
// FilterROIClusterSize
// MergeROIs
// MonocleReset
// TimeEquivalentOfROI
// UpdateMonocleTable(ROIsToUpdate="ROI1;ROI2;")

Menu "Iolite"
	"Monocle/0", Monocle()
End

// This function creates the main panel
Function Monocle()

	// *** INSPECTOR LIST ***
	// To make a new inspector available to Monocle, its prefix name must be added to this semi-colon separated list:
	String ListOfInspectors = "Histogram;KDE;REE;Wetherill;TeraWasserburg;"

	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O root:Packages:Monocle:Masks
		
	// Try to guess which windows are available:
	String/G ListOfMapWindows
	SVAR ListOfMapWindows
	ListOfMapWindows = WinList("*", ";", "WIN:1")
	ListOfMapWindows = RemoveFromList("IoliteMainWindow", ListOfMapWindows)
	
	// Create some other global variables:
	String/G SelectedMapType = "From selections"
	String/G SelectedInspector = "Histogram"

	SVAR ListOfROIs
	If (!SVar_Exists(ListOfROIs))	
		String/G ListOfROIs
		SVAR ListOfROIs = root:Packages:Monocle:ListOfROIs
		ListOfROIs = ""
	EndIf
	
	String/G ActiveInspectors = ""
	
	Variable/G InspectorX = 0
	Variable/G InspectorY = 0
	String/G InspectorShape = "Ellipse"
	Variable/G InspectorWidth = 10
	Variable/G InspectorHeight = 10
	Variable/G InspectorAngle = 0
	Variable/G MakingROI = 0
	String/G InspectorColor = "(0,0,0)"

	If (!WaveExists(root:Packages:Monocle:DataTable))
		Make/O/N=(0,0) root:Packages:Monocle:DataTable
		Make/O/N=(0,4)/T root:Packages:Monocle:MetaDataTable
		Wave MetaDataTable = $"root:Packages:Monocle:MetaDataTable"
		SetDimLabel 1, 0, NumberOfPixels MetaDataTable
		SetDimLabel 1, 1, TimeEquivalent MetaDataTable
		SetDimLabel 1, 2, Area MetaDataTable
		SetDimLabel 1, 3, CreatedBy MetaDataTable
		Make/T/O/N=0 root:Packages:Monocle:DataTableROINames
	EndIf

	DoWindow/F Monocle
	
	If (V_Flag != 0)
		KillWindow Monocle
	EndIf
	
	NewPanel/K=1 /W=(400,300,600,750)/N=Monocle as "Monocle"
	ModifyPanel fixedSize=1

	// Setup:
	GroupBox SetupGroup, pos={5,2}, size={190,100}, fSize=12, font="Geneva", fStyle=1, title="Setup"

	PopupMenu MapTypePU,pos={10,25},size={180,20},title="Map type:", proc=MapTypeProc
	PopupMenu MapTypePU,mode=1,popvalue="Select to begin",value= #"\"From selections;Cell space;\""
	PopupMenu MapTypePU, font="Geneva", fSize=12
	
	Button LaunchMapButton, pos={15,55}, size={80,40}, title="Attach\rto map", font="Geneva", fSize=12, proc=AttachToMapProc
	Button CreateMapsButton, pos={105,55}, size={80,40}, title="Recreate\rall maps", font="Geneva", fSize=12, proc=CreateAllMaps
	
	// ROIs:
	GroupBox ROIsGroup, pos={5,110}, size={190,150}, fSize=12, font="Geneva", fStyle=1, title="Regions of interest"
	
	Button NewRegionButton,pos={10,135},size={85,20},title="New", font="Geneva", fSize=12, proc=NewRegionProc
	Button FinishRegionButton,pos={105,135},size={85,20},title="Finish", font="Geneva", fSize=12, proc=FinishRegionProc
	
	Button NewFromSeedButton, pos={10,160},size={85,20}, title="From Seed", font="Geneva", fSize=12, proc=NewFromSeedProc
	Button NewFromCriteriaButton, pos={105,160}, size={85,20}, title="From Criteria", font="Geneva", fSize=12, proc=NewFromCriteriaProc

	Button ShowTableButton,pos={10,185},size={85,20},title="Table", font="Geneva", fSize=12, proc=ShowTableProc
	Button ExportTableButton,pos={105,185},size={85,20},title="Export", font="Geneva", fSize=12, proc=ExportTableProc	

	CheckBox ShowROIsCB, pos={120,210}, size={80,20},title="Show all", font="Geneva", fSize=12, proc=ShowROIsProc
	
	
	PopupMenu ROIPU, pos={10, 210}, size={120,20}, title="ROI:"
	PopupMenu ROIPU, mode=3, popvalue="None", value=MonocleROIList()
	PopupMenu ROIPU, font="Geneva", fSize=12
	
	Button ShowROIButton, pos={10, 235}, size={54,20}, title="Show", font="Geneva", fSize=12, proc=ShowROIProc
	Button HideROIButton, pos={73, 235}, size={54,20}, title="Hide", font="Geneva", fSize=12, proc=HideROIProc
	Button DeleteROIButton,pos={136,235},size={54,20},title="Delete", font="Geneva", fSize=12, proc=DeleteRegionProc	
	
	// Inspectors:
	GroupBox InspectorsGroup, pos={5,265}, size={190,155}, fSize=12, font="Geneva", fStyle=1, title="Inspectors"
	
	PopupMenu InspectorTypePU,pos={10,290},size={180,20},title="Type:", proc=InspectorProc
	PopupMenu InspectorTypePU,mode=3,popvalue="Histogram",value= #("\""+ListOfInspectors+"\"")//"\"Histogram;KDE;Wetherill;TeraWasserburg;REE;\""
	PopupMenu InspectorTypePU,font="Geneva", fSize=12

	PopupMenu InspectorShapePU, pos={10,315},size={80,20},title="Shape:", proc=InspectorShapeProc
	PopupMenu InspectorShapePU, mode=3, popvalue="Ellipse",value=#"\"Ellipse;Rectangle;\""
	PopupMenu InspectorShapePU,font="Geneva", fSize=12	
	
	SetVariable InspectorWidthSV, pos={10, 340}, size={90,20},title="Width:", font="Geneva", fSize=12,value=root:Packages:Monocle:InspectorWidth
	SetVariable InspectorHeightSV, pos={100, 340}, size={90,20},title="Height:", font="Geneva", fSize=12,value=root:Packages:Monocle:InspectorHeight

	SetVariable InspectorAngleSV, pos={10, 365}, size={90,20},title="Angle:", font="Geneva", fSize=12,value=root:Packages:Monocle:InspectorAngle		
	PopupMenu InspectorColorPU, pos={100, 365}, size={90,20}, title="Color:", proc=InspectorColorProc
	PopupMenu InspectorColorPU, value="*COLORPOP*"
	PopupMenu InspectorColorPU,font="Geneva", fSize=12	
		
	Button InspectorOptionsButton, pos={10, 390},size={54,20}, title="Options", font="Geneva", fSize=12, proc=InspectorOptionsProc
	Button LaunchInspectorButton,pos={73,390},size={54,20},title="Live", font="Geneva", fSize=12, proc=LaunchInspectorProc
	Button StaticInspectorButton, pos={136,390},size={54,20},title="Static", font="Geneva", fSize=12, proc=StaticInspectorProc	
	
	SetDrawEnv xcoord=rel,ycoord=rel, fillbgc= (65535,49151,49151),fillfgc= (65535,49151,49151), linethick=0.00
	DrawRect 0, 0.95,1,1
	DrawText 5, 447, "Cite Petrus et al. (2017)"
	
End

Function/T MonocleROIList()
	SVAR ListOfROIs = root:Packages:Monocle:ListOfROIs
	Return ListOfROIs
End

Function MonocleReset()
	DoWindow/K Monocle
	KillDataFolder/Z root:Packages:Monocle
	
	If (V_flag)
		Print "[Monocle] Couldn't remove the Monocle data folder. This reset most likely failed..."
	EndIf
	
	Monocle()
End

Function ShowROIsActive()
	ControlInfo/W=Monocle ShowROIsCB
	return V_Value
End


Function/S MonocleTargetWindow()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	If (cmpstr(SelectedMapType, "Cell space")==0)
		Return "Mapped_Image"
	Else
		Return "MonocleMap"
	EndIf
End

Function MonocleUsingCellSpace()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	If (cmpstr(SelectedMapType, "Cell space")==0)
		Return 1
	Else
		Return 0
	EndIf
End

Function ShowROIProc(ctrlName) : ButtonControl
	String ctrlName
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	ControlInfo ROIPU // Note: doing ControlInfo/W=Monocle ROIPU doesn't work...?
	
	If (V_Flag == 0) // Control doesn't exist
		Return 0
	EndIf	
	
	ShowROIOnImage(S_Value)
End

Function HideROIProc(ctrlName) : ButtonControl
	String ctrlName
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	ControlInfo ROIPU // Note: doing ControlInfo/W=Monocle ROIPU doesn't work...?
	
	If (V_Flag == 0) // Control doesn't exist
		Return 0
	EndIf	
	
	RemoveROIFromImage(S_Value)
//	Print V_flag, V_Value, S_Value	
End

Function ShowROIsProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	Wave/T ROINames = root:Packages:Monocle:DataTableROINames
	
	
	print TopImageName()
	Wave TopImage
	If (MonocleUsingCellSpace())
		NewDataFolder/O/S root:Packages:iolite:CellSpaceImages
		Wave TopImage = $("CellSpace_Sample")
		NewDataFolder/O/S root:Packages:Monocle:CellSpaceImages
	Else
		NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
		Wave TopImage = $TopImageName()
	EndIf
	
	Variable ROIindex
	
	For (ROIIndex = 0; ROIIndex < numpnts(ROINames); ROIIndex += 1)
		String ThisROIName = ROINames[ROIIndex]
		String ThisMaskName = ThisROIName + "_Mask"
		RemoveImage/Z/W=$MonocleTargetWindow() $ThisMaskName
	EndFor
	
	String ROIsOnMap = ImageNameList(MonocleTargetWindow(), ";")
	
	// Remove them all:
	For (ROIIndex = 0; ROIIndex < ItemsInList(ROIsOnMap); ROIIndex += 1)
		If (GrepString(StringFromList(ROIIndex, ROIsOnMap), "(?i)Mask"))
			ThisROIName = StringFromList(ROIIndex, ROIsOnMap)
			String ThisMaskString = "root:Packages:Monocle:Masks:"+ThisROIName+"_Mask"
			Wave ThisMask = $ThisMaskString
			String ThisMaskStringShort = ThisROIName+"_Mask"
			RemoveImage/Z/W=$MonocleTargetWindow() $ThisMaskStringShort
		EndIf
	EndFor
		
	// Add them back if checked:
	If (checked)
	
		NewDataFolder/O/S $("root:Packages:Monocle:Temp")
	
		For (ROIIndex = 0; ROIIndex < numpnts(ROINames); ROIIndex += 1)
			ThisROIName = ROINames[ROIIndex]
			ThisMaskString = "root:Packages:Monocle:Masks:"+ThisROIName+"_Mask"
			Wave ThisMask = $ThisMaskString
			ThisMaskStringShort = ThisROIName + "_Mask"
			If (MonocleUsingCellSpace())
			//	SetScale/P x, dimoffset(TopImage, 0), dimdelta(TopImage, 0),  "", ThisMask
			//	SetScale/P y, dimoffset(TopImage, 1), dimdelta(TopImage, 1), "", ThisMask			
				AppendImage/L/T/W=$MonocleTargetWindow() ThisMask
			Else
				AppendImage/L/B/W=$MonocleTargetWindow() ThisMask
			EndIf
			
			Variable r = 20000 +45000*abs(enoise(1))
			Variable g = 20000 +45000*abs(enoise(1))
			Variable b = 20000 +45000*abs(enoise(1))		
			
			ModifyImage $ThisMaskStringShort explicit=1, eval={0,r, g,b}, eval={1,-1,-1,-1}
			
			ImageAnalyzeParticles/Q/A=0 stats, ThisMask
			Wave W_SpotX, W_SpotY

			Variable SpotX = dimoffset(TopImage, 0) + dimdelta(TopImage,0)*W_SpotX[0]
			Variable SpotY = dimoffset(TopImage,1) + dimdelta(TopImage,1)*W_SpotY[0]
			print W_SpotX, W_SPotY,SpotX, SpotY, dimoffset(TopImage,0), dimdelta(TopImage,0)
			
			Variable tagpos = TagXForImageXY(ThisMask, SpotX, SpotY)
			
			Tag/W=$MonocleTargetWindow()/C/N=$ThisMaskStringShort/F=0/B=1/X=0.00/Y=0.00/L=0 $ThisMaskStringShort, tagpos, ThisROIName
		
		EndFor			
	EndIf
End


Function RemoveROIFromImage(ROIName)
	String ROIName
	
	String ThisMaskString = ROIName+"_Mask"
	RemoveImage/Z/W=$MonocleTargetWindow() $ThisMaskString	
End

Function ShowROIOnImage(ROIName)
	String ROIName
	
	Wave TopImage
	If (MonocleUsingCellSpace())
		NewDataFolder/O/S root:Packages:iolite:CellSpaceImages
		Wave TopImage = $("CellSpace_Sample")
		NewDataFolder/O/S root:Packages:Monocle:CellSpaceImages
	Else
		NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
		Wave TopImage = $TopImageName()
	EndIf	
	
	String ThisMaskString = "root:Packages:Monocle:Masks:"+ROIName+"_Mask"
	String ThisMaskStringShort = ROIName+"_Mask"
	Wave ThisMask = $ThisMaskString
	
	If (!WaveExists(ThisMask))
		Return 0
	EndIf
	
	RemoveROIFromImage(ROIName)
	
	If (MonocleUsingCellSpace())
		AppendImage/L/T/W=$MonocleTargetWindow() ThisMask
	Else
		AppendImage/L/B/W=$MonocleTargetWindow() THisMask
	EndIf
	
	Variable r = 20000 +45000*abs(enoise(1))
	Variable g = 20000 +45000*abs(enoise(1))
	Variable b = 20000 +45000*abs(enoise(1))		
			
	ModifyImage/W=$MonocleTargetWindow() $ThisMaskStringShort explicit=1, eval={0,r, g,b}, eval={1,-1,-1,-1}
			
	ImageAnalyzeParticles/Q/A=0 stats, ThisMask
	Wave W_SpotX, W_SpotY

	Variable SpotX = dimoffset(TopImage, 0) + dimdelta(TopImage,0)*W_SpotX[0]
	Variable SpotY = dimoffset(TopImage,1) + dimdelta(TopImage,1)*W_SpotY[0]
	print W_SpotX, W_SPotY,SpotX, SpotY, dimoffset(TopImage,0), dimdelta(TopImage,0)
			
	Variable tagpos = TagXForImageXY(ThisMask, SpotX, SpotY)
			
	Tag/W=$MonocleTargetWindow()/C/N=$ThisMaskStringShort/F=0/B=1/X=0.00/Y=0.00/L=0 $ThisMaskStringShort, tagpos, ROIName
			
	
End

Function TagXForImageXY(image, x, y)
	Wave image
	Variable x, y
 
	// x = DimOffset(image,0) + row * DimDelta(image,0)
	// y = DimOffset(image,1) + col * DimDelta(image,1)
 
	// solving for row and col:
	Variable row= (x - DimOffset(image,0)) / DimDelta(image,0)
	Variable col= (y - DimOffset(image,1)) / DimDelta(image,1)
	
	// now treat image as a one-dimensional wave
	Variable point = row + col * DimSize(image,0)
 
	// Tag takes X scaled value. Yes, this is a bit kludgy.
	Variable tagX= DimOffset(image,0)+ point * DimDelta(image,0)
 
	return tagX
End

Function InspectorShapeProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			print popNum, popStr
			SVAR InspectorShape = $"root:Packages:Monocle:InspectorShape"
			InspectorShape = popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0		
End

Function InspectorColorProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			print popNum, popStr
			SVAR InspectorColor = $"root:Packages:Monocle:InspectorColor"
			InspectorColor = popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0		
End


Function MapTypeProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	Switch( pa.eventCode )
		Case 2: // mouse up
			SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
			SelectedMapType = pa.popStr
						
			If (MonocleUsingCellSpace())
				DoAlert/T="Monocle" 1, "Do you wish to recalculate all cell space images?\r(This could take a while)"
				
				If (V_flag == 1)
					MakeAllCellSpaceImages()
				EndIf	
			Else
				DoAlert/T="Monocle" 1, "Do you wish to recalculate all from selections images?\r(Shouldn't take too long)"
				
				If (V_flag == 1)
					MakeAllSelectionsImages()
				EndIf
			EndIf
				
			Break		
	EndSwitch
	
	If (!MonocleTableEmpty())
		DoAlert/T="Monocle" 1, "Do you wish to clear existing ROIs?"
		
		If (V_flag == 1)
			DeleteAllROIs()
		EndIf
	EndIf

	Return 0
End

Function AttachToMapProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/F $MonocleTargetWindow()
	
	// If the window doesn't exist, take action
	If (V_flag != 1)
		If (MonocleUsingCellSpace())
			DoAlert/T="Monocle" 0, "Please open the cell space window from iolite and then try attaching again."
			Return -1	
		Else
			DisplayMonocleMap()
		EndIf	
	EndIf	
	
	DoWindow/F $MonocleTargetWindow()
	If (V_flag != 1)
		Print "[Monocle] Sorry... we can't seem to find a suitable window to attach to."
		Return -1
	EndIf	
	
	Print "[Monocle] Trying to install a hook function on", MonocleTargetWindow()	
	SetWindow $MonocleTargetWindow() hook(InspectorHook)=InspectorHook
End

Function ShowTableProc(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/K MonocleDataTable
	
	Edit/N=MonocleDataTable/K=1 root:Packages:Monocle:DataTable.ld, root:Packages:Monocle:MetaDataTable.ld as "Monocle Data Table"
	
	Variable showParts = 2^2 | 2^4 | 2^5 | 2^6
	
	ModifyTable/W=MonocleDataTable showParts=showParts, autosize={1,0,0,0,0}
	
End

Function DisplayMonocleMap()
	
	NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
	
	// Get a list of the available maps:
	String/G AvailableMaps = WaveList("*Map", ";", "")
	
	If (ItemsInList(AvailableMaps) == 0)
		Print "[Monocle] No from selections maps are available..."
		Return -1
	EndIf
	
	Wave ImageMap = $("root:Packages:Monocle:SelectionsImages:"+StringFromList(0,AvailableMaps))
	
	NewImage/K=1/N=MonocleMap/F ImageMap
//	ModifyGraph/W=MonocleMap height=600, width=600
	String AvailableMapsPath = "root:Packages:Monocle:SelectionsImages:AvailableMaps"
	
	PopupMenu MonocleMapPU, pos={1,1},size={80,20},title="Map:", proc=MonocleMapChangeProc
	PopupMenu MonocleMapPU, mode=1, popvalue=StringFromList(0,AvailableMaps),value=#AvailableMapsPath
	PopupMenu MonocleMapPU, font="Geneva", fSize=12

	PopupMenu MonocleColorMapPU, pos={200,1},size={80,20},title="Color map:", proc=MonocleColorMapChangeProc
	PopupMenu MonocleColorMapPU, mode=3, value="*COLORTABLEPOP*"
	PopupMenu MonocleColorMapPU, font="Geneva", fSize=12

	Variable defaultMin = WaveMin(ImageMap)
	If (defaultMin <=0)
		defaultMin = 0.01
	EndIf
	
	SetVariable MonocleMapMinSV, pos={475,1},size={100,20},title="Min:", proc=MonocleMapLimitsProc
	SetVariable MonocleMapMinSV, font="Geneva", fSize=12, value = _NUM:defaultMin
	
	SetVariable MonocleMapMaxSV, pos={575,1},size={100,20},title="Max:", proc=MonocleMapLimitsProc
	SetVariable MonocleMapMaxSV, font="Geneva", fSize=12, value = _NUM:WaveMax(ImageMap)
	
	CheckBox MonocleMapLogCB, pos={680,1}, size={50,20}, title="Log", proc=MonocleMapLogProc
	CheckBox MonocleMapLogCB, font="Geneva", fSize=12, value=1
	
	ModifyImage $StringFromList(0,AvailableMaps) ctab= {defaultMin,*,YellowHot,0}
	ModifyImage $StringFromList(0,AvailableMaps) log=1
	ModifyGraph/W=MonocleMap margin(top)=28, margin(right)=120
	ModifyGraph/W=MonocleMap noLabel=1
	ModifyGraph/W=MonocleMap width=650, height=650
	DoUpdate/W=MonocleMap
	ModifyGraph/W=MonocleMap width=0, height=0
	
	ColorScale/C/N=MonocleMapCS/W=MonocleMap/E/A=RT/X=0/Y=3.7 heightPct=99, log=1, fSize=12, image=$StringFromList(0,AvailableMaps) StringFromList(0,AvailableMaps)
End

Function MonocleMapLimitsProc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName, varStr, varName
	Variable varNum
	
	print ctrlName, varStr, varName, varNum
	If (GrepString(ctrlName, "(?i)Min"))
		ModifyImage $TopImageName() ctab={varNum,,,0}
	Else
		ModifyImage $TopImageName() ctab={,varNum,,0}	
	EndIf
End

Function MonocleMapLogProc(ctrlName, checked) : CheckBoxControl
	String ctrlName
	Variable checked
	ModifyImage $TopImageName() log=checked
	ColorScale/C/N=MonocleMapCS/W=MonocleMap log=checked
End

Function MonocleColorMapChangeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName, popStr
	Variable popNum
	ModifyImage $TopImageName() ctab={,,$popStr,0}
End

Function MonocleMapChangeProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName, popStr
	Variable popNum
	
	Wave ImageMap = $("root:Packages:Monocle:SelectionsImages:"+popStr)
	
	String ImagesOnMap = ImageNameList("MonocleMap", ";")
	
	AppendImage/W=MonocleMap ImageMap
	
	RemoveImage/W=MonocleMap $StringFromList(0, ImagesOnMap)
	
	ControlInfo/W=MonocleMap MonocleColorMapPU
	print V_flag, "is the control type..."		
	String ColorMapName = "YellowHot"
	
	If (V_flag == 3)
		ColorMapName = S_Value
	EndIf
	
	ControlInfo/W=MonocleMap MonocleMapLogCB
	print V_flag, "is the control type..."
	Variable useLog = 1
	If (V_flag == 2)
		useLog = V_Value
	EndIf
	
	Variable defaultMin = WaveMin(ImageMap)
	If (defaultMin <=0 && useLog)
		defaultMin = 0.01
	EndIf	
	ModifyImage $popStr ctab= {defaultMin,*,$ColorMapName,0}
	ModifyImage $popStr log=useLog
	
	print useLog, ColorMapName, defaultMin, WaveMax(ImageMap)
	
	ColorScale/C/N=MonocleMapCS/W=MonocleMap/E/A=RT/X=0/Y=3.7 heightPct=99, fSize=12, log=useLog, image=$popStr popStr
	SetVariable MonocleMapMaxSV value=_NUM:WaveMax(ImageMap)
	SetVariable MonocleMapMinSV value=_NUM:defaultMin
	
End


Function CreateAllMaps(ctrlName) : ButtonControl
	String ctrlName

	If (MonocleUsingCellSpace())
		MakeAllCellSpaceImages()
	Else
		MakeAllSelectionsImages()
	EndIf
	
	If (!MonocleTableEmpty())
		DoAlert/T="Monocle" 1, "Do you wish to clear existing ROIs?"
		
		If (V_flag == 1)
			DeleteAllROIs()
		EndIf
	EndIf	
End


Function InspectorProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			print popNum, popStr
			SVAR SelectedInspector = $"root:Packages:Monocle:SelectedInspector"
			SelectedInspector = popStr
			
 			Button StaticInspectorButton, disable=0
			Button LaunchInspectorButton, disable=0
			Button InspectorOptionsButton, disable=0
						
			String FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Static")
			If (strlen(FuncInfoStr) == 0)
				Print SelectedInspector+"Inspector_Static", "not found."
				Button StaticInspectorButton, disable=2
			EndIf			

			FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Launch")
			If (strlen(FuncInfoStr) == 0)
				Print SelectedInspector+"Inspector_Launch", "not found."
				Button LaunchInspectorButton, disable=2
			EndIf
			
			FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Options")
			If (strlen(FuncInfoStr) == 0)
				Print SelectedInspector+"Inspector_Options", "not found."
				Button InspectorOptionsButton, disable=2
			EndIf			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function LaunchMapProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	Switch (ba.eventCode)
		Case 2: // mouse up
			
			// If CellSpace, either bring the Cell Space map to the front, or put up a dialog to tell the user to open it from Iolite
			
			// If Selections, either bring to the front, or display a new image... this needs to be worked on
				
		Break
	EndSwitch
End

Function StaticInspectorProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Switch( ba.eventCode )
		Case 2: // mouse up
			// click code here
			print "Launch static!"
			SVAR SelectedInspector = root:Packages:Monocle:SelectedInspector
	
			String FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Static")
			If (strlen(FuncInfoStr) == 0)
				Print FuncInfoStr, "not found."
				Break
			EndIf	
		
			FuncRef ProtoInspector LaunchFunc = $(SelectedInspector+"Inspector_Static")
			LaunchFunc()			
			
			Break
	EndSwitch	
End

Function InspectorOptionsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Switch( ba.eventCode )
		Case 2: // mouse up
			// click code here
			SVAR SelectedInspector = root:Packages:Monocle:SelectedInspector
	
			String FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Options")
			If (strlen(FuncInfoStr) == 0)
				Print SelectedInspector+"Inspector_Options", "not found."
				Break
			EndIf	
		
			FuncRef ProtoInspector OptionsFunc = $(SelectedInspector+"Inspector_Options")
			OptionsFunc()			
			
			Break
	EndSwitch	
End

Function LaunchInspectorProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			print "Launch inspector!"
			
			SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
			SVAR SelectedInspector = root:Packages:Monocle:SelectedInspector
			SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
			
			String FuncInfoStr = FunctionInfo(SelectedInspector+"Inspector_Launch")
			If (strlen(FuncInfoStr) == 0)
				Print FuncInfoStr, "not found."
				Break
			EndIf
			
			//Wave InspectorROIx = root:Packages:Monocle:InspectorROIx
//			Wave InspectorROIy = root:Packages:Monocle:InspectorROIy
			
			NewDataFolder/O/S root:Packages:Monocle
			Make/O/N=201 InspectorROIx, InspectorROIy
						
			RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
	
			If (GrepString(SelectedMapType, "(?i)Cell space"))
				AppendToGraph/T/W=$MonocleTargetWindow() InspectorROIy vs InspectorROIx	
			Else
				AppendToGraph/W=$MonocleTargetWindow() InspectorROIy vs InspectorROIx
			EndIf				
			
			If (FindListItem(SelectedInspector, ActiveInspectors)== -1)
				ActiveInspectors += SelectedInspector + ";"
			EndIf
			
			
			FuncRef ProtoInspector LaunchFunc = $(SelectedInspector+"Inspector_Launch")
			LaunchFunc()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NewFromSeedProc(ctrlName) : ButtonControl
	String ctrlName
		
	If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
		Print "[Monocle] The specified map window does not exist."
		Return 0
	EndIf			
			
	DoWindow/F $MonocleTargetWindow()
	GraphNormal/W=$MonocleTargetWindow()
	HideTools/A/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
		
	NewDataFolder/O/S root:Packages:Monocle:Temp
		
	ImageGenerateROIMask/E=1/I=0/W=$MonocleTargetWindow() $TopImageName()
	Wave M_ROIMask
	
	If (!WaveExists(M_ROIMask))
		Print "[Monocle] Click new and draw a seed ROI before clicking this button."
		Return 0
	EndIf
	
	GraphNormal/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() /K ProgFront
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
	
	NVAR MakingROI = root:Packages:Monocle:MakingROI
	MakingROI = 0	
	
	NewRegionFromSeed2(M_ROIMask)

End

Function NewFromCriteriaProc(ctrlName) : ButtonControl
	String ctrlName
	
	If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
		Print "[Monocle] The specified map window does not exist."
		Return 0
	EndIf			
			
	DoWindow/F $MonocleTargetWindow()
	GraphNormal/W=$MonocleTargetWindow()
	HideTools/A/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
		
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	KillWaves/Z M_ROIMask
	ImageGenerateROIMask/E=1/I=0/W=$MonocleTargetWindow() $TopImageName()
	Wave M_ROIMask
	
	If (!WaveExists(M_ROIMask))
		Print "[Monocle] Applying criteria to the entire map!"		
	EndIf
	
	GraphNormal/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() /K ProgFront
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
	
	NVAR MakingROI = root:Packages:Monocle:MakingROI
	MakingROI = 0	
	
	If (WaveExists(M_ROIMask))
		NewRegionFromCriteria(ROIMask = M_ROIMask)
	Else
		NewRegionFromCriteria()
	EndIf
End

Function NewRegionProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			print "New region!"

			If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
				Print "[Monocle] The specified map window does not exist."
				Return 0
			EndIf
			
			ShowTools/A/W=$MonocleTargetWindow() poly
			SetDrawLayer/W=$MonocleTargetWindow() ProgFront
			Wave w = $GetImageWave(MonocleTargetWindow())
			String iminfo = ImageInfo(MonocleTargetWindow(), NameOfWave(w), 0)
			String xax = StringByKey("XAXIS", iminfo)
			String yax = StringByKey("YAXIS", iminfo)
			
			SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
			
			If (cmpstr(SelectedMapType, "Cell space") == 0)
				SetDrawEnv/W=$MonocleTargetWindow() linefgc= (3,52428,1),fillpat= 0,xcoord=top,ycoord=left,save
			Else
				SetDrawEnv/W=$MonocleTargetWindow() linefgc= (3,52428,1),fillpat= 0,xcoord=bottom,ycoord=left,save
			EndIf
			
			NVAR MakingROI = root:Packages:Monocle:MakingROI
			MakingROI = 1
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function FinishRegionProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			print "Finish region!"
			
			If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
				Print "[Monocle] The specified map window does not exist."
				Return 0
			EndIf			
			
			DoWindow/F $MonocleTargetWindow()
			GraphNormal/W=$MonocleTargetWindow()
			HideTools/A/W=$MonocleTargetWindow()
			SetDrawLayer/W=$MonocleTargetWindow() UserFront
			DoWindow/F Monocle

			SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
			String ROIName = "ROI"			
			Prompt ROIName, "Enter a name for this ROI: "
			
			// Prompt for a name:
			Do
				DoPrompt "New ROI", ROIName
				If (V_Flag)
					Return -1 // Cancelled.. should probably do something else here?
				EndIf
			While (FindListItem(ROIName, ListOfROIs) != -1)
												
			NewDataFolder/O/S root:Packages:Monocle								
			
			// Create a mask associated with that name?
			SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
			
			
			ImageGenerateROIMask/E=1/I=0/W=$MonocleTargetWindow() $TopImageName()
			
			Wave M_ROIMask
			KillWaves/Z $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")
			MoveWave M_ROIMask, root:Packages:Monocle:Masks:$(ROIName+"_Mask")
			
			//print TopImageName()
			//print ROIName
						
			ListOfROIs += ROIName +";"
			
			// Update data table?			
			UpdateMonocleTable(ROIsToUpdate=ROIName)
			Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
			MetaDataTable[%$ROIName][%$"CreatedBy"] = "Drawing"			
			
			// Want to keep the ROIs drawn on the image and show a label?
			// This will involve converting the drawing layer to some traces and removing the layer
		
			GraphNormal/W=$MonocleTargetWindow()
			SetDrawLayer/W=$MonocleTargetWindow() /K ProgFront
			SetDrawLayer/W=$MonocleTargetWindow() UserFront
			DoWindow/F Monocle	

			NVAR MakingROI = root:Packages:Monocle:MakingROI
			MakingROI = 0
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DeleteRegionProc(ctrlName) : ButtonControl
	String ctrlName

	print "Delete region!"
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	ControlInfo ROIPU // Note: doing ControlInfo/W=Monocle ROIPU doesn't work...?
	
	If (V_Flag == 0) // Control doesn't exist
		Return 0
	EndIf	
	
	String ROIName = S_Value
	
	SVAR ListOfROIs = root:Packages:Monocle:ListOfROIs
						
	ListOfROIs = RemoveFromList(ROIName, ListOfROIs)
			
	Wave MonocleTable = root:Packages:Monocle:DataTable
	Wave/T MonocleTableROINames = root:Packages:Monocle:DataTableROINames
	Variable ROIIndex = FindDimLabel(MonocleTable, 0, ROIName)
	
	RemoveROIFromImage(ROIName)
			
	If (ROIIndex != -2)
		DeletePoints ROIIndex, 1, MonocleTable
		DeletePoints ROIIndex, 1, MonocleTableROINames
		KillWaves/Z $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")								
	EndIf
				
	Return 0
End

Function MakeMathMap(MapName, Expression)
	String MapName, Expression
	
	String Channels = MonocleChannels()
	
	String Optional_Map = ""
	
	If (!MonocleUsingCellspace())
		Optional_Map = "_Map"
	EndIf
	
	If (MonocleUsingCellspace())
		NewDataFolder/O/S root:Packages:Monocle:CellspaceImages
	Else
		NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
	EndIf
	
	Wave Template = $(StringFromList(0, Channels)+Optional_Map)
	
	Duplicate/O Template, $(MapName+Optional_Map)
	
	String FullExpression = MapName+Optional_Map+"="+Expression
	print FullExpression
	Execute  FullExpression
	
	
	
End

Function NewRegionFromSeed(Target, SeedROI, NumSD, ROIName)
	Wave SeedROI, Target
	Variable NumSD
	String ROIName
	
	Variable ROIChanged = 0 // 1 when at least 1 pixel has been added to the ROI
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	Duplicate/O SeedROI, TempMask
	
	Variable iteration = 0
	
	Do			
		//Print "Iteration #", iteration
		iteration+=1
		
		ROIChanged = 0

		ImageAnalyzeParticles/Q stats TempMask
		Wave W_xmin, W_xmax, W_ymin, W_ymax
		Variable StartRow = WaveMin(W_xmin) -1
		Variable StopRow = WaveMax(W_xmax) + 1
		Variable StartCol = WaveMin(W_ymin) - 1
		Variable StopCol = WaveMax(W_ymax) + 1
		
		StartRow = StartRow < 1 ? 1 : StartRow
		StopRow = StopRow >= DimSize(Target,0) ? DimSize(Target,0) -1 : StopRow
		StartCol = StartCol < 1 ? 1 : StartCol
		StopCol = StopCol >= DimSize(Target,1) ? DimSize(Target,1) -1 : StopCol

		ImageStats/M=0/R=TempMask Target // Use stats from the growing ROI
		
		// Iterate through the rows:
		Variable row
		For (row = StartRow; row <= StopRow; row+=1)
			Variable col
			For (col = StartCol; col <= StopCol; col+=1)

				If ( TempMask[row][col-1]-TempMask[row][col]  == 1) // Change from 1 to 0
					If (Target[row][col-1] < V_avg + NumSD*V_sdev && Target[row][col-1] > V_avg - NumSD*V_sdev)
						TempMask[row][col-1] = 0
						ROIChanged = 1
						//Print "Expanded ROI at", row, col						
					EndIf
				ElseIf (TempMask[row][col-1]-TempMask[row][col] == -1) // Change from 0 to 1
					If (Target[row][col] < V_avg + NumSD*V_sdev && Target[row][col] > V_avg - NumSD*V_sdev)
						TempMask[row][col] = 0
						ROIChanged = 1
						//Print "Expanded ROI at", row, col						
					EndIf
				EndIf				
			EndFor
			
			If (ROIChanged)
				Break
			EndIf
		EndFor

		For (col = StartCol; col <= StopCol; col+=1)		
			For (row = StartRow; row <= StopRow; row+=1)
				If ( TempMask[row-1][col]-TempMask[row][col]  == 1) // From 1 to 0
					If (Target[row-1][col] < V_avg + NumSD*V_sdev && Target[row-1][col] > V_avg - NumSD*V_sdev)
						TempMask[row-1][col] = 0
						ROIChanged = 1
						//Print "Expanded ROI at", row, col						
					EndIf
				ElseIf (TempMask[row-1][col]-TempMask[row][col] == -1)
					If (Target[row][col] < V_avg + NumSD*V_sdev && Target[row][col] > V_avg - NumSD*V_sdev)
						TempMask[row][col] = 0
						ROIChanged = 1
						//Print "Expanded ROI at", row, col						
					EndIf
				EndIf				
			EndFor
			
			If (ROIChanged)
				Break
			EndIf
		EndFor		
	
	While (ROIChanged && iteration < 100000)
	
	SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
	ListOfROIs += ROIName +";"
		
	MoveWave TempMask, root:Packages:Monocle:Masks:$(ROIName+"_Mask")												
	
	// Update data table?			
	UpdateMonocleTable(ROIsToUpdate=ROIName)
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	MetaDataTable[%$ROIName][%$"CreatedBy"] = "Growing seed with " + num2str(NumSD) + " SD"
End

Function NewRegionFromSeed2(ROIMask)
	Wave ROIMask

	Print "NewRegionFromSeed2 started!"
	
	NewDataFolder/O/S root:Packages:Monocle:Temp

	Variable NumSD = 1
	String GrowingStats = "No"
	String Connectivity = "Edges"
	String ROIName = "ROI"

	Prompt NumSD, "Number of standard deviations to include: "
	Prompt GrowingStats, "Stats for expansion: ", popup, "Original seed;Adaptive;Growing;"
	Prompt Connectivity, "Type of pixel connectivity: ", popup, "Edges;Corners;"
	Prompt ROIName, "Name for new ROI: "
	
	SVar ListOfROIs = $("root:Packages:Monocle:ListOfROIs")
	
	// Prompt for a name:
	Do
		DoPrompt "New ROI from seed", ROIName, NumSD, GrowingStats, Connectivity
		If (V_Flag)
			Return -1 // Cancelled.. should probably do something else here?
		EndIf
	While (FindListItem(ROIName, ListOfROIs) != -1)	
	

	Wave Target
	If (MonocleUsingCellSpace())
		Wave Target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
	Else
		Wave Target =  $GetImageWave(TopImageGraph())
		print "Hello?", TopImageGraph(), GetImageWave(TopImageGraph())
	EndIf	
	
	// Get X,Y of current ROI
	ImageAnalyzeParticles/A=0 stats ROIMask
	Wave W_SpotX, W_SpotY
	
	ImageStats/R=ROIMask Target
	
	Variable ROIAverage = V_avg
	Variable ROISD = V_sdev
	
	ImageStats Target
	
	Variable ImageAverage = V_avg
	Variable ImageSD = V_sdev
	Variable ImageMin = V_min
	Variable ImageMax = V_max
	
	Duplicate/O Target, TargetNoNan
	
	TargetNoNan = numtype(Target[p][q]) == 2 ? -123456 : Target[p][q]
	
	If (GrepString(GrowingStats, "(?i)Original seed") && GrepString(Connectivity, "(?i)Edges"))
		Print "[Monocle] Seed fill without growing stats and edge connectivity..."
		ImageSeedFill/B=1 seedP=W_SpotX[0], seedQ=W_SpotY[0],min=ROIAverage - NumSD*ROISD,max=ROIAverage + NumSD*ROISD, target=0, srcWave=TargetNoNan	
	ElseIf (GrepString(GrowingStats, "(?i)Adaptive") && GrepString(Connectivity, "(?i)Edges"))
		Print "[Monocle] Seed fill with growing stats and edge connectivity..."
		ImageSeedFill/B=1 adaptive=NumSD, seedP=W_SpotX[0], seedQ=W_SpotY[0],min=ROIAverage - 2*NumSD*ROISD,max=ROIAverage + 2*NumSD*ROISD, target=0, srcWave=TargetNoNan		
	ElseIf (GrepString(GrowingStats, "(?i)Original seed") && GrepString(Connectivity, "(?i)Corners"))
		Print "[Monocle] Seed fill without growing stats and corner connectivity..."	
		ImageSeedFill/B=1/C seedP=W_SpotX[0], seedQ=W_SpotY[0],min=ROIAverage - NumSD*ROISD,max=ROIAverage + NumSD*ROISD, target=0, srcWave=TargetNoNan	
	ElseIf (GrepString(GrowingStats, "(?i)Adaptive") && GrepString(Connectivity, "(?i)Corners"))
		Print "[Monocle] Seed fill with growing stats and corner connectivity..."	
		ImageSeedFill/B=1/C adaptive=NumSD, seedP=W_SpotX[0], seedQ=W_SpotY[0],min=ImageMin,max=ImageMax, target=0, srcWave=TargetNoNan			
	ElseIf (GrepString(GrowingStats, "(?i)Growing"))
		NewRegionFromSeed(Target, ROIMask, NumSD, ROIName)
		Return 0
	EndIf
	
	Wave M_SeedFill
	Redimension/U/B M_SeedFill
						
	MoveWave M_SeedFill, root:Packages:Monocle:Masks:$(ROIName+"_Mask")												
	ListOfROIs += ROIName +";"
			
	// Update data table?			
	UpdateMonocleTable(ROIsToUpdate=ROIName)
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	MetaDataTable[%$ROIName][%$"CreatedBy"] = "Seed with " + GrowingStats + ", " + Connectivity + ", " + num2str(NumSD) + " SD"	
End

Function RETest(TestString)
	String TestString
	
	String FirstArgument, Comparator, SecondArgument	
	SplitString/E="([a-zA-Z0-9_%\(\),\\s*]+)\\s*(!=?|<=?|>=?|==?|<?|>?)\\s*([+-]?(?:\\d*\.)?\\d+)[;]?" TestString, FirstArgument,Comparator,SecondArgument	
	Print "V_flag", V_flag, "S_Value", S_value, "First", FirstArgument, "Comp", Comparator, "Second", SecondArgument
	
	String ArgOp, Ch1, Ch2
	SplitString/E="([a-zA-Z%]+)\(([a-zA-Z0-9_]+)\\s*,\\s*([a-zA-Z0-9_]+)\)\\s*" FirstArgument, ArgOp, Ch1, Ch2
	Print "V_flag", V_flag, "S_Value", S_value, "ArgOp", ArgOp, "Ch1", Ch1, "Ch2", Ch2
	
End

Function FilterROIClusterSize(ROIName, Size, [InPlace, NewROIName])
	String ROIName
	Variable Size
	Variable InPlace
	String NewROIName
	
	If (ParamIsDefault(InPlace))
		InPlace = 1
	EndIf
	
	If (!InPlace && ParamIsDefault(NewROIName))
		Print "[Monocle] Non-inplace filter requested, but no new name supplied."
		Return 0
	EndIf
	
	NewDataFolder/O/S $("root:Packages:Monocle:Temp")
	
	Wave ROIMask = $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")
	
	If (!WaveExists(ROIMask))
		Print "[Monocle] The requested ROI doesn't seem to exist?"
		Return 0
	EndIf
	
	ImageAnalyzeParticles/A=0/M=3 stats ROIMask
	
	Wave NewROIMask
	
	If (!InPlace)
		Duplicate/O ROIMask $NewROIName
		Wave NewROIMask = $NewROIName
	Else
		Duplicate/O ROIMask ROIMaskTemp
		Wave NewROIMask = ROIMaskTemp
	EndIf
	
	NewROIMask = 1
	
	Wave W_SpotX, W_SpotY, W_ImageObjArea
	
	Duplicate/O W_SpotX, ROIX
	Duplicate/O W_SpotY, ROIY
	Duplicate/O W_ImageObjArea, ROIObjArea
	Wave ROIX, ROIY, ROIObjArea
	Variable NumParticles = V_NumParticles
	
	Variable particle
	For (particle = 0; particle < NumParticles; particle += 1)
		If (ROIObjArea[particle] >= Size)
//			Print "Have particle", particle,">", Size, "with size=", ROIObjArea[particle], "pos=", ROIX[particle], ROIY[particle]
//			ImageAnalyzeParticles/U/L=(ROIX[particle], ROIY[particle]) mark ROIMask	
//			Wave M_ParticleMarker
	//		NewROIMask = M_ParticleMarker == 0 ? 0 : NewROIMask
			ImageSeedFill/C/B=1 seedP=ROIX[particle],seedQ=ROIY[particle], min=0, max=0, target=0, srcWave=ROIMask
			Wave M_SeedFill
			NewROIMask = M_SeedFill == 0 ? 0 : NewROIMask

		EndIf
	EndFor	

	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"		
	If (InPlace)
		ROIMask = NewROIMask
		UpdateMonocleTable(ROIsToUpdate=ROIName)
		MetaDataTable[%$ROIName][%$"CreatedBy"] = MetaDataTable[%$ROIName][%$"CreatedBy"] +" with cluster size filter of " + num2str(Size)
	Else
		UpdateMonocleTable(ROIsToUpdate=NewROIName)
		MetaDataTable[%$NewROIName][%$"CreatedBy"] = MetaDataTable[%$ROIName][%$"CreatedBy"] +" with cluster size filter of " + num2str(Size)		
	EndIf
End

Function CopyROI(ROIName, CopyName)
	String ROIName, CopyName
	
	Wave ROIMask = $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")
	
	String FullCopyName = "root:Packages:Monocle:Masks:"+CopyName+"_Mask"
	
	Duplicate/O ROIMask $FullCopyName
	
	SVar ListOfROIs = $("root:Packages:Monocle:ListOfROIs")
	
	ListOfROIs += CopyName + ";"
	
	UpdateMonocleTable(ROIsToUpdate=CopyName)
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	MetaDataTable[%$ROIName][%$"CreatedBy"] = "Copying " + ROIName

End

Function AreaOfROI(ROIMask, [ImageWidth, ImageHeight])
	Wave ROIMask
	Variable ImageWidth, ImageHeight
	
	If (ParamIsDefault(ImageWidth))
		ImageWidth = 1
	EndIf
	
	If (ParamIsDefault(ImageHeight))
		ImageHeight = 1
	EndIf
	
	ImageAnalyzeParticles/A=0/M=3 stats ROIMask
	
	Wave W_ImageObjArea
	
	Variable ImagePixelArea = dimsize(ROIMask,0)*dimsize(ROIMask,1)
	
	Variable ROIPixelArea = 0
	
	Variable i
	For (i = 0; i < V_NumParticles; i += 1)
		ROIPixelArea += W_ImageObjArea[i]
	EndFor
	
	Variable ROIFraction = ROIPixelArea/ImagePixelArea
	
	Return ROIFraction * (ImageWidth*ImageHeight)
End

Function TimeEquivalentOfROI(ROIMask)
	Wave ROIMask
	
	Variable ROIPixels = AreaOfROI(ROIMask)*dimsize(ROIMask,0)*dimsize(ROIMask,1)
	
	Wave IndexTime = $ioliteDFpath("CurrentDRS", "Index_Time")
	
	Variable DutyCycle = IndexTime[1]-IndexTime[0]
	
	Print "Number of pixels =", ROIPixels, "Duty cycle = ", DutyCycle, "Total time = ", ROIPixels*DutyCycle
	
	Return ROIPixels*DutyCycle

End

Function IntersectROIs(ListOfROIs, NewROIName)
	String ListOfROIs, NewROIName
	
	print "todo!"


End

Function FilterByCriteria(ROIName, Criteria, NewROIName)
	String ROIName, Criteria, NewROIName
		
	Wave ROIMask = $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")
	
	If (!WaveExists(ROIMask))
		Print "[Monocle] The specified ROI name doesn't exist"
		Return 0
	EndIf
	
	NewRegionFromCriteria(ROIMask=ROIMask, ROIName=NewROIName, CriteriaList=Criteria)
	
End

Function NewRegionsFromSteppedCriteria(RootName, GlobalCriteriaList, SteppedChannelName, StartValue, StopValue, Increment)
	String RootName, GlobalCriteriaList, SteppedChannelName
	Variable StartValue, StopValue, Increment
	
	print "Making", (StopValue-StartValue)/Increment, "new ROIs..."
	
	// GlobalCriteriaList might be something like:
	// Ca43_CPS > 1.8e7; Si29_CPS < 1e6;
	
	// VariableCriteriaList might be something like:
	// Final238_206
	
	// VariableRangeList might be something like:
	// X=Xstart,Xstop,Xinc;Y=Ystart,Ystop,Yinc;
	
	// Get an ROI mask if one is drawn:
	
	If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
		Print "[Monocle] The specified map window does not exist."
		Return 0
	EndIf			
			
	DoWindow/F $MonocleTargetWindow()
	GraphNormal/W=$MonocleTargetWindow()
	HideTools/A/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
		
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	KillWaves/Z M_ROIMask
	ImageGenerateROIMask/E=1/I=0/W=$MonocleTargetWindow() $TopImageName()
	Wave M_ROIMask
	
	If (!WaveExists(M_ROIMask))
		Print "[Monocle] Applying criteria to the entire map!"		
	EndIf
	
	GraphNormal/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() /K ProgFront
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
	
	NVAR MakingROI = root:Packages:Monocle:MakingROI
	MakingROI = 0	
	
	// End of get an ROI mask	
	
	
	Variable CurrentValue
	Variable CurrentIndex = 0
	For (CurrentValue = StartValue; CurrentValue < StopValue; CurrentValue += Increment)
	
		String ROIName = RootName + num2str(CurrentIndex)
	
		String ThisCriteria = SteppedChannelName + " > " + num2str(CurrentValue) + "; " + SteppedChannelName + " < " + num2str(CurrentValue + Increment) + ";"
		
		String AllCriteria = GlobalCriteriaList + ThisCriteria
		print AllCriteria
		
		If (WaveExists(M_ROIMask))
			NewRegionFromCriteria(ROIName = ROIName, CriteriaList = AllCriteria, ROIMask = M_ROIMask)
		Else
			NewRegionFromCriteria(ROIName = ROIName, CriteriaList = AllCriteria)
		EndIf
		
		CurrentIndex += 1
	
	EndFor
	
End

Function NewRegionsFromECDFSteps(RootName, GlobalCriteriaList, ECDFChannelName, Steps, [LowTrim, HighTrim])
	String RootName, GlobalCriteriaList, ECDFChannelName
	Variable Steps, LowTrim, HighTrim
	
	If (ParamIsDefault(LowTrim))
		LowTrim = 0
	EndIf
	
	If (ParamIsDefault(HighTrim))
		HighTrim = 0
	EndIf

	Wave ECDFChannel	
	If (MonocleUsingCellSpace())
		Wave ECDFChannel = $("root:Packages:Monocle:CellSpaceImages:"+ECDFChannelName)
	Else
		Wave ECDFChannel = $("root:Packages:Monocle:SelectionsImages:"+ECDFChannelName+"_Map")
	EndIf
	
	// Get an ROI mask if one is drawn:
	
	If (cmpstr(MonocleTargetWindow(),"")==0 || FindListItem(MonocleTargetWindow(), WinList("*", ";", "")) == -1)
		Print "[Monocle] The specified map window does not exist."
		Return 0
	EndIf			
			
	DoWindow/F $MonocleTargetWindow()
	GraphNormal/W=$MonocleTargetWindow()
	HideTools/A/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
		
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	KillWaves/Z M_ROIMask
	ImageGenerateROIMask/E=1/I=0/W=$MonocleTargetWindow() $TopImageName()
	Wave M_ROIMask
	
	If (!WaveExists(M_ROIMask))
		Print "[Monocle] Applying criteria to the entire map!"		
	EndIf
	
	GraphNormal/W=$MonocleTargetWindow()
	SetDrawLayer/W=$MonocleTargetWindow() /K ProgFront
	SetDrawLayer/W=$MonocleTargetWindow() UserFront
	DoWindow/F Monocle	
	
	NVAR MakingROI = root:Packages:Monocle:MakingROI
	MakingROI = 0	
	
	// End of get an ROI mask
	
	If (WaveExists(M_ROIMask))
		Print "Using an ROI mask..."
		NewRegionFromCriteria(ROIName = RootName+"Global", CriteriaList=GlobalCriteriaList, ROIMask = M_ROIMask)
	Else
		Print "Not using an ROI mask..."	
		NewRegionFromCriteria(ROIName = RootName+"Global", CriteriaList=GlobalCriteriaList)
	EndIf
	
	Wave GlobalMask = $("root:Packages:Monocle:Masks:"+RootName+"Global_Mask")	
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	Duplicate/O ECDFChannel ECDFChannelTemp
	WaveStats/Q ECDFChannelTemp
	
	MultiThread ECDFChannelTemp = GlobalMask[p][q] == 0 ? ECDFChannelTemp[p][q] : nan
	
	Redimension/N=(V_npnts) ECDFChannelTemp
	WaveTransform zapNaNs ECDFChannelTemp
	WaveTransform zapINFs ECDFChannelTemp	
	WaveStats/Q ECDFChannelTemp
		
	Sort ECDFChannelTemp ECDFChannelTemp
	
	Variable CurrentIndex
	Variable ROIIndex = 0
	Variable StepSize = (V_npnts - (LowTrim+HighTrim))/Steps
	For (CurrentIndex = LowTrim; CurrentIndex < V_npnts-StepSize -HighTrim; CurrentIndex += StepSize)
			
		String ROIName = RootName + num2str(ROIIndex)
		
		Variable StartValue = ECDFChannelTemp[CurrentIndex]
		
		Variable StopValue
		If (CurrentIndex + StepSize < V_npnts)
			StopValue = ECDFChannelTemp[CurrentIndex + StepSize]
		Else
			StopValue = ECDFChannelTemp[V_npnts-1]
		EndIf
		
		String ThisCriteria = ECDFChannelName + " > " + num2str(StartValue) + "; " + ECDFChannelName + " < " + num2str(StopValue) + ";" 
		String AllCriteria = GlobalCriteriaList + ThisCriteria
	
		Print  AllCriteria
		
		If (WaveExists(M_ROIMask))
			NewRegionFromCriteria(ROIName = ROIName, CriteriaList = AllCriteria, ROIMask = M_ROIMask)
		Else
			NewRegionFromCriteria(ROIName = ROIName, CriteriaList = AllCriteria)
		EndIf
		
		ROIIndex += 1
	EndFor	
End

Function NewRegionsByGrid(RootName, nx, ny, TestChannelName)
	String RootName
	String TestChannelName
	Variable nx, ny
	
	SVar ListOfROIs = $("root:Packages:Monocle:ListOfROIs")		
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
		
	Wave TestChannel	
	If (MonocleUsingCellSpace())
		Wave TestChannel = $("root:Packages:Monocle:CellSpaceImages:"+TestChannelName)
	Else
		Wave TestChannel = $("root:Packages:Monocle:SelectionsImages:"+TestChannelName+"_Map")
	EndIf
	
	Variable ix, iy, maskCounter = 0
	For (ix = 0; ix < dimsize(TestChannel,0); ix += nx)
	
		For (iy = 0; iy < dimsize(TestChannel,1); iy += ny)
		
			String ThisMaskName = RootName + num2str(maskCounter)
		
			Make/O/U/B/N=(dimsize(TestChannel,0),dimsize(TestChannel,1)) $("root:Packages:Monocle:Masks:"+ThisMaskName+"_Mask")
			Wave ThisMask = $("root:Packages:Monocle:Masks:"+ThisMaskName+"_Mask")
			ThisMask = 1
			
			Variable endx = ix + nx >= dimsize(TestChannel, 0) ? dimsize(TestChannel,0)-1 : ix+nx
			Variable endy = iy + ny >= dimsize(TestChannel, 1) ? dimsize(TestChannel,1)-1 : iy+ny			
			
			ThisMask[ix,endx][iy,endy] = 0
			maskCounter += 1
			
			ListOfROIs += ThisMaskName +";"
		EndFor
	EndFor
		
		
	UpdateMonocleTable()		
End

// Could optionally be able to specify a sub region to look within?
Function NewRegionFromCriteria([ROIMask, ROIName, CriteriaList])
	Wave ROIMask
	String ROIName, CriteriaList

	// CriteriaList should be like:
	// ChannelX > 5; diff%(ChannelA,ChannelB) < 10;
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	If (ParamIsDefault(ROIName))
		ROIName = "ROI"
	EndIf
	
	If (ParamIsDefault(CriteriaList))
		CriteriaList = ""
	EndIf

	SVar ListOfROIs = $("root:Packages:Monocle:ListOfROIs")	
	
	If (ParamIsDefault(ROIName) || ParamIsDefault(CriteriaList))
	
		Prompt ROIName, "Name for new ROI: "
		Prompt CriteriaList, "List of critera (; separated): "

		// Prompt for a name:
		Do
			DoPrompt "New ROI from criteria", ROIName, CriteriaList
			If (V_Flag)
				Return -1 // Cancelled.. should probably do something else here?
			EndIf
		While (FindListItem(ROIName, ListOfROIs) != -1)	
	EndIf
	
	Make/O/U/B/N=(1,1) CriteriaMask
	
	Variable CriterionIndex
	For (CriterionIndex = 0; CriterionIndex < ItemsInList(CriteriaList); CriterionIndex+=1)
	
		String ThisCriterionString = StringFromList(CriterionIndex, CriteriaList)
		
		String ChannelName = ""
		String ComparatorString = ""
		String ValueString = ""
		String OtherChannelName = ""
		
		// Check if it contains (), if so it is a special operator:
		If ( GrepString(ThisCriterionString, "\(*\)") )
			SplitString/E="([a-zA-Z0-9_%\(\),\\s*]+)\\s*(!=?|<=?|>=?|==?|<?|>?)\\s*([+-]?(?:\\d*\.)?\\d+)[;]?" ThisCriterionString, ChannelName,ComparatorString,ValueString
			
			If (V_flag != 3)
				Print "[Monocle] Problem with criteria string,", ThisCriterionString
				Return 0
			EndIf
			
			String SpecialOp = ChannelName
			String SpecialComp = ""
			SplitString/E="([a-zA-Z%]+)\(([a-zA-Z0-9_]+)\\s*,\\s*([a-zA-Z0-9_]+)\)\\s*" ChannelName, SpecialComp, ChannelName, OtherChannelName
			
			If (V_flag != 3)
				Print "[Monocle] Problem with special op string,", SpecialOp
				Return 0
			EndIf
			
			ComparatorString = SpecialComp + ComparatorString
		Else
			SplitString/E="([a-zA-Z0-9_%\(\),\\s*]+)\\s*(!=?|<=?|>=?|==?|<?|>?)\\s*([+-]?(?:\\d*\.)?\\d+)[;]?" ThisCriterionString, ChannelName,ComparatorString,ValueString
			
			If (V_flag != 3)
				Print "[Monocle] Problem with criteria string,", ThisCriterionString
				Return 0
			EndIf
		EndIf
		
		ChannelName = ReplaceString(" ", ChannelName, "")
		OtherChannelName = ReplaceString(" ", OtherChannelName, "")
		ComparatorString = ReplaceString(" ", ComparatorString, "")
		ValueString = ReplaceString(" ", ValueString, "")
		
		Print ChannelName, OtherChannelName, ComparatorString,ValueString
		
		Wave ThisChannel, OtherChannel
		If (MonocleUsingCellSpace())
			Wave ThisChannel = $("root:Packages:Monocle:CellSpaceImages:"+ChannelName)
			If (strlen(OtherChannelName) > 0)
				Wave OtherChannel = $("root:Packages:Monocle:CellSpaceImages:"+OtherChannelName)			
			EndIf
		Else
			Wave ThisChannel = $("root:Packages:Monocle:SelectionsImages:"+ChannelName+"_Map")

			If (strlen(OtherChannelName) > 0)
				Wave OtherChannel = $("root:Packages:Monocle:SelectionsImages:"+OtherChannelName+"_Map")
			EndIf
		EndIf
		
		If (CriterionIndex == 0)
			Redimension/N=(dimsize(ThisChannel,0), dimsize(ThisChannel,1)) CriteriaMask
			CriteriaMask = 1
		EndIf
		
		Variable Value = str2num(ValueString)
		
		StrSwitch (ComparatorString)
		Case "=":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (ThisChannel == Value) ? 0 : 1
			Break
		Case "<":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (ThisChannel < Value) ? 0 : 1
			Break
		Case "<=":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (ThisChannel <= Value) ? 0 : 1
			Break
		Case ">":
			CriteriaMask = (CriteriaMask==0 || CriterionIndex==0) && (ThisChannel > Value) ? 0 : 1
			Break
		Case ">=":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (ThisChannel >= Value) ? 0 : 1
			Break
		Case "!=":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (ThisChannel != Value) ? 0 : 1
			Break
		Case "diff%<":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (100*abs(ThisChannel - OtherChannel)/ThisChannel < Value) ? 0 : 1
			Break
		Case "diff%>":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && (100*abs(ThisChannel - OtherChannel)/ThisChannel > Value) ? 0 : 1
			Break		
		Case "diffabs<":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && ((ThisChannel - OtherChannel) < Value) ? 0 : 1				
			Break
		Case "diffabs>":
			CriteriaMask = (!CriteriaMask || CriterionIndex==0) && ((ThisChannel - OtherChannel) > Value) ? 0 : 1
			Break			
		EndSwitch
	
	EndFor
	
	If (!ParamIsDefault(ROIMask))
		CriteriaMask = CriteriaMask == ROIMask ? CriteriaMask : 1
	EndIf
		
	KillWaves/Z root:Packages:Monocle:Masks:$(ROIName+"_Mask")												
	MoveWave CriteriaMask, root:Packages:Monocle:Masks:$(ROIName+"_Mask")												
	ListOfROIs += ROIName +";"
			
	// Update data table?			
	UpdateMonocleTable(ROIsToUpdate=ROIName)
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	MetaDataTable[%$ROIName][%$"CreatedBy"] = "Critera: " + CriteriaList		

End

//Function NewRegionFromSeed2()
//	Print "NewRegionFromSeed started!"
//	
//	// Idea is to expand the ROI by adjacent points that fall within some criteria (i.e < 2SD of the ROI) iteratively 
//	// until there are no more points that'll satisfy the criteria or the whole thing is an ROI
//	
//	Wave M_ROIMask = $("root:Packages:Monocle:M_ROIMask")
//
//	Wave Target
//	If (MonocleUsingCellSpace())
//		Wave Target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
//	Else
//		Wave Target =  $GetImageWave(TopImageGraph())
//	EndIf
//	
//	Variable ROIChanged = 0 // 1 when at least 1 pixel has been added to the ROI
//	Variable ROIFull = 0 // 1 when the ROI is the entire map
//	
//	Variable NumSD = 1
//	
//	Duplicate/O M_ROIMask, TempMask
//	
//	Variable iteration = 0
//
//	ImageStats M_ROIMask
//	print V_minColLoc, V_maxColLoc, V_minRowLoc, V_maxRowLoc
//	
//
//	ImageStats/M=0/R=M_ROIMask Target // Use stats from the original ROI to determine criteria
//	
//	
//	Do			
//		Print "Iteration #", iteration
//		iteration+=1
//		
//		ROIChanged = 0
//		
////		ImageStats/M=0/R=TempMask Target // Use stats from the growing ROI
//
////		MatrixConvolve RowDiffMatrix, TempMask
//		
//		// Make a matrix that puts 1s only where we want to try expanding the matrix
//		
//		
//		
//		// Iterate through the rows:
//		Variable row
//		For (row = 0; row < dimsize(Target, 0); row+=1)
//			Variable col
//			For (col = 1; col < dimsize(Target, 1); col+=1)
//
//				If ( TempMask[row][col-1]-TempMask[row][col]  == 1)
//					If (Target[row][col-1] < V_avg + NumSD*V_sdev && Target[row][col-1] > V_avg - NumSD*V_sdev)
//						TempMask[row][col-1] = 0
//						ROIChanged = 1
//						//Print "Expanded ROI at", row, col						
//					EndIf
//				ElseIf (TempMask[row][col-1]-TempMask[row][col] == -1)
//					If (Target[row][col] < V_avg + NumSD*V_sdev && Target[row][col] > V_avg - NumSD*V_sdev)
//						TempMask[row][col] = 0
//						ROIChanged = 1
//						//Print "Expanded ROI at", row, col						
//					EndIf
//				EndIf				
//			EndFor
//			
//			If (ROIChanged)
//				Break
//			EndIf
//		EndFor
//
//		For (col = 0; col < dimsize(Target, 1); col+=1)		
//			For (row = 1; row < dimsize(Target, 0); row+=1)
//				If ( TempMask[row-1][col]-TempMask[row][col]  == 1)
//					If (Target[row-1][col] < V_avg + NumSD*V_sdev && Target[row-1][col] > V_avg - NumSD*V_sdev)
//						TempMask[row-1][col] = 0
//						ROIChanged = 1
//						//Print "Expanded ROI at", row, col						
//					EndIf
//				ElseIf (TempMask[row-1][col]-TempMask[row][col] == -1)
//					If (Target[row][col] < V_avg + NumSD*V_sdev && Target[row][col] > V_avg - NumSD*V_sdev)
//						TempMask[row][col] = 0
//						ROIChanged = 1
//						//Print "Expanded ROI at", row, col						
//					EndIf
//				EndIf				
//			EndFor
//			
//			If (ROIChanged)
//				Break
//			EndIf
//		EndFor		
//	
//	While (ROIChanged && !ROIFull)
//	
//	SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
//	String ROIName = "ROI"			
//	Prompt ROIName, "Enter a name for this ROI: "
//			
//	// Prompt for a name:
//	Do
//		DoPrompt "New ROI", ROIName
//		If (V_Flag)
//			Return -1 // Cancelled.. should probably do something else here?
//		EndIf
//	While (FindListItem(ROIName, ListOfROIs) != -1)
//		
//		
//	MoveWave TempMask, root:Packages:Monocle:Masks:$(ROIName+"_Mask")												
//	ListOfROIs += ROIName +";"
//			
//	// Update data table?			
//	UpdateMonocleTable()	
//End

Function NeuralNetROITrain(GoodROIName, BadROIName, Cutoff)
	String GoodROIName, BadROIName
	Variable Cutoff

	NewDataFolder/O/S root:Packages:Monocle:NN
	
	// Duplicate the masks, turn into a 1d wave, and invert (i.e. so mask pixels = 1 instead of 0)
	Duplicate/O $("root:Packages:Monocle:Masks:" + GoodROIName+"_Mask") GoodROIWave
	Redimension/N=(dimsize(GoodROIWave,0)*dimsize(GoodROIWave,1)) GoodROIWave
	GoodROIWave = !GoodROIWave
	Duplicate/O $("root:Packages:Monocle:Masks:" + BadROIName+"_Mask") BadROIWave
	Redimension/N=(dimsize(BadROIWave,0)*dimsize(BadROIWave,1)) BadROIWave	
	BadROIWave = !BadROIWave
		
	Variable nGoodROIPixels = sum(GoodROIWave)	
	Variable nBadROIPixels = sum(BadROIWave)
	
	SVAR ChannelList = $ioliteDFpath("output", "ListOfOutputChannels")
	
	Make/O/N=(nGoodROIPixels+nBadROIPixels, ItemsInList(ChannelList)) root:Packages:Monocle:NN:NNInput
	Make/O/N=(nGoodROIPixels+nBadROIPixels, 2) root:Packages:Monocle:NN:NNOutput
	Make/O/N=(ItemsInList(ChannelList),2) root:Packages:Monocle:NN:Extremes
	Wave NNInput = $("root:Packages:Monocle:NN:NNInput")
	Wave NNOutput = $("root:Packages:Monocle:NN:NNOutput")
	Wave Extremes = $("root:Packages:Monocle:NN:Extremes")
		
	// Populate input		
	Variable ci
	For (ci = 0; ci < ItemsInList(ChannelList); ci += 1)
		String ChannelName = StringFromList(ci, ChannelList)
		Wave Channel = $("root:Packages:Monocle:SelectionsImages:"+ChannelName+"_Map")
		print ChannelName
		Duplicate/O Channel ChannelWave
		
		// Turn ChannelWave into a 1d wave
		Redimension/N=(dimsize(ChannelWave,0)*dimsize(ChannelWave,1)) ChannelWave
		
		Duplicate/O ChannelWave ChannelGoodWave
		ChannelGoodWave = ChannelWave*GoodROIWave
		ChannelGoodWave = GoodROIWave[p] == 0 ? nan : ChannelGoodWave[p]
		WaveTransform zapNaNs ChannelGoodWave
		
		Duplicate/O ChannelWave ChannelBadWave
		ChannelBadWave = ChannelWave*BadROIWave
		ChannelBadWave = BadROIWave[p] == 0 ? nan : ChannelBadWave[p]
		WaveTransform zapNaNs ChannelBadWave
		
		Concatenate/NP/O {ChannelGoodWave,ChannelBadWave}, CombinedWave
		
		NNInput[][ci] = CombinedWave[p]
	EndFor
	
	// Populate output
	NNOutput = 0
	NNOutput[][0] = p < nGoodROIPixels ? 1 : 0
	NNOutput[][1] = p < nGoodROIPixels ? 0 : 1
	
	// Normalize each column
	For (ci = 0; ci < ItemsInList(ChannelList); ci += 1)
		MatrixOP/FREE aa = col(NNInput, ci)
		WaveStats/Q aa
		
		// min/max
		//NNInput[][ci] = (NNInput[p][ci]-V_min)/(V_max-V_min)
		//Extremes[ci][0] = V_min
		//Extremes[ci][1] = V_max	
		
		// softmax
		NNInput[][ci] = StatsLogisticCDF(NNInput[p][ci], V_avg, V_sdev)
		Extremes[ci][0] = V_avg
		Extremes[ci][1] = V_sdev
	EndFor
	
	NeuralNetworkTrain nhidden=ceil(2.5*ItemsInList(ChannelList)), input=NNInput ,output=NNOutput, iterations=5000, NReport=100, Momentum=0.15, LearningRate=0.001	
End

Function NeuralNetROIRun()

	NewDataFolder/O/S root:Packages:Monocle:NN

	SVAR ChannelList = $ioliteDFpath("output", "ListOfOutputChannels")
	Wave TestChannel = $("root:Packages:Monocle:SelectionsImages:"+StringFromList(0,ChannelList)+"_Map")
	
	Make/O/N=(dimsize(TestChannel,0)*dimsize(TestChannel,1), ItemsInList(ChannelList)) root:Packages:Monocle:NN:RunInputs
	Wave RunInputs = $("root:Packages:Monocle:NN:RunInputs")	
	
	Wave Extremes = $("root:Packages:Monocle:NN:Extremes")
	
	// Populate input		
	Variable ci
	For (ci = 0; ci < ItemsInList(ChannelList); ci += 1)
		String ChannelName = StringFromList(ci, ChannelList)
		Wave Channel = $("root:Packages:Monocle:SelectionsImages:"+ChannelName+"_Map")
		print ChannelName
		Duplicate/O Channel ChannelWave
		
		// Turn ChannelWave into a 1d wave
		Redimension/N=(dimsize(ChannelWave,0)*dimsize(ChannelWave,1)) ChannelWave		
		
		// min/max
//		RunInputs[][ci] = (ChannelWave[p]-Extremes[ci][0])/(Extremes[ci][1]-Extremes[ci][0])
		// softmax
		RunInputs[][ci] = StatsLogisticCDF(ChannelWave[p], Extremes[ci][0], Extremes[ci][1])
	EndFor
	
	MatrixTranspose RunInputs
	
	Wave W1 = $("root:Packages:Monocle:NN:M_Weights1")
	Wave W2 = $("root:Packages:Monocle:NN:M_Weights2")
	
	NeuralNetworkRun Input = RunInputs, WeightsWave1 = W1, WeightsWave2 = W2

End

Function DeleteAllROIs()
	NewDataFolder/O/S root:Packages:Monocle
	
	SVAR ListOfROIs = $("root:Packages:Monocle:ListOfROIs")

	Wave MonocleTable = root:Packages:Monocle:DataTable
	Wave/T MonocleTableROINames = root:Packages:Monocle:DataTableROINames
	
	String FullListOfROIs = ListOfROIs
	
	Variable ROIIndex
	For (ROIIndex = 0; ROIIndex < ItemsInList(FullListOfROIs); ROIIndex += 1)
	
		String ThisROI = StringFromList(ROIIndex, FullListOfROIs)
		
		Variable ROIDimIndex = FindDimLabel(MonocleTable, 0, ThisROI)
		
		If (ROIDimIndex != -2)
			DeletePoints ROIDimIndex, 1, MonocleTable
			DeletePoints ROIDimIndex, 1, MonocleTableROINames
			KillWaves/Z $("root:Packages:Monocle:Masks:"+ThisROI+"_Mask")
		EndIF
		
		ListOfROIs = RemoveFromList(ThisROI, ListOfROIs)				
	EndFor
End

Function MonocleTableEmpty()
	Wave MonocleTable = $("root:Packages:Monocle:DataTable")
	
	If (DimSize(MonocleTable, 0) == 0)
		Return 1
	EndIf
	
	Return 0
End

Function ExportTableProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			print "Export table!"
			
			Save/J/U={1,0,1,0} root:Packages:Monocle:DataTable,root:Packages:Monocle:MetaDataTable as "MonocleTable.txt"
			SavePICT/N=$MonocleTargetWindow() /E=-2
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function/S GetImageWave(grfName)
	String grfName							// use zero len str to speicfy top graph

	String s= ImageNameList(grfName, ";")
	Variable p1= StrSearch(s,";",0)
	if( p1<0 )
		return ""			// no image in top graph
	endif
	s= s[0,p1-1]
	Wave w= ImageNameToWaveRef(grfName, s)
	return GetWavesDataFolder(w,2)		// full path to wave including name
end

Function/S TopImageGraph()

	String grfName
	Variable i=0
	do
		grfName= WinName(i, 1)
		if( strlen(grfName) == 0 )
			break
		endif
		if( strlen( ImageNameList(grfName, ";")) != 0 )
			break
		endif
		i += 1
	while(1)
	return grfName
end		

// This routine returns the name of the top image in the top graph
Function/S TopImageName()

	String grfName
	Variable i=0
	do
		grfName= WinName(i, 1)
		if( strlen(grfName) == 0 )
			break
		endif
		String list=ImageNameList(grfName, ";")
		if( strlen( list) != 0 )
			return StringFromList(0,list,";")
			break
		endif
		i += 1
	while(1)
	return ""
end

Function/T MonocleChannels()

	If (MonocleUsingCellSpace())
	
		NewDataFolder/O/S root:Packages:Monocle:CellSpaceImages
		Return WaveList("*", ";", "")
	Else
		NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
		String MapList = WaveList("*Map", ";","")
		String NewMapList = ""
		
		Variable i
		For (i = 0; i < ItemsInList(MapList); i+=1)
			String MapName = ReplaceString("_Map", StringFromList(i, MapList), "")
			NewMapList += MapName + ";"
		EndFor
		Return NewMapList
	EndIf
	
	Return ""
End

Function UpdateMonocleTable([ROIsToUpdate])
	String ROIsToUpdate
		
	SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
	
	If (ParamIsDefault(ROIsToUpdate))
		ROIsToUpdate = ListofROIs
	EndIf
	
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	//SVAR ListOfOutputChannels = $ioliteDFpath("Output", "ListOfOutputChannels")
	String ListOfOutputChannels = MonocleChannels()
	ListOfOutputChannels = RemoveFromList("Beam_Seconds", ListOfOutputChannels)
	
	Variable ROIIndex, ChannelIndex
	
	Wave DataTable = $"root:Packages:Monocle:DataTable"
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	Wave/T DataTableROINames = $"root:Packages:Monocle:DataTableROINames"
	
	
	// Figure out if we have U-Pb data:
	Variable Have6_38 =0 
	Variable Have7_35 = 0
	Variable Have38_6 = 0
	Variable Have7_6 = 0
	
	Have6_38 = GrepString(ListOfOutputChannels, "(?i)Final206_238") ? 1 : 0
	Have7_35 = GrepString(ListOfOutputChannels, "(?i)Final207_235") ? 1 : 0
	Have38_6 = GrepString(ListOfOutputChannels, "(?i)Final238_206") ? 1 : 0
	Have7_6 = GrepString(ListOfOutputChannels, "(?i)Final207_206") ? 1 : 0	
	
	print "Doing correlations?", Have6_38, Have7_35, Have38_6, Have7_6	
	
	Variable ExtraColumns = 0
	If (Have6_38 && Have7_35)
		ExtraColumns += 1
	EndIf
	If (Have38_6 && Have7_6)
		ExtraColumns += 1
	EndIf
	
	Variable includeSum = 0
	Variable colsPerChannel = includeSum == 1 ? 3 : 2
	
	For (ROIIndex = 0; ROIIndex < ItemsInList(ROIsToUpdate); ROIIndex +=1)

		String ThisROIName = StringFromList(ROIIndex, ROIsToUpdate)
			
		// Check if this ROI already has an entry in the table:
		Variable ThisROIIndex = FindDimLabel(DataTable, 0, ThisROIName)
		
		If (ThisROIIndex == -2) // Label not found
			Redimension /N=(dimsize(DataTable,0)+1,ItemsInList(ListOfOutputChannels)*colsPerChannel + ExtraColumns) DataTable
			Redimension /N=(dimsize(DataTable,0)) DataTableROINames
			Redimension /N=(dimsize(DataTable,0), 4) MetaDataTable
			ThisROIIndex = dimsize(DataTable,0) -1
		EndIf
		
		SetDimLabel 0, ThisROIIndex, $ThisROIName, DataTable
		SetDimLabel 0, ThisROIIndex, $ThisROIName, MetaDataTable
		DataTableROINames[ThisROIIndex] = ThisROIName
		
		// Get wave corresponding to this ROI mask:		
		Wave Mask = $("root:Packages:Monocle:Masks:"+ThisROIName+"_Mask")
	
		WaveStats/Q Mask
		MetaDataTable[ThisROIIndex][%$"NumberOfPixels"] = num2str(V_npnts - V_sum)
		MetaDataTable[ThisROIIndex][%$"Area"] = num2str(AreaOfROI(Mask))
		MetaDataTable[ThisROIIndex][%$"TimeEquivalent"] = num2str(TimeEquivalentOfROI(Mask))
	
		For (ChannelIndex = 0; ChannelIndex < ItemsInList(ListOfOutputChannels); ChannelIndex += 1)
			String ThisChannelName = StringFromList(ChannelIndex, ListOfOutputChannels)


			Variable ThisColIndex = FindDimLabel(DataTable,1,ThisChannelName)
			
			If (ThisColIndex == -2) // Label not found
				Redimension /N=(dimsize(DataTable,0),ItemsInList(ListOfOutputChannels)*colsPerChannel + ExtraColumns) DataTable
			EndIf

			Variable MeanValue, UncertValue, SumValue		
			// Get image corresponding to this channel
			If (cmpstr(SelectedMapType, "Cell space")==0)
				Wave ThisImage = $("root:Packages:Monocle:CellSpaceImages:"+ThisChannelName)
//				Smooth/M=(NaN) 5, ThisImage
//				Redimension/N=(dimsize(ThisImage,0), dimsize(ThisImage,1)), Mask
//				ImageStats/M=0/Q/R=Mask ThisImage

			Else
				Wave ThisImage = $("root:Packages:Monocle:SelectionsImages:"+ThisChannelName+"_Map")
				//ImageStats/M=0/Q/R=Mask ThisImage
		
			EndIf		
			
			MonocleStats(ThisImage, Mask, MeanValue, UncertValue, SumValue)
			Print "got sum value = ", SumValue, "for", ThisChannelName
			
			SetDimLabel 1, (ChannelIndex*colsPerChannel), $ThisChannelName, DataTable
			
			String ThisUncertName = ThisChannelName+"_Int2SE"
			SetDimLabel 1, (ChannelIndex*colsPerChannel)+1, $ThisUncertName, DataTable					
			
//			DataTable[ROIIndex][ChannelIndex*2] = V_avg
//			DataTable[ROIIndex][ChannelIndex*2+1] = V_sdev*2/sqrt(V_npnts)						
			DataTable[ThisROIIndex][ChannelIndex*colsPerChannel] = MeanValue
			DataTable[ThisROIIndex][ChannelIndex*colsPerChannel+1] = UncertValue
			If (includeSum)
				String ThisSumName = ThisChannelName+"_Sum"
				SetDimLabel 1, (ChannelIndex*colsPerChannel)+2, $ThisSumName, DataTable			
				DataTable[ThisROIIndex][ChannelIndex*colsPerChannel+2] = SumValue
			EndIf
		EndFor
	
		Wave Ratio6_38
		Wave Ratio7_35
		Wave Ratio38_6
		Wave Ratio7_6
		
		Duplicate/O Mask FalseMask
		Redimension/D FalseMask
		FalseMask[][] = FalseMask[p][q] == 1 ? nan : 1
		
		If (Have6_38 && Have7_35)
			If (MonocleUsingCellSpace())
				Wave Ratio6_38 = root:Packages:Monocle:CellSpaceImages:Final206_238
				Wave Ratio7_35 = root:Packages:Monocle:CellSpaceImages:Final207_235
			Else
				Wave Ratio6_38 = root:Packages:Monocle:SelectionsImages:Final206_238_Map
				Wave Ratio7_35 = root:Packages:Monocle:SelectionsImages:Final207_235_Map
			EndIf				
			
			Duplicate/O Ratio6_38, Temp6_38
			Duplicate/O Ratio7_35, Temp7_35
			
			Temp6_38 = Ratio6_38*FalseMask
			Temp7_35 = Ratio7_35*FalseMask
			
			Redimension/N=(dimsize(Temp6_38,0)*dimsize(Temp6_38,1)) Temp6_38
			Redimension/N=(dimsize(Temp7_35,0)*dimsize(Temp7_35,1)) Temp7_35
	
			Temp6_38[p] = numtype(Temp7_35[p]) == 2 ? nan : Temp6_38[p]
			Temp7_35[p] = numtype(Temp6_38[p]) == 2 ? nan : Temp7_35[p]
	
			WaveTransform zapNaNs Temp6_38
			WaveTransform zapNaNs Temp7_35
	
			Variable corr = StatsCorrelation(Temp6_38,Temp7_35)			
			
			DataTable[ThisROIIndex][(ItemsInList(ListOfOutputChannels))*2] = corr
			
			String CorrName = "StatsCorr6_38v7_35"
			SetDimLabel 1, (ItemsInList(ListOfOutputChannels))*2, $CorrName, DataTable
		EndIf
		
		If (Have38_6 && Have7_6)
			If (MonocleUsingCellSpace())
				Wave Ratio38_6 = root:Packages:Monocle:CellSpaceImages:Final238_206
				Wave Ratio7_6 = root:Packages:Monocle:CellSpaceImages:Final207_206
			Else
				Wave Ratio38_6 = root:Packages:Monocle:SelectionsImages:Final238_206_Map
				Wave Ratio7_6 = root:Packages:Monocle:SelectionsImages:Final207_206_Map
			EndIf			
			
			Duplicate/O Ratio38_6, Temp38_6
			Duplicate/O Ratio7_6, Temp7_6
			
			Temp38_6 = Ratio38_6*FalseMask
			Temp7_6 = Ratio7_6*FalseMask
			
			Redimension/N=(dimsize(Temp38_6,0)*dimsize(Temp38_6,1)) Temp38_6
			Redimension/N=(dimsize(Temp7_6,0)*dimsize(Temp7_6,1)) Temp7_6
	
			Temp38_6[p] = numtype(Temp7_6[p]) == 2 ? nan : Temp38_6[p]
			Temp7_6[p] = numtype(Temp38_6[p]) == 2 ? nan : Temp7_6[p]
	
			WaveTransform zapNaNs Temp38_6
			WaveTransform zapNaNs Temp7_6
			
			corr = StatsCorrelation(Temp38_6, Temp7_6)	
			
			Variable corrcol = Have6_38 && Have7_35 ? (ItemsInList(ListOfOutputChannels))*2+1 : (ItemsInList(ListOfOutputChannels)-1)*2
			
			DataTable[ThisROIIndex][corrcol] = corr
			
			CorrName = "StatsCorr38_6v7_6"
			SetDimLabel 1, corrcol, $CorrName, DataTable		
		EndIf	
	
	EndFor
	
//	// Redimension the table to have no rows:
//	Redimension /N=(ItemsInList(ListOfROIs),ItemsInList(ListOfOutputChannels)*2 + ExtraColumns) DataTable
//	Redimension /N=(ItemsInList(ListOfROIs)) DataTableROINames
//	
//	For (ROIIndex = 0; ROIIndex < ItemsInList(ListOfROIs); ROIIndex += 1)
//	
//		String ThisROIName = StringFromList(ROIIndex, ListOfROIs)
//	
//		// Set the dim label as the ROI name
//		SetDimLabel 0, ROIIndex, $ThisROIName, DataTable
//		DataTableROINames[ROIIndex] = ThisROIName
//		
//		// Get wave corresponding to this ROI mask:		
//		Wave Mask = $("root:Packages:Monocle:Masks:"+ThisROIName+"_Mask")
//	
//		For (ChannelIndex = 0; ChannelIndex < ItemsInList(ListOfOutputChannels); ChannelIndex += 1)
//			String ThisChannelName = StringFromList(ChannelIndex, ListOfOutputChannels)
//
//			Variable MeanValue, UncertValue			
//			// Get image corresponding to this channel
//			If (cmpstr(SelectedMapType, "Cell space")==0)
//				Wave ThisImage = $("root:Packages:Monocle:CellSpaceImages:"+ThisChannelName)
////				Smooth/M=(NaN) 5, ThisImage
////				Redimension/N=(dimsize(ThisImage,0), dimsize(ThisImage,1)), Mask
////				ImageStats/M=0/Q/R=Mask ThisImage
//
//			Else
//				Wave ThisImage = $("root:Packages:Monocle:SelectionsImages:"+ThisChannelName+"_Map")
//				//ImageStats/M=0/Q/R=Mask ThisImage
//		
//			EndIf		
//			
//			MonocleStats(ThisImage, Mask, MeanValue, UncertValue)		
//			
//			SetDimLabel 1, (ChannelIndex*2), $ThisChannelName, DataTable
//			
//			String ThisUncertName = ThisChannelName+"_Int2SE"
//			SetDimLabel 1, (ChannelIndex*2)+1, $ThisUncertName, DataTable
//			
////			DataTable[ROIIndex][ChannelIndex*2] = V_avg
////			DataTable[ROIIndex][ChannelIndex*2+1] = V_sdev*2/sqrt(V_npnts)						
//			DataTable[ROIIndex][ChannelIndex*2] = MeanValue
//			DataTable[ROIIndex][ChannelIndex*2+1] = UncertValue
//		EndFor
//	
//		Wave Ratio6_38
//		Wave Ratio7_35
//		Wave Ratio38_6
//		Wave Ratio7_6
//		
//		Duplicate/O Mask FalseMask
//		Redimension/D FalseMask
//		FalseMask[][] = FalseMask[p][q] == 1 ? nan : 1
//		
//		If (Have6_38 && Have7_35)
//			If (MonocleUsingCellSpace())
//				Wave Ratio6_38 = root:Packages:Monocle:CellSpaceImages:Final206_238
//				Wave Ratio7_35 = root:Packages:Monocle:CellSpaceImages:Final207_235
//			Else
//				Wave Ratio6_38 = root:Packages:Monocle:SelectionsImages:Final206_238_Map
//				Wave Ratio7_35 = root:Packages:Monocle:SelectionsImages:Final207_235_Map
//			EndIf				
//			
//			Duplicate/O Ratio6_38, Temp6_38
//			Duplicate/O Ratio7_35, Temp7_35
//			
//			Temp6_38 = Ratio6_38*FalseMask
//			Temp7_35 = Ratio7_35*FalseMask
//			
//			Redimension/N=(dimsize(Temp6_38,0)*dimsize(Temp6_38,1)) Temp6_38
//			Redimension/N=(dimsize(Temp7_35,0)*dimsize(Temp7_35,1)) Temp7_35
//	
//			Temp6_38[p] = numtype(Temp7_35[p]) == 2 ? nan : Temp6_38[p]
//			Temp7_35[p] = numtype(Temp6_38[p]) == 2 ? nan : Temp7_35[p]
//	
//			WaveTransform zapNaNs Temp6_38
//			WaveTransform zapNaNs Temp7_35
//	
//			Variable corr = StatsCorrelation(Temp6_38,Temp7_35)			
//			
//			DataTable[ROIIndex][(ItemsInList(ListOfOutputChannels))*2] = corr
//			
//			String CorrName = "StatsCorr6_38v7_35"
//			SetDimLabel 1, (ItemsInList(ListOfOutputChannels))*2, $CorrName, DataTable
//		EndIf
//		
//		If (Have38_6 && Have7_6)
//			If (MonocleUsingCellSpace())
//				Wave Ratio38_6 = root:Packages:Monocle:CellSpaceImages:Final238_206
//				Wave Ratio7_6 = root:Packages:Monocle:CellSpaceImages:Final207_206
//			Else
//				Wave Ratio38_6 = root:Packages:Monocle:SelectionsImages:Final238_206_Map
//				Wave Ratio7_6 = root:Packages:Monocle:SelectionsImages:Final207_206_Map
//			EndIf			
//			
//			Duplicate/O Ratio38_6, Temp38_6
//			Duplicate/O Ratio7_6, Temp7_6
//			
//			Temp38_6 = Ratio38_6*FalseMask
//			Temp7_6 = Ratio7_6*FalseMask
//			
//			Redimension/N=(dimsize(Temp38_6,0)*dimsize(Temp38_6,1)) Temp38_6
//			Redimension/N=(dimsize(Temp7_6,0)*dimsize(Temp7_6,1)) Temp7_6
//	
//			Temp38_6[p] = numtype(Temp7_6[p]) == 2 ? nan : Temp38_6[p]
//			Temp7_6[p] = numtype(Temp38_6[p]) == 2 ? nan : Temp7_6[p]
//	
//			WaveTransform zapNaNs Temp38_6
//			WaveTransform zapNaNs Temp7_6
//			
//			corr = StatsCorrelation(Temp38_6, Temp7_6)	
//			
//			Variable corrcol = Have6_38 && Have7_35 ? (ItemsInList(ListOfOutputChannels))*2+1 : (ItemsInList(ListOfOutputChannels)-1)*2
//			
//			DataTable[ROIIndex][corrcol] = corr
//			
//			CorrName = "StatsCorr38_6v7_6"
//			SetDimLabel 1, corrcol, $CorrName, DataTable		
//		EndIf
//	
//	
//	EndFor

End

Function MakeAllSelectionsImages()

	NewDataFolder/O/S root:Packages:iolite:images
	NewDataFolder/O/S root:Packages:Monocle
	
	SVAR MonocleSelectionGroup = $("root:Packages:Monocle:SelectionGroup")
	If (!SVar_exists(MonocleSelectionGroup))
		String/G SelectionGroup
		SVAR MonocleSelectionGroup = $("root:Packages:Monocle:SelectionGroup")
	EndIf
	
	NewDataFolder/O/S root:Packages:Monocle:SelectionsImages
	

	//NewDataFolder/O/S root:Packages:iolite:images

	SVAR ListOfOutputNames=$ioliteDFpath("Output","ListOfOutputChannels")

	If(!SVar_Exists(ListOfOutputNames) || !strlen(ListOfOutputNames))
		Print "[Monocle] No output channels available to create images from. Process some data first."
		Return -1
	EndIf
	
	String /G ListOfImageWaves = ListOfOutputNames
	String ListOfWavesToNOTprocess="Beam_Seconds;"
	ListOfImageWaves = RemoveFromList(ListOfWavesToNOTprocess, ListOfImageWaves  , ";"  ,0)

	// Prompt for Selection Group
	String ListOfIntegTypes = MonocleIntegrationsInUse("no m_") // This only works for iolite 3+

	String SelectedInteg = ""
	If(WhichListItem("Output_1", ListOfIntegTypes) > -1)
		SelectedInteg = "Output_1"
	Else
		SelectedInteg = StringFromList(0,ListOfIntegTypes)
	EndIf
	
	Prompt SelectedInteg, "Selection group to use", popup, ListOfIntegTypes
	DoPrompt "Choose a selection group to make an image", SelectedInteg
	If (V_Flag==1) 
		Print "[Monocle] Making of images cancelled..."
		Return -1
	EndIf
	
	String SelectionGrpName = SelectedInteg
	MonocleSelectionGroup = SelectedInteg
	
	Wave SelectionGrpMatrix = $ioliteDFpath("integration", "m_"+SelectionGrpName)
	Variable/G NoOfSelections = dimsize(SelectionGrpMatrix, 0) - 1
	
	Wave SelectionsPointInfoWave = $MakeIoliteWave("images", "SelectionsPointInfoWave", N = NoOfSelections)
	Redimension /N=(-1,3)  SelectionsPointInfoWave
	SelectionsPointInfoWave = Nan
	
	SVAR IndexWaveName = $ioliteDFpath("DRSGlobals","IndexChannel")
	Wave IndexWave = $ioliteDFpath("Input",IndexWaveName)	
	If(!Waveexists(IndexWave) )								
		Print "[Monocle] Having some trouble making images from selections. Make sure that you have a DRS selected, and that output channels are available. Process aborted."
		Return -1
	EndIf 
	
	Variable SelectionCounter
	
	For(SelectionCounter = 1; SelectionCounter < NoOfSelections + 1; SelectionCounter += 1)		
		String ThisSelStartAndEndPoint = ReturnStartAndEndPoints(SelectionGrpName, SelectionCounter)
		Variable StartPoint = str2num(StringFromList(0,ThisSelStartAndEndPoint))
		Variable EndPoint = str2num(StringFromList(1,ThisSelStartAndEndPoint))

		StartPoint = StartPoint == -1 ? 0 : StartPoint
		StartPoint = StartPoint == -2 ? dimsize(IndexWave, 0)-1 : StartPoint
		EndPoint = EndPoint == -1 ? 0 : EndPoint
		EndPoint = EndPoint == -2 ? dimsize(IndexWave, 0)-1 : EndPoint
		
		SelectionsPointInfoWave[SelectionCounter-1][1] = StartPoint
		SelectionsPointInfoWave[SelectionCounter-1][2] = EndPoint	
		SelectionsPointInfoWave[SelectionCounter-1][0] = SelectionsPointInfoWave[SelectionCounter-1][2] - SelectionsPointInfoWave[SelectionCounter-1][1]
	EndFor

	MonocleMDsort(SelectionsPointInfoWave, 1)
	
	MatrixOp /O NumPointsWave = col(SelectionsPointInfoWave,  0)	
	Variable/G MaxNoOfPoints = WaveMax(NumPointsWave)
	Variable/G MinNoOfPoints = WaveMin(NumPointsWave)
		
	// By default, all maps are initially created with Left alignment:
	String Alignment = "Left"

	MonocleCreateChannelMaps(SelectionsPointInfoWave, ListOfImageWaves, Alignment, MaxNoOfPoints, NoOfSelections)	
	
End


//This function creates all the map matrices for Image by Selections. It is a separate function so that it can be called when first creating the images,
//but also when the user changes the row alignment (Left, Right, Center, or Justified)
Function MonocleCreateChannelMaps(SelectionsPointInfoWave, ListOfImageWaves, Alignment, MaxNoOfPoints, NoOfSelections)	
	
	Wave SelectionsPointInfoWave				//Wave containing the number of points (col 0), start point (col 1) and end point (col 2) of each selection
	String ListOfImageWaves					//String list of channel names to create images from.
	String Alignment								//Will be Left, Rigth, Center, or Justified (case insensitive)
	Variable MaxNoOfPoints						//Max number of rows in a single selection
	Variable NoOfSelections						//Number of selections in the Selection Group Matrix
	
	String/G ListOfMatrixMapWaves="" 			//global list of images created outputs
	Variable NoOfRows = MaxNoOfPoints + 1		//The image must be long enough to hold the longest selection, so set it to Max no of points in a selection + 1
	Variable NoOfCols = 	NoOfSelections			//Each selection is represented in the final image as a column
	
	Variable ChannelCounter
	Variable NoOfChannels = ItemsInList(ListOfImageWaves)
	
	For(ChannelCounter = 0;ChannelCounter < NoOfChannels;ChannelCounter += 1)			//loop through channels to map
		
		String ThisWaveName = stringfromlist(ChannelCounter, ListOfImageWaves) 			//get current channel from list
		Print "[Monocle] Creating map from selections for", ThisWaveName
		Wave ThisChannelSourceWave = $ioliteDFpath("CurrentDRS", ThisWaveName)			//Declare the original channel wave (e.g. Ca43_CPS)

		ThisWaveName+="_Map" 										//construct matrix name for this channel
		Make/O /N=(NoOfRows,NoOfCols) $ThisWaveName 				//create the image matrix for this channel
		ListOfMatrixMapWaves += ThisWaveName+";" 					//and add it to list of maps created
		Wave CurrentMatrix=$ThisWaveName 							//and create a local ref to it
		CurrentMatrix = Nan												//And kill off any values that might already be in it
		
		Variable SelectionCounter
				
		For(SelectionCounter = 0; SelectionCounter < NoOfSelections; SelectionCounter += 1)	//Loop through each selection and add it to the image matrix	
			Variable ThisStartPoint = SelectionsPointInfoWave[SelectionCounter][1]			//Get this selections start and end point
			Variable ThisEndPoint  = SelectionsPointInfoWave[SelectionCounter][2]
			Duplicate/O/R=[ThisStartPoint, ThisEndPoint] ThisChannelSourceWave, TempValsWave		//Duplicate the source wave over our target period
			Wave TempValsWave																	//Declare the wave containing just the values we want
			
					
			IF(GrepString(Alignment, "(?i)left") == 1)		//If set to left align, all scans start from the first row
				CurrentMatrix[0, (SelectionsPointInfoWave[SelectionCounter][0])][SelectionCounter]  =  TempValsWave [p]		// add these points to the image matrix
			
			ELSEIF(GrepString(Alignment, "(?i)right") == 1)		//If set to right align, all scans end at the last row, but start at totalpoints - noofpointsinthisselection
				CurrentMatrix[(NoOfRows - SelectionsPointInfoWave[SelectionCounter][0])-1, ][SelectionCounter]  =  TempValsWave[p - (NoOfRows - SelectionsPointInfoWave[SelectionCounter][0] -1)]	// add these points to the image matrix
			
			ELSEIF(GrepString(Alignment, "(?i)cent") == 1)		//If set to center align, scan line should be in the center of the image
				Variable RowMidPoint = floor(NoOfRows / 2)
				Variable ThisScanLength = SelectionsPointInfoWave[SelectionCounter][0]
				CurrentMatrix[(RowMidPoint - floor(ThisScanLength/2)), (RowMidPoint + floor(ThisScanLength/2))][SelectionCounter]  =  TempValsWave[p - (RowMidPoint - floor(ThisScanLength/2))]	
			
			ELSEIF(GrepString(Alignment, "(?i)just") == 1)
				
				//First off, duplicate Index_Time over the range of this selection so that we have an x wave for interpolation
				Wave /D Index_Time=$ioliteDFpath("currentDRS","index_time") 		//ref the output time wave
				If(!Waveexists(Index_Time) )										//Print error and abort if index time wave does not exist
					PrintAbort("The wave \"Index_Time\" does not exist. Make sure that you have a DRS selected, and that output channels are available")
				Endif
				Duplicate/O/R=[ThisStartPoint, ThisEndPoint] Index_Time, $"index_time_selection"
				Wave index_time_selection					//And declare it
				
				//Need get rid of Nans as Interpolate2 won't work with NaNs in the wave
				Variable SmoothingWidth = 3
				//if the smoothing width is less than the number of points in the wave it will throw an error, so check this before attempting the smooth
				SmoothingWidth = SmoothingWidth > dimsize(TempValsWave, 0) ? dimsize(TempValsWave, 0) : SmoothingWidth
				//Knock out any Nans. Have to keep going until there are no Nans left (determined by Wavestats V_numNaNs)
				//Note, if we have wide NaN gaps (> 2 NaNs wide) there will be a sharp boundary due to the smoothing. This is not an ideal way to get rid of missing data, but is meant just to get rid of the odd NaN gap	
				Do
					Smooth /M=(NaN) SmoothingWidth, TempValsWave 	// /M replaces on NaN with the running average. All the other values remain the same
					WaveStats/Q /M=1 TempValsWave					//Check for remaining NaNs
				While(V_numNaNs >0)									//Loop again if we still have NaNs
				
				 //Now interpolate to have the same width as all other scans (NoOfRows)
				Interpolate2 /E=2 /J=2 /T=2  /N=(NoOfRows) /Y=$ioliteDFpath("images","TempValsWave_Interp") index_time_selection, TempValsWave
				Wave TempValsWave_Interp = $ioliteDFpath("images","TempValsWave_Interp")		//Declare interped values wave
				
				CurrentMatrix[][SelectionCounter]  =  TempValsWave_Interp [p]					//And add the values to the image matrix
			ENDIF
		
		EndFor																			 	//until all columns added for this channel
		
	EndFor
	
	KillWaves/Z TempValsWave, TempValsWave_Interp		//Just to clean up, kill off the TempValsWave


End

// Multidimensional sort from Igor Exchange snippets... odd that the built in Igor sort isn't N-dimensionally aware! 
Function MonocleMDsort(w,keycol, [reversed])
	Wave w
	variable keycol, reversed
 
	variable type
 
	type = Wavetype(w)
 
	make/Y=(type)/free/n=(dimsize(w,0)) key
	make/free/n=(dimsize(w,0)) valindex
 
	if(type == 0)
		Wave/t indirectSource = w
		Wave/t output = key
		output[] = indirectSource[p][keycol]
	else
		Wave indirectSource2 = w
		multithread key[] = indirectSource2[p][keycol]
 	endif
 
	valindex=p
 	if(reversed)
 		sort/a/r key,key,valindex
 	else
		sort/a key,key,valindex
 	endif
 
	if(type == 0)
		duplicate/free indirectSource, M_newtoInsert
		Wave/t output = M_newtoInsert
	 	output[][] = indirectSource[valindex[p]][q]
	 	indirectSource = output
	else
		duplicate/free indirectSource2, M_newtoInsert
	 	multithread M_newtoinsert[][] = indirectSource2[valindex[p]][q]
		multithread indirectSource2 = M_newtoinsert
 	endif 
End

Function/T MonocleIntegrationsInUse(FormatToUse)
	string FormatToUse
	string ExistingIntegrations
	string ListOfIntegrationsInUse
	//store current Data Folder
	String CurrentDF=getdatafolder(1)
	//move to the integration folder
	setdatafolder(ioliteDFpath("integration",""))
	//get a list of the waves starting with "m_" in this folder (if this ever leads to errors with other waves named this way then might need to start using the options string as well - see help for wavelist())
	ExistingIntegrations=wavelist("m_*",";","")
	setdatafolder(CurrentDF)	//move back to the original data folder
	ListOfIntegrationsInUse = ExistingIntegrations
	//Now check if any of these are empty - if they are then remove them from the list
	//To do this use a loop, reference each numeric matrix in turn check if it only has one row and column
	variable i
	variable NoOfIntegrationTypes
	string ThisIntegrationName
	NoOfIntegrationTypes = ItemsInList(ExistingIntegrations, ";")
	for(i = 0;i < NoOfIntegrationTypes;i += 1)	// Initialize variables;continue test
		ThisIntegrationName = StringFromList(i, ExistingIntegrations, ";")
		wave NumericMatrix = $IoliteDFpath("Integration", ThisIntegrationName)
		if(DimSize(NumericMatrix, 0) == 1 || DimSize(NumericMatrix, 1) == 1)
			ListOfIntegrationsInUse = RemoveFromList(ThisIntegrationName, ListOfIntegrationsInUse, ";", 0)
		endif
	endfor
	if(cmpstr(FormatToUse, "with m_") == 0)
		return ListOfIntegrationsInUse
	else
		//Need to make sure that only the first to characters are removed from each list item (it's possible the standard will have a name starting with "M_")
		//First remove the first "m_" in the list
		ListOfIntegrationsInUse = ReplaceString("m_", ListOfIntegrationsInUse, "", 0, 1)
		//Now replace all instances of ";m_" with ";"
		ListOfIntegrationsInUse = ReplaceString(";m_", ListOfIntegrationsInUse, ";", 0)
		return ListOfIntegrationsInUse
	endif
	//Note that the returned list has a semicolon after the last item
end

Function MakeAllCellSpaceImages()

	DoWindow/F $MonocleTargetWindow()
	
	// If the window doesn't exist, take action
	If (V_flag != 1)
		DoAlert/T="Monocle" 0, "Please open the cell space window from iolite and then try again."
		Return -1	
	EndIf	

	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O/S root:Packages:Monocle:CellSpaceImages
	
	SVAR ListOfOutputChannels = $ioliteDFpath("Output", "ListOfOutputChannels")
	
	Variable ChannelIndex
	
	Wave Stage_X = $IoliteDFpath("CellSpaceImages","StageX_Interped")	//ref to interpolated stage x coordinates in the input folder
	Wave Stage_Y = $IoliteDFpath("CellSpaceImages","StageY_Interped")	//ref to interpolated stage y coordinates in the input folder
	Wave SpotSize = $IoliteDFpath("CellSpaceImages","SpotSize_Interped")//ref to interpolated spot size waves	
	Wave SampleImage = $ioliteDFpath("CellSpaceImages", "CellSpace_Sample")
	Wave SlitAngle = $ioliteDFpath("CellSpaceImages", "SlitAngle_Interped") // ref to interpolated slit angle wave
	NVar SlitWidth = $ioliteDFpath("LaserLogs", "SlitWidth")
	NVar SlitHeight = $ioliteDFpath("LaserLogs", "SlitHeight")	
	NVar SpotIsSlit = $ioliteDFpath("LaserLogs", "SpotIsSlit")	
	
	For (ChannelIndex = 0; ChannelIndex < ItemsInList(ListOfOutputChannels); ChannelIndex+=1)
	
		String ThisChannelName = StringFromList(ChannelIndex, ListOfOutputChannels)
		
		Print "[Monocle] Creating cell space map for", ThisChannelName
		Wave ThisChannel = $ioliteDFpath("CurrentDRS", ThisChannelName)
		If (!WaveExists(ThisChannel))
			Continue
		EndIf
		
		Duplicate/O SampleImage, $("root:Packages:Monocle:CellSpaceImages:"+ThisChannelName)
		Wave ThisCellSpaceImage = $("root:Packages:Monocle:CellSpaceImages:"+ThisChannelName)
		
		String FillInMatrixCommand = ""
		
		// If Iolite 3+
		If (GrepString(ks_VersionOfThisIcpmsPackage, "3.")==1)		
			If (SpotIsSlit)
				FillInMatrixCommand = "FillInMatrix($IoliteDFpath(\"CellSpaceImages\",\"StageX_Interped\"),"
				FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"StageY_Interped\"),"
				FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"SpotSize_Interped\"),"
				FillInMatrixCommand += "$ioliteDFpath(\"CurrentDRS\",\""+ ThisChannelName+ "\"), "
				FillInMatrixCommand += "$(\"root:Packages:Monocle:CellSpaceImages:"+ ThisChannelName+"\"),"
				FillInMatrixCommand += "width=" + num2str(SlitWidth) +","
				FillInMatrixCommand += "height=" + num2str(SlitHeight) + ","
				FillInMatrixCommand += "SlitAngle=$ioliteDFpath(\"CellSpaceImages\",\"SlitAngle_Interped\"))"
			Else
				FillInMatrixCommand = "FillInMatrix($IoliteDFpath(\"CellSpaceImages\",\"StageX_Interped\"),"
				FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"StageY_Interped\"),"
				FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"SpotSize_Interped\"),"
				FillInMatrixCommand += "$ioliteDFpath(\"CurrentDRS\",\""+ ThisChannelName+ "\"), "
				FillInMatrixCommand += "$(\"root:Packages:Monocle:CellSpaceImages:"+ ThisChannelName+"\"))"
			EndIf
		// If Iolite 2
		Else
			FillInMatrixCommand = "FillInMatrix($IoliteDFpath(\"CellSpaceImages\",\"StageX_Interped\"),"
			FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"StageY_Interped\"),"
			FillInMatrixCommand += "$IoliteDFpath(\"CellSpaceImages\",\"SpotSize_Interped\"),"
			FillInMatrixCommand += "$ioliteDFpath(\"CurrentDRS\",\""+ ThisChannelName+ "\"), "
			FillInMatrixCommand += "$(\"root:Packages:Monocle:CellSpaceImages:"+ ThisChannelName+"\"))"
		EndIf
		
		Execute/Q/Z FillInMatrixCommand
		
		If (V_Flag != 0)
			Print "[Monocle] There was a problem making your CellSpace images..."
			Print FillInMatrixCommand
		EndIf
	EndFor
End

// This function uses the selected stats method in iolite to work out the mean/uncert
// of an ROI in a particular channel.
Function MonocleStats(ChannelWave, MaskWave, MeanValue, UncertValue, SumValue)
	Wave ChannelWave, MaskWave
	Variable &MeanValue, &UncertValue, &SumValue
	
	NewDataFolder/O/S $("root:Packages:Monocle:Temp")
	
	If (!WaveExists(ChannelWave) || !WaveExists(MaskWave))
		print "Had a problem with updating stats... channel or mask doesn't exist?"
		MeanValue = nan
		UncertValue = nan
		Return 0
	EndIf
	
	Duplicate/O ChannelWave, TempChannelWave
	TempChannelWave = MaskWave[p][q] == 0 ? ChannelWave[p][q] : nan
	
	Duplicate/O ChannelWave, SumChannelWave
	SumChannelWave = MaskWave[p][q] == 0 ? ChannelWave[p][q] : 0
		
	//Redimension/N=(dimsize(ChannelWave,0),dimsize(ChannelWave,1)) MaskWave
	
	If (DimSize(ChannelWave,0) > 1 && DimSize(ChannelWave,1) > 1)
		Redimension/N=(dimsize(ChannelWave,0),dimsize(ChannelWave,1)) MaskWave
	EndIf
	
	If (DimSize(ChannelWave,0) != DimSize(MaskWave,0) || DimSize(ChannelWave,1) != DimSize(MaskWave,1))
		Print "Had a problem with updating stats... dimensions are 0?"
		MeanValue = nan
		UncertValue = nan
		Return 0
	EndIf
	
	Variable NumberOfPoints = 0
	
	String MethodForStats = GetStatsMethod(MonocleSelectionGroup())
	If (MonocleUsingCellSpace())
		MethodForStats = "Mean no outlier reject"
	EndIf
	
	
	
	//print "MethodForStats = ", MethodForStats
	StrSwitch (MethodForStats)
	
		Case "Mean no outlier reject":
			ImageStats/M=0/R=MaskWave ChannelWave		
			MeanValue = V_avg
			UncertValue = V_sdev*2/sqrt(V_npnts)
			NumberOfPoints = V_npnts
			SumValue = sum(SumChannelWave)
			Break
		Case "Mean with 2 S.D. outlier reject":
			ImageStats/M=0/R=MaskWave ChannelWave
			TempChannelWave = TempChannelWave < (V_avg - (2*V_sdev)) ? NaN : TempChannelWave
			TempChannelWave = TempChannelWave > (V_avg + (2*V_sdev)) ? NaN : TempChannelWave
			SumChannelWave = SumChannelWave < (V_avg - (2*V_sdev)) ? 0 : SumChannelWave
			SumChannelWave = SumChannelWave > (V_avg + (2*V_sdev)) ? 0 : SumChannelWave
			ImageStats/M=0/R=MaskWave TempChannelWave
			MeanValue = V_avg
			UncertValue = V_sdev*2/sqrt(V_npnts)
			NumberOfPoints = V_npnts
			SumValue = sum(SumChannelWave)
			Break
		Case "Mean with 3 S.D. outlier reject":
			ImageStats/M=0/R=MaskWave ChannelWave
			TempChannelWave = TempChannelWave < (V_avg - (3*V_sdev)) ? NaN : TempChannelWave
			TempChannelWave = TempChannelWave > (V_avg + (3*V_sdev)) ? NaN : TempChannelWave
			SumChannelWave = SumChannelWave < (V_avg - (3*V_sdev)) ? 0 : SumChannelWave
			SumChannelWave = SumChannelWave > (V_avg + (3*V_sdev)) ? 0 : SumChannelWave			
			ImageStats/M=0/R=MaskWave TempChannelWave
			MeanValue = V_avg
			UncertValue = V_sdev*2/sqrt(V_npnts)
			NumberOfPoints = V_npnts
			SumValue = sum(SumChannelWave)
			Break		
		Case "Median with MAD error no outlier reject":
			Print "[Monocle] This feature isn't implemented yet. Tell Joe."
			Break
		Case "Median with MAD error 2 S.D. outlier reject":
			Print "[Monocle] This feature isn't implemented yet. Tell Joe."		
			Break
		Case "Median with MAD error 3 S.D. outlier reject":
			Print "[Monocle] This feature isn't implemented yet. Tell Joe."
			Break
	EndSwitch
	
	If (MonocleUsingCellSpace())
		// If using cell space we have way more samples than we ought to so the 2se is under estimated (i.e. the 1/sqrt(N)
		// Cell Space uses 8 pixels per spot size in both dimensions be default OR the resolution of the mapped image it is overlain on
		// To convert to the equivalent # of normal samples?
		// Whole Pyx 3 is ~ 16.5M points in cell space
		// Whole Pyx 3 is ~ 51K points in from selections
		// A factor of 323
		// Scale factor is 0.5823 (um/pixel?) => 10 um = 17 pixels 
		// Whole garnet is ~ 563840 points in cell space
		// Whole garnet is ~ 25100 points in from selections
		// A factor of 22.46...
		// Spot size for this was 10 x 10 square
		// 10 / 8 = 1.25
		// Rep rate was 50 Hz
		// Speed was 115 um/s
		// Pixels per spot = 64
		// Duty cycle = 193.76 ms		
		// Moved in 1 duty cycle = 22.28 um
		// dimensions of cell space image = 1756 rows x 1246 columns = 2,187,976
		// dimensions of selections image = 220 rows x 210 columns = 46,200
		
		// Hmmmmm not exactly clear, but for measurements that don't overlap spatially, you'd think it would need to be adjusted by
		// a factor of 8*8 = 64. However, if measurements overlap spatially this would be less... kind of tricky to work out.
		
		// Actually, not always 8x8, that's just the default if not using a "mapped" image.
		// Note: the value below is hard-coded for some stuff Joe was working on. It is wrong for you!!!
		Print "[Monocle] Warning -- 2se was calculated using a value Joe hardcoded for some of his stuff. Tell him to fix it."
		UncertValue =  UncertValue*sqrt(NumberOfPoints)/(sqrt(NumberOfPoints/323)) // Pyx
//		UncertValue =  UncertValue*sqrt(NumberOfPoints)/(sqrt(NumberOfPoints/43)) // MnCrust
//		UncertValue = UncertValue*sqrt(NumberOfPoints)/(sqrt(NumberOfPoints/
	EndIf
End

Function/T MonocleSelectionGroup()
	NewDataFolder/O/S root:Packages:Monocle	
	SVAR SelectionGroup = root:Packages:Monocle:SelectionGroup	
	
	If (!SVar_Exists(SelectionGroup))
		String/G SelectionGroup
		SVAR SelectionGroup = root:Packages:Monocle:SelectionGroup	
	EndIf
	
	If (MonocleUsingCellSpace())
		SVAR CSMaskIntegration = root:Packages:iolite:CellSpaceImages:CurrLasMskInteg
		If (!SVar_exists(CSMaskIntegration))
			Print "[Monocle] Error getting cell space selection group... do you have one selected?"
			Return ""
		EndIf
	
		SelectionGroup = CSMaskIntegration
	EndIf
		
	Return SelectionGroup
End

Function CellSpaceResolution()

End

Function MergeROIs(ROIsToMerge, [NewROIName])
	String ROIsToMerge, NewROIName

	SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
	
	If (ParamIsDefault(NewROIName))
		String ROIName = "ROI"			
		Prompt ROIName, "Enter a name for this ROI: "
			
		// Prompt for a name:
		Do
			DoPrompt "New ROI", ROIName
			If (V_Flag)
				Return -1 // Cancelled.. should probably do something else here?
			EndIf
		While (FindListItem(ROIName, ListOfROIs) != -1)	
		
		NewROIName = ROIName
	EndIf
	
											
	NewDataFolder/O/S root:Packages:Monocle:Masks
	
	Make/O/U/B/N=(1,1) $(NewROIName+"_Mask")
	Wave MergedMask = $(NewROIName+"_Mask")
	

	Variable i
	For (i = 0; i < ItemsInList(ROIsToMerge); i+=1)
		String ThisMaskName = StringFromList(i, ROIsToMerge)
		
		Wave ThisMask = $("root:Packages:Monocle:Masks:"+ThisMaskName+"_Mask")
		
		If (!WaveExists(ThisMask))
			Print "[Monocle] You tried to merge a mask that doesn't seem to exist... I'm going to continue, but you've been warned!"
			Continue
		EndIf
	
		If (i == 0)
			Redimension/N=(dimsize(ThisMask,0), dimsize(ThisMask,1)) MergedMask
			MergedMask = 1
		EndIf
		
		MergedMask = MergedMask & ThisMask
			
	EndFor

	ListOfROIs += NewROIName +";"
		
	// Update data table?			
	UpdateMonocleTable(ROIsToUpdate=NewROIName)
	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
	MetaDataTable[%$NewROIName][%$"CreatedBy"] = "Merging " + ROIsToMerge
End
	
Function DismantleROI(ROIName)
	String ROIName
	
	SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
	
	NewDataFolder/O/S root:Packages:Monocle:Temp
	
	Wave ThisROI = $("root:Packages:Monocle:Masks:"+ROIName+"_Mask")
	
	ImageAnalyzeParticles stats ThisROI
	Wave W_SpotX, W_SpotY

	Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"
		
	Variable i
	For (i = 0; i < numpnts(W_SpotX); i+=1)

		ImageSeedFill/B=1 seedP=W_SpotX[i], seedQ=W_SpotY[i], target=0, srcwave = ThisROI
		Wave M_SeedFill
		String ThisSubName = ROIName+"_Sub"+num2str(i)
		
		MoveWave M_SeedFill, $("root:Packages:Monocle:Masks:"+ThisSubName + "_Mask")
		ListOfROIs += ThisSubName + ";"
		UpdateMonocleTable(ROisToUpdate=ThisSubName)
		MetaDataTable[%$ThisSubName][%$"CreatedBy"] = "Dismantling " + ROIName		
	EndFor	
End

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Common Inspector Functions
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function InspectorHook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	NVAR InspectorX = root:Packages:Monocle:InspectorX
	NVAR InspectorY = root:Packages:Monocle:InspectorY					
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType	
	NVAR MakingROI = root:Packages:Monocle:MakingROI
	
	SVAR InspectorShape = root:Packages:Monocle:InspectorShape
	NVAR InspectorWidth = root:Packages:Monocle:InspectorWidth
	NVAR InspectorHeight = root:Packages:Monocle:InspectorHeight
	NVAR InspectorAngle = root:Packages:Monocle:InspectorAngle
	
	Switch (s.eventCode)
		Case 4:
			If (MakingROI)
				Return 0
			EndIf
			
			If (ItemsInList(ActiveInspectors) == 0)
				Return 0
			EndIf
			
//			Variable timerRef = startMSTimer
//			Print "Starting main update hook"
			
			// Store the axis coordinates of the mouse location:			
			if (cmpstr(SelectedMapType, "Cell space")==0)			
				InspectorX = AxisValFromPixel(MonocleTargetWindow(), "top", s.mouseLoc.h)
			Else
				InspectorX = AxisValFromPixel(MonocleTargetWindow(), "bottom", s.mouseLoc.h)
			EndIf
			InspectorY = AxisValFromPixel(MonocleTargetWindow(), "left", s.mouseLoc.v)

			Wave target
			If (cmpstr(SelectedMapType, "Cell space") == 0)
				Wave target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
			Else
				Wave target =  $GetImageWave(TopImageGraph())
			EndIf			
			
			Variable LowerX = DimOffset(target,0) + InspectorWidth/2
			Variable UpperX = DimOffset(target,0) + DimDelta(target, 0)*DimSize(target, 0) -InspectorWidth/2
			Variable LowerY = DimOffset(target, 1) + InspectorHeight/2
			Variable UpperY = DimOffset(target,1) + DImDelta(target,1)*DimSize(target,1) - InspectorHeight/2
			
			If (InspectorX > UpperX || InspectorX < LowerX || InspectorY > UpperY || InspectorY < LowerY)
				Return 0
			EndIf
			
			Wave InspectorROIx = root:Packages:Monocle:InspectorROIx
			Wave InspectorROIy = root:Packages:Monocle:InspectorROIy
		
			StrSwitch (InspectorShape)
				Case "Ellipse":
					InspectorROIx = InspectorX + InspectorWidth*cos(2*p*pi/100)*cos(InspectorAngle*pi/180) - InspectorHeight*sin(2*p*pi/100)*sin(InspectorAngle*pi/180)
					InspectorROIy = InspectorY + InspectorWidth*cos(2*p*pi/100)*sin(InspectorAngle*pi/180) + InspectorHeight*sin(2*p*pi/100)*cos(InspectorAngle*pi/180)
					Break
				Case "Rectangle":
					InspectorROIx = InspectorX + InspectorWidth*(abs(cos(2*p*pi/100))*cos(2*p*pi/100)+abs(sin(2*pi*p/100))*sin(2*pi*p/100))*cos(InspectorAngle*pi/180) - InspectorHeight*(abs(cos(2*p*pi/100))*cos(2*p*pi/100)-abs(sin(2*pi*p/100))*sin(2*pi*p/100))*sin(InspectorAngle*pi/180)
					InspectorROIy = InspectorY + InspectorWidth*(abs(cos(2*p*pi/100))*cos(2*p*pi/100)+abs(sin(2*pi*p/100))*sin(2*pi*p/100))*sin(InspectorAngle*pi/180) + InspectorHeight*(abs(cos(2*p*pi/100))*cos(2*p*pi/100)-abs(sin(2*pi*p/100))*sin(2*pi*p/100))*cos(InspectorAngle*pi/180)
					Break					
			EndSwitch
			
			SVAR InspectorColor = root:Packages:Monocle:InspectorColor
			Variable r, g, b
			sscanf InspectorColor, "(%i,%i,%i)", r, g, b
			ModifyGraph/W=$MonocleTargetWindow() rgb(InspectorROIy)=(r,g,b)
						
			NewDataFolder/O/S root:Packages:Monocle
			KillWaves/Z root:Packages:Monocle:M_ROIMask
			//ImageBoundaryToMask ywave=InspectorROIy, xwave=InspectorROIx, width=dimsize(target,0), height=dimsize(target,1), scalingWave=target, seedX=InspectorX, seedY=InspectorY
			ImageBoundaryToMask ywave=InspectorROIy, xwave=InspectorROIx, width=dimsize(target,0), height=dimsize(target,1), scalingWave=target, seedX=dimoffset(target,0), seedY=dimoffset(target,1)
			Wave M_ROIMask
			//Redimension/D M_ROIMask
			//M_ROIMask[][] = M_ROIMask[p][q] == 0 ? nan : M_ROIMask[p][q]
			
			// Call the update functions for each of the active inspectors:
			Variable InspectorIndex
			For ( InspectorIndex = 0; InspectorIndex < ItemsInList(ActiveInspectors); InspectorIndex += 1)
				String ThisInspector = StringFromList(InspectorIndex, ActiveInspectors)
				//print "Updating", ThisInspector
				
				String FuncInfoStr = FunctionInfo(ThisInspector+"Inspector_Update")
				If (strlen(FuncInfoStr) == 0)
					Print FuncInfoStr, "not found."
					Continue
				EndIf	
				
				FUNCREF ProtoInspector InspectorUpdateFunc = $(ThisInspector + "Inspector_Update")
				InspectorUpdateFunc()
			EndFor
			
//			Variable microSecs = stopMSTimer(timerRef)
			
//			print "Update hook took", microSecs, "microseconds"
			
			// Originally: 2.18e6 us per update.
			// Now: ~ 10 times less!
			
		Break
		
		// Should also do a window closed hook to call the "_Close()" of each inspector
		Case 2:
			For ( InspectorIndex = 0; InspectorIndex < ItemsInList(ActiveInspectors); InspectorIndex += 1)
				ThisInspector = StringFromList(InspectorIndex, ActiveInspectors)
				print "Closing", ThisInspector
				
				FuncInfoStr = FunctionInfo(ThisInspector+"Inspector_Close")
				If (strlen(FuncInfoStr) == 0)
					Print FuncInfoStr, "not found."
					Continue
				EndIf				
				
				FUNCREF ProtoInspector InspectorCloseFunc = $(ThisInspector + "Inspector_Close")
				InspectorCloseFunc()
			EndFor			
			Break
			
		Case 5: // Mouse up: Create a new ROI based on the current position
			//print s.eventMod, " = event mod"
			// If Cmd (Mac) or Ctrl (Win) isn't down, return
			If  ((s.eventMod & 2^3) == 0)
				Return 0
			EndIf
			
			If (s.eventMod == 10) // If shift is also down, create a new ROI by doing a sort of seed fill
				Wave ROIMask = $("root:Packages:Monocle:M_ROIMask")				
				NewRegionFromSeed2(ROIMask)
				Return 0
			EndIf
		
			NVAR MakingROI = root:Packages:Monocle:MakingROI
			If (MakingROI)
				Return 0
			EndIf
		
			String ROIName="MyROI"
			Prompt ROIName, "Enter a name for this ROI (no spaces): "
			DoPrompt "Name ROI", ROIName
			If (V_flag)
				Return 0
			EndIf
			
			NewDataFolder/O/S root:Packages:Monocle:Masks
			Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
			If (WaveExists(M_ROIMask))
				String ROIDest = ROIName + "_Mask"	
				Duplicate/O M_ROIMask, $ROIDest
				Wave ROIDestWave = $ROIDest
				
				Redimension/B/U ROIDestWave
				SetScale/P x, dimoffset(ROIDestWave,0), dimdelta(ROIDestWave,0), "", ROIDestWave
				SetScale/P y, dimoffset(ROIDestWave,1), dimdelta(ROIDestWave, 1), "", ROIDestWave
				//ROIDestWave[][] = ROIDestWave[p][q] == 255 ? 1 : 0
				
				SVAR ListOfROIs = $"root:Packages:Monocle:ListOfROIs"
				ListOfROIs += ROIName + ";"
				UpdateMonocleTable(ROIsToUpdate=ROIName)
				Wave/T MetaDataTable = $"root:Packages:Monocle:MetaDataTable"	
				MetaDataTable[%$ROIName][%$"CreatedBy"] = "Loupe"
			EndIf
						
			Break
	EndSwitch
	
	Return 0
End

Function ProtoInspector()
End

Function MonocleCalculateEllipse(EllipseWave_X, EllipseWave_Y, Average_X, Stdev_X, Average_Y, Stdev_Y, ErrorCorrelation)
	wave EllipseWave_X
	wave EllipseWave_Y
	variable Average_X
	variable Stdev_X
	variable Average_Y
	variable Stdev_Y
	variable ErrorCorrelation
	//Convert the stdev values from a 2 sigma (approx. 95% confidence) univariate to a 95% confidence bivariate (2 sigma is only approx. 86% confidence for a bivariate distribution)
	Stdev_X = Stdev_X * 2.44765 / 2
	Stdev_Y = Stdev_Y * 2.44765 / 2
	variable PointsInEllipse
	PointsInEllipse = numpnts(EllipseWave_X)
	//First check that both waves are the same length
	if(numpnts(EllipseWave_Y) != PointsInEllipse)
		printabort("This function was passed two waves of unequal length. The troops have panicked. Hope is lost")
	endif
	EllipseWave_Y = Stdev_Y*cos(2*pi*p/(PointsInEllipse-1) - asin(ErrorCorrelation))+Average_Y
	EllipseWave_X=Stdev_X*sin(2*pi*p/(PointsInEllipse-1))+Average_X
end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Histogram Inspector
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function HistogramInspector_Launch()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	NewDataFolder/O/S root:Packages:Monocle
	
	// Create the window and set the hook for closing
	DoWindow/F HistogramInspector
	If (V_Flag == 1)
		KillWindow HistogramInspector
	EndIf
	
	KillDataFolder/Z root:Packages:Monocle:Histogram
	NewDataFolder/O/S root:Packages:Monocle:Histogram
	
	Variable/G HistogramBins = 100
	Variable/G HistogramStart = nan
	Variable/G HistogramStop = nan
		
	NewPanel/FLT/N=HistogramInspector/K=1/W=(200, 200, 750, 550)
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=HistogramInspector fixedSize=0
	
	Make/O/N=100 bins
	Make/O/N=100 counts
	
	Wave InspectorROIx = root:Packages:Monocle:InspectorROIx
	Wave InspectorROIy = root:Packages:Monocle:InspectorROIy
	
	RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
	
	If (GrepString(SelectedMapType, "(?i)Cell space"))
		AppendToGraph/T/W=$MonocleTargetWindow() InspectorROIy vs InspectorROIx	
	Else
		AppendToGraph/W=$MonocleTargetWindow() InspectorROIy vs InspectorROIx
	EndIf
	
	Display/N=HistogramGraph/HOST=HistogramInspector/FG=(FL,FT,FR,FB) counts
	ModifyGraph mode=5, hbFill=2, rgb=(17476, 17476, 17476)
	// Set appearance of traces:	
	
	// Set graph properties:
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	// Label axes according to which plot we're making:
	Label left "Counts"
	Label bottom "Value"
	
	SetWindow HistogramInspector hook(HistogramInspectorHook)=HistogramInspector_Hook	
	
	SetActiveSubwindow _endfloat_
End

Function HistogramInspector_Update()
	//Print "HistogramInspector_Update()"
	NewDataFolder/O/S root:Packages:Monocle:Histogram	
	// Plot an ROI from the current mouse location
	NVAR InspectorX = root:Packages:Monocle:InspectorX
	NVAR InspectorY = root:Packages:Monocle:InspectorY
	
	NVAR HistogramStart = $("root:Packages:Monocle:Histogram:HistogramStart")
	NVAR HistogramStop= $("root:Packages:Monocle:Histogram:HistogramStop")
	NVAR HistogramBins = $("root:Packages:Monocle:Histogram:HistogramBins")	

	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	Wave target
	If (cmpstr(SelectedMapType, "Cell space") == 0)
		Wave target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
	Else
		Wave target =  $GetImageWave(TopImageGraph())
	EndIf
	
	Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
	
	// Make a copy of the target map and multipy it by the mask
	Duplicate/O target, tempTarget
	tempTarget = M_ROIMask[p][q] == 0 ? target[p][q] : nan
	
//	WaveStats/Z/Q tempTarget
	
	ImageStats/M=0/R=M_ROIMask target
	
	Variable histstart = numtype(HistogramStart) == 2? V_min : HistogramStart
	Variable histend = numtype(HistogramStop) == 2? V_max : HistogramStop
		
	Variable histstep = (histend-histstart)/HistogramBins	
	
	Wave counts = root:Packages:Monocle:Histogram:counts
	Histogram/B={histstart,histstep,HistogramBins} tempTarget, counts

	SetAxis/W=HistogramInspector#HistogramGraph/A left
	SetAxis/W=HistogramInspector#HistogramGraph/A bottom
//	WaveInfo
	

End

Function HistogramInspector_Options()
	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O/S root:Packages:Monocle:Histogram
	
	NVAR HistogramStart = $("root:Packages:Monocle:Histogram:HistogramStart")
	NVAR HistogramStop= $("root:Packages:Monocle:Histogram:HistogramStop")
	NVAR HistogramBins = $("root:Packages:Monocle:Histogram:HistogramBins")		
	
	Variable HistBins = HistogramBins
	Variable HistStart = HistogramStart
	Variable HistStop = HistogramStop
		
	Prompt HistStart, "Histogram start (nan for min):"
	Prompt HistStop, "Histogram stop (nan for max):"
	Prompt HistBins, "Number of bins:"
	
	DoPrompt "Histogram Inspector Options", HistStart, HistStop, HistBins
	
	If (V_flag == 0) // not cancelled
		HistogramStart = HistStart
		HistogramStop = HistStop
		HistogramBins = HistBins
	EndIf
End

Function HistogramInspector_Close()
	// Clean up after the inspector, i.e. remove from the active list, kill some waves?
End

Function HistogramInspector_Hook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	
	Switch (s.eventCode)
		Case 2: // Closed
			ActiveInspectors = RemoveFromList("Histogram", ActiveInspectors)
			If (ItemsInList(ActiveInspectors) == 0)
				RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
			EndIf			
		Break
	EndSwitch
End

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// U-Pb Wetherill Inspector
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//########################################################
// Shared concordia related functions
//########################################################

//------------------------------------------------------------------------
// Function to generate some concordia waves
//------------------------------------------------------------------------
Function MonocleGenerateConcordia(ConcName, ConcStartAge, ConcStopAge, [NoOfPoints, NoOfMarkers, doTW, ConcFolder])
	String ConcName, ConcFolder
	Variable ConcStartAge, ConcStopAge, NoOfMarkers, NoOfPoints, doTW
	

	// Store the current data folder:
	String PreviousDF = GetDataFolder(1)
	
	// Check all of the optional parameters:
	
	// If a folder is specified, switch to it:
	If ( !ParamIsDefault(ConcFolder) )
		SetDataFolder ConcFolder
	EndIf
	
	// Handle defaults for optional params:
	If ( ParamIsDefault(NoOfMarkers) )
		NoOfMarkers = 10
	EndIf
	
	If ( ParamIsDefault(NoOfPoints) )
		NoOfPoints = 10000
	EndIf
	
	If ( ParamIsDefault(doTW) )
		doTW = 0
	EndIf
	
	Make/O/N=(NoOfPoints) $(ConcName + "X"), $(ConcName + "Y")
	Make/O/N=(NoOfMarkers) $(ConcName + "MarkerX"), $(ConcName + "MarkerY")
	
	Wave cX = $(ConcName + "X")
	Wave cY = $(ConcName + "Y")
	Wave cMX = $(ConcName + "MarkerX")
	Wave cMY = $(ConcName + "MarkerY")

	Variable l235 = 9.8485e-10
	Variable l238 = 1.55125e-10
	Variable l232 = 0.49475e-10
	Variable k = 137.88
	
	Variable i=0, ti = 0
	
	// Compute ratios for main concordia trace:
	For ( i = 0; i < NoOfPoints; i = i + 1 )
		ti = ((ConcStopAge-ConcStartAge)/NoOfPoints)*i + ConcStartAge
		If (!doTW)
			cX[i] = exp(l235*ti) - 1
			cY[i] = exp(l238*ti) - 1
		Else
			cX[i] = 1/(exp(l238*ti) - 1)
			cY[i] = (1/k)*(exp(l235*ti)-1)/(exp(l238*ti)-1)		
		EndIf
	EndFor
	
	// Compute ratios for markers:
	For ( i = 0; i < NoOfMarkers; i = i + 1 )
		ti = ((ConcStopAge-ConcStartAge)/NoOfMarkers)*i + ConcStartAge
		If (!doTW)
			cMX[i] = exp(l235*ti) - 1
			cMY[i] = exp(l238*ti) - 1
		Else
			cMX[i] = 1/(exp(l238*ti) - 1)
			cMY[i] = (1/k)*(exp(l235*ti)-1)/(exp(l238*ti)-1)		
		EndIf
	EndFor
	
	// Restore previous data folder:
	SetDataFolder PreviousDF
End

// This function creates the inspector as a panel similar to VizualAge
// and adds the update function to the list of functions called by a main hook
// setup on the target window.
Function WetherillInspector_Launch()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	// Create the window and set the hook for closing
	DoWindow/F WetherillInspector
	If (V_Flag == 1)
		KillWindow WetherillInspector
	EndIf
	
	KillDataFolder/Z root:Packages:Monocle:Wetherill
	NewDataFolder/O/S root:Packages:Monocle:Wetherill
	
	MonocleGenerateConcordia("WetherillConc", 0, 5e9, NoOfPoints=1000, NoOfMarkers=5e9/100e6, doTW=0, ConcFolder="root:Packages:Monocle:Wetherill")
	Wave ConcX = $"WetherillConcX", ConcY = $"WetherillConcY"
	Wave ConcMarkerX = $"WetherillConcMarkerX", ConcMarkerY = $"WetherillConcMarkerY"
	
	NewPanel/FLT/N=WetherillInspector/K=1/W=(200, 200, 750, 550)
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=WetherillInspector fixedSize=0

	NewDataFolder/O/S root:Packages:Monocle:Wetherill
	
	Display/N=WetherillGraph/HOST=WetherillInspector/FG=(FL,FT,FR,FB) ConcY vs ConcX
	AppendToGraph ConcMarkerY vs ConcMarkerX
	
	// Create tags:
	Variable i
	For (i = 1; i < 5e9/(100e6); i = i +1)
		String tagStr = "tag" + num2str(i)
		String tagValue = num2str(100*i) + " Ma"
		Tag/N=$tagStr/A=RC/F=0/Z=1/I=1/B=1/X=-0.5/Y=0.5/L=0/AO=0 WetherillConcMarkerY, i, tagValue
		//Tag/C/N=text0/L=0 WetherillConcX, 0,"dsfasdf"
	EndFor
	
	// Generate waves for live concordia data to be updated by the hook:
	Make/O/N=100 LiveEllipseX, LiveEllipseY
	LiveEllipseX = 0
	LiveEllipseY = 0
	AppendToGraph LiveEllipseY vs LiveEllipseX

	// Set appearance of traces:	
	ModifyGraph lsize[0]=1.5,rgb[0]=(0,0,0) 
	ModifyGraph mode[1]=3, marker[1]=19, msize[1]=5
	//ModifyGraph mode(LiveEllipseY)=3,marker(LiveEllipseY)=5,rgb(LiveEllipseY)=(0,0,65535), mode(LiveEllipseY) =0, lsize(LiveEllipseY)=2
	
	// Set graph properties:
	SetAxis left 0,1
	SetAxis bottom 0,10
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	// Label axes according to which plot we're making:
	Label left "\\S206\\MPb \\Z28/\\M \\S238\\MU"
	Label bottom "\\S207\\MPb \\Z28/\\M \\S235\\MU"
	
	SetWindow WetherillInspector hook(WetherillInspectorHook)=WetherillInspector_Hook	
	
	SetActiveSubwindow _endfloat_
End

Function WetherillInspector_Update()
	Print "WetherillInspector_Update()"
		
	// Clear all traces
	String TracesToKeep = "WetherillConcY;WetherillConcMarkerY;LiveEllipseY;"
	String AllTraces = TraceNameList("WetherillInspector#WetherillGraph", ";", 1)	
	String TracesToRemove = RemoveFromList(TracesToKeep, AllTraces)	
	
	Variable TraceIndex
	For (TraceIndex = 0; TraceIndex < ItemsInList(TracesToRemove); TraceIndex+=1)
		RemoveFromGraph/Z/W=WetherillInspector#WetherillGraph $StringFromList(TraceIndex, TracesToRemove)
	EndFor
	
	// Plot all the stored ROIs
	Wave MonocleTable = root:Packages:Monocle:MonocleTable
	Wave/T MonocleROINames = root:Packages:Monocle:MonocleROINames
	
	// Find which columns to use for each with FindDimLabel
	
	Variable i
	For (i = 0; i < dimsize(MonocleTable, 0); i+=1)
		Variable Pb206_U238
	EndFor
	
	// Plot an ROI from the current mouse location
	Wave EllipseX = root:Packages:Monocle:Wetherill:LiveEllipseX
	Wave EllipseY = root:Packages:Monocle:Wetherill:LiveEllipseY
	
	Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
	
	Wave Ratio6_38, Ratio7_35
	
	If (MonocleUsingCellSpace())
		Wave Ratio6_38 = root:Packages:Monocle:CellSpaceImages:Final206_238
		Wave Ratio7_35 = root:Packages:Monocle:CellSpaceImages:Final207_235
	Else
		Wave Ratio6_38 = root:Packages:Monocle:SelectionsImages:Final206_238_Map
		Wave Ratio7_35 = root:Packages:Monocle:SelectionsImages:Final207_235_Map
	EndIf
	
	NewDataFolder/O/S root:Packages:Monocle:Wetherill
	
	// Make a copy of the target map and multipy it by the mask
//	Duplicate/O Ratio6_38, Temp6_38
//	Temp6_38 = Ratio6_38*M_ROIMask
	
//	Duplicate/O Ratio7_35, Temp7_35
//	Temp7_35 = Ratio7_35*M_ROIMask
	
	ImageStats/M=0/R=M_ROIMask Ratio6_38
	
//	ImageStats Temp6_38
	Variable AvgY = V_avg
	Variable StdevY = V_sdev
	Variable MinY = V_min
	Variable MaxY = V_max
	Variable StderrY = V_sdev/sqrt(V_npnts)
	
//	ImageStats Temp7_35
	ImageStats/M=0/R=M_ROIMask Ratio7_35
	Variable AvgX = V_avg
	Variable StdevX = V_sdev
	Variable MinX = V_min
	Variable MaxX = V_max
	Variable StderrX = V_sdev/sqrt(V_npnts)
	
	Duplicate/O Ratio6_38, Temp6_38
	Temp6_38[][] = M_ROIMask == 0 ? Ratio6_38[p][q] : nan
	Duplicate/O Ratio7_35, Temp7_35
	Temp7_35[][] = M_ROIMask == 0 ? Ratio7_35[p][q] : nan
	
	Redimension/N=(dimsize(Temp6_38,0)*dimsize(Temp6_38,1)) Temp6_38
	Redimension/N=(dimsize(Temp7_35,0)*dimsize(Temp7_35,1)) Temp7_35
	
	Temp6_38[p] = numtype(Temp7_35[p]) == 2 ? nan : Temp6_38[p]
	Temp7_35[p] = numtype(Temp6_38[p]) == 2 ? nan : Temp7_35[p]
	
	WaveTransform zapNaNs Temp6_38
	WaveTransform zapNaNs Temp7_35
//	MatrixOp/O Temp7_35NN = zapNaNs(Temp7_35)
	
	Variable corr = StatsCorrelation(Temp6_38,Temp7_35)
	
	MonocleCalculateEllipse(EllipseX, EllipseY, AvgX, 2*StderrX, AvgY, 2*StderrY, corr)
	
	Variable plotMinX = AvgX - 12*StderrX
	Variable plotMaxX = AvgX + 12*StderrX
	Variable plotMinY = AvgY - 12*StderrY
	Variable plotMaxY = AvgY + 12*StderrY
	SetAxis/W=WetherillInspector#WetherillGraph left plotMinY, plotMaxY
	SetAxis/W=WetherillInspector#WetherillGraph bottom plotMinX, plotMaxX
End

Function WetherillInspector_Close()
	// Clean up after the inspector, i.e. remove from the active list, kill some waves?
End

Function WetherillInspector_Hook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	
	Switch (s.eventCode)
		Case 2: // Closed
			Print "WetherillInspector closed..."
			ActiveInspectors = RemoveFromList("Wetherill", ActiveInspectors)
			
			If (ItemsInList(ActiveInspectors) == 0)
				RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
			EndIf						
			Break
	EndSwitch

End

Function WetherillInspector_Static()

	NewDataFolder/O/S root:Packages:Monocle:Wetherill
	NewDataFolder/O/S root:Packages:Monocle:Wetherill:StaticPlot
	
	MonocleGenerateConcordia("WetherillConc", 0, 5e9, NoOfPoints=1000, NoOfMarkers=5e9/100e6, doTW=0, ConcFolder="root:Packages:Monocle:Wetherill:StaticPlot")
	Wave ConcX = $"WetherillConcX", ConcY = $"WetherillConcY"
	Wave ConcMarkerX = $"WetherillConcMarkerX", ConcMarkerY = $"WetherillConcMarkerY"
		
	Display/N=WetherillStaticGraph ConcY vs ConcX
	AppendToGraph ConcMarkerY vs ConcMarkerX
	
	// Create tags:
	Variable i
	For (i = 1; i < 5e9/(100e6); i = i +1)
		String tagStr = "tag" + num2str(i)
		String tagValue = num2str(100*i) + " Ma"
		Tag/N=$tagStr/A=RC/F=0/Z=1/I=1/B=1/X=-0.5/Y=0.5/L=0/AO=0 WetherillConcMarkerY, i, tagValue
	EndFor

	// Set appearance of traces:	
	ModifyGraph lsize[0]=1.5,rgb[0]=(0,0,0) 
	ModifyGraph mode[1]=3, marker[1]=19, msize[1]=5
	
	// Set graph properties:
	SetAxis left 0,1
	SetAxis bottom 0,10
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	// Label axes 
	Label left "\\S206\\MPb \\Z28/\\M \\S238\\MU"
	Label bottom "\\S207\\MPb \\Z28/\\M \\S235\\MU"
	
	Wave MonocleTable = root:Packages:Monocle:DataTable
	Wave/T ROINames = root:Packages:Monocle:DataTableROINames
	
	Variable ROIIndex
	For (ROIIndex = 0; ROIIndex < dimsize(MonocleTable,0); ROIIndex += 1)
		String ROIName = ROINames[ROIIndex]
		
		Make/O/N=100 $(ROIName + "_EllipseX")
		Make/O/N=100 $(ROIName + "_EllipseY")
		Wave EllipseX = $(ROIName + "_EllipseX")
		Wave EllipseY = $(ROIName + "_EllipseY")
	
		Variable AvgX = MonocleTable[ROIIndex][%$"Final207_235"]
		Variable AvgY = MonocleTable[ROIIndex][%$"Final206_238"]
		Variable StdevX = MonocleTable[ROIIndex][%$"Final207_235_Int2SE"]
		Variable StdevY = MonocleTable[ROIIndex][%$"Final206_238_Int2SE"]
		Variable corr = MonocleTable[ROIIndex][%$"StatsCorr6_38v7_35"]
				
		MonocleCalculateEllipse(EllipseX, EllipseY, AvgX, StdevX, AvgY, StdevY, corr)
		
		AppendToGraph EllipseY vs EllipseX
		ModifyGraph rgb($(ROIName+"_EllipseY"))=(0,0,0)
		
		Tag/C/N=$ROIName/F=0/B=1 $(ROIName+"_EllipseY"), 0, ROIName
	EndFor
End

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// U-Pb Tera-Wasserburg Inspector
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// This function creates the inspector as a panel similar to VizualAge
// and adds the update function to the list of functions called by a main hook
// setup on the target window.
Function TeraWasserburgInspector_Launch()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	// Create the window and set the hook for closing
	DoWindow/F TeraWasserburgInspector
	If (V_Flag == 1)
		KillWindow TeraWasserburgInspector
	EndIf
	
	KillDataFolder/Z root:Packages:Monocle:TeraWasserburg
	NewDataFolder/O/S root:Packages:Monocle:TeraWasserburg
	
	MonocleGenerateConcordia("TWConc", 0, 5e9, NoOfPoints=1000, NoOfMarkers=5e9/100e6, doTW=1, ConcFolder="root:Packages:Monocle:TeraWasserburg")
	Wave ConcX = $"TWConcX", ConcY = $"TWConcY"
	Wave ConcMarkerX = $"TWConcMarkerX", ConcMarkerY = $"TWConcMarkerY"
	
	NewPanel/FLT/N=TeraWasserburgInspector/K=1/W=(200, 200, 750, 550)
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=TeraWasserburgInspector fixedSize=0

	NewDataFolder/O/S root:Packages:Monocle:TeraWasserburg
	
	Display/N=TWGraph/HOST=TeraWasserburgInspector/FG=(FL,FT,FR,FB) ConcY vs ConcX
	AppendToGraph ConcMarkerY vs ConcMarkerX
	
	// Create tags:
	Variable i
	For (i = 1; i < 5e9/(100e6); i = i +1)
		String tagStr = "tag" + num2str(i)
		String tagValue = num2str(100*i) + " Ma"
		Tag/N=$tagStr/A=RC/F=0/Z=1/I=1/B=1/X=-0.5/Y=0.5/L=0/AO=0 TWConcMarkerY, i, tagValue
		//Tag/C/N=text0/L=0 WetherillConcX, 0,"dsfasdf"
	EndFor
	
	// Generate waves for live concordia data to be updated by the hook:
	Make/O/N=100 LiveEllipseX, LiveEllipseY
	LiveEllipseX = 0
	LiveEllipseY = 0
	AppendToGraph LiveEllipseY vs LiveEllipseX

	// Set appearance of traces:	
	ModifyGraph lsize[0]=1.5,rgb[0]=(0,0,0) 
	ModifyGraph mode[1]=3, marker[1]=19, msize[1]=5
	//ModifyGraph mode(LiveEllipseY)=3,marker(LiveEllipseY)=5,rgb(LiveEllipseY)=(0,0,65535), mode(LiveEllipseY) =0, lsize(LiveEllipseY)=2
	
	// Set graph properties:
	SetAxis left 0,1
	SetAxis bottom 0,10
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	// Label axes according to which plot we're making:
	Label left "\\S207\\MPb \\Z28/\\M \\S206\\MPb"
	Label bottom "\\S238\\MU \\Z28/\\M \\S206\\MPb"
	
	SetWindow TeraWasserburgInspector hook(TeraWasserburgInspectorHook)=TeraWasserburgInspector_Hook	
	
	SetActiveSubwindow _endfloat_
End

Function TeraWasserburgInspector_Update()
	Print "WetherillInspector_Update()"
		
	// Clear all traces
	String TracesToKeep = "TWConcY;TWConcMarkerY;LiveEllipseY;"
	String AllTraces = TraceNameList("TWInspector#TWGraph", ";", 1)	
	String TracesToRemove = RemoveFromList(TracesToKeep, AllTraces)	
	
	Variable TraceIndex
	For (TraceIndex = 0; TraceIndex < ItemsInList(TracesToRemove); TraceIndex+=1)
		RemoveFromGraph/Z/W=TeraWasserburgInspector#TWGraph $StringFromList(TraceIndex, TracesToRemove)
	EndFor
	
	// Plot all the stored ROIs -- THIS ISN'T DONE
	Wave MonocleTable = root:Packages:Monocle:DataTable
	Wave/T MonocleROINames = root:Packages:Monocle:DataTableROINames
	
	// Find which columns to use for each with FindDimLabel	
	Variable i
	For (i = 0; i < dimsize(MonocleTable, 0); i+=1)
		Variable Pb206_U238
	EndFor
	
	// Plot an ROI from the current mouse location
	Wave EllipseX = root:Packages:Monocle:TeraWasserburg:LiveEllipseX
	Wave EllipseY = root:Packages:Monocle:TeraWasserburg:LiveEllipseY
	
	Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
	
	Wave Ratio6_38, Ratio7_6, Ratio38_6
	
	If (MonocleUsingCellSpace())
		Wave Ratio6_38 = root:Packages:Monocle:CellSpaceImages:Final206_238
		Wave Ratio7_6 = root:Packages:Monocle:CellSpaceImages:Final207_206
		Wave Ratio38_6 = root:Packages:Monocle:CellSpaceImages:Final238_206
		
		If (!WaveExists(Ratio38_6))
			Duplicate Ratio6_38 $("root:Packages:Monocle:CellSpaceImages:Final238_206")
			Wave Ratio38_6 = root:Packages:Monocle:CellSpaceImages:Final238_206			
			Ratio38_6 = 1/Ratio38_6
		EndIf
	Else
		Wave Ratio6_38 = root:Packages:Monocle:SelectionsImages:Final206_238_Map
		Wave Ratio7_6 = root:Packages:Monocle:SelectionsImages:Final207_206_Map
		Wave Ratio38_6 = root:Packages:Monocle:SelectionsImages:Final238_206_Map

		If (!WaveExists(Ratio38_6))
			Duplicate/O Ratio6_38 $("root:Packages:Monocle:SelectionsImages:Final238_206")
			Wave Ratio38_6 = root:Packages:Monocle:SelectionsImages:Final238_206			
			Ratio38_6 = 1/Ratio38_6
		EndIf		
	EndIf
	
	NewDataFolder/O/S root:Packages:Monocle:TeraWasserburg
	
	// Make a copy of the target map and multipy it by the mask
//	Duplicate/O Ratio6_38, Temp6_38
//	Temp6_38 = Ratio6_38*M_ROIMask
	
//	Duplicate/O Ratio7_35, Temp7_35
//	Temp7_35 = Ratio7_35*M_ROIMask
	
	ImageStats/M=0/R=M_ROIMask Ratio7_6
	
//	ImageStats Temp6_38
	Variable AvgY = V_avg
	Variable StdevY = V_sdev
	Variable MinY = V_min
	Variable MaxY = V_max
	Variable StderrY = StdevY/sqrt(V_npnts)
	
//	ImageStats Temp7_35
	ImageStats/M=0/R=M_ROIMask Ratio38_6
	Variable AvgX = V_avg
	Variable StdevX = V_sdev
	Variable MinX = V_min
	Variable MaxX = V_max
	Variable StderrX = StdevX/sqrt(V_npnts)
	
	Duplicate/O Ratio7_6, Temp7_6
	Temp7_6[][] = M_ROIMask == 0 ? Ratio7_6[p][q] : nan
	Duplicate/O Ratio38_6, Temp38_6
	Temp38_6[][] = M_ROIMask == 0 ? Ratio38_6[p][q] : nan
	
	Redimension/N=(dimsize(Temp7_6,0)*dimsize(Temp7_6,1)) Temp7_6
	Redimension/N=(dimsize(Temp38_6,0)*dimsize(Temp38_6,1)) Temp38_6

	Temp7_6[p] = numtype(Temp7_6[p]) == 2 ? nan : Temp7_6[p]
	Temp38_6[p] = numtype(Temp38_6[p]) == 2 ? nan : Temp38_6[p]
	
	WaveTransform zapNaNs Temp7_6
	WaveTransform zapNaNs Temp38_6
//	MatrixOp/O Temp7_35NN = zapNaNs(Temp7_35)
	
	Variable corr = StatsCorrelation(Temp7_6,Temp38_6)
	
	Variable plotMinX = AvgX - 12*StderrX
	Variable plotMaxX = AvgX + 12*StderrX
	Variable plotMinY = AvgY - 12*StderrY
	Variable plotMaxY = AvgY + 12*StderrY	
	
	MonocleCalculateEllipse(EllipseX, EllipseY, AvgX, 2*StderrX, AvgY, 2*StderrY, corr)
	SetAxis/W=TeraWasserburgInspector#TWGraph left plotMinY, plotMaxY
	SetAxis/W=TeraWasserburgInspector#TWGraph bottom plotMinX, plotMaxX
End

Function TeraWasserburgInspector_Close()
	// Clean up after the inspector, i.e. remove from the active list, kill some waves?
End

Function TeraWasserburgInspector_Hook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	
	Switch (s.eventCode)
		Case 2: // Closed
			Print "TeraWasserburgInspector closed..."
			ActiveInspectors = RemoveFromList("TeraWasserburg", ActiveInspectors)
			If (ItemsInList(ActiveInspectors) == 0)
				RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
			EndIf						
			Break
	EndSwitch

End

Function TeraWasserburgInspector_Static()

	NewDataFolder/O/S root:Packages:Monocle:TeraWasserburg
	NewDataFolder/O/S root:Packages:Monocle:TeraWasserburg:StaticPlot
	
	MonocleGenerateConcordia("TWConc", 0, 5e9, NoOfPoints=1000, NoOfMarkers=5e9/100e6, doTW=1, ConcFolder="root:Packages:Monocle:TeraWasserburg:StaticPlot")
	Wave ConcX = $"TWConcX", ConcY = $"TWConcY"
	Wave ConcMarkerX = $"TWConcMarkerX", ConcMarkerY = $"TWConcMarkerY"
		
	Display/N=TWStaticGraph ConcY vs ConcX
	AppendToGraph ConcMarkerY vs ConcMarkerX
	
	// Create tags:
	Variable doTags = 1

	Variable i
	For (i = 1; i < 5e9/(100e6); i = i +1)
		String tagStr = "tag" + num2str(i)
		String tagValue = num2str(100*i) + " Ma"
		Tag/N=$tagStr/A=RC/F=0/Z=1/I=1/B=1/X=-0.5/Y=0.5/L=0/AO=0 TWConcMarkerY, i, tagValue
	EndFor


	// Set appearance of traces:	
	ModifyGraph lsize[0]=1.5,rgb[0]=(0,0,0) 
	ModifyGraph mode[1]=3, marker[1]=19, msize[1]=5
	
	// Set graph properties:
	SetAxis left 0,1
	SetAxis bottom 0,10
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	// Label axes 
	Label left "\\S207\\MPb \\Z28/\\M \\S206\\MPb"
	Label bottom "\\S238\\MU \\Z28/\\M \\S206\\MPb"
	
	Wave MonocleTable = root:Packages:Monocle:DataTable
	Wave/T ROINames = root:Packages:Monocle:DataTableROINames
	
	Variable ROIIndex
	For (ROIIndex = 0; ROIIndex < dimsize(MonocleTable,0); ROIIndex += 1)
		String ROIName = ROINames[ROIIndex]
		
		Make/O/N=100 $(ROIName + "_EllipseX")
		Make/O/N=100 $(ROIName + "_EllipseY")
		Wave EllipseX = $(ROIName + "_EllipseX")
		Wave EllipseY = $(ROIName + "_EllipseY")
	
		Variable AvgX = MonocleTable[ROIIndex][%$"Final238_206"]
		Variable AvgY = MonocleTable[ROIIndex][%$"Final207_206"]
		Variable StdevX = MonocleTable[ROIIndex][%$"Final238_206_Int2SE"]
		Variable StdevY = MonocleTable[ROIIndex][%$"Final207_206_Int2SE"]
		Variable corr = MonocleTable[ROIIndex][%$"StatsCorr38_6v7_6"]
				
		MonocleCalculateEllipse(EllipseX, EllipseY, AvgX, StdevX, AvgY, StdevY, corr)
		
		AppendToGraph EllipseY vs EllipseX
		ModifyGraph rgb($(ROIName+"_EllipseY"))=(0,0,0)
	
		If (doTags)
			Tag/C/N=$ROIName/F=0/B=1 $(ROIName+"_EllipseY"), 0, ROIName
		EndIf
	EndFor

End

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// KDE Inspector
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function KDEInspector_Launch()
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	NewDataFolder/O/S root:Packages:Monocle
	
	// Create the window and set the hook for closing
	DoWindow/F KDEInspector
	If (V_Flag == 1)
		KillWindow KDEInspector
	EndIf
	
	KillDataFolder/Z root:Packages:Monocle:KDE
	NewDataFolder/O/S root:Packages:Monocle:KDE
	
	Variable/G KDEBandwidth = nan
	Variable/G KDEStart = nan
	Variable/G KDEStop = nan
	Variable/G KDENx = nan
		
	NewPanel/FLT/N=KDEInspector/K=1/W=(200, 200, 750, 550)
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=KDEInspector fixedSize=0
	
	Make/O/N=100 datakde
	datakde = 0
	
	Display/N=KDEGraph/HOST=KDEInspector/FG=(FL,FT,FR,FB) datakde
//	ModifyGraph mode=5, hbFill=2, rgb=(17476, 17476, 17476)
	// Set appearance of traces:	
	
	// Set graph properties:
	ModifyGraph/W=KDEInspector#KDEGraph standoff=0
	ModifyGraph/W=KDEInspector#KDEGraph gFont="Helvetica",gfSize=18
	ModifyGraph/W=KDEInspector#KDEGraph mirror=2
	
	// Label axes according to which plot we're making:
	Label/W=KDEInspector#KDEGraph left "KDE"
	Label/W=KDEInspector#KDEGraph bottom "Value"	
	
	// Label axes according to which plot we're making:
//	Label left "KDE"
//	Label bottom "Value"
	
	SetWindow KDEInspector hook(KDEInspectorHook)=KDEInspector_Hook	
	
	SetActiveSubwindow _endfloat_

End

Function KDEInspector_Options()
	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O/S root:Packages:Monocle:KDE
	
	NVAR KDEBandwidth = $("root:Packages:Monocle:KDE:KDEBandwidth")
	NVAR KDEStart= $("root:Packages:Monocle:KDE:KDEStart")
	NVAR KDEStop = $("root:Packages:Monocle:KDE:KDEStop")		
	NVAR KDENx = $("root:Packages:Monocle:KDE:KDENx")
	
	Variable Bandwidth = KDEBandwidth
	Variable Start = KDEStart
	Variable Stop = KDEStop
	Variable Nx = KDENx
		
	Prompt Start, "Start (nan for min - 2 * bw):"
	Prompt Stop, "Stop  (nan for max + 2 * bw):"
	Prompt Bandwidth, "Bandwidth (nan for Scott's rule):"
	Prompt Nx, "Number of points:"
	
	DoPrompt "KDE Inspector Options", Start, Stop, Bandwidth, Nx
	
	If (V_flag == 0) // not cancelled
		KDEStart = Start
		KDEStop = Stop
		KDEBandwidth = Bandwidth
		KDENx = Nx
	EndIf
End

Function KDEInspector_Hook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	
	Switch (s.eventCode)
		Case 2: // Closed
			Print "KDEInspector closed..."
			ActiveInspectors = RemoveFromList("KDE", ActiveInspectors)
			If (ItemsInList(ActiveInspectors) == 0)
				RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
			EndIf
			Break
	EndSwitch
End

Function KDEInspector_Update()
	NewDataFolder/O/S root:Packages:Monocle:KDE

	// Plot an ROI from the current mouse location
//	NVAR InspectorX = root:Packages:Monocle:InspectorX
//	NVAR InspectorY = root:Packages:Monocle:InspectorY
		
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	Wave target
	String TargetName 
	If (MonocleUsingCellSpace())
		Wave target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
		TargetName = IoliteDFpath("CellSpaceImages","CellSpace_Sample")
	Else
		Wave target = $GetImageWave(TopImageGraph())
		TargetName = GetImageWave(TopImageGraph())
	EndIf
	
	
	Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
	
	// Make a copy of the target map and multipy it by the mask
	Duplicate/O target, tempTarget
	tempTarget = M_ROIMask[p][q] == 0 ? target[p][q] : nan

	RemoveFromGraph/Z/W=KDEInspector#KDEGraph datakde
	
	Redimension/D/N=(dimsize(tempTarget,0)*dimsize(tempTarget,1)) tempTarget
	SetScale/P x 0, 1, "", tempTarget
	WaveTransform zapNans tempTarget
	
	If (numpnts(tempTarget) == 0)
		Return 0
	EndIf

	WaveStats/Q/Z tempTarget

	NVar KDEBandwidth = $("root:Packages:Monocle:KDE:KDEBandwidth")
	
	Variable bw = numtype(KDEBandwidth) == 2 ? 2*1.06*V_sdev*numpnts(tempTarget)^(-1/5) : KDEBandwidth
	NVar KDEStart = $("root:Packages:Monocle:KDE:KDEStart")
	NVar KDEStop = $("root:Packages:Monocle:KDE:KDEStop")
	NVar KDENx = $("root:Packages:Monocle:KDE:KDENx")
	
	
	KDEInspector_KDE(tempTarget, bw, KDEStart, KDEStop, KDENx)
	
	Wave kde = root:Packages:Monocle:KDE:datakde


	AppendToGraph/W=KDEInspector#KDEGraph kde

	ModifyGraph/W=KDEInspector#KDEGraph mirror=2
	Label/W=KDEInspector#KDEGraph left "KDE"
	Label/W=KDEInspector#KDEGraph bottom "Value"		
	SetAxis/W=KDEInspector#KDEGraph/A left
	SetAxis/W=KDEInspector#KDEGraph/A bottom
//	WaveInfo
	

End

Function KDEInspector_Close()

End

Function KDEInspector_Static()
	NewDataFolder/O/S root:Packages:Monocle:KDE:StaticPlot
	
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	Display/N=KDEStaticPlot
	
	Wave/T ROINames = root:Packages:Monocle:DataTableROINames
	
	Variable ROIIndex
	For (ROIIndex = 0; ROIIndex < numpnts(ROINames); ROIIndex += 1)
		String ThisROIName = ROINames[ROIIndex]
		Wave ThisROI = $("root:Packages:Monocle:Masks:"+ThisROIName+"_Mask")
						
		Wave target
		If (cmpstr(SelectedMapType, "Cell space") == 0)
			Wave target = $IoliteDFpath("CellSpaceImages","CellSpace_Sample")
		Else
			Wave target =  $GetImageWave(TopImageGraph())
		EndIf
		

		Duplicate/O target, $("root:Packages:Monocle:KDE:StaticPlot:"+ThisROIName)
		Wave tempTarget = $("root:Packages:Monocle:KDE:StaticPlot:"+ThisROIName)
		
//		tempTarget = tempTarget *

		tempTarget = ThisROI[p][q] == 0 ? target[p][q] : nan

		
	
		Redimension/D/N=(dimsize(tempTarget,0)*dimsize(tempTarget,1)) tempTarget
		SetScale/P x 0, 1, "", tempTarget
		WaveTransform zapNans tempTarget
	
		If (numpnts(tempTarget) == 0)
			Continue
		EndIf

		WaveStats/Q/Z tempTarget

		NVar KDEBandwidth = $("root:Packages:Monocle:KDE:KDEBandwidth")
	
		Variable bw = numtype(KDEBandwidth) == 2 ? 2*1.06*V_sdev*numpnts(tempTarget)^(-1/5) : KDEBandwidth
		NVar KDEStart = $("root:Packages:Monocle:KDE:KDEStart")
		NVar KDEStop = $("root:Packages:Monocle:KDE:KDEStop")
		NVar KDENx = $("root:Packages:Monocle:KDE:KDENx")
	
	
		KDEInspector_KDE(tempTarget, bw, KDEStart, KDEStop, KDENx)
	
		Wave kde = root:Packages:Monocle:KDE:datakde
		Duplicate kde $("root:Packages:Monocle:KDE:StaticPlot:"+ThisROIName+"_kde")
		Wave thiskde = $("root:Packages:Monocle:KDE:StaticPlot:"+ThisROIName+"_kde")
		
		AppendToGraph/W=KDEStaticPlot thiskde
		
	EndFor
End

Function KDEInspector_KDE(w,bw, xminin, xmaxin, nxin)							// 1d kernel density estimation (Gaussian kernel)
	wave w; variable bw, xminin, xmaxin, nxin
	variable n=numpnts(w),kde_norm
	variable xmin = numtype(xminin) == 2 ? wavemin(w)-2*bw : xminin
	variable xmax = numtype(xmaxin) == 2 ? wavemax(w)+2*bw : xmaxin
	variable nx = numtype(nxin) == 2 ? min(round(100*(xmax-xmin)/bw),100) : nxin
	make /d/free/n=(n) wweights=1
	FastGaussTransform /TET=10/WDTH=(bw)/RX=(4*bw) /OUT1={xmin,nx,xmax} w,wweights 	// you may need to tweak /RX flag value
	wave M_FGT;  kde_norm=sum(M_FGT)*deltax(M_FGT);		M_FGT /= kde_norm
	string wn=NameofWave(w)+"_kde";	duplicate /d/o M_FGT, root:Packages:Monocle:KDE:datakde
	killwaves M_FGT
End

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// REE Inspector
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function REEInspector_Launch()


	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	
	NewDataFolder/O/S root:Packages:Monocle
	
	// Create the window and set the hook for closing
	DoWindow/F REEInspector
	If (V_Flag == 1)
		KillWindow REEInspector
	EndIf
	
	KillDataFolder/Z root:Packages:Monocle:REE
	NewDataFolder/O/S root:Packages:Monocle:REE
	
	REEInspector_Init()
		
	NewPanel/FLT/N=REEInspector/K=1/W=(200, 200, 750, 550)
	SetActiveSubwindow _endfloat_
	ModifyPanel/W=REEInspector fixedSize=0
	
	Wave REEValues = root:Packages:Monocle:REE:REEValues
	Wave REEPositions = root:Packages:Monocle:REE:REEPositions
	Wave/T REELabels = root:Packages:Monocle:REE:REEElements

	REEValues = 0

	SVAR REEOrdering = root:Packages:Monocle:REE:REEOrdering


	StrSwitch (REEOrdering)
		Case "AtomicNumbers":
			Wave REEAtomicNumbers = root:Packages:Monocle:REE:REEAtomicNumbers
			REEPositions = REEAtomicNumbers
			Break
		Case "IonicRadii":
			Wave REERadii = root:Packages:Monocle:REE:REERadii
			REEPositions = REERadii
			Break
		Default:
			REEPositions = REEAtomicNumbers
			Break
	EndSwitch
	
	Display/N=REEGraph/HOST=REEInspector/FG=(FL,FT,FR,FB) REEValues vs REEPositions


	// Set appearance of traces:	
	
	// Set graph properties:
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	

	ModifyGraph log(left)=1,userticks(bottom)={REEPositions,REELabels}
	SetAxis bottom 56.5, 71.5
	ModifyGraph mode=4,marker=19,msize=6
	SetWindow REEInspector hook(REEInspectorHook)=REEInspector_Hook	
	
	SetActiveSubwindow _endfloat_

End

Function REEInspector_Update()
	NewDataFolder/O/S root:Packages:Monocle:REE

	// Plot an ROI from the current mouse location
//	NVAR InspectorX = root:Packages:Monocle:InspectorX
//	NVAR InspectorY = root:Packages:Monocle:InspectorY
		
	SVAR SelectedMapType = root:Packages:Monocle:SelectedMapType
	//SVAR ListOfOutputChannels = $ioliteDFPath("output", "ListOfOutputChannels")
	String ListOfOutputChannels = MonocleChannels() 
	
	SVAR REENorm = root:Packages:Monocle:REE:REENorm
	
	Wave/T REEElements = root:Packages:Monocle:REE:REEElements
	Wave REEValues = root:Packages:Monocle:REE:REEValues

	Wave M_ROIMask = root:Packages:Monocle:M_ROIMask
	
	Variable i
	// Loop through each REE and update as available...
	For (i = 0; i < 14; i += 1)
		String ThisREE = REEElements[i]

		String ThisChannel = StringFromList(0,GrepList(ListOfOutputChannels, "(?)"+ThisREE))
		
	//	Print ThisREE, ThisChannel

		String ThisREEImagePath = ""
		
		If (MonocleUsingCellSpace())
			ThisREEImagePath = "root:Packages:Monocle:CellSpaceImages:"+ThisChannel
		Else
			ThisREEImagePath = "root:Packages:Monocle:SelectionsImages:"+ThisChannel + "_Map"
		EndIf
		
		Wave ThisREEImage = $ThisREEImagePath
		
		String NormPath = ""
		StrSwitch(REENorm)
			Case "CI":
				NormPath = "root:Packages:Monocle:REE:CI"
				Break
			Case "MUQ":
				NormPath = "root:Packages:Monocle:REE:MUQ"
				Break
		EndSwitch
		
		Wave ThisNorm = $NormPath

//		Duplicate/O ThisREEImage, ThisREEImageTemp
//		ThisREEImageTemp = ThisREEImage *M_ROIMask
		
//		WaveStats/Q/Z ThisREEImageTemp
		
//		ImageStats/M=1/R=M_ROIMask ThisREEImage

		Variable V_avg, V_uncert, V_sum
		MonocleStats(ThisREEImage, M_ROIMask, V_avg, V_uncert, V_sum)
		
		REEValues[%$ThisREE] = V_avg / ThisNorm[%$ThisREE]
	EndFor
	
	// Label axes according to which plot we're making:
	Label/W=REEInspector#REEGraph left "ROI / " + REENorm
	
	SetAxis/W=REEInspector#REEGraph/A left
	//SetAxis/W=REEInspector#REEGraph/A bottom
End

Function REEInspector_Hook(s)
	STRUCT WMWinHookStruct &s

	SVAR ActiveInspectors = root:Packages:Monocle:ActiveInspectors
	
	Switch (s.eventCode)
		Case 2: // Closed
			Print "REEInspector closed..."
			ActiveInspectors = RemoveFromList("REE", ActiveInspectors)
			If (ItemsInList(ActiveInspectors) == 0)
				RemoveFromGraph/Z/W=$MonocleTargetWindow() InspectorROIy
			EndIf						
			Break
	EndSwitch
End

Function REEInspector_Close()

End

Function REEInspector_Static()

	NewDataFolder/O/S root:Packages:Monocle:REE
	NewDataFolder/O/S root:Packages:Monocle:REE:StaticPlot
								
	Wave MonocleTable = root:Packages:Monocle:DataTable
	
	If (dimsize(MonocleTable,0) == 0)
		Print "[Monocle] You haven't created any ROIs yet."
		Return -1
	EndIf
	
	DoWindow/K REEStaticGraph
	
	Display/N=REEStaticGraph	
	
	Wave/T ROINames = root:Packages:Monocle:DataTableROINames
	Wave/T REEElements = root:Packages:Monocle:REE:REEElements
	
	//SVAR ListOfOutputChannels = $ioliteDFPath("output", "ListOfOutputChannels")	
	String ListOfOutputChannels = MonocleChannels()
	
	SVAR REENorm = root:Packages:Monocle:REE:REENorm
	
	String NormPath = ""
	StrSwitch(REENorm)
		Case "CI":
			NormPath = "root:Packages:Monocle:REE:CI"
			Break
		Case "MUQ":
			NormPath = "root:Packages:Monocle:REE:MUQ"
			Break
	EndSwitch
		
	Wave ThisNorm = $NormPath	
	
	Wave REEPositions = root:Packages:Monocle:REE:REEPositions
	Wave/T REELabels = root:Packages:Monocle:REE:REEElements

	SVAR REEOrdering = root:Packages:Monocle:REE:REEOrdering

	Wave REEAtomicNumbers = root:Packages:Monocle:REE:REEAtomicNumbers

	StrSwitch (REEOrdering)
		Case "AtomicNumbers":			
			REEPositions = REEAtomicNumbers
			Break
		Case "IonicRadii":
			Wave REERadii = root:Packages:Monocle:REE:REERadii
			REEPositions = REERadii
			Break
		Default:
			REEPositions = REEAtomicNumbers
			Break
	EndSwitch	
	
	Variable ROIIndex
	For (ROIIndex = 0; ROIIndex < dimsize(MonocleTable,0); ROIIndex += 1)
		String ROIName = ROINames[ROIIndex]
		
		Make/O/N=14 $(ROIName + "_REE")
		Wave ThisREEPattern = $(ROIName + "_REE")
	
		Variable REEIndex
		For (REEIndex = 0; REEIndex < 14; REEIndex += 1)
			String ThisREE = REEElements[REEIndex]	
			String ThisChannel = StringFromList(0,GrepList(ListOfOutputChannels, "(?)"+ThisREE))
		
			Variable ThisValue = MonocleTable[%$ROIName][%$ThisChannel]
		
			ThisREEPattern[REEIndex] = ThisValue/ThisNorm[%$ThisREE]
		
		EndFor

		AppendToGraph/W=REEStaticGraph ThisREEPattern vs REEPositions
	EndFor
	
	// Set graph properties:
	ModifyGraph standoff=0
	ModifyGraph gFont="Helvetica",gfSize=18
	ModifyGraph mirror=2
	
	ModifyGraph log(left)=1,userticks(bottom)={REEPositions,REELabels}
	SetAxis bottom 56.5, 71.5
	ModifyGraph mode=4,marker=19,msize=6	

End

Function REEInspector_Init()
	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O/S root:Packages:Monocle:REE

	String/G REENorm = "CI"
	String/G REEOrdering = "AtomicNumbers"
	
	Make/T/O/N=(5, 14) REEData
	
	Make/T/O REEElements =  {"La", "Ce", "Pr", "Nd", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu"}
	SetDimLabel 0, 0, Element, REEData
	REEData[%$"Element"][] = REEElements[q]
	
	Make/O REERadii = {1.032, 1.01, 0.99, 0.983, 0.97, 0.947, 0.938, 0.923, 0.912, 0.901, 0.89, 0.88, 0.868, 0.861}
	SetDimLabel 0, 1, IonicRadius, REEData
	REEData[%$"IonicRadius"][] = num2str(REERadii[q])
	
	Make/O REEAtomicNumbers = {57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71 }
	SetDimLabel 0, 2, AtomicNumber, REEData
	REEData[%$"AtomicNumber"][] =  num2str(REEAtomicNumbers[q])
	
	Make/O CI = {0.237, 0.613, 0.0928, 0.457, 0.148, 0.0563, 0.199, 0.0361, 0.246, 0.0546, 0.160, 0.0247, 0.161, 0.0246}
	SetDimLabel 0, 3, CI, REEData
	REEData[%$"CI"][] = num2str(CI[q])
	
	Make/O MUQ = {34.794, 72.19, 8.581, 32.006, 6.277, 1.121, 5.364, 0.798, 4.543, 0.912, 2.533, 0.388, 2.533, 0.377}
	SetDimLabel 0, 4, MUQ, REEData
	REEData[%$"MUQ"][] = num2str(MUQ[q])

	Make/O/N=14 REEValues
	Make/O/N=14 REEPositions
	
	Variable i
	For (i = 0; i < 14; i+=1)
		SetDimLabel 1, i, $REEElements[i], REEData
		SetDimLabel 0, i, $REEElements[i], REEElements
		SetDimLabel 0, i, $REEElements[i], REEAtomicNumbers
		SetDimLabel 0, i, $REEElements[i], REERadii
		SetDimLabel 0, i, $REEElements[i], CI
		SetDimLabel 0, i, $REEElements[i], MUQ
		SetDimLabel 0, i, $REEElements[i], REEValues
		SetDimLabel 0, i, $REEElements[i], REEPositions
	EndFor

End

Function REEInspector_Options()
	
	NewDataFolder/O/S root:Packages:Monocle
	NewDataFolder/O/S root:Packages:Monocle:REE
	
	SVAR REENorm = $("root:Packages:Monocle:REE:REENorm")
	SVAR REEOrdering = $("root:Packages:Monocle:REE:REEOrdering")
	
	String REENormPick
	String REEOrderingPick
	
	Prompt REENormPick, "Norm:", popup  "CI;MUQ;"
	Prompt REEOrderingPick, "Ordering:", popup "AtomicNumber;IonicRadius;"
	
	DoPrompt "REE Inspector Options", REENormPick, REEOrderingPick
	
	If (V_flag == 0) // not cancelled
		REENorm = REENormPick
		REEOrdering = REEOrderingPick
	EndIf

End