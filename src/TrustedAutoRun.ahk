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

/*
USBs := getAllDrives()
for Letter in USBs
{
	d := USBs[Letter]
	Msgbox % "Removable USB Detected`nDrive: `t" d.letter "`nLabel: `t" d.label "`nSerial: `t" d.Serial "`nSignature: `n" d.signature
}
MsgBox
*/

gosub, initGUI
ImageListID := IL_Create(10,5,1)
LV_SetImageList(ImageListID,0)
IL_Add(ImageListID, "shell32.dll", 8) 

USBs := getAllDrives()
for Letter in USBs
{
	d := USBs[Letter]
	LV_Add("Icon1", d.label " (" d.letter ":)")
}

LV_ModifyCol("Hdr")  ; Auto-adjust the column widths.
Return

initGUI:
#Include gui.ahk
Return

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
		d := getDriveInfo(A_LoopField)
		;Drives.list += d.letter
		drives[d.letter] := d
	}
	return drives
}

getDriveInfo(d) {
	DriveGet,s,serial,%d%:
	DriveGet,f,filesystem,%d%:
	DriveGet,l,label,%d%:
	sig := get_sig(d)
	return {letter:d,serial:s,filesystem:f,label:l,signature:sig}
}

get_sig(driveLetter) {
	global APP_NAME
	fUsbini := driveLetter ":\AUTORUN.INF"
	;if !FileExist(fUsbini)
	;	return false
	IniRead, sig, %fUsbini%, %APP_NAME%, signature, NULL
	return sig
}

isValid_sig(sig) {
	; Match SHA256
	return RegExMatch(sig,"^[A-Fa-f0-9]{64}$")
}

sign_usb(driveLetter,hmac) {
	global APP_NAME
	uuid := CreateUUID()
	sig := bcrypt_sha256_hmac(uuid, hmac)
	fUsbini := driveLetter ":\AUTORUN.INF"
	if FileExist(fUsbini)
		FileSetAttrib, -R, %fUsbini%
	IniWrite, %sig%, %fUsbini%, %APP_NAME%, signature
	e := ErrorLevel
	FileSetAttrib, +RH, %fUsbini%
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