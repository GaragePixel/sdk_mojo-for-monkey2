Namespace sdk_mojo.m2.input

#rem monkeydoc @hidden
#end
Enum GameControllerAxis		'uses SDL values
	LeftX=0
	LeftY=1
	RightX=2
	RightY=3
	LeftTrigger=4
	RightTrigger=5
End

#rem monkeydoc @hidden
#end
Enum GameControllerButton	'uses SDL values
	A=0
	B=1
	X=2
	Y=3
	Back=4
	Guide=5
	Start=6
	LeftStick=7
	RightStick=8
	LeftShoulder=9
	RightShoulder=10
	DpadUp=11
	DpadDown=12
	DpadLeft=13
	DpadRight=14
End

#rem monkeydoc @hidden
#end
Class GameController
	
	#rem monkeydoc True if game controller is attached.
	#end
	Property Attached:Bool()
		
		If _discarded Return False
		
		If SDL_GameControllerGetAttached( _sdlcontroller ) Return True
		
		Discard()
		
		Return False
	End
	
	#rem monkeydoc Name of game controller
	#end
	Property Name:String()
		
		If _discarded Return ""
		
		Return SDL_GameControllerName( _sdlcontroller )
	End

	#rem monkeydoc Gets game controller axis value in the range -1 to 1.
	#end	
	Method GetAxis:Float( axis:GameControllerAxis )
		
		If _discarded Return 0
		
		Return (Float(SDL_GameControllerGetAxis( _sdlcontroller,Cast<SDL_GameControllerAxis>( Int(axis) ) ) )+32768)/32767.5-1
	End
	
	#rem monkeydoc Check up/down state of a game controller button.
	
	Returns true if button has been pressed since the last call to [[ButtonPressed]].
	
	#end
	Method ButtonDown:Bool( button:GameControllerButton )
		
		If _discarded Return False
		
		Return SDL_GameControllerGetButton( _sdlcontroller,Cast<SDL_GameControllerButton>( Int(button) ) )
	End
	
	#rem monkeydoc Gets joystick mapping.
	#end
	Method GetMapping:String()
		
		If _discarded Return ""
		
		Local mapping:=SDL_GameControllerMapping( _sdlcontroller )
		
		Local r:=String.FromCString( mapping )
		
		SDL_free( mapping )
		
		Return r
	End
	
	#rem monkeydoc Closes a game controller.
	#end
	Method Close()
		
		If _discarded Return
		
		_refs-=1
		If Not _refs Discard()
	End
	
	#rem  monkeydoc Adds a GameController mapping.
	
	Returns 1 if mapping added, 0 if mapping updated, -1 if error.
	
	https://wiki.libsdl.org/SDL_GameControllerAddMapping
	
	#end
	Function AddMapping:Int( mapping:String )
		
		Return SDL_GameControllerAddMapping( mapping )
	End

	#rem monkeydoc Loads game controller mappings from a file.
	
	Returns the number of mappings added.

	#end
	Function AddMappingsFromFile:Int( path:String )
		
		Local n:=0
		
		For Local mapping:=Eachin LoadString( path,True ).Split( "~n" )
			
			mapping=mapping.Trim()
			
			If Not mapping Or mapping.StartsWith( "#" ) Continue
			
			n+=AddMapping( mapping )>0 ? 1 Else 0
		Next
		
		Return n
	End

#rem	
	Function GetAxisName:String( axis:GameControllerAxis )

		Return SDL_GameControllerGetStringForAxis( Cast<SDL_GameControllerAxis>( Int(axis) ) )
	End
	
	Function GetButtonName:String( button:GameControllerButton )
		
		Return SDL_GameControllerGetStringForButton( Cast<SDL_GameControllerButton>( int(button) ) )
	End
#end

	Function Open:GameController( index:Int )
		
		If index<0 Or index>=MaxControllers Return Null
		
		Local controller:=_controllers[index]
		If controller?.Attached
			controller._refs+=1
			Return controller
		End
		
		For Local devid:=0 Until JoystickDevice.NumJoysticks()
			
			If Not SDL_IsGameController( devid ) Continue
			
			Local sdlcontroller:=SDL_GameControllerOpen( devid )
			If Not sdlcontroller Continue
			
			Local inst:=SDL_JoystickInstanceID( SDL_GameControllerGetJoystick( sdlcontroller ) )
			If _opened[inst]
				SDL_GameControllerClose( sdlcontroller )
				Continue
			Endif

			Local controller:=New GameController( index,sdlcontroller,inst )
			
			Return controller
		Next
		
		Return Null
	End
	
	Private
	
	Const MaxControllers:=8
	
	Global _opened:=New IntMap<GameController>
	
	Global _controllers:=New GameController[MaxControllers]
	
	Field _refs:=1
	Field _discarded:=False
	
	Field _index:Int
	Field _sdlcontroller:SDL_GameController Ptr
	Field _inst:Int
	
	Field _hits:=New Bool[16]
	
	Method New( index:Int,sdlcontroller:SDL_GameController Ptr,inst:Int )
		
		_index=index
		_sdlcontroller=sdlcontroller
		_inst=inst
		
		_controllers[_index]=Self
		_opened[_inst]=Self
	End
	
	Method Discard()
		
		if _discarded Return
		
		SDL_GameControllerClose( _sdlcontroller )
		
		_controllers[_index]=Null
		
		_opened.Remove( _inst )
		
		_discarded=True
	End
	
End
