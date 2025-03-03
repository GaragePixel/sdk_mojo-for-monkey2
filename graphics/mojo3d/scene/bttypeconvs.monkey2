
Namespace sdk_mojo.m3.bullet

Public

Using stdlib.math.. 'if the legacy std is in the modules folder, we need that

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct Vec3f Extension

	Operator To:btVector3()

		Return New btVector3( x,y,z )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct btVector3 Extension

	Operator To:Vec3f()

		Return New Vec3f( x,y,z )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct Vec4f Extension
	
	Operator To:btVector4()

		Return New btVector4( x,y,z,w )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct btVector4 Extension

	Operator To:Vec4f()
	
		Return New Vec4f( x,y,z,w )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct Mat3f Extension

	Operator To:btMatrix3x3()

		Return New btMatrix3x3( i.x,j.x,k.x, i.y,j.y,k.y, i.z,j.z,k.z )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct btMatrix3x3 Extension

	Operator To:Mat3f()
	
		Return New Mat3f( Cast<Vec3f>( getColumn(0) ),Cast<Vec3f>( getColumn(1) ),Cast<Vec3f>( getColumn(2) ) )
	End
End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct AffineMat4f Extension
	
	Operator To:btTransform()
	
		Return New btTransform( Cast<btMatrix3x3>( m ),Cast<btVector3>( t ) )
	End

End

#rem monkeydoc Extension methods for bullet type conversions.
#end
Struct btTransform Extension
	
	Operator To:AffineMat4f()
	
		Return New AffineMat4f( Cast<Mat3f>( getBasis() ),Cast<Vec3f>( getOrigin() ) )
	End

End
