
Namespace sdk_mojo.m3

'#Import "<stdlib>"

'Using stdlib..
Using sdk_mojo.m2..
Using sdk_mojo.m3..
Using sdk.api.opengl..
Using sdk.api.bullet..
Using stdlib.reflection..

#Import "assets/"

#Import "scene/raycastresult"
#Import "scene/component"
#Import "scene/entity"
#Import "scene/entityexts"
#Import "scene/scene"
#Import "scene/world"
#Import "scene/material"
#Import "scene/posteffect"

#Import "scene/components/animation"
#Import "scene/components/animator"
#Import "scene/components/rigidbody"
#Import "scene/components/collider"
#Import "scene/components/joint"
#Import "scene/components/behaviour"
#Import "scene/components/flybehaviour"
#Import "scene/components/movebehaviour"
#Import "scene/components/rotatebehaviour"

#Import "scene/entities/camera"
#Import "scene/entities/light"
#Import "scene/entities/pivot"
#Import "scene/entities/renderable"
#Import "scene/entities/model"
#Import "scene/entities/sprite"
#Import "scene/entities/particlebuffer"
#Import "scene/entities/particlematerial"
#Import "scene/entities/particlesystem"

#Import "scene/materials/pbrmaterial"
#Import "scene/materials/spritematerial"
#Import "scene/materials/watermaterial"

#Import "scene/effects/bloomeffect"
#Import "scene/effects/monochromeeffect"
#Import "scene/effects/reflectioneffect"
#Import "scene/effects/godrayseffect"
#Import "scene/effects/fxaaeffect"

#Import "scene/jsonifier/jsonifier"
#Import "scene/jsonifier/invocation"
#Import "scene/jsonifier/jsonifierexts"
#Import "scene/jsonifier/comparejson"

#Import "scene/mesh"
#Import "scene/meshprims"
#Import "scene/bttypeconvs"

#Import "render/renderer"
#Import "render/renderqueue"
#Import "render/spritebuffer"

#Import "loader/loader"
#Import "loader/gltf2"
#Import "loader/gltf2loader"

Function InitMojo3d()
	
#If __DESKTOP_TARGET__
	
	SetConfig( "MOJO_OPENGL_PROFILE","compatibility" )

	SetConfig( "MOJO3D_DEFAULT_RENDERER","deferred" )
	
#Elseif __WEB_TARGET__

	SetConfig( "MOJO_OPENGL_PROFILE","es" )

	SetConfig( "MOJO3D_DEFAULT_RENDERER","deferred" )
	
#Elseif __MOBILE_TARGET__
	
	SetConfig( "MOJO_OPENGL_PROFILE","es" )

	SetConfig( "MOJO3D_DEFAULT_RENDERER","forward" )
	
	SetConfig( "MOJO3D_FORWARD_RENDERER_DIRECT",1 )
	SetConfig( "MOJO_DEPTH_BUFFER_BITS",16 )
	
#endif

	SetConfig( "MOJO_DEPTH_BUFFER_BITS",16 )
	
End
