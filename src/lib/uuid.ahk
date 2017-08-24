; from jNizM
; https://autohotkey.com/boards/viewtopic.php?p=27150#p27150
CreateUUID()
{
    VarSetCapacity(UUID, 16, 0)
    if (DllCall("rpcrt4.dll\UuidCreate", "ptr", &UUID) != 0)
        return (ErrorLevel := 1) & 0
    if (DllCall("rpcrt4.dll\UuidToString", "ptr", &UUID, "uint*", suuid) != 0)
        return (ErrorLevel := 2) & 0
    return StrGet(suuid), DllCall("rpcrt4.dll\RpcStringFree", "uint*", suuid)
}