#include once "MainForm.bi"
#include once "Drawing.bi"
#include once "Cards.bi"
#include once "MainFormEvents.bi"
#include once "PlayerCard.bi"
#include once "Nine.rh"
#include once "IntegerToWString.bi"
' #include once "crt.bi"
#include once "ThreadProc.bi"
#include once "Irc.bi"
#include once "IrcEvents.bi"
#include once "IrcReplies.bi"
#include once "NetworkParamDialogProc.bi"
#include once "AboutDialogProc.bi"

' Режим игры
Enum GameMode
	' Игра остановлена
	Stopped
	' Игра с самим собой
	Normal
	' Игра с компьютером
	AI
	' Игра по сети
	Network
End Enum

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
Const DealPackTimerElapsedTime As Integer = DealCardTimerElapsedTime

' Имена игроков
' Dim Shared RightEnemyName As WString * 512
' Dim Shared PlayerName As WString * 512
' Dim Shared LeftRightEnemyName As WString * 512
' Dim Shared BankName As WString * 512
Dim Shared CurrencyChar As WString * 16

' Массив точек для анимации карты игрока
Dim Shared PlayerDealCardAnimationPointStart As Point
Dim Shared PlayerDealCardAnimationCardSortNumber As Integer
Dim Shared PlayerDealCardAnimationCardIncrementX As Integer
Dim Shared PlayerDealCardAnimationCardIncrementY As Integer
Dim Shared PlayerDealCardAnimationPointStartCount As Integer

Dim Shared PlayerDealCardAnimationHDC As HDC
Dim Shared PlayerDealCardAnimationBitmap As HBITMAP
Dim Shared OldPlayerDealCardAnimationBitmap As HBITMAP
Dim Shared OldPlayerDealCardAnimationPen As HPEN
Dim Shared OldPlayerDealCardAnimationBrush As HBRUSH
Dim Shared OldPlayerDealCardAnimationFont As HFONT

Dim Shared MemoryHDC As HDC
Dim Shared MemoryBitmap As HBITMAP
Dim Shared OldMemoryBitmap As HBITMAP
Dim Shared OldMemoryPen As HPEN
Dim Shared OldMemoryBrush As HBRUSH
Dim Shared OldMemoryFont As HFONT

' Анимация выдачи карт
Dim Shared BankDealCardAnimationCardNumber As Integer

' Игра идёт
Dim Shared CurrentGameMode As GameMode

' Рисование
Const BackColor As Integer = &h006400
Const ForeColor As Integer = &hFFF8F0

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
	
	BackColorBrush = CreateSolidBrush(BackColor)
	BackColorPen = CreatePen(PS_SOLID, 1, BackColor)
	
	Dim hDefaultFont As HFONT = GetStockObject(DEFAULT_GUI_FONT)
	Dim oFont As LOGFONT = Any
	GetObject(hDefaultFont, SizeOf(LOGFONT), @oFont)
	oFont.lfHeight *= 4
	DefaultFont = CreateFontIndirect(@oFont)
	
	PlayerDealCardAnimationHDC = CreateCompatibleDC(0)
	Scope
		Dim hDCmem As HDC = GetDC(hWin)
		PlayerDealCardAnimationBitmap = CreateCompatibleBitmap(hDCmem, GetDeviceCaps(PlayerDealCardAnimationHDC, HORZRES), GetDeviceCaps(PlayerDealCardAnimationHDC, VERTRES))
		ReleaseDC(hWin, hDCmem)
	End Scope
	OldPlayerDealCardAnimationBitmap = SelectObject(PlayerDealCardAnimationHDC, PlayerDealCardAnimationBitmap)
	OldPlayerDealCardAnimationPen = SelectObject(PlayerDealCardAnimationHDC, BackColorPen)
	OldPlayerDealCardAnimationBrush = SelectObject(PlayerDealCardAnimationHDC, BackColorBrush)
	OldPlayerDealCardAnimationFont = SelectObject(PlayerDealCardAnimationHDC, DefaultFont)
	
	MemoryHDC = CreateCompatibleDC(0)
	Scope
		Dim hDCmem As HDC = GetDC(hWin)
		MemoryBitmap = CreateCompatibleBitmap(hDCmem, GetDeviceCaps(MemoryHDC, HORZRES), GetDeviceCaps(MemoryHDC, VERTRES))
		ReleaseDC(hWin, hDCmem)
	End Scope
	OldMemoryBitmap = SelectObject(MemoryHDC, MemoryBitmap)
	OldMemoryPen = SelectObject(MemoryHDC, BackColorPen)
	OldMemoryBrush = SelectObject(MemoryHDC, BackColorBrush)
	OldMemoryFont = SelectObject(MemoryHDC, DefaultFont)
End Sub

Sub MainFormMenuNewGame_Click(ByVal hWin As HWND)
	If CurrentGameMode = GameMode.Normal OrElse CurrentGameMode = GameMode.Network Then
		Dim WarningMsg As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_NEWGAMEWARNING, @WarningMsg, 1024 - 1)
		Dim MessageBoxTitle As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
		If MessageBox(hWin, @WarningMsg, @MessageBoxTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2) <> IDYES Then
			Exit Sub
		End If
	End If
	CurrentGameMode = GameMode.Normal
	PostMessage(hWin, PM_NEWGAME, 0, 0)
End Sub

Sub MainFormMenuNewNetworkGame_Click(ByVal hWin As HWND)
	' TODO Сделать сетевой режим
	If CurrentGameMode = GameMode.Normal OrElse CurrentGameMode = GameMode.Network Then
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
	' Открыть соединение с сервером
	' m_IrcClient.ExtendedData = @m_IrcClient
	' m_IrcClient.ServerMessageEvent = @ServerMessage
	' m_IrcClient.UserJoinedEvent = @UserJoined
	' If m_IrcClient.OpenIrc(@Server, @Port, @LocalAddress, @LocalPort, @"", @Nick, @Nick, @"Gaming The Nine Bot", False) = ResultType.None Then
		' Запустить второй поток для генерации событий
		' Dim hThread As Handle = CreateThread(NULL, 0, @ThreadProc, @m_IrcClient, 0, 0)
		' CloseHandle(hThread)
	' End If
	CurrentGameMode = GameMode.Network
	PostMessage(hWin, PM_NEWGAME, 0, 0)
End Sub

Sub MainFormMenuNewAIGame_Click(ByVal hWin As HWND)
	If CurrentGameMode = GameMode.Normal OrElse CurrentGameMode = GameMode.Network Then
		Dim WarningMsg As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_NEWGAMEWARNING, @WarningMsg, 1024 - 1)
		Dim MessageBoxTitle As WString * 1024 = Any
		LoadString(GetModuleHandle(0), IDS_WINDOWTITLE, @MessageBoxTitle, 1024 - 1)
		If MessageBox(hWin, @WarningMsg, @MessageBoxTitle, MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2) <> IDYES Then
			Exit Sub
		End If
	End If
	CurrentGameMode = GameMode.AI
	PostMessage(hWin, PM_NEWGAME, 0, 0)
End Sub

Sub MainFormMenuFileExit_Click(ByVal hWin As HWND)
	DestroyWindow(hWin)
End Sub

Sub MainFormMenuHelpContents_Click(ByVal hWin As HWND)
	MessageBox(hWin, "Справочная система ещё не реализована", "Девятка", MB_OK + MB_ICONINFORMATION)
End Sub

Sub MainFormMenuHelpAbout_Click(ByVal hWin As HWND)
	DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DLG_ABOUT), hWin, @AboutDialogProc, 0)
End Sub

Sub MainForm_LeftMouseDown(ByVal hWin As HWND, ByVal KeyModifier As Integer, ByVal X As Integer, ByVal Y As Integer)
	If PlayerCanPlay Then
		' Получить номер карты, на который щёлкнул пользователь
		Dim CardNumber As Integer = GetClickPlayerCardNumber(@PlayerDeck(0), X, Y, DefautlCardWidth, DefautlCardHeight)
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
	
	' Карты игрока и врагов
	If CurrentGameMode <> GameMode.Stopped Then
		DrawCharacterPack(hDC, MemoryHDC, @RightEnemyDeck(0), Characters.RightCharacter)
		DrawCharacterPack(hDC, MemoryHDC, @PlayerDeck(0), Characters.Player)
		DrawCharacterPack(hDC, MemoryHDC, @LeftEnemyDeck(0), Characters.LeftCharacter)
	End If
	
	DrawBankPack(hDC, MemoryHDC, CurrentGameMode <> GameMode.Stopped, @BankDeck(0))
	
	' Деньги
	Scope
		Dim intColor As Integer = SetTextColor(MemoryHDC, ForeColor)
		Dim intBkMode As Integer = SetBkMode(MemoryHDC, TRANSPARENT)
		
		DrawMoney(hDC, MemoryHDC, @RightEnemyMoney)
		DrawMoney(hDC, MemoryHDC, @PlayerMoney)
		DrawMoney(hDC, MemoryHDC, @LeftEnemyMoney)
		DrawMoney(hDC, MemoryHDC, @BankMoney)
		
		' TODO Выяснить координаты стрелки
		' If PlayerCanPlay Then
			' DrawUpArrow(hDC, MemoryHDC, 0, 0)
		' End If
		
		SetTextColor(MemoryHDC, intColor)
		SetBkMode(MemoryHDC, intBkMode)
	End Scope
	
	EndPaint(hWin, @pnt)
End Sub

Sub MainForm_Resize(ByVal hWin As HWND, ByVal ResizingRequested As Integer, ByVal ClientWidth As Integer, ByVal ClientHeight As Integer)
	' Изменение размеров окна, пересчитать координаты карт
	
	' TODO Адаптивный дизайн: масштабирование и распределение по всему окну
	
	' Центр клиентской области
	' Dim ClientRectangle As RECT = Any
	' GetClientRect(hWin, @ClientRectangle)
	' Dim cx As Integer = ClientRectangle.right \ 2
	' Dim cy As Integer = ClientRectangle.bottom \ 2
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
End Sub

Sub MainForm_Close(ByVal hWin As HWND)
	' Пользователь пытается закрыть окно
	' Если игра уже идёт, то спросить
	DestroyWindow(hWin)
End Sub

Sub MainForm_UnLoad(ByVal hWin As HWND)
	SelectObject(MemoryHDC, OldMemoryFont)
	SelectObject(MemoryHDC, OldMemoryBrush)
	SelectObject(MemoryHDC, OldMemoryPen)
	SelectObject(MemoryHDC, OldMemoryBitmap)
	DeleteObject(MemoryBitmap)
	DeleteDC(MemoryHDC)
	
	SelectObject(PlayerDealCardAnimationHDC, OldPlayerDealCardAnimationFont)
	SelectObject(PlayerDealCardAnimationHDC, OldPlayerDealCardAnimationBrush)
	SelectObject(PlayerDealCardAnimationHDC, OldPlayerDealCardAnimationPen)
	SelectObject(PlayerDealCardAnimationHDC, OldPlayerDealCardAnimationBitmap)
	DeleteObject(PlayerDealCardAnimationBitmap)
	DeleteDC(PlayerDealCardAnimationHDC)
	
	DeleteObject(DefaultFont)
	DeleteObject(BackColorPen)
	DeleteObject(BackColorBrush)
	
	cdtTerm()
End Sub

Sub MainForm_NewGame(ByVal hWin As HWND)
	' Начинаем новую игру
	
	' Событие восстановления суммы денег
	SendMessage(hWin, PM_DEFAULTMONEY, 0, 0)
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_NewStage(ByVal hWin As HWND)
	' Новый раунд игры
	
	PlayerKeyboardCardNumber = 0
	
	If PlayerMoney.Value <= 0 Then
		' Проигрыш
		' TODO Анимация проигрыша
		CurrentGameMode = GameMode.Stopped
		If MessageBox(hWin, "Ты проиграл. Начать заново?", "Девятка", MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
			' Начинаем заново
			PostMessage(hWin, PM_NEWGAME, 0, 0)
		End If
		
	Else
		If RightEnemyMoney.Value <= 0 Then
			' Проигрыш
			' TODO Анимация проигрыша
			CurrentGameMode = GameMode.Stopped
			If MessageBox(hWin, "Зиновий проиграл. Начать заново?", "Девятка", MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
				' Начинаем заново
				PostMessage(hWin, PM_NEWGAME, 0, 0)
			End If
		Else
			If LeftEnemyMoney.Value <= 0 Then
				' Проигрыш
				' TODO Анимация проигрыша
				CurrentGameMode = GameMode.Stopped
				If MessageBox(hWin, "Ева проиграла. Начать заново?", "Девятка", MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON1) = IDYES Then
					' Начинаем заново
					PostMessage(hWin, PM_NEWGAME, 0, 0)
				End If
			Else
				' Событие взятия суммы у игроков
				SendMessage(hWin, PM_DEALMONEY, 0, 0)
				
				' Событие раздачи колоды карт игрокам
				PostMessage(hWin, PM_DEALPACK, 0, 0)
			End If
		End If
	End If
End Sub

Sub MainForm_DefaultMoney(ByVal hWin As HWND)
	' Событие восстановления денег
	' TODO Анимация восстановления денег
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value = DefaultMoney
	' m(3) = BankMoney.Value
	
	PlayerMoney.Value = DefaultMoney
	LeftEnemyMoney.Value = DefaultMoney
	RightEnemyMoney.Value = DefaultMoney
	BankMoney.Value = 0
	' RightEnemyMoney.Value, PlayerMoney.Value, LeftEnemyMoney.Value, BankMoney.Value
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
End Sub

Sub MainForm_DealMoney(ByVal hWin As HWND)
	' Взятие денег у персонажей
	' TODO Анимация взятия денег у игроков
	' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
	Dim m(3) As Integer = Any
	m(0) = PlayerMoney.Value
	m(1) = RightEnemyMoney.Value
	m(2) = LeftEnemyMoney.Value = DefaultMoney
	m(3) = BankMoney.Value
	
	PlayerMoney.Value -= ZZZMoney
	LeftEnemyMoney.Value -= ZZZMoney
	RightEnemyMoney.Value -= ZZZMoney
	BankMoney.Value = 3 * ZZZMoney
	
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
End Sub

Sub MainForm_DealPack(ByVal hWin As HWND)
	' Раздача колоды
	
	' Перемешивание массива
	Dim RandomNumbers(35) As Integer = Any
	ShuffleArray(@RandomNumbers(0), 36)
	
	' Выдача игрокам
	For i As Integer = 0 To 11
		PlayerDeck(i).IsUsed = True
		PlayerDeck(i).CardSortNumber = RandomNumbers(i)
		PlayerDeck(i).CardNumber = GetCardNumber(RandomNumbers(i))
	Next
	For i As Integer = 0 To 11
		LeftEnemyDeck(i).IsUsed = True
		LeftEnemyDeck(i).CardSortNumber = RandomNumbers(i + 12)
		LeftEnemyDeck(i).CardNumber = GetCardNumber(RandomNumbers(i + 12))
	Next
	For i As Integer = 0 To 11
		RightEnemyDeck(i).IsUsed = True
		RightEnemyDeck(i).CardSortNumber = RandomNumbers(i + 2 * 12)
		RightEnemyDeck(i).CardNumber = GetCardNumber(RandomNumbers(i + 2 * 12))
	Next
	
	' Сортировать карты по мастям по старшинству
	SortCharacterPack(@RightEnemyDeck(0))
	SortCharacterPack(@PlayerDeck(0))
	SortCharacterPack(@LeftEnemyDeck(0))
	
	' Анимация раздачи колоды
	SetTimer(hWin, MainFormTimers.BankDealCard, DealPackTimerElapsedTime, NULL)
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
		PostMessage(hWin, PM_RENEMYDEALCARD, CardNumber, 0)
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
		PostMessage(hWin, PM_LENEMYDEALCARD, CardNumber, 0)
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
		PostMessage(hWin, PM_USERDEALCARD, CardNumber, 0)
	End If
End Sub

Sub MainForm_RightEnemyFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value
	' m(3) = BankMoney.Value
	
	RightEnemyMoney.Value -= FFFMoney
	BankMoney.Value += FFFMoney
	
	' TODO Анимация взятия денег
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	Select Case CurrentGameMode
		Case GameMode.Normal
			' Передать ход игроку
			PostMessage(hWin, PM_USERATTACK, 0, 0)
			
		Case GameMode.AI
			' Назначить карту игроку
			Dim IsUsed As Integer = 0
			Dim CardIndex As Integer = GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0))
			If CardIndex >= 0 Then
				IsUsed = True
			End If
			' Передать ход игроку
			PostMessage(hWin, PM_USERATTACK, CardIndex, IsUsed)
			
		Case GameMode.Network
			' TODO Ход игрока при сетевой игре
			
	End Select
	
End Sub

Sub MainForm_UserFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value
	' m(3) = BankMoney.Value
	
	PlayerMoney.Value -= FFFMoney
	BankMoney.Value += FFFMoney
	
	' TODO Анимация взятия денег
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	' Передать ход левому игроку
	PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
End Sub

Sub MainForm_LeftEnemyFool(ByVal hWin As HWND)
	' Взятие денег у игрока при отсутствии карты для хода
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value
	' m(3) = BankMoney.Value
	
	LeftEnemyMoney.Value -= FFFMoney
	BankMoney.Value += FFFMoney
	
	' TODO Анимация взятия денег
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	' Передать правому врагу
	PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
End Sub

Sub MainForm_RightEnemyWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	' TODO Анимация игрок забирает все деньги банка
	' BankDealMoneyTimerId
	' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value
	' m(3) = BankMoney.Value
	
	RightEnemyMoney.Value += BankMoney.Value
	BankMoney.Value = 0
	
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_UserWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	' TODO Анимация игрок забирает все деньги банка
	' BankDealMoneyTimerId
	' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value = DefaultMoney
	' m(3) = BankMoney.Value
	
	PlayerMoney.Value += BankMoney.Value
	BankMoney.Value = 0
	
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_LeftEnemyWin(ByVal hWin As HWND)
	' Игрок положил последнюю карту
	' TODO Анимация игрок забирает все деньги банка
	' BankDealMoneyTimerId
	' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
	' Dim m(3) As Integer = Any
	' m(0) = PlayerMoney.Value
	' m(1) = RightEnemyMoney.Value
	' m(2) = LeftEnemyMoney.Value = DefaultMoney
	' m(3) = BankMoney.Value
	
	LeftEnemyMoney.Value += BankMoney.Value
	BankMoney.Value = 0
	
	' Scope
		' Dim hDC As HDC = GetDC(hWin)
		' DrawMoney(hDC, m(0), m(1), m(2), m(3))
		' ReleaseDC(hWin, hDC)
	' End Scope
	
	' Начать новый раунд
	PostMessage(hWin, PM_NEWSTAGE, 0, 0)
End Sub

Sub MainForm_RightEnemyDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	RightEnemyDeck(CardNumber).IsUsed = False
	
	' Начальная и конечная точки
	PlayerDealCardAnimationCardSortNumber = RightEnemyDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - RightEnemyDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - RightEnemyDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	
	PlayerDealCardAnimationPointStart.X = RightEnemyDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = RightEnemyDeck(CardNumber).Y
	
	' Запустить таймер
	SetTimer(hWin, MainFormTimers.RightEnemyDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Sub MainForm_UserDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	PlayerDeck(CardNumber).IsUsed = False
	
	' Начальная и конечная точки
	PlayerDealCardAnimationCardSortNumber = PlayerDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	
	PlayerDealCardAnimationPointStart.X = PlayerDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = PlayerDeck(CardNumber).Y
	
	' Запустить таймер
	SetTimer(hWin, MainFormTimers.PlayerDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Sub MainForm_LeftEnemyDealCard(ByVal hWin As HWND, ByVal CardNumber As Integer)
	' Удалить карту из массива
	LeftEnemyDeck(CardNumber).IsUsed = False
	
	' Начальная карта
	PlayerDealCardAnimationCardSortNumber = LeftEnemyDeck(CardNumber).CardSortNumber
	' Приращение аргумента
	PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - LeftEnemyDeck(CardNumber).X) \ DealCardAnimationPartsCount
	PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - LeftEnemyDeck(CardNumber).Y) \ DealCardAnimationPartsCount
	' Начальная точка
	PlayerDealCardAnimationPointStart.X = LeftEnemyDeck(CardNumber).X
	PlayerDealCardAnimationPointStart.Y = LeftEnemyDeck(CardNumber).Y
	
	' Запустить таймер
	SetTimer(hWin, MainFormTimers.LeftEnemyDealCard, DealCardTimerElapsedTime, NULL)
End Sub

Sub RightEnemyDealCardTimer_Tick(ByVal hWin As HWND)
	' DrawCharacterPack(hDC, MemoryHDC, @RightEnemyDeck(0), Characters.RightCharacter)
	' Если на руках карт нет, то победа
	If IsPlayerWin(@RightEnemyDeck(0)) Then
		' PostMessage(hWin, PM_RENEMYWIN, 0, 0)
	Else
		Dim wParam As WPARAM = Any
		Dim lParam As LPARAM = Any
		
		' Передать ход игроку
		Select Case CurrentGameMode
			Case GameMode.Normal
				lParam = False
				
			Case GameMode.AI
				' Выбрать карту за игрока
				Dim CardIndex As Integer = GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0))
				If CardIndex >= 0 Then
					wParam = CardIndex
					lParam = True
				Else
					lParam = False
				End If
				
			Case GameMode.Network
				
		End Select
		
		' PostMessage(hWin, PM_USERATTACK, wParam, lParam)
	End If
End Sub

Sub PlayerDealCardTimer_Tick(ByVal hWin As HWND)
	' DrawCharacterPack(hDC, MemoryHDC, @PlayerDeck(0), Characters.Player)
	' Если карт больше нет, то это победа
	If IsPlayerWin(@PlayerDeck(0)) Then
		' Победа
		' PostMessage(hWin, PM_USERWIN, 0, 0)
	Else
		' Передать ход левому врагу
		' PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
	End If
End Sub

Sub LeftEnemyDealCardTimer_Tick(ByVal hWin As HWND)
	' Анимация передвижения карты
	
	Dim hDC As HDC = GetDC(hWin)
	
	Select Case PlayerDealCardAnimationPointStartCount
		Case 0
			PlayerDealCardAnimationPointStartCount = 1
			' TODO Исправить мигание колоды: стереть только ненужную карту
			DrawCharacterPack(hDC, MemoryHDC, @LeftEnemyDeck(0), Characters.LeftCharacter)
			' Увеличить координаты X и Y
			' PlayerDealCardAnimationPointStart.X += IncrementX(BankDeck(PlayerDealCardAnimationCardSortNumber).X)
			' PlayerDealCardAnimationPointStart.Y += IncrementY(BankDeck(PlayerDealCardAnimationCardSortNumber).Y)
			
			' Положить в память старое изображение
			BitBlt(PlayerDealCardAnimationHDC, 0, 0, DefautlCardWidth, DefautlCardHeight, hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, SRCCOPY)
			
		Case 1
			' Восстановить изображение из памяти
			BitBlt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, DefautlCardWidth, DefautlCardHeight, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
			
			' Увеличить координаты X и Y
			PlayerDealCardAnimationPointStart.X += IncrementX(BankDeck(PlayerDealCardAnimationCardSortNumber).X)
			PlayerDealCardAnimationPointStart.Y += IncrementY(BankDeck(PlayerDealCardAnimationCardSortNumber).Y)
			
			' Поместить в память изображение взяв оттуда где будет новое
			BitBlt(PlayerDealCardAnimationHDC, 0, 0, DefautlCardWidth, DefautlCardHeight, hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, SRCCOPY)
			' Нарисовать новое
			cdtDrawExt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, DefautlCardWidth, DefautlCardHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
			
			Dim dx As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDealCardAnimationPointStart.X)
			Dim dy As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDealCardAnimationPointStart.Y)
			If dx < Abs(PlayerDealCardAnimationCardIncrementX) OrElse dy < Abs(PlayerDealCardAnimationCardIncrementY) Then
				' Как только будет достигнута последняя точка, то остановить таймер
				PlayerDealCardAnimationPointStartCount = 2
			End If
			
		Case 2
			' KillTimer(hWin, wParam)
			KillTimer(hWin, MainFormTimers.LeftEnemyDealCard)
			PlayerDealCardAnimationPointStartCount = 0
			' Восстановить изображение из памяти
			BitBlt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, DefautlCardWidth, DefautlCardHeight, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
			
			' Сделать карту видимой на поле
			BankDeck(PlayerDealCardAnimationCardSortNumber).IsUsed = True
			
			' Нарисовать карту
			cdtDrawExt(hDC, BankDeck(PlayerDealCardAnimationCardSortNumber).X, BankDeck(PlayerDealCardAnimationCardSortNumber).Y, DefautlCardWidth, DefautlCardHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
			
			' Если на руках карт нет, то победа
			If IsPlayerWin(@LeftEnemyDeck(0)) Then
				' Победа
				' PostMessage(hWin, PM_LENEMYWIN, 0, 0)
			Else
				' Передать ход правому врагу
				' PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
			End If
	End Select
	
	ReleaseDC(hWin, hDC)
End Sub

Sub BankDealCardTimer_Tick(ByVal hWin As HWND)
	' Колода исчезает
	BankDeck(BankDealCardAnimationCardNumber).IsUsed = False
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		Dim NewNumber As Integer = GetBankCardNumberAnimateDealCard(BankDealCardAnimationCardNumber)
		
		EraseBankCard(hDC, PlayerDealCardAnimationHDC, @BankDeck(NewNumber))
		
		ReleaseDC(hWin, hDC)
	End Scope
	' Увеличить счётчик
	BankDealCardAnimationCardNumber += 1
	' Если вышли за границу, то перейти к следующему этапу анимации
	If BankDealCardAnimationCardNumber >= 36 Then
		BankDealCardAnimationCardNumber = 0
		KillTimer(hWin, MainFormTimers.BankDealCard)
		SetTimer(hWin, MainFormTimers.BankDealCardRightEnemy, DealCardTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealCardRightEnemyTimer_Tick(ByVal hWin As HWND)
	' Появляются карты у правого врага
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterCard(hDC, @RightEnemyDeck(BankDealCardAnimationCardNumber), Characters.RightCharacter)
		
		ReleaseDC(hWin, hDC)
	End Scope
	BankDealCardAnimationCardNumber += 1
	If BankDealCardAnimationCardNumber >= 12 Then
		BankDealCardAnimationCardNumber = 11
		KillTimer(hWin, MainFormTimers.BankDealCardRightEnemy)
		SetTimer(hWin, MainFormTimers.BankDealCardPlayer, DealCardTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealCardPlayerTimer_Tick(ByVal hWin As HWND)
	' Повляются карты у игрока
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		DrawCharacterCard(hDC, @PlayerDeck(BankDealCardAnimationCardNumber), Characters.Player)
		
		ReleaseDC(hWin, hDC)
	End Scope
	BankDealCardAnimationCardNumber -= 1
	If BankDealCardAnimationCardNumber < 0 Then
		BankDealCardAnimationCardNumber = 11
		KillTimer(hWin, MainFormTimers.BankDealCardPlayer)
		SetTimer(hWin, MainFormTimers.BankDealCardLeftEnemy, DealCardTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealCardLeftEnemyTimer_Tick(ByVal hWin As HWND)
	' Появляются карты у левого персонажа
	Scope
		Dim hDC As HDC = GetDC(hWin)
		
		If BankDealCardAnimationCardNumber <> 11 Then
			' Переместить в память
			BitBlt(PlayerDealCardAnimationHDC, 0, 0, DefautlCardWidth, LeftEnemyDeck(11).Y - LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).Y + DefautlCardHeight, hDC, LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).X, LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).Y, SRCCOPY)
		End If
		
		' Нарисовать
		DrawCharacterCard(hDC, @LeftEnemyDeck(BankDealCardAnimationCardNumber), Characters.LeftCharacter)
		
		' Переместить из памяти
		If BankDealCardAnimationCardNumber <> 11 Then
			BitBlt(hDC, LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).X, LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).Y, DefautlCardWidth, LeftEnemyDeck(11).Y - LeftEnemyDeck(BankDealCardAnimationCardNumber + 1).Y + DefautlCardHeight, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
		End If
		
		ReleaseDC(hWin, hDC)
	End Scope
	
	BankDealCardAnimationCardNumber -= 1
	If BankDealCardAnimationCardNumber < 0 Then
		BankDealCardAnimationCardNumber = 0
		KillTimer(hWin, MainFormTimers.BankDealCardLeftEnemy)
		SetTimer(hWin, MainFormTimers.BankDealCardFinish, DealCardTimerElapsedTime, NULL)
	End If
End Sub

Sub BankDealCardFinishTimer_Tick(ByVal hWin As HWND)
	' Закончилось
	KillTimer(hWin, MainFormTimers.BankDealCardFinish)
	
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

Sub BankDealMoneyTimer_Tick(ByVal hWin As HWND)
	
End Sub
