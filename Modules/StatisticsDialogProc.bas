#include "StatisticsDialogProc.bi"
#include "Resources.RH"

Function StatisticsDialogProc(ByVal hwndDlg As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM)As INT_PTR
	
	Select Case uMsg
		
		Case WM_INITDIALOG
			Dim pParam As StatisticParams Ptr = CPtr(StatisticParams Ptr, lParam)
			
			If pParam <> NULL Then
				SetDlgItemInt(hwndDlg, IDC_EDT_WINSCOUNT, pParam->WinsCount, 0)
				SetDlgItemInt(hwndDlg, IDC_EDT_FAILSCOUNT, pParam->FailsCount, 0)
				
				HeapFree(GetProcessHeap(), 0, pParam)
			End If
			
		Case WM_COMMAND
			Select Case LOWORD(wParam)
				
				Case IDOK
					EndDialog(hwndDlg, Cast(INT_PTR, 0))
					
				Case IDCANCEL
					EndDialog(hwndDlg, Cast(INT_PTR, 0))
					
			End Select
			
		Case WM_CLOSE
			EndDialog(hwndDlg, 0)
			
		Case Else
			Return False
			
	End Select
	
	Return True
	
End Function
