#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shellapi.bi"
#include once "win\shlwapi.bi"

' Справка
Const HelpString = !"Утилита отправки данных на сервер\r\nИспользование:\r\nbs.exe сервер порт [локальный-адрес [локальный‐порт]]\r\nПример:\r\nbs.exe chat.freenode.net 6667"

' Ошибки
Const ErrorWsaStartup = "Не могу инициализовать WSAStartup"
Const ErrorOpenSocket = "Не могу создать сокет"
Const ErrorSetSockOpt = "Не могу установить интервал ожидания данных"
Const ErrorCreateThread = "Не могу создать поток чтения данных с сервера"
Const ErrorOpenConnection = "Не могу соединиться с сервером"
Const ErrorSendData = "Не могу отправить данные на сервер"
Const ErrorReceiveData = "Не могу получить ответ от сервера"

' Локальный адрес и порт
Const LocalIP = "0.0.0.0"
Const LocalPort = "0"


' Точка входа
Declare Sub EntryPoint Alias "EntryPoint"()
