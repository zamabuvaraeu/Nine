#ifndef GDIGRAPHICS_BI
#define GDIGRAPHICS_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"

Type GdiGraphics
	Dim DeviceContext As HDC
	Dim Bitmap As HBITMAP
	Dim OldBitmap As HBITMAP
	Dim OldPen As HPEN
	Dim OldBrush As HBRUSH
	Dim OldFont As HFONT
End Type

Declare Sub InitializeGraphics( _
	ByVal g As GdiGraphics Ptr, _
	ByVal hWin As HWND, _
	ByVal DefaultPen As HPEN, _
	ByVal DefaultBrush As HBRUSH, _
	ByVal DefaultFont As HFONT _
)

Declare Sub UnInitializeGraphics( _
	ByVal g As GdiGraphics Ptr _
)

#endif
