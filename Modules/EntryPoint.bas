#include "EntryPoint.bi"
#include "WinMain.bi"

#ifdef WITHOUT_RUNTIME
Function EntryPoint Alias "EntryPoint"()As Integer
#endif
	
	Dim ArgsCount As DWORD = Any
	Dim Args As WString Ptr Ptr = CommandLineToArgvW(GetCommandLine(), @ArgsCount)
	Dim RetCode As Integer = WinMain(GetModuleHandle(0), NULL, Args, CInt(ArgsCount), SW_SHOW)
	LocalFree(Args)
	
	#ifdef WITHOUT_RUNTIME
		Return RetCode
	#else
		End(RetCode)
	#endif
	
#ifdef WITHOUT_RUNTIME
End Function
#endif
