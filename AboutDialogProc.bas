#include once "AboutDialogProc.bi"
#include once "Nine.rh"

Function AboutDialogProc(ByVal hwndDlg As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM)As INT_PTR
	Select Case uMsg
		Case WM_INITDIALOG
			
		Case WM_COMMAND
			Select Case LOWORD(wParam)
				Case IDOK
					' Dim AboutMsg As WString *256
					' LoadString(hInst, IDS_ABOUT, AboutMsg, 256)
					' О программе
					'MessageBox(hWin, "Игра Девятка на стадии разработки", "Девятка", MB_OK + MB_ICONINFORMATION)
					EndDialog(hwndDlg, IDOK)
				Case IDCANCEL
					EndDialog(hwndDlg, IDCANCEL)
			End Select
			
		Case WM_CLOSE
			EndDialog(hwndDlg, 0)
			
		Case Else
			Return False
	End Select
	Return True
End Function
