#ifndef PLAYERCARD_BI
#define PLAYERCARD_BI

' Игроки
Enum Characters
	RightCharacter
	Player
	LeftCharacter
End Enum

' Ирок с индексом девятки в массиве
Type CharacterWithNine
	Dim Character As Characters
	Dim NineIndex As Integer
End Type

' Карта игрока
Type PlayerCard
	' Карта используется
	Dim IsUsed As Boolean
	
	' Номер карты для рисования
	Dim CardNumber As Integer
	
	' Порядковый номер карты для сортировки
	' Шестёрки самые младшие, тузы самые старшие
	Dim CardSortNumber As Integer
End Type

' Деньги
Type Money
	Const MaxCharacterNameLength As Integer = 511
	
	Dim CharacterName As WString * (MaxCharacterNameLength + 1)
	Dim Value As Integer
	
End Type

' Возвращает номер карты из массива, которую можно положить на стол
' pc — массив карт игрока
' bc — массив карт на столе
Declare Function GetPlayerDealCard( _
	ByVal pc as PlayerCard Ptr, _
	ByVal bp As PlayerCard Ptr _
)As Integer

' Создание и перемешивание массива
Declare Sub ShuffleArray( _
	ByVal a As Integer Ptr, _
	ByVal length As Integer _
)

Declare Sub BubbleSortArray( _
	ByVal a As Integer Ptr, _
	ByVal length As Integer _
)

' Возвращает номер карты для отображения
Declare Function GetCardNumber( _
	ByVal CardSortNumber As Integer _
)As Integer

' Возвращает порядковый номер карты
Declare Function GetClickPlayerCardNumber( _
	ByVal pc As PlayerCard Ptr, _
	ByVal X As Integer, _
	ByVal Y As Integer _
)As Integer

' Персонаж выиграл
Declare Function IsPlayerWin( _
	ByVal pc As PlayerCard Ptr _
)As Boolean

' Возвращает персонажа, у которого девятка бубен
Declare Function GetNinePlayerNumber( _
	ByVal RightDeck As PlayerCard Ptr, _
	ByVal PlayerDeck As PlayerCard Ptr, _
	ByVal LeftDeck As PlayerCard Ptr _
)As CharacterWithNine

' Проверяет правильность выбора карты пользователем
Declare Function ValidatePlayerCardNumber( _
	ByVal PlayerCardSortNumber As Integer, _
	ByVal bp As PlayerCard Ptr _
)As Boolean

#endif
