#NoTrayIcon

#AutoIt3Wrapper_Icon=res\VoiceBox.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=VoiceBox
#AutoIt3Wrapper_Res_Fileversion=2.0.3.0
#AutoIt3Wrapper_Res_Language=1036

#cs ----------------------------------------------------------------------------

	VoiceBox
	par mGeek (http://mgeek.fr)
	avec les am�liorations de PHP-Voxygen ainsi que PHP-TwinMee de TiBounise (http://tibounise.com)

	changelog:

	- � venir:
	Design � terminer
	Rendre la connexion avec TwinMee stable
	Trouver une solution plus adapt�e que le _GuiDisable() pour indiquer le chargement

	- 2.03 (1)
	Supression du CUI laiss� par m�garde

	- 2.03
	Supression des includes inutiles
	Ajout d'un message pour avertir les utilisateurs des probl�mes rencontr�s avec TwinMee
	Optimisation lors de la conversion du texte:
		Disparition de curl pour une solution plus l�g�re (plus de dossier /temp)
		Les fichiers � �couter sont maintenant stoqu�s dans %temp%
	A propos du player:
		Retour de <Sound.au3> malgr� certaines fonctions qui marchent mal chez certaines personnes
		Par cons�quent, le player est r�int�gr� -- bouton play/pause qui se substitue au bouton �couter

	- 2.02
	Corrig�: Ajout d'un timeout lors de la connexion aux serveurs
	Corrig�: Ajout d'un timeout lors du t�l�chargement des fichiers mp3
	Corrig�: Supression du player mp3 et remplacement par le lecteur associ� avec Windows

	- 2.01
	Ajout: V�rification de l'existance des librairies CURL / T�l�chargement si elles ne sont pas pr�sentes
	Corrig�: Disparition de la ProgressBar en cas d'erreur de conversion (pour les deux services)
	Nettoyage de code

#ce ----------------------------------------------------------------------------

#include <String.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include "Include.au3"
#include <Sound.au3> ;Inclut File.au3

$version = "2.03"
$displayVersion = " " & $version

OnAutoItExitRegister("_Exit")

Local $grommoFile = @TempDir & "/grommo.ini", $voxygenFile = @TempDir & "/voxygen.ini", $twinmeeFile = @TempDir & "/twinmee.ini"
InetGet("https://raw.github.com/mGeek/VoiceBox/master/files/grommo.ini", $grommoFile, 1)
InetGet("https://raw.github.com/mGeek/VoiceBox/master/files/voxygen.ini", $voxygenFile, 1)
InetGet("https://raw.github.com/mGeek/VoiceBox/master/files/twinmee.ini", $twinmeeFile, 1)

Opt("GUIOnEventMode", 1)
;HotKeySet("{ENTER}", "buttonListen")

MsgBox(32, "VoiceBox", "Certains utilisateurs ont des probl�mes avec certaines voix de TwinMee." & @CRLF & "J'y peux rien si leur API est � moiti� foutu, h�berg� � droite � gauche sur 30 serveurs en parall�le.")

Global $GUI = GUICreate("VoiceBox" & $displayVersion, 340, 300)
GUISetFont(10, 400, 0, "Calibri")
GUISetBkColor(0xFCFCFC)

GUICtrlCreateLabel("", 150, 20 + 2, 500, 1)
GUICtrlSetBkColor(-1, 0xCCCCCC)

GUICtrlCreateIcon(@AutoItExe, 0, 5+2, 5+1, 32, 32)

GUICtrlCreateLabel("VoiceBox" & $displayVersion, 45, 10, 150, 20)
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
$radioTwinMee = GUICtrlCreateRadio("TwinMee (beta)", 180, 190, 100, 25)
GUICtrlSetColor(-1, 0x535353)

GUICtrlCreateLabel("Voix", 45 + 3, 220, 30, 20)
GUICtrlSetColor(-1, 0x535353)
$combo = GUICtrlCreateCombo("", 80, 220, 160, 25)

$voiceFileRead = StringSplit(FileRead($voxygenFile), "*")
For $i = 1 To UBound($voiceFileRead) - 1
	GUICtrlSetData($combo, $voiceFileRead[$i] & "|", $voiceFileRead[1])
Next

GUICtrlCreateLabel("", 0, 250, 350, 50)
GUICtrlSetBkColor(-1, 0xE5E5E5)
GUICtrlSetState(-1, $GUI_DISABLE)

GUICtrlCreateLabel("", 0, 251, 350, 1)
GUICtrlSetBkColor(-1, 0xFFFFFF)
GUICtrlSetState(-1, $GUI_DISABLE)

$buttonListen = GUICtrlCreateButton("�couter", 80, 265, 90, 25)
GUICtrlSetOnEvent(-1, "buttonListen")

GUICtrlCreateButton("T�l�charger", 175, 265, 90, 25)
GUICtrlSetOnEvent(-1, "buttonDownload")

GUISetOnEvent(-3, "_Exit")
GUISetState(@SW_SHOW)

Global $voxygenActivated = True, $soundPlaying = False, $soundStatus, $sound
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
	If $soundPlaying And $soundStatus <> _SoundStatus($sound) Then
		Switch _SoundStatus($sound)
			Case "playing"
				GUICtrlSetData($buttonListen, "Pause")
				$soundStatus = "playing"
			Case "paused"
				GUICtrlSetData($buttonListen, "Lecture")
				$soundStatus = "paused"
			Case "stopped"
				GUICtrlSetData($buttonListen, "�couter")
				$soundStatus = ""
				$soundPlaying = False
		EndSwitch
		ConsoleWrite(_SoundStatus($sound) & @CRLF)
	EndIf
WEnd

Func _Exit()
	DirRemove(@ScriptDir & "\temp", 1)
	Exit 0
EndFunc   ;==>_Exit

Func buttonListen()
	ConsoleWrite("buttonClick" & @CRLF)
	If $soundPlaying Then
		ConsoleWrite("> Son" & @CRLF)
		If _SoundStatus($sound) = "playing" Then Return _SoundPause($sound)
		If _SoundStatus($sound) = "paused" Then Return _SoundResume($sound)
	Else
		_GUIDisable($GUI, 0, 45)
		$voice = GUICtrlRead($combo)
		$text = GUICtrlRead($edit)
		$mp3 = voiceSynthesis($voice, grommoFilter($text))
		_GUIDisable(-1, 1)
		If FileExists($mp3) Then
			Global $sound = _SoundOpen($mp3)
			_SoundPlay($sound)
			$soundPlaying = True
		EndIf
	EndIf
EndFunc   ;==>buttonListen

Func buttonDownload()
	_GUIDisable($GUI, 0, 45)
	$voice = GUICtrlRead($combo)
	$text = GUICtrlRead($edit)
	$mp3 = voiceSynthesis($voice, grommoFilter($text))
	If FileExists($mp3) Then
		$file = FileSaveDialog("VoiceBox", @UserProfileDir & "\Downloads\", "Fichiers MP3 (*.mp3)")
		If StringRight($file, 4) <> ".mp3" Then $file &= ".mp3"
		If Not FileMove($mp3, $file, 1) Then MsgBox(48, "Erreur", "Une erreur est survenue et le fichier n'a pas �t� d�plac�." & @CRLF & "Veuillez r�essayer")
	EndIf
	_GUIDisable(-1, 1)
EndFunc   ;==>buttonDownload

Func voiceSynthesis($voice, $text)
	ConsoleWrite("Requ�te.." & @CRLF)
	ProgressOn("", "Requ�te en cours..")
	$HTTP = ObjCreate("winhttp.winhttprequest.5.1")

	If $voxygenActivated = True Then ;Requ�te en fonction du serveur s�l�ctionn�
		$postData = 'voice=' & $voice & '&texte=' & $text
		$HTTP.Open("POST", "http://voxygen.fr/index.php", False)
	Else
		$authcode = FileReadLine($twinmeeFile, 2)
		$postData = 'KagedoSynthesis=' & URLEncode('<KagedoSynthesis><Identification><codeAuth>' & $authcode & '</codeAuth></Identification><Result><ResultCode/><ErrorDetail/></Result><MainData><DialogList><Dialog character="' & $voice & '">' & $text & '</Dialog></DialogList></MainData></KagedoSynthesis>')
		$HTTP.Open("POST", "http://webservice.kagedo.fr/nsynthesis/ws/makenewsound", False)
	EndIf
	$HTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	$HTTP.Send($postData)

	ConsoleWrite("R�ponse serveur: " & $HTTP.Status & @CRLF)
	If $HTTP.Status <> "200" Then Return ConsoleWrite(ProgressOff() & MsgBox(48, "Erreur", "Le serveur n'a pas r�pondu la r�ponse voulue" & @CRLF & "R�ponse donn�e: " & $HTTP.Status) & @CRLF)

	$data = StringReplace(StringReplace($HTTP.ResponseText, @LF, ""), @CR, "") ;Supprime les caract�res de retour � la ligne de la r�ponse

	If $voxygenActivated = True Then ;Retrouve le lien du fichier MP3
		$data = _StringBetween($data, 'mp3:"', '"')
	Else
		$data = _StringBetween($data, 'url="', '"')
	EndIf
	If IsArray($data) Then ;Si le lien a �t� retrouv�
		$timer = TimerInit()
		$file = _TempFile(-1, -1, ".mp3")
		$iget_mp3 = InetGet($data[0], $file, 1, 1)
		Do
			ProgressSet(50)
			If TimerDiff($timer) > 2000 Then Return ConsoleWrite(ProgressOff() & MsgBox(48, "Erreur", "Le t�l�chargement semble long, les serveurs de Voxygen sont peut �tre satur�s" & @CRLF & "Veuillez r�essayer l'op�ration.") & @CRLF)
			Sleep(10)
		Until InetGetInfo($iget_mp3, 2)
		ProgressOff()
		Return $file
	Else
		Return ConsoleWrite("!> Erreur" & ProgressOff() & MsgBox(48, "Erreur", "Impossible de r�cuper l'URL du fichier audio" & @CRLF & "Veuillez r�essayer l'op�ration.") & @CRLF)
	EndIf
EndFunc   ;==>voiceSynthesis

Func grommoFilter($text)
	$grommoDatabase = IniReadSection($grommoFile, "GROMMO")
	For $i = 1 To $grommoDatabase[0][0]
		$text = StringReplace($text, $grommoDatabase[$i][0], IniRead($grommoFile, 'GROMMO', $grommoDatabase[$i][0], $grommoDatabase[$i][0]))
		ConsoleWrite("-> GROMMO: " & $i & @CRLF)
	Next
	Return $text
EndFunc   ;==>grommoFilter