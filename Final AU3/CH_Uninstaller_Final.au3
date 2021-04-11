#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_Uninstaller.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Description=Script file for uninstalling LazyD Charter
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=LazyD Charter
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=LazyD is not a company
#AutoIt3Wrapper_Res_LegalCopyright=None
#AutoIt3Wrapper_Res_LegalTradeMarks=None
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>

#include <LazyD Charter Color Theme.au3>

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)

Global $g_sIniFile = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"

Global $g_sInstallPath = IniRead($g_sIniFile,"Install","Install_Path","")
Global $g_sAppData = IniRead($g_sIniFile,"Install","AppData_Checked","")
Global $g_sAutoIt = IniRead($g_sIniFile,"Install","AutoIt_Checked","")
Global $g_sRegistry = IniRead($g_sIniFile,"Install","Registry_Checked","")
Global $g_sExtension = IniRead($g_sIniFile,"Install","Extension","")
Global $g_sRegHive = IniRead($g_sIniFile,"Install","Registry_Hive","")

GLobal $g_idCheckKeepSamples
Global $g_idCheckKeepSongs

Create_App_Window()

func Create_App_Window()

	; Create the App Window
	GUICreate("LazyD Charter Uninstaller", 800, 320, -1, -1)
	GUISetIcon($g_sInstallPath & "\Apps\ChResource\LazyD_Ch.ico")
	GUISetOnEvent($GUI_EVENT_CLOSE, "Quit_App")
	GUISetBkColor($COL_APP_WINDOW)

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create the General Info label
	GUICtrlCreateLabel("The following changes were made to your PC while installing LazyD Charter. I will revert the changes made.", 15, 35, 775, 50)
	GUICtrlSetFont(-1, 14, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	; Create the AppData Info label
	GUICtrlCreateLabel("[AppData]:", 10, 120, 90, 30, $SS_RIGHT)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateLabel("No Changes", 130, 120, 650, 30)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	if $g_sAppData = "True" then GUICtrlSetData(-1, """AppData\Roaming\LazyD Charter"" folder was created")

	; Create the Install Path Info label
	GUICtrlCreateLabel("[Install Path]:", 10, 160, 90, 30, $SS_RIGHT)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateLabel("No Changes", 130, 160, 650, 30)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetData(-1, """" & $g_sInstallPath & """ folder was created")

	; Create the Registry Info label
	GUICtrlCreateLabel("[Registry]:", 10, 200, 90, 30, $SS_RIGHT)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateLabel("No Changes", 130, 200, 650, 30)
	GUICtrlSetFont(-1, 12, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	if $g_sRegistry = "True" then GUICtrlSetData(-1, """" & $g_sRegHive & "." & $g_sExtension & """ key and sub-keys were added")

	; Create the Uninstall Button
	GUICtrlCreateButton("UNINSTALL", 15, 255, 110, 50)
	GUICtrlSetTip(-1, "Uninstall LazyD Charter")
	GUICtrlSetOnEvent(-1, "Uninstall")
	GUICtrlSetBkColor(-1, $COL_BTN_DEFAULT)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create the QUIT Button
	GUICtrlCreateButton("QUIT", 138, 255, 110, 50)
	GUICtrlSetTip(-1, "Exit without uninstalling.")
	GUICtrlSetOnEvent(-1, "Quit_App")
	GUICtrlSetBkColor(-1, $COL_BTN_QUIT)
	GUICtrlSetFont(-1, 16, 400, 0, "")

	; Create Keep Samples Folder CheckBox
	$g_idCheckKeepSamples = GUICtrlCreateCheckbox("Keep Samples Folder", 270, 255, 500, 25)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Keep Songs Folder CheckBox
	$g_idCheckKeepSongs = GUICtrlCreateCheckbox("Keep Songs Folder", 270, 280, 500, 25)
	GUICtrlSetBkColor(-1, $COL_GROUP)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Graphic GUI Controls (for eye candy)
	GUICtrlCreateGraphic(10, 45, 780, 50) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(10, 110, 100, 120) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(120, 110, 670, 120) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP)

	GUICtrlCreateGraphic(10, 250, 780, 60) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP)

	GUICtrlCreateGraphic(10, 240, 780, 3) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	GUICtrlCreateGraphic(10, 100, 780, 3) ; 2 pxs high horizontal line
	GUICtrlSetBkColor(-1, $COL_GROUP_HEADER)

	; Display the App Window
	GUISetState(@SW_SHOW)

	; Message Loop
	While 1
		Sleep(100)
	WEnd

EndFunc

func Uninstall()

	Local $iAppDataDelSuccess
	Local $iInstallDirDelSuccess = 1
	;Local $iDirRemove

	Local $sRegDelString = "Registry: No actions taken"
	Local $g_sAppDataDelString = "AppData Folder: No actions taken"
	Local $sInstallDirString = "Install Directory: No actions taken"

	; Delete Registry
	RegRead($g_sRegHive & "."  & $g_sExtension,"")
	if @error <= 0 then
		; Key already exists, check if it is a LazyD Charter key
		if RegRead($g_sRegHive & "." & $g_sExtension,"Check") = """LazyD Charter""" Then
			; This key was created by LazyD Charter before, delete
			RegDelete($g_sRegHive & "." & $g_sExtension)
			$sRegDelString = (@Error = 0) ? ("Registry: Key was successfully deleted") : ("Registry: WARNING! Unable to delete """ & $g_sRegHive & "." & $g_sExtension & """!")
		EndIf
	EndIf

	; Delete AppData
 	$iAppDataDelSuccess = DirRemove(@AppDataDir & "\LazyD Charter", $DIR_REMOVE)
	$g_sAppDataDelString = ($iAppDataDelSuccess = 1) ? ("AppData Folder: Deleted successfully") : ("AppData Folder: WARNING! Unable to delete """ & @AppDataDir & "\LazyD Charter""!")

	; Delete Folders (keep Samples and/or Songs folders if checked)
	$iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Assets", $DIR_REMOVE) * $iInstallDirDelSuccess
	$iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Project", $DIR_REMOVE) * $iInstallDirDelSuccess
	$iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Temp", $DIR_REMOVE) * $iInstallDirDelSuccess
	if not (_IsChecked($g_idCheckKeepSamples)) Then $iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Samples", $DIR_REMOVE) * $iInstallDirDelSuccess
	if not (_IsChecked($g_idCheckKeepSongs)) then $iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Songs", $DIR_REMOVE) * $iInstallDirDelSuccess
	;$iInstallDirDelSuccess = DirRemove($g_sInstallPath & "\Apps", $DIR_REMOVE)

	; if any of the deletion steps above is unsuccessful, result would be 0
	$sInstallDirString = ($iInstallDirDelSuccess = 1) ? ("Install Folder: All SubFolders deleted successfully") : ("Install Folder: WARNING! Unable to delete some SubFolders!")

	Local $sRoot = StringLeft($g_sInstallPath, 2)
	Local $sParent = StringTrimRight($g_sInstallPath, StringLen($g_sInstallPath) - StringInStr($g_sInstallPath, "\", 0, -1) + 1)
	Local $hFile

	; Run Batch to Delete Apps if either one of the CheckBoxes are checked
	if (_IsChecked($g_idCheckKeepSamples) or _IsChecked($g_idCheckKeepSongs)) Then
		FileDelete($g_sInstallPath & "\DeleteAppsFolder.bat")
		$hFile = FileOpen($g_sInstallPath & "\DeleteAppsFolder.bat", $FO_APPEND)
		FileWriteLine($hFile, "@PUSHD %~dp0")
		FileWriteLine($hFile, "@ECHO OFF")
		FileWriteLine($hFile, "ECHO LazyD Charter:")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO This is an automatically created batch file")
		FileWriteLine($hFile, "ECHO which will remove the remaining APPS folder")
		FileWriteLine($hFile, "ECHO and will delete itself after running.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO " & $sRegDelString)
		FileWriteLine($hFile, "ECHO " & $g_sAppDataDelString)
		FileWriteLine($hFile, "ECHO " & $sInstallDirString)
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		if _IsChecked($g_idCheckKeepSamples) then FileWriteLine($hFile, "ECHO SAMPLES SubDirectory was skipped per user choice")
		if _IsChecked($g_idCheckKeepSongs) then FileWriteLine($hFile, "ECHO SONGS SubDirectory was skipped per user choice")
		if _IsChecked($g_idCheckKeepSamples) or _IsChecked($g_idCheckKeepSongs) then FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Changing Drive to """ & $sRoot & """")
		FileWriteLine($hFile, $sRoot)
		FileWriteLine($hFile, "ECHO Changing Directory to """ & $g_sInstallPath & """")
		FileWriteLine($hFile, "CD """ & $g_sInstallPath & """")
		FileWriteLine($hFile, "ECHO Batch File: %CD%\DeleteAppsFolder.bat ")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Please confirm correct directory and")
		FileWriteLine($hFile, "ECHO Press ""Y"" to delete APPS folder")
		FileWriteLine($hFile, "TIMEOUT 5 >NUL")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Waiting for 5 seconds to let script and interpreter")
		FileWriteLine($hFile, "ECHO to shutdown.")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "CHOICE /C YX /N /M ""Continue? (Press ""X"" to QUIT)""")
		FileWriteLine($hFile, "IF ERRORLEVEL 2 GOTO QUIT")
		FileWriteLine($hFile, "IF ERRORLEVEL 1 @ECHO OFF")
		FileWriteLine($hFile, "IF EXIST """ & $g_sInstallPath & "\Apps"" RMDIR /Q /S """ & $g_sInstallPath & "\Apps""")
		FileWriteLine($hFile, "IF EXIST """ & $g_sInstallPath & "\DeleteAppsFolder.bat"" DEL /F /Q """ & $g_sInstallPath & "\DeleteAppsFolder.bat""")
		FileWriteLine($hFile, ":QUIT")
		FileWriteLine($hFile, "ECHO ------------------------------------------------")
		FileWriteLine($hFile, "ECHO Please re-run this batch script to complete deletion")
		FileWriteLine($hFile, "ECHO """ & $sParent & "\DeleteAppsFolder.bat""")
		FileWriteLine($hFile, "ECHO End of Batch Script")
		FileWriteLine($hFile, "PAUSE")
		FileClose($hFile)

		Run("""" & $g_sInstallPath & "\DeleteAppsFolder.bat""") ; ,@SW_HIDE add after file name

		Exit
	EndIf

 	; Run Batch to Delete $g_sInstallPath if none of the CheckBoxes are checked
	FileDelete($sParent & "\DeleteInstallFolder.bat")
	$hFile = FileOpen($sParent & "\DeleteInstallFolder.bat", $FO_APPEND)
	FileWriteLine($hFile, "@PUSHD %~dp0")
	FileWriteLine($hFile, "@ECHO OFF")
	FileWriteLine($hFile, "ECHO LazyD Charter:")
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "ECHO This is an automatically created batch file")
	FileWriteLine($hFile, "ECHO which will remove the remaining Install Folder")
	FileWriteLine($hFile, "ECHO and will delete itself after running.")
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "ECHO " & $sRegDelString)
	FileWriteLine($hFile, "ECHO " & $g_sAppDataDelString)
	FileWriteLine($hFile, "ECHO " & $sInstallDirString)
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
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "ECHO Please confirm correct directory and")
	FileWriteLine($hFile, "ECHO Press ""Y"" to delete Install Folder")
	FileWriteLine($hFile, "TIMEOUT 5 >NUL")
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "ECHO Waiting for 5 seconds to let script and interpreter")
	FileWriteLine($hFile, "ECHO to shutdown.")
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "CHOICE /C YX /N /M ""Continue? (Press ""X"" to QUIT)""")
	FileWriteLine($hFile, "IF ERRORLEVEL 2 GOTO QUIT")
	FileWriteLine($hFile, "IF ERRORLEVEL 1 @ECHO OFF")
	FileWriteLine($hFile, "IF EXIST """ & $g_sInstallPath & """ RMDIR /Q /S """ & $g_sInstallPath & """")
	FileWriteLine($hFile, "IF EXIST """ & $sParent & "\DeleteInstallFolder.bat"" DEL /F /Q """ & $sParent & "\DeleteInstallFolder.bat""")
	FileWriteLine($hFile, ":QUIT")
	FileWriteLine($hFile, "ECHO ------------------------------------------------")
	FileWriteLine($hFile, "ECHO Please re-run this batch script to complete deletion")
	FileWriteLine($hFile, "ECHO """ & $sParent & "\DeleteInstallFolder.bat""")
	FileWriteLine($hFile, "ECHO End of Batch Script")
	FileWriteLine($hFile, "PAUSE")
	FileClose($hFile)

	Run("""" & $sParent & "\DeleteInstallFolder.bat""")

	Exit

EndFunc

func _IsChecked($idControlID)

	; Check if CheckBox is checked
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED

EndFunc

func Quit_App()

	; Close App Window, Exit App
	GUIDelete(@GUI_WinHandle)
	Exit

EndFunc