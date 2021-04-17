@cls

@REM Set variables for 7z file to be included in Self Extracting Exe
@set "SevenZipPath=D:\Apps\00-Charter\Portable\7-ZipPortable\App\7-Zip"
@set "InstallerPath=%~dp0."		If batch file is located under Installer Folder
@REM @set "InstallerPath=C:\Users\gkhna\Desktop\CH_Install"		If batch file is located elsewhere, also change ExclusionList file accordingly 
@set "ZipName=CH Install.7z"
@set "ExclusionList=_Exclude List.txt"

@REM Set variables for creating the Self Extracting Exe
@set "SevenZipSDKPath=D:\Apps\00-Charter\7z SDK\lzma1900\bin"
@set "SelfExeName=LazyD Charter Installer.exe"
@set "ConfigurationFile=_Self Extracting Exe Configuration.txt"

@REM Delete old archieve contents (as deleted stuff remain in the archieve w/o this step)
"%SevenZipPath%\7z.exe" d "%InstallerPath%\%ZipName%" *

@REM Add current contents with an Exclusion List
"%SevenZipPath%\7z.exe" a -x@"%InstallerPath%\%ExclusionList%" "%InstallerPath%\%ZipName%" "%InstallerPath%\*"

@REM Create Self Extracting Exe
copy /b "%SevenZipSDKPath%\7zSD.sfx" + "%InstallerPath%\%ConfigurationFile%" + "%InstallerPath%\%ZipName%" "%InstallerPath%\%SelfExeName%"
