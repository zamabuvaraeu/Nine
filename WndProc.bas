#include once "WndProc.bi"
#include once "Cards.bi"
#include once "win\windowsx.bi"
#include once "GameEvents.bi"
#include once "PlayerCard.bi"
#include once "Nine.rh"
#include once "IntegerToWString.bi"
#include once "crt.bi"

' Зиновий и Ева
Const RightEnemyName = "Зиновий: "
Const PlayerName = "Я: "
Const LeftRightEnemyName = "Ева: "
Const BankName = "Банк: "

' Тёмно‐зелёный цвет
Const DarkGreenColor As Integer = &h006400

' Начальные сумы денег у игроков
Const DefaultMoney As Integer = 10
' Количество денег, которое кладётся в банк в начале игры
Const ZZZMoney As Integer = 2
' Количество денег, которое кладётся в банк если у игрока нет карт для хода
Const FFFMoney As Integer = 1

' Количество частей в траектории анимации карты
Const DealCardAnimationPartsCount As Integer = 32
' Количество миллисекунд таймера
Const TimerElapsedTime As Integer = 25
Const TimerElapsedTimeDealPack As Integer = TimerElapsedTime * 2
' Таймер анимации хода игрока
Const RightEnemyDealCardTimerId As Integer = 1
Const PlayerDealCardTimerId As Integer = 2
Const LeftEnemyDealCardTimerId As Integer = 3
' Анимация раздачи колоды
Const BankDealCardTimerId As Integer = 4
' Анимация получения персонажем всей суммы из банка
Const BankDealMoneyTimerId As Integer = 5

' Массив точек для анимации карты игрока
Dim Shared PlayerDealCardAnimationPointStart As Point
Dim Shared PlayerDealCardAnimationCardSortNumber As Integer
Dim Shared PlayerDealCardAnimationCardIncrementX As Integer
Dim Shared PlayerDealCardAnimationCardIncrementY As Integer
Dim Shared PlayerDealCardAnimationPointStartCount As Integer
Dim Shared PlayerDealCardAnimationHDC As HDC
Dim Shared PlayerDealCardAnimationBitmap As HBITMAP
' Анимация выдачи карт
Dim Shared BankDealCardAnimationStartCount As Integer
Dim Shared BankDealCardAnimationCardNumber As Integer


' Ширина и высота карты
Dim Shared mintWidth As Integer
Dim Shared mintHeight As Integer
' Игра идёт
Dim Shared GameIsRunning As Boolean
' Рисование
Dim Shared DarkGreenBrush As HBRUSH
Dim Shared DarkGreenPen As HPEN
Dim Shared DoubleFont As HFONT

' Колода
Dim Shared BankDeck(35) As PlayerCard
' Карты
Dim Shared PlayerDeck(11) As PlayerCard
Dim Shared LeftEnemyDeck(11) As PlayerCard
Dim Shared RightEnemyDeck(11) As PlayerCard
' Деньги
Dim Shared PlayerMoney As Money
Dim Shared LeftEnemyMoney As Money
Dim Shared RightEnemyMoney As Money
Dim Shared BankMoney As Money

' Игрок может щёлкать по своим картам
Dim Shared PlayerCanPlay As Boolean
' Указатель на индекс карты для ввода с клавиатуры
Dim Shared PlayerKeyboardCardNumber As Integer

Sub DrawCharactersPack(ByVal hDC As HDC, ByVal pc As PlayerCard Ptr, ByVal Character As Characters)
	' TODO Пересчёт координат карт при удалении из массива, чтобы не было пустых мест
	' Dim oldFont As HFONT = SelectObject(PlayerDealCardAnimationHDC, DoubleFont)
	' Dim oldColor As Integer = SetTextColor(PlayerDealCardAnimationHDC, &hFFFFFF)
	' Dim BkMode As Integer = SetBkMode(PlayerDealCardAnimationHDC, TRANSPARENT)
	Dim OldPen As HPEN = SelectObject(PlayerDealCardAnimationHDC, DarkGreenPen)
	Dim OldBrush As HBRUSH = SelectObject(PlayerDealCardAnimationHDC, DarkGreenBrush)
	
	' Стереть
	Rectangle(PlayerDealCardAnimationHDC, 0, 0, pc[11].X - pc[0].X + pc[11].Width, pc[11].Y - pc[0].Y + pc[11].Height)
	
	For i As Integer = 0 To 11
		If GameIsRunning Then
			' Нарисовать те, что на руках у персонажей
			If pc[i].IsUsed Then
				If Character = Characters.Player Then
					' Для игрока нарисовать лицевую сторону
					cdtDrawExt(PlayerDealCardAnimationHDC, pc[i].X - pc[0].X, pc[i].Y - pc[0].Y, pc[i].Width, pc[i].Height, pc[i].CardNumber, CardViews.Normal, 0)
				Else
					' Для врагов нарисовать рубашку
					cdtDrawExt(PlayerDealCardAnimationHDC, pc[i].X - pc[0].X, pc[i].Y - pc[0].Y, pc[i].Width, pc[i].Height, Backs.Sky, CardViews.Back, 0)
				End If
			' Else
				' If Character = Characters.Player Then
					' Стереть
					' Rectangle(PlayerDealCardAnimationHDC, pc[i].X - pc[0].X, pc[i].Y - pc[0].Y, pc[i].X - pc[0].X + pc[i].Width, pc[i].Y - pc[0].Y + pc[i].Height)
				' Else
					' Rectangle(PlayerDealCardAnimationHDC, pc[i].X, pc[i].Y, pc[i].X + pc[i].Width, pc[i].Y + pc[i].Height)
				' End If
			End If
		' Else
			' Стереть
			' Rectangle(PlayerDealCardAnimationHDC, pc[i].X, pc[i].Y, pc[i].X + pc[i].Width, pc[i].Y + pc[i].Height)
		End If
	Next
	
	' TODO Нарисовать стрелку, указывающую на карту, которую можно отправить по Enter
	
	SelectObject(PlayerDealCardAnimationHDC, OldBrush)
	SelectObject(PlayerDealCardAnimationHDC, OldPen)
	' SetBkMode(PlayerDealCardAnimationHDC, BkMode)
	' SetTextColor(PlayerDealCardAnimationHDC, oldColor)
	' SelectObject(PlayerDealCardAnimationHDC, oldFont)
	
	' Восстановить изображение из памяти
	BitBlt(hDC, pc[0].X, pc[0].Y, pc[11].X - pc[0].X + pc[11].Width, pc[11].Y - pc[0].Y + pc[11].Height, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
End Sub

Sub DrawBankPack(ByVal hDC As HDC)
	' Нарисовать в памяти
	Dim OldPen As HPEN = SelectObject(PlayerDealCardAnimationHDC, DarkGreenPen)
	Dim OldBrush As HBRUSH = SelectObject(PlayerDealCardAnimationHDC, DarkGreenBrush)
	
	For i As Integer = 0 To 35
		If GameIsRunning Then
			' Нарисовать только те, что лежат на рабочем столе
			If BankDeck(i).IsUsed Then
				cdtDrawExt(PlayerDealCardAnimationHDC, BankDeck(i).X - BankDeck(0).X, BankDeck(i).Y - BankDeck(0).Y, BankDeck(i).Width, BankDeck(i).Height, BankDeck(i).CardNumber, CardViews.Normal, 0)
			Else
				' Для остальных рамки
				Rectangle(PlayerDealCardAnimationHDC, BankDeck(i).X - BankDeck(0).X, BankDeck(i).Y - BankDeck(0).Y, BankDeck(i).X - BankDeck(0).X + BankDeck(i).Width, BankDeck(i).Y - BankDeck(0).Y + BankDeck(i).Height)
			End If
		Else
			' Нарисовать все карты
			cdtDrawExt(PlayerDealCardAnimationHDC, BankDeck(i).X - BankDeck(0).X, BankDeck(i).Y - BankDeck(0).Y, BankDeck(i).Width, BankDeck(i).Height, BankDeck(i).CardNumber, CardViews.Normal, 0)
		End If
	Next
	SelectObject(PlayerDealCardAnimationHDC, OldPen)
	SelectObject(PlayerDealCardAnimationHDC, OldBrush)
	
	' Восстановить изображение из памяти
	BitBlt(hDC, BankDeck(0).X, BankDeck(0).Y, BankDeck(8).X - BankDeck(0).X + BankDeck(8).Width, BankDeck(35).Y - BankDeck(0).Y + BankDeck(35).Height, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
	
End Sub

Sub DrawMoney(ByVal hDC As HDC)
	' Шрифт
	Dim oldFont As HFONT = SelectObject(hDC, DoubleFont)
	Dim oldColor As Integer = SetTextColor(hDC, &hFFFFFF)
	Dim BkMode As Integer = SetBkMode(hDC, TRANSPARENT)
	Dim OldPen As HPEN = SelectObject(hDC, DarkGreenPen)
	Dim OldBrush As HBRUSH = SelectObject(hDC, DarkGreenBrush)
	
	' Деньги игрока, соперников и банка
	
	Dim buffer As WString * 256 = Any
	Dim bufferMoney As WString * 256 = Any
	
	Scope
		itow(PlayerMoney.Value, @bufferMoney, 10)
		lstrcpy(@buffer, @PlayerName)
		lstrcat(@buffer, @bufferMoney)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, PlayerMoney.X, PlayerMoney.Y, PlayerMoney.X + 2 * MoneyTextSize.cx, PlayerMoney.Y + MoneyTextSize.cy)
		
		TextOut(hDC, PlayerMoney.X, PlayerMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		itow(LeftEnemyMoney.Value, @bufferMoney, 10)
		lstrcpy(@buffer, @LeftRightEnemyName)
		lstrcat(@buffer, @bufferMoney)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, LeftEnemyMoney.X, LeftEnemyMoney.Y, LeftEnemyMoney.X + 2 * MoneyTextSize.cx, LeftEnemyMoney.Y + MoneyTextSize.cy)
		
		TextOut(hDC, LeftEnemyMoney.X, LeftEnemyMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		itow(RightEnemyMoney.Value, @bufferMoney, 10)
		lstrcpy(@buffer, @RightEnemyName)
		lstrcat(@buffer, @bufferMoney)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, RightEnemyMoney.X, RightEnemyMoney.Y, RightEnemyMoney.X + 2 * MoneyTextSize.cx, RightEnemyMoney.Y + MoneyTextSize.cy)
		
		TextOut(hDC, RightEnemyMoney.X, RightEnemyMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	Scope
		itow(BankMoney.Value, @bufferMoney, 10)
		lstrcpy(@buffer, @BankName)
		lstrcat(@buffer, @bufferMoney)
		
		Dim MoneyTextSize As SIZE = Any
		GetTextExtentPoint32(hDC, @buffer, lstrlen(@buffer), @MoneyTextSize)
		
		Rectangle(hDC, BankMoney.X, BankMoney.Y, BankMoney.X + 2 * MoneyTextSize.cx, BankMoney.Y + MoneyTextSize.cy)
		
		TextOut(hDC, BankMoney.X, BankMoney.Y, @buffer, lstrlen(@buffer))
	End Scope
	
	' TODO Изображения соперников и банка
	
	' Очистка
	SelectObject(hDC, OldBrush)
	SelectObject(hDC, OldPen)
	SetBkMode(hDC, BkMode)
	SetTextColor(hDC, oldColor)
	SelectObject(hDC, oldFont)
End Sub

Function WndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	Select Case wMsg
		Case WM_CREATE
			' Инициализация случайных чисел
			Dim dtNow As SYSTEMTIME = Any
			GetSystemTime(@dtNow)
			srand(dtNow.wMilliseconds - dtNow.wSecond + dtNow.wMinute + dtNow.wHour)
			
			' Инициализация библиотеки
			cdtInit(@mintWidth, @mintHeight)
			' Размеры карт
			' Dim EnemyCardWidth As Integer = (mintWidth * 2 ) \ 3
			' Dim EnemyCardHeight As Integer = (mintHeight * 2) \ 3
			For i As Integer = 0 To 11
				' Карты игрока
				PlayerDeck(i).Width = mintWidth
				PlayerDeck(i).Height = mintHeight
				' Карты врагов
				LeftEnemyDeck(i).Width = mintWidth
				LeftEnemyDeck(i).Height = mintHeight
				RightEnemyDeck(i).Width = mintWidth
				RightEnemyDeck(i).Height = mintHeight
				' Игровое поле
				BankDeck(i).Width = mintWidth
				BankDeck(i).Height = mintHeight
				' Карта лежит на рабочем столе
				BankDeck(i).IsUsed = True
				BankDeck(i).CardNumber = GetCardNumber(i)
				BankDeck(i).CardSortNumber = i
			Next
			For i As Integer = 12 To 35
				BankDeck(i).Width = mintWidth
				BankDeck(i).Height = mintHeight
				BankDeck(i).IsUsed = True
				BankDeck(i).CardNumber = GetCardNumber(i)
				BankDeck(i).CardSortNumber = i
			Next
			
			' Объекты GDI
			DarkGreenBrush = CreateSolidBrush(DarkGreenColor)
			DarkGreenPen = CreatePen(PS_SOLID, 1, DarkGreenColor)
			' Шрифт
			Dim hDefaultFont As HFONT = GetStockObject(DEFAULT_GUI_FONT)
			Dim oFont As LOGFONT = Any
			GetObject(hDefaultFont, SizeOf(LOGFONT), @oFont)
			oFont.lfHeight = oFont.lfHeight * 3 - oFont.lfHeight \ 2
			DoubleFont = CreateFontIndirect(@oFont)
			
			PlayerDealCardAnimationHDC = CreateCompatibleDC(0)
			If PlayerDealCardAnimationHDC = 0 Then
				' MessageBox(hWin, @"Не могу создать контекст устройства", @"Девятка", MB_ICONINFORMATION)
			End If
			
			Dim hDCmem As HDC = GetDC(hWin)
			PlayerDealCardAnimationBitmap = CreateCompatibleBitmap(hDCmem,  GetDeviceCaps(PlayerDealCardAnimationHDC, HORZRES),  GetDeviceCaps(PlayerDealCardAnimationHDC, VERTRES))
			
			If PlayerDealCardAnimationBitmap = 0 Then
				' MessageBox(hWin, @"Не могу создать изображение", @"Девятка", MB_ICONINFORMATION)
			End If
			If SelectObject(PlayerDealCardAnimationHDC, PlayerDealCardAnimationBitmap) = 0 Then
				' MessageBox(hWin, @"Не могу выбрать изображение", @"Девятка", MB_ICONINFORMATION)
			End If
			If DeleteDC(hDCmem) = 0 Then
				' MessageBox(hWin, @"Не могу удалить контекст", @"Девятка", MB_ICONINFORMATION)
			End If
			
		Case WM_COMMAND
			' События от нажатий кнопок и меню
			Select Case HiWord(wParam)
				Case BN_CLICKED, 1
					Select Case LoWord(wParam)
						Case IDM_GAME_NEW
							' Новая игра
							If GameIsRunning Then
								' Игра идёт
								' Спросить у пользователя
								' желает ли он прервать текущую игру
								' Dim WarningMsg As WString *256
								' LoadString(hInst, IDS_NEWGAMEWARNING, WarningMsg, 256)
								Dim intResult As Integer = MessageBox(hWin, "Игра уже идёт. Точно остановить?", "Девятка", MB_YESNO + MB_ICONEXCLAMATION + MB_DEFBUTTON2)
								If intResult = IDYES Then
									' Начинаем заново
									PostMessage(hWin, PM_NEWGAME, 0, 0)
								End If
							Else
								PostMessage(hWin, PM_NEWGAME, 0, 0)
							End If
							
						Case IDM_GAME_NEW_NETWORK
							' TODO Сделать сетевой режим
							
						Case IDM_FILE_EXIT
							' Выход
							DestroyWindow(hWin)
							
						Case IDM_HELP_CONTENTS
							' Справка - содержание
							
						Case IDM_HELP_ABOUT
							' Сообщение "О программе"
							' Dim AboutMsg As WString *256
							' LoadString(hInst, IDS_ABOUT, AboutMsg, 256)
							' О программе
							' MessageBox(hWin, AboutMsg, strTitle, MB_OK + MB_ICONINFORMATION)
							
					End Select
			End Select
			
		Case WM_LBUTTONDOWN
			If PlayerCanPlay Then
				' Получить номер карты, на который щёлкнул пользователь
				Dim CardNumber As Integer = GetClickPlayerCardNumber(@PlayerDeck(0), GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam))
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
			
		Case WM_KEYDOWN
			' Выбрать карту
			Select Case wParam
				Case VK_LEFT
					' TODO Установить номер на ближайшую левую карту
					' Перерисовать стрелку‐указатель
					' PlayerKeyboardCardNumber -= 1
					
				Case VK_RIGHT
					' TODO Установить номер на ближайшую правую карту
					' Перерисовать стрелку‐указатель
					' PlayerKeyboardCardNumber += 1
					
				Case VK_RETURN
					' Проверить правильность хода пользователя
					If ValidatePlayerCardNumber(PlayerDeck(PlayerKeyboardCardNumber).CardSortNumber, @BankDeck(0)) Then
						' Запретить ходить пользователю
						PlayerCanPlay = False
						' Ходить
						PostMessage(hWin, PM_USERATTACK, PlayerKeyboardCardNumber, True)
					End If
			End Select
			
		Case WM_TIMER
			' Анимация
			Select Case wParam
				Case LeftEnemyDealCardTimerId, PlayerDealCardTimerId, RightEnemyDealCardTimerId
					' Анимация передвижения карты
					
					Dim hDC As HDC = GetDC(hWin)
					
					Select Case PlayerDealCardAnimationPointStartCount
						Case 0
							PlayerDealCardAnimationPointStartCount = 1
							' Положить в память старое изображение
							BitBlt(PlayerDealCardAnimationHDC, 0, 0, mintWidth, mintHeight, hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, SRCCOPY)
						Case 1
							' Восстановить изображение из памяти
							BitBlt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, mintWidth, mintHeight, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
							
							' Если координата X больше, то увеличить
							If BankDeck(PlayerDealCardAnimationCardSortNumber).X > PlayerDealCardAnimationPointStart.X Then
								PlayerDealCardAnimationPointStart.X += PlayerDealCardAnimationCardIncrementX
							Else
								' Иначе уменьшить
								PlayerDealCardAnimationPointStart.X -= PlayerDealCardAnimationCardIncrementX
							End If
							' Если коордитата Y больше, то уменьшить
							If BankDeck(PlayerDealCardAnimationCardSortNumber).Y > PlayerDealCardAnimationPointStart.Y Then
								PlayerDealCardAnimationPointStart.Y += PlayerDealCardAnimationCardIncrementY
							Else
								' Иначе увеличить
								PlayerDealCardAnimationPointStart.Y -= PlayerDealCardAnimationCardIncrementY
							End If
							' Поместить в память изображение взяв оттуда где будет новое
							BitBlt(PlayerDealCardAnimationHDC, 0, 0, mintWidth, mintHeight, hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, SRCCOPY)
							' Нарисовать новое
							cdtDrawExt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, mintWidth, mintHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
							
							Dim dx As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDealCardAnimationPointStart.X)
							Dim dy As Integer = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDealCardAnimationPointStart.Y)
							If dx < Abs(PlayerDealCardAnimationCardIncrementX) OrElse dy < Abs(PlayerDealCardAnimationCardIncrementY) Then
								' Как только будет достигнута последняя точка, то остановить таймер
								PlayerDealCardAnimationPointStartCount = 2
							End If
						Case 2
							KillTimer(hWin, wParam)
							PlayerDealCardAnimationPointStartCount = 0
							' Восстановить изображение из памяти
							BitBlt(hDC, PlayerDealCardAnimationPointStart.X, PlayerDealCardAnimationPointStart.Y, mintWidth, mintHeight, PlayerDealCardAnimationHDC, 0, 0, SRCCOPY)
							
							' Сделать карту видимой на поле
							BankDeck(PlayerDealCardAnimationCardSortNumber).IsUsed = True
							
							' Нарисовать карту
							cdtDrawExt(hDC, BankDeck(PlayerDealCardAnimationCardSortNumber).X, BankDeck(PlayerDealCardAnimationCardSortNumber).Y, mintWidth, mintHeight, BankDeck(PlayerDealCardAnimationCardSortNumber).CardNumber, CardViews.Normal, 0)
							
							' Передать ход следующему игроку
							Select Case wParam
								Case RightEnemyDealCardTimerId
									' Если на руках карт нет, то победа
									If IsPlayerWin(@RightEnemyDeck(0)) Then
										PostMessage(hWin, PM_WIN, 0, Characters.RightCharacter)
									Else
										' Передать ход игроку
										PostMessage(hWin, PM_USERATTACK, 0, 0)
									End If
								Case PlayerDealCardTimerId
									' Если карт больше нет, то это победа
									If IsPlayerWin(@PlayerDeck(0)) Then
										' Победа
										PostMessage(hWin, PM_WIN, 0, Characters.Player)
									Else
										' Передать ход левому врагу
										PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
									End If
								Case LeftEnemyDealCardTimerId
									' Если на руках карт нет, то победа
									If IsPlayerWin(@LeftEnemyDeck(0)) Then
										' Победа
										PostMessage(hWin, PM_WIN, 0, Characters.LeftCharacter)
									Else
										' Передать ход правому врагу
										PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
									End If
							End Select
					End Select
					
					ReleaseDC(hWin, hDC)
					
				Case BankDealCardTimerId
					' Анимация раздачи колоды
					Select Case BankDealCardAnimationStartCount
						Case 0
							' Колода исчезает
							Scope
								Dim hDC As HDC = GetDC(hWin)
								Dim OldPen As HPEN = SelectObject(hDC, DarkGreenPen)
								Dim OldBrush As HBRUSH = SelectObject(hDC, DarkGreenBrush)
								
								Rectangle(hDC, BankDeck(BankDealCardAnimationCardNumber).X, BankDeck(BankDealCardAnimationCardNumber).Y, BankDeck(BankDealCardAnimationCardNumber).X + BankDeck(BankDealCardAnimationCardNumber).Width, BankDeck(BankDealCardAnimationCardNumber).Y + BankDeck(BankDealCardAnimationCardNumber).Height)
								
								SelectObject(hDC, OldPen)
								SelectObject(hDC, OldBrush)
								ReleaseDC(hWin, hDC)
							End Scope
							' Увеличить счётчик
							' Если вышли за границу, то перейти к следующему этапу анимации
							BankDealCardAnimationCardNumber += 1
							If BankDealCardAnimationCardNumber = 36 Then
								BankDealCardAnimationCardNumber = 0
								BankDealCardAnimationStartCount = 1
							End If
						Case 1
							' Появляются карты у правого персонажа
							Scope
								Dim hDC As HDC = GetDC(hWin)
								
								cdtDrawExt(hDC, RightEnemyDeck(BankDealCardAnimationCardNumber).X, RightEnemyDeck(BankDealCardAnimationCardNumber).Y, RightEnemyDeck(BankDealCardAnimationCardNumber).Width, RightEnemyDeck(BankDealCardAnimationCardNumber).Height, Backs.Sky, CardViews.Back, 0)
								
								ReleaseDC(hWin, hDC)
							End Scope
							BankDealCardAnimationCardNumber += 1
							If BankDealCardAnimationCardNumber = 12 Then
								BankDealCardAnimationCardNumber = 11
								BankDealCardAnimationStartCount = 2
							End If
						Case 2
							' Повляются карты у игрока
							Scope
								Dim hDC As HDC = GetDC(hWin)
								
								cdtDrawExt(hDC, PlayerDeck(BankDealCardAnimationCardNumber).X, PlayerDeck(BankDealCardAnimationCardNumber).Y, PlayerDeck(BankDealCardAnimationCardNumber).Width, PlayerDeck(BankDealCardAnimationCardNumber).Height, PlayerDeck(BankDealCardAnimationCardNumber).CardNumber, CardViews.Normal, 0)
								
								ReleaseDC(hWin, hDC)
							End Scope
							BankDealCardAnimationCardNumber -= 1
							If BankDealCardAnimationCardNumber = -1 Then
								BankDealCardAnimationCardNumber = 0
								BankDealCardAnimationStartCount = 3
							End If
						Case 3
							' Появляются карты у левого персонажа
							Scope
								Dim hDC As HDC = GetDC(hWin)
								
								cdtDrawExt(hDC, LeftEnemyDeck(BankDealCardAnimationCardNumber).X, LeftEnemyDeck(BankDealCardAnimationCardNumber).Y, LeftEnemyDeck(BankDealCardAnimationCardNumber).Width, LeftEnemyDeck(BankDealCardAnimationCardNumber).Height, Backs.Sky, CardViews.Back, 0)
								
								ReleaseDC(hWin, hDC)
							End Scope
							BankDealCardAnimationCardNumber += 1
							If BankDealCardAnimationCardNumber = 12 Then
								BankDealCardAnimationCardNumber = 0
								BankDealCardAnimationStartCount = 4
							End If
						Case 4
							' Закончилось
							KillTimer(hWin, wParam)
							BankDealCardAnimationStartCount = 0
							
							' Найти того, у кого девятка бубен и сделать сделать его ход
							Dim cn As CharacterWithNine = GetNinePlayerNumber(@RightEnemyDeck(0), @PlayerDeck(0), @LeftEnemyDeck(0))
							Select Case cn.Char
								Case Characters.RightCharacter
									PostMessage(hWin, PM_RENEMYATTACK, cn.NineIndex, True)
								Case Characters.Player
									PostMessage(hWin, PM_USERATTACK, cn.NineIndex, True)
								Case Characters.LeftCharacter
									PostMessage(hWin, PM_LENEMYATTACK, cn.NineIndex, True)
							End Select
					End Select
			End Select
			
		Case WM_PAINT
			Dim ClientRectangle As RECT = Any
			GetClientRect(hWin, @ClientRectangle)
			
			' Рисуем игровое поле
			Dim pnt As PAINTSTRUCT = Any
			Dim hDC As HDC = BeginPaint(hWin, @pnt)
			
			' Закрасить рабочий стол зелёным цветом
			Dim oldBrush As HBRUSH = SelectObject(hDC, DarkGreenBrush)
			Dim oldPen As HPEN = SelectObject(hDC, DarkGreenPen)
			ExtFloodFill(hDC, 0, 0, &h004000, FLOODFILLBORDER)
			
			' Карты игрока и врагов
			DrawCharactersPack(hDC, @RightEnemyDeck(0), Characters.RightCharacter)
			DrawCharactersPack(hDC, @PlayerDeck(0), Characters.Player)
			DrawCharactersPack(hDC, @LeftEnemyDeck(0), Characters.LeftCharacter)
			' Рабочий стол
			DrawBankPack(hDC)
			
			' Деньги
			DrawMoney(hDC)
			
			' Очистка
			SelectObject(hDC, oldPen)
			SelectObject(hDC, oldBrush)
			EndPaint(hWin, @pnt)
			
		Case WM_SIZE
			' Изменение размеров окна, пересчитать координаты карт
			
			' Центр клиентской области
			Dim ClientRectangle As RECT = Any
			GetClientRect(hWin, @ClientRectangle)
			Dim cx As Integer = ClientRectangle.right \ 2
			Dim cy As Integer = ClientRectangle.bottom \ 2
			
			Scope
				' Карты банка
				' Смещение относительно центра клиентской области для центрирования карт
				Dim dx As Integer = cx - (mintWidth * 9) \ 2
				Dim dy As Integer = mintHeight
				
				For k As Integer = 0 To 3
					For j As Integer = 0 To 8
						Dim i As Integer = k * 9 + j
						BankDeck(i).X = j * mintWidth + dx
						BankDeck(i).Y = k * mintHeight + dy
					Next
				Next
				' Деньги банка
				BankMoney.X = cx
				BankMoney.Y = mintHeight \ 2
			End Scope
			
			Scope
				' Карты игрока
				Dim dxPlayer As Integer = cx - (mintWidth * 12) \ 2
				Dim dyPlayer As Integer = mintHeight * 6 - mintHeight \ 3
				For i As Integer = 0 To 11
					PlayerDeck(i).X = i * mintWidth + dxPlayer
					PlayerDeck(i).Y = dyPlayer
				Next
				' Деньги игрока
				PlayerMoney.X = cx
				PlayerMoney.Y = mintHeight * 6 - 2 * mintHeight \ 3
			End Scope
			
			Scope
				' Карты левого врага
				Dim dxEnemyLeft As Integer = cx - (mintWidth * 9) \ 2 - mintWidth - mintWidth \ 2
				Dim dyEnemyLeft As Integer = mintHeight - mintHeight \ 3
				For i As Integer = 0 To 11
					LeftEnemyDeck(i).X = dxEnemyLeft
					LeftEnemyDeck(i).Y = i * (mintHeight \ 3) + dyEnemyLeft
				Next
				' Деньги левого врага
				LeftEnemyMoney.X = dxEnemyLeft
				LeftEnemyMoney.Y = mintHeight \ 3
			End Scope
			
			Scope
				' Карты правого врага
				Dim dxEnemyRight As Integer = cx + (mintWidth * 9) \ 2 + mintWidth \ 2
				Dim dyEnemyRight As Integer = mintHeight - mintHeight \ 3
				For i As Integer = 0 To 11
					RightEnemyDeck(i).X = dxEnemyRight
					RightEnemyDeck(i).Y = i * (mintHeight \ 3) + dyEnemyRight
				Next
				' Деньги правого врага
				RightEnemyMoney.X = dxEnemyRight
				RightEnemyMoney.Y = mintHeight \ 3
			End Scope
			
		Case WM_CLOSE
			' Пользователь пытается закрыть окно
			' Если игра уже идёт, то спросить
			DestroyWindow(hWin)
			
		Case WM_DESTROY
			' Очистка
			DeleteObject(DoubleFont)
			If DeleteObject(PlayerDealCardAnimationBitmap) = 0 Then
				MessageBox(hWin, @"Не могу удалить картинку", @"Девятка", MB_ICONINFORMATION)
			End If
			If DeleteDC(PlayerDealCardAnimationHDC) = 0 Then
				MessageBox(hWin, @"Не могу удалить устройство рисования", @"Девятка", MB_ICONINFORMATION)
			End If
			If DeleteObject(DarkGreenPen) = 0 Then
				' MessageBox(hWin, @"Не могу удалить перо", @"Девятка", MB_ICONINFORMATION)
			End If
			If DeleteObject(DarkGreenBrush) = 0 Then
				' MessageBox(hWin, @"Не могу удалить кисть", @"Девятка", MB_ICONINFORMATION)
			End If
			cdtTerm()
			' Окно уничтожается
			PostQuitMessage(0)
			
		Case PM_NEWGAME
			' Начинаем новую игру
			GameIsRunning = True
			
			' Событие восстановления суммы денег
			SendMessage(hWin, PM_DEFAULTMONEY, 0, 0)
			
			' Начать новый раунд
			PostMessage(hWin, PM_NEWSTAGE, 0, 0)
			
		Case PM_NEWSTAGE
			' Новый раунд игры
			
			PlayerKeyboardCardNumber = 0
			
			If PlayerMoney.Value <= 0 Then
				' Проигрыш
				' TODO Анимация проигрыша
				GameIsRunning = False
			Else
				' Событие взятия суммы у игроков
				SendMessage(hWin, PM_DEALMONEY, 0, 0)
				
				' Событие раздачи колоды карт игрокам
				PostMessage(hWin, PM_DEALPACK, 0, 0)
				
			End If
			
		Case PM_DEFAULTMONEY
			' Событие восстановления денег
			' TODO Анимация восстановления денег
			PlayerMoney.Value = DefaultMoney
			LeftEnemyMoney.Value = DefaultMoney
			RightEnemyMoney.Value = DefaultMoney
			BankMoney.Value = 0
			
			Scope
				Dim hDC As HDC = GetDC(hWin)
				DrawMoney(hDC)
				ReleaseDC(hWin, hDC)
			End Scope
			
		Case PM_DEALMONEY
			' Взятие денег у персонажей
			' TODO Анимация взятия денег у игроков
			' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
			
			PlayerMoney.Value -= ZZZMoney
			LeftEnemyMoney.Value -= ZZZMoney
			RightEnemyMoney.Value -= ZZZMoney
			BankMoney.Value = 3 * ZZZMoney
			
			Scope
				Dim hDC As HDC = GetDC(hWin)
				DrawMoney(hDC)
				ReleaseDC(hWin, hDC)
			End Scope
			
		Case PM_DEALPACK
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
			For i As Integer = 0 To 35
				BankDeck(i).IsUsed = False
			Next
			
			' Сортировать карты по мастям по старшинству
			SortCharacterPack(@RightEnemyDeck(0))
			SortCharacterPack(@PlayerDeck(0))
			SortCharacterPack(@LeftEnemyDeck(0))
			
			' Анимация раздачи колоды
			SetTimer(hWin, BankDealCardTimerId, TimerElapsedTimeDealPack, NULL)
			
		Case PM_RENEMYATTACK
			' Ход правого врага
			If lParam = False Then
				' Номер карты определить самостоятельно
				Dim CardIndex As Integer = GetPlayerDealCard(@RightEnemyDeck(0), @BankDeck(0))
				If CardIndex >= 0 Then
					wParam = CardIndex
					lParam = True
				End If
			End If
			If lParam Then
				' В параметре wParam номер карты
				' Отправить карту на поле
				PostMessage(hWin, PM_DEALCARD, wParam, Characters.RightCharacter)
			Else
				' Правый враг не может ходить
				' MessageBox(hWin, @"Правый враг не может ходить", @"Девятка", MB_ICONINFORMATION)
				SendMessage(hWin, PM_FOOL, 0, Characters.RightCharacter)
				' Передать ход игроку
				PostMessage(hWin, PM_USERATTACK, 0, 0)
			End If
			
		Case PM_USERATTACK
			' Ход игрока
			If lParam Then
				' Ходить указанной картой
				PostMessage(hWin, PM_DEALCARD, wParam, Characters.Player)
			Else
				' Проверить, может ли игрок ходить
				If GetPlayerDealCard(@PlayerDeck(0), @BankDeck(0)) >= 0 Then
					PlayerCanPlay = True
				Else
					' У пользователя нет карт для хода
					' MessageBox(hWin, @"Игрок не может ходить", @"Девятка", MB_ICONINFORMATION)
					SendMessage(hWin, PM_FOOL, 0, Characters.Player)
					' Передать ход левому игроку
					PostMessage(hWin, PM_LENEMYATTACK, 0, 0)
				End If
			End If
			
		Case PM_LENEMYATTACK
			' Ход левого врага
			If lParam = False Then
				' Определить номер карты, которой можно ходить
				Dim CardIndex As Integer = GetPlayerDealCard(@LeftEnemyDeck(0), @BankDeck(0))
				If CardIndex >= 0 Then
					' MessageBox(hWin, @"Номер карты положительный", @"Девятка", MB_ICONINFORMATION)
					wParam = CardIndex
					lParam = True
				Else
					lParam = False
				End If
			End If
			If lParam Then
				' В параметре wParam номер карты
				' Отправить карту на поле
				PostMessage(hWin, PM_DEALCARD, wParam, Characters.LeftCharacter)
			Else
				' Левый враг не может ходить
				' MessageBox(hWin, @"Левый враг не может ходить", @"Девятка", MB_ICONINFORMATION)
				SendMessage(hWin, PM_FOOL, 0, Characters.LeftCharacter)
				' Передать правому врагу
				PostMessage(hWin, PM_RENEMYATTACK, 0, 0)
			End If
			
		Case PM_FOOL
			' Взятие денег у игрока при отсутствии карты для хода
			' TODO Анимация взятия денег
			' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
			Select Case lParam
				Case Characters.RightCharacter
					RightEnemyMoney.Value -= FFFMoney
				Case Characters.Player
					PlayerMoney.Value -= FFFMoney
				Case Characters.LeftCharacter
					LeftEnemyMoney.Value -= FFFMoney
			End Select
			BankMoney.Value += FFFMoney
			
			Scope
				Dim hDC As HDC = GetDC(hWin)
				DrawMoney(hDC)
				ReleaseDC(hWin, hDC)
			End Scope
			
		Case PM_WIN
			' Игрок положил последнюю карту
			' TODO Анимация игрок забирает все деньги банка
			' BankDealMoneyTimerId
			' RedrawWindow(hWin, NULL, NULL, RDW_INVALIDATE)
			Select Case lParam
				Case Characters.RightCharacter
					RightEnemyMoney.Value += BankMoney.Value
				Case Characters.Player
					PlayerMoney.Value += BankMoney.Value
				Case Characters.LeftCharacter
					LeftEnemyMoney.Value += BankMoney.Value
			End Select
			BankMoney.Value = 0
			
			Scope
				Dim hDC As HDC = GetDC(hWin)
				DrawMoney(hDC)
				ReleaseDC(hWin, hDC)
			End Scope
			
			' Начать новый раунд
			PostMessage(hWin, PM_NEWSTAGE, 0, 0)
			
		Case PM_DEALCARD
			' Игрок кидает карту на поле
			' wParam содержит индекс в массиве карт
			
			' Перерисовка колоды пользователя
			Dim hDC As HDC = GetDC(hWin)
			
			Select Case lParam
				Case Characters.RightCharacter
					' Удалить карту из массива
					RightEnemyDeck(wParam).IsUsed = False
					DrawCharactersPack(hDC, @RightEnemyDeck(0), Characters.RightCharacter)
					
					' Начальная и конечная точки
					PlayerDealCardAnimationPointStart.X = RightEnemyDeck(wParam).X
					PlayerDealCardAnimationPointStart.Y = RightEnemyDeck(wParam).Y
					PlayerDealCardAnimationCardSortNumber = RightEnemyDeck(wParam).CardSortNumber
					
					' Приращение аргумента
					PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - RightEnemyDeck(wParam).X) \ DealCardAnimationPartsCount
					PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - RightEnemyDeck(wParam).Y) \ DealCardAnimationPartsCount
					
					' Запустить таймер
					SetTimer(hWin, RightEnemyDealCardTimerId, TimerElapsedTime, NULL)
					
				Case Characters.Player
					' Удалить карту из массива
					PlayerDeck(wParam).IsUsed = False
					DrawCharactersPack(hDC, @PlayerDeck(0), Characters.Player)
					
					' Начальная и конечная точки
					PlayerDealCardAnimationPointStart.X = PlayerDeck(wParam).X
					PlayerDealCardAnimationPointStart.Y = PlayerDeck(wParam).Y
					PlayerDealCardAnimationCardSortNumber = PlayerDeck(wParam).CardSortNumber
					
					' Приращение аргумента
					PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - PlayerDeck(wParam).X) \ DealCardAnimationPartsCount
					PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - PlayerDeck(wParam).Y) \ DealCardAnimationPartsCount
					
					' Запустить таймер
					SetTimer(hWin, PlayerDealCardTimerId, TimerElapsedTime, NULL)
					
				Case Characters.LeftCharacter
					' Удалить карту из массива
					LeftEnemyDeck(wParam).IsUsed = False
					DrawCharactersPack(hDC, @LeftEnemyDeck(0), Characters.LeftCharacter)
					
					' Начальная и конечная точки
					PlayerDealCardAnimationPointStart.X = LeftEnemyDeck(wParam).X
					PlayerDealCardAnimationPointStart.Y = LeftEnemyDeck(wParam).Y
					PlayerDealCardAnimationCardSortNumber = LeftEnemyDeck(wParam).CardSortNumber
					
					' Приращение аргумента
					PlayerDealCardAnimationCardIncrementX = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).X - LeftEnemyDeck(wParam).X) \ DealCardAnimationPartsCount
					PlayerDealCardAnimationCardIncrementY = Abs(BankDeck(PlayerDealCardAnimationCardSortNumber).Y - LeftEnemyDeck(wParam).Y) \ DealCardAnimationPartsCount
					
					' Запустить таймер
					SetTimer(hWin, LeftEnemyDealCardTimerId, TimerElapsedTime, NULL)
					
			End Select
			ReleaseDC(hWin, hDC)
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)    
	End Select
	Return 0
End Function
