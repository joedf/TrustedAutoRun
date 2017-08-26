﻿; Generated by AutoGUI 1.4.9a
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

Gui +HwndhMainWindow
Gui Add, Tab3, x3 y3 w416 h367, Devices|Options|About
Gui Tab, 1
Gui Add, ListView, x8 y29 w404 h312 Tile gListEvents AltSubmit vList_Devices, Devices
Gui Add, Button, x333 y343 w80 h23 gUntrust vBtn_Untrust Disabled, Untrust
Gui Add, Button, x251 y343 w80 h23 gTrust vBtn_Trust Disabled, Trust
Gui Add, Button, x7 y343 w80 h23 gSetup vBtn_Setup Disabled, Setup...
Gui Add, Button, x89 y343 w80 h23 gRawEdit vBtn_RawEdit Disabled, Raw edit...
Gui Tab, 2
Gui Add, CheckBox, x10 y32 w120 h23, Run at start up
Gui Add, CheckBox, x10 y60 w120 h23, Show notifications
;Gui Add, CheckBox, x10 y87 w159 h23, Show icon in system tray
Gui Tab, 3
Gui Add, Text, x25 y40 w165 h23 +0x200, %APP_NAME% v%APP_VERSION%
Gui Add, Text, x25 y66 w137 h23 +0x200, by joedf
Gui Add, Text, x25 y91 w120 h23 +0x200, Revision: %APP_DATE%
Gui Add, Link, x25 y122 w302 h40, <a href="%APP_URL%">%APP_URL%</a>

Gui Show, w420 h371, %APP_NAME% v%APP_VERSION%
Return

GuiEscape:
GuiClose:
	ExitApp

; Do not edit above this line

MinimizeToTray:
	;TODO
	;/////////////////////////////////
	;/////////////////////////////////
	;/////////////////////////////////
	;/////////////////////////////////
return

ListEvents:
	Btns := "Untrust|Trust|Setup|RawEdit"
	if (dLetter:=getSelectedDrive()) {
		if InStr(A_GuiControlEvent,"DoubleClick") {
			run, explorer.exe "%dLetter%:\",,,xPID
			; Workaround apparent Win7 drawing issue
			WinWait, ahk_pid %xPID%, , 0
			WinSet, Redraw, , ahk_id %hMainWindow%
		}
		Loop, Parse, Btns, |
			GuiControl, Enable, Btn_%A_LoopField%
	} else {
		Loop, Parse, Btns, |
			GuiControl, Disable, Btn_%A_LoopField%
	}
Return

RefreshList:
	LV_Delete()
	IL_Destroy(ImageListID)
	ImageListID := IL_Create(10,5,1)
	LV_SetImageList(ImageListID,0)
	IL_Add(ImageListID, "shell32.dll", 8) 

	USBs := getAllDrives()
	USBs_ConnectedCount := ObjCount(USBs)
	USBs_ConnectedList := ObjKeys(USBs)
	;DriveGet, USBs_ConnectedList, list, REMOVABLE

	iconCount := 1
	for dLetter in USBs
	{
		d := USBs[dLetter]
		trust := is_trusted_USB(d)

		ListItem_Icon := "Icon1"
		ListItem_Text := d.label " (" d.letter ":)" (trust?(" [trusted]"):(""))

		if (d.icon) {
			IL_Add(ImageListID, d.icon, 1) 
			iconCount += 1
			ListItem_Icon := "Icon" iconCount
		}

		LV_Add(ListItem_Icon,ListItem_Text)
	}

	LV_ModifyCol("Hdr")  ; Auto-adjust the column widths.
	Gosub, ListEvents
Return

Setup:
	if (dLetter:=getSelectedDrive()) {
		Gui +Disabled
		Gui +OwnDialogs
		Gui, Show, , %APP_NAME% v%APP_VERSION% (Setup Wizard running...)
		RunWait, setupwizard.ahk
		Gui -Disabled
		Gui, Show, , %APP_NAME% v%APP_VERSION%
	}
	Gosub, RefreshList
Return

RawEdit:
	if (dLetter:=getSelectedDrive()) {
		Gui +Disabled
		Gui +OwnDialogs
		Gui, Show, , %APP_NAME% v%APP_VERSION% (Raw Edit running...)
		fINF := dLetter ":\AUTORUN.INF"
		FileSetAttrib, -R, %fINF%
		RunWait, notepad.exe "%fINF%"
		FileSetAttrib, +RH, %fINF%
		Gui -Disabled
		Gui, Show, , %APP_NAME% v%APP_VERSION%
	}
	Gosub, RefreshList
Return

Trust:
	if (dLetter:=getSelectedDrive()) {
		x := USBs[dLetter]
		if Trust_USB(x)
			MsgBox trust success
		else
			MsgBox trust fail
	}
	Gosub, RefreshList
Return

Untrust:
	if (dLetter:=getSelectedDrive()) {
		x := USBs[dLetter]
		if Untrust_USB(x)
			MsgBox untrust success
		else
			MsgBox untrust fail
	}
	Gosub, RefreshList
Return

getSelectedDrive() {
	if (x:=LV_GetNext()) {
		LV_GetText(dName, x)
		dLetter := SubStr(dName, InStr(dName,":)",1,0)-1, 1)
		Return dLetter
	}
	Return 0
}
