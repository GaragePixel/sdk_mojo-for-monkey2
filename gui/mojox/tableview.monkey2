
Namespace sdk_mojo.mx

#rem monkeydoc The TableView class.
#end
Class TableView Extends ScrollView

	#rem monkeydoc Creates a new table view.
	#end
	Method New()
		Style=GetStyle( "TableView" )
		
		_docker=New DockingView
		
		ContentView=_docker
	End
	
	Method New( columns:Int,rows:Int=0 )
		Self.New()
		
		Columns=columns

		Rows=rows
	End
	
	Method New( columns:String[] )
		Self.New()
		
		For Local column:=Eachin columns
			AddColumn( column )
		Next
	End
	
	Property Columns:Int()
	
		Return _cols.Length
	
	Setter( columns:Int )
		DebugAssert( columns>=0 )
		
		If columns=_cols.Length Return
	
		Local n:=_cols.Length

		For Local i:=columns Until n
			_docker.RemoveView( _cols[i] )
		Next
		
		_cols.Resize( columns )
		
		For Local i:=n Until columns
			_cols[i]=New TableColumn( "",Null,_rowSizes )
			_docker.AddView( _cols[i],"left" )
		Next
		
		RequestRender()
	End
	
	Property Rows:Int()
	
		Return _numRows
	
	Setter( rows:Int )
		DebugAssert( rows>=0 )
		
		If rows=_numRows Return
	
		_numRows=rows
		
		_rowSizes.Resize( _numRows )
	
		For Local col:=Eachin _cols
			col._rows.Resize( _numRows )
		Next
		
		RequestRender()
	End
	
	#rem monkeydoc Adds a column.
	
	Returns index of new column.
	
	@return Index of new column.
	#end	
	Method AddColumn:Int( text:String="",icon:Image=Null,size:String="",draggable:Bool=False )

		Local col:=New TableColumn( text,icon,_rowSizes )

		_docker.AddView( col,"left",size,draggable )

		_cols.Push( col )
		
		Return _cols.Length-1
	End

	
	#rem monkeydoc Adds rows.
	
	Returns index of first row added.
	
	@return Index of first row added.
	
	#end
	Method AddRows:Int( num:Int )
	
		_numRows+=num
		_rowSizes.Resize( _numRows )
	
		For Local col:=Eachin _cols
			col.Rows.Resize( _numRows )
		Next
		
		Return _numRows-num
	End
	
	#rem monkeydoc Removes all rows.
	#end
	Method RemoveAllRows()
	
		For Local col:=Eachin _cols
			For Local row:=0 Until _numRows
				col.SetView( row,Null )
			Next
			col.Rows.Clear()
		Next
		
		_rowSizes.Clear()
		
		_numRows=0
	End
	
	#rem monkeydoc Removes all rows and columns.
	#end
	Method RemoveAll()
	
		RemoveAllRows()
	
		_docker.RemoveAllViews()
		
		_cols.Clear()
	End
	
	#rem monkeydoc Gets the view at a cell location.
	#end
	Operator[]:View( col:Int,row:Int )
		Assert( col>=0 And col<_cols.Length And row>=0 And row<_numRows )
	
		Return _cols[col].Rows[row]
	End
	
	#rem monkeydoc Sets the view at a cell location.
	#end
	Operator[]=( col:Int,row:Int,view:View )
		Assert( col>=0 And col<_cols.Length And row>=0 And row<_numRows )
		
		_cols[col].SetView( row,view )
	End
	
	#rem monkeydoc Number of columns.
	
	Deprecated! Use [[Columns]] property instead.
	
	#end
	Property NumColumns:Int()
	
		Return _cols.Length
	End
	
	#rem monkeydoc Number of rows.

	Deprecated! Use [[Rows]] property instead.

	#end
	Property NumRows:Int()
	
		Return _numRows
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
		
		Local h:=0
		For Local i:=0 Until _rowSizes.Length
			h+=_rowSizes[i]
		Next
		
		size.y=Max( h,size.y )
		
		Return size
	End
	
	Method OnLayout() Override
	
		Super.OnLayout()
		
		For Local i:=0 Until _rowSizes.Length
'			_rowSizes[i]=0
		Next
	End
	
	Private
	
	Class TableColumn Extends View
	
		Method New( text:String,icon:Image,rowSizes:Stack<Int> )
			
			Style=GetStyle( "TableColumn" )
			
			_rowSizes=rowSizes
			
			_header=New Label( text,icon )
			
			_header.Style=GetStyle( "TableHeader" )
			
			AddChildView( _header )
			
			_rows.Resize( _rowSizes.Length )
		End
		
		Property Rows:Stack<View>()
		
			Return _rows
		End
		
		Method SetView( row:Int,view:View )
		
			If _rows[row] RemoveChildView( _rows[row] )
			
			_rows[row]=view
			
			If _rows[row] AddChildView( _rows[row] )
		End
		
		Protected
		
		Method OnMeasure:Vec2i() Override
		
			Local size:=_header.LayoutSize
			
			For Local i:=0 Until _rows.Length
			
				Local view:=_rows[i]
				If Not view Continue
				
				_rowSizes[i]=Max( _rowSizes[i],view.LayoutSize.y )
				
				size.x=Max( size.x,view.LayoutSize.x )
				
				size.y+=view.LayoutSize.y
			Next
			
			Return size
		End

		Method OnLayout() Override
		
			_header.Frame=New Recti( 0,0,Width,_header.LayoutSize.y )
			
			Local y:=_header.LayoutSize.y
			
			For Local i:=0 Until _rows.Length
				
				Local view:=_rows[i]
				
				Local y2:=y+_rowSizes[i]
				If view view.Frame=New Recti( 0,y,Width,y2 )
				y=y2
				
			Next
		End
		
		Private
		
		Field _header:Label
		
		Field _rowSizes:Stack<Int>
		
		Field _rows:=New Stack<View>
	End
	
	Field _docker:DockingView
	
	Field _numRows:Int
	
	Field _rowSizes:=New Stack<Int>
	
	Field _cols:=New Stack<TableColumn>
	
End
