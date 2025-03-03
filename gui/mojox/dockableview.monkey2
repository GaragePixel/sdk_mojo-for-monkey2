
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class DockableView Extends DockingView

	Method New()
		_content=New DockableContent( Self )
		
		ContentView=_content
	End
	
	Protected
	
	Method OnMeasureContent:Vec2i() Virtual
		Return New Vec2i( 0,0 )
	End
	
	Method OnMeasureContent2:Vec2i( size:Vec2i ) Virtual
		Return New Vec2i( 0,0 )
	End
	
	Method OnLayoutContent() Virtual
	End
	
	Method OnRenderContent( canvas:Canvas ) Virtual
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Virtual
	End
	
	Private
	
	Class DockableContent Extends View
	
		Method New( view:DockableView )
			Style=New Style( GetStyle( "" ) )
			
			_view=view
		End
		
		Protected
		
		Method OnValidateStyle() Override
		
			_view.ValidateStyle()
		End
		
		Method OnMeasure:Vec2i() Override
		
			Return _view.OnMeasureContent()
		End
		
		Method OnMeasure2:Vec2i( size:Vec2i ) Override
		
			Return _view.OnMeasureContent2( size )
		End
		
		Method OnLayout() Override
		
			_view.OnLayoutContent()
		End
		
		Method OnRender( canvas:Canvas ) Override
		
			canvas.Font=_view.RenderStyle.Font
			canvas.Color=_view.RenderStyle.TextColor
		
			_view.OnRenderContent( canvas )
		End
		
		Method OnMouseEvent( event:MouseEvent ) Override
		
			_view.OnContentMouseEvent( event )
		End
		
		Private
		
		Field _view:DockableView
	
	End
	
	Field _content:DockableContent
	
End
