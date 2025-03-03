
Namespace sdk_mojo.mx

#rem monkeydoc The Lable class.
#end
Class Label Extends View

	#rem monkeydoc Invoked when the label is clicked.
	#end
	Field Clicked:Void()

	#rem monkeydoc Invoked when the label is right clicked.
	#end
	Field RightClicked:Void()
	
	#rem monkeydoc Invoked when the label is double clicked.
	#end
	Field DoubleClicked:Void()
	
	#rem monkeydoc Creates a new label.
	#end
	Method New( text:String="",icon:Image=Null )
		Style=GetStyle( "Label" )

		Layout="fill-x"
		Gravity=New Vec2f( 0,.5 )
		TextGravity=New Vec2f( 0,.5 )

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

	#rem monkeydoc Label text.
	#end
	Property Text:String()
	
		Return _text
		
	Setter( text:String )
		If text=_text Return
	
		_text=text
		
		RequestRender()
	End

	#rem monkeydoc Label text gravity.
	#end
	Property TextGravity:Vec2f()
	
		Return _textGravity
	
	Setter( textGravity:Vec2f )
		If textGravity=_textGravity Return
	
		_textGravity=textGravity

		RequestRender()
	End

	#rem monkeydoc Label icon.
	#end
	Property Icon:Image()
	
		Return _icon
	
	Setter( icon:Image )
		If icon=_icon Return
	
		_icon=icon
		
		RequestRender()
	End
	
	#rem monkeydoc Adds a view to the right of the label.
	#end
	Method AddView( view:View )
		
		AddChildView( view )
	
		_views.Push( view )
	End
	
	#rem monkeydoc Removes a view from the label.
	#end
	Method RemoveView( view:View )
	
		RemoveChildView( view )
		
		_views.Remove( view )
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override

		_iconSize=New Vec2i( 0,0 )
		_textSize=New Vec2i( 0,0 )
		_viewsSize=New Vec2i( 0,0 )
		
		Local w:=0,h:=0

		If _icon
			_iconSize=New Vec2i( _icon.Width,_icon.Height )
			w=_iconSize.x
			h=_iconSize.y
		Endif
		
		If _text
			_textSize=RenderStyle.MeasureText( _text )
			w+=_textSize.x
			h=Max( h,_textSize.y )
		Endif
		
		For Local view:=Eachin _views
			_viewsSize.x+=view.LayoutSize.x
			_viewsSize.y=Max( _viewsSize.y,view.LayoutSize.y )
		Next
		
		w+=_viewsSize.x
		h=Max( h,_viewsSize.y )
		
		Return New Vec2i( w,h )
	End
	
	Method OnLayout() Override
	
		Local iy:=(Height-_iconSize.y)/2
		_iconRect=New Recti( 0,iy,_iconSize.x,iy+_iconSize.y )
	
		Local tx:=_iconSize.x,ty:=0
		Local tw:=_textSize.x,th:=Height
		_textRect=New Recti( tx,ty,tx+tw,ty+th )
		
		Local x1:=Width
		
		For Local i:=_views.Length-1 To 0 Step -1
			Local view:=_views[i]
			Local x0:=i ? Max( x1-view.LayoutSize.x,_textRect.Right ) Else _textRect.Right
			view.Frame=New Recti( x0,0,x1,Height )
			x1=x0
		Next
		
		_textRect.Right=x1
		
		#rem
		For Local view:=Eachin _views.Backwards()
			Local x0:=Max( x1-view.LayoutSize.x,_textRect.Right )
			view.Frame=New Recti( x0,0,x1,Height )
			x1=x0
		Next
		_textRect.Right=x1
		#end
		
		Return
		
		Local x0:=_textRect.Right
		For Local view:=Eachin _views
		
			Local x1:=Min( x0+view.LayoutSize.x,Width )
			view.Frame=New Recti( x0,0,x1,Height )
			x0=x1
		Next
	
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If _icon 
			RenderStyle.DrawIcon( canvas,_icon,_iconRect.X,_iconRect.Y )
		Endif

		If _text
			RenderStyle.DrawText( canvas,_text,_textRect,_textGravity )
		Endif
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override

		Select event.Type
		Case EventType.MouseDown,EventType.MouseWheel
		
			Return
			
		Case EventType.MouseClick
		
			Clicked()
			
		Case EventType.MouseRightClick
		
			RightClicked()
			
		Case EventType.MouseDoubleClick
		
			DoubleClicked()
		End

		event.Eat()
	End
	
	Private
	
	Field _text:String
	Field _textGravity:Vec2f=New Vec2f( 0,.5 )
	Field _icon:Image
	Field _views:=New Stack<View>
	
	Field _iconSize:Vec2i
	Field _iconRect:Recti
	Field _textSize:Vec2i
	Field _textRect:Recti
	Field _viewsSize:Vec2i

End
