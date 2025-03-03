
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class MenuSeparator Extends View

	Method New()
		Style=GetStyle( "MenuSeparator" )
	End

End

#rem monkeydoc @hidden
#end
Class MenuButton Extends Button

	Method New( text:String )
		Super.New( text )

		Style=GetStyle( "MenuButton" )
		TextGravity=New Vec2f( 0,.5 )
		Layout="fill-x"

'		MinSize=New Vec2i( 100,0 )

	End
	
	Method New( action:Action )
		Super.New( action )
		
		Style=GetStyle( "MenuButton" )
		TextGravity=New Vec2f( 0,.5 )
		Layout="fill-x"
		
'		MinSize=New Vec2i( 100,0 )

		_action=action
	End
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
		
		If _action
			Local hotKey:=_action.HotKeyText
			If hotKey size.x+=RenderStyle.Font.TextWidth( "         "+hotKey )
		Endif
		
		Return size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Super.OnRender( canvas )
		
		If _action
			Local hotKey:=_action.HotKeyText
			If hotKey
				Local w:=RenderStyle.Font.TextWidth( hotKey )
				Local tx:=(Width-w)
				Local ty:=(Height-MeasuredSize.y) * TextGravity.y
				canvas.DrawText( hotKey,tx,ty )
			Endif
		Endif
	
	End
	
	Field _action:Action

End

#rem monkeydoc The Menu class.
#end
Class Menu Extends DockingView

	#rem monkeydoc Creates a new menu.
	#end
	Method New( text:String="" )
		Style=GetStyle( "Menu" )
		Visible=False
		Layout="float"
		Gravity=New Vec2f( 0,0 )
		
		_text=text
	End
	
	#rem monkeydoc Menu text
	#end
	Property Text:String()
		Return _text
	End

	#rem monkeydoc Clears all items from the menu.
	#end
	Method Clear()
		Super.RemoveAllViews()
	End

	#rem monkeydoc Adds a view to the menu.
	#end	
	Method AddView( view:View )
	
		AddView( view,"top" )
	End
	
	#rem monkeydoc Adds an action to the menu.
	#end	
	Method AddAction( action:Action )
	
		Local button:=New MenuButton( action )
		
		button.Clicked=Lambda()
		
			CloseAll()
			'
			'a bit gnarly, but makes sure menu is *really* closed...
			'
			App.RequestRender()
			App.Idle+=action.Trigger
		End
		
		AddView( button )
	End
	
	Method AddAction:Action( text:String )
		Local action:=New Action( text )
		AddAction( action )
		Return action
	End
	
	#rem monkeydoc Adds a separator to the menu.
	#end
	Method AddSeparator()
		AddView( New MenuSeparator,"top" )
	End
	
	#rem monkeydoc Adds a submenu to the menu.
	#end
	Method AddSubMenu( menu:Menu )
	
		Local button:=New MenuButton( menu.Text )

		button.Clicked=Lambda()
			If menu.Visible
				menu.Close()
			Else
				Local location:=New Vec2i( button.Bounds.Right,button.Bounds.Top )
				menu.Open( location,button,Self )
			Endif
		End
		
		AddView( button,"top" )
	End
	
	#rem monkeydoc Opens the menu.
	#end
	Method Open()
	
		Open( App.MouseLocation,App.ActiveWindow,Null )
	End
	
	#rem monkeydoc @hidden
	#end
	Method Open( location:Vec2i,view:View,owner:View )
	
		Assert( Not Visible )
		
		While Not _open.Empty And _open.Top<>owner
			_open.Top.Close()
		Wend
		
		If _open.Empty
			_filter=App.MouseEventFilter
			App.MouseEventFilter=MouseEventFilter
		Endif
		
		Local window:=view.Window
		location=view.TransformPointToView( location,window )
		
		window.AddChildView( Self )
		Offset=location
		Visible=True
		
		_owner=owner

		_open.Push( Self )
	End
	
	#rem monkeydoc @hidden
	#end	
	Method Close()
	
		Assert( Visible )
		
		While Not _open.Empty
		
			Local menu:=_open.Pop()
			menu.Parent.RemoveChildView( menu )
			menu.Visible=False
			menu._owner=Null
			
			If menu=Self Exit
		Wend
		
		If Not _open.Empty Return
		
		App.MouseEventFilter=_filter

		_filter=Null
	End
	
	Private
	
	Field _text:String
	Field _owner:View
	
	Global _open:=New Stack<Menu>
	
	Global _filter:Void( MouseEvent )
	
	Function CloseAll()
		
		_open[0].Close()
	End
	
	Function MouseEventFilter( event:MouseEvent )
	
		If event.Eaten Return
		
		Local view:=event.View
			
		For Local menu:=Eachin _open
		
			If view.IsChildOf( menu ) Return
			
		Next
		
		If _open[0]._owner
		
			If view<>_open[0]._owner And view.IsChildOf( _open[0]._owner ) Return
			
			If event.Type=EventType.MouseDown 
				CloseAll()
			Else
'				event.Eat()
			Endif
		
		Else
			
			If event.Type=EventType.MouseDown
				CloseAll()
			Else
'				event.Eat()
			Endif
		
		Endif
	End
		
End

Class MenuBar Extends ToolBar

	Method New()
		Style=GetStyle( "MenuBar" )
		
		Layout="fill-x"
		Gravity=New Vec2f( 0,0 )
	End
	
	Method AddMenu( menu:Menu )
	
		Local button:=New MenuButton( menu.Text )

		button.Clicked=Lambda()
		
			If menu.Visible
				menu.Close()
			Else
				Local location:=New Vec2i( button.Bounds.Left,button.Bounds.Bottom )
				menu.Open( location,button,Self )
			Endif
		End
		
		AddView( button )
	End
	
End
