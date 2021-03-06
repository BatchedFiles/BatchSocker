#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

' Соединиться с сервером и вернуть сокет
Declare Function ConnectToServer(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr, ByVal localServer As WString Ptr, ByVal LocalServiceName As WString Ptr)As SOCKET

' Создать сокет, привязанный к адресу
Declare Function CreateSocketAndBind(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr)As SOCKET

' Создать прослушивающий сокет, привязанный к адресу
Declare Function CreateSocketAndListen(ByVal localServer As WString Ptr, ByVal ServiceName As WString Ptr)As SOCKET

' Закрывает сокет
Declare Sub CloseSocketConnection(ByVal mSock As SOCKET)

' Разрешение доменного имени
Declare Function ResolveHost(ByVal sServer As WString Ptr, ByVal ServiceName As WString Ptr)As addrinfoW Ptr
