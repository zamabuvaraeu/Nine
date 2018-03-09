#ifndef DRAWING_BI
#define DRAWING_BI

#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "PlayerCard.bi"

Declare Sub GetMoneyString( _
	ByVal buffer As WString Ptr, _
	ByVal MoneyValue As Integer, _
	ByVal CharacterName As WString Ptr _
)

Declare Sub DrawCard( _
	ByVal hDC As HDC, _
	ByVal hDCMem As HDC, _
	ByVal X As Integer, _
	ByVal Y As Integer, _
	ByVal CardNumber As Integer _
)

Declare Sub DrawCharacterCard( _
	ByVal hDC As HDC, _
	ByVal pPlayerCard As PlayerCard Ptr, _
	ByVal Character As Characters _
)

Declare Sub DrawBankCard( _
	ByVal hDC As HDC, _
	ByVal pBankCard As PlayerCard Ptr, _
	ByVal GameIsRunning As Boolean _
)

Declare Sub EraseCard( _
	ByVal hDC As HDC, _
	ByVal hDCMem As HDC, _
	ByVal pPlayerCard As PlayerCard Ptr _
)

Declare Sub DrawCharacterPack( _
	ByVal hDC As HDC, _
	ByVal pPlayerCard As PlayerCard Ptr, _
	ByVal Character As Characters _
)

Declare Sub DrawBankPack( _
	ByVal hDC As HDC, _
	ByVal GameIsRunning As Boolean, _
	ByVal BankDeck As PlayerCard Ptr _
)

Declare Sub CalcMoneySize( _
	ByVal MoneyTextSize As SIZE Ptr, _
	ByVal hDC As HDC, _
	ByVal CharacterMoney As Money Ptr _
)

Declare Sub DrawUpArrow( _
	ByVal hDC As HDC, _
	ByVal hCDMem As HDC, _
	ByVal X As Integer, _
	ByVal Y As Integer _
)

#endif
