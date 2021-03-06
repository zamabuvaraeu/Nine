#include "NetworkParamDialogProc.bi"
#include "Resources.RH"

Function NetworkParamDialogProc(ByVal hwndDlg As HWND, ByVal uMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM)As INT_PTR
	
	Select Case uMsg
		
		' Case WM_INITDIALOG
			
		Case WM_COMMAND
			
			Select Case LOWORD(wParam)
				
				Case IDOK
					Dim pParams As NetworkParams Ptr = HeapAlloc(GetProcessHeap(), 0, SizeOf(NetworkParams))
					
					If pParams <> NULL Then
						
						pParams->ResultCode = IDOK
						
						GetDlgItemText(hwndDlg, IDC_EDT_NICK, @pParams->Nick, MaxCharsLength)
						GetDlgItemText(hwndDlg, IDC_EDT_SERVER, @pParams->Server, MaxCharsLength)
						GetDlgItemText(hwndDlg, IDC_EDT_PORT, @pParams->Port, MaxCharsLength)
						GetDlgItemText(hwndDlg, IDC_EDT_CHANNEL, @pParams->Channel, MaxCharsLength)
						GetDlgItemText(hwndDlg, IDC_EDT_LOCALADDRESS, @pParams->LocalAddress, MaxCharsLength)
						GetDlgItemText(hwndDlg, IDC_EDT_LOCALPORT, @pParams->LocalPort, MaxCharsLength)
						
					End If
					
					EndDialog(hwndDlg, Cast(INT_PTR, pParams))
					
				Case IDCANCEL
					Dim pParams As NetworkParams Ptr = HeapAlloc(GetProcessHeap(), 0, SizeOf(NetworkParams))
					
					If pParams <> NULL Then
						pParams->ResultCode = IDCANCEL
					End If
					
					EndDialog(hwndDlg, Cast(INT_PTR, pParams))
					
			End Select
			
		Case WM_CLOSE
			EndDialog(hwndDlg, 0)
			
		Case Else
			Return False
			
	End Select
	
	Return True
	
End Function
