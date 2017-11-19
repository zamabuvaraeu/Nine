#ifndef DRAWING_BI
#define DRAWING_BI

#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "PlayerCard.bi"

Declare Sub DrawCharacterPack(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal pPlayerCard As PlayerCard Ptr, ByVal Character As Characters)

Declare Sub DrawBankPack(ByVal hDC As HDC, ByVal hDCMem As HDC, ByVal GameIsRunning As Boolean, ByVal BankDeck As PlayerCard Ptr)

Declare Sub DrawMoney(ByVal hDC As HDC, ByVal OldValue As Integer, ByVal NewValue As Integer, ByVal X As Integer, ByVal Y As Integer, ByVal CharacterName As WString Ptr)

Declare Sub DrawUpArrow(ByVal hDC As HDC, ByVal NewCardNumber As Integer)

#endif
