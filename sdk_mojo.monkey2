
Namespace sdk_mojo

'Shoulds compile in 3 minutes and 45 seconds in release mode
'and 4 minutes and 39 seconds in debug mode.

#rem

#end 

#Import "<stdlib>"

'graphics

#Import "graphics/mojo/mojo"										'Graphics Framework
																	'depends:
																	'	emscripten (stdlib)
																	'	stdlib
																	'	sdl2 (stdlib)
																	'	opengl (sdk)
																	'	openal (sdk)
																	'	freetype (stdlib)
																	
#Import "graphics/mojo3d/mojo3d"									'Graphics Framework
																	'depends:
																	'	stdlib
																	'	mojo

#Import "graphics/mojo3d-vr/mojo3d-vr"								'Graphics Framework
																	'depends:
																	'	stdlib
																	'	mojo3d
'gui

#Import "gui/mojox/mojox"											'Graphics User Interface Framework
																	'depends:
																	'	stdlib
																	'	mojo
																	'	hoedown
																	'	litehtml

'medias

#Import "medias/loaders/mojo3d-loaders/mojo3d-loaders"				'Graphics Framework
																	'depends:
																	'	stdlib
																	'	assimp
																	'	mojo3d

#Import "medias/players/simplevideoplayer/simplevideoplayer"		'MediaPlayerApi
																	'depends:
																	'	stdlib
																	'	mojo
																	'	theoraplayer

'physics

#Import "physics/box2dext/box2dext"									'Physics Framework
																	'depends:
																	'	box2d (sdk)

#Import "physics/mx2_box2d/b2draw"									'Physics Framework
																	'depends:
																	'	box2d (sdk)

#Import "physics/mx2_box2d/b2joints"								'Physics Framework
																	'depends:
																	'	box2d (sdk)
Using sdk_mojo.m2

Using sdk_mojo.m3
																	
Function Main()
	
	'You can comment the mojo 3d's call if you are sure you don't need
	'it for your projet (recompile the library after that). 
	'Please note you don't need to do that with wx2cc (the wonkey
	'compiler), thank to its unused code cleaner.
	
	sdk_mojo.m2.InitMojo()
	
	sdk_mojo.m3.InitMojo3d()

	Print "sdk_mojo version 1.0 - 2025-02-26"
End 