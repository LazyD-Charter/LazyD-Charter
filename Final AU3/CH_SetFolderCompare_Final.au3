#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_SetFolderManager.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Comment=Set Folder and SetCopy Folders Sync
#AutoIt3Wrapper_Res_Description=Set Folder and SetCopy Folders Sync
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=LazyD Charter
#AutoIt3Wrapper_Res_ProductVersion=1.0
#AutoIt3Wrapper_Res_CompanyName=LazyD is not a company!
#AutoIt3Wrapper_Res_LegalCopyright=None
#AutoIt3Wrapper_Res_LegalTradeMarks=None
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Array.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <TreeViewConstants.au3>
#include <GuiTreeView.au3>
#include <ComboConstants.au3>
#include <AutoItConstants.au3>
#include <GuiComboBox.au3>

#Region ; Global Stuff
AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)

Const $sSamples = "\Samples" ; Samples Folder
Const $sSet = "\Set" ; Set Folder
Const $sSetCopy = "\SetCopy" ; SetCopy Folder

Global $g_sSamplesPath ; Path to the Folder that contains the "Set" Folder
Global $g_iSampleCopies ; Number of SampleCopies
Global $g_sCopyMethod ; Copy Method (del: Delete SetCopy Folders and re-copy all, over: Copy all overwriting existing files, no-over: Copy all files not existing, skip those that do)

Global $g_idLabel_SetCopy
Global $g_idTreeView_SetCopyFolder
Global $g_idComboSampleCopy
Global $g_idInput_SampleCopy
Global $g_idComboCopyMethod

Global $g_bGUI_MODE = True

if $CmdLine[0] = 0 Then
	; Script started by User (no params needed)
	; $g_iSampleCopies
	; $g_sCopyMethod
Elseif $CmdLine[0] = 2 Then
	; Script started by Excel (params required)
	$g_iSampleCopies = Int($CmdLine[1], $NUMBER_32BIT)
	$g_sCopyMethod = $CmdLine[2]

	; Check if $g_iSampleCopies is an integer, terminate if not, then terminate if less than 1
	if not IsInt($g_iSampleCopies) then Exit
	if $g_iSampleCopies < 1 then Exit

	; Check if $g_sCopyMethod is a valid parameter, terminate if not
	if StringInStr("DELETE OVERWRITE NO-OVERWRITE", $g_sCopyMethod) = 0 then Exit

	; If all params are correct then set GUI_Mode = False
	$g_bGUI_MODE = False
Else
	; Wrong number of params, abort!!!
	Exit
EndIf

; Ini File Path
Global $g_sIniFile = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"

; Read ini file for InstallDirectory\Samples folder path
Global $g_sInstallPath = IniRead($g_sIniFile, "Install", "Install_Path","")
Global $g_sExtension = IniRead($g_sIniFile,"Install","Extension","NotRead")

#include <LazyD Charter Color Theme.au3>
#include <FolderList_to_TreeView.au3>

if $g_bGUI_MODE then CreateAppWindow() ; Run App in GUI Mode
Sync_NoGUI() ; Run App in No_GUI Mode

#EndRegion

func CreateAppWindow()

	; Terminate script with a warning MsgBox if Install_Path can not be read
	if $g_sInstallPath = "" then
		MsgBox($MB_OK,"Warning","Either ""APPDATA\Roaming\LazyD Charter\LazyD Charter.ini"" is missing or Couldn't read contents for ""Install_Path"" key value." & @CRLF & "Terminating script!")
		Exit
	EndIf

	$g_sSamplesPath = $g_sInstallPath & $sSamples

	; Create the App Window
	Local $hAppWindow = GUICreate("LazyD Charter - SetFolderManager",830,520,-1,-1,-1,-1)
	GUISetIcon($g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico")
	GUISetBkColor($COL_APP_WINDOW, $hAppWindow)
	GUISetOnEvent($GUI_EVENT_CLOSE, "App_Close")

	; Create GUI Elements and Set On Event

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Set Folder label
	GUICtrlCreateLabel("Set Folder Contents",10,10,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create SetCopy Folder label
	GUICtrlCreateLabel("Set #",420,10,290,20,$SS_RIGHT,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Set Folder Path Label
	GUICtrlCreateLabel($g_sSamplesPath & $sSet,10,45,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	; Create SetCopy Folder Path Label
	$g_idLabel_SetCopy = GUICtrlCreateLabel($g_sSamplesPath & $sSetCopy,420,45,400,20,-1,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1,$COL_GROUP_HEADER)

	Local $sSetPath = $g_sSamplesPath & $sSet
	Local $aSetFoldersFiles = _FileListToArrayRec($sSetPath,Default,$FLTAR_FILESFOLDERS,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	; Create Set TreeView and populate
	Local $idTreeView = GUICtrlCreateTreeView(10,70,400,300,-1,-1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 12, 400, 0, "")

	Local $aReturn = Array_to_TreeView_Advanced_1D($aSetFoldersFiles, $sSetPath)
	Populate_TreeView_Advanced_1D($aReturn, $idTreeView, False)

	; Create SetCopy TreeView
	$g_idTreeView_SetCopyFolder = GUICtrlCreateTreeView(420,70,400,300,-1,-1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 12, 400, 0, "")

	; Get Max Number of SetCopy folders
	Local $sSetCopyPath = $g_sSamplesPath & $sSetCopy
	Local $aSetCopyFolders = _FileListToArray($sSetCopyPath,"*",$FLTA_FOLDERS,false)
	Local $i_MaxSampleCopy

	if $aSetCopyFolders="" then
		$i_MaxSampleCopy = 0
	Else
		$i_MaxSampleCopy = $aSetCopyFolders[ubound($aSetCopyFolders)-1]
		$i_MaxSampleCopy = StringTrimLeft($i_MaxSampleCopy,3)
		$aReturn = Array_to_TreeView_Advanced_1D($aSetCopyFolders, $sSetCopyPath)
		Populate_TreeView_Advanced_1D($aReturn, $g_idTreeView_SetCopyFolder, False)
	EndIf

	; Create ComboBox for Sample Copy selection
	$g_idComboSampleCopy = GUICtrlCreateCombo("Copy",720,5,100,25,-1,-1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	_GUICtrlComboBox_ResetContent($g_idComboSampleCopy)
	GUICtrlSetOnEvent($g_idComboSampleCopy, "Sample_Copy_Change")

	Local $sComboSampleCopy
	if $i_MaxSampleCopy <> 0 Then
		$sComboSampleCopy = "1"
		for $i = 2 to $i_MaxSampleCopy
			$sComboSampleCopy &= "|" & $i
		next
		GUICtrlSetData($g_idComboSampleCopy,$sComboSampleCopy)
	endif

	; Create Input Box for Sample Copy change
	$g_idInput_SampleCopy = GUICtrlCreateInput("",240,402,70,30,$SS_CENTER + $ES_NUMBER,-1)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 18, 400, 0, "")

	; Create SetCopyNumber label for Input Sample Copy change
	GUICtrlCreateLabel("Set New Copy Number",10,405,190,20,$SS_RIGHT,-1)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlSetData($g_idInput_SampleCopy,$i_MaxSampleCopy)

	; Create Sync Set-SetCopy Folders Button
	Local $iBtn_Sync = GUICtrlCreateButton("SYNC FOLDERS",620,390,200,50,-1,-1)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetOnEvent($iBtn_Sync, "Sync_GUI")
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create ComboBox for Copy Method
	$g_idComboCopyMethod = GUICtrlCreateCombo("NO-OVERWRITE",355,402,185,30,-1,-1)
	GUICtrlSetData($g_idComboCopyMethod, "OVERWRITE|DELETE")
	GUICtrlSetBkColor($g_idComboCopyMethod, $COL_GROUP)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create CLOSE Button
	Local $iBtn_Close = GUICtrlCreateButton("CLOSE",720,450,100,50,-1,-1)
	GUICtrlSetBkColor($iBtn_Close, $COL_BTN_QUIT)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetOnEvent($iBtn_Close, "App_Close")

	; Create Graphic GUI Controls (for eye candy)
	GUICtrlCreateGraphic(10, 385, 810, 61) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(10, 505, 810, 5) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	; Display the App Window
	GUISetState(@SW_SHOW,$hAppWindow)

	; MessageLoop
	While 1
		sleep(100)
	WEnd

EndFunc

func Sync_NoGUI()

	Local $iCopyMethod = ($g_sCopyMethod = "OVERWRITE") ? ($FC_OVERWRITE) : ($FC_NOOVERWRITE)

	; Terminate script if Install_Path can not be read
	if $g_sInstallPath = "" then Exit

	$g_sSamplesPath = $g_sInstallPath & $sSamples

	;--------------------------------------------------------
	; Create missing "SetCopy\Setn" folders
	; Get ArraySetCopyFolders - non-recursively
	; for i = 1 to n (Param2)
	; if "Setn" doesnt exist create "Setn" folder

	Local $sFolderPath
	Local $aSetCopies = _FileListToArray($g_sSamplesPath & $sSetCopy, Default, $FLTA_FOLDERS)

	; Delete any SetCopy\Set# folder if # > $g_iSampleCopies
	for $i = 1 to $aSetCopies[0]
		if int(StringTrimLeft($aSetCopies[$i],3), $NUMBER_32BIT) > $g_iSampleCopies then DirRemove($g_sSamplesPath & $sSetCopy & $sSet & int(StringTrimLeft($aSetCopies[$i],3), $NUMBER_32BIT), $DIR_REMOVE)
	Next

	; Depending on CopyMethod Delete/Create SetCopy\Set# folders
	for $i=1 to $g_iSampleCopies
		$sFolderPath = $g_sSamplesPath & $sSetCopy & $sSet & $i
		if $g_sCopyMethod = "DELETE" Then DirRemove($sFolderPath, $DIR_REMOVE)
		if not (FileExists($sFolderPath)) Then  DirCreate($sFolderPath)
	next

	;--------------------------------------------------------
	; Create any missing subFolders under "SetCopy\Setn"
	; Get ArraySet of all subFolders under "Set" recursively
	; for i = 1 to n (Param2)
		; for each subFolder in ArraySet check if subFolder exists under "Setn"
			; if subFolder doesn't exist then crate SubFolder

	Local $aSetFolders
	Local $sSetPath

	$sSetPath = $g_sSamplesPath & $sSet
	$aSetFolders = _FileListToArrayRec($sSetPath,Default,$FLTAR_FOLDERS,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	for $i = 1 to $g_iSampleCopies
		for $j = 1 to UBound($aSetFolders)-1
			$sFolderPath=$g_sSamplesPath & $sSetCopy & $sSet & $i & "\" & $aSetFolders[$j]
			if not (FileExists($sFolderPath)) then DirCreate($sFolderPath)
		Next
	next

	;--------------------------------------------------------
	; Copy/Rename any missing files under "SetCopy" folder and any subfolders
		; Get ArraySetFiles for all files inside "Set" folder and any files inside subfolders of "Set" folder - recursively
		; for each file in ArraySetFiles
			; if file doesnt exist under "Setn" then
				; copy file from "Set" to "Setn"
				; rename file to (file & "-" & n)

	Local $aSetFiles
	Local $sFileLeft ;File in Set Folder (fullpath)
	Local $sFileRight ;File in SetCopy Folder (fullpath)
	Local $sExt ;Extension of the file
	Local $sLeftPath ;Used by FileCopy, FullPath to the Set File
	Local $sRightPath ;Used by FileCopy, FullPath to the SetCopy File

	$aSetFiles = _FileListToArrayRec($sSetPath,Default,$FLTAR_FILES,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	for $i = 1 to $g_iSampleCopies
		for $j = 1 to ubound($aSetFiles)-1
			$sExt = StringRight($aSetFiles[$j],StringLen($aSetFiles[$j])-StringInStr($aSetFiles[$j],".",0,-1)+1)

			$sFileLeft = StringLeft($aSetFiles[$j],StringInStr($aSetFiles[$j],".",0,-1)-1)
			$sLeftPath = $g_sSamplesPath & $sSet & "\" & $aSetFiles[$j]

			$sFileRight = $sFileLeft & "-" & $i & $sExt
			$sRightPath = $g_sSamplesPath & $sSetCopy & $sSet & $i & "\" & $sFileRight

			FileCopy($sLeftPath, $sRightPath, $iCopyMethod)
		Next
	next

	Exit

EndFunc

func Sync_GUI()

	$g_sCopyMethod = GUICtrlRead($g_idComboCopyMethod)
	Local $iCopyMethod = ($g_sCopyMethod = "OVERWRITE") ? ($FC_OVERWRITE) : ($FC_NOOVERWRITE)

	;--------------------------------------------------------
	; Create missing "SetCopy\Setn" folders
	; Get ArraySetCopyFolders - non-recursively
	; for i = 1 to n (Param2)
	; if "Setn" doesnt exist create "Setn" folder

	Local $sSetCopyPath = $g_sSamplesPath & $sSetCopy

	$g_iSampleCopies = number(GUICtrlRead($g_idInput_SampleCopy), $NUMBER_32BIT)

	if not (IsNumber ($g_iSampleCopies)) then Return

	if $g_iSampleCopies < 1 then ;or $g_iSampleCopies> 9 then ; Need at least SetCopy\Set1 folder for functionality
		MsgBox($MB_OK,"Sample Copy Number Out of Range","Sample Copy Number must be atleast 1" & chr(13) & "Aborting in 10 seconds!",10)
		Return
	EndIf

	Local $sFolderPath

	for $i=1 to $g_iSampleCopies
		$sFolderPath = $g_sSamplesPath & $sSetCopy & $sSet & $i
		if $g_sCopyMethod = "DELETE" Then DirRemove($sFolderPath, $DIR_REMOVE)
		if not (FileExists($sFolderPath)) Then  DirCreate($sFolderPath)
	next

	;--------------------------------------------------------
	; Delete any SetCopy Folder whose number is greater than SampleCopies

	Local $aDeleteFolder = _FileListToArray($sSetCopyPath,"*",$FLTA_FOLDERS,false)

	if $aDeleteFolder = "" Then
		; Folder is Empty
	Else
		for $i = 1 to ubound($aDeleteFolder)-1
			if number(StringTrimLeft($aDeleteFolder[$i],3), $NUMBER_32BIT) > $g_iSampleCopies then DirRemove($sSetCopyPath & "\" & $aDeleteFolder[$i],$DIR_REMOVE)
		Next
	EndIf

	;--------------------------------------------------------
	; Create any missing subFolders under "SetCopy\Setn"
	; Get ArraySet of all subFolders under "Set" recursively
	; for i = 1 to n (Param2)
		; for each subFolder in ArraySet check if subFolder exists under "Setn"
			; if subFolder doesn't exist then crate SubFolder

	Local $aSetFolders
	Local $sSetPath

	$sSetPath = $g_sSamplesPath & $sSet
	$aSetFolders = _FileListToArrayRec($sSetPath,Default,$FLTAR_FOLDERS,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	for $i = 1 to $g_iSampleCopies
		for $j = 1 to UBound($aSetFolders)-1
			$sFolderPath=$g_sSamplesPath & $sSetCopy & $sSet & $i & "\" & $aSetFolders[$j]
			if not (FileExists($sFolderPath)) then DirCreate($sFolderPath)
		Next
	next

	;--------------------------------------------------------
	; Copy/Rename any missing files under "SetCopy" folder and any subfolders
		; Get ArraySetFiles for all files inside "Set" folder and any files inside subfolders of "Set" folder - recursively
		; for each file in ArraySetFiles
			; if file doesnt exist under "Setn" then
				; copy file from "Set" to "Setn"
				; rename file to (file & "-" & n)

	Local $aSetFiles
	Local $sFileLeft ;File in Set Folder (fullpath)
	Local $sFileRight ;File in SetCopy Folder (fullpath)
	Local $sExt ;Extension of the file
	Local $sLeftPath ;Used by FileCopy, FullPath to the Set File
	Local $sRightPath ;Used by FileCopy, FullPath to the SetCopy File

	$aSetFiles = _FileListToArrayRec($sSetPath,Default,$FLTAR_FILES,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	for $i = 1 to $g_iSampleCopies
		for $j = 1 to ubound($aSetFiles)-1
			$sExt = StringRight($aSetFiles[$j],StringLen($aSetFiles[$j])-StringInStr($aSetFiles[$j],".",0,-1)+1)

			$sFileLeft = StringLeft($aSetFiles[$j],StringInStr($aSetFiles[$j],".",0,-1)-1)
			$sLeftPath = $g_sSamplesPath & $sSet & "\" & $aSetFiles[$j]

			$sFileRight = $sFileLeft & "-" & $i & $sExt
			$sRightPath = $g_sSamplesPath & $sSetCopy & $sSet & $i & "\" & $sFileRight

			FileCopy($sLeftPath, $sRightPath, $iCopyMethod)
		Next
	next

	; Update SampleCopy TreeView
	Local $aSetCopyFolders = _FileListToArray($sSetCopyPath,"*",$FLTA_FOLDERS,false)
	Local $i_MaxSampleCopy

	if $aSetCopyFolders="" then
		$i_MaxSampleCopy = 0
	Else
		$i_MaxSampleCopy = $aSetCopyFolders[ubound($aSetCopyFolders)-1]
		$i_MaxSampleCopy = StringTrimLeft($i_MaxSampleCopy,3)
		;Array_to_TreeView_Simple($aSetCopyFolders,$g_idTreeView_SetCopyFolder)
	EndIf

	Local $aReturn = Array_to_TreeView_Advanced_1D($aSetCopyFolders, $sSetCopyPath)
	Populate_TreeView_Advanced_1D($aReturn, $g_idTreeView_SetCopyFolder, False)

	GUICtrlSetData($g_idLabel_SetCopy,$g_sSamplesPath & $sSetCopy)

	; Update Combo_SampleCopy and Input_SampleCopy
	Local $sCombSampleCopy = "1"
	for $i = 2 to $g_iSampleCopies
		$sCombSampleCopy &= "|" & $i
	next

	_GUICtrlComboBox_ResetContent($g_idComboSampleCopy)
	GUICtrlSetData($g_idComboSampleCopy,$sCombSampleCopy)
	GUICtrlSetData($g_idInput_SampleCopy,$g_iSampleCopies)

EndFunc

func Sample_Copy_Change()

	Local $iComboValue = GUICtrlRead($g_idComboSampleCopy)

	if $iComboValue = "Copy" then Return

	Local $sSetCopyPath = $g_sSamplesPath & $sSetCopy & $sSet & $iComboValue
	Local $aSetCopyFoldersFiles = _FileListToArrayRec($sSetCopyPath,Default,$FLTAR_FILESFOLDERS,$FLTAR_RECUR,$FLTAR_NOSORT,$FLTAR_RELPATH)

	if $aSetCopyFoldersFiles = "" Then
		_GUICtrlTreeView_DeleteAll ($g_idTreeView_SetCopyFolder)
	Else
		Local $aReturn = Array_to_TreeView_Advanced_1D($aSetCopyFoldersFiles, $sSetCopyPath)
		Populate_TreeView_Advanced_1D($aReturn, $g_idTreeView_SetCopyFolder, False)
	EndIf
	GUICtrlSetData($g_idLabel_SetCopy,$g_sSamplesPath & $sSetCopy & $sSet & $iComboValue)

EndFunc

func App_Close()

	GUIDelete(@GUI_WinHandle)
	Exit

EndFunc
