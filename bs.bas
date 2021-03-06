#include once "bs.bi"
#include once "Network.bi"
#include once "WriteLine.bi"
#include once "IntegerToWString.bi"

Const EOFChar As Integer = 26

Const CodePage As Integer = CP_UTF8

Const ReadConsoleBufferLength As DWORD = 32768 - 1

Function ThreadProc(ByVal lpParam As LPVOID)As DWORD
	Dim pSocket As SOCKET Ptr = lpParam
	' Идентификатор вывода
	Dim OutHandle As Handle = GetStdHandle(STD_OUTPUT_HANDLE)
	
	Do
		Dim m_Buffer As ZString * (ReadConsoleBufferLength + 1) = Any
		
		' Читать данные из сокета
		Dim intReceivedBytesCount As Integer = recv(*pSocket, @m_Buffer, ReadConsoleBufferLength, 0)
		
		Select Case intReceivedBytesCount
			Case SOCKET_ERROR
				' Ошибка сети
				#ifdef withoutrtl
					ExitProcess(NetworkError)
				#else
					End(NetworkError)
				#endif
				
			Case 0
				' Клиент закрыл соединение
				#ifdef withoutrtl
					ExitProcess(0)
				#else
					End(0)
				#endif
				
			Case Else
				' Заключительный нулевой символ
				m_Buffer[intReceivedBytesCount] = 0
				
		End Select
		
		' Вернуть строку
		Dim strReceiveData As WString * (ReadConsoleBufferLength + 1) = Any
		MultiByteToWideChar(CodePage, 0, @m_Buffer, -1, @strReceiveData, ReadConsoleBufferLength + 1)
		
		' Количество символов, выведенных на консоль или записанных в файл
		Dim CharsCount As DWORD = Any
		
		' Вывести на консоль
		If WriteConsole(OutHandle, @strReceiveData, lstrlen(@strReceiveData), @CharsCount, 0) = 0 Then
			' Возможно, вывод перенаправлен, нужно записать в файл
			If WriteFile(OutHandle, @m_Buffer, intReceivedBytesCount, @CharsCount, 0) = 0 Then
				#ifdef withoutrtl
					ExitProcess(NetworkError)
				#else
					End(NetworkError)
				#endif
			End If
		End If
		
	Loop
	Return 0
End Function

#ifdef withoutrtl
Sub EntryPoint Alias "EntryPoint"()
#endif
	Dim ErrorHandle As Handle = GetStdHandle(STD_ERROR_HANDLE)
	
	' Получить параметры программы
	Dim ArgsCount As DWORD = Any
	' Массив параметров командной строки
	Dim Args As WString Ptr Ptr = CommandLineToArgvW(GetCommandLine(), @ArgsCount)
	
	If ArgsCount < 3 Then
		' Отобразить справку
		WriteString(ErrorHandle, HelpString)
		#ifdef withoutrtl
				ExitProcess(ParamError)
		#else
				End(ParamError)
		#endif
	End If
	
	' Параметр 1 — сервер
	' Параметр 2 — порт
	' Параметр 3 — локальный адрес
	' Параметр 4 — локальный порт
	
	' Идентификатор ввода
	Dim InHandle As Handle = GetStdHandle(STD_INPUT_HANDLE)
	
	' Открыть сокет
	' Сокеты
	Dim objWsaData As WSAData = Any
	If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> 0 Then
		WriteString(ErrorHandle, @ErrorWsaStartup)
		#ifdef withoutrtl
				ExitProcess(NetworkError)
		#else
				End(NetworkError)
		#endif
	End If
	
	' Открыть сокет
	Dim m_Socket As SOCKET = ConnectToServer(Args[1], Args[2], Iif(ArgsCount > 3, Args[3], @LocalIP), Iif(ArgsCount > 4, Args[4], @LocalPort))
	
	If m_Socket = INVALID_SOCKET Then
		WriteString(ErrorHandle, @ErrorOpenConnection)
		#ifdef withoutrtl
				ExitProcess(NetworkError)
		#else
				End(NetworkError)
		#endif
	End If
	
	' Ожидать чтения данных с клиента 10 минут
	Dim ReceiveTimeOut As DWORD = 10 * 60 * 1000
	If setsockopt(m_Socket, SOL_SOCKET, SO_RCVTIMEO, CPtr(ZString Ptr, @ReceiveTimeOut), SizeOf(DWORD)) <> 0 Then
		WriteString(ErrorHandle, @ErrorSetSockOpt)
		CloseSocketConnection(m_Socket)
		#ifdef withoutrtl
				ExitProcess(NetworkError)
		#else
				End(NetworkError)
		#endif
	End If
	
	Dim ThreadId As DWORD = Any
	Dim hThread As HANDLE = CreateThread(NULL, 0, @ThreadProc, @m_Socket, 0, @ThreadId)
	
	If hThread = 0 Then
		WriteString(ErrorHandle, @ErrorCreateThread)
		CloseSocketConnection(m_Socket)
		#ifdef withoutrtl
				ExitProcess(ThreadError)
		#else
				End(ThreadError)
		#endif
	End If
	
	Do
		' Читать данные с консоли
		Dim s As WString * (ReadConsoleBufferLength + 1) = Any
		Dim SymbolsCount As DWORD = Any
		If ReadConsole(InHandle, @s, ReadConsoleBufferLength, @SymbolsCount, 0) = 0 Then
			' Ошибка чтения с консоли, возможно ввод перенаправлен
			
			Dim z As ZString * (ReadConsoleBufferLength + 1) = Any
			If ReadFile(InHandle, @z, ReadConsoleBufferLength, @SymbolsCount, 0) = 0 Then
				Exit Do
			End If
			
			If SymbolsCount = 0 Then
				Exit Do
			End If
			
			If send(m_Socket, @z, SymbolsCount, 0) = SOCKET_ERROR Then
				Exit Do
			End If
		Else
			#if __FB_DEBUG__ <> 0
				Print "Введённое количество символов", SymbolsCount
				Print "Длина строки", Len(s)
			#endif
			
			If SymbolsCount = 0 Then
				Exit Do
			End If
			
			s[SymbolsCount] = 0
			
			Dim wEOF As WString Ptr = StrChr(@s, EOFChar)
			If wEOF <> 0 Then
				wEOF[0] = 0
				' Закрыть соединение
			End If
			
			' Перекодируем в байты utf8
			Dim SendBuffer As ZString * (ReadConsoleBufferLength * 4 + 1) = Any
			Dim SendBufferLength As Integer = WideCharToMultiByte(CodePage, 0, @s, -1, @SendBuffer, (ReadConsoleBufferLength * 4 + 1), 0, 0) - 1
			
			#if __FB_DEBUG__ <> 0
				Print "Количество отправляемых байт", SendBufferLength
			#endif
			
			If send(m_Socket, @SendBuffer, SendBufferLength, 0) = SOCKET_ERROR Then
				Exit Do
			End If
			
			If wEOF <> 0 Then
				Exit Do
			End If
		End If
		
	Loop
	
	' Подождать, когда завершится второй поток
	WaitForSingleObject(hThread, INFINITE)
	CloseHandle(hThread)
	
	' Закрыть соединение
	CloseSocketConnection(m_Socket)
	WSACleanUp()
	LocalFree(Args)
	#ifdef withoutrtl
		ExitProcess(0)
	#else
		End(0)
	#endif

#ifdef withoutrtl
End Sub
#endif
