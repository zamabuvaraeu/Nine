#include once "ThreadProc.bi"
#include once "Irc.bi"

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	Dim objClient As IrcClient Ptr = CPtr(IrcClient Ptr, lpParam)
	Do
	Loop While objClient->GetData() = ResultType.None
	' Закрыть
	objClient->CloseIrc()
	Return 0
End Function
