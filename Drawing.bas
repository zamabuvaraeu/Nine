#include once "Drawing.bi"
#include once "Cards.bi"
#include once "IntegerToWString.bi"

Sub GetMoneyString( _
		ByVal buffer As WString Ptr, _
		ByVal MoneyValue As Integer, _
		ByVal CharacterName As WString Ptr _
	)
	' TODO Отображать валюту по текущим языковым стандартам
	Dim bufferMoney As WString * 256 = Any
	itow(MoneyValue, @bufferMoney, 10)
	
	lstrcpy(buffer, CharacterName)
	lstrcat(Buffer, ": ")
	
	lstrcat(buffer, bufferMoney)
	' lstrcat(buffer, " ")
	
	' lstrcat(buffer, CurrencyChar)
End Sub

Sub DrawCard( _
		ByVal hDC As HDC, _
		ByVal hDCMem As HDC, _
		ByVal X As Integer, _
		ByVal Y As Integer, _
		ByVal CardNumber As Integer _
	)
	cdtDrawExt(hDCMem, 0, 0, DefautlCardWidth, DefautlCardHeight, CardNumber, CardViews.Normal, 0)
	BitBlt(hDC, _
		X, _
		Y, _
		DefautlCardWidth, _
		DefautlCardHeight, _
		hDCMem, 0, 0, SRCCOPY)
End Sub

Sub DrawCharacterCard( _
		ByVal hDC As HDC, _
		ByVal pPlayerCard As PlayerCard Ptr, _
		ByVal Character As Characters _
	)
	If pPlayerCard->IsUsed Then
		' Для игрока нарисовать лицевую сторону
		' Для врагов нарисовать рубашку
		If Character = Characters.Player Then
			cdtDrawExt(hDC, pPlayerCard->X, pPlayerCard->Y, DefautlCardWidth, DefautlCardHeight, pPlayerCard->CardNumber, CardViews.Normal, 0)
		Else
			cdtDrawExt(hDC, pPlayerCard->X, pPlayerCard->Y, DefautlCardWidth, DefautlCardHeight, Backs.Sky, CardViews.Back, 0)
		End If
	End If
End Sub

Sub EraseCard( _
		ByVal hDC As HDC, _
		ByVal hDCMem As HDC, _
		ByVal pPlayerCard As PlayerCard Ptr _
	)
	Rectangle(hDCMem, pPlayerCard->X, pPlayerCard->Y, pPlayerCard->X + DefautlCardWidth, pPlayerCard->Y + DefautlCardHeight)
	
	BitBlt(hDC, _
		pPlayerCard->X, _
		pPlayerCard->Y, _
		DefautlCardWidth, _
		DefautlCardHeight, _
		hDCMem, pPlayerCard->X, pPlayerCard->Y, SRCCOPY)
End Sub

Sub DrawBankCard( _
		ByVal hDC As HDC, _
		ByVal pBankCard As PlayerCard Ptr, _
		ByVal GameIsRunning As Boolean _
	)
	If GameIsRunning Then
		' Нарисовать только те, что лежат на рабочем столе
		If pBankCard->IsUsed Then
			cdtDrawExt(hDC, pBankCard->X, pBankCard->Y, DefautlCardWidth, DefautlCardHeight, pBankCard->CardNumber, CardViews.Normal, 0)
		End If
	Else
		' Нарисовать все карты
		cdtDrawExt(hDC, pBankCard->X, pBankCard->Y, DefautlCardWidth, DefautlCardHeight, pBankCard->CardNumber, CardViews.Normal, 0)
	End If
End Sub

Sub DrawCharacterPack( _
		ByVal hDC As HDC, _
		ByVal pPlayerCard As PlayerCard Ptr, _
		ByVal Character As Characters _
	)
	For i As Integer = 0 To 11
		If pPlayerCard[i].IsUsed Then
			If Character = Characters.Player Then
				' Для игрока нарисовать лицевую сторону
				cdtDrawExt(hDC, pPlayerCard[i].X, pPlayerCard[i].Y, DefautlCardWidth, DefautlCardHeight, pPlayerCard[i].CardNumber, CardViews.Normal, 0)
			Else
				' Для врагов нарисовать рубашку
				cdtDrawExt(hDC, pPlayerCard[i].X, pPlayerCard[i].Y, DefautlCardWidth, DefautlCardHeight, Backs.Sky, CardViews.Back, 0)
			End If
		End If
	Next
End Sub

Sub DrawBankPack( _
		ByVal hDC As HDC, _
		ByVal GameIsRunning As Boolean, _
		ByVal BankDeck As PlayerCard Ptr _
	)
	For i As Integer = 0 To 35
		If GameIsRunning Then
			' Нарисовать только те, что лежат на рабочем столе
			If BankDeck[i].IsUsed Then
				cdtDrawExt(hDC, BankDeck[i].X, BankDeck[i].Y, DefautlCardWidth, DefautlCardHeight, BankDeck[i].CardNumber, CardViews.Normal, 0)
			End If
		Else
			' Нарисовать все карты
			cdtDrawExt(hDC, BankDeck[i].X, BankDeck[i].Y, DefautlCardWidth, DefautlCardHeight, BankDeck[i].CardNumber, CardViews.Normal, 0)
		End If
	Next
End Sub

Sub DrawUpArrow( _
		ByVal hDC As HDC, _
		ByVal hDCMem As HDC, _
		ByVal X As Integer, _
		ByVal Y As Integer _
	)
	Const UpArrow = "↑"
	
	Dim UpArrowTextSize As SIZE = Any
	GetTextExtentPoint32(hDCMem, @UpArrow, lstrlen(@UpArrow), @UpArrowTextSize)
	
	' Стереть
	Rectangle(hDCMem, 0, 0, UpArrowTextSize.cx, UpArrowTextSize.cy)
	
	TextOut(hDCMem, 0, 0, @UpArrow, lstrlen(@UpArrow))
	
	BitBlt(hDC, _
		X, _
		Y, _
		UpArrowTextSize.cx, _
		UpArrowTextSize.cy, _
		hDCMem, 0, 0, SRCCOPY)
End Sub
