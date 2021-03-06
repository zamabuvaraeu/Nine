#include "MainFormWndProc.bi"
#include "MainFormEvents.bi"
#include "Resources.RH"
#include "MainForm.bi"

#include "SimpleDebug.bi"

Const BackColor As Integer = &h006400

Common Shared OldRightEnemyGroupBoxProc As WndProc
Common Shared OldUserGroupBoxProc As WndProc
Common Shared OldLeftEnemyGroupBoxProc As WndProc
Common Shared OldBankGroupBoxProc As WndProc

Dim Shared BackColorBrush As HBRUSH

Sub EraseBackGround(ByVal hWin As HWND, ByVal hDCGroupBox As HDC)
	
	Dim rcClient As RECT = Any
	GetwindowRect(hWin, @rcClient)
	
	rcClient.right -= rcClient.left
	rcClient.bottom -= rcClient.top
	rcClient.left = 0
	rcClient.top = 0
	
	FillRect(hDCGroupBox, @rcClient, BackColorBrush)
	
End Sub

Function RightEnemyGroupBoxProc(ByVal hwndGroupBox As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_ERASEBKGND
			EraseBackGround(hwndGroupBox, Cast(HDC, wParam))
			Return 1
			
		Case WM_COMMAND
			CallWindowProc(@MainFormWndProc, GetParent(hwndGroupBox), wMsg, wParam, lParam)
			
		Case Else
			Return CallWindowProc(OldRightEnemyGroupBoxProc, hwndGroupBox, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Function UserGroupBoxProc(ByVal hwndGroupBox As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_ERASEBKGND
			EraseBackGround(hwndGroupBox, Cast(HDC, wParam))
			Return 1
			
		Case WM_COMMAND
			CallWindowProc(@MainFormWndProc, GetParent(hwndGroupBox), wMsg, wParam, lParam)
			
		Case Else
			Return CallWindowProc(OldUserGroupBoxProc, hwndGroupBox, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Function LeftEnemyGroupBoxProc(ByVal hwndGroupBox As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_ERASEBKGND
			EraseBackGround(hwndGroupBox, Cast(HDC, wParam))
			Return 1
			
		Case WM_COMMAND
			CallWindowProc(@MainFormWndProc, GetParent(hwndGroupBox), wMsg, wParam, lParam)
			
		Case Else
			Return CallWindowProc(OldLeftEnemyGroupBoxProc, hwndGroupBox, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Function BankGroupBoxProc(ByVal hwndGroupBox As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_ERASEBKGND	
			EraseBackGround(hwndGroupBox, Cast(HDC, wParam))
			Return 1
			
		Case WM_COMMAND
			CallWindowProc(@MainFormWndProc, GetParent(hwndGroupBox), wMsg, wParam, lParam)
			
		Case Else
			Return CallWindowProc(OldBankGroupBoxProc, hwndGroupBox, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Function MainFormWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			BackColorBrush = CreateSolidBrush(BackColor)
			MainForm_Load(hWin, wParam, lParam)
			
		Case WM_COMMAND
			
			' DebugMessageBoxValue(LoWord(wParam), "Дочернее окно")
			
			Select Case HiWord(wParam)
				
				Case 0 ' Меню или кнопка
					
					Select Case LoWord(wParam)
						
						Case IDM_GAME_NEW
							MainFormMenuNewGame_Click(hWin)
							
						Case IDM_GAME_NEW_AI
							MainFormMenuNewAIGame_Click(hWin)
							
						Case IDM_GAME_NEW_NETWORK
							MainFormMenuNewNetworkGame_Click(hWin)
							
						Case IDM_GAME_STATISTICS
							MainFormMenuStatistics_Click(hWin)
							
						Case IDM_GAME_SETTINGS
						Case IDM_GAME_UNDO
							
						Case IDM_FILE_EXIT
							MainFormMenuFileExit_Click(hWin)
							
						Case IDM_HELP_CONTENTS
							MainFormMenuHelpContents_Click(hWin)
							
						Case IDM_HELP_ABOUT
							MainFormMenuHelpAbout_Click(hWin)
							
						Case IDC_RIGHTENEMY_CARD_01 To IDC_RIGHTENEMY_CARD_01 + 12
							
						Case IDC_PLAING_CARD_01 To IDC_PLAING_CARD_01 + 12
							PlayerCard_Click(hWin, LoWord(wParam), Cast(HWND, lParam))
							
						Case IDC_LEFTENEMY_CARD_01 To IDC_LEFTENEMY_CARD_01 + 12
							
						Case IDC_BANK_CARD_01 To IDC_BANK_CARD_01 + 36
							
					End Select
					
				Case 1 ' Акселератор
					
					Select Case LoWord(wParam)
						
						Case IDM_GAME_NEW_ACS
							MainFormMenuNewGame_Click(hWin)
							
						Case IDM_GAME_NEW_AI_ACS
							MainFormMenuNewAIGame_Click(hWin)
							
						Case IDM_GAME_NEW_NETWORK_ACS
							MainFormMenuNewNetworkGame_Click(hWin)
							
						Case IDM_GAME_STATISTICS_ACS
							MainFormMenuStatistics_Click(hWin)
							
						Case IDM_GAME_SETTINGS_ACS
						Case IDM_GAME_UNDO_ACS
							
					End Select
					
				' Case Else ' Элемент управления
					
					
			End Select
			
			
		' Case WM_LBUTTONDOWN
			' MainForm_LeftMouseDown(hWin, wParam, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam))
			
		' Case WM_KEYDOWN
			' MainForm_KeyDown(hWin, wParam)
			
		' Case WM_TIMER
			
			' Select Case wParam
				
				' Case RightEnemyDealCardTimer
					' RightEnemyDealCardTimer_Tick(hWin)
					
				' Case PlayerDealCardTimer
					' PlayerDealCardTimer_Tick(hWin)
					
				' Case LeftEnemyDealCardTimer
					' LeftEnemyDealCardTimer_Tick(hWin)
					
				' Case BankDealPackTimer
					' BankDealPackTimer_Tick(hWin)
					
				' Case BankDealPackRightEnemyTimer
					' BankDealPackRightEnemyTimer_Tick(hWin)
					
				' Case BankDealPackPlayerTimer
					' BankDealPackPlayerTimer_Tick(hWin)
					
				' Case BankDealPackLeftEnemyTimer
					' BankDealPackLeftEnemyTimer_Tick(hWin)
					
				' Case BankDealPackFinishTimer
					' BankDealPackFinishTimer_Tick(hWin)
					
			' End Select
			
		' Case WM_PAINT
			' MainForm_Paint(hWin)
			
		' Case WM_DRAWITEM 
			' MainForm_DrawItem(hWin, Cast(HWND, wParam), CPtr(DRAWITEMSTRUCT Ptr, lParam))
			
		Case WM_SIZE
			MainForm_ReSize(hWin, wParam, LoWord(lParam), HiWord(lParam))
			
		Case WM_CLOSE
			MainForm_Close(hWin)
			
		Case WM_DESTROY
			MainForm_UnLoad(hWin)
			DeleteObject(BackColorBrush)
			PostQuitMessage(0)
			
		' Case WM_CTLCOLORSTATIC
			' MainForm_StaticControlTextColor(hWin, Cast(HWND, lParam), Cast(HDC, wParam))
			
		Case PM_NEWGAME
			MainForm_NewGame(hWin)
			
		Case PM_NEWSTAGE
			MainForm_NewStage(hWin)
			
		Case PM_RENEMYATTACK
			MainForm_RightEnemyAttack(hWin, wParam, lParam)
			
		Case PM_USERATTACK
			MainForm_UserAttack(hWin, wParam, lParam)
			
		Case PM_LENEMYATTACK
			MainForm_LeftEnemyAttack(hWin, wParam, lParam)
			
		Case PM_RENEMYFOOL
			MainForm_RightEnemyFool(hWin)
			
		Case PM_USERFOOL
			MainForm_UserFool(hWin)
			
		Case PM_LENEMYFOOL
			MainForm_LeftEnemyFool(hWin)
			
		Case PM_RENEMYWIN
			MainForm_RightEnemyWin(hWin)
			
		Case PM_PLAYERWIN
			MainForm_UserWin(hWin)
			
		Case PM_LENEMYWIN
			MainForm_LeftEnemyWin(hWin)
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function
