#include "CardControl.bi"

Const BackColor As Integer = &h006400

Type WindowExtraData
	Dim CardNumber As Integer
	Dim CardView As CardViews
End Type

Function CardControlWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			Dim pWndExtra As WindowExtraData Ptr = Allocate(SizeOf(WindowExtraData))
			pWndExtra->CardNumber = 0
			pWndExtra->CardView = CardViews.Normal
			
			SetWindowLongPtr(hWin, 0, Cast(LONG_PTR, pWndExtra))
			
			Dim DefautlCardWidth As Integer = Any
			Dim DefautlCardHeight As Integer = Any
			cdtInit(@DefautlCardWidth, @DefautlCardHeight)
			
		' Case WM_LBUTTONDOWN
			' MainForm_LeftMouseDown(hWin, wParam, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam))
			
		' Case WM_KEYDOWN
			' MainForm_KeyDown(hWin, wParam)
			
		Case WM_PAINT
			Dim ps As PAINTSTRUCT = Any
			Dim hDCWin As HDC = BeginPaint(hWin, @ps)
			
			Dim pWndExtra As WindowExtraData Ptr = CPtr(WindowExtraData Ptr, GetWindowLongPtr(hWin, 0))
			
			Dim rc As RECT = Any
			GetWindowRect(hWin, @rc)
			
			cdtDrawExt(hDCWin, 0, 0, rc.right - rc.left, rc.bottom - rc.top, pWndExtra->CardNumber, pWndExtra->CardView, 0)
			
			EndPaint(hWin, @ps)
			
		Case WM_DESTROY
			Dim pWndExtra As WindowExtraData Ptr = CPtr(WindowExtraData Ptr, GetWindowLongPtr(hWin, 0))
			DeAllocate(pWndExtra)
			
			cdtTerm()
			PostQuitMessage(0)
			
		Case PM_SETCARDNUMBER
			'
			
		Case PM_GETCARDNUMBER
			'
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Function InitCardControl()As Integer
	
	Dim hInst As HINSTANCE = GetModuleHandle(0)
	
	Dim wcls As WNDCLASSEX = Any
	With wcls
		.cbSize        = SizeOf(WNDCLASSEX)
		.style         = 0
		.lpfnWndProc   = @CardControlWndProc
		.cbClsExtra    = 0
		.cbWndExtra    = SizeOf(WindowExtraData Ptr)
		.hInstance     = hInst
		.hIcon         = LoadIcon(NULL, IDI_APPLICATION)
		.hCursor       = LoadCursor(NULL, IDC_ARROW)
		.hbrBackground = CreateSolidBrush(BackColor)
		.lpszMenuName  = Cast(WString Ptr, NULL)
		.lpszClassName = @CardControlClassName
		.hIconSm       = NULL
	End With
	
	Return RegisterClassEx(@wcls)
	
End Function
