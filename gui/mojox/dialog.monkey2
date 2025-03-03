
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class DialogTitle Extends Button

	Field Dragged:Void( v:Vec2i )

	Method New( text:String="" )
		Super.New( text )
		
		Style=GetStyle( "DialogTitle" )
	End
	
	Private
	
	Field _org:Vec2i
	Field _drag:Bool
	Field _hover:Bool
	
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

End

#rem monkeydoc The dialog class.
#end
Class Dialog Extends View

	#rem monkeydoc Creates a new dialog.
	#end
	Method New()
	
		Style=GetStyle( "Dialog" )
		
		_title=New DialogTitle
		_title.Dragged=Lambda( vec:Vec2i )
			Frame+=vec
			RequestRender()
		End
		
		_content=New DockingView
		_content.Style=GetStyle( "DialogContent" )
		
		_actions=New DockingView
		_actions.Style=GetStyle( "DialogActions" )
		_actions.Layout="float"
		
		_docker=New DockingView

		_docker.AddView( _title,"top" )
		_docker.ContentView=_content
		_docker.AddView( _actions,"bottom" )
		
		AddChildView( _docker )
	End
	
	Method New( title:String,contentView:View=Null )
		Self.New()
		
		Title=title
		
		If contentView ContentView=contentView
	End
	
	#rem monkeydoc Dialog title.
	#end
	Property Title:String()
	
		Return _title.Text
	
	Setter( title:String )
	
		_title.Text=title
	End
	
	#rem monkeydoc Dialog content view.
	#end
	Property ContentView:View()
	
		Return _content.ContentView
	
	Setter( contentView:View )
	
		_content.ContentView=contentView
	End
	
	#rem monkeydoc Adds an action to the dialog.
	#end
	Method AddAction( action:Action )

		Local button:=New PushButton( action )
		
		_actions.AddView( button,"left" )
	End
	
	Method AddAction:Action( label:String,icon:Image=Null )
	
		Local action:=New Action( label,icon )
		AddAction( action )
		Return action
	End
	
	#rem monkeydoc Binds an action to a key.
	#end
	Method SetKeyAction( key:Key,action:Action )
	
		_keyActions[key]=action
	End

	#rem monkeydoc Opens the dialog.
	#end	
	Method Open()
		Assert( Not _window,"Dialog is already open" )
	
		_window=App.ActiveWindow
		
		Local size:=MeasureLayoutSize()
		
		Local origin:=(_window.Rect.Size-size)/2
		
		Frame=New Recti( origin,origin+size )
		
		_window.AddChildView( Self )
	End
	
	#rem monkeydoc Closes the dialog.
	#end
	Method Close()
		Assert( _window,"Dialog is not open" )
	
		_window.RemoveChildView( Self )
		
		_window=Null
	End

#if __TARGET__<>"emscripten"
	
	#rem monkeydoc Creates and runs a modal dialog.
	#end
	Function Run:Int( title:String,view:View,actions:String[],onEnter:Int=-1,onEscape:Int=-1 )
		
		Local dialog:=New Dialog( title )
		
		dialog.ContentView=view
		
		Local future:=New Future<Int>
		
		For Local i:=0 Until actions.Length
		
			Local action:=dialog.AddAction( actions[i] )
			
			action.Triggered=Lambda()
			
				future.Set( i )
			
			End

			If i=onEnter dialog.SetKeyAction( Key.Enter,action )
			
			If i=onEscape dialog.SetKeyAction( Key.Escape,action )
		Next
		
		dialog.Open()
		
		App.BeginModal( dialog )
		
		Local result:=future.Get()

		App.EndModal()
		
		dialog.Close()
		
		Return result
	End
	
	#end
	
	Protected
	
	Method OnMeasure:Vec2i() Override
		Return _docker.LayoutSize
	End
	
	Method OnLayout() Override
		_docker.Frame=Rect
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
			Local action:=_keyActions[event.Key]
			If action action.Trigger()
		End
		
		event.Eat()
	End
	
	Private
	
	Field _title:DialogTitle
	Field _content:DockingView
	Field _actions:DockingView
	Field _docker:DockingView
	
	Field _keyActions:=New Map<Key,Action>
	
	Field _window:Window
End

#rem monkeydoc The TextDialog class.
#end
Class TextDialog Extends Dialog

	#rem monkeydoc Creates a new text dialog.
	#end
	Method New( title:String="",text:String="" )
		Super.New( title )
		
		_label=New Label( text )
		_label.TextGravity=New Vec2f( .5,.5 )
		
		ContentView=_label
	End
	
	#rem monkeydoc Dialog text.
	#end
	Property Text:String()
	
		Return _label.Text
	
	Setter( text:String )
		
		_label.Text=text
	End
	
#if __TARGET__<>"emscripten"
	
	#rem monkeydoc Creates and runs a modal text dialog.
	#end
	Function Run:Int( title:String,text:String,actions:String[],onEnter:Int=-1,onEscape:Int=-1 )
	
		Local dialog:=New TextDialog( title,text )
		
		Local result:=New Future<Int>
		
		For Local i:=0 Until actions.Length
		
			Local action:=dialog.AddAction( actions[i] )
			
			action.Triggered=Lambda()
			
				result.Set( i )
			End
			
			If i=onEnter dialog.SetKeyAction( Key.Enter,action )
			
			If i=onEscape dialog.SetKeyAction( Key.Escape,action )
			
		Next
		
		dialog.Open()
		
		App.BeginModal( dialog )
		
		Local r:=result.Get()
		
		App.EndModal()
		
		dialog.Close()
		
		Return r
	End
	
	#end
	
	Private
	
	Field _label:Label
	
End

#rem monkeydoc The ProgressDialog class.
#end
Class ProgressDialog Extends Dialog

	#rem monkeydoc Creates a new progress dialog.
	#end
	Method New( title:String="",text:String="" )
		Super.New( title )
		
		_label=New Label( text )
		
		_progress=New ProgressBar
		
		Local docker:=New DockingView
		
		docker.AddView( _label,"top" )
		
		docker.AddView( _progress,"top" )
		
		ContentView=docker
	End
	
	#rem monkeydoc Dialog text.
	#end
	Property Text:String()
	
		Return _label.Text
	
	Setter( text:String )
		
		_label.Text=text
	End
	
	Private
	
	Field _label:Label
	
	Field _progress:ProgressBar
	
End
