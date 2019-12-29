; AHK-GlobalGestures v1.09 - https://github.com/CheeseFrog/AHK-GlobalGestures

#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 200
CoordMode, Mouse, Screen 
; SetDefaultMouseSpeed, 0
; SetMouseDelay, 1
noRclick:=0


trail(n) { ; trail as gesture line
DllCall("SystemParametersInfo", UInt, 0x005D, UInt, n, Str, 0, UInt, 0)
}
DllCall("SystemParametersInfo", UInt, 0x005E, UInt, 0, UIntP, noTrail, UInt, 0) ; get default trail


RLUD(x1,y1,x2,y2) { ; gesture logic
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
trail(noTrail)
global noRclick
If (noRclick) {
	noRclick:=0
	Return 1
	}
}


browser(x1,y1,x2,y2) { ; gestures in chromium, firefox, IE
If !(WinActive("ahk_class Chrome_WidgetWin_1") OR WinActive("ahk_class MozillaWindowClass") OR WinActive("ahk_class IEFrame"))
	Return -1
If ((Abs(x2-x1)>A_ScreenWidth*.55) OR (Abs(y2-y1)>A_ScreenHeight*.55)) ; long-drag gestures
	Switch RLUD(x1,y1,x2,y2) {
		Case 1:
			Send ^{PgDn} ; tab right
		Case 2:
			Send ^{PgUp} ; tab left
		Case 3:
			Send {Home} ; ^{Up} ; scroll home
		Case 4:
			Send {End} ; ^{Down} ; stroll end
		Default:
			Return -1
		}
Else
	Switch RLUD(x1,y1,x2,y2) {
		Case 1:
			Send {Browser_Forward} ; {Alt down}{Right}{Alt up} ; forward page
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



RandM(x1,y1) {
KeyWait, MButton, U
noR()
MouseGetPos,x2,y2
Switch RLUD(x1,y1,x2,y2) {
	Case 1:
		Send {Media_Next} ; next track
	Case 2:
		Send {Media_Prev} ; previous track
	Case 3:
		Send {Media_Stop} ; stop
	Case 4:
		Send {Media_Play_Pause} ; pause / play
	Default:
		Send {Ctrl down}{0}{Ctrl up} ; zoom reset
	}
}


~Rbutton & MButton::
If GetKeyState("LButton", "P") {
	noRclick:=1
	Send {Volume_Mute} ; volume mute
}
Return


RandL(x1,y1,t1) { ; global rocker gestures
KeyWait, RButton, U
KeyWait, LButton, U
If noR()
	Exit
MouseGetPos,x2,y2
Switch RLUD(x1,y1,x2,y2) {
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
		If ((t2-t1) < 300)
			Send {Alt down}{tab}{Alt up} ; alt-tab
		Else
			Send {Ctrl down}{Alt down}{tab}{Alt up}{Ctrl up} ; alt-tab menu
	}
}


~RButton & LButton::Return ; handle in RButton


RButton::
t1:=A_TickCount
MouseGetPos,x1,y1
trail(16) ; trail length (max 16)
If !GetKeyState("LButton", "P") and !GetKeyState("MButton", "P")
	while GetKeyState("RButton", "P")
		If GetKeyState("LButton", "P") {
			RandL(x1,y1,t1)
			Exit
			}
		Else
		If GetKeyState("MButton", "P") {
			RandM(x1,y1)
			Exit
			}
If noR()
	Exit
MouseGetPos, x2, y2
If !(browser(x1,y1,x2,y2))
	Exit
If (abs(x2-x1)+abs(y2-y1)<22) { ; ignore mini-drag
	Click Right
	Exit
	}
MouseMove,%x1%, %y1%, 0 ; preserve default right-click drag
Click, down, right
MouseMove, %x2%, %y2%, 2
Click, up, right
Return


wheel(DU) {
global noRclick
noRclick:=1 
If GetKeyState("LButton", "P") {
	If (DU)
		Send {Volume_Down} ; volume down
	Else
		Send {Volume_Up} ; volume up
	Exit
	}
If (DU)
	Send {Ctrl down}{WheelDown} ; zoom out
Else
	Send {Ctrl down}{WheelUp} ; zoom in
sleep 10
Send {Ctrl up}
}


~Rbutton & WheelDown::wheel(1)
~Rbutton & WheelUp::wheel(0)
