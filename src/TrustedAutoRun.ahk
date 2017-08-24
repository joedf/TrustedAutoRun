#NoEnv
;#NoTrayIcon
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

USBs := getAllDrives()
for Letter in USBs
{
	d := USBs[Letter]
	Msgbox % "Removable USB Detected`nDrive: `t" d.letter "`nLabel: `t" d.label "`nSerial: `t" d.Serial
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

sign_usb(driveLetter) {
	bcrypt_sha256_hmac(string, hmac)
}
