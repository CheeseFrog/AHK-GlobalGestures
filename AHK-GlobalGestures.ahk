; AHK-GlobalGestures v1.19 - https://github.com/CheeseFrog/AHK-GlobalGestures


#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 200
CoordMode, Mouse, Screen
DllCall("SystemParametersInfo", UInt, 0x005E, UInt, 0, UIntP, noTrail, UInt, 0) ; get default trail


trail(n) { ; trail as gesture line
DllCall("SystemParametersInfo", UInt, 0x005D, UInt, n, Str, 0, UInt, 0)
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
global
RL:=0
sleep 5 ; fixes R lockout bug on R+L+M
trail(noTrail)
If (noRclick) {
	noRclick:=0
	Return 1
	}
}


browser() { ; gestures in chromium, firefox, IE
global
MouseGetPos, x2, y2
If !(WinActive("ahk_class Chrome_WidgetWin_1") or WinActive("ahk_class MozillaWindowClass") or WinActive("ahk_class IEFrame"))
	Return -1
If ((Abs(x2-x1)>A_ScreenWidth*.55) or (Abs(y2-y1)>A_ScreenHeight*.55)) ; long-drag gestures
	Switch RLUD(x1, y1, x2, y2) {
		Case 1:
			Send ^{PgDn} ; tab right
		Case 2:
			Send ^{PgUp} ; tab left
		Case 3:
			Send ^{Home} ; scroll home
		Case 4:
			Send ^{End} ; stroll end
		Default:
			Return -1
		}
Else
	Switch RLUD(x1, y1, x2, y2) {
		Case 1:
			Send {Browser_Forward} ; forward page
		Case 2:
			Send {Browser_Back} ; back page
		Case 3:
			Send {PgUp} ; {WheelUp 6} ; scroll down
		Case 4:
			Send {PgDn} ; scroll up
		Default:
			Return -1
		}
}


RandM(x1, y1) {
global
while GetKeyState("RButton", "P")
	If GetKeyState("MButton", "P") and noRclick {
		Send {Ctrl down}{0}{Ctrl up} ; reset zoom
		KeyWait, MButton, U
		}	
KeyWait, MButton, U
If noR()
	Exit
MouseGetPos, x2, y2
Switch RLUD(x1, y1, x2, y2) {
	Case 1:
		Send {Media_Next} ; next track
	Case 2:
		Send {Media_Prev} ; previous track
	Case 3:
		Send {Media_Stop} ; stop
	Case 4:
		Send {Media_Play_Pause} ; pause / play
	Default:
		Send {Ctrl down}{0}{Ctrl up} ; reset zoom
	}
}


wheel(D) {
global
If GetKeyState("LButton", "P") {
	If RL {
		noRclick:=1
		If (D)
			Send {Volume_Down} ; volume down
		Else
			Send {Volume_Up} ; volume up
		}
	Exit
}
noRclick:=1
If (D)
	Send {Ctrl down}{WheelDown} ; zoom out
Else
	Send {Ctrl down}{WheelUp} ; zoom in
sleep 5
Send {Ctrl up}
}


RandL(x1, y1, t1) { ; global rocker gestures
global
while GetKeyState("RButton", "P")
	while GetKeyState("LButton", "P")
		If GetKeyState("MButton", "P") {
			noRclick:=1
			Send {Volume_Mute} ; volume mute
			KeyWait, MButton, U
			}
If noR()
	Exit
MouseGetPos, x2, y2
Switch RLUD(x1, y1, x2, y2) {
	Case 1:
		Send {Ctrl down}#{Right}{Ctrl up} ; desktop right
	Case 2:
		Send {Ctrl down}#{Left}{Ctrl up} ; desktop left
	Case 3:
		Send #{tab} ; win-tab menu
	Case 4:
		Send #d ; show desktop
	Default:
		t2:=A_TickCount
		If ((t2-t1) < 500)
			Send {Alt down}{tab}{Alt up} ; alt-tab
		Else
			Send {Ctrl down}{Alt down}{tab}{Alt up}{Ctrl up} ; alt-tab menu
	}
}


checkclick() {
global
MouseGetPos, x1, y1
If !GetKeyState("LButton", "P") and !GetKeyState("MButton", "P") ; anti-reverse rocker
	while GetKeyState("RButton", "P")
		If GetKeyState("MButton", "P") {
			RandM(x1, y1)
			Return 1
			}
		Else
		If GetKeyState("LButton", "P") {
			RandL(x1, y1, t1)
			Return 1
			}
}


RButton::
t1:=A_TickCount
trail(16) ; trail length (max 16)
If checkclick() or noR() or !browser()
	Exit
If (abs(x2-x1)+abs(y2-y1)<22) { ; ignore mini-drag
	Click Right
	Exit
	}
MouseMove, %x1%, %y1%, 0 ; preserve default right-click drag
Click, down, right
MouseMove, %x2%, %y2%, 2
Click, up, right
Return


~Rbutton & MButton::Return ; prevent M-click
~RButton & LButton::RL:=1
~Rbutton & WheelUp::wheel(0)
~Rbutton & WheelDown::wheel(1)
