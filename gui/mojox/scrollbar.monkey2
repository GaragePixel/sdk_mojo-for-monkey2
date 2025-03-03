
Namespace sdk_mojo.mx

#rem monkeydoc The ScrollBar class.
#end
Class ScrollBar Extends View

	#rem monkeydoc Invoked when the user drags the scroll knob.
	#end
	Field ValueChanged:Void( value:Int )

	#rem monkeydoc Creates a new scroll bar.
	#end
	Method New( axis:Axis=stdlib.math.coordinates.Axis.X )

		Style=GetStyle( "ScrollBar" )

		_axis=axis

		Local taxis:=_axis=Axis.X ? "x" Else "y"
		
'		Style=GetStyle( "ScrollBar:"+taxis )

'		_knobStyle=GetStyle( "ScrollKnob:"+taxis )
	End
	
	#rem monkeydoc The scroll bar axis.
	#end
	Property Axis:Axis()
	
		Return _axis
		
	Setter( axis:Axis )

		If axis=_axis Return
	
		_axis=axis
		
		App.RequestRender()
	End
	
	#rem monkeydoc The scroll bar page size.
	#end
	Property PageSize:Int()
	
		Return _pageSize
		
	Setter( pageSize:Int )

		If pageSize=_pageSize Return
	
		_pageSize=pageSize
		
		App.RequestRender()
	End
	
	#rem monkeydoc The scroll bar value.
	#end
	Property Value:Int()
	
		Return _value
		
	Setter( value:Int )
	
		value=Clamp( value,_minimum,_maximum )
		
		If value=_value Return
	
		_value=value
		
		App.RequestRender()
	End
	
	#rem monkeydoc The scroll bar minimum value.
	#end
	Property Minimum:Int()
	
		Return _minimum
		
	Setter( minimum:Int )
	
		If minimum=_minimum Return
	
		_minimum=minimum
		
		_value=Max( _value,_minimum )
		
		App.RequestRender()
	End
	
	#rem monkeydoc The scroll bar maximum value.
	#end
	Property Maximum:Int()
	
		Return _maximum
		
	Setter( maximum:Int )
		If maximum=_maximum Return
	
		_maximum=maximum
		
		_value=Min( _value,_maximum )

		App.RequestRender()
	End
	
	Protected
	
	Field _axis:Axis
	Field _value:Int
	Field _minimum:Int
	Field _maximum:Int
	Field _pageSize:Int=1
	
	Field _knobStyle:Style
	Field _knobRect:Recti
	
	Field _drag:Bool
	Field _hover:Bool
	
	Field _offset:Int
	
	Method OnValidateStyle() Override
		
		_knobStyle=GetStyle( "ScrollKnob" )
	End
	
	Method OnMeasure:Vec2i() Override
	
		Return _knobStyle.Bounds.Size
	End
	
	Method OnLayout() Override
	
		Local range:=_maximum-_minimum+_pageSize
		
		Select _axis
		Case Axis.X
		
			Local sz:=range ? Max( _pageSize*Width/range,16 ) Else Width
			Local pos:=_maximum>_minimum ? (_value-_minimum)*(Width-sz)/(_maximum-_minimum) Else 0
			
			_knobRect=New Recti( pos,0,pos+sz,Height )
		
'			Local min:=(_value-_minimum)*Width/range
'			Local max:=(_value-_minimum+_pageSize)*Width/range
			
'			_knobRect=New Recti( min,0,max,16 )
			
		Case Axis.Y
		
			Local sz:=range ? Max( _pageSize*Height/range,16 ) Else Height
			Local pos:=_maximum>_minimum ? (_value-_minimum)*(Height-sz)/(_maximum-_minimum) Else 0
			
			_knobRect=New Recti( 0,pos,Width,pos+sz )
			
'			Local min:=(_value-_minimum)*Height/range
'			Local max:=(_value-_minimum+_pageSize)*Height/range
			
'			_knobRect=New Recti( 0,min,16,max )
		End
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If _maximum=_minimum Return
		
		Local style:=_knobStyle
		
		If _drag style=style.GetState( "active" ) Else If _hover style=style.GetState( "hover" )

		style.Render( canvas,_knobRect )
	End

	Method OnMouseEvent( event:MouseEvent ) Override
	
		Local p:=event.Location
		
		Local value:=_value
		Local drag:=_drag,hover:=_hover
		Local range:=_maximum-_minimum+_pageSize
		
		Select event.Type
		Case EventType.MouseDown
		
			If _knobRect.Contains( p )
			
				Select _axis
				Case Axis.X
					_offset=p.x*range/Rect.Width-_value
				Case Axis.Y
					_offset=p.y*range/Rect.Height-_value
				End
				_drag=True
				
			Else If _axis=Axis.X

				If p.x<_knobRect.Left 
					_value-=_pageSize
				Else If p.x>=_knobRect.Right
					_value+=_pageSize
				Endif
				
			Else If _axis=Axis.Y
			
				If p.y<_knobRect.Top
					_value-=_pageSize
				Else If p.y>=_knobRect.Bottom
					_value+=_pageSize
				Endif
				
			Endif
			
		Case EventType.MouseMove
		
			If _drag
			
				Local range:=_maximum-_minimum+_pageSize
				
				Select _axis
				Case Axis.X
					_value=p.x*range/Rect.Width-_offset
				Case Axis.Y
					_value=p.y*range/Rect.Height-_offset
				End
				
			Else If _knobRect.Contains( p )
			
				_hover=True
				
			Else
			
				_hover=False
			Endif
			
		Case EventType.MouseLeave
		
			_hover=False
			
		Case EventType.MouseUp
		
			_drag=False
		End
		
		_value=Clamp( _value,_minimum,_maximum )
		
		If _value<>value Or _drag<>drag Or _hover<>hover
			If _value<>value ValueChanged( _value )
			App.RequestRender()
		Endif
		
		event.Eat()
	End

End
