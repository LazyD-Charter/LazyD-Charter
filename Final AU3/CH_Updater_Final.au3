#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_Updater.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Description=Script file for updating LazyD Charter files
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=LazyD Charter
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=LazyD is not a company
#AutoIt3Wrapper_Res_LegalCopyright=None
#AutoIt3Wrapper_Res_LegalTradeMarks=None
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <File.au3>
#include <FileConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <Constants.au3>
#include <TreeViewConstants.au3>
#include <GuiTreeView.au3>
#include <Date.au3>
#include <StringConstants.au3>

#include <LazyD Charter Color Theme.au3>

AutoItSetOption("MustDeclareVars",1)
AutoItSetOption("GUIOnEventMode", 1)

; Read ini file for InstallDirectory\Samples folder path
Global $g_sIniFile = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"
Global $g_sInstallPath = IniRead($g_sIniFile,"Install","Install_Path","NotRead")
Global $g_sAppDataChecked = IniRead($g_sIniFile,"Install","AppData_Checked","NotRead") ; Unused ATM
Global $g_sAutoItChecked = IniRead($g_sIniFile,"Install","AutoIt_Checked","NotRead")
Global $g_sRegistryChecked = IniRead($g_sIniFile,"Install","Registry_Checked","NotRead")
Global $g_sExtension = IniRead($g_sIniFile,"Install","Extension","NotRead")
Global $g_sRegHive = IniRead($g_sIniFile,"Install","Registry_Hive","NotRead")
Global $g_sAutoItVer = IniRead($g_sIniFile,"Install","AutoItVer","NotRead")

; API Key to access Shared Folder
Global $g_sApiKey = IniRead($g_sIniFile,"Install","API_Key","NotRead") ; Drive API restricted
; (Drive) Shared Folder FileID
Global $g_sSharedFolderID = IniRead($g_sIniFile,"Install","Updates_Folder_ID","NotRead")  ; testfolder

; Terminate script with a warning MsgBox if Install_Path can not be read
if $g_sInstallPath = "" then
	MsgBox($MB_OK,"Warning","Either ""APPDATA\Roaming\LazyD Charter\LazyD Charter.ini"" is missing or Couldn't read contents for ""Install_Path"" key value." & @CRLF & "Terminating script!")
	Exit
EndIf

; App Window Related
Global $g_idTV_New
Global $g_idTV_Updated
Global $g_id_lblInfo
Global $g_id_lblSizeInfo
Global $g_idCheck_AllNew
Global $g_idCheck_AllUpdated
Global $g_idCheck_BackupUpdated

Global $g_iTotalSizeBytes = 0
Global $g_iTotalSizeBytesLast = 0

Global $g_aFolderListDetails
Global $g_aTV_Event[2]

; HTTP GET Query Parameters
Global $g_sSpaces = "Drive"
Global $g_sPageSize = "500" ; Max number of files returned from a single query (Max Allowed: 1000)

#include <GuiTreeViewEx_Modified.au3>

#include <FolderList_to_TreeView.au3>
#include <Drive_Files_List.au3>
#include <Drive_Download_Filev2.au3>

CreateAppWindow()

func CreateAppWindow()

	;Create the App Window
	Local $hAppWindow = GUICreate("LazyD Charter - Updater",830,545,-1,-1,-1,-1)
	GUISetIcon($g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico")
	GUISetBkColor($COL_APP_WINDOW, $hAppWindow)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Quit_App")

	;Create GUI Elements and Set On Event

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	;Create Warning label
	GUICtrlCreateLabel("Please close any AutoIt scripts that are running!",10,10,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetColor(-1, $COL_BTN_QUIT)
	GUICtrlSetBkColor(-1,$COL_APP_WINDOW)

	;Create New Content label
	GUICtrlCreateLabel("New Content",10,45,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	;Create Updated Content Label
	GUICtrlCreateLabel("Updated Content",420,45,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	;Create New Content TreeView
	$g_idTV_New = GUICtrlCreateTreeView(10,70,400,300, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES), -1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 12, 400, 0, "")

	;Create Update Content TreeView
	$g_idTV_Updated = GUICtrlCreateTreeView(420,70,400,300, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES),-1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 12, 400, 0, "")

	;Create CHECK for updated files Button
	Local $iBtn_Check = GUICtrlCreateButton("CHECK UPDATES",10,415,200,50,-1,-1)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetOnEvent($iBtn_Check, "Check_Updates")
	GUICtrlSetFont(-1, 14, 400, 0, "")

	;Create SYNC Files Button
	Local $iBtn_Sync = GUICtrlCreateButton("DOWNLOAD",620,415,200,50,-1,-1)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetOnEvent($iBtn_Sync, "Sync_Updates")
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Select All New Items CheckBox
	$g_idCheck_AllNew = GUICtrlCreateCheckbox("Check to Select All New",10,378,350,25,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetOnEvent($g_idCheck_AllNew, "_Events")

	; Create Select All Updated Items CheckBox
	$g_idCheck_AllUpdated = GUICtrlCreateCheckbox("Check to Select All Updated",420,378,350,25,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetOnEvent($g_idCheck_AllUpdated, "_Events")

	; Create Keep Backups CheckBox
	$g_idCheck_BackupUpdated = GUICtrlCreateCheckbox("Check to keep a backup of updated files",230,427,350,25,-1,-1)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create CLOSE Button
	Local $iBtn_Close = GUICtrlCreateButton("CLOSE",720,475,100,50,-1,-1)
	GUICtrlSetBkColor($iBtn_Close, $COL_BTN_QUIT)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetOnEvent($iBtn_Close, "Quit_App")

	;Create Information label
	$g_id_lblInfo = GUICtrlCreateLabel("Click ""CHECK UPDATES"" to Retrieve File List",10,490,450,25,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	;Create Selected Items Size Information label
	$g_id_lblSizeInfo = GUICtrlCreateLabel(" Total Size: 0 B",500,490,200,25,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	; Create Graphic GUI Controls (for eye candy)
	GUICtrlCreateGraphic(10, 410, 810, 61) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(10, 530, 810, 5) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	;Display the App Window
	GUISetState(@SW_SHOW,$hAppWindow)

	_GUITreeViewEx_RegMsg()

	;MessageLoop
	While 1
		sleep(10)
		_GUITreeViewEx_AutoCheck()
		GetTotalSize()
	WEnd

EndFunc

Func _Events()

	Switch @GUI_CtrlId
		Case $g_idCheck_AllNew
			if not(_IsChecked($g_idCheck_AllNew)) then
				GUICtrlSetData($g_idCheck_AllNew,"Check to Select All New")
				Adjust_TreeView_Selection(0, False)
			Else
				GUICtrlSetData($g_idCheck_AllNew,"Uncheck to Deselect All New")
				Adjust_TreeView_Selection(0)
			EndIf
		Case $g_idCheck_AllUpdated
			if not (_IsChecked($g_idCheck_AllUpdated)) then
				GUICtrlSetData($g_idCheck_AllUpdated,"Check to Select All Updated")
				Adjust_TreeView_Selection(1, False)
			Else
				GUICtrlSetData($g_idCheck_AllUpdated,"Uncheck to Deselect All Updated")
				Adjust_TreeView_Selection(1)
			EndIf
	EndSwitch

EndFunc

Func Adjust_TreeView_Selection($iArrayNo, $bState = True)

	if $g_aTV_Event[$iArrayNo] = "" then return

	Local $aTV = $g_aTV_Event[$iArrayNo]
	Local $idTV = $aTV[0][3]
	Local $hTV = GUICtrlGetHandle($idTV)

	Local $iSign = ($bState=True) ? (1) : (-1)

	for $i = 0 to UBound($aTV)-1
		if $aTV[$i][5] <> "" then
			Local $bCurrentState = _GUICtrlTreeView_GetChecked($hTV, $aTV[$i][5])
			Local $iMultiplier = ($bCurrentState = $bState) ? (0) : (1)
			_GUICtrlTreeView_SetChecked($hTV, $aTV[$i][5], $bState)
			$g_iTotalSizeBytes = ($aTV[$i][0] = 0) ? ($g_iTotalSizeBytes + $iSign * $aTV[$i][15] * $iMultiplier) : ($g_iTotalSizeBytes) ; if file
		endif
	Next

	_GUITreeViewEx_Check_All($hTV, $bState)

EndFunc

Func GetTotalSize()

	if $g_iTotalSizeBytes = $g_iTotalSizeBytesLast then return

	Local $sTotalSizeUnit ="B"
	Local $iTotalSize = $g_iTotalSizeBytes

	if $g_iTotalSizeBytes/1024 >= 1 then
		$iTotalSize = $g_iTotalSizeBytes/1024
		$sTotalSizeUnit = "KB"
	EndIf
	if $iTotalSize/1024 >= 1 Then
		$iTotalSize = $iTotalSize/1024
		$sTotalSizeUnit = "MB"
	EndIf
	if $iTotalSize/1024 >= 1 Then
		$iTotalSize = $iTotalSize/1024
		$sTotalSizeUnit = "GB"
	EndIf

	GUICtrlSetData($g_id_lblSizeInfo," Total Size: " & round($iTotalSize,2) & " " & $sTotalSizeUnit)

	$g_iTotalSizeBytesLast = $g_iTotalSizeBytes

EndFunc

func _IsChecked($idControlID)

	; Check if CheckBox is checked
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED

EndFunc

Func _GetFilesDetails($aArray, $sPathRelative = "")

	#forceref $sPathRelative

	Local $aTempFileTime[ubound($aArray)][7]

	$aTempFileTime[0][0] = $aArray[0]
	for $i = 1 to ubound($aArray)-1
		Local $sFileFullPath = ($sPathRelative = "") ? ($aArray[$i]) : ($sPathRelative & "\" & $aArray[$i])
		Local $aFileTime = FileGetTime($sFileFullPath,$FT_MODIFIED,$FT_ARRAY)
		$aTempFileTime[$i][0] = $aArray[$i]
		for $j = 0 to 5
			$aTempFileTime[$i][$j+1] = $aFileTime[$j]
		Next
	Next

	Return $aTempFileTime

EndFunc

func Check_Updates()

	; Close any previous TreeView Item Selected State processing
	_GUITreeViewEx_CloseTV($g_idTV_New)
	_GUITreeViewEx_CloseTV($g_idTV_Updated)

	GUICtrlSetData($g_id_lblInfo, "Retrieving file list from Google Drive. Please Wait...")

	Local $aGetList = GetDriveFilesRec($g_sSharedFolderID, $g_sApiKey)

	GUICtrlSetData($g_id_lblInfo, "File list retrieved from Google Drive.")

	Local $aReturn = Array_to_TreeView_Advanced($aGetList, Default, Default, 3, "application/vnd.google-apps.folder")

	$g_aFolderListDetails = Compare_Files_New_Updated($aReturn, $g_sInstallPath) ;Returns 3 arrays [0]: Holds "All" data, [1]: Only "New Item" Data, [2]: Only "Updated Item" Data

	; Reset Total Size of selected files
	$g_iTotalSizeBytes = 0

	; Set Checkboxes to unchecked state
	GUICtrlSetState($g_idCheck_AllNew, $GUI_UNCHECKED)
	GUICtrlSetState($g_idCheck_AllUpdated, $GUI_UNCHECKED)

	; $g_aTV_Event is Global to pass TV Array to Item Selection
	$g_aTV_Event[0] = Populate_TreeView_Advanced($g_aFolderListDetails[1], $g_idTV_New, False)
	$g_aTV_Event[1] = Populate_TreeView_Advanced($g_aFolderListDetails[2], $g_idTV_Updated, False)

	; Initiate TreeView Item Selected State Processing
	_GUITreeViewEx_InitTV($g_idTV_New)
	_GUITreeViewEx_InitTV($g_idTV_Updated)

EndFunc

Func Compare_Files_New_Updated($aCompare, $sFolderPath) ; = "FullPath")

	; Set Time Difference Threshold (seconds)
	Local $iTimeDiffThreshold = 10

	Local $aCompareThis = $aCompare[1]

	; Set Index values for ease of use
	Local $iNewItemIndex = ubound($aCompareThis,2) + 0
	Local $iUpdatedItemIndex = ubound($aCompareThis,2) + 1
	Local $iNewIndex = ubound($aCompareThis,2) + 2
	Local $iUpdatedIndex = ubound($aCompareThis,2) + 3

	; Redim to hold update/new info
	ReDim $aCompareThis[ubound($aCompareThis)][ubound($aCompareThis,2)+4]

	Local $aReturn[3]
	Local $aCompareNew = $aCompareThis ;[ubound($aCompareThis)][ubound($aCompareThis,2)]
	Local $aCompareUpdate = $aCompareThis ;[ubound($aCompareThis)][ubound($aCompareThis,2)]

	Local $iParentIndex
	Local $sParentFolder

	;#forceref $iNewItemIndex, $iUpdatedItemIndex

	; UTC Time Correction
	Local $tSystemUTC = _Date_Time_GetSystemTime ( )
	Local $tSystem = _Date_Time_GetLocalTime ( )

	Local $sSystemUTC = _Date_Time_SystemTimeToDateTimeStr($tSystemUTC, 1)
	Local $sSystem = _Date_Time_SystemTimeToDateTimeStr($tSystem, 1)

	Local $iUTCDiff = _DateDiff('s', $sSystemUTC, $sSystem)

	;Local $bFullPath = ($sFolderPath = "FullPath") ? (True) : (False)
	if StringRight($sFolderPath,1) = "\" then StringTrimRight($sFolderPath,1) ; trim if path has "\" appended

	; Recurse through $aCompareThis Array
	Local $iStartIndex = 0
	if UBound($aCompareThis)-1 <> $aCompareThis[0][0] or $aCompareThis[0][6] = "Not a PC Folder List" then $iStartIndex = 1 ; Set $iStartIndex = 1 if first row is not a valid Folder/File

	for $i = $iStartIndex to UBound($aCompareThis)-1
		Local $sItemName = $aCompareThis[$i][6+$aCompareThis[$i][2]]
		Local $sItemNameCopy = $sItemName
		Local $sItemPath = $aCompareThis[$i][6]
		Local $sItemPathCopy = $sItemPath

		if $aCompareThis[$i][0] = 0 then
			; if file type is a3x then change it to $g_sExtension while searching
			Local $sFileExtension = StringTrimLeft($sItemName,StringInStr($sItemName,".",0,-1))
			if $sFileExtension = "a3x" then $sItemPath = StringTrimRight($sItemPath,3) & $g_sExtension
		EndIf

		Local $aFileTime[6]
		$aFileTime = FileGetTime($sFolderPath & "\" & $sItemPath,$FT_MODIFIED,$FT_ARRAY)

		if $aCompareThis[$i][0] = 1 then ; Folder Item
			if not (FileExists($sFolderPath & "\" & $sItemPath)) Then ; Folder added recently, or deleted by user(?)
				; Folder doesn't exist on Client
				; Add "New" to Folder and all children (will come from recursing)
				$aCompareThis[$i][$iNewIndex] = "(New)"
				$aCompareNew[$i][$iNewIndex] = "(New)"

				; Add "New Item" to all parents
				for $j = 1 to $aCompareThis[$i][2]-1 ; May need to be adjusted when fullpath is used
					$sParentFolder = StringTrimRight($sItemPathCopy,StringLen($sItemNameCopy) + 1)
					$iParentIndex = _ArraySearch($aCompareThis,$sParentFolder,Default,Default,Default,Default,Default,6,False)

					if $aCompareThis[$iParentIndex][$iNewItemIndex] = "" Then
						$aCompareThis[$iParentIndex][$iNewItemIndex] = "(New Item)"
						$aCompareNew[$iParentIndex][$iNewItemIndex] = "(New Item)"
						$sItemPathCopy = $aCompareThis[$iParentIndex][6]
						$sItemNameCopy = $aCompareThis[$iParentIndex][$aCompareThis[$iParentIndex][2]+6]
					Else
						ExitLoop
					EndIf
				Next
			Else
				; Folder Exists on Client
				; Do Nothing

			EndIf
		Else ; File Item
			if not (FileExists($sFolderPath & "\" & $sItemPath)) Then ; File added recently, or deleted by user(?)
				; File doesn't exist on Client
				; Add "New" to Item
				$aCompareThis[$i][$iNewIndex] = "(New)"
				$aCompareNew[$i][$iNewIndex] = "(New)"

				; Add "New Item" to all parent folders
				for $j = 1 to $aCompareThis[$i][2]-1 ; May need to be adjusted when fullpath is used
					$sParentFolder = StringTrimRight($sItemPathCopy,StringLen($sItemNameCopy) + 1)
					$iParentIndex = _ArraySearch($aCompareThis,$sParentFolder,Default,Default,Default,Default,Default,6,False)

					if $aCompareThis[$iParentIndex][$iNewItemIndex] = "" Then
						$aCompareThis[$iParentIndex][$iNewItemIndex] = "(New Item)"
						$aCompareNew[$iParentIndex][$iNewItemIndex] = "(New Item)"
						$sItemPathCopy = $aCompareThis[$iParentIndex][6]
						$sItemNameCopy = $aCompareThis[$iParentIndex][$aCompareThis[$iParentIndex][2]+6]
					Else
						ExitLoop
					EndIf
				Next

			Else
				; File Exists on Client, compare Modified Time
				; If Server "Newer" then Add "Updated" to Item, Add "Updated Item" to all parent folders
				Local $sLocalDate = $aFileTime[0] & "/" & $aFileTime[1] & "/" & $aFileTime[2] & " " & _
									$aFileTime[3] & ":" & $aFileTime[4] & ":" & $aFileTime[5]
				Local $sServerDate = $aCompareThis[$i][17] & "/" & $aCompareThis[$i][18] & "/" & $aCompareThis[$i][19] & " " & _
									 $aCompareThis[$i][20] & ":" & $aCompareThis[$i][21] & ":" & $aCompareThis[$i][22]

				Local $iTimeDiffSeconds = _DateDiff('s', $sLocalDate, $sServerDate) + $iUTCDiff ; Local - UTC

				if $iTimeDiffSeconds >= $iTimeDiffThreshold then ; server is newer
					; Add "Updated" to Item
					$aCompareThis[$i][$iUpdatedIndex] = "(Updated)"
					$aCompareUpdate[$i][$iUpdatedIndex] = "(Updated)"

					; Add "Updated Item" to all parents
					for $j = 1 to $aCompareThis[$i][2]-1 ; May need to be adjusted when fullpath is used
					$sParentFolder = StringTrimRight($sItemPathCopy,StringLen($sItemNameCopy) + 1)
					$iParentIndex = _ArraySearch($aCompareThis,$sParentFolder,Default,Default,Default,Default,Default,6,False)

					if $aCompareThis[$iParentIndex][$iUpdatedItemIndex] = "" Then
						$aCompareThis[$iParentIndex][$iUpdatedItemIndex] = "(Updated Item)"
						$aCompareUpdate[$iParentIndex][$iUpdatedItemIndex] = "(Updated Item)"
						$sItemPathCopy = $aCompareThis[$iParentIndex][6]
						$sItemNameCopy = $aCompareThis[$iParentIndex][$aCompareThis[$iParentIndex][2]+6]
					Else
						ExitLoop
					EndIf
				Next
				Else

				EndIf

				; If Server "Same" or "Older" then
				; Do Nothing

			EndIf
		EndIf
	Next

	Local $aReturn0[2]
	Local $aReturn1[2]
	Local $aReturn2[2]

	$aReturn0[0] = $aCompare[0]
	$aReturn1[0] = $aCompare[0]
	$aReturn2[0] = $aCompare[0]
	$aReturn0[1] = $aCompareThis
	$aReturn1[1] = $aCompareNew
	$aReturn2[1] = $aCompareUpdate

	$aReturn[0] = $aReturn0
	$aReturn[1] = $aReturn1
	$aReturn[2] = $aReturn2

	Return $aReturn

EndFunc


; Some older version, not used ATM
Func Compare_Files_All($aCompareThis, $aCompareWith, $idTV)

	Local $hTV = GUICtrlGetHandle($idTV)

	Local $aNewItem[1][ubound($aCompareThis,2)]
	Local $aUpdatedItem[1][ubound($aCompareThis,2)]

	Local $aTemp[1][ubound($aCompareThis,2)]

	Local $tSystemUTC = _Date_Time_GetSystemTime ( )
	Local $tSystem = _Date_Time_GetLocalTime ( )

	Local $sSystemUTC = _Date_Time_SystemTimeToDateTimeStr($tSystemUTC, 1)
	Local $sSystem = _Date_Time_SystemTimeToDateTimeStr($tSystem, 1)

	Local $iUTCDiff = _DateDiff('s', $sSystemUTC, $sSystem)

	for $i = 0 to UBound($aCompareThis)-1
		Local $hItem = $aCompareThis[$i][5]
		Local $sItemName = $aCompareThis[$i][6+$aCompareThis[$i][2]]
		Local $sItemPath = $aCompareThis[$i][6]

		if $hItem <> "" then ; Valid Folder/File
			if $aCompareThis[$i][0] = 1 then ; Folder Item
				if not (FileExists($g_sInstallPath & "\" & $sItemPath)) Then ; Folder added recently, or deleted by user(?)
					; Folder doesn't exist on Client
					; Add "New" to Folder and all children (will come from recursing), "New Item" to all parents
					_GUICtrlTreeView_SetText ($hTV, $hItem, $sItemName & " (New)")

 					; Add this and all children to  NewArray (will come from recursing)
					$aTemp = _ArrayExtract($aCompareThis, $i, $i)
					_ArrayConcatenate($aNewItem, $aTemp)
				Else
					; Folder Exists on Client
					; Do Nothing
				EndIf
			Else ; File Item

				; if file type is a3x then change it to $g_sExtension while searching
				Local $sFileExtension = StringTrimLeft($sItemName,StringInStr($sItemName,".",0,-1))
				if $sFileExtension = "a3x" then $sItemPath = StringTrimRight($sItemPath,3) & $g_sExtension

				if not (FileExists($g_sInstallPath & "\" & $sItemPath)) Then ; File added recently, or deleted by user(?)
					; File doesn't exist on Client
					; Add "New" to Item, Add "New Item" to all parent folders
					_GUICtrlTreeView_SetText ($hTV, $hItem, $sItemName & " (New)")

					; Add to NewArray
					$aTemp = _ArrayExtract($aCompareThis, $i, $i)
					_ArrayConcatenate($aNewItem, $aTemp)
				Else
					; File Exists on Client, compare Modified Time
					; If Server "Newer" then Add "Updated" to Item, Add "Updated Item" to all parent folders
					Local $iInstallFilesIndex = _ArraySearch($aCompareWith, $sItemPath)
					Local $sLocalDate = $aCompareWith[$iInstallFilesIndex][1] & "/" & $aCompareWith[$iInstallFilesIndex][2] & "/" & $aCompareWith[$iInstallFilesIndex][3] & " " & _
										$aCompareWith[$iInstallFilesIndex][4] & ":" & $aCompareWith[$iInstallFilesIndex][5] & ":" & $aCompareWith[$iInstallFilesIndex][6]
					Local $sServerDate = $aCompareThis[$i][17] & "/" & $aCompareThis[$i][18] & "/" & $aCompareThis[$i][19] & " " & _
										 $aCompareThis[$i][20] & ":" & $aCompareThis[$i][21] & ":" & $aCompareThis[$i][22]

					Local $iTimeDiffSeconds = _DateDiff('s', $sLocalDate, $sServerDate) + $iUTCDiff ; Local - UTC

					if $iTimeDiffSeconds >= 10 then ; server is newer
						; Add "Updated" to Item
						_GUICtrlTreeView_SetText ($hTV, $hItem, $sItemName & " (Updated)")

						; Add to UpdatedArray
						$aTemp = _ArrayExtract($aCompareThis, $i, $i)
						_ArrayConcatenate($aUpdatedItem, $aTemp)
					Else
						; server is older
						; Do Nothing
					EndIf

					; If Server "Same" or "Older" then
					; Do Nothing
				EndIf
			EndIf
		EndIf
	Next

EndFunc

Func Sync_Updates()

	if $g_aTV_Event[0] = "" or $g_aTV_Event[1] = "" then return ; return if any of the New or Updated Arrays are not arrays (empty)

	; Get CheckedState for both TreeViews, and enter into an array[ubound(new)+ubound(updated)][6] - array size should never exceed these values
	; array[$i][0] = 0 or 1 - 1 for folder
	; array[$i][1] = 0 or 1 - 1 if updated (need for backing up if relevant checkbox is checked)
	; array[$i][2] = File/FolderID
	; array[$i][3] = RelativePath
	; array[$i][4] = File/Folder Name
	; array[$i][5] = 0-4	    ; 0: Copy as usual
								; 1: script file updated (perform ext change)
								; 2: ch_updater updated (perform ext change)(need batch file)
								; 3: AutoIt#.exe updated same version (need batch file to delete old and copy new)
								; 4: AutoIt#.exe updated new version (need batch file to delete old)(need Registry Update)(need ini file update)
	; array[$i][6] = FileSize

	; Check if file or folder
		; if folder then check if exists
			; if not(exists) then create dir

		; if file then Download by FileID to InstallDir\Temp\Download\RelativePath

		; Copy original file to InstallDir\Temp\Backup\datetime\RelativePath if "keep backup" is checked

		; Copy File to Charter with FC_CREATEPATH param according to extension change

		; Delete file from InstallDir\Temp\Download\RelativePath if copy is successful

		; Update TreeViews somehow, so downloaded files dont show

		; Delete InstallDir\Temp\Download\ contents if no files left _ArrayRec(filesonly) = ""

	; Update ini file and Registry if necessary
		; Update ini: AutoItVer to new exe name
		; Update Registry RegHive\.Ext\shell\open\command - Default with new exe name

	; Create batch file if needed
		; Warn user that app will close and run a batch script (MsgBox)
		; Start Batch file

	; ------------------------------------------------

	; Find out number of rows needed for $aDownloadList
	Local $iArrayRowSize = 0
	for $iArrayNo = 0 to 1
		Local $aItems = $g_aTV_Event[$iArrayNo]
		Local $hTV = GUICtrlGetHandle($aItems[0][3])
		for $i = 0 to Ubound($aItems)-1
			Local $hItem = $aItems[$i][5]
			if $hItem <> "" Then
				if _GUICtrlTreeView_GetChecked($hTV, $hItem) then $iArrayRowSize += 1
			EndIf
		Next
	Next

	if $iArrayRowSize = 0 then return

	Local $sFileName
	Local $iFileSize

	Local $aDownloadList[$iArrayRowSize][7]
	Local $iRowIndex = 0
	Local $iFileCount = 0

	for $iArrayNo = 0 to 1
		$aItems = $g_aTV_Event[$iArrayNo]
		$hTV = GUICtrlGetHandle($aItems[0][3])
		for $i = 0 to Ubound($aItems)-1
			$hItem = $aItems[$i][5]
			if $hItem <> "" Then
				if _GUICtrlTreeView_GetChecked($hTV, $hItem) then
					$aDownloadList[$iRowIndex][0] = $aItems[$i][0] ; File or folder
					$aDownloadList[$iRowIndex][1] = $iArrayNo ; New or updated
					$aDownloadList[$iRowIndex][2] = $aItems[$i][11] ; File/Folder ID
					$aDownloadList[$iRowIndex][3] = $aItems[$i][6] ; RelativePath
					$aDownloadList[$iRowIndex][4] = $aItems[$i][$aItems[$i][2] + 6] ; File/Folder Name
					$aDownloadList[$iRowIndex][6] = $aItems[$i][$aItems[0][1] + 6 + 5] ; FileSize
					$sFileName = $aDownloadList[$iRowIndex][4]
					if $sFileName = $g_sAutoItVer then
						; AutoIt#.exe updated with same version
						$aDownloadList[$iRowIndex][5] = 3
					ElseIf StringRegExp($sFileName, "(?i)AutoIt\d.exe", $STR_REGEXPMATCH) = 1 Then
						; AutoIt#.exe updated to new version
						$aDownloadList[$iRowIndex][5] = 4
					elseif StringRight($sFileName, 3) = "a3x" Then
						; Script File updated
						$aDownloadList[$iRowIndex][5] = 1
						if $sFileName = "CH_Updater.a3x" then $aDownloadList[$iRowIndex][5] = 2 ; Update Copy type to 2 if script is the updater
					Else
						$aDownloadList[$iRowIndex][5] = 0
					EndIf
					if $aDownloadList[$iRowIndex][0] <> 1 then $iFileCount += 1
					$iRowIndex += 1
				EndIf
			EndIf
		Next
	Next

	Local $tSystem = _Date_Time_GetLocalTime ( )
	Local $sDateTime = _Date_Time_SystemTimeToDateTimeStr($tSystem, 1)
	$sDateTime = StringReplace($sDateTime,"/","-")
	$sDateTime = StringReplace($sDateTime,":",".")

	Local $bKeepBackup = (_IsChecked($g_idCheck_BackupUpdated)) ? (True) : (False)

	Local $bCreateBatch = False
	Local $bUpdateIni = False
	Local $bUpdateRegistry = False

	Local $g_sAutoItVerOld = ""
	Local $g_sAutoItVerNew = ""
	Local $sUpdaterName = ""
	Local $iCurrentFileNo = 1

	for $i = 0 to Ubound($aDownloadList)-1
		Local $bIsFolder = ($aDownloadList[$i][0] = 1) ? (True) :(False)
		Local $bIsUpdated = ($aDownloadList[$i][1] = 1) ? (True) : (False)
		Local $sFileID = $aDownloadList[$i][2]
		Local $sRelPath = $aDownloadList[$i][3]
		$sFileName = $aDownloadList[$i][4]
		Local $iCopyMethod = $aDownloadList[$i][5]
		Local $sRelPathNewExt = StringTrimRight($sRelPath,3) & $g_sExtension
		$iFileSize = $aDownloadList[$i][6]

		if $bIsFolder Then
			if (not FileExists($g_sInstallPath & "\" & $sRelPath) and not $bIsUpdated) then DirCreate($g_sInstallPath & "\" & $sRelPath)
		Else
			; Adjust FileSize
			Local $sFileSizeUnit ="B"
			Local $iSize = $iFileSize

			if $iSize/1024 >= 1 then
				$iSize = $iSize/1024
				$sFileSizeUnit = "KB"
			EndIf
			if $iSize/1024 >= 1 Then
				$iSize = $iSize/1024
				$sFileSizeUnit = "MB"
			EndIf
			if $iSize/1024 >= 1 Then
				$iSize = $iSize/1024
				$sFileSizeUnit = "GB"
			EndIf
			$iSize = round($iSize,2)

			; Download file to temp\download
			GUICtrlSetData($g_id_lblInfo,"Downloading (" & $iCurrentFileNo & "\" & $iFileCount & "): " & $sFileName & " - " & $iSize & " " & $sFileSizeUnit)
			$iCurrentFileNo += 1
			Drive_Download_File($sFileID, $g_sInstallPath & "\Temp\Download", $sFileName, $g_sApiKey)

			; Copy file to temp\download\relative path unless Updater or Updated AutoIt3.exe
			Select
				Case $iCopyMethod = 0
					FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sFileName, $g_sInstallPath & "\Temp\Download" & "\" & $sRelPath, $FC_CREATEPATH)

				Case $iCopyMethod = 1
					FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sFileName, $g_sInstallPath & "\Temp\Download" & "\" & $sRelPathNewExt, $FC_CREATEPATH)

				Case $iCopyMethod = 2
					FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sFileName, $g_sInstallPath & "\Temp" & "\" & StringTrimRight($sFileName,3) & $g_sExtension)

				Case $iCopyMethod = 3
					FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sFileName, $g_sInstallPath & "\Temp" & "\" & $sFileName)

				Case $iCopyMethod = 4
					FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sFileName, $g_sInstallPath & "\Temp\Download" & "\" & $sRelPath, $FC_CREATEPATH)

			EndSelect

			; Copy to the final destination according to copy method
			if $iCopyMethod = 0 Then
				; Keep backup if updated
				if ($bIsUpdated and $bKeepBackup) then FileCopy($g_sInstallPath & "\" & $sRelPath, $g_sInstallPath & "\Temp\Backup\" & $sDateTime & "\" & $sRelPath, $FC_CREATEPATH)
				; Copy to final destination
				FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sRelPath, $g_sInstallPath & "\" & $sRelPath, $FC_OVERWRITE + $FC_CREATEPATH)

			elseif $iCopyMethod = 1 Then
				; Change extension
				$sRelPathNewExt = StringTrimRight($sRelPath,3) & $g_sExtension
				; Copy to temp\download\relative path
				FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sRelPath, $g_sInstallPath & "\Temp\Download" & "\" & $sRelPathNewExt, $FC_OVERWRITE)
				; Keep backup if checked
				if ($bIsUpdated and $bKeepBackup) then FileCopy($g_sInstallPath & "\" & $sRelPathNewExt, $g_sInstallPath & "\Temp\Backup\" & $sDateTime & "\" & $sRelPathNewExt, $FC_CREATEPATH)
				; Copy to Final Destination
				FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sRelPathNewExt, $g_sInstallPath & "\" & $sRelPathNewExt, $FC_OVERWRITE)

			elseif $iCopyMethod = 2 then
				$bCreateBatch = True
				; Change extension
				$sRelPathNewExt = StringTrimRight($sRelPath,3) & $g_sExtension
				; Variables for Batch File
				$sUpdaterName = StringTrimRight($sFileName,3) & $g_sExtension
				; Keep backup if checked
				if ($bIsUpdated and $bKeepBackup) then FileCopy($g_sInstallPath & "\" & $sRelPathNewExt, $g_sInstallPath & "\Temp\Backup\" & $sDateTime & "\" & $sRelPathNewExt, $FC_CREATEPATH)

			elseif $iCopyMethod = 3 then
				$bCreateBatch = True
				; Variables for Batch File
				$g_sAutoItVerOld = $sFileName
				; Keep backup if checked
				if ($bIsUpdated and $bKeepBackup) then FileCopy($g_sInstallPath & "\" & $sRelPath, $g_sInstallPath & "\Temp\Backup\" & $sDateTime & "\" & $sRelPath, $FC_CREATEPATH)

			elseif $iCopyMethod = 4 then
				$bCreateBatch = True
				$bUpdateIni = True
				$bUpdateRegistry = True
				; Variables for Batch File
				$g_sAutoItVerOld = $g_sAutoItVer
				$g_sAutoItVerNew = $sFileName
				; Keep backup if checked
				if ($bKeepBackup) then FileCopy($g_sInstallPath & "\Apps" & "\" & $g_sAutoItVerOld, $g_sInstallPath & "\Temp\Backup\" & $sDateTime & "\Apps" & "\" & $g_sAutoItVerOld, $FC_CREATEPATH)
				; Copy to final destination
				FileMove($g_sInstallPath & "\Temp\Download" & "\" & $sRelPath, $g_sInstallPath & "\" & $sRelPath, $FC_OVERWRITE + $FC_CREATEPATH)
			EndIf
		endif
	next

	; Update Ini if required
	If $bUpdateIni Then
		IniWrite($g_sIniFile,"Install","AutoItVer",$g_sAutoItVerNew)
	EndIf

	; Update Registry if required
	if $g_sRegistryChecked = True and $bUpdateRegistry = True then
		RegRead($g_sRegHive & "."  & $g_sExtension,"")
		if @error <= 0 then
			; Key already exists, check if it is a LazyD Charter key
			if RegRead($g_sRegHive & "." & $g_sExtension,"Check") = """LazyD Charter""" Then
				RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell\open\command", "","REG_SZ","""" & $g_sInstallPath & "\Apps\" & $g_sAutoItVerNew & """ ""%1""")
			EndIf
		EndIf
	EndIf

	; If no files exist under temp/download then delete folder and create new
	Local $aRemainingFiles = _FileListToArrayRec($g_sInstallPath & "\Temp\Download", Default, $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_NOSORT, $FLTAR_RELPATH)
	if $aRemainingFiles = "" Then
		DirRemove($g_sInstallPath & "\Temp\Download", $DIR_REMOVE)
		DirCreate($g_sInstallPath & "\Temp\Download")
	EndIf

	Local $sMsgBoxMessage = "Downloading of files have finished. Closing ""LazyD Charter - Updater""."
	if $bCreateBatch = True then $sMsgBoxMessage &= @CRLF & "An automatically created batch file will run to update running processes."

	msgbox($MB_OK,"Update Completed", $sMsgBoxMessage)

	; Create Batch File if required
	If $bCreateBatch Then
		Local $sRoot = StringLeft($g_sInstallPath, 2)
		Local $hFile

		FileDelete($g_sInstallPath & "\Temp\CopyRemainingFiles.bat")
		$hFile = FileOpen($g_sInstallPath & "\Temp\CopyRemainingFiles.bat", $FO_APPEND)
		FileWriteLine($hFile, "@PUSHD %~dp0")
		FileWriteLine($hFile, "@ECHO OFF")
		FileWriteLine($hFile, "ECHO LazyD Charter:")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO This is an automatically created batch file")
		FileWriteLine($hFile, "ECHO which will delete running script files, copy")
		FileWriteLine($hFile, "ECHO updated ones and will delete itself after running.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		if $sUpdaterName <> "" then FileWriteLine($hFile, "ECHO -COPY updated Updater Script")
		if $g_sAutoItVerOld <> "" and $g_sAutoItVerNew = "" then FileWriteLine($hFile, "ECHO -COPY updated " & $g_sAutoItVerOld)
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Changing Drive to """ & $sRoot & """")
		FileWriteLine($hFile, $sRoot)
		FileWriteLine($hFile, "ECHO Changing Directory to """ & $g_sInstallPath & "\Temp""")
		FileWriteLine($hFile, "CD """ & $g_sInstallPath & "\Temp""")
		FileWriteLine($hFile, "ECHO Batch File: %CD%\CopyRemainingFiles.bat")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Waiting for 5 seconds to let script and interpreter")
		FileWriteLine($hFile, "ECHO to shutdown.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "TIMEOUT 5 >NUL")
		FileWriteLine($hFile, "SET COPYCMD=/Y")
		if $sUpdaterName <> "" then FileWriteLine($hFile, "MOVE """ & $g_sInstallPath & "\Temp\" & $sUpdaterName & """ """ & $g_sInstallPath & "\Apps\" & $sUpdaterName & """")
		if $g_sAutoItVerOld <> "" and $g_sAutoItVerNew = "" then FileWriteLine($hFile, "MOVE """ & $g_sInstallPath & "\Temp\" & $g_sAutoItVerOld & """ """ & $g_sInstallPath & "\Apps\" & $g_sAutoItVerOld & """")
		if $g_sAutoItVerOld <> "" and $g_sAutoItVerNew <> "" then FileWriteLine($hFile, "DEL /F /Q """ & $g_sInstallPath & "\Apps\" & $g_sAutoItVerOld & """")
		FileWriteLine($hFile, "DEL /F /Q """ & $g_sInstallPath & "\Temp\CopyRemainingFiles.bat""")
		FileClose($hFile)

		; Run Batch file and exit Updater App
		Run("""" & $g_sInstallPath & "\Temp\CopyRemainingFiles.bat""")
		Exit

	EndIf

	Quit_App()

EndFunc

func Quit_App()

	; Close App Window, Exit App
	GUIDelete(@GUI_WinHandle)
	Exit

EndFunc