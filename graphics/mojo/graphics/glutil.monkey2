
Namespace sdk_mojo.m2.graphics.glutil

Private

Using stdlib.collections..

Global bindings:=New IntStack

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
