#ifndef SIMPLEDEBUG_BI
#define SIMPLEDEBUG_BI

Declare Function DebugMessageBoxValue( _
	ByVal Value As LongInt, _
	ByVal pCaption As WString Ptr _
)As Integer

Declare Function DebugMessageBoxArray( _
	ByVal pArray As Integer Ptr, _
	ByVal Length As Integer, _
	ByVal pCaption As WString Ptr _
)As Integer

#endif
