#include "Cards.bi"

Function CardNumberToString( _
		ByVal CardNumber As Integer, _
		ByVal pValue As WString Ptr _
	)As Integer
	
	Select Case CardNumber \ 4
		
		Case Faces.Ace
			lstrcpy(pValue, "A")
			
		Case Faces.Two
			lstrcpy(pValue, "2")
			
		Case Faces.Three
			lstrcpy(pValue, "3")
			
		Case Faces.Four
			lstrcpy(pValue, "4")
			
		Case Faces.Five
			lstrcpy(pValue, "5")
			
		Case Faces.Six
			lstrcpy(pValue, "6")
			
		Case Faces.Seven
			lstrcpy(pValue, "7")
			
		Case Faces.Eight
			lstrcpy(pValue, "8")
			
		Case Faces.Nine
			lstrcpy(pValue, "9")
			
		Case Faces.Ten
			lstrcpy(pValue, "10")
			
		Case Faces.Jack
			lstrcpy(pValue, "J")
			
		Case Faces.Queen
			lstrcpy(pValue, "Q")
			
		Case Faces.King
			lstrcpy(pValue, "K")
			
	End Select
	
	Select Case CardNumber Mod 4
		
		Case Suits.Clubs
			lstrcat(pValue, "♣")
			
		Case Suits.Diamond
			lstrcat(pValue, "♦")
			
		Case Suits.Hearts
			lstrcat(pValue, "♥")
			
		Case Suits.Spades
			lstrcat(pValue, "♠")
			
	End Select
	
	Return 0
	
End Function
