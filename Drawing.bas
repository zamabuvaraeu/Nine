#include once "Drawing.bi"
#include once "Cards.bi"
#include once "IntegerToWString.bi"

Sub GetMoneyString(ByVal buffer As WString Ptr, ByVal MoneyValue As Integer, ByVal CharacterName As WString Ptr)
	' TODO Консертирование валюты в соответствии с текущими языковыми параметрами
	Dim bufferMoney As WString * 256 = Any
	itow(MoneyValue, @bufferMoney, 10)
	
	lstrcpy(buffer, CharacterName)
	lstrcat(Buffer, ": ")
	
	lstrcat(buffer, bufferMoney)
	' lstrcat(buffer, " ")
	
	' lstrcat(buffer, CurrencyChar)
End Sub

Sub DrawCharacterCard(ByVal hDC As HDC, ByVal X As Integer, ByVal Y As Integer, ByVal pPlayerCard As PlayerCard Ptr, ByVal Character As Characters)
	If pPlayerCard->IsUsed Then
		If Character = Characters.Player Then
			' Для игрока нарисовать лицевую сторону
			cdtDrawExt(hDC, X, Y, DefautlCardWidth, DefautlCardHeight, pPlayerCard->CardNumber, CardViews.Normal, 0)
		Else
			' Для врагов нарисовать рубашку
			cdtDrawExt(hDC, X, Y, DefautlCardWidth, DefautlCardHeight, Backs.Sky, CardViews.Back, 0)
		End If
	End If
End Sub

Sub DrawCharacterPack(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal pPlayerCard As PlayerCard Ptr, ByVal Character As Characters)
	Rectangle(hDCMem, 0, 0, pPlayerCard[11].X - pPlayerCard[0].X + DefautlCardWidth, pPlayerCard[11].Y - pPlayerCard[0].Y + DefautlCardHeight)
	
	For i As Integer = 0 To 11
		DrawCharacterCard(hDCMem, pPlayerCard[i].X - pPlayerCard[0].X, pPlayerCard[i].Y - pPlayerCard[0].Y, @pPlayerCard[i], Character)
	Next
	
	BitBlt(hDC, _
		pPlayerCard[0].X, _
		pPlayerCard[0].Y, _
		pPlayerCard[11].X - pPlayerCard[0].X + DefautlCardWidth, _
		pPlayerCard[11].Y - pPlayerCard[0].Y + DefautlCardHeight, _
		hDCMem, 0, 0, SRCCOPY)
End Sub

Sub DrawBankPack(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal GameIsRunning As Boolean, ByVal BankDeck As PlayerCard Ptr)
	Rectangle(hDCMem, 0, 0, BankDeck[35].X - BankDeck[0].X + DefautlCardWidth, BankDeck[35].Y - BankDeck[0].Y + DefautlCardHeight)
	
	For i As Integer = 0 To 35
		If GameIsRunning Then
			' Нарисовать только те, что лежат на рабочем столе
			If BankDeck[i].IsUsed Then
				cdtDrawExt(hDCMem, BankDeck[i].X - BankDeck[0].X, BankDeck[i].Y - BankDeck[0].Y, DefautlCardWidth, DefautlCardHeight, BankDeck[i].CardNumber, CardViews.Normal, 0)
			End If
		Else
			' Нарисовать все карты
			cdtDrawExt(hDCMem, BankDeck[i].X - BankDeck[0].X, BankDeck[i].Y - BankDeck[0].Y, DefautlCardWidth, DefautlCardHeight, BankDeck[i].CardNumber, CardViews.Normal, 0)
		End If
	Next
	
	BitBlt(hDC, _
		BankDeck[0].X, _
		BankDeck[0].Y, _
		BankDeck[35].X - BankDeck[0].X + DefautlCardWidth, _
		BankDeck[35].Y - BankDeck[0].Y + DefautlCardHeight, _
		hDCMem, 0, 0, SRCCOPY)
End Sub

Sub DrawMoney(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal CharacterMoney As Money Ptr)
	Dim buffer As WString * (Money.MaxCharacterNameLength * 2 + 1) = Any
	GetMoneyString(@buffer, CharacterMoney->Value, @CharacterMoney->CharacterName)
	
	Dim MoneyTextSize As SIZE = Any
	GetTextExtentPoint32(hDCMem, @buffer, lstrlen(@buffer), @MoneyTextSize)
	
	Rectangle(hDCMem, 0, 0, MoneyTextSize.cx, MoneyTextSize.cy)
	
	TextOut(hDCMem, 0, 0, @buffer, lstrlen(@buffer))
	
	BitBlt(hDC, _
		CharacterMoney->X, _
		CharacterMoney->Y, _
		MoneyTextSize.cx, _
		MoneyTextSize.cy, _
		hDCMem, 0, 0, SRCCOPY)
End Sub

Sub DrawUpArrow(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal X As Integer, ByVal Y As Integer)
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
