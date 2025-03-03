
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class DockKnob Extends View

	Field Dragged:Void( v:Vec2i )

	Method New()
		Style=GetStyle( "DockKnob" )
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Return New Vec2i( 0,0 )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown
			_drag=True
			_org=event.Location
		Case EventType.MouseUp
			_drag=False
		Case EventType.MouseEnter
			_hover=True
		Case EventType.MouseLeave
			_hover=False
		Case EventType.MouseMove
			If _drag Dragged( event.Location-_org )
		End
		
		If _drag
			StyleState="active"
		Else If _hover
			StyleState="hover"
		Else
			StyleState=""
		Endif
	End
	
	Private
	
	Field _org:Vec2i
	
	Field _drag:Bool
	Field _hover:Bool
	
End

#rem monkeydoc @hidden
#end
Class DockedView Extends View

	Method New( view:View,location:String,size:String,resizable:Bool )
		Style=GetStyle( "DockedView" )
		
		_view=view
		_location=location
		_size=size
		_resizable=resizable
		
		If _size.EndsWith( "%" )
			_sizeMode=SizeMode.Relative
			_relSize=Float( _size.Slice( 0,-1 ) )/100
		Else If String( Int( _size ) )=_size
			_sizeMode=SizeMode.Absolute
			_absSize=Int( _size )
		Else
			_sizeMode=SizeMode.Natural
		Endif
		
		AddChildView( _view )
		
		If _sizeMode=SizeMode.Absolute And _resizable
		
			_knob=New DockKnob
			
			_knob.Dragged=Lambda( v:Vec2i )
			
				Select _location
				Case "top"
					AbsoluteSize+=v.y
				Case "bottom"
					AbsoluteSize-=v.y
				Case "left"
					AbsoluteSize+=v.x
				Case "right"
					AbsoluteSize-=v.x
				End
			End
			
			AddChildView( _knob )
			
		Endif
	End
	
	Property View:View()
	
		Return _view
		
	Setter( view:View )
	
		If _view RemoveChildView( _view )
		
		_view=view
		
		If _view AddChildView( _view )
	End
	
	Property Location:String()
	
		Return _location
	End
	
	Property Size:String()
	
		Return _size
		
	Setter( size:String )
		If size=_size Return
		
		If size.EndsWith( "%" )
			RelativeSize=Float( size.Slice( 0,-1 ) )/100.0
		Else If String( Int( size ) )=size
			AbsoluteSize=Int( size )
		Endif
	End
	
	Property Resizable:Bool()
	
		Return _resizable
	End
	
	Property RelativeSize:Float()
	
		Return _relSize
	
	Setter( size:Float )
		If _sizeMode<>SizeMode.Relative Return
		
		size=Max( size,0.0 )
		
		If size=_relSize Return
		
		_relSize=size
		
		_size=String( Int( _relSize*100.0 ) )+"%"
		
		App.RequestRender()
	End
	
	Property AbsoluteSize:Int()
	
		Return _absSize
	
	Setter( size:Int )
		If _sizeMode<>SizeMode.Absolute Return
		
		size=Max( size,0 )
		
		If size=_absSize Return
		
		_absSize=size
		
		_size=String( _absSize )
		
		App.RequestRender()
	End
	
	Method RealSize:Int( size:Int )
		Select _sizeMode
		
		Case SizeMode.Natural,SizeMode.Absolute
		
			If _location="left" Or _location="right" Return LayoutSize.x
			Return LayoutSize.y
			
		Case SizeMode.Relative
		
			Return _relSize * size
		End
		
		Return 0
	End
	
	Private
	
	Field _view:View
	Field _knob:DockKnob
	Field _location:String
	Field _size:String
	Field _resizable:Bool

	Field _sizeMode:SizeMode
	Field _relSize:Float
	Field _absSize:Int
	
	Enum SizeMode
		Natural
		Absolute
		Relative
	End
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=_view.LayoutSize
		
		If _sizeMode=SizeMode.Absolute
			Select _location
			Case "top","bottom"
				size.y=_absSize
				If _knob size.y+=_knob.LayoutSize.y
			Case "left","right"
				size.x=_absSize
				If _knob size.x+=_knob.LayoutSize.x
			End
			#rem
		Else If _sizeMode=SizeMode.Relative
			Select _location
			Case "top","bottom"
				size.y=size.y/_relSize
			Case "left","right"
				size.x=size.x/_relSize
			End
			#end
		Endif
		
		Return size
	End
	
	Method OnLayout:Void() Override
	
		Local rect:=Rect
		
		If _knob
			Local w:=_knob.LayoutSize.x
			Local h:=_knob.LayoutSize.y
			Select _location
			Case "top"
				_knob.Frame=New Recti( 0,Height-h,Width,Height )
				rect.Bottom-=h
			Case "bottom"
				_knob.Frame=New Recti( 0,0,Width,h )
				rect.Top+=h
			Case "left"
				_knob.Frame=New Recti( Width-w,0,Width,Height )
				rect.Right-=w
			Case "right"
				_knob.Frame=New Recti( 0,0,w,Height )
				rect.Left+=w
			End
		Endif
		
		_view.Frame=rect
	End

End

#rem monkeydoc The DockingView class.
#end
Class DockingView Extends View

	#rem monkeydoc Creates a new docking view.
	#end
	Method New()
		Style=GetStyle( "DockingView" )
	End
	
	#rem monkeydoc The content view.
	#end
	Property ContentView:View()

		Return _contentView
			
	Setter( contentView:View )
	
		If contentView=_contentView Return
		
		If _content RemoveChildView( _content )
		
		_contentView=contentView
		
		_content=ContentViewContainer( _contentView )
		
		If _content AddChildView( _content )
		
		App.RequestRender()
	End
	
	#rem monkeydoc Adds a view.
	
	`location` should be one of "left", "right", "top", "bottom".
	
	`size` can be either an integer number of pixels or a percentage. If no size is specified, the view's layout size is used.
	
	If `resizable` is true, the view can be resizable. Note: this must be used with `size` set to a non-0 integer.
	
	#end
	Method AddView( view:View,location:String )
	
		AddView( view,location,"",False )
	End
	
	Method AddView( view:View,location:String,size:String )
	
		AddView( view,location,size,False )
	End
	
	Method AddView( view:View,location:String,size:String,resizable:Bool )
	
		Local dock:=New DockedView( view,location,size,resizable )

		_docks.Add( dock )
		
		AddChildView( dock )
	End
	
	#rem monkeydoc Removes a view.
	#end
	Method RemoveView( view:View )
	
		Local dock:=FindView( view )
		If Not dock Return
		
		dock.View=Null
		
		_docks.Remove( dock )
		
		RemoveChildView( dock )
	End
	
	#rem monkeydoc Gets size of a view.
	#end
	Method GetViewSize:String( view:View )
	
		Return FindView( view ).Size
	End
	
	#rem monkeydoc Sets size of a view.
	#end
	Method SetViewSize( view:View,size:String )
	
		FindView( view ).Size=size
	End
	
	#rem monkeydoc Removes all views.
	#end
	Method RemoveAllViews()
	
		For Local dock:=Eachin _docks
		
			dock.View=Null
			
			RemoveChildView( dock )
		Next
		
		_docks.Clear()
		
		App.RequestRender()
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override

		Local size:=New Vec2i
		If _content size=_content.LayoutSize
		
		_docksSize=New Vec2i
		
		For Local dock:=Eachin _docks

			'FIXME - silly place to do this...
			dock.Visible=dock.View.Visible
			If Not dock.Visible Continue
	
			Select dock.Location
			Case "top","bottom"
				
				_docksSize.y+=dock.LayoutSize.y
				
				size.x=Max( size.x,dock.LayoutSize.x )
				size.y+=dock.LayoutSize.y
				
			Case "left","right"

				_docksSize.x+=dock.LayoutSize.x
			
				size.y=Max( size.y,dock.LayoutSize.y )
				size.x+=dock.LayoutSize.x
			End

		Next
		
		Return size
	End
	
	Method OnLayout() Override
	
		Local rect:=OnLayoutContent( Rect.Size-_docksSize )
		
		Local fsize:=rect.Size
		
		For Local dock:=Eachin _docks

			If Not dock.Visible Continue
		
			Select dock.Location
			Case "top"
			
				Local top:=rect.Top+dock.RealSize( fsize.y )
				
				If dock.Resizable And top>rect.Bottom top=rect.Bottom
'				If top>rect.Bottom top=rect.Bottom

				dock.Frame=New Recti( rect.Left,rect.Top,rect.Right,top )
				rect.Top=top
				
			Case "bottom"
			
				Local bottom:=rect.Bottom-dock.RealSize( fsize.y )
				
				If dock.Resizable And bottom<rect.Top bottom=rect.Top
'				If bottom<rect.Top bottom=rect.Top

				dock.Frame=New Recti( rect.Left,bottom,rect.Right,rect.Bottom )
				rect.Bottom=bottom
				
			Case "left"
			
				Local left:=rect.Left+dock.RealSize( fsize.x )
				
				If dock.Resizable And left>rect.Right left=rect.Right
'				If left>rect.Right left=rect.Right

				dock.Frame=New Recti( rect.Left,rect.Top,left,rect.Bottom )
				rect.Left=left
				
			Case "right"
				Local right:=rect.Right-dock.RealSize( fsize.x )
				
				If dock.Resizable And right<rect.Left right=rect.Left
'				If right<rect.Left right=rect.Left

				dock.Frame=New Recti( right,rect.Top,rect.Right,rect.Bottom )
				rect.Right=right
				
			End

		Next
		
		If _content _content.Frame=rect
	End
	
	Method OnLayoutContent:Recti( contentSize:Vec2i ) Virtual
		Return Rect
	End
	
	Method ContentViewContainer:View( contentView:View ) Virtual
		Return contentView
	End
	
	Private
	
	Field _content:View
	Field _contentView:View
	Field _docksSize:Vec2i
	
	Field _docks:=New Stack<DockedView>
	
	Method FindView:DockedView( view:View )
	
		For Local dock:=Eachin _docks
			If dock.View=view Return dock
		Next
		
		Return Null
	End

End
