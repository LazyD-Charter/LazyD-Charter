#include-once

#include <Array.au3>
#include <GuiTreeView.au3>
#include <TreeViewConstants.au3>
#include <File.au3>
#include <FileConstants.au3>

AutoItSetOption("MustDeclareVars",1)

Global $g_sIconFolder = @ScriptDir & "\Icons\"
Global $g_sIconFile = "IconTypes.txt"

Global $g_bIconFileRead = False
Global $g_aIcons

func Array_to_TreeView_Advanced($aArray, $sPathRelative = "", $iStartIndex = 1, $iFolderColumn = 0, $sFolderString = "")

	#forceref $sFolderString, $sPathRelative

	if $iStartIndex = Default then $iStartIndex = 1
	if $sPathRelative = Default then $sPathRelative = ""

	if $aArray = "" then Return
	if UBound($aArray, 2) = 1 then return
	if $iFolderColumn = 0 and $sPathRelative = "" then Return

	; Passing an extended array (more than 1 columns) with FileListtoArray (RelativePath) format is enough
	; $sPathRelative = Path of the folder that was searched with FileListtoArray (RelativePath), or Empty String for FullPath
	; $iStartIndex = 1 if FileListtoArray Array (Index 0 is number of files/folders
	; $iFolderColumn = Which column to check for isFolder condition
	; $sFolderString = Which string value to search in $iFolderColumn to determine if isFolder

	Local $bRelativePath

	if $iFolderColumn = 0 Then
		$bRelativePath = (StringInStr($aArray[$iStartIndex][0],$sPathRelative)>0) ? (False) : (True)
	Else
		$bRelativePath = True
	EndIf

	if StringRight($sPathRelative,1) = "\" then StringTrimRight($sPathRelative,1)

	Local $iAddRowforFullPath = 1
	Local $iFullPathOccurrence = 0

	if $bRelativePath = False Then
		$iAddRowforFullPath = 1
		$aArray[$iStartIndex][0] = StringReplace($aArray[$iStartIndex][0], "\", "\")
		if @extended > $iFullPathOccurrence then $iFullPathOccurrence= @extended
	EndIf

	; Find max nested folders
	Local $iOccurrence = 0
	for $i = 1 to ubound($aArray)-1
		$aArray[$i][0] = StringReplace($aArray[$i][0], "\", "\")
		if @extended > $iOccurrence then $iOccurrence= @extended
	Next

	$iOccurrence += 1 ; to account for any files inside max nested folder
	$iOccurrence = ($bRelativePath = False) ? ($iOccurrence + 1 - $iFullPathOccurrence) : ($iOccurrence)

	Local $aRearrangedArray[ubound($aArray)-$iStartIndex+$iAddRowforFullPath][6 + $iOccurrence + ubound($aArray,2)]
	; $aRearrangedArray[$i][0] = 1 (Folder)/ 0 (File)
	; $aRearrangedArray[$i][1] = # of nested folders in $sPathRelative = $iFullPathOccurrence
	; $aRearrangedArray[$i][2] = Folder Level (1:Root), from Count of "\" + 1
	; $aRearrangedArray[$i][3] = $idTreeView
	; $aRearrangedArray[$i][4] = $hParent
	; $aRearrangedArray[$i][5] = $hSelf
	; $aRearrangedArray[$i][6] = RelativePath (from $aArray[$i][0])
	; $aRearrangedArray[$i][7] to [7 + $iOccurrence] = Root Folder - SubFolder1 - SubFolderN - FileName
	; $aRearrangedArray[$i][7+$iOccurrence] to [7+$iOccurrence+ubound($aArray)-1] = $aArray[$i][1+] rest of the $aArray

	;Local $aTemp
	if $iAddRowforFullPath = 1 Then
		$aRearrangedArray[0][1] = $iOccurrence
		$aRearrangedArray[0][2] = ($bRelativePath = True) ? (0) : (1)
		$aRearrangedArray[0][3] = "" ;$idTreeView
		$aRearrangedArray[0][6] = ($iFolderColumn = 0) ? ($sPathRelative) : ("Not a PC Folder List")
		$aRearrangedArray[0][7] = ($iFolderColumn = 0) ? ($sPathRelative) : ("Not a PC Folder List")
	EndIf

	for $i = 0 to UBound($aRearrangedArray)-1-$iAddRowforFullPath
		$aRearrangedArray[$i+$iAddRowforFullPath][1] = $iFullPathOccurrence
		$aRearrangedArray[$i+$iAddRowforFullPath][3] = "" ;$idTreeView

		Local $aTemp = StringSplit($aArray[$i + $iStartIndex][0],"\")
		$aRearrangedArray[$i+$iAddRowforFullPath][2] = ($bRelativePath = True) ? ($aTemp[0]-$iFullPathOccurrence) : ($aTemp[0]+1-$iFullPathOccurrence)

		if $iAddRowforFullPath = 1 Then
			if $iFolderColumn = 0 then
				$aRearrangedArray[$i+$iAddRowforFullPath][6] = ($bRelativePath = True) ? ($sPathRelative & "\" & $aArray[$i + $iStartIndex][0]) : ($aArray[$i + $iStartIndex][0])
				for $j = 1+$iFullPathOccurrence to $aTemp[0]
					$aRearrangedArray[$i+$iAddRowforFullPath][6+$j-$iFullPathOccurrence] = $aTemp[$j]
				Next
			Else
				$aRearrangedArray[$i+$iAddRowforFullPath][6] = $aArray[$i+$iStartIndex][0]
				for $j = 1+$iFullPathOccurrence to $aTemp[0]
					$aRearrangedArray[$i+$iAddRowforFullPath][6+$j-$iFullPathOccurrence] = $aTemp[$j]
				Next
			EndIf
		Else

		EndIf

		;Fill in the rest of $aRearranged from $aArray
		for $j = 1 to UBound($aArray,2) - 1
			$aRearrangedArray[$i+$iAddRowforFullPath][6 + $iAddRowforFullPath + $iOccurrence + $j - 1] = $aArray[$i + $iStartIndex][$j]
		Next
	Next

	;Sort Files Last within $aRearrangedArray
	;First: Copy Folders to $aTemp

	Local $iNextRow = 0
	ReDim $aTemp[1][ubound($aRearrangedArray)]
	for $i = 0 to ubound($aRearrangedArray)-1
		if $iFolderColumn = 0 Then
			Local $sFileFullPath = $aRearrangedArray[$i][6] ;($sPathRelative = "") ? ($aRearrangedArray[$i][6]) :($sPathRelative & "\" & $aRearrangedArray[$i][6])
			if StringInStr(FileGetAttrib($sFileFullPath),"D")>0 then ; This is a folder, copy to next empty solt in $aTemp2
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 1
					$aRearrangedArray[$i][0] = 1
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 1
					$aRearrangedArray[$i][0] = 1
				EndIf

				$iNextRow += 1
			EndIf
		Else
			if $aRearrangedArray[$i][$iFolderColumn+6+$iOccurrence] = $sFolderString or ($i = 0 and $iStartIndex = 1) Then
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 1
					$aRearrangedArray[$i][0] = 1
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 1
					$aRearrangedArray[$i][0] = 1
				EndIf

				$iNextRow += 1
			EndIf
		EndIf
	Next

	;Second: Copy Files to $aTemp
	for $i = 0 to ubound($aRearrangedArray)-1
		if $iFolderColumn = 0 Then
			if $aRearrangedArray[$i][0] <> 1 then ; This is not a folder
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 0
					$aRearrangedArray[$i][0] = 0
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 0
					$aRearrangedArray[$i][0] = 0
				EndIf

				$iNextRow += 1
			EndIf
		Else
			if $aRearrangedArray[$i][0] <> 1 Then ; This is not a folder
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 0
					$aRearrangedArray[$i][0] = 0
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 0
					$aRearrangedArray[$i][0] = 0
				EndIf

				$iNextRow += 1
			EndIf
		EndIf
	Next

	Local $aReturn[2]

	$aReturn[0]= $iOccurrence
	$aReturn[1] = $aTemp

	Return $aReturn

EndFunc

func Populate_TreeView_Advanced($aTVArray2, $idTV, $bAutoExpand = True, $bAddAll = False)

	Local $aTVArray = $aTVArray2[1]
	Local $iOccurrence = $aTVArray2[0]

	Local $hParent
	Local $hSelf
	Local $sRelativePath

	_GUICtrlTreeView_DeleteAll ($idTV)

	_GUICtrlTreeView_BeginUpdate($idTV)

	Local $bRelativePath = ($aTVArray[0][2] = 0) ? (True) : (False)
	Local $iStartIndex = ($bRelativePath = True) ? (1) : (0)

	$aTVArray[0][3] = $idTV

	for $iFolderLevel = 1 to $iOccurrence
		for $i = 0 to ubound($aTVArray)-1
			Local $iNewIndex = ubound($aTVArray,2)-4
			Local $sNewUpdatedInfo = ""
			$sNewUpdatedInfo = ($aTVArray[$i][$iNewIndex] = "(New Item)") ? ($sNewUpdatedInfo & " (New Item)") : ($sNewUpdatedInfo)
			$sNewUpdatedInfo = ($aTVArray[$i][$iNewIndex+1] = "(Updated Item)") ? ($sNewUpdatedInfo & " (Updated Item)") : ($sNewUpdatedInfo)
			$sNewUpdatedInfo = ($aTVArray[$i][$iNewIndex+2] = "(New)") ? ($sNewUpdatedInfo & " (New)") : ($sNewUpdatedInfo)
			$sNewUpdatedInfo = ($aTVArray[$i][$iNewIndex+3] = "(Updated)") ? ($sNewUpdatedInfo & " (Updated)") : ($sNewUpdatedInfo)

			if $sNewUpdatedInfo <> "" or $bAddAll = True then
				if $aTVArray[$i][2] = $iFolderLevel then
					if $bRelativePath = True Then
						$sRelativePath = ($aTVArray[0][6] = "Not a PC Folder List") ? ("") : ($aTVArray[0][6])
						for $j = 7 to 5 + $aTVArray[$i][2] step 1
							$sRelativePath &= "\" & $aTVArray[$i][$j]
						Next
						if $aTVArray[0][6] = "Not a PC Folder List" then $sRelativePath = StringTrimLeft($sRelativePath,1)
					Else
						$sRelativePath = $aTVArray[0][6]
						for $j = 7 to 5 + $aTVArray[$i][2] step 1
							$sRelativePath &= "\" & $aTVArray[$i][$j]
						Next
					EndIf

					Local $iParentIndex = _ArraySearch($aTVArray,$sRelativePath,$iStartIndex,Default,Default,Default,Default,6,False)
					$hParent = (@error = 6) ? ("") : ($aTVArray[$iParentIndex][5])

					if $hParent = "" then ; Root level folder/file
						$hSelf = _GUICtrlTreeView_Add($idTV, 0, $aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]]) ; & $sNewUpdatedInfo)
						$aTVArray[$i][3] = $idTV
						$aTVArray[$i][4] = $hParent
						$aTVArray[$i][5] = $hSelf

						;Format Style of Added Item 1: Folder, 0: File
						_TreeViewItemFormat($aTVArray, $i) ;, $iParentIndex)
					Else ; Sub-Folder/File
						$hSelf = _GUICtrlTreeView_AddChild($idTV,$hParent,$aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]]) ; & $sNewUpdatedInfo)
						$aTVArray[$i][3] = $idTV
						$aTVArray[$i][4] = $hParent
						$aTVArray[$i][5] = $hSelf

						;Format Style of Added Item 1: Folder, 0: File
						_TreeViewItemFormat($aTVArray, $i) ;, $iParentIndex)
					EndIf
				EndIf
			EndIf
		next
	Next

	_GUICtrlTreeView_EndUpdate($idTV)

	; Expand TreeView (default: True)
	if $bAutoExpand then _GUICtrlTreeView_Expand($idTV)

	Return $aTVArray

endfunc

func Array_to_TreeView_Advanced_1D($aArray, $sPathRelative, $iStartIndex = 1)

	if $iStartIndex = Default then $iStartIndex = 1

	if $aArray = "" then Return
	if UBound($aArray, 2) > 1 then return
	if $sPathRelative = "" then Return

	; Passing a 1D array from FileListtoArray (RelativePath) format is enough
	; $sPathRelative: Path of the FileList_to_Array function was called
	; $iStartIndex = 1 if FileListtoArray has file count at 1st row (row index = 0)

	Local $bRelativePath = True
	Local $iFolderColumn = 0

	if StringInStr($aArray[$iStartIndex], $sPathRelative) > 0 then $bRelativePath = False

	if StringRight($sPathRelative,1) = "\" then StringTrimRight($sPathRelative,1)

	Local $iAddRowforFullPath = 1

	Local $iFullPathOccurrence = 0
	if $bRelativePath = False Then
		$iAddRowforFullPath = 1
		$aArray[$iStartIndex] = StringReplace($aArray[$iStartIndex], "\", "\")
		if @extended > $iFullPathOccurrence then $iFullPathOccurrence= @extended
	EndIf

	; Find max nested folders
	Local $iOccurrence = 0
	for $i = 1 to ubound($aArray)-1
		$aArray[$i] = StringReplace($aArray[$i], "\", "\")
		if @extended > $iOccurrence then $iOccurrence= @extended
	Next

	$iOccurrence += 1 ; to account for any files inside max nested folder
	$iOccurrence = ($bRelativePath = False) ? ($iOccurrence + 1 - $iFullPathOccurrence) : ($iOccurrence)

	Local $aRearrangedArray[ubound($aArray)-$iStartIndex+$iAddRowforFullPath][6 + $iOccurrence + ubound($aArray,2)+1]
	; $aRearrangedArray[$i][0] = 1 (Folder)/ 0 (File)
	; $aRearrangedArray[$i][1] = # of nested folders in $sPathRelative = $iFullPathOccurrence
	; $aRearrangedArray[$i][2] = Folder Level (1:Root), from Count of "\" + 1
	; $aRearrangedArray[$i][3] = $idTreeView
	; $aRearrangedArray[$i][4] = $hParent
	; $aRearrangedArray[$i][5] = $hSelf
	; $aRearrangedArray[$i][6] = RelativePath (from $aArray[$i])
	; $aRearrangedArray[$i][7] to [7 + $iOccurrence] = Root Folder - SubFolder1 - SubFolderN - FileName

	;Local $aTemp
	if $iAddRowforFullPath = 1 Then
		$aRearrangedArray[0][1] = $iOccurrence
		$aRearrangedArray[0][2] = ($bRelativePath = True) ? (0) : (1)
		$aRearrangedArray[0][3] = "" ;$idTreeView
		$aRearrangedArray[0][6] = ($iFolderColumn = 0) ? ($sPathRelative) : ("Not a PC Folder List")
		$aRearrangedArray[0][7] = ($iFolderColumn = 0) ? ($sPathRelative) : ("Not a PC Folder List")
	EndIf

	for $i = 0 to UBound($aRearrangedArray)-1-$iAddRowforFullPath
		$aRearrangedArray[$i+$iAddRowforFullPath][1] = $iFullPathOccurrence
		$aRearrangedArray[$i+$iAddRowforFullPath][3] = "" ;$idTreeView

		Local $aTemp = StringSplit($aArray[$i + $iStartIndex],"\")
		$aRearrangedArray[$i+$iAddRowforFullPath][2] = ($bRelativePath = True) ? ($aTemp[0]-$iFullPathOccurrence) : ($aTemp[0]+1-$iFullPathOccurrence)

		if $iAddRowforFullPath = 1 Then
			if $iFolderColumn = 0 then
				$aRearrangedArray[$i+$iAddRowforFullPath][6] = ($bRelativePath = True) ? ($sPathRelative & "\" & $aArray[$i + $iStartIndex]) : ($aArray[$i + $iStartIndex])
				for $j = 1+$iFullPathOccurrence to $aTemp[0]
					$aRearrangedArray[$i+$iAddRowforFullPath][6+$j-$iFullPathOccurrence] = $aTemp[$j]
				Next
			Else

			EndIf
		Else

		EndIf
	Next

	;Sort Files Last within $aRearrangedArray
	;First: Copy Folders to $aTemp

	Local $iNextRow = 0
	ReDim $aTemp[1][ubound($aRearrangedArray)]
	for $i = 0 to ubound($aRearrangedArray)-1
		if $iFolderColumn = 0 Then
			Local $sFileFullPath = $aRearrangedArray[$i][6] ;($sPathRelative = "") ? ($aRearrangedArray[$i][6]) :($sPathRelative & "\" & $aRearrangedArray[$i][6])
			if StringInStr(FileGetAttrib($sFileFullPath),"D")>0 then ; This is a folder, copy to next empty slot in $aTemp2
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 1
					$aRearrangedArray[$i][0] = 1
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 1
					$aRearrangedArray[$i][0] = 1
				EndIf

				$iNextRow += 1
			EndIf
		Else

		EndIf
	Next

	;Second: Copy Files to $aTemp
	for $i = 0 to ubound($aRearrangedArray)-1
		if $iFolderColumn = 0 Then
			if $aRearrangedArray[$i][0] <> 1 then ; This is not a folder
				if $iNextRow = 0 then
					$aTemp = _ArrayExtract($aRearrangedArray,$i,$i)
					$aTemp[0][0] = 0
					$aRearrangedArray[$i][0] = 0
				Else
					_ArrayConcatenate($aTemp, _ArrayExtract($aRearrangedArray,$i,$i))
					$aTemp[$iNextRow][0] = 0
					$aRearrangedArray[$i][0] = 0
				EndIf

				$iNextRow += 1
			EndIf
		Else

		EndIf
	Next

	Local $aReturn[2]

	$aReturn[0]= $iOccurrence
	$aReturn[1] = $aTemp

	Return $aReturn

EndFunc

func Populate_TreeView_Advanced_1D($aTVArray2, $idTV, $bAutoExpand = True)

	Local $aTVArray = $aTVArray2[1]
	Local $iOccurrence = $aTVArray2[0]

	Local $hParent
	Local $hSelf
	Local $sRelativePath

	_GUICtrlTreeView_DeleteAll ($idTV)

	_GUICtrlTreeView_BeginUpdate($idTV)

	Local $bRelativePath = ($aTVArray[0][2] = 0) ? (True) : (False)
	Local $iStartIndex = ($bRelativePath = True) ? (1) : (0)

	$aTVArray[0][3] = $idTV

	for $iFolderLevel = 1 to $iOccurrence
		for $i = 0 to ubound($aTVArray)-1
			ConsoleWrite($i & " of " & ubound($aTVArray)-1 & @crlf)
			if $aTVArray[$i][2] = $iFolderLevel then
				if $bRelativePath = True Then
					$sRelativePath = ($aTVArray[0][6] = "Not a PC Folder List") ? ("") : ($aTVArray[0][6])
					for $j = 7 to 5 + $aTVArray[$i][2] step 1
						$sRelativePath &= "\" & $aTVArray[$i][$j]
					Next
					if $aTVArray[0][6] = "Not a PC Folder List" then $sRelativePath = StringTrimLeft($sRelativePath,1)
				Else
					$sRelativePath = $aTVArray[0][6]
					for $j = 7 to 5 + $aTVArray[$i][2] step 1
						$sRelativePath &= "\" & $aTVArray[$i][$j]
					Next
				EndIf

				Local $iParentIndex = _ArraySearch($aTVArray,$sRelativePath,$iStartIndex,Default,Default,Default,Default,6,False)
				$hParent = (@error = 6) ? ("") : ($aTVArray[$iParentIndex][5])

				if $hParent = "" then ; Root level folder/file
					$hSelf = _GUICtrlTreeView_Add($idTV, 0, $aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]])
					$aTVArray[$i][3] = $idTV
					$aTVArray[$i][4] = $hParent
					$aTVArray[$i][5] = $hSelf

					;Format Style of Added Item 1: Folder, 0: File
					_TreeViewItemFormat($aTVArray, $i) ;, $iParentIndex)
				Else ; Sub-Folder/File
					$hSelf = _GUICtrlTreeView_AddChild($idTV,$hParent,$aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]])
					$aTVArray[$i][3] = $idTV
					$aTVArray[$i][4] = $hParent
					$aTVArray[$i][5] = $hSelf

					;Format Style of Added Item 1: Folder, 0: File
					_TreeViewItemFormat($aTVArray, $i) ;, $iParentIndex)
				EndIf
			EndIf
		next
	Next

	_GUICtrlTreeView_EndUpdate($idTV)

	; Expand TreeView (default: True)
	if $bAutoExpand then _GUICtrlTreeView_Expand($idTV)

	Return $aTVArray

endfunc

func IniFile_to_TreeView($idTV, $sIniFilePath, $sDelimiter, $iStringSplitFlag = 0)

	; Strip NoCount Flag if present
	if $iStringSplitFlag >= 2 then $iStringSplitFlag -= 2

	Local $aArrayForTV[1]

	Local $aIniSections = IniReadSectionNames($sIniFilePath)

	for $i = 1 to $aIniSections[0]
		_ArrayAdd($aArrayForTV,$aIniSections[$i])

		Local $aSectionKeys = IniReadSection($sIniFilePath, $aIniSections[$i])

		for $j = 1 to $aSectionKeys[0][0]
			Local $sKey = $aSectionKeys[$j][0]
			_ArrayAdd($aArrayForTV,$aIniSections[$i] & "\" & $sKey)

			Local $sKeyValues = $aSectionKeys[$j][1]
			Local $aIndividualValue = StringSplit($sKeyValues,$sDelimiter,$iStringSplitFlag)
			for $k = 1 to $aIndividualValue[0]
				_ArrayAdd($aArrayForTV,$aIniSections[$i] & "\" & $sKey & "\" & $aIndividualValue[$k])
			next
		next
	Next

	$aArrayForTV[0]=ubound($aArrayForTV)-1

	Local $aTest = Array_to_TreeView_Advanced_1D($aArrayForTV, "C:\folderthatdoesntexist")
	Populate_TreeView_Advanced_IniFile($aTest, $idTV, False)

	return $aArrayForTV

EndFunc

func Populate_TreeView_Advanced_IniFile($aTVArray2, $idTV, $bAutoExpand = True)

	Local $aTVArray = $aTVArray2[1]
	Local $iOccurrence = $aTVArray2[0]

	Local $hParent
	Local $hSelf
	Local $sRelativePath

	_GUICtrlTreeView_DeleteAll ($idTV)

	_GUICtrlTreeView_BeginUpdate($idTV)

	Local $bRelativePath = ($aTVArray[0][2] = 0) ? (True) : (False)
	Local $iStartIndex = ($bRelativePath = True) ? (1) : (0)

	$aTVArray[0][3] = $idTV

	for $iFolderLevel = 1 to $iOccurrence
		for $i = 0 to ubound($aTVArray)-1
			if $aTVArray[$i][2] = $iFolderLevel then
				if $bRelativePath = True Then
					$sRelativePath = ($aTVArray[0][6] = "Not a PC Folder List") ? ("") : ($aTVArray[0][6])
					for $j = 7 to 5 + $aTVArray[$i][2] step 1
						$sRelativePath &= "\" & $aTVArray[$i][$j]
					Next
					if $aTVArray[0][6] = "Not a PC Folder List" then $sRelativePath = StringTrimLeft($sRelativePath,1)
				Else
					$sRelativePath = $aTVArray[0][6]
					for $j = 7 to 5 + $aTVArray[$i][2] step 1
						$sRelativePath &= "\" & $aTVArray[$i][$j]
					Next
				EndIf

				Local $iParentIndex = _ArraySearch($aTVArray,$sRelativePath,$iStartIndex,Default,Default,Default,Default,6,False)
				$hParent = (@error = 6) ? ("") : ($aTVArray[$iParentIndex][5])

				if $hParent = "" then ; Root level folder/file
					$hSelf = _GUICtrlTreeView_Add($idTV, 0, $aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]])
					$aTVArray[$i][3] = $idTV
					$aTVArray[$i][4] = $hParent
					$aTVArray[$i][5] = $hSelf

					;Format Style of Added Item 1: Folder, 0: File
					_TreeViewItemFormat_NoCustomIcons($aTVArray, $i)
				Else ; Sub-Folder/File
					$hSelf = _GUICtrlTreeView_AddChild($idTV,$hParent,$aTVArray[$i][6+$aTVArray[$i][2]-$aTVArray[$i][1]])
					$aTVArray[$i][3] = $idTV
					$aTVArray[$i][4] = $hParent
					$aTVArray[$i][5] = $hSelf

					;Format Style of Added Item 1: Folder, 0: File
					_TreeViewItemFormat_NoCustomIcons($aTVArray, $i)
				EndIf
			EndIf
		next
	Next

	_GUICtrlTreeView_EndUpdate($idTV)

	; Expand TreeView (default: True)
	if $bAutoExpand then _GUICtrlTreeView_Expand($idTV)

	Return $aTVArray

endfunc

func _TreeViewItemFormat($aTVArray, $i)

	#forcedef $g_sExtension

	Local $sFileExtension
	Local $sFileName
	Local $bFoundIcon = False
	Local $k
	Local $hTV = $aTVArray[$i][3]
	Local $hParent = $aTVArray[$i][4]
	Local $hSelf = $aTVArray[$i][5]
	Local $iIsFolder = $aTVArray[$i][0]

#Region Icons Array
	; Create $g_aIcons array
	local $sPath = $g_sIconFolder & $g_sIconFile

	if $g_bIconFileRead = False Then

		_FileReadToArray($sPath,$g_aIcons,$FRTA_NOCOUNT,"|")

		Local $iTotalIcons = ubound($g_aIcons)
		for $i = $iTotalIcons-1 to 0 step -1 ; start checking from EOF
			if $g_aIcons[$i][0] = "Comment" then
				$iTotalIcons -= 1
				ExitLoop
			EndIf
		next

		if $iTotalIcons <> ubound($g_aIcons) Then
			_ArrayDelete($g_aIcons,$iTotalIcons & "-" & ubound($g_aIcons)-1)
		EndIf

;~ 		; Special case if a3x extension is changed
;~ 		$g_aIcons[3][0] = $g_sExtension & $g_aIcons[3][0]

		$g_bIconFileRead = True
	EndIf
#EndRegion

	Local $aCheckIconType

	if $hParent = "" then ; Root level Folder/File
		if $iIsFolder = 1 Then ; Root level Folder
			; This is a root level folder (empty by default)
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[0][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[0][1],0,2) ; if Folder, Empty Folder icon by default
		Else
			; This is a root level file
			$sFileName = $aTVArray[$i][$aTVArray[$i][2]+6]
			$sFileExtension = StringTrimLeft($sFileName,StringInStr($sFileName,".",0,-1))
			$k = 3
			While $g_aIcons[$k][0] <> ""
				if StringInStr($g_aIcons[$k][0],$sFileExtension)>0 Then
					$aCheckIconType = StringSplit($g_aIcons[$k][0]," ")
					for $m = 1 to $aCheckIconType[0]
						if $aCheckIconType[$m]= $sFileExtension Then
							_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[$k][2])
							_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[$k][1]) ; Suitable File icon
							$bFoundIcon = True
							ExitLoop
						EndIf
					Next
					if $bFoundIcon = True then ExitLoop
				EndIf
				$k += 1
				if $k = ubound($g_aIcons) then ExitLoop
			WEnd
			if $bFoundIcon = False Then
				; Unknown file type
				_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[2][2])
				_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[2][1]) ; Unknown File icon
			EndIf
		EndIf
	Else
		if $iIsFolder = 1 Then ; SubFolder
			; This is a subfolder (empty by default)
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[0][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[0][1],0,2) ; if Folder, Empty Folder icon by default
			_GUICtrlTreeView_SetIcon($hTV,$hParent,$g_sIconFolder & $g_aIcons[1][1]) ; if a Child is added, change the Parent Folder icon to a non-empty one
		Else
			; This is a root level file
			$sFileName = $aTVArray[$i][$aTVArray[$i][2]+6]
			$sFileExtension = StringTrimLeft($sFileName,StringInStr($sFileName,".",0,-1))
			$k = 3
			While $g_aIcons[$k][0] <> ""
				if StringInStr($g_aIcons[$k][0],$sFileExtension)>0 Then
					$aCheckIconType = StringSplit($g_aIcons[$k][0]," ")
					for $m = 1 to $aCheckIconType[0]
						if $aCheckIconType[$m]= $sFileExtension Then
							_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[$k][2])
							_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[$k][1]) ; Suitable File icon
							_GUICtrlTreeView_SetIcon($hTV,$hParent,$g_sIconFolder & $g_aIcons[1][1]) ; if a Child is added, change the Parent Folder icon to a non-empty one
							$bFoundIcon = True
							ExitLoop
						EndIf
					Next
					if $bFoundIcon = True then ExitLoop
				EndIf
				$k += 1
				if $k = ubound($g_aIcons) then ExitLoop
			WEnd
			if $bFoundIcon = False Then
				; Unknown file type
				_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[2][2])
				_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_sIconFolder & $g_aIcons[2][1]) ; Unknown File icon
				_GUICtrlTreeView_SetIcon($hTV,$hParent,$g_sIconFolder & $g_aIcons[1][1]) ; if a Child is added, change the Parent Folder icon to a non-empty one
			EndIf
		EndIf
	EndIf

EndFunc

func _TreeViewItemFormat_NoCustomIcons($aTVArray, $i)

	; populate the treeview control
	;shell32.dll icons: 3: Empty Folder, 126: Folder with File, 168: (Audio) File, 1: File, 2: App"

	Local $g_aIcons[3][4]
	Local $hTV = $aTVArray[$i][3]
	Local $hParent = $aTVArray[$i][4]
	Local $hSelf = $aTVArray[$i][5]
	Local $iIsFolder = $aTVArray[$i][0]

#Region IconTypes
	; Empty Folder
	$g_aIcons[0][0] = "Empty Folder"
	$g_aIcons[0][1] = "shell32.dll"
	$g_aIcons[0][2] = True
	$g_aIcons[0][3] = 3
	; Full Folder
	$g_aIcons[1][0] = "Full Folder"
	$g_aIcons[1][1] = "shell32.dll"
	$g_aIcons[1][2] = True
	$g_aIcons[1][3] = 126
	; Unknown File
	$g_aIcons[2][0] = "Unknown File"
	$g_aIcons[2][1] = "shell32.dll"
	$g_aIcons[2][2] = False
	$g_aIcons[2][3] = 1
#EndRegion

	if $hParent = "" then ; Root level Folder/File
		if $iIsFolder = 1 Then ; Root level Folder
			; This is a root level folder (empty by default)
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[0][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_aIcons[0][1],$g_aIcons[0][3]) ; if Folder, Empty Folder icon by default
		Else
			; This is a root level file
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[2][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_aIcons[2][1],$g_aIcons[2][3]) ; Unknown File icon
		EndIf
	Else
		if $iIsFolder = 1 Then ; SubFolder
			; This is a subfolder (empty by default)
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[0][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_aIcons[0][1],$g_aIcons[0][3]) ; if Folder, Empty Folder icon by default
			_GUICtrlTreeView_SetIcon($hTV,$hParent,$g_aIcons[1][1],$g_aIcons[1][3]) ; if a Child is added, change the Parent Folder icon to a non-empty one
		Else
			_GUICtrlTreeView_SetBold($hTV,$hSelf,$g_aIcons[2][2])
			_GUICtrlTreeView_SetIcon($hTV,$hSelf,$g_aIcons[2][1],$g_aIcons[2][3]) ; Unknown File icon
			_GUICtrlTreeView_SetIcon($hTV,$hParent,$g_aIcons[1][1],$g_aIcons[1][3]) ; if a Child is added, change the Parent Folder icon to a non-empty one
		EndIf
	EndIf

EndFunc


; Some older versions. The following may not provide accurate results in certain conditions eventhough they seem to work

func Array_to_TreeView_Simple($aFoldersFiles,$idTreeView)

	Local $iOccurrence

	;Find max nested folders
	$iOccurrence=0
	for $i = 1 to ubound($aFoldersFiles)-1
		$aFoldersFiles[$i] = StringReplace($aFoldersFiles[$i], "\", "\")
		if @extended > $iOccurrence then $iOccurrence= @extended
	Next

	$iOccurrence += 1

	if ($aFoldersFiles = "") then Return

	Local $aSplitSet[ubound($aFoldersFiles)][$iOccurrence+1]
	Local $aTemp

	for $i = 1 to ubound($aFoldersFiles)-1
		$aTemp = StringSplit($aFoldersFiles[$i],"\")
		for $j = 0 to $aTemp[0]
			$aSplitSet[$i-1][$j] = $aTemp[$j]
		Next
	next

	;Sort Files Last within $aSplitSet
	Local $aTemp2[ubound($aSplitSet)-1][$iOccurrence+2]

	;First: Copy Folders to $aTemp2
	Local $iNextRow = 0
	for $i = 1 to ubound($aSplitSet)-1
		if StringInStr($aSplitSet[$i-1][($aSplitSet[$i-1][0])],".")=0 and $aSplitSet[$i-1][0] <> 0 Then ;this is a folder, copy to next empty slot in $aTemp2
			for $j = 0 to $aSplitSet[$i-1][0]
				$aTemp2[$iNextRow][$j+1]=$aSplitSet[$i-1][$j]
				$aTemp2[$iNextRow][0] = 1 ;text in bold bit
			Next
			$aSplitSet[$i-1][0]=0
			$iNextRow += 1
		endif
	next

	;Second: Copy Files to $aTemp2
	for $i = 1 to ubound($aSplitSet)-1
		if $aSplitSet[$i-1][0] <> 0 Then ;this is a folder, copy to next empty slot in $aTemp2
			for $j = 0 to $aSplitSet[$i-1][0]
				$aTemp2[$iNextRow][$j+1]=$aSplitSet[$i-1][$j]
				$aTemp2[$iNextRow][0] = 0 ;text in normal bit
			Next
			$iNextRow += 1
		endif
	Next
	redim $aSplitSet[ubound($aTemp2)-1][$iOccurrence+2]
	$aSplitSet=$aTemp2

	_pop_treeview_simple($idTreeView,$aSplitSet,$iOccurrence)

EndFunc

func _pop_treeview_simple($hTV,$array,$iOccurrence)

    ; populate the treeview control
	;shell32.dll icons: 3: Empty Folder, 126: Folder with File, 168: (Audio) File, 1: File, 2: App"

	Local $hitem
	Local $hLast

	_GUICtrlTreeView_BeginUpdate($hTV)

	for $j = 2 to $iOccurrence+1
		For $1 = 0 To UBound($array) - 1
			if $array[$1][1] = '' then exitloop
			If $j=2 and $array[$1][1] = 1 Then
				$hLast = _GUICtrlTreeView_Add($hTV, 0, $array[$1][$j])
				;Format Style of Added Item 1: Folder, 0: File
				if $array[$1][0] = 1 then
					_GUICtrlTreeView_SetBold($hTV,$hLast,True)
					_GUICtrlTreeView_SetIcon($hTV,$hLast,"shell32.dll",3) ; if Folder, Empty Folder icon by default
				Else
					_GUICtrlTreeView_SetBold($hTV,$hLast,False)
					_GUICtrlTreeView_SetIcon($hTV,$hLast,"shell32.dll",168) ; Suitable File icon
				endIf
			Elseif $array[$1][1] = $j-1 Then
				$hitem = _GUICtrlTreeView_FindItem($hTV, $array[$1][$j-1],False,0)
				If $hitem <> 0 Then
					$hLast = _GUICtrlTreeView_AddChild($hTV, $hitem, $array[$1][$j])
					;Format Style of Added Item 1: Folder, 0: File
					if $array[$1][0] = 1 then
						_GUICtrlTreeView_SetBold($hTV,$hLast,True)
						_GUICtrlTreeView_SetIcon($hTV,$hLast,"shell32.dll",3) ; if Folder, Empty Folder icon by default
						_GUICtrlTreeView_SetIcon($hTV,$hitem,"shell32.dll",126) ; if a Child is added, change the Parent Folder icon to a non-empty one
					Else
						_GUICtrlTreeView_SetBold($hTV,$hLast,False)
						_GUICtrlTreeView_SetIcon($hTV,$hLast,"shell32.dll",168) ; Suitable File icon
						_GUICtrlTreeView_SetIcon($hTV,$hitem,"shell32.dll",126) ; if a Child is added, change the Parent Folder icon to a non-empty one
					endIf
				EndIf
			EndIf
		Next
	Next

    _GUICtrlTreeView_EndUpdate($hTV)

endfunc
