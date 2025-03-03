
Namespace sdk_mojo.mx

#rem monkeydoc The Button class.
#end
Class Button Extends Label

	#rem monkeydoc Invoked when the button is dragged.
	#end
	Field Dragged:Void( v:Vec2i )

	#rem monkeydoc Creates a new button.
	#end
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
		
		Style=GetStyle( "Button" )
		TextGravity=New Vec2f( .5,.5 )

		Text=text
		Icon=icon
	End
	
	Method New( action:Action )
		Self.New()
		
		Text=action.Text
		Icon=action.Icon
		
		Clicked=Lambda()
			action.Trigger()
		End
		
		action.Modified=Lambda()
			Enabled=action.Enabled
			Text=action.Text
			Icon=action.Icon
		End
	End
	
	#rem monkeydoc Button selected state.
	#end
	Property Selected:Bool()
	
		Return _selected
	
	Setter( selected:Bool )
		If selected=_selected return
	
		_selected=selected
		
		UpdateStyleState()
	End
	
	#rem monkeydoc PushButtonMode flag.
	
	If false (the default), the button will invoke [[Clicked]] each time the left mouse button is pressed. 
	
	If true, the button will invoke [[Clicked]] only when the left mouse button is released AND the mouse is still hovering over the button.
	
	#end
	Property PushButtonMode:Bool()
	
		Return _pushButtonMode
	
	Setter( mode:Bool )
	
		_pushButtonMode=mode
	End

	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Return Super.OnMeasure()
	End
	
	Method OnValidateStyle() Override
	
		Super.OnValidateStyle()
	
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Super.OnRender( canvas )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown,EventType.MouseWheel
		
			Return
			
		Case EventType.MouseClick
		
			_org=event.Location
			_active=True
			
			If Not _pushButtonMode Clicked()
			
		Case EventType.MouseDoubleClick
		
			If Not _pushButtonMode DoubleClicked()
		
		Case EventType.MouseRightClick
		
			If Not _pushButtonMode RightClicked()
		
		Case EventType.MouseUp
		
			If _pushButtonMode And _hover Clicked()
			
			_active=False
			
		Case EventType.MouseEnter
		
			_hover=True
			
		Case EventType.MouseLeave
		
			_hover=False
			
		Case EventType.MouseMove
		
			If _active Dragged( event.Location-_org )
		End
		
		UpdateStyleState()

		event.Eat()
	End
	
	Private

	Field _pushButtonMode:Bool
	Field _selected:Bool	
	Field _active:Bool
	Field _hover:Bool
	Field _org:Vec2i

	Method UpdateStyleState()
	
		If _selected
			StyleState="selected"
		Else If _active And _hover
			StyleState="active"
		Else If _active Or _hover
			StyleState="hover"
		Else
			StyleState=""
		Endif
	
	End
End
