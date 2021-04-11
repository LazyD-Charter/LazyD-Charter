#NoTrayIcon

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Outfile=CH_Install\Scripts\CH_VideoPlayer.a3x
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Description=Video Player for LazyD Charter
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=LazyD Charter
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=LazyD is not a company
#AutoIt3Wrapper_Res_LegalCopyright=None
#AutoIt3Wrapper_Res_LegalTradeMarks=None
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <WinAPI.au3>

#include <LazyD Charter Color Theme.au3>

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)

; Ini File Path
Global $sIniFilePath = @AppDataDir & "\LazyD Charter\LazyD Charter.ini"

; Read ini file for InstallDirectory folder path
Global $sInstallPath = IniRead($sIniFilePath, "Install", "Install_Path","")

; Read ChVideoWindowPosition.ini for window position
Global $g_iTop = IniRead($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Top",0)
Global $g_iLeft = IniRead($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Left",0)

Global $g_hAppWindow
Global $g_idInput

Global $g_iWidth = 320 ; Default AppWindow Width
Global $g_iHeight = 180 ; Default AppWindow Height
Global $g_dblAspect = $g_iWidth / $g_iHeight ; Default Aspect Ratio

Global $g_sAlias = "chvideo" ; Default Alias to be used for the VideoFile (FullPath), only used while Quit_App ()
Global $g_sVideoFile ; VideoFile (FullPath)
Global $g_iVideoLocLeft = 0 ; Default Video pos (Right) inside App_Window
Global $g_iVideoLocTop = 0 ; Default Video pos (Top) inside App_Window

Global $g_iBorderHor ; Needed for WinMove()
Global $g_iBorderVer ; Needed for WinMove()

Global $g_iSleepAmount = 1 ; Sleep amount in milliseconds for GUI while/wend - My app needs to be responsive, therefore I have set it to 1, adjust accordingly

Global $g_bResize = True
Global $g_bVideoInfoReceived = False

Create_App_Window()

func Create_App_Window()

	; Create App Window
	$g_hAppWindow = GUICreate("ChVideo", $g_iWidth, $g_iHeight, $g_iLeft, $g_iTop, $WS_SYSMENU + $WS_POPUP + $WS_CAPTION + $WS_SIZEBOX + $WS_MAXIMIZEBOX + $WS_MINIMIZEBOX, $WS_EX_TOPMOST)
	GUISetIcon($sInstallPath & "\Apps\ChResource\LazyD_Ch.ico")
	GUISetBkColor($COL_APP_WINDOW)
	GUISetOnEvent($GUI_EVENT_CLOSE, "Quit_App")

	; Get Horizontal and Vertical Border Sizes
	Local $aPos = WinGetPos("ChVideo")

	$g_iBorderHor = $aPos[2]-$g_iWidth
	$g_iBorderVer = $aPos[3]-$g_iHeight

	; Create Dummy Button to intercept Return key press
	GUICtrlCreateButton("",0,0,0,0,-1,-1)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetFont(-1, 14, 400, 0, "")

	; Create Input Box to receive messages
	$g_idInput = GUICtrlCreateInput("", 0, 0, 1, 1)
	GUICtrlSetFont(-1, 1, 400, 0, "")
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetBkColor(-1, $COL_APP_WINDOW)
	GUICtrlSetState($GUI_DISABLE, $g_idInput)

	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")
	GUIRegisterMsg($WM_SIZE, "WM_SIZE")

	; Message Loop
	While 1
		sleep($g_iSleepAmount)
	WEnd

EndFunc

Func ProcessString($sInput)

	if StringLeft($sInput, 10) = "VideoSize:" then ; SendMessage as "VideoSize: VideoWidth VideoHeight"
		; Get VideoSize and Set Aspect
		Local $aVideoSize = StringSplit(StringTrimLeft($sInput,11), " ")
		$g_dblAspect = Number($aVideoSize[3]) / Number($aVideoSize[4])
		$g_bVideoInfoReceived = True

	elseif StringLeft($sInput, 10) = "VideoFile:" Then ; SendMessage as "VideoFile: "FullPathVideoFile"" - surrounding FullPathVideoFile with double-quotes are necessary for long names and those with spaces
		; Get VideoFile FullPath
		$g_sVideoFile = StringTrimLeft($sInput, 11)

	elseif StringLeft($sInput,9) = "Location:" Then
		; Move Window to position
		Local $aLocation = StringSplit($sInput, " ")
		$g_iTop = $aLocation[2]
		$g_iLeft = $aLocation[3]
		WinMove($g_hAppWindow, "",$g_iTop,$g_iLeft, $g_iWidth + $g_iBorderHor, $g_iHeight + $g_iBorderVer)

	elseif StringLeft($sInput, 10) = "Terminate:" Then ; SendMessage as "Terminate:"
		; Quit_App
		Quit_App()

	Else
		; Call function to send message to mci Device, everything else not mentioned above will be regarded as a mciSendString() string. In case of faulty commands, mci will return an error at most
		mciSendString($sInput)

	EndIf

EndFunc

Func mciSendString($sSendString)

	if $sSendString = "put " & $g_sAlias & " window at" then ; The initial put window command while opening VideoFile "put chvideo window at"
		WinMove($g_hAppWindow, "", $g_iLeft, $g_iTop, $g_iWidth + $g_iBorderHor, $g_iHeight + $g_iBorderVer)
		$sSendString &= " " & $g_iVideoLocLeft & " " & $g_iVideoLocTop & " " & $g_iWidth & " " & $g_iHeight
	EndIf

	if $g_bVideoInfoReceived then mciSENDCOMMAND($sSendString)

EndFunc

Func mciSENDCOMMAND($sSendString)

	Local $sStrReturn
	DllCall("winmm.dll", "LONG", "mciSendString", "STR", $sSendString, "STR", $sStrReturn, "LONG", 0, "LONG*", 0) ; Local $amciError = (would return error no)
	; Error No: 0 - ok, else check: https://docs.microsoft.com/en-us/previous-versions/visualstudio/visual-basic-6/aa228215(v=vs.60)?redirectedfrom=MSDN

EndFunc

Func ResizeWindow($hWnd)

	$g_bResize = False
	WinMove($hWnd, "", $g_iLeft + $g_iBorderHor, $g_iTop, $g_iWidth + $g_iBorderHor, $g_iHeight + $g_iBorderVer)
	$g_bResize = True

	Local $sSendString = "put " & $g_sAlias & " window at " & $g_iVideoLocLeft  & " " & $g_iVideoLocTop & " " & $g_iWidth & " " & $g_iHeight
	mciSendString($sSendString)

EndFunc

Func WM_SIZE($hWnd, $Msg, $wParam, $lParam) ; App Window Size Change

	#forceref $hWnd, $Msg, $wParam

    Local $iGUIWidth = BitAND($lParam, 0xFFFF)
	$g_iWidth = $iGUIWidth
	$g_iHeight = int($iGUIWidth / $g_dblAspect)

	if $g_bResize = True then ResizeWindow($hWnd)

    Return $GUI_RUNDEFMSG

EndFunc   ;==>_WM_SIZE

Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam) ; InputBox Text Change

	#forceref $hWnd, $Msg, $lParam

	Local $sInput

    Local $intMessageCode
    Local $intControlID_From

    $intControlID_From =  BitAND($wParam, 0xFFFF)
    $intMessageCode = BitShift($wParam, 16)

    Switch $intControlID_From
        Case $g_idInput
            Switch $intMessageCode
                Case $EN_CHANGE
                    $sInput = GUICtrlRead($g_idInput)
					ProcessString($sInput)
            EndSwitch
    EndSwitch

    Return $GUI_RUNDEFMSG

EndFunc

func Quit_App()

	; Write Last Window Position to ini file
	Local $aWindowPosition = wingetpos("ChVideo")
	IniWrite($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Left",$aWindowPosition[0])
	IniWrite($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Top",$aWindowPosition[1])
	IniWrite($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Width",$aWindowPosition[2])
	IniWrite($sInstallPath & "\Apps\Text Files\ChVideoWindowPosition.ini","WindowPosition","Height",$aWindowPosition[3])

	; Close Alias and VideoFile
	mciSendString("close " & $g_sAlias)
	mciSendString("close " & $g_sVideoFile) ; will possibly return an error since alias already closed

	; Give some time for above commands (5-10 milliseconds should be enough) and Exit
	sleep(50)
	GUIDelete($g_hAppWindow)
	Exit

EndFunc