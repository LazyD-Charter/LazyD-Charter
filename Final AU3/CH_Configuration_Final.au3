#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_Configuration.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Description=Script file for configuring LazyD Charter installation options
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

; Default Variable Values
Global $g_sIniFile = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"
Global $g_sInstallPath = IniRead($g_sIniFile,"Install","Install_Path","NotRead")
Global $g_sAppDataChecked = IniRead($g_sIniFile,"Install","AppData_Checked","NotRead") ; Unused ATM
Global $g_sAutoItChecked = IniRead($g_sIniFile,"Install","AutoIt_Checked","NotRead")
Global $g_sRegistryChecked = IniRead($g_sIniFile,"Install","Registry_Checked","NotRead")
Global $g_sExtension = IniRead($g_sIniFile,"Install","Extension","NotRead")
Global $g_sRegHive = IniRead($g_sIniFile,"Install","Registry_Hive","NotRead")
Global $g_sAutoItVer = IniRead($g_sIniFile,"Install","AutoItVer","NotRead")

Global $g_sDEFAULT_EXT = ($g_sExtension = "a3x") ? ($g_sExtension & "s") : ($g_sExtension)

; Quit_App if Install Path can not be read
If $g_sInstallPath = "NotRead" then
	MsgBox($MB_OK,"Warning!","Install Path can not be read. Please check if """ & $g_sIniFile & """ exists.")
	Exit
EndIf

;~ ; Get Script Files Names without Extension
;~ Global $g_aScriptFiles = Get_ScriptFileNames_WithoutExtension()

Global $g_sCurrentInstallPath = $g_sInstallPath
Global $g_sCurrentAppDataChecked = $g_sAppDataChecked
Global $g_sCurrentAutoItChecked = $g_sAutoItChecked
Global $g_sCurrentRegistryChecked = $g_sRegistryChecked
Global $g_sCurrentExtension = $g_sExtension
Global $g_sCurrentRegHive = $g_sRegHive

; Set GUI Control element default values according to ini file values
Global $g_iAppDataChecked = ($g_sAppDataChecked = "True") ? ($GUI_CHECKED) : ($GUI_UNCHECKED)
Global $g_iAutoItChecked = ($g_sAutoItChecked = "True") ? ($GUI_CHECKED) : ($GUI_UNCHECKED)
Global $g_iRegistryChecked = ($g_sRegistryChecked = "True") ? ($GUI_CHECKED) : ($GUI_UNCHECKED)
Global $g_iAppDataState = ($g_sAppDataChecked = "True") ? ($GUI_ENABLE) : ($GUI_DISABLE)
Global $g_iAutoItState = ($g_sAutoItChecked = "True") ? ($GUI_ENABLE) : ($GUI_DISABLE)
Global $g_iRegistryState = ($g_sAutoItChecked = "True") ? ($GUI_ENABLE) : ($GUI_DISABLE)
Global $g_iInputExtensionState = ($g_iRegistryChecked = $GUI_CHECKED) ? ($GUI_ENABLE) : ($GUI_DISABLE)

Global $g_id_inputInstallDirectory
Global $g_id_checkRegistry
Global $g_id_checkAutoIt
Global $g_id_inputExtension
Global $g_id_checkAppData
Global $g_id_lblInputExtension

Create_App_Window()

Func Create_App_Window()

	; Create App Window
	GUICreate("LazyD Charter Configuration", 611, 550, -1, -1)
	GUISetIcon($g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico")
	GUISetBkColor($COL_APP_WINDOW)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Quit_App")

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create QUIT Button
	GUICtrlCreateButton("QUIT", 493, 112, 100, 33)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_BTN_QUIT)
	GUICtrlSetTip(-1, "Click to quit the re-configuration process.")
	GUICtrlSetOnEvent(-1,"Quit_App")

	; Create Install Directory Input Box
	$g_id_inputInstallDirectory = GUICtrlCreateInput($g_sInstallPath, 16, 48, 465, 32)
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

	; Create APPLY Button
	GUICtrlCreateButton("APPLY", 16, 112, 100, 33)
	GUICtrlSetFont(-1, 14, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetTip(-1, "Apply configuration changes.")
	GUICtrlSetOnEvent(-1,"Execute_Changes")

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
	GUICtrlSetState(-1, $g_iAppDataChecked + $g_iAppDataState)
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
	GUICtrlSetState(-1, $g_iAutoItChecked + $g_iAutoItState)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetTip(-1, "Keep it checked to copy """ & $g_sAutoItVer & """ and ""LazyD Charter Scripts"" to install directory.")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetOnEvent(-1, "AutoIT_Check")

	; Create Registry Keys installation option Checkbox (tied to AutoIT option)
	$g_id_checkRegistry = GUICtrlCreateCheckbox("Add Registry Keys (Requires UAC Admin Priviledge)", 72, 384, 489, 41)
	GUICtrlSetState(-1, $g_iRegistryChecked + $g_iRegistryState)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetTip(-1, "Adds Registry Keys to allow double-click running of scripts.")
	GUICtrlSetOnEvent(-1, "Registry_Check")

	; Create Extension option InputBox (tied to Registry Keys install option)
	$g_id_inputExtension = GUICtrlCreateInput($g_sDEFAULT_EXT, 96, 432, 89, 32, BitOR($GUI_SS_DEFAULT_INPUT,$ES_CENTER))
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetState(-1, $g_iInputExtensionState)

	$g_id_lblInputExtension = GUICtrlCreateLabel("Extension for AutoIt scripts", 200, 432, 224, 28)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetTip(-1, "AutoIt scripts will be registered with this extension")
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetState(-1, $g_iInputExtensionState)

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
	; Create Configuration Info Button
	GUICtrlCreateButton("CONFIGURATION INFO", 24, 504, 188, 33)
	GUICtrlSetFont(-1, 12, 800, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetTip(-1, "Open ""LazyD Charter - Configuration Information"" file")
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetOnEvent(-1,"Info_File")

	; Display the App Window
	GUISetState(@SW_SHOW)

	; Message Loop
	While 1
		sleep(100)
	WEnd

EndFunc

Func Get_ScriptFileNames_WithoutExtension()

	Local $aScriptFile = _FileListToArray($g_sInstallPath & "\Apps",Default,$FLTA_FILES,Default)

	; Delete from Array if FileName = $g_sAutoItVer or Extension is not $g_sExtension
	Local $iFileCount = $aScriptFile[0]
	Local $sScriptFileName
	Local $sScriptFileExtension
	Local $sScriptFileName_WithoutExtension

	for $i = 1 to ubound($aScriptFile)-1
		$sScriptFileName = $aScriptFile[$i]
		$sScriptFileExtension = StringTrimLeft($sScriptFileName,StringInStr($sScriptFileName,".",0,-1))

		if ($sScriptFileName = $g_sAutoItVer) Or not ($sScriptFileExtension = $g_sCurrentExtension) Then
			$aScriptFile[$i] = ""
			$iFileCount -= 1
		EndIf
	Next

	; Create Temp Array to hold script file names without extension
	Local $aTemp[1]
	if $iFileCount > 0 Then
		redim $aTemp[$iFileCount]
		Local $iIndex = 0
		for $i = 1 to ubound($aScriptFile)-1
			if not ($aScriptFile[$i] = "") Then
				$sScriptFileName = $aScriptFile[$i]
				$sScriptFileName_WithoutExtension = StringTrimRight($sScriptFileName,1 + StringLen($g_sCurrentExtension)) ; 1 for "."
				$aTemp[$iIndex] = $sScriptFileName_WithoutExtension
				$iIndex += 1
			EndIf
		Next
	EndIf

	; Return Final Array
	return $aTemp

endfunc

Func Execute_Changes()

	; Get New Configuration Options
	$g_sInstallPath = GUICtrlRead($g_id_inputInstallDirectory)
	$g_iAppDataChecked = GUICtrlRead($g_id_checkAppData) ; Disabled ATM
	$g_iAutoItChecked = GUICtrlRead($g_id_checkAutoIt)
	$g_iRegistryChecked = GUICtrlRead($g_id_checkRegistry)
	$g_sExtension = GUICtrlRead($g_id_inputExtension)
	$g_sRegHive = $g_sRegHive ; No option for this ATM

	$g_sAppDataChecked = ($g_iAppDataChecked = $GUI_CHECKED) ? ("True") : ("False")
	$g_sAutoItChecked = ($g_iAutoItChecked = $GUI_CHECKED) ? ("True") : ("False")
	$g_sRegistryChecked = ($g_iRegistryChecked = $GUI_CHECKED) ? ("True") : ("False")

	; Check for New Reg Key exists, if exists and Check Value <> "LazyD Charter" then warn user and return
	If _IsEnabled($g_id_inputExtension) Then
		; Check if key already exists
		RegRead($g_sRegHive & "."  & $g_sExtension,"")
		if @error <= 0 then
			; Key already exists, check if it is a LazyD Charter key
			if RegRead($g_sRegHive & "." & $g_sExtension,"Check") = """LazyD Charter""" Then
				; This key was created by LazyD Charter before, can update
				If $g_sExtension = $g_sCurrentExtension Then
					; No need to create a new key, just change current Installation Paths to the New Installation Path
					RegWrite($g_sRegHive & "."  & $g_sExtension & "\DefaultIcon","","REG_SZ","""" & $g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico""")
					RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell\open\command", "","REG_SZ","""" & $g_sInstallPath & "\Apps\" & $g_sAutoItVer & """ ""%1""")
				EndIf
			Else
				; This key belongs to some other app, warn and return
				MsgBox($MB_OK, "Warning!", "The New Extension """ & $g_sExtension & """ belongs to some other application." & @CRLF & "Please select another extension. Click OK to return back to the Configuration window.")
				Return
			EndIf
		Else
			; Create New Key
			RegWrite($g_sRegHive & "."  & $g_sExtension)
				RegWrite($g_sRegHive & "."  & $g_sExtension, "Check", "REG_SZ", """LazyD Charter""")

			RegWrite($g_sRegHive & "."  & $g_sExtension & "\DefaultIcon")
				RegWrite($g_sRegHive & "."  & $g_sExtension & "\DefaultIcon","","REG_SZ","""" & $g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico""")

			RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell")
				RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell\open")
					RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell\open\command")
						RegWrite($g_sRegHive & "."  & $g_sExtension & "\shell\open\command", "","REG_SZ","""" & $g_sInstallPath & "\Apps\" & $g_sAutoItVer & """ ""%1""")
		EndIf
	Else
		$g_sExtension = "a3x"
	EndIf

	; Create New Installation Folder (if Old <> New)
	If $g_sInstallPath <> $g_sCurrentInstallPath Then
		; Check if Install Dir Exists, create if not
		Local $iCharterInstallDirCreated
		if not(FileExists($g_sInstallPath)) Then
			$iCharterInstallDirCreated = DirCreate($g_sInstallPath)
		EndIf

		; Return to Main App if above steps are unsuccessful
		if $iCharterInstallDirCreated <> 1 and not(FileExists($g_sInstallPath)) then
			MsgBox($MB_OK, "Error", "Couldn't create LazyD Charter install dir: """ & $g_sInstallPath & """")
			Return
		EndIf
	EndIf

	; Copy Install Folder (if Old <> New)
	If $g_sInstallPath <> $g_sCurrentInstallPath Then
		DirCopy($g_sCurrentInstallPath, $g_sInstallPath, $FC_OVERWRITE)
	EndIf

	; Delete AutoIt and scripts if AutoIt is unchecked
	if not (_IsChecked($g_id_checkAutoIt)) Then
		FileDelete($g_sInstallPath & "\Apps\" & $g_sAutoItVer)
		FileDelete($g_sInstallPath & "\Apps\*." & $g_sCurrentExtension)
	EndIf

	; Change Extension Type of scripts if Extension Input Box is Enabled, and Old Extension <> New Extension
	if _IsChecked($g_id_checkAutoIt) Then
		If $g_sExtension <> $g_sCurrentExtension Then
			; Read script filenames from scripts file
;~ 			Local $hScriptFile = FileOpen($g_sScriptFiles, $FO_READ)
;~ 			Local $aScriptFiles = FileReadToArray($hScriptFile)
;~ 			FileClose($hScriptFile)

			Local $aScriptFiles = Get_ScriptFileNames_WithoutExtension()

			for $i = 0 to ubound($aScriptFiles)-1
				FileCopy($g_sCurrentInstallPath & "\Apps\" & $aScriptFiles[$i] & "." & $g_sCurrentExtension, $g_sInstallPath & "\Apps\" & $aScriptFiles[$i] & "." & $g_sExtension)
			Next
		EndIf
	EndIf

	; Change AppData ini
	IniWrite($g_sIniFile,"Install","Install_Path",$g_sInstallPath)
	IniWrite($g_sIniFile,"Install","AppData_Checked",$g_sAppDataChecked) ; Unused ATM
	IniWrite($g_sIniFile,"Install","AutoIt_Checked",$g_sAutoItChecked)
	IniWrite($g_sIniFile,"Install","Registry_Checked",$g_sRegistryChecked)
	IniWrite($g_sIniFile,"Install","Extension",$g_sExtension)
	IniWrite($g_sIniFile,"Install","Registry_Hive",$g_sRegHive)
	IniWrite($g_sIniFile,"Install","AutoItVer",$g_sAutoItVer)

	; Delete Old Reg Key if not same
	if $g_sCurrentRegistryChecked = "True" then
		; Old Key exists, delete if Old <> New
		if $g_sExtension <> $g_sCurrentExtension Then
			RegRead($g_sRegHive & "."  & $g_sCurrentExtension,"")
			if @error <= 0 then
				; Key already exists, check if it is a LazyD Charter key
				if RegRead($g_sRegHive & "." & $g_sCurrentExtension,"Check") = """LazyD Charter""" Then
					RegDelete($g_sRegHive & "." & $g_sCurrentExtension)
				EndIf
			EndIf
		EndIf
	Else
		; Old Key doesn't exist
		; Do Nothing
	EndIf

	; Create Batch file to delete old Installation Folder (if Old <> New)
	Local $sRoot = StringLeft($g_sCurrentInstallPath, 2)
	Local $sParent = StringTrimRight($g_sCurrentInstallPath, StringLen($g_sCurrentInstallPath) - StringInStr($g_sCurrentInstallPath, "\", 0, -1) + 1)
	Local $hFile

	if $g_sInstallPath <> $g_sCurrentInstallPath Then
		FileDelete($sParent & "\DeleteInstallFolder.bat")
		$hFile = FileOpen($sParent & "\DeleteInstallFolder.bat", $FO_APPEND)
		FileWriteLine($hFile, "@PUSHD %~dp0")
		FileWriteLine($hFile, "@ECHO OFF")
		FileWriteLine($hFile, "ECHO LazyD Charter:")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO This is an automatically created batch file")
		FileWriteLine($hFile, "ECHO which will remove the Old Install Folder")
		FileWriteLine($hFile, "ECHO and will delete itself after running.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Old Install Directory: """ & $g_sCurrentInstallPath & """")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Changing Drive to """ & $sRoot & """")
		FileWriteLine($hFile, $sRoot)
		FileWriteLine($hFile, "ECHO Changing Directory to """ & $sParent & """")
		FileWriteLine($hFile, "CD """ & $sParent & """")
		if $sParent = $sRoot then
			FileWriteLine($hFile, "ECHO Batch File: %CD%DeleteInstallFolder.bat ")
		Else
			FileWriteLine($hFile, "ECHO Batch File: %CD%\DeleteInstallFolder.bat ")
		EndIf
		if $g_sCurrentExtension <> $g_sExtension then FileWriteLine($hFile, "DEL /F /Q """ & $g_sInstallPath & "\Apps\*." & $g_sCurrentExtension & """")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Please confirm correct directory and")
		FileWriteLine($hFile, "ECHO Press ""Y"" to delete Old Install Folder")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Waiting for 5 seconds to let script and interpreter")
		FileWriteLine($hFile, "ECHO to shutdown.")
		FileWriteLine($hFile, "TIMEOUT 5 >NUL")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "CHOICE /C YX /N /M ""Continue? (Press ""X"" to QUIT)""")
		FileWriteLine($hFile, "IF ERRORLEVEL 2 GOTO QUIT")
		FileWriteLine($hFile, "IF ERRORLEVEL 1 @ECHO OFF")
		FileWriteLine($hFile, "IF EXIST """ & $g_sCurrentInstallPath & """ RMDIR /Q /S """ & $g_sCurrentInstallPath & """")
		FileWriteLine($hFile, "IF EXIST """ & $sParent & "\DeleteInstallFolder.bat"" DEL /F /Q """ & $sParent & "\DeleteInstallFolder.bat""")
		FileWriteLine($hFile, ":QUIT")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Please re-run this batch script to complete deletion")
		FileWriteLine($hFile, "ECHO """ & $sParent & "\DeleteInstallFolder.bat""")
		FileWriteLine($hFile, "ECHO End of Batch Script")
		FileWriteLine($hFile, "PAUSE")
		FileClose($hFile)

		; Run Batch file and exit Configuration App
		Run("""" & $sParent & "\DeleteInstallFolder.bat""")
		Exit
	EndIf

	; Create Batch file to change extensions when install path stays the same
	if ($g_sInstallPath = $g_sCurrentInstallPath) and ($g_sExtension <> $g_sCurrentExtension) Then
		FileDelete($g_sInstallPath & "\DeleteLeftOverScripts.bat")
		$hFile = FileOpen($g_sInstallPath & "\DeleteLeftOverScripts.bat", $FO_APPEND)
		FileWriteLine($hFile, "@PUSHD %~dp0")
		FileWriteLine($hFile, "@ECHO OFF")
		FileWriteLine($hFile, "ECHO LazyD Charter:")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO This is an automatically created batch file")
		FileWriteLine($hFile, "ECHO which will delete some left over script files")
		FileWriteLine($hFile, "ECHO and will delete itself after running.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Current Extension: """ & $g_sCurrentExtension & """")
		FileWriteLine($hFile, "ECHO New Extension: """ & $g_sExtension & """")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Changing Drive to """ & $sRoot & """")
		FileWriteLine($hFile, $sRoot)
		FileWriteLine($hFile, "ECHO Changing Directory to """ & $g_sInstallPath & """")
		FileWriteLine($hFile, "CD """ & $g_sInstallPath & """")
		if $sParent = $sRoot then
			FileWriteLine($hFile, "ECHO Batch File: %CD%DeleteLeftOverScripts.bat ")
		Else
			FileWriteLine($hFile, "ECHO Batch File: %CD%\DeleteLeftOverScripts.bat ")
		EndIf
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Waiting for 5 seconds to let script and interpreter")
		FileWriteLine($hFile, "ECHO to shutdown.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "TIMEOUT 5 >NUL")
		FileWriteLine($hFile, "DEL /F /Q """ & $g_sInstallPath & "\Apps\*." & $g_sCurrentExtension & """")
		FileWriteLine($hFile, "DEL /F /Q """ & $g_sInstallPath & "\DeleteLeftOverScripts.bat""")
		FileClose($hFile)

		; Run Batch file and exit Configuration App
		Run("""" & $g_sInstallPath & "\DeleteLeftOverScripts.bat""")
		Exit
	EndIf

EndFunc

func Select_Install_Directory()

	; Changes needed to be done on various controls when user changes the install directory
	Local $sDefaultPath = GUICtrlRead($g_id_inputInstallDirectory)
	Local $sDefaultDrive = StringLeft($sDefaultPath,3)
	Local $g_sInstallPath = FileSelectFolder("Select the main folder to install LazyD Charter to...",$sDefaultDrive,Default,"",@GUI_WinHandle)

	if $g_sInstallPath = "" then
		GUICtrlSetData($g_id_inputInstallDirectory,$sDefaultPath)
		Return
	Else
		if StringRight($g_sInstallPath, 13) = "LazyD Charter" Then
			; User selected the Default Folder Name
			; Do Nothing
		Else
			if StringLen($g_sInstallPath) = 3 Then
				; User selected the root of a drive, append Default Folder name
				$g_sInstallPath &= "LazyD Charter"
			Else
				; User selected a different folder
				; Do Nothing
			EndIf
		EndIf
	EndIf

	GUICtrlSetData($g_id_inputInstallDirectory,$g_sInstallPath)

EndFunc

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

func Info_File()

	; Open Configuration Info.rtf in default viewer
	ShellExecute($g_sInstallPath & "\Apps\Text Files\Configuration Info.rtf")

EndFunc

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

func Quit_App()

	; Close App Window, Exit App
	GUIDelete(@GUI_WinHandle)
	Exit

EndFunc