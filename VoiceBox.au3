#AutoIt3Wrapper_Icon=res\VoiceBox.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=VoiceBox
#AutoIt3Wrapper_Res_Fileversion=2.0.2.0
#AutoIt3Wrapper_Res_Language=1036

#cs ----------------------------------------------------------------------------

	VoiceBox 2.02
	par mGeek (http://mgeek.fr)
	avec les améliorations de PHP-Voxygen ainsi que PHP-TwinMee de TiBounise (http://tibounise.com)

	changelog:
	- 2.02
	Corrigé: Ajout d'un timeout lors de la connexion aux serveurs
	Corrigé: Ajout d'un timeout lors du téléchargement des fichiers mp3
	Corrigé: Supression du player mp3 et remplacement par le lecteur associé avec Windows

	- 2.01
	Ajout: Vérification de l'existance des librairies CURL / Téléchargement si elles ne sont pas présentes
	Corrigé: Disparition de la ProgressBar en cas d'erreur de conversion (pour les deux services)
	Nettoyage de code

#ce ----------------------------------------------------------------------------

#include <Array.au3>
#include <String.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include "Include.au3"

$version = "2.02"
$displayVersion = " " & $version

OnAutoItExitRegister("_Exit")
DirCreate(@ScriptDir & "\temp")
DirCreate(@ScriptDir & "\files")

If Not FileExists(@ScriptDir & "\curl\curl.exe") _
		Or Not FileExists(@ScriptDir & "\curl\libcurl.dll") _
		Or Not FileExists(@ScriptDir & "\curl\libeay32.dll") _
		Or Not FileExists(@ScriptDir & "\curl\libssl32.dll") Then
	DirCreate(@ScriptDir & "\curl")
	ProgressOn("VoiceBox", "Chargement des librairies manquantes", 'Téléchargement de "curl.exe"')
	InetGet("https://raw.github.com/mGeek/VoiceBox/master/curl/curl.exe", @ScriptDir & "\curl\curl.exe", 1)
	ProgressSet(30, 'Téléchargement de "libcurl.dll"')
	InetGet("https://raw.github.com/mGeek/VoiceBox/master/curl/libcurl.dll", @ScriptDir & "\curl\libcurl.dll", 1)
	ProgressSet(60, 'Téléchargement de "libeay32.dll"')
	InetGet("https://raw.github.com/mGeek/VoiceBox/master/curl/libeay32.dll", @ScriptDir & "\curl\libeay32.dll", 1)
	ProgressSet(90, 'Téléchargement de "libssl32.dll"')
	InetGet("https://raw.github.com/mGeek/VoiceBox/master/curl/libssl32.dll", @ScriptDir & "\curl\libssl32.dll", 1)
	ProgressOff()
EndIf

Local $grommoFile = "files/grommo.ini", $voxygenFile = "files/voxygen.ini", $twinmeeFile = "files/twinmee.ini"
InetGet("https://raw.github.com/mGeek/VoiceBox/master/" & $grommoFile, $grommoFile, 1)
InetGet("https://raw.github.com/mGeek/VoiceBox/master/" & $voxygenFile, $voxygenFile, 1)
InetGet("https://raw.github.com/mGeek/VoiceBox/master/" & $twinmeeFile, $twinmeeFile, 1)

Opt("GUIOnEventMode", 1)

Global $GUI = GUICreate("VoiceBox" & $displayVersion, 340, 300)
GUISetFont(10, 400, 0, "Calibri")
GUISetBkColor(0xFCFCFC)

GUICtrlCreateLabel("", 10, 20 + 2, 500, 1)
GUICtrlSetBkColor(-1, 0xCCCCCC)

GUICtrlCreateLabel("VoiceBox" & $displayVersion, 10, 10, 115, 20)
GUICtrlSetColor(-1, 0x111111)
GUICtrlSetFont(-1, 15, 800)

GUICtrlCreateLabel("Message", 25, 50, 50, 20)
GUICtrlSetColor(-1, 0x535353)
$edit = GUICtrlCreateEdit("Bienvenue sur VoiceBox !", 80, 50, 225, 130, $es_wantreturn + $ws_vscroll + $es_autovscroll)

GUICtrlCreateLabel("Service", 30 + 3, 195, 40, 20)
GUICtrlSetColor(-1, 0x535353)

$radioVoxygen = GUICtrlCreateRadio("Voxygen", 80, 190, 100, 25)
GUICtrlSetColor(-1, 0x535353)
GUICtrlSetState(-1, $GUI_CHECKED)
$radioTwinMee = GUICtrlCreateRadio("TwinMee", 180, 190, 100, 25)
GUICtrlSetColor(-1, 0x535353)

GUICtrlCreateLabel("Voix", 45 + 3, 220, 30, 20)
GUICtrlSetColor(-1, 0x535353)
$combo = GUICtrlCreateCombo("", 80, 220, 160, 25)

$voiceFileRead = StringSplit(FileRead($voxygenFile), "*")
For $i = 1 To UBound($voiceFileRead) - 1
	GUICtrlSetData($combo, $voiceFileRead[$i] & "|", $voiceFileRead[1])
Next

GUICtrlCreateLabel("", 0, 250, 350, 50)
GUICtrlSetBkColor(-1, 0xF5F5F5)
GUICtrlSetState(-1, $GUI_DISABLE)

GUICtrlCreateLabel("", 0, 251, 350, 1)
GUICtrlSetBkColor(-1, 0xFFFFFF)
GUICtrlSetState(-1, $GUI_DISABLE)

GUICtrlCreateButton("Écouter", 80, 265, 90, 25)
GUICtrlSetOnEvent(-1, "buttonListen")

GUICtrlCreateButton("Télécharger", 175, 265, 90, 25)
GUICtrlSetOnEvent(-1, "buttonDownload")

GUISetOnEvent(-3, "_Exit")
GUISetState(@SW_SHOW)

Global $voxygenActivated = True
While 1
	Sleep(10)
	If GUICtrlRead($radioVoxygen) = $GUI_CHECKED And Not $voxygenActivated Then
		ConsoleWrite("> Actualisation du combo pour Voxygen" & @CRLF)
		GUICtrlSetData($combo, "", "")
		$voiceFileRead = StringSplit(FileRead($voxygenFile), "*")
		For $i = 1 To UBound($voiceFileRead) - 1
			GUICtrlSetData($combo, $voiceFileRead[$i] & "|", $voiceFileRead[1])
		Next
		$voxygenActivated = True
	EndIf
	If GUICtrlRead($radioVoxygen) = $GUI_UNCHECKED And $voxygenActivated Then
		ConsoleWrite("> Actualisation du combo pour TwinMee" & @CRLF)
		GUICtrlSetData($combo, "", "")
		$voiceFileRead = StringSplit(FileReadLine($twinmeeFile, 1), "*")
		For $i = 1 To UBound($voiceFileRead) - 1
			GUICtrlSetData($combo, $voiceFileRead[$i] & "|", $voiceFileRead[1])
		Next
		$voxygenActivated = False
	EndIf
WEnd

Func _Exit()
	DirRemove(@ScriptDir & "\temp", 1)
	Exit 0
EndFunc   ;==>_Exit

Func buttonListen()
	_GUIDisable($GUI, 0, 45)
	$voice = GUICtrlRead($combo)
	$text = GUICtrlRead($edit)
	$mp3 = voiceSynthesis($voice, grommoFilter($text))
	_GUIDisable(-1, 1)
	If FileExists($mp3) Then ShellExecute($mp3)
EndFunc   ;==>buttonListen

Func buttonDownload()
	_GUIDisable($GUI, 0, 45)
	$voice = GUICtrlRead($combo)
	$text = GUICtrlRead($edit)
	$mp3 = voiceSynthesis($voice, grommoFilter($text))
	If FileExists($mp3) Then
		$file = FileSaveDialog("VoiceBox", @UserProfileDir & "\Downloads\", "Fichiers MP3 (*.mp3)")
		If StringRight($file, 4) <> ".mp3" Then $file &= ".mp3"
		If Not FileMove($mp3, $file, 1) Then MsgBox(48, "Erreur", "Une erreur est survenue et le fichier n'a pas été déplacé." & @CRLF & "Veuillez réessayer")
	EndIf
	_GUIDisable(-1, 1)
EndFunc   ;==>buttonDownload

Func voiceSynthesis($voice, $text)
	Switch $voxygenActivated
		Case True
			ProgressOn("VoiceBox", "Conversion du texte", "Attente du serveur de Voxygen..")
			$timer = TimerInit()
			$pid = Run(@ScriptDir & '\curl\curl.exe voxygen.fr/index.php -X POST -d "voice=' & $voice & "&texte=" & $text & '" -o output', @ScriptDir & '\curl', @SW_HIDE)
			Do
				If TimerDiff($timer) > 2000 Then
					ProgressOff()
					MsgBox(48, "Attention", "Les serveurs de Voxygen semblent être cassés. Veuillez réessayer l'opération.")
					ExitLoop
				EndIf
				Sleep(10)
			Until Not ProcessExists($pid)
			$post = StringReplace(FileRead(@ScriptDir & "\curl\output"), @LF, "")
			$post = StringReplace($post, @CR, "")
			$post = _StringBetween($post, 'mp3:"', '"')
			;FileDelete(@ScriptDir & "\curl\output")
			If IsArray($post) Then
				$file = StringTrimLeft(_MD5($voice & $text), 2) & ".mp3"
				ConsoleWrite($file & " / " & $post[0] & @CRLF)
				ProgressSet(100, "Téléchargement du fichier..")
				$timer = TimerInit()
				$iget_mp3 = InetGet($post[0], @ScriptDir & "\temp\" & $file, 1, 1)
				Do
					ProgressSet(InetGetInfo($iget_mp3, 0))
					If TimerDiff($timer) > 2000 Then
						ProgressOff()
						MsgBox(48, "Attention", "Les serveurs de Voxygen semblent être cassés. Veuillez réessayer l'opération.")
						ExitLoop
					EndIf
					Sleep(10)
				Until InetGetInfo($iget_mp3, 2)
				ProgressOff()
				Return @ScriptDir & "\temp\" & $file
			Else
				ConsoleWrite("!> Erreur" & @CRLF)
				ProgressOff()
				Return MsgBox(48, "Erreur", "Impossible de récuper une URL pour le fichier audio. Veuillez recommencer.")
			EndIf
		Case False
			$authcode = FileReadLine($twinmeeFile, 2)
			$postData = 'KagedoSynthesis=' & URLEncode('<KagedoSynthesis><Identification><codeAuth>' & $authcode & '</codeAuth></Identification><Result><ResultCode/><ErrorDetail/></Result><MainData><DialogList><Dialog character="' & $voice & '">' & $text & '</Dialog></DialogList></MainData></KagedoSynthesis>')
			ConsoleWrite($postData & @CRLF)
			ProgressOn("VoiceBox", "Conversion du texte", "Attente du serveur de TwinMee..")
			$timer = TimerInit()
			$pid = Run(@ScriptDir & '\curl\curl.exe http://webservice.kagedo.fr/nsynthesis/ws/makenewsound -X POST -d "' & $postData & '" -o output', @ScriptDir & '\curl', @SW_HIDE)
			Do
				If TimerDiff($timer) > 2000 Then
					ProgressOff()
					MsgBox(48, "Attention", "Les serveurs de TwinMee semblent être cassés. Veuillez réessayer l'opération.")
					ExitLoop
				EndIf
				Sleep(10)
			Until Not ProcessExists($pid)
			$post = StringReplace(FileRead(@ScriptDir & "\curl\output"), @LF, "")
			$post = _StringBetween($post, 'url="', '"')
			FileDelete(@ScriptDir & "\curl\output")
			If IsArray($post) Then
				$file = StringTrimLeft(_MD5($voice & $text), 2) & ".mp3"
				ConsoleWrite($file & " / " & $post[0] & @CRLF)
				ProgressSet(100, "Téléchargement du fichier..")
				$timer = TimerInit()
				$iget_mp3 = InetGet($post[0], @ScriptDir & "\temp\" & $file, 1, 1)
				Do
					ProgressSet(InetGetInfo($iget_mp3, 0))
					If TimerDiff($timer) > 2000 Then
						ProgressOff()
						MsgBox(48, "Attention", "Les serveurs de TwinMee semblent être cassés. Veuillez réessayer l'opération.")
						ExitLoop
					EndIf
					Sleep(10)
				Until InetGetInfo($iget_mp3, 2)
				ProgressOff()
				Return @ScriptDir & "\temp\" & $file
			Else
				ConsoleWrite("!> Erreur" & @CRLF)
				ProgressOff()
				Return MsgBox(48, "Erreur", "Impossible de récuper une URL pour le fichier audio. Veuillez recommencer.")
			EndIf
	EndSwitch
EndFunc   ;==>voiceSynthesis

Func grommoFilter($text)
	$grommoDatabase = IniReadSection($grommoFile, "GROMMO")
	For $i = 1 To $grommoDatabase[0][0]
		$text = StringReplace($text, $grommoDatabase[$i][0], IniRead($grommoFile, 'GROMMO', $grommoDatabase[$i][0], $grommoDatabase[$i][0]))
		ConsoleWrite("-> GROMMO: " & $i & @CRLF)
	Next
	Return $text
EndFunc   ;==>grommoFilter