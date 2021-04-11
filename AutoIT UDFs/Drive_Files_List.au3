#include-once

#include <JSON.au3> ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn/
#include <Array.au3>

#comments-start
--------------------------------------------------------------------------------------------------------------------------------------------
Google Specific Parameters (Variables)
--------------------------------------
$sApiKey: (Required) Obtained from Google Developers Console - https://console.developers.google.com
$sSharedFolderID: (Required) Browse to a Publicly Shared Drive Folder and copy the address portion after "https://drive.google.com/drive/folders/"
$sSpaces: (Optional Query Parameter)
$sPageSize: (Optional Query Parameter) Number of items(folders/files) returned by a single GET HTTP request for a single folder
									   Max Allowed by Google: 1000
									   Might be needed to be adjusted depending on Internet connectivity
--------------------------------------------------------------------------------------------------------------------------------------------
Script Specific Parameters (Variables)
--------------------------------------

Column Data for Details Array
$a_Files[$i][0]  = Folder/File Reconstructed Path (as if it was a PC folder that was _FileList_to_ArrayRec'ed with RelativePath option)
$a_Files[$i][1]  = Folder/File ID
$a_Files[$i][2]  = Folder/File Name
$a_Files[$i][3]  = mimeType (for Google specific ones - https://developers.google.com/drive/api/v3/mime-types)
$a_Files[$i][4]  = modifiedTime
$a_Files[$i][5]  = size (Folder sizes are set as "-1" for distinguishing reasons)
$a_Files[$i][6]  = Parent Folder ID
$a_Files[$i][7]  = "Year" part of ModifiedTime
$a_Files[$i][8]  = "Month" part of ModifiedTime
$a_Files[$i][9]  = "Day" part of ModifiedTime
$a_Files[$i][10] = "Hour" part of ModifiedTime
$a_Files[$i][11] = "Minute" part of ModifiedTime
$a_Files[$i][12] = "Seconds" part of ModifiedTime
--------------------------------------------------------------------------------------------------------------------------------------------
#comments-end

AutoItSetOption("MustDeclareVars", 1)

func GetDriveFilesRec($sSharedFolderID, $sApiKey, $sSpaces = "Drive", $sPageSize ="500")

	; Google specific parameters
	$sSpaces = "&spaces=" & $sSpaces
	$sPageSize = "&pageSize=" & $sPageSize

	Local $a_Files [0][6]

	Local $i_FileCount = 0

	; Create the WinHTTP Object
	Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1") ; Requires at least IE 5 to be present

	Local $i_StartIndex = 0

	; Get Root Folders/Files list
	_GetFolderFileList($sSharedFolderID, $sApiKey, $sSpaces, $sPageSize, $a_Files, $i_FileCount, $oHTTP)

	; Recurse Root Folders to get all Folders/Files List
	while $i_StartIndex <= $i_FileCount-1
		if $a_Files[$i_StartIndex][2] = "application/vnd.google-apps.folder" then _GetFolderFileList($a_Files[$i_StartIndex][0], $sApiKey, $sSpaces, $sPageSize, $a_Files, $i_FileCount, $oHTTP)
		$i_StartIndex += 1
	WEnd

	; Sort $a_Files
	_Sort_Arrays($sSharedFolderID, $a_Files)

	_ArrayInsert($a_Files,0,$i_FileCount)

	; Redim $a_Files
	Local $aTemp = $a_Files
	Redim $a_Files[ubound($a_Files)][UBound($a_Files,2)+7]

	$a_Files[0][0] = $i_FileCount
	for $i = 1 to ubound($aTemp)-1
		for $j = 1 to ubound($aTemp,2)
			$a_Files[$i][$j]=$aTemp[$i][$j-1]
		Next
	next

	; Transform $a_Files to _FileListToArrayRec() Format
	Local $sParentFolder
	Local $i_ParentFolderIndex

	$a_Files[0][0] = $i_FileCount
	for $i = 1 to $i_FileCount
		if $a_Files[$i][6]=$sSharedFolderID then ; this is a root folder/file
			$a_Files[$i][0] = $a_Files[$i][2] ; Folder/File name (Full Path)
		Else
			$sParentFolder = $a_Files[$i][6]
			$i_ParentFolderIndex = _ArraySearch($a_Files,$sParentFolder,0,0,0,0,1,1,False)

			$a_Files[$i][0] = $a_Files[$i_ParentFolderIndex][0] & "\" & $a_Files[$i][2] ; Folder/File name (Full Path)
		EndIf
		Local $sModified = $a_Files[$i][4]
		$a_Files[$i][7] = StringMid($sModified,1,4)
		$a_Files[$i][8] = StringMid($sModified,6,2)
		$a_Files[$i][9] = StringMid($sModified,9,2)
		$a_Files[$i][10] = StringMid($sModified,12,2)
		$a_Files[$i][11] = StringMid($sModified,15,2)
		$a_Files[$i][12] = StringMid($sModified,18,2)
	Next

	; Delete WinHTTP Object
	$oHTTP = 0

	return $a_Files

EndFunc

func _Sort_Arrays($sSharedFolderID, byRef $a_Files)

	Local $a_FilesTemp = $a_Files
	Local $sRoot = $sSharedFolderID
	Local $sParent = $sRoot
	Local $iStartIndex, $iEndIndex
	Local $iSortColumn = 1
	Local $iDescending = 0
	Local $bStopSorting = False

	$iStartIndex= 0
	for $i = 0 to ubound($a_FilesTemp)-2
		if $a_FilesTemp[$i+1][5] <> $sParent or $i = ubound($a_FilesTemp)-2 Then
			$iEndIndex = $i
			if $i = ubound($a_FilesTemp)-2 Then
				if $sParent = $a_FilesTemp[$i+1][5] then
					$iEndIndex = $i+1
					$bStopSorting = True
				EndIf
			EndIf
			_ArraySort($a_FilesTemp,$iDescending,$iStartIndex,$iEndIndex,$iSortColumn)
			$sParent = $a_FilesTemp[$i+1][5]
			$iStartIndex = $i+1
			if $bStopSorting = True then ExitLoop
		EndIf
	Next

	$a_Files = $a_FilesTemp

EndFunc

func _GetFolderFileList($sSharedFolderID, $sApiKey, $sSpaces, $sPageSize, byref $a_Files, byref $i_FileCount, $oHTTP)

	Local $bLoopFolders = True
	Local $sURL
	Local $sPageToken = ""
	Local $sNextPageToken = ""
	Local $sResponseText
	Local $iStatus
	Local $o_jsonResponseText

	while $bLoopFolders
		if $sNextPageToken = "" Then
			$sPageToken = ""
		Else
			$sPageToken = "&pageToken=" & $sNextPageToken
		EndIf

		; URL for Directory Listing
		$sURL = "https://www.googleapis.com/drive/v3/files?q='" & $sSharedFolderID & "'%20in%20parents" & $sSpaces & "&fields=nextPageToken%2Cfiles(id%2Cname%2CmimeType%2CmodifiedTime%2Csize)" & $sPageSize & $sPageToken & "&key=" & $sApiKey

		; Open "GET" connection to the URL
		$oHTTP.Open("GET", $sURL, False)

		; Set additional Request Headers
		;$oHTTP.SetRequestHeader("Authorization","Bearer [Api-Key]") ; Doesn't work, need [Access Token] instead
		$oHTTP.SetRequestHeader("Accept","application/json")

		If @error Then
			;SetError(1, 0, 0)
		EndIf

		; Send the Request
		Local $sTest = $oHTTP.Send()

		if $sTest <> "" Then
			for $j = 1 to 3
				sleep(1000)
				;GUICtrlSetData($id_lblInfo, "Ooops! Contacting Google Again: " & $j & "/3")
				$sTest = $oHTTP.Send()
				if $sTest = "" then ExitLoop
			Next
		EndIf

		If @error Then
			;SetError(2, 0, 0)
		EndIf

		$sResponseText = $oHTTP.ResponseText
		$iStatus = $oHTTP.Status

		If $iStatus <> 200 Then
			;GUICtrlSetData($id_lblInfo, "Ooops! Google responded with: " & $iStatus)
			;return 0
			;SetError(3, $iStatus, $sResponseText)
		EndIf

		; Create Scripting.Dictionary object for $sResponseText
		$o_jsonResponseText = Json_Decode($sResponseText)

		; Get nextPageToken
		if $o_jsonResponseText.exists('nextPageToken') then
			$sNextPageToken = Json_Get($o_jsonResponseText,'.nextPageToken')
		Else
			$sNextPageToken = ""
			$bLoopFolders = False
		EndIf

		; Get Files array from ResponseText Array
		Local $i=0
		while $i>=0
			Local $o_FilesTemp = Json_Get($o_jsonResponseText,'.files[' & $i & ']')
			if @error <> 0 then ExitLoop
			; Set Folder sizes to -1, so they don't mix up with files of 0 size
			if not ($o_FilesTemp.exists('size')) then $o_FilesTemp.add ('size', '-1')
			$o_FilesTemp.add ('parent', $sSharedFolderID)

			local $a_FilesTemp = $o_FilesTemp.items
			_ArrayTranspose($a_FilesTemp)
			$i_FileCount = _ArrayConcatenate($a_Files,$a_FilesTemp)

			$i += 1
		WEnd
	WEnd

endfunc