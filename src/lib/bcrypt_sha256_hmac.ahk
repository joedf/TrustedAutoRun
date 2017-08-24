; modified from jNizM
; permalink: https://github.com/jNizM/AHK_CNG

bcrypt_sha256_hmac(string, hmac) {
	if A_OSVersion in WIN_7,WIN_VISTA,WIN_2003,WIN_XP,WIN_2000,WIN_NT4,WIN_95,WIN_98,WIN_ME
		return win7_bcrypt_sha256_hmac(string, hmac)
	else
		return win10_bcrypt_sha256_hmac(string, hmac)
}

win10_bcrypt_sha256_hmac(string, hmac)
{
	static BCRYPT_SHA256_ALGORITHM     := "SHA256"
	static BCRYPT_ALG_HANDLE_HMAC_FLAG := 0x00000008
	static BCRYPT_HASH_LENGTH          := "HashDigestLength"

	if !(hBCRYPT := DllCall("LoadLibrary", "str", "bcrypt.dll", "ptr"))
		throw Exception("Failed to load bcrypt.dll", -1)

	if (NT_STATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", hAlgo, "ptr", &BCRYPT_SHA256_ALGORITHM, "ptr", 0, "uint", BCRYPT_ALG_HANDLE_HMAC_FLAG) != 0)
		throw Exception("BCryptOpenAlgorithmProvider: " NT_STATUS, -1)

	if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_HASH_LENGTH, "uint*", cbHash, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
		throw Exception("BCryptGetProperty: " NT_STATUS, -1)

	VarSetCapacity(pbInput,  StrPut(string, "UTF-8"), 0) && cbInput  := StrPut(string, &pbInput,  "UTF-8") - 1
	VarSetCapacity(pbSecret, StrPut(hmac, "UTF-8"), 0)   && cbSecret := StrPut(hmac,   &pbSecret, "UTF-8") - 1
	VarSetCapacity(pbHash, cbHash, 0)
	if (NT_STATUS := DllCall("bcrypt\BCryptHash", "ptr", hAlgo, "ptr", &pbSecret, "uint", cbSecret, "ptr", &pbInput, "uint", cbInput, "ptr", &pbHash, "uint", cbHash) != 0)
		throw Exception("BCryptHash: " NT_STATUS, -1)

	loop % cbHash
		hash .= Format("{:02x}", NumGet(pbHash, A_Index - 1, "uchar"))

	DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", hAlgo, "uint", 0)
	DllCall("FreeLibrary", "ptr", hBCRYPT)

	return hash
}

win7_bcrypt_sha256_hmac(string, hmac)
{
	static BCRYPT_SHA256_ALGORITHM     := "SHA256"
	static BCRYPT_ALG_HANDLE_HMAC_FLAG := 0x00000008
	static BCRYPT_OBJECT_LENGTH        := "ObjectLength"
	static BCRYPT_HASH_LENGTH          := "HashDigestLength"

	if !(hBCRYPT := DllCall("LoadLibrary", "str", "bcrypt.dll", "ptr"))
		throw Exception("Failed to load bcrypt.dll", -1)

	if (NT_STATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", hAlgo, "ptr", &BCRYPT_SHA256_ALGORITHM, "ptr", 0, "uint", BCRYPT_ALG_HANDLE_HMAC_FLAG) != 0)
		throw Exception("BCryptOpenAlgorithmProvider: " NT_STATUS, -1)

	if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_OBJECT_LENGTH, "uint*", cbHashObject, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
		throw Exception("BCryptGetProperty: " NT_STATUS, -1)

	if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_HASH_LENGTH, "uint*", cbHash, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
		throw Exception("BCryptGetProperty: " NT_STATUS, -1)

	VarSetCapacity(pbHashObject, cbHashObject, 0) && VarSetCapacity(pbSecret, StrPut(hmac, "UTF-8"), 0) && cbSecret := StrPut(hmac, &pbSecret, "UTF-8") - 1
	if (NT_STATUS := DllCall("bcrypt\BCryptCreateHash", "ptr", hAlgo, "ptr*", hHash, "ptr", &pbHashObject, "uint", cbHashObject, "ptr", &pbSecret, "uint", cbSecret, "uint", 0) != 0)
		throw Exception("BCryptCreateHash: " NT_STATUS, -1)

	VarSetCapacity(pbInput, StrPut(string, "UTF-8"), 0) && cbInput := StrPut(string, &pbInput, "UTF-8") - 1
	if (NT_STATUS := DllCall("bcrypt\BCryptHashData", "ptr", hHash, "ptr", &pbInput, "uint", cbInput, "uint", 0) != 0)
		throw Exception("BCryptHashData: " NT_STATUS, -1)

	VarSetCapacity(pbHash, cbHash, 0)
	if (NT_STATUS := DllCall("bcrypt\BCryptFinishHash", "ptr", hHash, "ptr", &pbHash, "uint", cbHash, "uint", 0) != 0)
		throw Exception("BCryptFinishHash: " NT_STATUS, -1)

	loop % cbHash
		hash .= Format("{:02x}", NumGet(pbHash, A_Index - 1, "uchar"))

	DllCall("bcrypt\BCryptDestroyHash", "ptr", hHash)
	DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", hAlgo, "uint", 0)
	DllCall("FreeLibrary", "ptr", hBCRYPT)

	return hash
}