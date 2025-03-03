
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class ClipView Extends View

	Method New()
		
		AcceptsMouseEvents=False
	End
	
	Property ContentView:View()
	
		Return _content
		
	Setter( contentView:View )
	
		If _content RemoveChildView( _content )
		
		_content=contentView
		
		If _content AddChildView( _content )
	End
	
	Property ContentFrame:Recti()
	
		Return _contentFrame
	
	Setter( contentFrame:Recti )
	
		_contentFrame=contentFrame
	End
	
	Private
	
	Field _content:View

	Field _contentFrame:Recti
	
	Method OnMeasure:Vec2i() Override
	
		If _content Return _content.LayoutSize
		
		Return New Vec2i
	End
	
	Method OnLayout() Override
	
		If _content _content.Frame=_contentFrame
	End
	
End

#rem monkeydoc The ScrollView class
#end
Class ScrollView Extends DockingView

	#rem monkeydoc Creates a new scroll view.
	#end
	Method New()
		Style=GetStyle( "ScrollView" )
		
		_clipper=New ClipView

		_scrollx=New ScrollBar( Axis.X )
		_scrollx.ValueChanged=Lambda( value:Int )
			_scroll.x=value
		End
		AddChildView( _scrollx )
		
		_scrolly=New ScrollBar( Axis.Y )
		_scrolly.ValueChanged=Lambda( value:Int )
			_scroll.y=value
		End
		AddChildView( _scrolly )
	End

	Method New( contentView:View )
		Self.New()
		
		ContentView=contentView
	End

	#rem monkeydoc Whether scroll bars are visible.
	#end
	Property ScrollBarsVisible:Bool()
	
		Return _scrollBarsVisible
	
	Setter( scrollBarsVisible:Bool )

		If scrollBarsVisible=_scrollBarsVisible Return
	
		_scrollBarsVisible=scrollBarsVisible
		
		App.RequestRender()
	End
	
	#rem moneydoc Current scroll x/y.
	#end
	Property Scroll:Vec2i()
	
		Return _scroll
	
	Setter( scroll:Vec2i )
	
		If Not _content Or _clipper.Frame.Empty Return
		
		Local fsize:=_clipper.Frame.Size
		
		scroll.x=Min( scroll.x,_clipper.ContentFrame.Width-fsize.x )
		scroll.x=Max( scroll.x,0 )
		
		scroll.y=Min( scroll.y,_clipper.ContentFrame.Height-fsize.y )
		scroll.y=Max( scroll.y,0 )
		
		If scroll=_scroll Return
		
		_scroll=scroll
		
		App.RequestRender()
	End
	
	#rem monkeydoc Currently visible rect.
	#end
	Property VisibleRect:Recti()
	
		Local marg:=_content.RenderStyle.Bounds
		
		Local scroll:=_scroll+marg.Origin
		
		Return New Recti( scroll,scroll+_clipper.Frame.Size )
	End

	#rem monkeydoc Ensures a rect is visible, modifying [[Scroll]] if necessary.
	#end	
	Method EnsureVisible( rect:Recti )
	
		If Not _content Or _clipper.Frame.Empty Return
		
		Local marg:=_content.RenderStyle.Bounds
		
		Local fsize:=_clipper.Frame.Size
		
		rect-=marg.Origin
		rect+=marg
		
		If rect.Right>_scroll.x+fsize.x
			_scroll.x=rect.Right-fsize.x
			App.RequestRender()
		Endif
		
		If rect.Left<_scroll.x
			_scroll.x=rect.Left
			App.RequestRender()
		Endif
		
		If rect.Bottom>_scroll.y+fsize.y
			_scroll.y=rect.Bottom-fsize.y
			App.RequestRender()
		Endif
		
		If rect.Top<_scroll.y
			_scroll.y=rect.Top
			App.RequestRender()
		Endif
		
	End
	
	Protected
	
	Method OnLayoutContent:Recti( contentSize:Vec2i ) Override
	
		If Not _content Return Rect
		
		Local rect:=Rect
		
		Local size:=Rect.Size
		
		Local csize:=contentSize
		
		Local vsize:=_content.Measure2( csize-New Vec2i( _scrolly.LayoutSize.x,0 ) )

		If _scrollBarsVisible

			Local xbar:=_scrollx.LayoutSize.y
			Local ybar:=_scrolly.LayoutSize.x
			
			If vsize.y<=csize.y
				If vsize.x<=csize.x xbar=0
			Else
				If vsize.x<=csize.x-ybar xbar=0
			Endif
			
			If vsize.y<=csize.y-xbar ybar=0

			csize.y-=xbar
			csize.x-=ybar

			If xbar
				rect.max.y-=xbar
				_scrollx.Visible=True
				_scrollx.Frame=New Recti( 0,size.y-xbar,size.x-ybar,size.y )
				_scrollx.PageSize=csize.x
				_scrollx.Maximum=vsize.x-csize.x
				_scrollx.Value=_scroll.x
			Else
				_scrollx.Visible=False
				_scrollx.Value=0
				vsize.x=csize.x
			Endif
			
			If ybar
				rect.max.x-=ybar
				_scrolly.Visible=True
				_scrolly.Frame=New Recti( size.x-ybar,0,size.x,size.y-xbar )
				_scrolly.PageSize=csize.y
				_scrolly.Maximum=vsize.y-csize.y
				_scrolly.Value=_scroll.y
			Else
				_scrolly.Visible=False
				_scrolly.Value=0
				vsize.y=csize.y
			Endif

		Else
		
			_scrollx.Visible=False
			_scrollx.PageSize=csize.x
			_scrollx.Maximum=vsize.x-csize.x
			_scrollx.Value=_scroll.x
			
			_scrolly.Visible=False
			_scrolly.PageSize=csize.y
			_scrolly.Maximum=vsize.y-csize.y
			_scrolly.Value=_scroll.y

		Endif
		
		_scroll.x=_scrollx.Value
		_scroll.y=_scrolly.Value
		
		_clipper.ContentFrame=New Recti( -_scroll,-_scroll+vsize )
		
		Return rect
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		If Not _content Return

		Select event.Type
		Case EventType.MouseWheel
		
			Local scroll:=_scroll
			
			Local delta:=New Vec2i( 0,_content.RenderStyle.Font.Height*event.Wheel.Y )
			
			Scroll-=delta
			
			If scroll<>_scroll event.Eat()
		End
	End
	
	Method ContentViewContainer:View( contentView:View ) Override
	
		_content=contentView
		
		_clipper.ContentView=contentView
		
		Return _clipper
	End
	
	Private
	
	Field _content:View
	
	Field _scroll:Vec2i

	Field _clipper:ClipView	
	Field _scrollx:ScrollBar
	Field _scrolly:ScrollBar
	
	Field _scrollBarsVisible:Bool=True
	
End
