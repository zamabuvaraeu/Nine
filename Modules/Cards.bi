#ifndef CARDS_BI
#define CARDS_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"

Extern "Windows-MS"

Declare Function cdtInit Alias "cdtInit"( _
	ByVal Width As Integer Ptr, _
	ByVal Height As Integer Ptr _
)As Integer

Declare Function cdtDrawExt Alias "cdtDrawExt"( _
	ByVal hDC As HDC, _
	ByVal X As Integer, _
	ByVal Y As Integer, _
	ByVal dX As Integer, _
	ByVal dY As Integer, _
	ByVal Card As Integer, _
	ByVal Suit As Integer, _
	ByVal Color As DWORD _
)As Integer

Declare Sub cdtTerm Alias "cdtTerm"()

End Extern

' Ширина и высота карты
Common Shared DefautlCardWidth As Integer
Common Shared DefautlCardHeight As Integer

Public Enum Backs
	Crosshatch = 53
	Sky = 54
	Mineral = 55
	Fish = 56
	Frog = 57
	Flower = 58
	Island = 59
	Squares = 60
	Magenta = 61
	Sanddunes = 62
	Spaces = 63
	Lines = 64
	Cars = 65
	Unused = 66
	X = 67
	O = 68
End Enum

Public Enum Faces
	Ace = 0
	Two = 1
	Three = 2
	Four = 3
	Five = 4
	Six = 5
	Seven = 6
	Eight = 7
	Nine = 8
	Ten = 9
	Jack = 10
	Queen = 11
	King = 12
End Enum

Public Enum Suits
	Clubs = 0
	Diamond = 1
	Hearts = 2
	Spades = 3
End Enum

Public Enum CardViews
	Normal = 0
	Back = 1
	Invert = 2
End Enum

Declare Function CardNumberToString( _
	ByVal CardNumber As Integer, _
	ByVal pValue As WString Ptr _
)As Integer

#endif
