#NoEnv
;#NoTrayIcon
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include lib\uuid.ahk
#Include lib\bcrypt_sha256_hmac.ahk

APP_NAME := "TrustedAutoRun"
APP_DATE := "24/08/17"
APP_VERSION := "0.0.2"
APP_URL := "https://github.com/joedf/TrustedAutoRun"
APP_INI := A_ScriptDir "\config.ini"
APP_PID := DllCall("GetCurrentProcessId")

/*
USBs := getAllDrives()
for Letter in USBs
{
	d := USBs[Letter]
	Msgbox % "Removable USB Detected`nDrive: `t" d.letter "`nLabel: `t" d.label "`nSerial: `t" d.Serial "`nSignature: `n" d.signature
}
MsgBox
*/



/*

CHECK FOR Status REaDY EVERYWHERE,. funcs too
to avoid usbs that are "ejected" but still physically connected to appear
in refresh list, etc
DriveGet, drivestatus, Status, %a_LoopField%:\
      If drivestatus = Ready

need EJECTION DETECTION!

*/



Gosub, initGUI
Gosub, RefreshList

; from https://autohotkey.com/board/topic/45042-detect-when-specific-usb-device-is-connected/#entry280380
OnMessage(0x219, "notify_USB_Change")
SetTimer, detectEject, 500
Return 

notify_USB_Change(wParam, lParam, msg, hwnd) 
{ 
	global USBs_ConnectedCount
	global USBs_ConnectedList
	;MsgBox, %wParam% %lParam% %msg% %hwnd%
	oldCount := USBs_ConnectedCount
	oldList := USBs_ConnectedList
	Gosub, RefreshList

	; Autoruns excuted only on adding a device, not on removal
	if (USBs_ConnectedCount > oldCount) {
		;MsgBox Insert! %USBs_ConnectedCount% > %oldCount%
		;Msgbox %oldList%,%USBs_ConnectedList%
		if x:=newDiff(oldList,USBs_ConnectedList) {
			;Msgbox New Device: %x%
			; TODO!: NOT ALL Autoruns! only the newly added one!
			trusted_autorun(x)
		}
	}
}

initGUI:
	#Include lib\gui.ahk
Return

detectEject:
	Loop, Parse, USBs_ConnectedList
	{
		DriveGet, drivestatus, Status, %A_LoopField%:\
		if drivestatus != Ready
			PostMessage, 0x219, , , , ahk_pid %APP_PID%
	}
Return

; from https://autohotkey.com/boards/viewtopic.php?p=42795#p42795
ObjCount(o) {
	return NumGet(&o + 4*A_PtrSize)
}

ObjKeys(o) {
	l := ""
	for k in o
		l .= k
	return l
}

newDiff(old,new) {
	Loop, Parse, new
	{
		if !InStr(old,A_LoopField,0)
			return A_LoopField
	}
	return false
}

trusted_autorun(d) {
	global USBs
	if !IsObject(d) {
		d := USBs[d]
	}

	if is_trusted_USB(d) {
		fINF := d.letter ":\AUTORUN.INF"
		IniRead, dAction, %fINF%, AUTORUN, Open, NULL
		dAction := d.letter ":\" dAction
		if FileExist(dAction) {
			;MsgBox Success Action: %dAction%
			Run, "%dAction%", , UseErrorLevel
			return !ErrorLevel
		}
	}
	Return False
}

trusted_autorunAll() {
	global USBs
	for dLetter in USBs
	{
		d := USBs[dLetter]
		Return trusted_autorun(d)
	}
}

is_trusted_USB(d) {
	global APP_NAME
	global APP_INI
	onDriveSig := get_sig(d.letter)
	serial := d.serial
	IniRead, trustSig, %APP_INI%, %APP_NAME%, %serial%, NULL
	if ( isValid_sig(onDriveSig) && isValid_sig(trustSig) ) {
		StringUpper, onDriveSig, onDriveSig
		StringUpper, trustSig, trustSig
		return (onDriveSig == trustSig)
	}
	return false
}

Trust_USB(d) {
	global APP_NAME
	global APP_INI
	if (sig := sign_usb(d.letter,d.Serial)) {
		IniWrite, %sig%, %APP_INI%, %APP_NAME%, % d.serial
		Return !ErrorLevel
	}
	Return False
}

UnTrust_USB(d) {
	global APP_NAME
	global APP_INI
	if (unsign_usb(d.letter)) {
		IniDelete, %APP_INI%, %APP_NAME%, % d.serial
		Return !ErrorLevel
	}
	Return False
}

getAllDrives() {
	drives := Object()
	;drives.list := ""
	DriveGet, drivelist, List, REMOVABLE
	Loop,Parse,drivelist
	{
		DriveGet, drivestatus, Status, %A_LoopField%:\
		If drivestatus = Ready
		{
			d := getDriveInfo(A_LoopField)
			;Drives.list += d.letter
			drives[d.letter] := d
		}
	}
	return drives
}

getDriveInfo(d) {
	DriveGet,s,serial,%d%:
	DriveGet,f,filesystem,%d%:
	DriveGet,l,label,%d%:
	sig := get_sig(d)
	pIcon := getDriveIcon(d)
	return {letter:d,serial:s,filesystem:f,label:l,signature:sig,icon:pIcon}
}

getDriveIcon(driveLetter) {
	fINF := driveLetter ":\AUTORUN.INF"
	IniRead, pIcon, %fINF%, AUTORUN, icon, *
	if ( ErrorLevel || (pIcon=="*"))
		Return False
	Return driveLetter ":\" pIcon
}

get_sig(driveLetter) {
	global APP_NAME
	fINF := driveLetter ":\AUTORUN.INF"
	IniRead, sig, %fINF%, %APP_NAME%, signature, NULL
	if (isValid_sig(sig))
		return sig
	Return False
}

isValid_sig(sig) {
	; Match SHA256
	return RegExMatch(sig,"^[A-Fa-f0-9]{64}$")
}

sign_usb(driveLetter,hmac) {
	global APP_NAME
	fINF := driveLetter ":\AUTORUN.INF"
	if FileExist(fINF) {
		IniRead, rSig, %fINF%, %APP_NAME%, signature, NULL
		; Do not resign if valid signature already exists
		if isValid_sig(rSig) {
			return rSig
		}
		FileSetAttrib, -R, %fINF%
	}
	uuid := CreateUUID()
	sig := bcrypt_sha256_hmac(uuid, hmac)
	IniWrite, %sig%, %fINF%, %APP_NAME%, signature
	e := ErrorLevel
	FileSetAttrib, +RH, %fINF%
	if !e
		return sig
	return false
}

unsign_usb(driveLetter) {
	global APP_NAME
	fINF := driveLetter ":\AUTORUN.INF"
	if !FileExist(fINF)
		Return true
	FileSetAttrib, -R, %fINF%
	IniDelete,%fINF%,%APP_NAME%
	e := ErrorLevel
	FileSetAttrib, +RH, %fINF%
		Return !e
}
