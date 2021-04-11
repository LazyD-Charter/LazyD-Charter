#cs
	Date: 2018-02-10, 12:31
	Description: UDF for using Google oAuth 2.0 API
	Author: Ascer
	Functions: oAuth2GetAuthorizationCode, oAuth2GetAccessToken, oAuth2RefreshAccessToken
#ce


#Region 1.0, Google oAuth 2.0.

Local $AUTHORIZATION_CODE = ""

;==============================================================================================================================================================
; Function:         oAuth2GetAuthorizationCode($sClientId [, $sRedirectUri = "http://localhost"])
;
; Description:      Send request via your default browser to account.google.com to create Authorization Code.
;					After calling this function you need to choose your google account and allow your app to read an emails.
;					When button was pressed look on your url adress in browser. Will look somthing like that:
;					http://localhost/?code=4/bAfCtJxXdnepvdhufpdsdfsddfgddfgombFQB8Ve2d_8KyVfvbGf8b_GwOMsdfB8uDfZkwsdD-s-vN5Sip7bdfsB1jcGqqU#
;					Your Authorization Code is: 4/bAfCtJxXdnepvdhufpdsdfsddfgddfgombFQB8Ve2d_8KyVfvbGf8b_GwOMsdfB8uDfZkwsdD-s-vN5Sip7bdfsB1jcGqqU#
;					This will required parameter to send request to get access_token.
;
; Parameter(s):     $sClientId - string | Your "client_id" from *json file.
;					$sRedirectUri - string | (Default = "http://localhost") This you can find in your *json file in param called: "redirect_uris"
;
; Return Value(s):  Nothing.
;
; Author (s):		Ascer
;==============================================================================================================================================================
Func oAuth2GetAuthorizationCode($sClientId, $sRedirectUri = "http://localhost")

	Local $sRequest = "https://accounts.google.com/o/oauth2/auth?"
	$sRequest &= "redirect_uri=" & _URIEncode($sRedirectUri)
	$sRequest &= "&response_type=code"
	$sRequest &= "&client_id=" & $sClientId
	$sRequest &= "&scope=https%3A%2F%2Fmail.google.com%2F"
	$sRequest &= "&approval_prompt=force"

	ShellExecute($sRequest)

EndFunc

;==============================================================================================================================================================
; Function:         oAuth2GetAccessToken($sClientId, $sClientSecret [, $sAuthorizationCode = $AUTHORIZATION_CODE [, $sRedirectUri = "http://localhost"]])
;
; Description:      Send request to Google API using previous received $sAuthorizationCode to get access_token and refresh_token.
;
; Parameter(s):     $sClientId - string | Your "client_id" from *json file.
;					$sClientSecret - string | Your "client_secret" from *json file.
;					$sAuthorizationCode - string | (Default = $AUTHORIZATION_CODE). Code received from google calling oAuth2GetAuthorizationCode function.
;					$sRedirectUri - string | (Default = "http://localhost") This you can find in your *json file in param called: "redirect_uris"
;
; Return Value(s):  On Success Set Error to 0 and Returns 1D array containing:
;									[0] - "access_token"
;									[1] - "expires_in"
;									[2] - "refresh_token"
;									[3] - "token_type"
;					On Failure Set Error to:
;									1 - Failed to create object in $oHttp ("winhttp.winhttprequest.5.1")
;									2 - Invalid parameter in calling HttpRequest. Received status <> 200. @error = $iStatus
;									3 - Failed to get values from Google respond.
; Author (s):		Ascer
;==============================================================================================================================================================
Func oAuth2GetAccessToken($sClientId, $sClientSecret, $sAuthorizationCode = $AUTHORIZATION_CODE, $sRedirectUri = "http://localhost")

	Local $oHttp = ObjCreate("winhttp.winhttprequest.5.1")

	If Not IsObj($oHttp) Then Return except("oAuth2GetAccessToken()", 'Error durning create object "winhttp.winhttprequest.5.1". Something wrong with your Microsoft lib.', 1, 1)

	$oHttp.Open("POST", "https://accounts.google.com/o/oauth2/token", False)

	$oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")

	Local $sRequest = "grant_type=authorization_code"
	$sRequest &= "&code=" & $sAuthorizationCode
	$sRequest &= "&redirect_uri=" & _URIEncode($sRedirectUri)
	$sRequest &= "&client_id=" & $sClientId
	$sRequest &= "&client_secret=" & $sClientSecret

	$oHttp.Send($sRequest)

	Local $iStatus = $oHttp.Status
	Local $sOutput = $oHttp.ResponseText

	If $iStatus <> 200 Then Return except("aAuthGetAccessToken()", "Error durning send request to Google. $oHttp.Status = " & $iStatus & @CRLF & "$oHttp.ResponseText = " & $sOutput, 2, $iStatus)

	Local $aAccessToken = _JsonValue($sOutput, '"access_token" : "', '",')
	Local $aExpiresIn = _JsonValue($sOutput, '"expires_in" : ', ",")
	Local $aRefreshToken = _JsonValue($sOutput, '"refresh_token" : "', '",')
	Local $aTokenType = _JsonValue($sOutput, '"token_type" : "', '"')

	If Not IsArray($aAccessToken) Or Not IsArray($aExpiresIn) Or Not IsArray($aRefreshToken) Or Not IsArray($aTokenType) Then
		Return except("aAuthGetAccessToken()", "Error durning reading $oHttp.ResponseText. Google must changed *json respond for this request." & @CRLF & "$oHttp.ResponseText = " & $sOutput, 3, 3)
	EndIf

	Local $aTable = [$aAccessToken[0], $aExpiresIn[0], $aRefreshToken[0], $aTokenType[0]]

	Return SetError(0, 0, $aTable)

EndFunc

;==============================================================================================================================================================
; Function:         oAuth2RefreshAccessToken($sRefreshToken, $sClientId, $sClientSecret)
;
; Description:      Send request to Google API using refresh_token to get a new access_token.
;
; Parameter(s):     $sRefreshToken - string | Your refresh_token received calling function oAuth2GetAccessToken()[2]
;					$sClientId - string | Your "client_id" from *json file.
;					$sClientSecret - string | Your "client_secret" from *json file.
;
; Return Value(s):  On Success Set Error to 0 and Returns 1D array containing:
;									[0] - "access_token"
;									[1] - "expires_in"
;									[2] - "token_type"
;					On Failure Set Error to:
;									1 - Failed to create object in $oHttp ("winhttp.winhttprequest.5.1")
;									2 - Invalid parameter in calling HttpRequest. Received status <> 200. @error = $iStatus
;									3 - Failed to get values from Google respond.
; Author (s):		Ascer
;==============================================================================================================================================================
Func oAuth2RefreshAccessToken($sRefreshToken, $sClientId, $sClientSecret)

	Local $oHttp = ObjCreate("winhttp.winhttprequest.5.1")

	If Not IsObj($oHttp) Then Return except("oAuth2RefreshAccessToken()", 'Error durning create object "winhttp.winhttprequest.5.1". Something wrong with your Microsoft lib.', 1, 1)

	$oHttp.Open("POST", "https://accounts.google.com/o/oauth2/token", False)

	$oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")

	Local $sRequest = "refresh_token=" & $sRefreshToken
	$sRequest &= "&client_id=" & $sClientId
	$sRequest &= "&client_secret=" & $sClientSecret
	$sRequest &= "&grant_type=refresh_token"

	$oHttp.Send($sRequest)

	Local $iStatus = $oHttp.Status
	Local $sOutput = $oHttp.ResponseText

	If $iStatus <> 200 Then Return except("oAuth2RefreshAccessToken()", "Error durning send request to Google. $oHttp.Status = " & $iStatus & @CRLF & "$oHttp.ResponseText = " & $sOutput, 2, $iStatus)

	Local $aAccessToken = _JsonValue($sOutput, '"access_token" : "', '",')
	Local $aExpiresIn = _JsonValue($sOutput, '"expires_in" : ', ",")
	Local $aTokenType = _JsonValue($sOutput, '"token_type" : "', '"')

	If Not IsArray($aExpiresIn) Or Not IsArray($aAccessToken) Or Not IsArray($aTokenType) Then
		Return except("oAuth2RefreshAccessToken()", "Error durning reading $oHttp.ResponseText. Google must changed *json respond for this request." & @CRLF & "$oHttp.ResponseText = " & $sOutput, 3, 3)
	EndIf

	Local $aTable = [$aAccessToken[0], $aExpiresIn[0], $aTokenType[0]]

	Return SetError(0, 0, $aTable)

EndFunc

#EndRegion

#Region 1.1, Internal Functions.

Func _URIEncode($sData)
    Local $aData = StringSplit(BinaryToString(StringToBinary($sData,4),1),"")
    Local $nChar
    $sData=""
    For $i = 1 To $aData[0]
        $nChar = Asc($aData[$i])
        Switch $nChar
            Case 45, 46, 48 To 57, 65 To 90, 95, 97 To 122, 126
                $sData &= $aData[$i]
            Case 32
                $sData &= "+"
            Case Else
                $sData &= "%" & Hex($nChar,2)
        EndSwitch
    Next
    Return $sData
EndFunc ;==> _URIEncode by Prog@ndy

Func _JsonValue($sString, $sStart, $sEnd, $iMode = 0, $bCase = False)
	; If starting from beginning of string
	$sStart = $sStart ? "\Q" & $sStart & "\E" : "\A"

	; Set mode
	If $iMode <> 1 Then $iMode = 0

	; If ending at end of string
	If $iMode = 0 Then
		; Use lookahead
		$sEnd = $sEnd ? "(?=\Q" & $sEnd & "\E)" : "\z"
	Else
		; Capture end string
		$sEnd = $sEnd ? "\Q" & $sEnd & "\E" : "\z"
	EndIf

	; Set correct case sensitivity
	If $bCase = Default Then
		$bCase = False
	EndIf

	Local $aReturn = StringRegExp($sString, "(?s" & (Not $bCase ? "i" : "") & ")" & $sStart & "(.*?)" & $sEnd, 3)
	If @error Then Return SetError(1, 0, 0)
	Return $aReturn
EndFunc   ;==>_JsonValue = _StringBetween by SmOke_N

Func except($sFuncName, $sData, $vReturnValue, $iError = @error, $iScriptLineNumber = @ScriptLineNumber)
	ConsoleWrite("+++ Line: " & $iScriptLineNumber & ", Func: " & $sFuncName & " -> " & $sData & @CRLF)
	Return SetError($iError, 0, $vReturnValue)
EndFunc

#EndRegion
