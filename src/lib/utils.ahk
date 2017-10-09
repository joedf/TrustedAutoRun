HighDPI() {
	; from https://autohotkey.com/board/topic/3241-how-to-detect-normal-or-large-font-size-settings-dpi/	
	; returns 0 if normal font size or 1 if LARGE font size
	RegRead, DPI_value, HKEY_CURRENT_USER, Control Panel\Desktop\WindowMetrics, AppliedDPI
	if errorlevel=1 ; the reg key was not found - it means default settings
		return 0
	if DPI_value=96 ; 96 is the default font size setting
		return 0
	if DPI_value>96 ; A higher value should mean LARGE font size setting
		return 1
}