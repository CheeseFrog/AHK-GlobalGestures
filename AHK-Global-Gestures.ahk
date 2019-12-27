; AHK-Global-Gestures v1.01 - https://github.com/CheeseFrog/AHK-Global-Gestures

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
DllCall("SystemParametersInfo", UInt, 0x005E, UInt, 0, UIntP, nTrail, UInt, 0) ; get default trail


UDLR(x1,y1,x2,y2) { ; gesture logic
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


browser(x1,y1,x2,y2) { ; gestures in chromium, firefox, IE
if !(WinActive("ahk_class Chrome_WidgetWin_1") OR WinActive("ahk_class MozillaWindowClass") OR WinActive("ahk_class IEFrame"))
	Return -1
bigx:=(Abs(x2-x1)>A_ScreenWidth*.62)
bigy:=(Abs(y2-y1)>A_ScreenHeight*.62)
Switch UDLR(x1,y1,x2,y2) {
	Case 1:
		If (bigx)
			Send ^{PgDn} ; tab right
		Else
			Send {Alt down}{Right}{Alt up} ; forward page
	Case 2:
		If (bigx)
			Send ^{PgUp} ; tab left
		Else
			Send {Alt down}{Left}{Alt up} ; back page
	Case 3:
		If (bigy)
			Send {Home} ; ^{Up} ; scroll home
		Else
			Send {PgUp 2}
	Case 4:
		If (bigy)
			Send {End} ; ^{Down} ; stroll end
		Else
			Send {PgDn 2}
	Default:
		Return -1
	}
}


~RButton & LButton::Return ; handle in RButton::


RandL(x1,y1,t1) { ; global rocker gestures
KeyWait, LButton, U
MouseGetPos,x2,y2
Switch UDLR(x1,y1,x2,y2) {
	Case 1:
		Send {Ctrl down}#{Right}{Ctrl up} ; desktop right
	Case 2:
		Send {Ctrl down}#{Left}{Ctrl up} ; desktop left
	Case 3:
		Send #{tab} ; win-tab Menu
	Case 4:
		Send #d ; show desktop
	Default:
		t2:=A_TickCount
		if ((t2-t1) < 300)
			Send {Alt down}{tab}{Alt up} ; alt-tab
		Else
			Send {Ctrl down}{Alt down}{tab}{Alt up}{Ctrl up} ; alt-tab menu
	}
}


RButton::
If (noRclick) {
	noRclick:=0
	Return
	}
t1:=A_TickCount
MouseGetPos,x1,y1
trail(16)
if !GetKeyState("LButton", "P")
	while GetKeyState("RButton", "P")
		if GetKeyState("LButton", "P") {
			RandL(x1,y1,t1)
			Sleep 20
			trail(nTrail)
			Return
			}
trail(nTrail)
If (noRclick) {
	noRclick:=0
	Return
	}
MouseGetPos, x2, y2
If !(browser(x1,y1,x2,y2))
	Return
MouseMove,%x1%, %y1%, 0 ; preserve default right-click drag
Click, down, right
MouseMove, %x2%, %y2%, 2
Click, up, right
Return


~Rbutton & WheelDown:: ; zoom on R-press
If GetKeyState("RButton", "P") {
	noRclick:=1 
	Send {Ctrl down}{WheelDown}
	sleep 10
	Send {Ctrl up}
	}
Return


~Rbutton & WheelUp:: ; zoom on R-press
If GetKeyState("RButton", "P") {
	noRclick:=1
	Send {Ctrl down}{WheelUp}
	sleep 10
	Send {Ctrl up}
	}
Return


~Rbutton & MButton:: ; zoom reset
noRclick:=1 
Send {Ctrl down}{0}{Ctrl up}
Return
