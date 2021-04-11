#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_Installer.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Description=Script file for installing LazyD Charter
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

#include <LazyD Charter Color Theme.au3>

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)

Global $g_sDEFAULT_EXT = "a3xs"
Global $g_sAutoItVer ="AutoIt3.exe"

Global $g_h_MainApp
Global $g_id_inputInstallDirectory
Global $g_id_checkRegistry
Global $g_id_checkAutoIt
Global $g_id_inputExtension
Global $g_id_checkAppData
Global $g_id_lblInputExtension

Global $g_sGDriveFolder

; Get Script Files Names without the extension
Global $g_aScriptFiles = Get_ScriptFileNames_WithoutExtension()

Create_App_Window()

Func Create_App_Window()

	; Ini File Path
	Local $sIniFilePath = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"

	; Read ini file for InstallDirectory folder path
	Local $sInstallPathforIcon = IniRead($sIniFilePath, "Install", "Install_Path","")

	Local $sIconPath = ($sInstallPathforIcon="") ? (@ScriptDir & "\..\Charter\Apps") : ($sInstallPathforIcon & "\Apps")
	$g_sGDriveFolder = ($sInstallPathforIcon="") ? (@ScriptDir & "\..\Charter\Apps\Text Files\Google Stuff") : ($sInstallPathforIcon & "\Apps\Text Files\Google Stuff")

	; Create App Window
	$g_h_MainApp = GUICreate("LazyD Charter Installer", 611, 549, -1, -1)
	GUISetIcon($sIconPath & "\ChResource\LazyD_Ch.ico")
	GUISetBkColor($COL_APP_WINDOW)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Quit_App")

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Default Variable Values
	Local $sInstallPath ;= "C:\LazyD Charter" ;Default install location
	Local $iAppDataChecked = $GUI_CHECKED
	Local $iAutoItChecked = $GUI_CHECKED
	Local $iRegistryChecked = $GUI_CHECKED
	Local $iInputExtensionState = $GUI_ENABLE

	; Read Ini File in case an installation already exists
	$sInstallPath = IniRead(@AppDataDir & "\LazyD Charter\LazyD Charter.ini","Install","Install_Path","C:\LazyD Charter")
	Local $sAppDataChecked = IniRead(@AppDataDir & "\LazyD Charter\LazyD Charter.ini","Install","AppData_Checked","True") ; Unused ATM
	Local $sAutoItChecked = IniRead(@AppDataDir & "\LazyD Charter\LazyD Charter.ini","Install","AutoIt_Checked","True")
	Local $sRegistryChecked = IniRead(@AppDataDir & "\LazyD Charter\LazyD Charter.ini","Install","Registry_Checked","True")
	$g_sDEFAULT_EXT = IniRead(@AppDataDir & "\LazyD Charter\LazyD Charter.ini","Install","Extension",$g_sDEFAULT_EXT)

	; Change CheckBox Checked State if according to ini file data
	if $sAppDataChecked = "False" then $iAppDataChecked = $GUI_UNCHECKED
	; Registry CheckBox first so AutoIt CheckBox values overwrite
	if $sRegistryChecked = "False" then
		$iRegistryChecked = $GUI_UNCHECKED
		$iInputExtensionState = $GUI_DISABLE
	EndIf
	if $sAutoItChecked = "False" then
		$iAutoItChecked = $GUI_UNCHECKED
		$iRegistryChecked = $GUI_UNCHECKED + $GUI_DISABLE
		$iInputExtensionState = $GUI_DISABLE
	EndIf

	; Create Install Directory Input Box
	$g_id_inputInstallDirectory = GUICtrlCreateInput($sInstallPath, 16, 48, 465, 32)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP)

	; Create Install Directory Label
	GUICtrlCreateLabel("Install Directory", 16, 16, 146, 28)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)

	; Create Install Directory SELECT Button
	GUICtrlCreateButton("SELECT", 496, 48, 100, 33)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetTip(-1, "Click to select another install folder location.")
	GUICtrlSetOnEvent(-1,"Select_Install_Directory")

	; Create QUIT Button
	GUICtrlCreateButton("QUIT", 493, 112, 100, 33)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_BTN_QUIT)
	GUICtrlSetTip(-1, "Click to quit the installation process. All temporary files will be automatically deleted.")
	GUICtrlSetOnEvent(-1,"Quit_App")

	; Create INSTALL Button
	GUICtrlCreateButton("INSTALL", 16, 112, 100, 33)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetTip(-1, "Install ""LazyD Charter"" to the installation folder with the options selected below.")
	GUICtrlSetOnEvent(-1,"Install_App")

	; ----------------------------
	; Create Install Options Group
	GUICtrlCreateGroup("Options", 24, 176, 569, 313)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	; Create Install Options Message Label
	GUICtrlCreateLabel("Optional installation features which will make your life easier, none are essential for using LazyD Charter.", 40, 216, 504, 60)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1, $COL_GROUP)

	; Create AppData Option CheckBox (and Label seperately as text color wouldn't change)
	$g_id_checkAppData = GUICtrlCreateCheckbox("", 42, 288, 41, 41)
	GUICtrlSetState(-1, $iAppDataChecked)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "This option is disabled at the moment.")
	GUICtrlSetBkColor(-1, $COL_GROUP)

	GUICtrlCreateLabel("Create ""AppData\Roaming\LazyD Charter"" folder", 60, 295, 420, 41)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetTip(-1, "This option is disabled at the moment.")
	GUICtrlSetColor(-1, $COL_GROUP_HEADER)
	GUICtrlSetBkColor(-1, $COL_GROUP)

	; Create AutoIt installation option CheckBox
	$g_id_checkAutoIt = GUICtrlCreateCheckbox("Use AutoIt Scripts", 42, 344, 465, 41)
	GUICtrlSetState(-1, $iAutoItChecked)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetTip(-1, "Keep it checked to copy """ & $g_sAutoItVer & """ and ""LazyD Charter Scripts"" to install directory.")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetOnEvent(-1, "AutoIT_Check")

	; Create Registry Keys installation option Checkbox (tied to AutoIT option)
	$g_id_checkRegistry = GUICtrlCreateCheckbox("Add Registry Keys (Requires UAC Admin Priviledge)", 72, 384, 489, 41)
	GUICtrlSetState(-1, $iRegistryChecked)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetTip(-1, "Adds Registry Keys to allow double-click running of scripts.")
	GUICtrlSetOnEvent(-1, "Registry_Check")

	; Create Extension option InputBox (tied to Registry Keys install option)
	$g_id_inputExtension = GUICtrlCreateInput($g_sDEFAULT_EXT, 96, 432, 89, 32, BitOR($GUI_SS_DEFAULT_INPUT,$ES_CENTER))
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetState(-1, $iInputExtensionState)

	$g_id_lblInputExtension = GUICtrlCreateLabel("Extension for AutoIt scripts", 200, 432, 224, 28)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetTip(-1, "AutoIt scripts will be registered with this extension")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetState(-1, $iInputExtensionState)

	; --------------------------------
	; Create Graphics GUIControls (for eye candy) - order is important
	GUICtrlCreateGraphic(24, 176, 569, 25) ;Group Header Color
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(24, 202, 569, 286) ;Group Background Color
	GUICtrlSetBkColor(-1, $COL_GROUP)

	GUICtrlCreateGraphic(32, 280, 553, 2) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(32, 336, 553, 2) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	; ---------------------------------
	; Create Installation Info Button
	GUICtrlCreateButton("INSTALLATION INFO", 24, 504, 188, 33)
	GUICtrlSetFont(-1, 12, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetTip(-1, "Open ""LazyD Charter - Installation Information"" file")
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetOnEvent(-1,"Info_Window")

	; Display the App Window
	GUISetState(@SW_SHOW)

	; Message Loop
	While 1
		sleep(100)
	WEnd

EndFunc

Func Get_ScriptFileNames_WithoutExtension()

	Local $aScriptFile = _FileListToArray(@ScriptDir,Default,$FLTA_FILES,Default)
	Local $aTemp[ubound($aScriptFile)-1]

	for $i = 1 to ubound($aScriptFile)-1
		Local $sScriptFileName = $aScriptFile[$i]
		Local $sScriptFileName_WithoutExtension = StringTrimRight($sScriptFileName,4) ; 4 = 3 for "a3x" + 1 for "."
		$aTemp[$i-1] = $sScriptFileName_WithoutExtension
	Next

	return $aTemp

endfunc

func AutoIT_Check()

	; Check if AutoIt installation option checkbox is checked
	if _IsChecked($g_id_checkAutoIt) Then
		GUICtrlSetState($g_id_checkRegistry, $GUI_UNCHECKED + $GUI_ENABLE)
	Else
		GUICtrlSetState($g_id_checkRegistry, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($g_id_inputExtension, $GUI_DISABLE)
		GUICtrlSetState($g_id_lblInputExtension, $GUI_DISABLE)
	EndIf

EndFunc

func Registry_Check()

	; Check if Registry changes installation option checkbox is checked
	if _IsChecked($g_id_checkRegistry) Then
		GUICtrlSetState($g_id_inputExtension, $GUI_ENABLE)
		GUICtrlSetState($g_id_lblInputExtension, $GUI_ENABLE)
	Else
		GUICtrlSetState($g_id_inputExtension, $GUI_DISABLE)
		GUICtrlSetState($g_id_lblInputExtension, $GUI_DISABLE)
	EndIf

EndFunc

func Info_Window()

	; Set Path according to script dir location
	Local $sInfoPath = (FileExists(@ScriptDir & "\Text Files")) ? (@ScriptDir & "\Text Files") : (@ScriptDir & "\..\Charter\Apps\Text Files")

	; Open Installation Info.rtf in default viewer
	ShellExecute($sInfoPath & "\Installation Info.rtf")

EndFunc

func Quit_App()

	; Close App Window, Exit App
	GUIDelete(@GUI_WinHandle)
	Exit

EndFunc

func Select_Install_Directory()

	; Changes needed to be done on various controls when user changes the install directory
	Local $sDefaultPath = GUICtrlRead($g_id_inputInstallDirectory)
	Local $sDefaultDrive = StringLeft($sDefaultPath,3)
	Local $sInstallPath = FileSelectFolder("Select the main folder to install LazyD Charter to...",$sDefaultDrive,Default,"",@GUI_WinHandle)

	if $sInstallPath = "" then
		GUICtrlSetData($g_id_inputInstallDirectory,$sDefaultPath)
		Return
	Else
		if StringRight($sInstallPath, 13) = "LazyD Charter" Then
			; User selected the Default Folder Name
			; Do Nothing
		Else
			if StringLen($sInstallPath) = 3 Then
				; User selected the root of a drive, append Default Folder name
				$sInstallPath &= "LazyD Charter"
			Else
				; User selected a different folder
				; Do Nothing
			EndIf
		EndIf
	EndIf

	GUICtrlSetData($g_id_inputInstallDirectory,$sInstallPath)

EndFunc

func Install_App()

	Local $sRegHive = "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\"
	Local $sInstallPath = GUICtrlRead($g_id_inputInstallDirectory)
	Local $iOverWriteMethod = $FC_OVERWRITE

	; Install LazyD Charter with the installation options selected

	; Check $sExt related stuff
	Local $sExt
	$sExt = GUICtrlRead($g_id_inputExtension)
	if _isEnabled($g_id_inputExtension) Then
		; Check if $sExt is empty
		if $sExt = "" Then
			msgbox($MB_OK,"Warning","Extension Type is Blank! I will set it to the Default = """ & $g_sDEFAULT_EXT &  """ and Return back to the Options Window" & @CRLF & "Please set it accordingly or keep it as it is.")
			GUICtrlSetData($g_id_inputExtension, $g_sDEFAULT_EXT)
			Return
		Else
			; Check if key already exists
			RegRead($sRegHive & "."  & $sExt,"")
			if @error <= 0 then
				; Key already exists, check if it is a LazyD Charter key
				if RegRead($sRegHive & "." & $sExt,"Check") = """LazyD Charter""" Then
					; This key was created by LazyD Charter before
					; Do Nothing
				Else
					; This key looks like belonging to some other app
					if $sExt = $g_sDEFAULT_EXT then
						; Default Extension is registered to some other app, append "s" to $g_sDEFAULT_EXT and Return to Options Window
						msgbox($MB_OK,"Warning","The Default Extension Type """ & $g_sDEFAULT_EXT & """ is registered with another application!" & @CRLF & "I will set it to """ & $g_sDEFAULT_EXT & "s" & """ and Return back to the Options Window" & @CRLF & "Please click INSTALL button again.")
						$g_sDEFAULT_EXT &= "s"
						GUICtrlSetData($g_id_inputExtension, $g_sDEFAULT_EXT)
					Else
						; User supplied Extension is registered to some other app, change back to Default and Return to Options Window
						msgbox($MB_OK,"Warning","The selected Extension Type is registered with another application!" & @CRLF & "I will set it to the Default = """ & $g_sDEFAULT_EXT & """ and Return back to the Options Window" & @CRLF & "Please change it to something else.")
						GUICtrlSetData($g_id_inputExtension, $g_sDEFAULT_EXT)
					EndIf
					Return
				EndIf
			EndIf
		EndIf
	Else
		; Set a Default Value, Won't be used anyway since Registry option is unchecked
		$sExt = "a3x"
	EndIf

	; Before anything check if previous ini file exists or contains "Install_Path" key
	Local $sPreviousInstallPath = IniRead(@AppDataDir & "\Roaming\LazyD Charter\LazyD Charter.ini","Install","Install_Path","")

	; Check whether current install path is same as previous install path
	if not ($sPreviousInstallPath = "" or $sPreviousInstallPath <> $sInstallPath) Then
		; Check whether Install Folder size is zero
		if not (DirGetSize($sPreviousInstallPath) = 0) Then
			; If it is, ask to user what to do?
			Local $iAnswer = msgbox($MB_YESNOCANCEL,"Previous Installation Found","Found some folders at a previous installation location:" & @CRLF & """" & $sPreviousInstallPath & """" & @CRLF & "Should I delete the old installation folder?" & @CRLF & "Click CANCEL Button to Abort!")
			if $iAnswer = $IDNO Then
				; Set Overwrite method to No-Overwrite and Continue
				$iOverWriteMethod = $FC_NOOVERWRITE
			Elseif $iAnswer =$IDYES Then
				; Delete previous installation folder and continue
				DirRemove($sPreviousInstallPath,$DIR_REMOVE)
			elseif $iAnswer = $IDCANCEL Then
				; User cancelled the install operation
				Return
			EndIf
		EndIf
	EndIf

	; Check if Install Dir Exists, create if not
	Local $iCharterInstallDirCreated
	if not(FileExists($sInstallPath)) Then
		$iCharterInstallDirCreated = DirCreate($sInstallPath)
	EndIf

	; Return to Main App if above steps are unsuccessful
	if $iCharterInstallDirCreated <> 1 and not(FileExists($sInstallPath)) then
		msgbox($MB_OK, "Error", "Couldn't create LazyD Charter install dir: """ & $sInstallPath & """")
		Return
	EndIf

	; Copy Temp Install Folder\Charter Contents to Install Folder
	DirCopy(@ScriptDir & "\..\Charter",$sInstallPath,$iOverWriteMethod)

	; Copy AutoIt3.exe and Script Files to Charter\Apps folders according to Install Options
	if not(_IsChecked($g_id_checkAutoIt)) Then
		; Don't copy AutoIt3.exe or a3x scripts
		; Do Nothing
	elseif (_IsChecked($g_id_checkAutoIt) and not(_IsChecked($g_id_checkRegistry))) Then
		; Copy AutoIt3.exe and Copy Scripts with unchanged extension (a3x)
		FileCopy(@ScriptDir & "\" & $g_sAutoItVer, $sInstallPath & "\Apps",$iOverWriteMethod)
		for $i = 1 to ubound($g_aScriptFiles)
			if not ($g_aScriptFiles[$i-1] = "") then FileCopy(@ScriptDir & "\" & $g_aScriptFiles[$i-1] & ".a3x", $sInstallPath & "\Apps", $iOverWriteMethod)
		next
	elseif (_IsChecked($g_id_checkAutoIt) and _IsChecked($g_id_checkRegistry)) Then
		; Copy AutoIt3.exe and Copy Script Files with new extension (Extension may be set to default "a3x" regardless depending on the input box State ($GUI_DISABLE))
		FileCopy(@ScriptDir & "\" & $g_sAutoItVer, $sInstallPath & "\Apps",$iOverWriteMethod)
		for $i = 1 to ubound($g_aScriptFiles)
			if not ($g_aScriptFiles[$i-1] = "") then FileCopy(@ScriptDir & "\" & $g_aScriptFiles[$i-1] & ".a3x", $sInstallPath & "\Apps\" & $g_aScriptFiles[$i-1] & "." & $sExt, $iOverWriteMethod)
		next
	EndIf

	; Create Registry Entry for Extension (if install option is selected) if it doesn't exist and add shell command to start AutoIt3.exe with the calling a3x script's full path
	if (_IsChecked($g_id_checkRegistry) and _IsChecked($g_id_checkAutoIt)) Then
		RegRead($sRegHive & "."  & $sExt,"")

		If @Error > 0 Then
		   ; Key does not exist create all entries
			RegWrite($sRegHive & "."  & $sExt)
				RegWrite($sRegHive & "."  & $sExt, "Check", "REG_SZ", """LazyD Charter""")

			RegWrite($sRegHive & "."  & $sExt & "\DefaultIcon")
				RegWrite($sRegHive & "."  & $sExt & "\DefaultIcon","","REG_SZ","""" & $sInstallPath & "\Apps\ChResource\LazyD_Ch.ico""")

			RegWrite($sRegHive & "."  & $sExt & "\shell")
				RegWrite($sRegHive & "."  & $sExt & "\shell\open")
					RegWrite($sRegHive & "."  & $sExt & "\shell\open\command")
						RegWrite($sRegHive & "."  & $sExt & "\shell\open\command", "","REG_SZ","""" & $sInstallPath & "\Apps\" & $g_sAutoItVer & """ ""%1""")
		Else
		   ; Key does exist, check for subkeys and stuff and create subkeys if they don't exist, and update/create values
			RegWrite($sRegHive & "."  & $sExt, "Check", "REG_SZ", """LazyD Charter""") ; update/create Value(Check)

			RegRead($sRegHive & "."  & $sExt & "\DefaultIcon","") ; Read Subkey(DefaultIcon) Default Value
			if @error <> 0 then RegWrite($sRegHive & "."  & $sExt & "\DefaultIcon") ; Create Subkey(DefaultIcon)
			RegWrite($sRegHive & "."  & $sExt & "\DefaultIcon","","REG_SZ","""" & $sInstallPath & "\Apps\ChResource\LazyD_Ch.ico""") ; Update/create Value(DefaultIcon Location)

			RegRead($sRegHive & "."  & $sExt & "\shell","") ; Read Subkey(shell) Default Value
			if @error <> 0 then RegWrite($sRegHive & "."  & $sExt & "\shell") ; Create Subkey(shell)
				RegRead($sRegHive & "."  & $sExt & "\shell\open","") ; Read Subkey(shell\open) Default Value
				if @error <> 0 then RegWrite($sRegHive & "."  & $sExt & "\shell\open") ; Create Subkey(shell\open)
					RegRead($sRegHive & "."  & $sExt & "\shell\open\command","") ; Read Subkey(shell\open\command) Default Value
					if @error <> 0 then RegWrite($sRegHive & "."  & $sExt & "\shell\open\command") ; Create Subkey(shell\open\command)
					RegWrite($sRegHive & "."  & $sExt & "\shell\open\command","","REG_SZ","""" & $sInstallPath & "\Apps\" & $g_sAutoItVer & """ ""%1""") ; Update/create Value(AutoIt3.exe Location)
		endif
	EndIf

	; Create Charter AppData/Roaming Folder if it doesnt exist
	if not (FileExists(@AppDataDir & "LazyD Charter")) Then
		DirCreate(@AppDataDir & "\LazyD Charter")
	EndIf

	; Create LazyD Charter.ini and write options
	Local $sAppDataChecked = (_IsChecked($g_id_checkAppData)) ? ("True") : ("False")
	Local $sAutoItChecked = (_IsChecked($g_id_checkAutoIt)) ? ("True") : ("False")
	Local $sRegistryChecked = ((not _IsEnabled($g_id_checkRegistry)) or (not _IsChecked($g_id_checkRegistry))) ? ("False") : ("True")

	Local $hFile = FileOpen($g_sGDriveFolder & "\GDrive API Key.txt")
	Local $sAPIKey = FileReadLine($hFile)
	FileClose($hFile)

	$hFile = FileOpen($g_sGDriveFolder & "\Updates Folder ID.txt")
	Local $sUpdatesFolderID = FileReadLine($hFile)
	FileClose($hFile)

	$hFile = FileOpen($g_sGDriveFolder & "\Extras Folder ID.txt")
	Local $sExtrasFolderID = FileReadLine($hFile)
	FileClose($hFile)

	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Install_Path", $sInstallPath)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "AppData_Checked", $sAppDataChecked)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "AutoIt_Checked", $sAutoItChecked)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Registry_Checked", $sRegistryChecked)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Extension", $sExt)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Registry_Hive", $sRegHive)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "AutoItVer", $g_sAutoItVer)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "API_Key", $sAPIKey)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Updates_Folder_ID", $sUpdatesFolderID)
	IniWrite(@AppDataDir & "\LazyD Charter\LazyD Charter.ini", "Install", "Extras_Folder_ID", $sExtrasFolderID)

	; Copy xlsm to User Desktop
	if FileExists(@DesktopDir & "\LazyD Charter.xlsm") then
		; if previous xlsm found append (New) to filename and copy
		FileCopy($sInstallPath & "\Assets\Excel\LazyD Charter.xlsm",@DesktopDir & "\LazyD Charter (New).xlsm",$FC_NOOVERWRITE)
	Else
		; copy as is
		FileCopy($sInstallPath & "\Assets\Excel\LazyD Charter.xlsm",@DesktopDir,$FC_NOOVERWRITE)
	EndIf

	; Notify User about Successful Installation and Close Installer
	MsgBox($MB_OK,"LazyD Charter Installer","Installation was successful. Click OK to close Installer")

	Quit_App()

endFunc

func _IsChecked($idControlID)

	; Check if CheckBox is checked
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED

EndFunc

func _IsEnabled($idControlID)

	; Check for Control's State (ENABLED/DISABLED)
	if BitAnd(GUICtrlGetState($idControlID), $GUI_ENABLE) = $GUI_ENABLE Then
		Return True
	Else
		Return False
	EndIf

Endfunc