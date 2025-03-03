
Namespace sdk_mojo.mx

#rem monkeydoc The ProgressBar class.
#end
Class ProgressBar Extends View

	#rem monkeydoc Creates a new progress bar.
	#end
	Method New( fps:Int=15,speed:Float=2 )
		Style=GetStyle( "ProgressBar" )
		
		Activated+=Lambda()
			_timer=New Timer( fps,Lambda()
				_scroll+=speed
				RequestRender()
			End )
		End
		
		Deactivated+=Lambda()
			_timer.Cancel()
		End
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Local icon:=RenderStyle.Icons[0]
		
		Return icon.Rect.Size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Local icon:=RenderStyle.Icons[0]
	
		Local w:=icon.Width
		Local h:=icon.Height
		
		Local color:=canvas.Color
		canvas.Color=RenderStyle.IconColor
		
		_scroll=_scroll Mod w
			
		For Local x:=_scroll-w+1 Until Width Step w
			canvas.DrawRect( x,0,w,Height,icon )
		Next
		
		canvas.Color=color
	End
	
	Private
	
	Field _timer:Timer
	
	Field _scroll:Float
	
End
