
Namespace sdk_mojo.m2.input

Private

Const DEBUG:=False

Public

#rem monkeydoc Type alias for compatibility.

The name JoystickDevice has been deprecated in favor of plain Joystick.

#end
Alias JoystickDevice:Joystick

#rem monkeydoc Joystick hat directions.

| JoystickHat value	| 
|:------------------|
| Centered
| Up
| Right
| Down
| Left
| RightUp
| RightDown
| LeftUp
| LeftDown

#end
Enum JoystickHat	'SDL values...
	Centered=0
	Up=1
	Right=2
	Down=4
	Left=8
	RightUp=Right|Up
	RightDown=Right|Down
	LeftUp=Left|Up
	LeftDown=Left|Down
End

#rem monkeydoc The Joystick class.
#end
Class Joystick
	
	#rem monkeydoc True if joystick is currently attached.
	#end
	Property Attached:Bool()
		
		If _discarded Return False
		
		If SDL_JoystickGetAttached( _sdljoystick ) Return True
		
		Discard()
		
		Return False
	End

	#rem monkeydoc Joystick device name.
	#end	
	Property Name:String()
		
		If _discarded Return ""
		
		Return SDL_JoystickName( _sdljoystick )
	End
	
	#rem monkeydoc Joystick GUID.
	#end
	Property GUID:String()
		
		If _discarded Return ""

		Local buf:=New Byte[64]
		Local guid:=SDL_JoystickGetGUID( _sdljoystick )
		SDL_JoystickGetGUIDString( guid,Cast<stdlib.plugins.libc.char_t Ptr>( buf.Data ),buf.Length )
		buf[buf.Length-1]=0
		Return String.FromCString( buf.Data )
	End
	
	#rem monkeydoc The number of axes supported by the joystick.
	#end	
	Property NumAxes:Int()
		
		If _discarded Return 0
		
		Return SDL_JoystickNumAxes( _sdljoystick )
	End
	
	#rem monkeydoc The number of balls upported by the joystick.
	#end	
	Property NumBalls:Int()
		
		If _discarded Return 0
		
		Return SDL_JoystickNumBalls( _sdljoystick )
	End
	
	#rem monkeydoc The number of buttons supported by the joystick.
	#end	
	Property NumButtons:Int()
		
		If _discarded Return 0
		
		Return SDL_JoystickNumButtons( _sdljoystick )
	End
	
	#rem monkeydoc The number of hats supported by the joystick.
	#end	
	Property NumHats:Int()
		
		If _discarded Return 0
		
		Return SDL_JoystickNumHats( _sdljoystick )
	End
	
	#rem monkeydoc Gets joystick axis value and returns a result in the range -1 to 1.
	
	The `axis` parameter must be in the range 0 (inclusive) to [[NumAxes]] (exclusive).
	
	The returned value is in the range -1.0 to +1.0.
	
	
	#end	
	Method GetAxis:Float( axis:Int )
		
		If _discarded Return 0
		
		Return (Float(SDL_JoystickGetAxis( _sdljoystick,axis ))+32768)/32767.5-1
	End
	
	#rem monkeydoc Gets joystick ball value.

	The `ball` parameter must be in the range 0 (inclusive) to [[NumBalls]] (exclusive).
	
	#end	
	Method GetBall:Vec2i( ball:Int )

		If _discarded Return Null
		
		Local x:Int,y:Int
		SDL_JoystickGetBall( _sdljoystick,ball,Varptr x,Varptr y )
		Return New Vec2i( x,y )
	End

	#rem monkeydoc Gets joystick hat value.

	The `hat` parameter must be in the range 0 (inclusive) to [[NumHats]] (exclusive).

	#end	
	Method GetHat:JoystickHat( hat:Int )

		If _discarded Return JoystickHat.Centered
		
		Return Cast<JoystickHat>( SDL_JoystickGetHat( _sdljoystick,hat ) )
	End

	#rem monkeydoc Gets button up/down state.
	
	The `button` parameter must be in the range 0 (inclusive) to [[NumButtons]] (exclusive).
	
	The returned value is true if button is down, else false.

	#end
	Method ButtonDown:Bool( button:Int )
		
		If _discarded Return False
		
		Return SDL_JoystickGetButton( _sdljoystick,button )
	End
	
	#rem monkeydoc Checks if a button has been pressed.

	The `button` parameter must be in the range 0 (inclusive) to [[NumButtons]] (exclusive).

	Returns true if button has been pressed since the last call to [[ButtonPressed]].
	
	
	#end
	Method ButtonPressed:Bool( button:Int )

		If _discarded Return False
		
		If ButtonDown( button )
			If _hits[button] Return False
			_hits[button]=True
			Return True
		Endif
		_hits[button]=False
		Return False
	End
	
	#rem monkeydoc Closes the joystick.
	#end
	Method Close()
		
		If _discarded Return
		
		_refs-=1
		If Not _refs Discard()
	End
	
	#rem monkeydoc Gets the number of attached joysticks.
	#end
	Function NumJoysticks:Int()
		
		Return Min( SDL_NumJoysticks(),MaxJoysticks )
	End

	#rem monkeydoc Opens a joystick if possible.
	
	@param index Joystick index.

	#end
	Function Open:Joystick( index:Int )
		
		If index<0 Or index>=MaxJoysticks Return Null
		
		Local joystick:=_joysticks[index]
		If joystick?.Attached
			joystick._refs+=1
			Return joystick
		End
		
		For Local devid:=0 Until NumJoysticks()

			Local sdljoystick:=SDL_JoystickOpen( devid )
			If Not sdljoystick Continue
			
			Local inst:=SDL_JoystickInstanceID( sdljoystick )
			If _opened[inst]
				SDL_JoystickClose( sdljoystick )
				Continue
			Endif
			
			Local joystick:=New Joystick( index,sdljoystick,inst )
			
			Return joystick
		Next
		
		Return Null
	End

	Internal
	
	Function UpdateJoysticks()
		
		SDL_JoystickUpdate()
	End
	
	Function SendEvent( event:SDL_Event Ptr )
		
		Select event->type
		Case SDL_JOYDEVICEADDED
			
			Local jevent:=Cast<SDL_JoyDeviceEvent Ptr>( event )
			
			If DEBUG Print "SDL_JOYDEVICEADDED, device id="+jevent->which
			
		Case SDL_JOYDEVICEREMOVED
			
			Local jevent:=Cast<SDL_JoyDeviceEvent Ptr>( event )
			
			If DEBUG Print "SDL_JOYDEVICEREMOVED, inst id="+jevent->which
		End
	
	End
	
	Private
	
	Const MaxJoysticks:=8
	
	'currently opened joysticks by instance id.
	Global _opened:=New IntMap<Joystick>
	
	'curently opened joysticks by user id.
	Global _joysticks:=New Joystick[MaxJoysticks]
	
	Function GetGUID:String( joystick:SDL_Joystick Ptr )
		
		Local buf:=New Byte[64]
		Local guid:=SDL_JoystickGetGUID( joystick )
		SDL_JoystickGetGUIDString( guid,Cast<stdlib.plugins.libc.char_t Ptr>( buf.Data ),buf.Length )
		buf[buf.Length-1]=0
		Return String.FromCString( buf.Data )
	End
	
	Field _refs:=1
	Field _discarded:Bool
	
	Field _index:Int
	Field _sdljoystick:SDL_Joystick Ptr 
	Field _inst:Int
	
	Field _hits:=New Bool[32]
	
	Method New( index:Int,sdljoystick:SDL_Joystick Ptr,inst:Int )
		
		_index=index
		_sdljoystick=sdljoystick
		_inst=inst
		
		_joysticks[_index]=Self
		
		_opened[_inst]=Self
	End
	
	Method Discard()

		If _discarded Return
		
		SDL_JoystickClose( _sdljoystick )
		
		_joysticks[_index]=Null
		
		_opened.Remove( _inst )
		
		_discarded=True
	End

End
