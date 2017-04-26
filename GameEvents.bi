#ifndef unicode
#define unicode
#endif

#include once "windows.bi"

' События игры

' Подготовка к игре
Const PM_NEWGAME As UINT = WM_USER + 0

' Установка денег в начальное положение
Const PM_DEFAULTMONEY As UINT = WM_USER + 1

' Взятие суммы у игроков
Const PM_DEALMONEY As UINT = WM_USER + 2

' Раздача колоды карт игрокам
Const PM_DEALPACK As UINT = WM_USER + 3

' Ход правого врага
' wParam — номер карты в массиве
' lParam — True если используется карта в массиве
Const PM_RENEMYATTACK As UINT = WM_USER + 4

' Ход левого врага
' wParam — номер карты в массиве
' lParam — True если используется карта в массиве
Const PM_LENEMYATTACK As UINT = WM_USER + 5

' Ход игрока
' wParam — номер карты в массиве
' lParam — True если используется карта в массиве
Const PM_USERATTACK As UINT = WM_USER + 6

' Взятие денег у игрока при отсутствии карты для хода
' lParam — номер игрока, Characters.RightCharacter, Characters.Player, Characters.LeftCharacter
Const PM_FOOL As UINT = WM_USER + 9

' Персонаж положил последнюю карту
' lParam — номер игрока, Characters.RightCharacter, Characters.Player, Characters.LeftCharacter
Const PM_WIN As UINT = WM_USER + 12

' Персонаж кидает карту на поле
' wParam — номер карты в массиве
' lParam — номер игрока, Characters.RightCharacter, Characters.Player, Characters.LeftCharacter
Const PM_DEALCARD As UINT = WM_USER + 18

' Новый тур игры
Const PM_NEWSTAGE As UINT = WM_USER + 19
