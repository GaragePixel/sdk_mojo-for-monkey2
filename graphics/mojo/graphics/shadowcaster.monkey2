
Namespace sdk_mojo.m2.graphics

#rem monkeydoc The ShadowCaster class.
#end
Class ShadowCaster

	#rem monkeydoc Creates a new shadow caster.
	#end
	Method New()
	End
	
	Method New( rect:Rectf )
	
		_vertices=New Vec2f[]( rect.TopLeft,rect.TopRight,rect.BottomRight,rect.BottomLeft )
'		_vertices=New Vec2f[]( rect.TopLeft,rect.BottomLeft,rect.BottomRight,rect.TopRight )
	End
	
	Method New( radius:Float,segments:Int )
	
		_vertices=New Vec2f[segments]
		
		For Local i:=0 Until segments
			_vertices[i]=New Vec2f( Cos( i * TwoPi /segments )*radius,Sin( i * TwoPi / segments )*radius )
		Next
	End
	
	Method New( vertices:Vec2f[] )
	
		_vertices=vertices
	End

	#rem monkeydoc Shadow caster vertices.
	#end	
	Property Vertices:Vec2f[]()
	
		Return _vertices
	
	Setter( vertices:Vec2f[] )
	
		_vertices=vertices
	End
	
	Private
	
	Field _vertices:Vec2f[]
	
End

