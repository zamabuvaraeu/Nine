#include once "MainForm.bi"
#include once "Drawing.bi"
#include once "Cards.bi"
#include once "MainFormEvents.bi"
#include once "PlayerCard.bi"
#include once "Nine.rh"
#include once "IntegerToWString.bi"
#include once "ThreadProc.bi"
#include once "Irc.bi"
#include once "IrcEvents.bi"
#include once "IrcReplies.bi"
#include once "NetworkParamDialogProc.bi"
#include once "AboutDialogProc.bi"
#include once "GdiGraphics.bi"

' Режим игры
Enum GameModes
	' Игра остановлена
	Stopped
	' Игра с самим собой
	Normal
	' Игра с компьютером
	AI
	' Игра по сети
	Online
End Enum

Const DefaultBackColor As Integer = &h006400
Const DefaultForeColor As Integer = &hFFF8F0

' Начальные сумы денег у игроков
Const DefaultMoney As Integer = 20
' Количество денег, которое кладётся в банк в начале игры
Const ZZZMoney As Integer = 2
' Количество денег, которое кладётся в банк если у игрока нет карт для хода
Const FFFMoney As Integer = 1

' Количество частей в траектории анимации карты
Const DealCardAnimationPartsCount As Integer = 32

' Количество миллисекунд таймера
Const DealCardTimerElapsedTime As Integer = 25
Const DealPackTimerElapsedTime As Integer = 25

Dim Shared CurrencyChar As WString * 16

Dim Shared CharacterDealCardAnimationEnabled As Boolean
Dim Shared BankDealPackAnimationEndbled As Boolean

' Массив точек для анимации карты игрока
Dim Shared PlayerDealCardAnimationPointStart As Point
Dim Shared PlayerDealCardAnimationCardSortNumber As Integer
Dim Shared PlayerDealCardAnimationCardIncrementX As Integer
Dim Shared PlayerDealCardAnimationCardIncrementY As Integer
Dim Shared PlayerDealCardAnimationPointStartCount As Integer

' Номер карты для анимации раздачи колоды
Dim Shared BankDealPackAnimationCardNumber As Integer

' Игра идёт
Dim Shared GameMode As GameModes

' Рисование

Dim Shared MemoryGraphics As GdiGraphics
Dim Shared AnimationGraphics As GdiGraphics
Dim Shared RealGraphics As GdiGraphics

Dim Shared BackColorBrush As HBRUSH
Dim Shared BackColorPen As HPEN
Dim Shared DefaultFont As HFONT

' Колода
Dim Shared BankDeck(35) As PlayerCard
' Карты
Dim Shared PlayerDeck(11) As PlayerCard
Dim Shared LeftEnemyDeck(11) As PlayerCard
Dim Shared RightEnemyDeck(11) As PlayerCard
' Деньги
Dim Shared RightEnemyMoney As Money
Dim Shared PlayerMoney As Money
Dim Shared LeftEnemyMoney As Money
Dim Shared BankMoney As Money

Dim Shared HwndStaticRightEnemy As HWND
Dim Shared HwndStaticPlayer As HWND
Dim Shared HwndStaticLeftEnemy As HWND
Dim Shared HwndStaticBank As HWND


' Игрок может щёлкать по своим картам
Dim Shared PlayerCanPlay As Boolean
' Указатель на индекс карты для ввода с клавиатуры
Dim Shared PlayerKeyboardCardNumber As Integer


Function IncrementX(ByVal X As Integer)As Integer
	' Если координата X больше, то увеличить
	If X > PlayerDealCardAnimationPointStart.X Then
		Return PlayerDealCardAnimationCardIncrementX
	Else
		' Иначе уменьшить
		Return -1 * PlayerDealCardAnimationCardIncrementX
	End If
End Function

Function IncrementY(ByVal Y As Integer)As Integer
	' Если коордитата Y больше, то уменьшить
	If Y > PlayerDealCardAnimationPointStart.Y Then
		Return PlayerDealCardAnimationCardIncrementY
	Else
		' Иначе увеличить
		Return -1 * PlayerDealCardAnimationCardIncrementY
	End If
End Function

Sub RightEnemyDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	RightEnemyDeck(CardNumber).IsUsed = False
	' Сделать карту видимой на поле
	BankDeck(RightEnemyDeck(CardNumber).CardSortNumber).IsUsed = True
	
	' Начальная и конечная точки
	PlayerDealCardAnimationCardSortNumber = RightEnemyDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - RightEnemyDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - RightEnemyDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	
	PlayerDealCardAnimationPointStart.X = RightEnemyDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = RightEnemyDeck(CardNumber).Y
	
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterPack(hDC, @RightEnemyDeck(0), Characters.RightCharacter)
		
		BitBlt(AnimationGraphics.DeviceContext, _
			0, _
			0, _
			GetDeviceCaps(hDC, HORZRES), _
			GetDeviceCaps(hDC, VERTRES), _
			hDC, 0, 0, SRCCOPY)
		
		ReleaseDC(hWin, hDC)
	End Scope
	
	SetTimer(hWin, MainFormTimers.RightEnemyDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Sub UserDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	PlayerDeck(CardNumber).IsUsed = False
	' Сделать карту видимой на поле
	BankDeck(PlayerDeck(CardNumber).CardSortNumber).IsUsed = True
	
	' Начальная и конечная точки
	PlayerDealCardAnimationCardSortNumber = PlayerDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	
	PlayerDealCardAnimationPointStart.X = PlayerDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = PlayerDeck(CardNumber).Y
	
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		EraseCard(hDC, AnimationGraphics.DeviceContext, @PlayerDeck(CardNumber))
		
		BitBlt(AnimationGraphics.DeviceContext, _
			0, _
			0, _
			GetDeviceCaps(hDC, HORZRES), _
			GetDeviceCaps(hDC, VERTRES), _
			hDC, 0, 0, SRCCOPY)
		
		ReleaseDC(hWin, hDC)
	End Scope
	
	SetTimer(hWin, MainFormTimers.PlayerDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Sub LeftEnemyDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	LeftEnemyDeck(CardNumber).IsUsed = False
	' Сделать карту видимой на поле
	BankDeck(LeftEnemyDeck(CardNumber).CardSortNumber).IsUsed = True
	
	' Начальная карта
	PlayerDealCardAnimationCardSortNumber = LeftEnemyDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - LeftEnemyDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - LeftEnemyDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	' Начальная точка
	PlayerDealCardAnimationPointStart.X = LeftEnemyDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = LeftEnemyDeck(CardNumber).Y
	
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterPack(hDC, @LeftEnemyDeck(0), Characters.LeftCharacter)
		
		BitBlt(AnimationGraphics.DeviceContext, _
			0, _
			0, _
			GetDeviceCaps(hDC, HORZRES), _
			GetDeviceCaps(hDC, VERTRES), _
			hDC, 0, 0, SRCCOPY)
		
		ReleaseDC(hWin, hDC)
	End Scope
	
	SetTimer(hWin, MainFormTimers.LeftEnemyDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Function AnimateCard(ByVal hWin As HWND)As Boolean
	' Анимация передвижения карты
	Dim hDC As HDC = GetDC(hWin)
	
	If CharacterDealCardAnimationEnabled = False Then
		DrawBankCard(hDC, @BankDeck(PlayerDealCardAnimationCardSortNumber), True)
		Return True
	End If
	
	Select Case PlayerDealCardAnimationPointStartCount
		Case 0
			' Из оригинальной рабочей области во временный буфер
			BitBlt(MemoryGraphics.DeviceContext, _
				0, _
				0, _
				GetDeviceCaps(AnimationGraphics.DeviceContext, HORZRES), _
				GetDeviceCaps(AnimationGraphics.DeviceContext, VERTRES), _
				AnimationGraphics.DeviceContext, 0, 0, SRCCOPY)
			
			' Увеличить координаты X и Y
			PlayerDealCardAnimationPointStart.X += IncrementX(BankDeck(PlayerDealCardAnimationCardSortNumber).X)
			PlayerDealCardAnimationPointStart.Y += IncrementY(BankDeck(PlayerDealCardAnimationCardSortNumber).Y)
			
			' Нарисовать карту во временном буфере
			cdtDrawExt(MemoryGraphics.DeviceContext, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, DefautlCardWidth, DefautlCardHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
			
			' Нарисовать из временного буфера в рабочую область
			BitBlt(hDC, _
				0, _
				0, _
				GetDeviceCaps(MemoryGraphics.DeviceContext, HORZRES), _
				GetDeviceCaps(MemoryGraphics.DeviceContext, VERTRES), _
				MemoryGraphics.DeviceContext, 0, 0, SRCCOPY)
			
			Dim dx As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDealCardAnimationPointStart.X)
			Dim dy As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDealCardAnimationPointStart.Y)
			
			If dx < Abs(PlayerDealCardAnimationCardIncrementX) OrElse dy < Abs(PlayerDealCardAnimationCardIncrementY) Then
				' Как только будет достигнута последняя точка, то остановить таймер
				PlayerDealCardAnimationPointStartCount = 1
			End If
			
			AnimateCard = False
		Case 1
			PlayerDealCardAnimationPointStartCount = 0
			
			' Восстановить оригинальную рабочую область
			BitBlt(hDC, _
				0, _
				0, _
				GetDeviceCaps(AnimationGraphics.DeviceContext, HORZRES), _
				GetDeviceCaps(AnimationGraphics.DeviceContext, VERTRES), _
				AnimationGraphics.DeviceContext, 0, 0, SRCCOPY)
			
			' Нарисовать карту в конечной точке
			cdtDrawExt(hDC, BankDeck(PlayerDealCardAnimationCardSortNumber).X, BankDeck(PlayerDealCardAnimationCardSortNumber).Y, DefautlCardWidth, DefautlCardHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
			
			AnimateCard = True
	End Select
	ReleaseDC(hWin, hDC)
End Function

Sub UpdateMoney(ByVal hwndStaticControl As HWND, ByVal cm As Money Ptr, ByVal NewValue As Integer)
	Dim buffer As WString * (Money.MaxCharacterNameLength * 2 + 1) = Any
	GetMoneyString(@buffer, NewValue, @cm->CharacterName)
	
	Dim MoneyTextSize As SIZE = Any
	GetTextExtentPoint32(MemoryGraphics.DeviceContext, @buffer, lstrlen(@buffer), @MoneyTextSize)
	
	cm->Value = NewValue
	
	MoveWindow(hwndStaticControl, cm->X, cm->Y, MoneyTextSize.cx, MoneyTextSize.cy, 0)
	SendMessage(hwndStaticControl, WM_SETTEXT, 0, Cast(LPARAM, @buffer))
End Sub


Sub MainFormMenuNewGame_Click(ByVal hWin As HWND)
	If GameMode = GameModes.Normal OrElse GameMode = GameModes.Online Then
		Dim WarningMsg As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_NEWGAMEWARNING, @WarningMsg, 1024 - 1)
		Dim MessageBoxTitle As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
		If MessageBox(hWin, @WarningMsg, @MessageBoxTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2) <> IDYES Then
			Exit Sub
		End If
	End If
	GameMode = GameModes.Normal
	PostMessage(hWin, PM_NEWGAME, 0, 0)
End Sub

Sub MainFormMenuNewAIGame_Click(ByVal hWin As HWND)
	If GameMode = GameModes.Normal OrElse GameMode = GameModes.Online Then
		Dim WarningMsg As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_NEWGAMEWARNING, @WarningMsg, 1024 - 1)
		Dim MessageBoxTitle As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
		If MessageBox(hWin, @WarningMsg, @MessageBoxTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2) <> IDYES Then
			Exit Sub
		End If
	End If
	GameMode = GameModes.AI
	PostMessage(hWin, PM_NEWGAME, 0, 0)
End Sub

Sub MainFormMenuNewNetworkGame_Click(ByVal hWin As HWND)
	' TODO Сделать сетевой режим
	If GameMode = GameModes.Normal OrElse GameMode = GameModes.Online Then
		Dim WarningMsg As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_NEWGAMEWARNING, @WarningMsg, 1024 - 1)
		Dim MessageBoxTitle As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
		If MessageBox(hWin, @WarningMsg, @MessageBoxTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2) <> IDYES Then
			Exit Sub
		End If
	End If
	If DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DLG_NETWORK), hWin, @NetworkParamDialogProc, 0) <> IDOK Then
		Exit Sub
	End If
End Sub

Sub MainFormMenuFileExit_Click(ByVal hWin As HWND)
	DestroyWindow(hWin)
End Sub

Sub MainFormMenuHelpContents_Click(ByVal hWin As HWND)
	Dim NineWindowTitle As WString * (511 + 1) = Any
	LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @NineWindowTitle, 511)
	
	Dim HelpMessage As WString * (511 + 1) = Any
	LoadString(GetModuleHandle(0), IDS_NOTIMPLEMENTED, @HelpMessage, 511)
	
	MessageBox(hWin, @HelpMessage, @NineWindowTitle, MB_OK + MB_ICONINFORMATION)
End Sub

Sub MainFormMenuHelpAbout_Click(ByVal hWin As HWND)
	' Dim MessageBoxTitle As WString * 1024 = Any
	' LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
	' ShellAbout(hWin, @MessageBoxTitle, "Девятка", LoadIcon(GetModuleHandle(0), Cast(WString Ptr, IDR_ICON)))
	DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DLG_ABOUT), hWin, @AboutDialogProc, 0)
End Sub


Sub MainForm_Load(ByVal hWin As HWND, ByVal wParam As WPARAM, ByVal lParam As LPARAM)
	' Ники игроков
	LoadString(GetModuleHandle(0), IDS_RIGHTENEMYNICK, @RightEnemyMoney.CharacterName, Money.MaxCharacterNameLength)
	LoadString(GetModuleHandle(0), IDS_USERNICK, @PlayerMoney.CharacterName, Money.MaxCharacterNameLength)
	LoadString(GetModuleHandle(0), IDS_LEFTENEMYNICK, @LeftEnemyMoney.CharacterName, Money.MaxCharacterNameLength)
	LoadString(GetModuleHandle(0), IDS_BANKNICK, @BankMoney.CharacterName, Money.MaxCharacterNameLength)
	LoadString(GetModuleHandle(0), IDS_CURRENCYCHAR, @CurrencyChar, 8)
	
	' Инициализация случайных чисел
	Dim dtNow As SYSTEMTIME = Any
	GetSystemTime(@dtNow)
	srand(dtNow.wMilliseconds - dtNow.wSecond + dtNow.wMinute + dtNow.wHour)
	
	' Инициализация библиотеки
	cdtInit(@DefautlCardWidth, @DefautlCardHeight)
	
	' Размеры карт
	For i As Integer = 0 To 35
		' Карта лежит на рабочем столе
		BankDeck(i).IsUsed = True
		BankDeck(i).CardNumber = GetCardNumber(i)
		BankDeck(i).CardSortNumber = i
	Next
	
	BackColorBrush = CreateSolidBrush(DefaultBackColor)
	BackColorPen = CreatePen(PS_SOLID, 1, DefaultBackColor)
	
	Scope
		Dim hDefaultFont As HFONT = GetStockObject(DEFAULT_GUI_FONT)
		Dim oFont As LOGFONT = Any
		GetObject(hDefaultFont, SizeOf(LOGFONT), @oFont)
		oFont.lfHeight *= 4
		DefaultFont = CreateFontIndirect(@oFont)
	End Scope
	
	InitializeGraphics(@AnimationGraphics, hWin, BackColorPen, BackColorBrush, DefaultFont)
	InitializeGraphics(@MemoryGraphics, hWin, BackColorPen, BackColorBrush, DefaultFont)
	InitializeGraphics(@RealGraphics, hWin, BackColorPen, BackColorBrush, DefaultFont)
	
	BankDealPackAnimationEndbled = True
	CharacterDealCardAnimationEnabled = True
	
	HwndStaticRightEnemy = CreateWindow( _
		"STATIC", "Девятка", _
		WS_CHILD Or WS_VISIBLE Or SS_LEFTNOWORDWRAP, _
		10, 10, 40, 20, _
		hWin, NULL, NULL, NULL _
	)
	SendMessage(HwndStaticRightEnemy, WM_SETFONT, Cast(WPARAM, DefaultFont), 0)
	
	HwndStaticPlayer = CreateWindow( _
		"STATIC", "Девятка", _
		WS_CHILD Or WS_VISIBLE Or SS_LEFTNOWORDWRAP, _
		10, 10, 40, 20, _
		hWin, NULL, NULL, NULL _
	)
	SendMessage(HwndStaticPlayer, WM_SETFONT, Cast(WPARAM, DefaultFont), 0)
	
	HwndStaticLeftEnemy = CreateWindow( _
		"STATIC", "Девятка", _
		WS_CHILD Or WS_VISIBLE Or SS_LEFTNOWORDWRAP, _
		10, 10, 40, 20, _
		hWin, NULL, NULL, NULL _
	)
	SendMessage(HwndStaticLeftEnemy, WM_SETFONT, Cast(WPARAM, DefaultFont), 0)
	
	HwndStaticBank = CreateWindow( _
		"STATIC", "Девятка", _
		WS_CHILD Or WS_VISIBLE Or SS_LEFTNOWORDWRAP, _
		10, 10, 40, 20, _
		hWin, NULL, NULL, NULL _
	)
	SendMessage(HwndStaticBank, WM_SETFONT, Cast(WPARAM, DefaultFont), 0)
	
End Sub

Sub MainForm_UnLoad(ByVal hWin As HWND)
	UnInitializeGraphics(@RealGraphics)
	UnInitializeGraphics(@MemoryGraphics)
	UnInitializeGraphics(@AnimationGraphics)
	
	DeleteObject(DefaultFont)
	DeleteObject(BackColorPen)
	DeleteObject(BackColorBrush)
	
	cdtTerm()
End Sub

Sub MainForm_LeftMouseDown(ByVal hWin As HWND, ByVal KeyModifier As Integer, ByVal X As Integer, ByVal Y As Integer)
	If PlayerCanPlay Then
		' Получить номер карты, на который щёлкнул пользователь
		Dim CardNumber As Integer = GetClickPlayerCardNumber(@PlayerDeck(0), X, Y)
		If CardNumber >= 0 Then
			' Проверить правильность хода пользователя
			If ValidatePlayerCardNumber(PlayerDeck(CardNumber).CardSortNumber, @BankDeck(0)) Then
				' Запретить ходить пользователю
				PlayerCanPlay = False
				' Ходить
				PostMessage(hWin, PM_USERATTACK, CardNumber, True)
			End If
		End If
	End If
End Sub

Sub MainForm_KeyDown(ByVal hWin As HWND, ByVal KeyCode As Integer)
	' Выбрать карту
	Select Case KeyCode
		Case VK_LEFT
			If PlayerCanPlay Then
				' Установить номер на ближайшую левую карту
				Dim tmpNumber As Integer = PlayerKeyboardCardNumber
				Do
					tmpNumber -= 1
					If tmpNumber < 0 Then
						tmpNumber = 11
					End If
					If PlayerDeck(tmpNumber).IsUsed Then
						Exit Do
					End If
				Loop While tmpNumber <> PlayerKeyboardCardNumber
				PlayerKeyboardCardNumber = tmpNumber
				' TODO Перерисовать стрелку‐указатель
				' Scope
					' Dim hDC As HDC = GetDC(hWin)
					' DrawUpArrow(hDC, PlayerKeyboardCardNumber)
					' ReleaseDC(hWin, hDC)
				' End Scope
			End If

		Case VK_RIGHT
			If PlayerCanPlay Then
				' Установить номер на ближайшую правую карту
				Dim tmpNumber As Integer = PlayerKeyboardCardNumber
				Do
					tmpNumber += 1
					If tmpNumber > 11 Then
						tmpNumber = 0
					End If
					If PlayerDeck(tmpNumber).IsUsed Then
						Exit Do
					End If
				Loop While tmpNumber <> PlayerKeyboardCardNumber
				PlayerKeyboardCardNumber = tmpNumber
				' TODO Перерисовать стрелку‐указатель
				' Scope
					' Dim hDC As HDC = GetDC(hWin)
					' DrawUpArrow(hDC, PlayerKeyboardCardNumber)
					' ReleaseDC(hWin, hDC)
				' End Scope
			End If
			
		Case VK_RETURN
			' Проверить правильность хода пользователя
			If PlayerCanPlay Then
				If ValidatePlayerCardNumber(PlayerDeck(PlayerKeyboardCardNumber).CardSortNumber, @BankDeck(0)) Then
					' Запретить ходить пользователю
					PlayerCanPlay = False
					' Ходить
					PostMessage(hWin, PM_USERATTACK, PlayerKeyboardCardNumber, True)
				End If
			End If
	End Select
End Sub

Sub MainForm_Paint(ByVal hWin As HWND)
	Dim UpdateRect As RECT = Any
	If GetUpdateRect(hWin, @UpdateRect, True) = 0 Then
		Exit Sub
	End If
	
	Dim pnt As PAINTSTRUCT = Any
	Dim hDC As HDC = BeginPaint(hWin, @pnt)
	
	BitBlt(hDC, _
		UpdateRect.left, _
		UpdateRect.top, _
		UpdateRect.right - UpdateRect.left, _
		UpdateRect.bottom - UpdateRect.top, _
		RealGraphics.DeviceContext, UpdateRect.left, UpdateRect.top, SRCCOPY _
	)
	
	EndPaint(hWin, @pnt)
End Sub

Sub MainForm_Resize(ByVal hWin As HWND, ByVal ResizingRequested As Integer, ByVal ClientWidth As Integer, ByVal ClientHeight As Integer)
	' TODO Адаптивный дизайн: масштабирование и распределение по всему окну
	
	' Центр клиентской области
	Dim cx As Integer = ClientWidth \ 2
	Dim cy As Integer = ClientHeight \ 2
	
	Scope
		' Карты банка
		' Смещение относительно центра клиентской области для центрирования карт
		Dim dx As Integer = cx - (DefautlCardWidth * 9) \ 2
		Dim dy As Integer = DefautlCardHeight
		
		For j As Integer = 0 To 3
			For i As Integer = 0 To 8
				Dim CardIndex As Integer = j * 9 + i
				BankDeck(CardIndex).X = i * DefautlCardWidth + dx
				BankDeck(CardIndex).Y = j * DefautlCardHeight + dy
			Next
		Next
		' Деньги банка
		BankMoney.X = cx - DefautlCardWidth
		BankMoney.Y = DefautlCardHeight \ 3
	End Scope
	
	Scope
		' Карты игрока
		Dim dxPlayer As Integer = cx - (DefautlCardWidth * 12) \ 2
		Dim dyPlayer As Integer = DefautlCardHeight * 6 - DefautlCardHeight \ 3
		For i As Integer = 0 To 11
			PlayerDeck(i).X = i * DefautlCardWidth + dxPlayer
			PlayerDeck(i).Y = dyPlayer
		Next
		' Деньги игрока
		PlayerMoney.X = cx - DefautlCardWidth
		PlayerMoney.Y = DefautlCardHeight * 6 - 3 * DefautlCardHeight \ 3
	End Scope
	
	Scope
		' Карты левого врага
		Dim dxEnemyLeft As Integer = cx - (DefautlCardWidth * 9) \ 2 - DefautlCardWidth - DefautlCardWidth \ 2
		Dim dyEnemyLeft As Integer = DefautlCardHeight - DefautlCardHeight \ 3
		For i As Integer = 0 To 11
			LeftEnemyDeck(i).X = dxEnemyLeft
			LeftEnemyDeck(i).Y = i * (DefautlCardHeight \ 3) + dyEnemyLeft
		Next
		' Деньги левого врага
		LeftEnemyMoney.X = dxEnemyLeft
		LeftEnemyMoney.Y = DefautlCardHeight \ 8
	End Scope
	
	Scope
		' Карты правого врага
		Dim dxEnemyRight As Integer = cx + (DefautlCardWidth * 9) \ 2 + DefautlCardWidth \ 2
		Dim dyEnemyRight As Integer = DefautlCardHeight - DefautlCardHeight \ 3
		For i As Integer = 0 To 11
			RightEnemyDeck(i).X = dxEnemyRight
			RightEnemyDeck(i).Y = i * (DefautlCardHeight \ 3) + dyEnemyRight
		Next
		' Деньги правого врага
		RightEnemyMoney.X = dxEnemyRight - DefautlCardWidth
		RightEnemyMoney.Y = DefautlCardHeight \ 8
	End Scope
	
	' Рисование
	Dim UpdateRect As RECT = Any
	SetRect(@UpdateRect, 0, 0, ClientWidth, ClientHeight)
	FillRect(RealGraphics.DeviceContext, @UpdateRect, BackColorBrush)
	
	' Карты игрока и врагов
	If GameMode <> GameModes.Stopped Then
	' Rectangle(hDCMem, pPlayerCard[0].X, pPlayerCard[0].Y, pPlayerCard[11].X + DefautlCardWidth, pPlayerCard[11].Y + DefautlCardHeight)
		DrawCharacterPack(RealGraphics.DeviceContext, @RightEnemyDeck(0), Characters.RightCharacter)
		DrawCharacterPack(RealGraphics.DeviceContext, @PlayerDeck(0), Characters.Player)
		DrawCharacterPack(RealGraphics.DeviceContext, @LeftEnemyDeck(0), Characters.LeftCharacter)
	End If
	
	DrawBankPack(RealGraphics.DeviceContext, GameMode <> GameModes.Stopped, @BankDeck(0))
	
	' Деньги
	UpdateMoney(HwndStaticRightEnemy , @RightEnemyMoney, RightEnemyMoney.Value)
	UpdateMoney(HwndStaticPlayer, @PlayerMoney, PlayerMoney.Value)
	UpdateMoney(HwndStaticLeftEnemy , @LeftEnemyMoney, PlayerMoney.Value)
	UpdateMoney(HwndStaticBank, @BankMoney, BankMoney.Value)
	' Scope
		' Dim intColor As Integer = SetTextColor(RealGraphics.DeviceContext, DefaultForeColor)
		' Dim intBkMode As Integer = SetBkMode(RealGraphics.DeviceContext, TRANSPARENT)
		
		' DrawMoney(RealGraphics.DeviceContext, @RightEnemyMoney)
		' DrawMoney(RealGraphics.DeviceContext, @PlayerMoney)
		' DrawMoney(RealGraphics.DeviceContext, @LeftEnemyMoney)
		' DrawMoney(RealGraphics.DeviceContext, @BankMoney)
		
		' TODO Выяснить координаты стрелки
		' If PlayerCanPlay Then
			' DrawUpArrow(hDC, MemoryGraphics.DeviceContext, 0, 0)
		' End If
		
		' SetTextColor(RealGraphics.DeviceContext, intColor)
		' SetBkMode(RealGraphics.DeviceContext, intBkMode)
	' End Scope
End Sub

Sub MainForm_Close(ByVal hWin As HWND)
	' Пользователь пытается закрыть окно
	' Если игра уже идёт, то спросить
	DestroyWindow(hWin)
End Sub

Sub MainForm_StaticControlTextColor(ByVal hWin As HWND, ByVal hwndControl As HWND, ByVal hDC As HDC)
	SetTextColor(hDC, DefaultForeColor)
	SetBkColor(hDC, DefaultBackColor)
End Sub


Sub MainForm_NewGame(ByVal hWin As HWND)
	' Начинаем новую игру
	
	' Восстановление суммы денег
	UpdateMoney(HwndStaticRightEnemy , @RightEnemyMoney, DefaultMoney)
	UpdateMoney(HwndStaticPlayer, @PlayerMoney, DefaultMoney)
	UpdateMoney(HwndStaticLeftEnemy , @LeftEnemyMoney, DefaultMoney)
	UpdateMoney(HwndStaticBank, @BankMoney, 0)
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_NewStage(ByVal hWin As HWND)
	' Новый раунд игры
	
	Dim OldGameMode As GameModes = GameMode
	PlayerKeyboardCardNumber = 0
	
	Dim NineWindowTitle As WString * (511 + 1) = Any
	LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @NineWindowTitle, 511)
	
	Dim CharacterFail As WString * (511 + 1) = Any
	LoadString(GetModuleHandle(0), IDS_CHARACTERFAIL, @CharacterFail, 511)
	
	Dim TryAgain As WString * (511 + 1) = Any
	LoadString(GetModuleHandle(0), IDS_TRYAGAIN, @TryAgain, 511)
	
	If RightEnemyMoney.Value <= 0 Then
		' Проигрыш
		' TODO Анимация проигрыша
		Dim FailMessageText As WString * (511 * 3 + 1) = Any
		lstrcpy(@FailMessageText, @RightEnemyMoney.CharacterName)
		lstrcat(@FailMessageText, @CharacterFail)
		lstrcat(@FailMessageText, @TryAgain)
		
		GameMode = GameModes.Stopped
		If MessageBox(hWin, @FailMessageText, @NineWindowTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
			' Начинаем заново
			GameMode = OldGameMode
			PostMessage(hWin, PM_NEWGAME, 0, 0)
		End If
	Else
		If PlayerMoney.Value <= 0 Then
			' Проигрыш
			' TODO Анимация проигрыша
			Dim FailMessageText As WString * (511 * 3 + 1) = Any
			lstrcpy(@FailMessageText, @PlayerMoney.CharacterName)
			lstrcat(@FailMessageText, @CharacterFail)
			lstrcat(@FailMessageText, @TryAgain)
			
			GameMode = GameModes.Stopped
			If MessageBox(hWin, @FailMessageText, @NineWindowTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
				' Начинаем заново
				GameMode = OldGameMode
				PostMessage(hWin, PM_NEWGAME, 0, 0)
			End If
			
		Else
			If LeftEnemyMoney.Value <= 0 Then
				' Проигрыш
				' TODO Анимация проигрыша
				Dim FailMessageText As WString * (511 * 3 + 1) = Any
				lstrcpy(@FailMessageText, @LeftEnemyMoney.CharacterName)
				lstrcat(@FailMessageText, @CharacterFail)
				lstrcat(@FailMessageText, @TryAgain)
				
				GameMode = GameModes.Stopped
				If MessageBox(hWin, @FailMessageText, @NineWindowTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
					' Начинаем заново
					GameMode = OldGameMode
					PostMessage(hWin, PM_NEWGAME, 0, 0)
				End If
			Else
				' Событие взятия суммы у игроков
				SendMessage(hWin, PM_DEALMONEY, 0, 0)
				
				' Событие раздачи колоды карт игрокам
				PostMessage(hWin, PM_BANKDEALPACK, 0, 0)
			End If
		End If
	End If
End Sub

Sub MainForm_DealMoney(ByVal hWin As HWND)
	' Взятие денег у персонажей
	UpdateMoney(HwndStaticRightEnemy, @RightEnemyMoney, RightEnemyMoney.Value - ZZZMoney)
	UpdateMoney(HwndStaticPlayer, @PlayerMoney, PlayerMoney.Value - ZZZMoney)
	UpdateMoney(HwndStaticLeftEnemy, @LeftEnemyMoney, LeftEnemyMoney.Value - ZZZMoney)
	UpdateMoney(HwndStaticBank, @BankMoney, 3 * ZZZMoney)
End Sub

Sub MainForm_BankDealPack(ByVal hWin As HWND)
	' Раздача колоды
	
	' Перемешивание массива
	Dim RandomNumbers(35) As Integer = Any
	ShuffleArray(@RandomNumbers(0), 36)
	
	' Выдача игрокам
	For i As Integer = 0 To 11
		RightEnemyDeck(i).IsUsed = True
		BankDeck(i).IsUsed = False
		RightEnemyDeck(i).CardSortNumber = RandomNumbers(i)
		RightEnemyDeck(i).CardNumber = GetCardNumber(RandomNumbers(i))
	Next
	SortCharacterPack(@RightEnemyDeck(0))
	
	For i As Integer = 0 To 11
		PlayerDeck(i).IsUsed = True
		BankDeck(i + 12).IsUsed = False
		PlayerDeck(i).CardSortNumber = RandomNumbers(i + 12)
		PlayerDeck(i).CardNumber = GetCardNumber(RandomNumbers(i + 12))
	Next
	SortCharacterPack(@PlayerDeck(0))
	
	For i As Integer = 0 To 11
		LeftEnemyDeck(i).IsUsed = True
		BankDeck(i + 2 * 12).IsUsed = False
		LeftEnemyDeck(i).CardSortNumber = RandomNumbers(i + 2 * 12)
		LeftEnemyDeck(i).CardNumber = GetCardNumber(RandomNumbers(i + 2 * 12))
	Next
	SortCharacterPack(@LeftEnemyDeck(0))
	
	' Анимация раздачи колоды
	If BankDealPackAnimationEndbled Then
		SetTimer(hWin, MainFormTimers.BankDealPack, DealPackTimerElapsedTime, NULL)
	Else
		Scope
			Dim InvalidRectangle As RECT = Any
			SetRect(@InvalidRectangle, RightEnemyDeck(0).X, RightEnemyDeck(0).Y, RightEnemyDeck(11).X + DefautlCardWidth, RightEnemyDeck(11).Y + DefautlCardHeight)
			InvalidateRect(hWin, @InvalidRectangle, 0)
		End Scope
		
		Scope
			Dim InvalidRectangle As RECT = Any
			SetRect(@InvalidRectangle, PlayerDeck(0).X, PlayerDeck(0).Y, PlayerDeck(11).X + DefautlCardWidth, PlayerDeck(11).Y + DefautlCardHeight)
			InvalidateRect(hWin, @InvalidRectangle, 0)
		End Scope
		
		Scope
			Dim InvalidRectangle As RECT = Any
			SetRect(@InvalidRectangle, LeftEnemyDeck(0).X, LeftEnemyDeck(0).Y, LeftEnemyDeck(11).X + DefautlCardWidth, LeftEnemyDeck(11).Y + DefautlCardHeight)
			InvalidateRect(hWin, @InvalidRectangle, 0)
		End Scope
		
		Scope
			Dim InvalidRectangle As RECT = Any
			SetRect(@InvalidRectangle, BankDeck(0).X, BankDeck(0).Y, BankDeck(35).X + DefautlCardWidth, BankDeck(35).Y + DefautlCardHeight)
			InvalidateRect(hWin, @InvalidRectangle, 0)
		End Scope
		
		Dim cn As CharacterWithNine = GetNinePlayerNumber(@RightEnemyDeck(0), @PlayerDeck(0), @LeftEnemyDeck(0))
		Select Case cn.Character
			Case Characters.RightCharacter
				PostMessage(hWin, PM_RENEMYATTACK, cn.NineIndex, True)
			Case Characters.Player
				PostMessage(hWin, PM_USERATTACK, cn.NineIndex, True)
			Case Characters.LeftCharacter
				PostMessage(hWin, PM_LENEMYATTACK, cn.NineIndex, True)
		End Select
	End If
End Sub


Sub MainForm_RightEnemyAttack(ByVal hWin As HWND, ByVal CardNumber As Integer, ByVal IsUsed As Integer)
	If IsUsed = 0 Then
		' Карта не назначена, номер определить самостоятельно
		Dim CardIndex As Integer = GetPlayerDealCard(@RightEnemyDeck(0), @BankDeck(0))
		If CardIndex >= 0 Then
			CardNumber = CardIndex
			IsUsed = True
		End If
	End If
	
	If IsUsed = 0 Then
		' Карта не найдена, персонаж не может ходить
		PostMessage(hWin, PM_RENEMYFOOL, 0, 0)
	Else
		' Карта найдена, скинуть её на стол
		RightEnemyDealCard(hWin, CardNumber)
	End If
End Sub

Sub MainForm_UserAttack(ByVal hWin As HWND, ByVal CardNumber As Integer, ByVal IsUsed As Integer)
	If IsUsed = 0 Then
		' Карта не назначена, номер определить самостоятельно
		If GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0)) >= 0 Then
			PlayerCanPlay = True
		Else
			' Карта не найдена, персонаж не может ходить
			PostMessage(hWin, PM_USERFOOL, 0, 0)
		End If
	Else
		' Установить номер на ближайшую правую карту
		Dim tmpNumber As Integer = CardNumber
		Do
			tmpNumber += 1
			If tmpNumber > 11 Then
				tmpNumber = 0
			End If
			If PlayerDeck(tmpNumber).IsUsed Then
				Exit Do
			End If
		Loop While tmpNumber <> CardNumber
		PlayerKeyboardCardNumber = tmpNumber
		' TODO Перерисовать стрелку‐указатель
		' Scope
			' Dim hDC As HDC = GetDC(hWin)
			' DrawUpArrow(hDC, PlayerKeyboardCardNumber)
			' ReleaseDC(hWin, hDC)
		' End Scope
		' Ходить указанной картой
		UserDealCard(hWin, CardNumber)
	End If
End Sub

Sub MainForm_LeftEnemyAttack(ByVal hWin As HWND, ByVal CardNumber As Integer, ByVal IsUsed As Integer)
	If IsUsed = 0 Then
		' Карта не назначена, номер определить самостоятельно
		Dim CardIndex As Integer = GetPlayerDealCard(@LeftEnemyDeck(0), @BankDeck(0))
		If CardIndex >= 0 Then
			CardNumber = CardIndex
			IsUsed = True
		End If
	End If
	
	If IsUsed = 0 Then
		' Карта не найдена, персонаж не может ходить
		PostMessage(hWin, PM_LENEMYFOOL, 0, 0)
	Else
		' Карта найдена, скинуть её на стол
		LeftEnemyDealCard(hWin, CardNumber)
	End If
End Sub


Sub MainForm_RightEnemyFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	UpdateMoney(HwndStaticRightEnemy, @RightEnemyMoney, RightEnemyMoney.Value - FFFMoney)
	UpdateMoney(HwndStaticBank, @BankMoney, BankMoney.Value + FFFMoney)
	
	Select Case GameMode
		Case GameModes.Normal
			' Передать ход игроку
			PostMessage(hWin, PM_USERATTACK, 0, 0)
			
		Case GameModes.AI
			' Назначить карту игроку
			Dim IsUsed As Integer = 0
			Dim CardIndex As Integer = GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0))
			If CardIndex >= 0 Then
				IsUsed = True
			End If
			' Передать ход игроку
			PostMessage(hWin, PM_USERATTACK, CardIndex, IsUsed)
			
		Case GameModes.Online
			' TODO Ход игрока при сетевой игре
			
	End Select
	
End Sub

Sub MainForm_UserFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	UpdateMoney(HwndStaticPlayer, @PlayerMoney, PlayerMoney.Value - FFFMoney)
	UpdateMoney(HwndStaticBank, @BankMoney, BankMoney.Value + FFFMoney)
	
	' Передать ход левому игроку
	PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
End Sub

Sub MainForm_LeftEnemyFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	UpdateMoney(HwndStaticLeftEnemy, @LeftEnemyMoney, LeftEnemyMoney.Value - FFFMoney)
	UpdateMoney(HwndStaticBank, @BankMoney, BankMoney.Value + FFFMoney)
	
	' Передать правому врагу
	PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
End Sub


Sub MainForm_RightEnemyWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	UpdateMoney(HwndStaticRightEnemy, @RightEnemyMoney, RightEnemyMoney.Value + BankMoney.Value)
	UpdateMoney(HwndStaticBank, @BankMoney, 0)
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_UserWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	UpdateMoney(HwndStaticPlayer, @PlayerMoney, PlayerMoney.Value + BankMoney.Value)
	UpdateMoney(HwndStaticBank, @BankMoney, 0)
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_LeftEnemyWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	UpdateMoney(HwndStaticLeftEnemy, @LeftEnemyMoney, LeftEnemyMoney.Value + BankMoney.Value)
	UpdateMoney(HwndStaticBank, @BankMoney, 0)
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub


Sub RightEnemyDealCardTimer_Tick(ByVal hWin As HWND)
	If AnimateCard(hWin) Then
		KillTimer(hWin, MainFormTimers.RightEnemyDealCard)
		' Если на руках карт нет, то победа
		If IsPlayerWin(@RightEnemyDeck(0)) Then
			PostMessage(hWin, PM_RENEMYWIN, 0, 0)
		Else
			Dim wParam As WPARAM = Any
			Dim lParam As LPARAM = Any
			
			' Передать ход игроку
			Select Case GameMode
				Case GameModes.Normal
					lParam = False
					
				Case GameModes.AI
					' Выбрать карту за игрока
					Dim CardIndex As Integer = GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0))
					If CardIndex >= 0 Then
						wParam = CardIndex
						lParam = True
					Else
						lParam = False
					End If
					
				Case GameModes.Online
					
			End Select
			
			PostMessage(hWin, PM_USERATTACK, wParam, lParam)
		End If
	End If
End Sub

Sub PlayerDealCardTimer_Tick(ByVal hWin As HWND)
	If AnimateCard(hWin) Then
		KillTimer(hWin, MainFormTimers.PlayerDealCard)
		If IsPlayerWin(@PlayerDeck(0)) Then
			' Победа
			PostMessage(hWin, PM_USERWIN, 0, 0)
		Else
			' Передать ход левому врагу
			PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
		End If
	End If
End Sub

Sub LeftEnemyDealCardTimer_Tick(ByVal hWin As HWND)
	If AnimateCard(hWin) Then
		KillTimer(hWin, MainFormTimers.LeftEnemyDealCard)
		' Если на руках карт нет, то победа
		If IsPlayerWin(@LeftEnemyDeck(0)) Then
			' Победа
			PostMessage(hWin, PM_LENEMYWIN, 0, 0)
		Else
			' Передать ход правому врагу
			PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
		End If
	End If
End Sub


Sub BankDealPackTimer_Tick(ByVal hWin As HWND)
	' Колода исчезает
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		Dim NewNumber As Integer = GetBankCardNumberAnimateDealCard(BankDealPackAnimationCardNumber)
		EraseCard(hDC, AnimationGraphics.DeviceContext, @BankDeck(NewNumber))
		
		ReleaseDC(hWin, hDC)
	End Scope
	' Увеличить счётчик
	BankDealPackAnimationCardNumber += 1
	' Если вышли за границу, то перейти к следующему этапу анимации
	If BankDealPackAnimationCardNumber >= 36 Then
		BankDealPackAnimationCardNumber = 0
		KillTimer(hWin, MainFormTimers.BankDealPack)
		SetTimer(hWin, MainFormTimers.BankDealPackRightEnemy, DealPackTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealPackRightEnemyTimer_Tick(ByVal hWin As HWND)
	' Появляются карты у правого врага
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterCard(hDC, @RightEnemyDeck(BankDealPackAnimationCardNumber), Characters.RightCharacter)
		
		ReleaseDC(hWin, hDC)
	End Scope
	BankDealPackAnimationCardNumber += 1
	If BankDealPackAnimationCardNumber >= 12 Then
		BankDealPackAnimationCardNumber = 11
		KillTimer(hWin, MainFormTimers.BankDealPackRightEnemy)
		SetTimer(hWin, MainFormTimers.BankDealPackPlayer, DealPackTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealPackPlayerTimer_Tick(ByVal hWin As HWND)
	' Повляются карты у игрока
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterCard(hDC, @PlayerDeck(BankDealPackAnimationCardNumber), Characters.Player)
		
		ReleaseDC(hWin, hDC)
	End Scope
	BankDealPackAnimationCardNumber -= 1
	If BankDealPackAnimationCardNumber < 0 Then
		BankDealPackAnimationCardNumber = 11
		KillTimer(hWin, MainFormTimers.BankDealPackPlayer)
		SetTimer(hWin, MainFormTimers.BankDealPackLeftEnemy, DealPackTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealPackLeftEnemyTimer_Tick(ByVal hWin As HWND)
	' Появляются карты у левого персонажа
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		If BankDealPackAnimationCardNumber <> 11 Then
			' Переместить в память
			BitBlt(AnimationGraphics.DeviceContext, 0, 0, DefautlCardWidth, LeftEnemyDeck(11).Y - LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).Y + DefautlCardHeight, hDC, LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).X, LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).Y, SRCCOPY)
		End If
		
		' Нарисовать
		DrawCharacterCard(hDC, @LeftEnemyDeck(BankDealPackAnimationCardNumber), Characters.LeftCharacter)
		
		' Переместить из памяти
		If BankDealPackAnimationCardNumber <> 11 Then
			BitBlt(hDC, LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).X, LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).Y, DefautlCardWidth, LeftEnemyDeck(11).Y - LeftEnemyDeck(BankDealPackAnimationCardNumber + 1).Y + DefautlCardHeight, AnimationGraphics.DeviceContext, 0, 0, SRCCOPY)
		End If
		
		ReleaseDC(hWin, hDC)
	End Scope
	
	BankDealPackAnimationCardNumber -= 1
	If BankDealPackAnimationCardNumber < 0 Then
		BankDealPackAnimationCardNumber = 0
		KillTimer(hWin, MainFormTimers.BankDealPackLeftEnemy)
		SetTimer(hWin, MainFormTimers.BankDealPackFinish, DealPackTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealPackFinishTimer_Tick(ByVal hWin As HWND)
	' Закончилось
	KillTimer(hWin, MainFormTimers.BankDealPackFinish)
	
	' Найти того, у кого девятка бубен и сделать назначить ему ход
	Dim cn As CharacterWithNine = GetNinePlayerNumber(@RightEnemyDeck(0), @PlayerDeck(0), @LeftEnemyDeck(0))
	Select Case cn.Character
		Case Characters.RightCharacter
			PostMessage(hWin, PM_RENEMYATTACK, cn.NineIndex, True)
		Case Characters.Player
			PostMessage(hWin, PM_USERATTACK, cn.NineIndex, True)
		Case Characters.LeftCharacter
			PostMessage(hWin, PM_LENEMYATTACK, cn.NineIndex, True)
	End Select
End Sub
