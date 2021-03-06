#ifndef REGISTRY_BI
#define REGISTRY_BI

#ifndef unicode
#define unicode
#endif

#include "windows.bi"

Const RegistrySection = "Software\Tagalong Games\Nine"

Const RegistryUserWinsCountKey = "WinsCount"
Const RegistryUserFailsCountKey = "FailsCount"

Declare Function GetRegistryString( _
	ByVal Key As WString Ptr, _
	ByVal DefaultValue As WString Ptr, _
	ByVal ValueLength As Integer, _
	ByVal pValue As WString Ptr _
)As Integer

Declare Function SetRegistryString( _
	ByVal Key As WString Ptr, _
	ByVal Value As WString Ptr _
)As Boolean

Declare Function GetRegistryDWORD( _
	ByVal Key As WString Ptr, _
	ByVal pValue As DWORD Ptr _
)As Boolean

Declare Function SetRegistryDWORD( _
	ByVal Key As WString Ptr, _
	ByVal Value As DWORD Ptr _
)As Boolean

Declare Function IncrementRegistryDWORD( _
	ByVal Key As WString Ptr _
)As Boolean

' Declare Function GetRegistryQWORD( _
	' ByVal Key As WString Ptr, _
	' ByVal pValue As QWORD Ptr _
' )As Integer

' Declare Function SetRegistryQWORD( _
	' ByVal Key As WString Ptr, _
	' ByVal Value As QWORD Ptr _
' )As Boolean

#endif
