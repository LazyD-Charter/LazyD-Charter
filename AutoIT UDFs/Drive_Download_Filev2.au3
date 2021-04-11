#include-once

#include <FileConstants.au3>

AutoItSetOption("MustDeclareVars", 1)

;Global $__g_oHTTP_ErrorHandler = ObjEvent("AutoIt.Error", __HTTP_OnError) ; Install a custom error handler

Func Drive_Download_File($sFileID, $sDownloadPath, $sFileName, $sApiKey, $sDriveSpace = "Drive")

	$sDriveSpace = "&Spaces=" & $sDriveSpace

	; URL for File Download
	Local $sURL = "https://www.googleapis.com/drive/v3/files/" & $sFileID & "?alt=media" & $sDriveSpace & "&key=" & $sApiKey

	; Create the WinHTTP Object
	Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")

	; Open "GET" connection to the URL
	$oHTTP.Open("GET", $sURL, False)

	Local $sResponseText
	Local $sResponseBody
	Local $iStatus

	; Set additional Request Headers
	;$oHTTP.SetRequestHeader("Authorization","Bearer AIzaSyBO2hW3EW0ahdBPZO12gfspq5h2MkKjnoo") ; Doesn't work, need Access Token
	$oHTTP.SetRequestHeader("Accept","application/json")

	If @error Then
		SetError(1, 0, 0)
	EndIf

	#forceref $sResponseText

	; Send the Request
	$oHTTP.Send() ; Local $sRequest =

	If @error Then
		SetError(2, 0, 0)
	EndIf

	$sResponseText = $oHTTP.ResponseText
	$sResponseBody = $oHTTP.ResponseBody
	$iStatus = $oHTTP.Status

	If $iStatus <> 200 Then
		SetError(3, $iStatus, $sResponseText)
	EndIf

	Local $hFile = FileOpen($sDownloadPath & "\" & $sFileName, $FO_OVERWRITE)
	FileWrite($hFile,$sResponseBody)
	FileClose($hFile)

	; Delete WinHTTP Objects
	$oHTTP = 0

EndFunc
