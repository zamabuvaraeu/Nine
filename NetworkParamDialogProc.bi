#ifndef NETWORKPARAMDIALOGPROC_BI
#define NETWORKPARAMDIALOGPROC_BI

#ifndef unicode
#define unicode
#endif

#include "windows.bi"

Const MaxCharsLength As Integer = 255

Type NetworkParams
	Dim ResultCode As Integer
	
	Dim Nick As WString * (MaxCharsLength + 1)
	Dim Server As WString * (MaxCharsLength + 1)
	Dim Port As WString * (MaxCharsLength + 1)
	Dim Channel As WString * (MaxCharsLength + 1)
	Dim LocalAddress As WString * (MaxCharsLength + 1)
	Dim LocalPort As WString * (MaxCharsLength + 1)
End Type

Declare Function NetworkParamDialogProc(ByVal hwndDlg As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM)As INT_PTR

#endif
