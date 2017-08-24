#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

DriveGet, drivelist, List, REMOVABLE
Loop,Parse,drivelist
{
	d := getDriveInfo(A_LoopField)
	Msgbox % "Removable USB Detected`nDrive: `t" d.letter "`nLabel: `t" d.label "`nSerial: `t" d.Serial
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
