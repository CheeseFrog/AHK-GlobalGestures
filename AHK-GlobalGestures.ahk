; AHK-GlobalGestures v1.25 - https://github.com/CheeseFrog/AHK-GlobalGestures


#NoEnv
#SingleInstance Force
IfExist, %A_ScriptDir%\GG1.ico
	Menu, Tray, Icon, %A_ScriptDir%\GG1.ico, 1
CoordMode, Mouse, Screen
DllCall("SystemParametersInfo", UInt, 0x005E, UInt, 0, UIntP, noTrail, UInt, 0) ; get default trail
wOS:=DllCall("GetVersion")&0xFF ; Win Version
Progress, B X50 Y60 ZH0 CW121212 FM20 CTwhite,, % " ", OSD, Segoe UI Light ; OSD setup
WinSet, Transparent, 0, OSD
WinSet, ExStyle, +0x20, OSD

trail(n) { ; trail as gesture line
DllCall("SystemParametersInfo", UInt, 0x005D, UInt, n, Str, 0, UInt, 0)
}


OSD(msg) { ; On-Screen Display
Global
SetTimer, OffSD, Delete
If (msg!=old)
	Progress,,, %msg%, OSD
old:=msg
WinSet, Transparent, % a:=240, OSD
SetTimer, OffSD, 1100
Return
OffSD:
	WinSet, Transparent, % a:=(a>2)*a*.7, OSD
	If (a)
		SetTimer, OffSD, 17
	Return
}


RLUD(x1, y1, x2, y2) { ; gesture logic
DZ:=33 ; deadzone
If (Abs(x2-x1)>Abs(y2-y1)) {
	If ((x2-x1)>DZ)
		Return 1
	If ((x2-x1)<-DZ)
		Return 2
	}
If ((y2-y1)<-DZ)
	Return 3
If ((y2-y1)>DZ)
	Return 4
}


noR() { ; prevent context menu
Global
RL:=0
trail(noTrail)
If (noRclick) {
	noRclick:=0
	Return 1
	}
}


browser() { ; gestures in chromium, firefox, IE
Global
MouseGetPos, x2, y2
If !(WinActive("ahk_class Chrome_WidgetWin_1") or WinActive("ahk_class MozillaWindowClass") or WinActive("ahk_class IEFrame"))
	Return -1
If ((Abs(x2-x1)>A_ScreenWidth*.55) or (Abs(y2-y1)>A_ScreenHeight*.55)) ; long-drag gestures
	Switch RLUD(x1, y1, x2, y2) {
		Case 1:
			Send ^{PgDn}
			OSD("Tab Right")
		Case 2:
			Send ^{PgUp}
			OSD("Tab Left")
		Case 3:
			Send ^{Home}
			OSD("Scroll Home")
		Case 4:
			Send ^{End}
			OSD("Scroll End")
		Default:
			Return -1
		}
Else
	Switch RLUD(x1, y1, x2, y2) {
		Case 1:
			Send {Browser_Forward}
			OSD("Page Forward")
		Case 2:
			Send {Browser_Back}
			OSD("Page Back")
		Case 3:
			Send {PgUp}
			OSD("Scroll Up")
		Case 4:
			Send {PgDn}
			OSD("Scroll Down")
		Default:
			Return -1
		}
}


RandM(x1, y1) {
Global
While (GetKeyState("RButton", "P"))
	If (GetKeyState("MButton", "P") and noRclick) {
		Send {Ctrl down}{0}{Ctrl up}
		OSD("Zoom Reset")
		KeyWait, MButton, U
		}	
KeyWait, MButton, U
If (noR())
	Exit
MouseGetPos, x2, y2
Switch RLUD(x1, y1, x2, y2) {
	Case 1:
		Send {Media_Next}
		OSD("Media Next")
	Case 2:
		Send {Media_Prev}
		OSD("Media Last")
	Case 3:
		Send {Media_Stop}
		OSD("Media Stop")
	Case 4:
		Send {Media_Play_Pause}
		OSD("Media Play/Pause")
	Default:
		Send {Ctrl down}{0}{Ctrl up}
		OSD("Zoom Reset")
	}
}


wheel(D) {
Global
If (GetKeyState("LButton", "P")) {
	If (RL) {
		noRclick:=1
		If (D)
			Send {Volume_Down} ; volume down
		Else
			Send {Volume_Up} ; volume up
		If (wOS<8)
			OSD("Volume "+(D?Chr(0x2212):"+"))
		}
	Exit
}
noRclick:=1
OSD("Zoom "+(D?Chr(0x2212):"+"))
If (D)
	Send {Ctrl down}{WheelDown} ; zoom out
Else
	Send {Ctrl down}{WheelUp} ; zoom in
sleep 5
Send {Ctrl up}
}


RandL(x1, y1, t1) { ; Global rocker gestures
Global
While (GetKeyState("RButton", "P"))
	While (GetKeyState("LButton", "P"))
		If (GetKeyState("MButton", "P")) {
			noRclick:=1
			Send {Volume_Mute} ; volume mute
			If (wOS<8)
				OSD("Volume Mute")
			KeyWait, MButton, U
			}
If (noR())
	Exit
MouseGetPos, x2, y2
Switch RLUD(x1, y1, x2, y2) {
	Case 1:
		Send {Ctrl down}#{Right}{Ctrl up}
		OSD("Desktop Right")
	Case 2:
		Send {Ctrl down}#{Left}{Ctrl up}
		OSD("Desktop Left")
	Case 3:
		If (wOS<10)
			Send {Ctrl down}#{tab}{Ctrl up}
		Else
			Send #{tab}
		OSD("Task View")
	Case 4:
		Send #d
		OSD("Show Desktop")
	Default:
		t2:=A_TickCount
		If ((t2-t1) < 500)
			Send {Alt down}{tab}{Alt up} ; alt-tab
		Else
			Send {Ctrl down}{Alt down}{tab}{Alt up}{Ctrl up} ; alt-tab menu
	}
}


checkclick() {
Global
MouseGetPos, x1, y1
If !(GetKeyState("LButton", "P") or GetKeyState("MButton", "P")) ; anti-reverse rocker
	While (GetKeyState("RButton", "P"))
		If (GetKeyState("MButton", "P")) {
			RandM(x1, y1)
			Return 1
			}
		Else
		If (GetKeyState("LButton", "P")) {
			RandL(x1, y1, t1)
			Return 1
			}
}


RButton::
t1:=A_TickCount
trail(16) ; trail length (max 16)
If (checkclick() or noR() or !browser())
	Exit
If (abs(x2-x1)+abs(y2-y1)<22) ; ignore mini-drag
	Click Right
Else {
	MouseMove, %x1%, %y1%, 0 ; preserve default right-click drag
	Click, down, right
	MouseMove, %x2%, %y2%, 2
	Click, up, right
	}
Return


~Rbutton & MButton::Return ; prevent M-click
~RButton & LButton::RL:=1
~Rbutton & WheelUp::wheel(0)
~Rbutton & WheelDown::wheel(1)
