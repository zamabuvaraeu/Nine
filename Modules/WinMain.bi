#ifndef WINMAIN_BI
#define WINMAIN_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"

Declare Function wWinMain( _
	Byval hInst As HINSTANCE, _
	ByVal hPrevInstance As HINSTANCE, _
	ByVal lpCmdLine As LPWSTR, _
	ByVal iCmdShow As Long _
)As Long

#endif
