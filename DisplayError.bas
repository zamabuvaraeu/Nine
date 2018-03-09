#include once "DisplayError.bi"

#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "IntegerToWString.bi"

Sub DisplayError( _
		ByVal ErrorCode As Integer, _
		ByVal Caption As WString Ptr _
	)
	
	Dim Buffer As WString * 100 = Any
	itow(ErrorCode, @Buffer, 10)
	MessageBox(0, @Buffer, Caption, MB_ICONERROR)
End Sub