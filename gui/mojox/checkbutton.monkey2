
Namespace sdk_mojo.mx

#rem monkeydoc The CheckGroup class.
#end
Class CheckGroup

	Field CheckedChanged:Void()

	Property Checked:CheckButton()
	
		Return _checked
	End

	Private
	
	Field _views:=New Stack<CheckButton>
	
	Field _checked:CheckButton
	
End

#rem monkeydoc The CheckButton class.
#end
Class CheckButton Extends Label

	#rem monkeydoc Invoked when the button's [[Checked]] state changes.
	
	Note: This is only invoked as the result of user interaction.
	
	#end
	Field Clicked:Void()

	#rem monkeydoc Creates a new CheckButton.
	#end
	Method New( text:String="",icon:Image=Null,group:CheckGroup=Null )
		Super.New( text,icon )
		
		Style=GetStyle( "CheckButton" )
		
		AcceptsKeyEvents=False
		AcceptsMouseEvents=False

		_checkBox=New Button
		_checkBox.Style=GetStyle( "CheckBox" )
		_checkBox.Icon=_checkBox.RenderStyle.Icons[0]
		_checkBox.Layout="float"
		_checkBox.Gravity=New Vec2f( 1,.5 )
		
		Local clicked:=Lambda()
		
			If _group And Checked Return
			
			Checked=Not Checked
			
			Clicked()
			
			If _group _group.CheckedChanged()
		End
		
		_checkBox.Clicked+=clicked
		
		Super.Clicked+=clicked
		
		AddView( _checkBox )

		If group Group=group
	End
	
	#rem monkeydoc The CheckGroup the button belongs to.
	#end
	Property Group:CheckGroup()
	
		Return _group
	
	Setter( group:CheckGroup )
		Assert( group And Not _group )
		
		_group=group

		_group._views.Add( Self )
		
		If _group._views.Length=1
			group._checked=Self
			SetChecked( True )
		Endif
	End
	
	#rem monkeydoc The button's checked state.
	#end
	Property Checked:Bool()
	
		Return _checked
		
	Setter( checked:Bool )
		If checked=_checked Return
		
		If _group
			If Not checked Return

			If _group._checked _group._checked.SetChecked( False )

			_group._checked=Self
		Endif

		SetChecked( checked )
	End
	
	Protected

	Method OnValidateStyle() Override

		_checkBox.Icon=_checkBox.RenderStyle.Icons[ _checked ]
	End
	
	Private
	
	Field _checked:Bool
	
	Field _checkBox:Button
	
	Field _group:CheckGroup
	
	Method SetChecked( checked:Bool )
		_checked=checked

		InvalidateStyle()
	End

End
