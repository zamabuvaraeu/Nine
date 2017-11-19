#include once "Drawing.bi"
#include once "Cards.bi"
#include once "IntegerToWString.bi"

Sub GetMoneyString(ByVal buffer As WString Ptr, ByVal Value As Integer, ByVal CharacterName As WString Ptr)
	' TODO Консертирование валюты в соответствии с текущими языковыми параметрами
	Dim bufferMoney As WString * 256 = Any
	itow(Value, @bufferMoney, 10)
	
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
	Rectangle(hDCMem, 0, 0, BankDeck[35].X + DefautlCardWidth, BankDeck[35].Y + DefautlCardHeight)
	
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
		DefautlCardWidth * 9, _
		DefautlCardHeight * 4, _
		hDCMem, 0, 0, SRCCOPY)
End Sub

Sub DrawMoney(ByVal hDC As HDC, ByVal OldValue As Integer, ByVal NewValue As Integer, ByVal X As Integer, ByVal Y As Integer, ByVal CharacterName As WString Ptr)
End Sub

/'
Sub DrawMoney(ByVal hDC As HDC, ByVal OldRightEnemyMoney As Integer,  ByVal OldPlayerMoney As Integer, ByVal OldLeftEnemyMoney As Integer, ByVal OldBankMoney As Integer)
	' Шрифт
	Dim oldFont As HFONT = SelectObject(hDC, DefaultFont)
	Dim oldColor As Integer = SetTextColor(hDC, ForeColor)
	Dim BkMode As Integer = SetBkMode(hDC, TRANSPARENT)
	Dim OldPen As HPEN = SelectObject(hDC, BackColorPen)
	Dim OldBrush As HBRUSH = SelectObject(hDC, BackColorBrush)
	
	' Деньги игрока, соперников и банка
	
	Dim buffer As WString * 256 = Any
	
	Scope
		GetMoneyString(buffer, OldRightEnemyMoney, @RightEnemyName)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, RightEnemyMoney.X, RightEnemyMoney.Y, RightEnemyMoney.X + MoneyTextSize.cx, RightEnemyMoney.Y + MoneyTextSize.cy)
		
		GetMoneyString(buffer, RightEnemyMoney.Value, @RightEnemyName)
		
		TextOut(hDC, RightEnemyMoney.X, RightEnemyMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		GetMoneyString(buffer, OldPlayerMoney, @PlayerName)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, PlayerMoney.X, PlayerMoney.Y, PlayerMoney.X + MoneyTextSize.cx, PlayerMoney.Y + MoneyTextSize.cy)
		
		GetMoneyString(buffer, PlayerMoney.Value, @PlayerName)
		
		TextOut(hDC, PlayerMoney.X, PlayerMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		GetMoneyString(buffer, OldLeftEnemyMoney, @LeftRightEnemyName)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, LeftEnemyMoney.X, LeftEnemyMoney.Y, LeftEnemyMoney.X + MoneyTextSize.cx, LeftEnemyMoney.Y + MoneyTextSize.cy)
		
		GetMoneyString(buffer, LeftEnemyMoney.Value, @LeftRightEnemyName)
		
		TextOut(hDC, LeftEnemyMoney.X, LeftEnemyMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		GetMoneyString(buffer, OldBankMoney, @BankName)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, BankMoney.X, BankMoney.Y, BankMoney.X + MoneyTextSize.cx, BankMoney.Y + MoneyTextSize.cy)
		
		GetMoneyString(buffer, BankMoney.Value, @BankName)
		
		TextOut(hDC, BankMoney.X, BankMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	' Очистка
	SelectObject(hDC, OldBrush)
	SelectObject(hDC, OldPen)
	SetBkMode(hDC, BkMode)
	SetTextColor(hDC, oldColor)
	SelectObject(hDC, oldFont)
End Sub
'/
/'
Sub DrawUpArrow(ByVal hDC As HDC, ByVal NewCardNumber As Integer)
	Const UpArrow = "↑"
	' Шрифт
	Dim oldFont As HFONT = SelectObject(hDC, DoubleFont)
	Dim oldColor As Integer = SetTextColor(hDC, ForeColor)
	Dim BkMode As Integer = SetBkMode(hDC, TRANSPARENT)
	Dim OldPen As HPEN = SelectObject(hDC, BackColorPen)
	Dim OldBrush As HBRUSH = SelectObject(hDC, BackColorBrush)
	
	' Стереть старое изображение стрелки
	Rectangle(hDC, PlayerDeck(0).X, PlayerDeck(0).Y + DefautlCardHeight, PlayerDeck(11).X + DefautlCardWidth, PlayerDeck(11).Y + 2 * DefautlCardHeight)
	
	' Нарисовать стрелку по координанам карт игрока
	TextOut(hDC, PlayerDeck(NewCardNumber).X + DefautlCardWidth \ 2, PlayerDeck(NewCardNumber).Y + DefautlCardHeight + 5, @UpArrow, lstrlen(@UpArrow))
	
	' Очистка
	SelectObject(hDC, OldBrush)
	SelectObject(hDC, OldPen)
	SetBkMode(hDC, BkMode)
	SetTextColor(hDC, oldColor)
	SelectObject(hDC, oldFont)
End Sub
'/