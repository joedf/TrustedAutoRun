#NoEnv
;#NoTrayIcon
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include lib\uuid.ahk
#Include lib\bcrypt_sha256_hmac.ahk

APP_NAME := "TrustedAutoRun"

USBs := getAllDrives()
for Letter in USBs
{
	d := USBs[Letter]
	Msgbox % "Removable USB Detected`nDrive: `t" d.letter "`nLabel: `t" d.label "`nSerial: `t" d.Serial "`nSignature: `t" sign_usb(d.letter,d.Serial)
}
MsgBox

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
	return {letter:d,serial:s,filesystem:f,label:l}
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
