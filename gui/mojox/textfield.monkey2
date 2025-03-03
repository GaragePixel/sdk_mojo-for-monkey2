
Namespace sdk_mojo.mx

#rem monkeydoc The TextField class.
#end
Class TextField Extends TextView

	#rem monkeydoc Invoked when the user edits text.
	#end
	Field TextChanged:Void()

	#rem monkeydoc Invoked when the user hits 'Enter'.
	#end
	Field Entered:Void()

	#rem monkeydoc Invoked when the user hits 'Escape'
	#end
	Field Escaped:Void()

	#rem monkeydoc Invoked when the user hits 'Tab'.
	#end
	Field Tabbed:Void()

	#rem monkeydoc Creates a new TextField.
	#end
	Method New()
		Style=GetStyle( "TextField" )
		ContentView.Style=New Style
		
		Layout="fill-x"
		Gravity=New Vec2f( .5 )
		
		ScrollBarsVisible=False
		
		MaxSize=New Vec2i( 320,0 )
		
		Document.TextChanged+=Lambda()
			TextChanged()
		End
	End
	
	Method New( maxLength:Int )
		Self.New()
		
		MaxLength=maxLength
	End
	
	Method New( text:String,maxLength:Int=80 )
		Self.New( maxLength )
		
		Text=text
	End
	
	#rem monkeydoc Maximum text length.
	#end
	Property MaxLength:Int()

		Return _maxLength
	
	Setter( maxLength:Int )
	
		_maxLength=maxLength
		
		RequestRender()
	End
	
	Protected
	
	Method OnKeyViewChanged( oldKeyView:View,newKeyView:View ) Override
	
		If newKeyView=Self
			SelectAll()
		Else
			SelectText( 0,0 )
		Endif
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
			Select event.Key
			Case Key.Enter
				Entered()
				Return
			Case Key.Escape
				Escaped()
				Return
			Case Key.Tab
				Tabbed()
				Return
			End
		Case EventType.KeyUp
			Select event.Key
			Case Key.Enter,Key.Escape,Key.Tab
				Return
			End
		End
		
		Super.OnKeyEvent( event )
		
		If _maxLength>=Document.TextLength Return
		
		Local anchor:=Anchor,cursor:=Cursor
		
		SelectText( _maxLength,Document.TextLength )
		
		ReplaceText( "" )
		
		SelectText( anchor,cursor )
	End

	Method OnMeasureContent:Vec2i() Override
	
		Return New Vec2i( CharWidth*_maxLength,CharHeight )
	End

	Private
		
	Field _maxLength:Int=80
End
