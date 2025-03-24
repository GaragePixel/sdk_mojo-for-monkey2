
Namespace sdk_mojo.m2.graphics.glutil

Private

'iDkP for GaragePixel: FIXED!
'	Instead of trying to solve the bizarro problem itself, 
'	I created a glStack from the original stdlib stack 
'	to create an int stack for the glShader to work on. 
'	I just came up with another way to tackle the problem, 
'	thanks to the Zen method of Michael Abrash.
'Using stdlib.collections..

'#If __DEBUG__
'	Using stdlib.collections..
'#End 

Global bindings:=New IntglStack

Public

Function glShaderSourceEx:Void( shader:GLuint,source:String )

	Local n:=source.Length
	Local buf:=Cast<Byte Ptr>( stdlib.plugins.libc.malloc( n+1 ) )
	For Local i:=0 Until n
		buf[i]=source[i]
	Next
	buf[n]=0
	
	Local p:=Cast<GLcchar Ptr>( buf )
	
	glShaderSource( shader,1,Varptr p,Null )
	
	stdlib.plugins.libc.free( buf )
End

Function glGetShaderInfoLogEx:String( shader:GLuint )

	Local buf:=New Byte[1024],length:GLsizei
	
	glGetShaderInfoLog( shader,buf.Length,Varptr length,Cast<GLchar Ptr>( Varptr buf[0] ) )
	
	Return String.FromCString( Varptr buf[0] )
End

Function glGetProgramInfoLogEx:String( program:GLuint )

	Local buf:=New Byte[1024],length:GLsizei
	
	glGetProgramInfoLog( program,buf.Length,Varptr length,Cast<GLchar Ptr>( Varptr buf[0] ) )
	
	Return String.FromCString( Varptr buf[0] )
End

#rem monkeydoc @hidden
#end
Global glDebug:Bool=False

#rem monkeydoc @hidden
#end
Global glGraphicsSeq:Int=1

#rem monkeydoc @hidden
#end
Global glRetroMode:Bool=False

#rem monkeydoc @hidden
#end
Global glRetroSeq:Int=1

#rem monkeydoc @hidden
#end
Function glInvalidateGraphics()
	
	glGraphicsSeq+=1
End

#rem monkeydoc @hidden
#end
Function glCheck()
	
	If Not glDebug Return
	
	Local err:=glGetError()
	If err=GL_NO_ERROR Return
	
	Local msg:=""
	Select err
	Case GL_INVALID_ENUM
		msg="INVALID_ENUM"
	Case GL_INVALID_VALUE
		msg="INVALID_VALUE"
	Case GL_INVALID_OPERATION
		msg="INVALID_OPERATION"
	Case GL_INVALID_FRAMEBUFFER_OPERATION
		msg="INVALID_FRAMEBUFFER_OPERATION"
	Case GL_OUT_OF_MEMORY
		msg="OUT_OF_MEMORY"
	Default
		msg="?????"
	End
	
	RuntimeError( "GL ERROR: "+msg+" "+err )
End

#rem monkeydoc @hidden
#end
Function glPushTexture:Void( target:GLenum,texture:GLuint )

	Assert( target=GL_TEXTURE_2D Or target=GL_TEXTURE_CUBE_MAP )
	
	Local binding:Int
	glGetIntegerv( target=GL_TEXTURE_2D ? GL_TEXTURE_BINDING_2D Else GL_TEXTURE_BINDING_CUBE_MAP,Varptr binding )

	bindings.Push( binding )
	bindings.Push( target )
	
	glBindTexture( target,texture )
End

#rem monkeydoc @hidden
#end
Function glPopTexture:Void()
	
	Local target:=bindings.Pop()
	Assert( target=GL_TEXTURE_2D Or target=GL_TEXTURE_CUBE_MAP )
	
	glBindTexture( target,bindings.Pop() )
End

#rem monkeydoc @hidden
#end
Function glPushBuffer( target:GLenum,buf:GLuint )
	
	Assert( target=GL_ARRAY_BUFFER Or target=GL_ELEMENT_ARRAY_BUFFER )
	
	Local binding:Int
	glGetIntegerv( target=GL_ARRAY_BUFFER ? GL_ARRAY_BUFFER_BINDING Else GL_ELEMENT_ARRAY_BUFFER_BINDING,Varptr binding )
	
	bindings.Push( binding )
	bindings.Push( target )
	
	glBindBuffer( target,buf )
End

#rem monkeydoc @hidden
#end
Function glPopBuffer()
	
	Local target:=bindings.Pop()
	Assert( target=GL_ARRAY_BUFFER Or target=GL_ELEMENT_ARRAY_BUFFER )
	
	glBindBuffer( target,bindings.Pop() )
End

#rem monkeydoc @hidden
#end
Function glPushFramebuffer:Void( target:GLenum,framebuf:GLuint )
	
	Assert( target=GL_FRAMEBUFFER )
	
	Local binding:Int
	glGetIntegerv( GL_FRAMEBUFFER_BINDING,Varptr binding )
	
	bindings.Push( framebuf )
	bindings.Push( target )
	
	glBindFramebuffer( target,framebuf )
End

#rem monkeydoc @hidden
#end
Function glPopFramebuffer:Void()
	
	Local target:=bindings.Pop()
	Assert( target=GL_FRAMEBUFFER )
	
	glBindFramebuffer( target,bindings.Pop() )
End

#rem monkeydoc @hidden
#end
Function glCompile:Int( type:Int,source:String )
	
	If BBGL_ES
	
		Local prefix:="
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif
"
		source=prefix+source
		
		If BBGL_draw_buffers source="#extension GL_EXT_draw_buffers : require~n"+source
			
'		If glexts.GL_standard_derivatives source="#extension GL_OES_standard_derivatives : require~n"+source
	Else
			
		Local prefix:="
#version 120
"
		source=prefix+source
	Endif
	
	Local shader:=glCreateShader( type )
	glShaderSourceEx( shader,source )
	glCompileShader( shader )
	
	Local status:Int
	glGetShaderiv( shader,GL_COMPILE_STATUS,Varptr status )
	If Not status
		
		Local lines:=source.Split( "~n" )
		
		For Local i:=0 Until lines.Length
			Print (i+1)+":~t"+lines[i]
		Next
		
		RuntimeError( "Failed to compile shader:"+glGetShaderInfoLogEx( shader ) )
	Endif
	Return shader
End

#rem monkeydoc @hidden
#end
Function glLink:Void( program:Int )
	glLinkProgram( program )

	Local status:Int
	glGetProgramiv( program,GL_LINK_STATUS,Varptr status )
	If Not status
		RuntimeError( "Failed to link program:"+glGetProgramInfoLogEx( program ) )
	Endif
End

Private 

'iDkP from GaragePixel
'	glStack in order to fix for good the dependancy issue.

#rem monkeydoc @hidden
#end
Alias IntglStack:glStack<Int>

#rem monkeydoc @hidden
#end
Class glStack<T> Implements IContainer<T>

	#rem monkeydoc The glStack.Iterator struct.
	#end
	Struct Iterator 'Implements IIterator<T>
	
		Private

		Field _stack:glStack
		Field _index:Int
		
		Method AssertCurrent()
			DebugAssert( _index<_stack._length,"Invalid stack iterator" )
		End
		
		Method New( stack:glStack,index:Int )
			_stack=stack
			_index=index
		End
		
		Public

		Property AtEnd:Bool()
			Return _index>=_stack._length
		End

		Property Current:T()
			AssertCurrent()
			Return _stack._data[_index]
		Setter( current:T )
			AssertCurrent()
			_stack._data[_index]=current
		End

		Method Bump()
			AssertCurrent()
			_index+=1
		End

		Method Erase()
			AssertCurrent()
			_stack.Erase( _index )
		End

		Method Insert( value:T )
			DebugAssert( _index<=_stack._length,"Invalid stack iterator" )
			_stack.Insert( _index,value )
		End
	End
	
	#rem monkeydoc The glStack.BackwardsIterator struct.
	#end
	Struct BackwardsIterator 'Implements IIterator<T>
	
		Private

		Field _stack:glStack
		Field _index:Int
		
		Method AssertCurrent()
			DebugAssert( _index>=0,"Invalid stack iterator" )
		End
		
		Method New( stack:glStack,index:Int )
			_stack=stack
			_index=index
		End
		
		Public
		
		#rem monkeydoc Checks if the iterator has reached the end of the stack.
		#end
		Property AtEnd:Bool()
			Return _index=-1
		End
		
		#rem monkeydoc The value currently pointed to by the iterator.
		#end
		Property Current:T()
			AssertCurrent()
			Return _stack._data[_index]
		Setter( current:T )
			AssertCurrent()
			_stack._data[_index]=current
		End
		
		#rem monkeydoc Bumps the iterator so it points to the next value in the stack.
		#end
		Method Bump()
			AssertCurrent()
			_index-=1
		End
		
		#rem monkeydoc Safely erases the value pointed to by the iterator.
		
		After calling this method, the iterator will point to the value after the removed value.
		
		Therefore, if you are manually iterating through a stack you should not call [[Bump]] after calling this method or you
		will end up skipping a value.
		
		#end
		Method Erase()
			AssertCurrent()
			_stack.Erase( _index )
			_index-=1
		End
		
		#rem monkeydoc Safely inserts a value before the value pointed to by the iterator.

		After calling this method, the iterator will point to the newly added value.
		
		#end
		Method Insert( value:T )
			DebugAssert( _index<_stack._length,"Invalid stack iterator" )
			_index+=1
			_stack.Insert( _index,value )
		End
	End
	
	Private

	Field _data:T[]
	Field _length:Int
	
	Public

	Method New()
		_data=New T[10]
	End
	
	Method New( length:Int )
		_length=length
		_data=New T[_length]
	End

	Method New( values:T[] )
		AddAll( values )
	End
	
	Method New( values:List<T> )
		AddAll( values )
	End
	
	Method New( values:Deque<T> )
		_length=values.Length
		_data=New T[_length]
		values.Data.CopyTo( _data,0,0,_length )
	End
	
	Method New( values:glStack<T> )
		_length=values.Length
		_data=New T[_length]
		values.Data.CopyTo( _data,0,0,_length )
	End

	Property Empty:Bool()
		Return _length=0
	End

	Method All:Iterator()
		Return New Iterator( Self,0 )
	End
	
	Method Backwards:BackwardsIterator()
		Return New BackwardsIterator( Self,_length-1 )
	End

	Method ToArray:T[]()
		Return _data.Slice( 0,_length )
	End

	Property Data:T[]()
		Return _data
	End
	
	Property Length:Int()
		Return _length
	End
	
	Property Capacity:Int()
		Return _data.Length
	End

	Method Compact()
		If _length<>_data.Length _data=_data.Slice( 0,_length )
	End
		
	Method Resize( length:Int )
		DebugAssert( length>=0 )
		
		For Local i:=length Until _length
			_data[i]=Null
		Next
		
		Reserve( length )
		_length=length
	End

	Method Reserve( capacity:Int )
		DebugAssert( capacity>=0 )
		
		If _data.Length>=capacity Return
		
		capacity=Max( _length*2,capacity )
		Local data:=New T[capacity]
		_data.CopyTo( data,0,0,_length )
		_data=data
	End
	

	Method Clear()
		Resize( 0 )
	End
	
	Method Erase( index:Int )
		DebugAssert( index>=0 And index<=_length )
		If index=_length Return
		
		_data.CopyTo( _data,index+1,index,_length-index-1 )
		Resize( _length-1 )
	End

	Method Erase( index1:Int,index2:Int )
		DebugAssert( index1>=0 And index1<=_length And index2>=0 And index2<=_length And index1<=index2 )
		
		If index1=_length Return
		_data.CopyTo( _data,index2,index1,_length-index2 )
		Resize( _length-index2+index1 )
	End
	
	Method Insert( index:Int,value:T )
		DebugAssert( index>=0 And index<=_length )
		
		Reserve( _length+1 )
		_data.CopyTo( _data,index,index+1,_length-index )
		_data[index]=value
		_length+=1
	End

	Method Get:T( index:Int )
		DebugAssert( index>=0 And index<_length,"glStack index out of range" )
		
		Return _data[index]
	End
	
	Method Set( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"glStack index out of range" )
		
		_data[index]=value
	End

	Operator []:T( index:Int )
		DebugAssert( index>=0 And index<_length,"glStack index out of range" )
		
		Return _data[index]
	End

	Operator []=( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"glStack index out of range" )
		
		_data[index]=value
	End

	Method Add( value:T )
		Reserve( _length+1 )
		_data[_length]=value
		_length+=1
	End

	Method AddAll( values:T[] )
		Reserve( _length+values.Length )
		values.CopyTo( _data,0,_length,values.Length )
		Resize( _length+values.Length )
	End

	Method AddAll<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End

	Method Append<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End
	
	Method FindIndex:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=start
		While i<_length
			If _data[i]=value Return i
			i+=1
		Wend
		Return -1
	End

	Method FindLastIndex:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=_length
		While i>start
			i-=1
			If _data[i]=value Return i
		Wend
		Return -1
	End

	Method Contains:Bool( value:T )
		Return FindIndex( value )<>-1
	End

	Method Remove:Bool( value:T,start:Int=0 )
		Local i:=FindIndex( value,start )
		If i=-1 Return False
		Erase( i )
		Return True
	End

	Method RemoveLast:Bool( value:T,start:Int=0 )
		Local i:=FindLastIndex( value,start )
		If i=-1 Return False
		Erase( i )
		Return True
	End
	
	Method RemoveEach:Int( value:T )
		Local put:=0,n:=0
		For Local get:=0 Until _length
			If _data[get]=value 
				n+=1
				Continue
			Endif
			_data[put]=_data[get]
			put+=1
		Next
		Resize( put )
		Return n
	End
		
	Method RemoveIf:Int( condition:Bool( value:T ) )
		Local put:=0,n:=0
		For Local get:=0 Until _length
			If condition( _data[get] )
				n+=1
				Continue
			Endif
			_data[put]=_data[get]
			put+=1
		Next
		Resize( put )
		Return n
	End
	
	Method Slice:glStack( index:Int )

		Return Slice( index,_length )
	End

	Method Slice:glStack( index1:Int,index2:Int )

		If index1<0
			index1=Max( index1+_length,0 )
		Else If index1>_length
			index1=_length
		Endif
		
		If index2<0
			index2=Max( index2+_length,index1 )
		Else If index2>_length
			index2=_length
		Else If index2<index1
			index2=index1
		Endif
		
		Return New glStack( _data.Slice( index1,index2 ) )
	End

	Method Swap( index1:Int,index2:Int )
		DebugAssert( index1>=0 And index1<_length And index2>=0 And index2<_length,"glStack index out of range" )
		
		Local t:=_data[index1]
		_data[index1]=_data[index2]
		_data[index2]=t
	End
	
	Method Swap( stack:glStack )
		Local data:=_data,length:=_length
		_data=stack._data
		_length=stack._length
		stack._data=data
		stack._length=length
	End
	
	Method Sort( ascending:Int=True )
		If ascending
			Sort( Lambda:Int( x:T,y:T )
				Return x<=>y
			End )
		Else
			Sort( Lambda:Int( x:T,y:T )
				Return y<=>x
			End )
		Endif
	End

	Method Sort( compareFunc:Int( x:T,y:T ) )
		Sort( compareFunc,0,_length-1 )
	End

	Method Sort( compareFunc:Int( x:T,y:T ),lo:Int,hi:int )
	
		If hi<=lo Return
		
		If lo+1=hi
			If compareFunc( _data[hi],_data[lo] )<0 Swap( hi,lo )
			Return
		Endif
		
		Local i:=(lo+hi)/2
		
		If compareFunc( _data[i],_data[lo] )<0 Swap( i,lo )

		If compareFunc( _data[hi],_data[i] )<0
			Swap( hi,i )
			If compareFunc( _data[i],_data[lo] )<0 Swap( i,lo )
		Endif
		
		Local x:=lo+1
		Local y:=hi-1
		Repeat
			Local p:=_data[i]
			While compareFunc( _data[x],p )<0
				x+=1
			Wend
			While compareFunc( p,_data[y] )<0
				y-=1
			Wend
			If x>y Exit
			If x<y
				Swap( x,y )
				If i=x i=y Else If i=y i=x
			Endif
			x+=1
			y-=1
		Until x>y

		Sort( compareFunc,lo,y )
		Sort( compareFunc,x,hi )
	End

	Property Top:T()
		DebugAssert( _length,"glStack is empty" )
		
		Return _data[_length-1]
	End

	Method Pop:T()
		DebugAssert( _length,"glStack is empty" )
		
		_length-=1
		Local value:=_data[_length]
		_data[_length]=Null
		Return value
	End

	Method Push( value:T )
		Add( value )
	End

	Method Join:String( separator:String ) Where T=String
		Return separator.Join( ToArray() )
	End
	
End
