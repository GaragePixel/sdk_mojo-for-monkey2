
Namespace sdk_mojo.mx

#rem monkeydoc @hidden
#end
Class TabButton Extends Button

	Field CloseClicked:Void()

	Method New( text:String,icon:Image,view:View,closable:bool )
		Super.New( text,icon )
		
		Style=GetStyle( "TabButton" )
		
		_view=view
		
		If closable

			_close=New Button
			_close.Style=GetStyle( "TabClose" )
			_close.Icon=_close.Style.Icons[0]
			_close.Clicked=Lambda()
				CloseClicked()
			End
		
			AddView( _close )
		Endif
	End
	
	Property View:View()
	
		Return _view
	
	Setter( view:View )
	
		_view=view
	End
	
	Private
	
	Field _button:Button
	Field _close:Button
	
	Field _view:View

End

#rem monkeydoc @hidden
#end
Class TabBar Extends ToolBar

	Method New()
		Style=GetStyle( "TabBar" )
		Layout="fill-x"
	End
	
End

#rem monkeydoc The TabViewFlags enum.

Tab view flags:

| TabViewFlags	| Description
|:--------------|:-----------
| ClosableTabs	| Tabs can be closed.
| DraggableTabs	| Tabs can be dragged.

#end
Enum TabViewFlags
	ClosableTabs=1
	DraggableTabs=2
End

#rem monkeydoc The TabView class.
#end
Class TabView Extends DockingView

	#rem monkeydoc Invoked when the current tab changes.
	#end
	Field CurrentChanged:Void()
	
	#rem monkeydoc @hidden
	#end
	Field Clicked:Void()
	
	#rem monkeydoc Invoked when a tab is right clicked.
	#end
	Field RightClicked:Void()
	
	#rem monkeydoc Invoked when a tab is double clicked.
	#end
	Field DoubleClicked:Void()
	
	#rem monkeydoc Invoked when a tab is double clicked.
	#end
	Field CloseClicked:Void( index:Int )

	#rem monkeydoc Invoked when a tab is dragged.
	#end	
	Field Dragged:Void()

	#rem monkeydoc Creates a new tab view.
	#end
	Method New( flags:TabViewFlags=Null )
	
		_flags=flags
		
		Style=GetStyle( "TabView" )
		Layout="fill"
		_tabBar=New TabBar
		
		AddView( _tabBar,"top" )
	End
	
	#rem monkeydoc Tab view flags.
	#end
	Property Flags:TabViewFlags()
	
		Return _flags
	End
	
	#rem monkeydoc Number of tabs
	#end
	Property NumTabs:Int()
	
		Return _tabs.Length
	End
	
	#rem monkeydoc The current index.
	#end
	Property CurrentIndex:Int()

		If _current Return TabIndex( _current.View )

		Return -1
		
	Setter( currentIndex:Int )
	
		MakeCurrent( _tabs[currentIndex],False )
	End
	
	#rem monkeydoc The current view.
	#end
	Property CurrentView:View()
	
		If _current Return _current.View

		Return Null
	
	Setter( currentView:View )
	
		MakeCurrent( _tabs[ TabIndex( currentView ) ],False )
	End

	#rem monkeydoc Gets a tab's view.
	#end
	Method TabView:View( index:Int )
		Assert( index>=0 And index<_tabs.Length,"Tab index out of range" )
	
		Return _tabs[index].View
	End

	#rem monkeydoc Gets a tab's index.
	#end
	Method TabIndex:Int( view:View )
	
		For Local i:=0 Until _tabs.Length
			If _tabs[i].View=view Return i
		Next

		Return -1
	End

	#rem monkeydoc Adds a tab.
	#end	
	Method AddTab:Int( text:String,view:View,makeCurrent:Bool=False )
	
		Return AddTab( text,Null,view,makeCurrent )
	End

	Method AddTab:Int( text:String,icon:Image,view:View,makeCurrent:Bool=False )
	
		Assert( TabIndex( view )=-1,"View has already been added to TabView" )
	
		Local tab:=New TabButton( text,icon,view,_flags & TabViewFlags.ClosableTabs )
		
		tab.Clicked=Lambda()
		
			MakeCurrent( tab,True )

			Clicked()
		End
		
		tab.RightClicked=Lambda()
		
			MakeCurrent( tab,True )
			
			RightClicked()
		End
		
		tab.DoubleClicked=Lambda()
		
			MakeCurrent( tab,True )
			
			DoubleClicked()
		End
		
		tab.Dragged+=Lambda( v:Vec2i )
		
			If Not (_flags & TabViewFlags.DraggableTabs) return

			Local mx:=_tabBar.MouseLocation.x
			If mx<0 Return
			
			Local w:=tab.Bounds.Width

			Local x:=0,i:=_tabs.Length
			For Local j:=0 Until i

				If mx<x+w
					i=j
					Exit
				Endif
				
				If tab=_tabs[j] Continue
				
				x+=_tabs[j].Bounds.Width
				If mx<x Return
			Next
			
			Local i2:=_tabs.FindIndex( tab )
			If i=i2 Return

			If i>i2 i-=1
			
			_tabs.Erase( i2 )
			_tabs.Insert( i,tab )
			
			_tabBar.RemoveAllViews()
			For Local view:=Eachin _tabs
				_tabBar.AddView( view )
			Next

			RequestRender()
			
			Dragged()
		End
		
		tab.CloseClicked=Lambda()
		
			CloseClicked( TabIndex( tab.View ) )
		End
		
		Local index:=_tabs.Length

		_tabBar.AddView( tab )
		_tabs.Push( tab )
		
		If makeCurrent CurrentIndex=index

		Return index
	End
	
	#rem monkeydoc Removes a tab.
	#end
	Method RemoveTab( index:Int )
	
		If _current=_tabs[index]
			_current.Selected=False
			_current=Null
			ContentView=Null
		Endif
		
		_tabBar.RemoveView( _tabs[index] )
		_tabs.Erase( index )
	End
	
	Method RemoveTab( view:View )
	
		RemoveTab( TabIndex( view ) )
	End
	
	Method SetTabView( index:Int,view:View )
	
		_tabs[index].View=view
		
		If _tabs[index]=_current ContentView=view
	End
	
	Method SetTabView( view:View,newView:View )

		SetTabView( TabIndex( view ),newView )
	End
	
	#rem monkeydoc Sets a tab's text.
	#end
	Method SetTabText( index:Int,text:String )
	
		_tabs[index].Text=text
	End
	
	Method SetTabText( view:View,text:String )
	
		SetTabText( TabIndex( view ),text )
	End
	
	#rem monkeydoc Sets a tab's icon.
	#end
	Method SetTabIcon( index:Int,icon:Image )
	
		_tabs[index].Icon=icon
	End
	
	Method SetTabIcon( view:View,icon:Image )
	
		SetTabIcon( TabIndex( view ),icon )
	End
	
	Private
	
	Field _flags:TabViewFlags
	
	Field _tabBar:TabBar
	
	Field _tabs:=New Stack<TabButton>
	
	Field _current:TabButton
	
	Method MakeCurrent( tab:TabButton,notify:Bool )
	
		If tab=_current Return
		
		If _current _current.Selected=False
		
		ContentView=tab.View
		
		_current=tab
		
		If _current _current.Selected=True
		
		If notify CurrentChanged()
	End
	
End
