
Namespace sdk_mojo.m2.input

#rem monkeydoc Global instance of the MouseDevice class.
#end
Const Mouse:=New MouseDevice

#rem monkeydoc Mouse buttons.

| MouseButton	| Description
|:--------------|------------
| Left			| Left mouse button.
| Middle		| Middle mouse button.
| Right			| Right mouse button.

#end
Enum MouseButton
	None=0
	Left=1
	Middle=2
	Right=3
End

#rem monkeydoc Mouse system cursors.

| MouseCursor	| Description
|:--------------|:------------
| Arrow			| Arrow.
| IBeam			| I-Beam.
| Wait			| Wait.
| CrossHair		| Crosshair.
| WaitArrow		| Small wait cursor (or Wait if not available).
| SizeNWSE		| Double arrow pointing north-west and south-east.
| SizeNESW		| Double arrow pointing north-east and south-west.
| SizeWE		| Double arrow pointing west and east.
| SizeNS		| Double arrow pointing north and south.
| SizeALL		| Four pointed arrow pointing north, south, east, and west.
| No			| Slashed circle or crossbones.
| Hand			| Hand.

#end
Enum MouseCursor
	Arrow=0
	IBeam=1
	Wait=2
	CrossHair=3
	WaitArrow=4
	SizeNWSE=5
	SizeNESW=6
	SizeWE=7
	SizeNS=8
	SizeALL=9
	No=10
	Hand=11
	'
	Max=12
End

#rem monkeydoc The MouseDevice class.

To access the mouse device, use the global [[Mouse]] constant.

The mouse device should only used after a new [[AppInstance]] is created.

#end
Class MouseDevice

	#rem monkeydoc The mouse cursor, see [[MouseCursor]] enumeration for details.
	
	#end
	Property Cursor:MouseCursor()
	
		Return _cursor
		
	Setter( cursor:MouseCursor )
	
		_cursor = cursor
		
		SDL_SetCursor( _cursors[_cursor] )
	End
	
	#rem monkeydoc Pointer visiblity state.
	#end
	Property PointerVisible:Bool()
	
		Return SDL_ShowCursor( -1 )=SDL_ENABLE
		
	Setter( pointerVisible:Bool )
	
		SDL_ShowCursor( pointerVisible ? SDL_ENABLE Else SDL_DISABLE )
	
	End
	
	#rem monkeydoc X coordinate of the mouse location.
	#end
	Property X:Int()
		Return Location.x
	End
	
	#rem monkeydoc Y coordinate of the mouse location.
	#end
	Property Y:Int()
		Return Location.y
	End


'---[ by DrCox85 ]----------------------------------------------
	#rem monkeydoc X Speed of the mouse.
	#end
	Property XSpeed:Int()
		Local d:=_location.x-_lastlocation.x
		_lastlocation.x=_location.x
		Return d
	End
	
	#rem monkeydoc Y Speed of the mouse.
	#end
	Property YSpeed:Int()
		Local d:=_location.y-_lastlocation.y
		_lastlocation.y=_location.y
		Return d
	End
	#rem monkeydoc The mouse desktop location.
	
	This property get the mouse desktop location.
	
	#end
	Property DesktopLocation:Vec2i()
		Return _desktoplocation
	End
	
'---------------------------------------------------------------	

	#rem monkeydoc The mouse location.
	
	This property may be written to warp the mouse to a new location.
	
	#end
	Property Location:Vec2i()
		Return _location
	Setter( location:Vec2i )
		_location=location
		SDL_WarpMouseInWindow( Null,location.x,location.y )
	End
	
	#rem monkeydoc The mouse wheel delta x value since the last app update.
	#end
	Property WheelX:Int()
		Return Wheel.x
	End
	
	#rem monkeydoc The mouse wheel delta y value since the last app update.
	#end
	Property WheelY:Int()
		Return Wheel.y
	End
	
	#rem monkeydoc The mouse wheel delta value since the last app update.
	#end
	Property Wheel:Vec2i()
		Return _wheel
	End
#rem
	Property WheelXDelta:Int()
		Return _wheelDelta.x
	End	
	
	Property WheelYDelta:Int()
		Return _wheelDelta.y
	End		
	
	Property WheelDelta:Vec2i()
		Return _wheelDelta
	End	
#End	
	
	#rem monkeydoc Checks the current up/down state of a mouse button.
	
	Returns true if `button` is currently held down.
	
	@param button Button to checl.
	#end
	Method ButtonDown:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		Return _down[button]
	End

	#rem monkeydoc Checks if a mouse button was pressed.
	
	Returns true if `button` was pressed since the last app update.

	@param button Button to check.
	
	#end
	Method ButtonPressed:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		
		Local pressed:=_pressed[button]
		
		_pressed[button]=False
		
		Return pressed
	End
	
	#rem monkeydoc Checks if a mouse button was released.
	
	Returns true if `button` was released since the last app update.
	
	@param button Button to check.
	
	#end
	Method ButtonReleased:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		
		Local released:=_released[button]
		
		_released[button]=False
		
		Return released
	End
	
	#rem monkeydoc @hidden
	#end
	Method ButtonHit:Bool( button:MouseButton )
		Return ButtonPressed( button )
	End
	
'---[ by GaragePixel ]------------------------------------------	
	Method WheelHack( activated:Bool )
		_wheelHack=activated
	End 
'---------------------------------------------------------------	

	Internal

	Method Init()
	
		_cursors=New SDL_Cursor Ptr[ MouseCursor.Max ]
		
		For Local i:=0 Until _cursors.Length
		
			_cursors[i]=SDL_CreateSystemCursor( Cast<SDL_SystemCursor>( i ) )
		Next
		
		_cursor=MouseCursor.Arrow
		
		SDL_SetCursor( _cursors[_cursor] )
	End
	
	Method Update()
		
'		_wheelNow=_wheel
	
		Local mask:=SDL_GetMouseState( Varptr _location.x,Varptr _location.y )
'---[ by DrCox85 ]----------------------------------------------
		SDL_GetGlobalMouseState(Varptr _desktoplocation.x, Varptr _desktoplocation.y)
'---------------------------------------------------------------		
		If App.ActiveWindow	_location=App.ActiveWindow.TransformPointFromView( App.ActiveWindow.MouseScale * _location,Null )
		
		UpdateButton( MouseButton.Left,mask & 1 )
		UpdateButton( MouseButton.Middle,mask & 2 )
		UpdateButton( MouseButton.Right,mask & 4)

'---[ by GaragePixel ]------------------------------------------	
		If Not _wheelHack _wheel=Null ' Deactivate the reinit
		'_wheel=Null ' Original
'---------------------------------------------------------------		
'		_wheelDelta=_wheelNow-_wheelOld
'		_wheelOld=_wheelNow ' Added by iDkP
		
		
	End
	
	Method SendEvent( event:SDL_Event Ptr )
		
		Select event->type
		
			Case SDL_MOUSEWHEEL
			
				Local mevent:=Cast<SDL_MouseWheelEvent Ptr>( event )
				
				Local window:=Window.WindowForID( mevent->windowID )
				If Not window Return
				
				_wheel+=New Vec2i( mevent->x,mevent->y )
	
		End
		
	End
	
	Method Reset()
		For Local i:=0 Until 4
			_pressed[i]=False
			_released[i]=false
		next
	End
	
	Private

	Field _init:Bool	
	Field _location:Vec2i
'---[ by DrCox85 ]----------------------------------------------
	Field _desktoplocation:Vec2i=New Vec2i(0,0)
	Field _lastlocation:Vec2i=New Vec2i(0,0)
'---------------------------------------------------------------	
	Field _wheel:Vec2i
'---[ by GaragePixel ]------------------------------------------
	Field _wheelHack:Bool
'---------------------------------------------------------------	
'	Field _wheelNow:Vec2i=New Vec2i() ' Added by iDkP
'	Field _wheelOld:Vec2i=New Vec2i() ' Added by iDkP
'	Field _wheelDelta:Vec2i=New Vec2i() ' Added by iDkP
	Field _down:=New Bool[4]
	Field _pressed:=New Bool[4]
	Field _released:=New Bool[4]
	Field _cursors:=New SDL_Cursor Ptr[ MouseCursor.Max ]
	Field _cursor:MouseCursor
	
	Method New()
	End
	
	Method UpdateButton( button:MouseButton,down:Bool )
		'_pressed[button]=False
		'_released[button]=False
		If down=_down[button] Return
		If down _pressed[button]=True Else _released[button]=True
		_down[button]=down
	End
	
End
