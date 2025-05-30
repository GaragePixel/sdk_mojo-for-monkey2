
Namespace sdk_mojo.m2.graphics

Using stdlib.math.matrices..

Using stdlib.graphics..

#rem 
2025-05-28 GaragePixel added: Draw sublibrary draw methods integration (Trect9 too, now called TPatches, Fit called Rect)
2025-05-26 GaragePixel added: Draw sublibrary, DrawImageTiled, DrawImageFit, Rect9's draw funcs
2021-05-24 Danilo added: DrawOval now middlepoint (like circle), ColorMask Property
2021-05-15 Danilo added: DrawRoundedRect, DrawChamferRect
2021-05-15 Danilo added: DrawCross, DrawX, DrawTarget, DrawTriangle, DrawDiamond, DrawSquare, DrawGrid
2021-05-15 Danilo added: DrawFrameRoundedRect, DrawFrameChamber, DrawFrameTriangle, DrawFrameDiamond, DrawFrameSquare, DrawFrameCircle, DrawFrameOval, DrawFrameOvalDepth
2021-05-15 Seyhajin added: _width/_height pre-assignation in creator and assignation in Resize() and new creator using width/height properties, and added Width, Height properties
2021-01-28 Seyhajin added: Get an integer packed color from rgba inputs (0..255)
2021-01-20 Seyhajin added: DrawImageIcon
2021-01-13 Seyhajin modded: DrawImageQuad, DrawImage (added shader:Shader=null param)
2021-01-13 (1st Commit Wonkey) Seyhajin added: _userUnfiformCallback, _pmcolor2, _color2, _xyzPosition, draw/image helpers, or new overloads/fields
2018-01-30 Sibly added: Overhaul of render batching
2017-07-19 Sibly added: Color, matrix, and blendmode upgrades
2017-03-12 Sibly added: Font/DrawText pipeline tweaks
2017-01-24 Sibly added: DrawImageQuad
2016-12-08 Sibly added: DrawImage/DrawImageRect, batching improvements (render pipeline logic)
2016-11-10 Sibly added: Initial commit. Draw funcs: DrawRect, DrawOval, DrawLine, Styling: Field/prop management for color, matrix, blend modes, etc, Render pipeline logic: Core batching (the drawops stack), flush, clipping, scissoring, viewport, blend and transformation matrix handling
#end 

#Rem 

	The drawing methods of the Canvas class are deprecated. 
	You can still use them and they will remain so until the next language release (2026). 

	If you choose to use Mx2cc's stdlib and sdk_mojo, the drawing methods will be deprecated 
	and deleted after version 2025-09. This means that the examples will be changed 
	and it will be harder to adapt them from Mx2 to W as easily as before, 
	because you won't have to change only the dependencies, but also every drawing method in your programs.
	
	Technical stuff (TODO):
	Overriding the drawing methods will cause changes in App.Style and App.Skin file (Drawrect) and 
	in the Image file (DrawImage).
#end 

#rem wonkeydoc Converts 4 bytes or ints to a packed integer color
@author jl
@since 2021-01-28
Get an integer packed color from rgba inputs (0..255)
#end
Function ICol:UInt( r:Int, g:Int, b:Int, a:Int = 255 )
	'Note: jl math functions moved to wonkey.math
	r = Clamp(r, 0, 255)
	g = Clamp(g, 0, 255)
	b = Clamp(b, 0, 255)
	a = Clamp(a, 0, 255)
	Return UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
End

#rem monkeydoc Outline modes.

Outline modes are used with the [[Canvas.OutlineMode]] property and control the style
of outline drawn.

| OutlineMode	| Description
|:--------------|:-----------
| None			| Outlines disabled.
| Solid			| Solid outlines.
| Smooth		| Smooth outlines.

#end
Enum OutlineMode
	None=0
	Solid=1
	Smooth=2
End

' Define the concrete type alias for Monkey2's Canvas
' Added by iDkP
Alias FrameBufferMojo:FrameBuffer<Canvas,Image,Texture>

' Define the concrete type alias for Monkey2's Canvas
' Added by iDkP
Alias CanvasWrapperMojo:CanvasWrapper<Canvas,Image,Texture>

' Define the concrete type alias for Monkey2's Mojo implementation
' Added by iDkP
'Alias ImageBufferMojo:ImageBuffer<Canvas,Image,Texture>

' Define the concrete type alias for Monkey2's Mojo Canvas, Image and Texture
' Added by iDkP
'Alias FrameBufferMojo:FrameBuffer<Canvas,Image,Texture>

#rem monkeydoc The Canvas class.

Canvas objects are used to perform rendering to either a mojo [[View]] or an 'off screen' [[Image]].

To draw to a canvas, use one of the 'Draw' methods. Drawing is affected by a number of draw states, including:

* [[Color]] - the current drawing color. This is combined with the current alpha to produce the final rendering color and alpha values.
* [[Alpha]] - the current drawing alpha level.
* [[Matrix]] - the current drawing matrix. All drawing coordinates are multiplied by this matrix before rendering.
* [[BlendMode]] - the blending mode for drawing, eg: opaque, alpha, additive, multiply.
* [[Viewport]] - the current viewport. All drawing coordinates are relative to the top-left of the viewport.
* [[Scissor]] - the current scissor rect. All rendering is clipped to the union of the viewport and the scissor rect.
* [[Font]] - The current font to use when drawing text with [[DrawText]].

Drawing does not occur immediately. Drawing commands are 'buffered' to reduce the overhead of sending lots of draw calls to the lower level graphics API. You can force all drawing commands in the buffer to actually render using [[Flush]].

#end
Class Canvas
	
	#rem monkeydoc Creates a canvas that renders to an image
	#end
	Method New( image:Image )
		
		Local rtarget:=New RenderTarget( New Texture[]( image.Texture ),Null )
		
		Init( rtarget,New GraphicsDevice )
		
		BeginRender( New Recti( 0,0,image.Rect.Size ),AffineMat3f.Translation( image.Rect.Origin ) )
	End

	#rem monkeydoc @hidden Creates a canvas that renders to the backbuffer.
	#end	
	Method New( width:Int,height:Int )
		
		Init( Null,New GraphicsDevice( width,height ) )
	End

	#rem monkeydoc @hidden Resizes a canvas that renders to the backbuffer.
	#end	
	Method Resize( size:Vec2i )
		
		_device.Resize( size )
	End

	#rem monkeydoc @hidden
	#end	
	Method BeginRender( bounds:Recti,matrix:AffineMat3f )
	
		Flush()
		
		_rmatrixStack.Push( _rmatrix )
		_rboundsStack.Push( _rbounds )
		
		_rmatrix*=matrix
		_rbounds&=TransformRecti( bounds,_rmatrix )

		Viewport=bounds
		Scissor=New Recti( 0,0,bounds.Size )
		AmbientLight=Color.Black
		BlendMode=BlendMode.Alpha
		PointSize=0
		LineWidth=0
		LineSmoothing=False
		TextureFilteringEnabled=true
		OutlineMode=OutlineMode.None
		'OutlineColor=Color.Yellow 'Added iDkP (should introduce a Mojo debugmode?)
		OutlineWidth=0
		
		ClearMatrix()
	End
	
	#rem monkeydoc @hidden
	#end	
	Method EndRender()
	
		If _lighting EndLighting()
		
		Flush()
		
		_rbounds=_rboundsStack.Pop()
		_rmatrix=_rmatrixStack.Pop()
	End

	#rem monkeydoc Get access to the Draw methods.
	@author iDkP from GaragePixel
	@since 2025-05-25
	#end
	Property Draw:TDraw() 'Added by iDkP
		Return _tdraw
	End	

	#rem monkeydoc Get access to the Transform methods.
	@author iDkP from GaragePixel
	@since 2025-05-29
	#end
	Property Transform:TTransform()
		Return _ttransform
	End

	#rem wonkeydoc The current canvas width
	#end
	Property Width:Int()
		'jl added
		Return _width
	End
	#rem wonkeydoc The current canvas height
	#end
	Property Height:Int()
		'jl added
		Return _height
	End
	
	#rem monkeydoc The current render target.
	#end	
	Property RenderTarget:RenderTarget()
	
		Return _rtarget
	End
	
	#rem monkeydoc The current viewport.
	The viewport describes the rect within the render target that rendering occurs in.
	All rendering is relative to the top-left of the viewport, and is clipped to the intersection of the viewport and scissor rects.
	This property must not be modified if the canvas is in lighting mode.
	#end
	Property Viewport:Recti()
	
		Return _viewport
	
	Setter( viewport:Recti )
		DebugAssert( Not _lighting,"Canvas.Viewport property cannot be modified while lighting" )
		If _lighting return

		Flush()
			
		_viewport=viewport
		
		_dirty|=Dirty.Viewport|Dirty.Scissor
	End

	#rem monkeydoc The current scissor rect.
	The scissor rect is a rect within the viewport that can be used for additional clipping.
	Scissor rect coordinates are relative to the current viewport rect, but are not affected by the current drawing matrix.
	This property must not be modified if the canvas is in lighting mode.
	#end
	Property Scissor:Recti()
	
		Return _scissor
	
	Setter( scissor:Recti )
		DebugAssert( Not _lighting,"Canvas.Scissor property cannot be modified while lighting" )
		If _lighting return
	
		Flush()
	
		_scissor=scissor
		
		_dirty|=Dirty.Scissor
	End
	
	#rem monkeydoc Ambient light color for lighting mode.
	Sets the ambient light color for lighting.
	This property cannot be modified if the canvas is already in lighting mode.
	#end
	Property AmbientLight:Color()
	
		Return _ambientLight
	
	Setter( ambient:Color )
		DebugAssert( Not _lighting,"Canvas.AmbientLight property cannot be modified while lighting" )
		If _lighting return
	
		_ambientLight=ambient
	End
	
	#rem monkeydoc The current drawing blend mode.
	#end	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
	End
	
	#rem monkeydoc TODO! Texture filtering enabled state.
	Set to true for normal behavior.
	Set to false for a groovy retro effect.
	#end	
	Property TextureFilteringEnabled:Bool()
		
		Return Not _device.RetroMode
		
	Setter( enabled:Bool )
		DebugAssert( Not _lighting,"Canvas.TextureFilteringEnabled property cannot be modified while lighting" )
		If _lighting Return
		
		Local rmode:=Not enabled
		
		If rmode=_device.RetroMode Return
		
		Flush()

		_device.RetroMode=rmode
	End

	'jl added
	Field _textureFilter2:bool = True
	Property TextureFiltering:Bool()
		Return _textureFilter2
	Setter( enabled:Bool )
		_textureFilter2 = enabled
	End
	
	#rem monkeydoc The current point size for use with DrawPoint.
	#end
	Property PointSize:Float()
	
		Return _pointSize
	
	Setter( pointSize:Float )
	
		_pointSize=pointSize
	End

	#rem monkeydoc The current line width for use with DrawLine.
	#end	
	Property LineWidth:Float()

		Return _lineWidth
	
	Setter( lineWidth:Float )
	
		_lineWidth=lineWidth
	End
	
	#rem monkeydoc Smoothing enabled for DrawLine.
	#end	
	Property LineSmoothing:Bool()
	
		Return _lineSmoothing
	
	Setter( smoothing:Bool )
	
		_lineSmoothing=smoothing
	End
	
	#rem monkeydoc The current font for use with DrawText.
	Set font to null to use the default mojo font.
	#end	
	Property Font:Font()
	
		Return _font
	
	Setter( font:Font )
	
		If Not font font=_defaultFont
	
		_font=font
	End
	
	#rem monkeydoc The current drawing alpha level.
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	This allows you to use [[Alpha]] as a 'master' alpha level.
	#end	
	Property Alpha:Float()
	
		Return _alpha
		
	Setter( alpha:Float )
	
		_alpha=alpha
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	#rem monkeydoc The current drawing color.
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	This allows you to use [[Alpha]] as a 'master' alpha level.
	#end
	Property Color:Color()
	
		Return _color
	
	Setter( color:Color )
	
		_color=color
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End

	#rem wonkeydoc The current drawing color mask.
	#end
	Property ColorMask:ColorMask()
	
		Return _colorMask
	
	Setter( colorMask:ColorMask )

		_colorMask=colorMask
	End

	Field RenderAmbient:void( device:GraphicsDevice ) 'jp added
	
	Const BGR:UInt = 255 Shl 16 | 255 Shl 8 | 255 'jp added
	
	Method SetColAlpha( alpha:UByte )
		'jp added
		alpha = Clamp(Float(alpha), 0.0, 255.0)
		
		_pmcolor = alpha Shl 24 | _pmcolor & BGR
	End

	Method SetCol( color:UInt )
		'jp added
		_pmcolor = color
	End

	Method SetCol( r:int, g:int, b:int, a:int = 255 )
		'jp added
		r = Clamp(r, 0, 255)
		g = Clamp(g, 0, 255)
		b = Clamp(b, 0, 255)
		a = Clamp(a, 0, 255)
		_pmcolor = UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
	End

	'----------------------------------------------------------------------- Uniforms

	Property Color2:Color()
		Return _color2
	
	Setter( color2:Color )
		_color2=color2
		
		_pmcolor2=UInt(_color2.a) Shl 24 | UInt(_color2.b) Shl 16 | UInt(_color2.g) Shl 8 | UInt(_color2.r)
	End

	Method SetUserUniformCallback(callback:Void(canvas:Canvas, uniforms:UniformBlock))
		_userUniformCallback = callback
	End
	
	Method SetCol2( r:uint, g:uint, b:uint, a:uint = 255 )
		_pmcolor2 = UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
	End

	Method SetCol2( color:Color )
		_pmcolor2 = UInt(_color2.a) Shl 24 | UInt(_color2.b) Shl 16 | UInt(_color2.g) Shl 8 | UInt(_color2.r)
	End

	Method SetXYZ( x:float,	y:float,	z:float )
		_xyzPosition.x = x
		_xyzPosition.y = y
		_xyzPosition.z = z
	End

	Method SetViewport( x:float, y:float, w:float, h:float )
		'jp added
		If _lighting return

		Flush()
			
		_viewport = New Rectf( x,y,x+w,y+h )
		
		_dirty |= Dirty.Viewport | Dirty.Scissor
	End
	
	#rem monkeydoc The current outline mode.
	Outline modes control the style of outlines drawn.
	See the [[OutlineMode]] enum for a list of possible values.
	#end
	Property OutlineMode:OutlineMode()
		
		Return _outlineMode
	
	Setter( mode:OutlineMode )
		
		_outlineMode=mode
	End
	
	#rem monkeydoc The current outline color.
	#end
	Property OutlineColor:Color()
		
		Return _outlineColor
		
	Setter( color:Color )
		
		_outlineColor=color

		Local a:=_outlineColor.a * 255.0
		
		_outlinepmcolor=UInt(a) Shl 24 | UInt(_outlineColor.b*a) Shl 16 | UInt(_outlineColor.g*a) Shl 8 | UInt(_outlineColor.r*a)
	End

	#rem monkeydoc The current outline width.
	#end
	Property OutlineWidth:Float()
		
		Return _outlineWidth
		
	Setter( width:Float )
		
		_outlineWidth=width
	End
		
	Class TTransform

		#rem monkeydoc The current drawing matrix
		All coordinates passed to draw methods are multiplied by this matrix for rendering.
		#end
		Property Matrix:AffineMat3f() 
		
			Return _._matrix
		
		Setter( matrix:AffineMat3f )
		
			_._matrix=matrix
			
			_._tanvec=_._matrix.i.Normalize()
		End
		
		#rem monkeydoc The current outline width.
		#end
		Property OutlineWidth:Float()
			
			Return _._outlineWidth
			
		Setter( width:Float )
			
			_._outlineWidth=width
		End
		
		#rem monkeydoc Pushes the drawing matrix onto the internal matrix stack.
		#end
		Method PushMatrix()
		
			_._matrixStack.Push( _._matrix )
		End
		
		#rem monkeydoc Pops the drawing matrix off the internal matrix stack.
		#end
		Method PopMatrix()
		
			_._matrix=_._matrixStack.Pop()
		End
		
		#rem monkeydoc Clears the internal matrix stack and sets the drawing matrix to the identitity matrix.
		#end
		Method ClearMatrix()
		
			_._matrixStack.Clear()
			_._matrix=New AffineMat3f
		End
		
		#rem monkeydoc Translates the drawing matrix.
		Translates the drawing matrix. This has the effect of translating all drawing coordinates by `tx` and `ty`.
		@param tx X translation.
		@param ty Y translation.
		@param tv X/Y translation.
		#end
		Method Translate( tx:Float,ty:Float )
		
			Matrix=Matrix.Translate( tx,ty )
		End
		
		Method Translate( tv:Vec2f )
		
			Matrix=Matrix.Translate( tv )
		End
	
		#rem monkeydoc Rotates the drawing matrix.
		Rotates the drawing matrix. This has the effect of rotating all drawing coordinates by the angle `rz'.
		@param rz Rotation angle in radians.
		#end
		Method Rotate( rz:Float )
		
			Matrix=Matrix.Rotate( rz )
		End
	
		#rem monkeydoc Scales the drawing matrix.
		Scales the drawing matrix. This has the effect of scaling all drawing coordinates by `sx` and `sy`.
		@param sx X scale factor.
		@param sy Y scale factor.
		@param sv X/Y scale factor.
		#end
		Method Scale( sx:Float,sy:Float )
		
			Matrix=Matrix.Scale( sx,sy )
		End
		
		Method Scale( sv:Vec2f )
		
			Matrix=Matrix.Scale( sv )
		End
		
		Private 
		
		Field _:Canvas 'parent
	End 

	'----------------------------------------------------------------------- Lighting
	
	#rem monkeydoc Adds a light to the canvas.
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	#end
	Method AddLight( light:Image,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddLight() can only be used while lighting" )
		If Not _lighting Return
		
		If _lightNV+4>_lightVB.Length Return
		
		Local lx:=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		Local ly:=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		
		Local op:=New LightOp
		op.light=light
		op.lightPos=New Vec2f( lx,ly )
		op.primOffset=_lightNV
		_lightOps.Push( op )

		_vp=_lightVP0+_lightNV
		_lightNV+=4
		
		Local vs:=light.Vertices
		Local ts:=light.TexCoords
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y,lx,ly,_pmcolor )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y,lx,ly,_pmcolor )
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tv:Vec2f )
		AddLight( light,tv.x,tv.y )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float )
		AddLight( light,tv.x,tv.y,rz )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float,sv:Vec2f )
		AddLight( light,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	'----------------------------------------------------------------------- Shadowing
	
	#rem monkeydoc Adds a shadow caster to the canvas.
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	#end
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddShadowCaster() can only be used while lighting" )
		If Not _lighting Return
	
		Local op:=New ShadowOp
		op.caster=caster
		op.firstVert=_shadowVerts.Length
		_shadowOps.Push( op )
		
		Local tv:=New Vec2f( tx,ty )
		
		For Local sv:=Eachin caster.Vertices
			sv+=tv
			Local lv:=New Vec2f(
			_matrix.i.x * sv.x + _matrix.j.x * sv.y + _matrix.t.x,
			_matrix.i.y * sv.x + _matrix.j.y * sv.y + _matrix.t.y )
			_shadowVerts.Push( lv )
		Next
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float )
		AddShadowCaster( caster,tv.x,tv.y,rz )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float,sv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Copies a pixmap from the rendertarget.
	This method must not be called while the canvas is in lighting mode.
	@param rect The rect to copy.
	#end
	Method CopyPixmap:Pixmap( rect:Recti )
		DebugAssert( Not _lighting,"Canvas.CopyPixmap() cannot be used while lighting" )
		If _lighting Return Null
		
		Local pixmap:=New Pixmap( rect.Width,rect.Height,PixelFormat.RGBA32 )
		
		CopyPixels( rect,pixmap )
		
		Return pixmap
	End
	
	#rem monkeydoc Copies a rectangular region of pixels to a pixmap.
	#end
	Method CopyPixels( rect:Recti,pixmap:Pixmap,dstx:Int=0,dsty:Int=0 )
		DebugAssert( Not _lighting,"Canvas.CopyPixels() cannot be used while lighting" )
		If _lighting Return

		Flush()
		
		rect=TransformRecti( rect,_rmatrix ) & _rbounds
		
		_device.CopyPixels( rect,pixmap,dstx,dsty )
	End
	
	#rem monkeydoc Gets a pixel color.
	Returns the color of the pixel at the given coordinates.
	#end
	Method GetPixel:Color( x:Int,y:Int )
		
		Flush()
		
		CopyPixels( New Recti( x,y,x+1,y+1 ),_tmpPixmap1x1 )
		
		Return _tmpPixmap1x1.GetPixel( 0,0 )
	End
	
	#rem monkeydoc Gets a pixel color.
	Returns the ARGB color of the pixel at the given coordinates.
	#end
	Method GetPixelARGB:UInt( x:Int,y:Int )

		Flush()
		
		CopyPixels( New Recti( x,y,x+1,y+1 ),_tmpPixmap1x1 )
		
		Return _tmpPixmap1x1.GetPixelARGB( 0,0 )
	End
	
	#rem monkeydoc Clears the viewport.
	Clears the current viewport to `color`.
	This method must not be called while the canvas is in lighting mode.
	@param color Color to clear the viewport to.
	#end
	Method Clear( color:Color )
		DebugAssert( Not _lighting,"Canvas.Clear() cannot be used while lighting" )
		If _lighting Return
		
		Validate()
			
		_device.Clear( color )
		
		_drawNV=0
		_drawOps.Clear()
		_drawOp=New DrawOp
	End
	
	#rem monkeydoc Flushes drawing commands.
	Flushes any outstanding drawing commands in the draw buffer.
	This is only generally necessary if you are drawing to an image.
	#end
	Method Flush()
		
		If _drawOps.Empty 
			_device.FlushTarget()
			Return
		Endif
		
		Validate()
		
		_drawVB.Invalidate( 0,_drawNV )
		
		_drawVB.Unlock()
		
		'Render ambient
		RenderDrawOps( 0 )
		
		If _lighting
		
			'render diffuse gbuffer
			_device.RenderTarget=_gbrtargets[0]
			
			RenderDrawOps( 1 )
			
			'render normal gbuffer
			_device.RenderTarget=_gbrtargets[1]
			
			RenderDrawOps( 2 )

			'back to rendertarget
			_device.RenderTarget=_rtarget
			
		Endif
		
		_device.FlushTarget()
		
		_drawVP0=Cast<Vertex2f Ptr>( _drawVB.Lock() )
		_drawNV=0
		_drawOps.Clear()
		_drawOp=New DrawOp
	End
	
	#rem monkeydoc True if canvas is in lighting mode.
	#end
	Property IsLighting:Bool()
	
		Return _lighting
	End
	
	#rem monkeydoc Puts the canvas into lighting mode.
	
	While in lighting mode, you can add lights and shadow casters to the cavas using [[AddLight]] and [[AddShadowCaster]]. Lights and shadows
	are later rendered by calling [[EndLighting]].
	
	Each call to BeginLighting must be matched with a corresponding call to EndLighting.
	
	The following properties must not be modified while in lighting mode: [[Viewport]], [[Scissor]], [[AmbientLight]]. Attempting to
	modify these properties while in lighting mode will result in a runtime error in debug builds.
	
	The following methods must not be called in lighting mode: [[Clear]], [[BeginLighting]]. Attepting to call these methods while in
	lighting mode will result in a runtime error in debug builds.
	
	#end
	Method BeginLighting()
		DebugAssert( Not _lighting,"Already lighting" )
		If _lighting Return
		
		_lighting=True
		
		Local gbufferSize:=_device.RenderTargetSize
		gbufferSize.x=Max( gbufferSize.x,1920 )
		gbufferSize.y=Max( gbufferSize.y,1080 )

		If Not _gbuffers[0] Or gbufferSize.x>_gbuffers[0].Width Or gbufferSize.y>_gbuffers[0].Height
			
			For Local i:=0 Until 2
	
				If _gbuffers[i] _gbuffers[i].Discard()
				If _gbrtargets[i] _gbrtargets[i].Discard()
	
				_gbuffers[i]=New Texture( gbufferSize.x,gbufferSize.y,PixelFormat.RGBA32,TextureFlags.Dynamic )
				_gbrtargets[i]=New RenderTarget( New Texture[]( _gbuffers[i] ),Null )
			Next
	
			Local gbufferScale:=New Vec2f( 1 )/Cast<Vec2f>( gbufferSize )
	
			_uniforms.SetVec2f( "GBufferScale",gbufferScale )
			_uniforms.SetTexture( "GBuffer0",_gbuffers[0] )
			_uniforms.SetTexture( "GBuffer1",_gbuffers[1] )
	
		Endif
		
		Validate()
		
		_uniforms.SetVec4f( "AmbientLight",_ambientLight )
		
		_device.RenderTarget=_gbrtargets[0]
		_device.Clear( Color.Black )
			
		_device.RenderTarget=_gbrtargets[1]
		_device.Clear( New Color( .5,.5,0 ) )
		
		_device.RenderTarget=_rtarget
	End
	
	#rem monkeydoc Renders lighting and ends lighting mode.
	Renders any lights and shadows casters added to the canvas through calls to [[AddLight]] and [[AddShadowCaster]] and ends lighting mode.
	Any lights and shadow casters added to the canvas are also removed and must be added again later if you want to render them again.
	This method must be called while the canvas is in lighting mode.
	#end
	Method EndLighting()
		DebugAssert( _lighting,"Not lighting" )
		If Not _lighting Return
		
		Flush()
		
		_lightVB.Invalidate( 0,_lightNV )
		
		_lightVB.Unlock()
		
		RenderLighting()
	
		_lightVP0=Cast<Vertex2f Ptr>( _lightVB.Lock() )
		_lightNV=0
		_lightOps.Clear()
		
		_shadowOps.Clear()
		_shadowVerts.Clear()
	
		_lighting=False
	End

	#rem monkeydoc Mini-Library Draw
	@author iDkP from GaragePixel
	@since 2025-05-25
	@version 2025-05-26
			
	Helpers to program draw ops in mojo/sdk_mojo

	Note: The TDraw is a singleton created in the Canvas class
	and addressable as a property. We call the property Draw to get 
	access to the draw functions.
			
	canvas.Draw.Line( params )

	About the old draw methods in canvas, it will be declared as deprecated but
	will be preserved until a new version of the project Monkey2. You can
	use the actual mojo for your old project, but use Mojo.Draw for your next
	project.
	#end
	Class TDraw

		#rem monkeydoc Get access to the Triangle_ methods.
		#end
		Property Triangle_:TTriangle_()
			Return _ttriangle_
		End

		#rem monkeydoc Get access to the Rect_ methods.
		#end
		Property Rect_:TRect_()
			Return _trect_
		End

		#rem monkeydoc Get access to the Image_ methods.
		#end
		Property Image_:TImage_()
			Return _timage_
		End

		#rem monkeydoc Get access to the Icon_ methods.
		#end
		Property Icon:TIcon()
			Return _ticon
		End

		#rem monkeydoc Get access to the Text_ methods.
		#end
		Property Text_:TText_()
			Return _ttext_
		End

		#rem monkeydoc Get access to the Wireframe methods.
		#end
		Property Wireframe:TWireframe()
			Return _twireframe
		End

		#rem monkeydoc Get access to the Debug methods.
		#end
		Property Debug:TDebug()
			Return _tdebug
		End

		#rem monkeydoc Draws a point.
		Draws a point in the current [[Color]] using the current [[BlendMode]].
		The point coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
		@param x Point x coordinate.
		@param y Point y coordinate.
		@param v Point coordinates.
		#end
		Method Point( x:Float,y:Float )
		
			If _._pointSize<=0
				_.AddDrawOp( _._shader,_._material,_._blendMode,1,1 )
				_.AddPointVertex( x,y,0,0 )
				Return
			Endif
			
			Local d:=_._pointSize/2
			_.AddDrawOp( _._shader,_._material,_._blendMode,4,1 )
			_.AddVertex( x-d,y-d,0,0 )
			_.AddVertex( x+d,y-d,1,0 )
			_.AddVertex( x+d,y+d,1,1 )
			_.AddVertex( x-d,y+d,0,1 )
		End
		
		Method Point( v:Vec2f )
			Point( v.x,v.y )
		End

		#rem monkeydoc Draws a line.
		Draws a line in the current [[Color]] using the current [[BlendMode]].
		The line coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
		@param x0 X coordinate of first endpoint of the line.
		@param y0 Y coordinate of first endpoint of the line.
		@param x1 X coordinate of first endpoint of the line.
		@param y1 Y coordinate of first endpoint of the line.
		@param v0 First endpoint of the line.
		@param v1 Second endpoint of the line.
		#end
		Method Line( x0:Float,y0:Float,x1:Float,y1:Float )
	
			If _._lineWidth<=0
				_.AddDrawOp( _._shader,_._material,_._blendMode,2,1 )
				_.AddPointVertex( x0,y0,0,0 )
				_.AddPointVertex( x1,y1,1,1 )
				Return
			Endif
			
	'		x0+=.5;y0+=.5;x1+=.5;y1+=.5
			
			Local dx:=y0-y1,dy:=x1-x0
			Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_._lineWidth
			dx*=sc;dy*=sc
			
			If Not _._lineSmoothing
				_.AddDrawOp( _._shader,_._material,_._blendMode,4,1 )
				_.AddPointVertex( x0-dx,y0-dy,0,0 )
				_.AddPointVertex( x0+dx,y0+dy,0,0 )
				_.AddPointVertex( x1+dx,y1+dy,0,0 )
				_.AddPointVertex( x1-dx,y1-dy,0,0 )
				Return
			End
			
			Local pmcolor:=_._pmcolor
			
			_.AddDrawOp( _._shader,_._material,_._blendMode,4,2 )
	
			_.AddPointVertex( x0,y0,0,0 )
			_.AddPointVertex( x1,y1,0,0 )
			_._pmcolor=0
			_.AddPointVertex( x1-dx,y1-dy,0,0 )
			_.AddPointVertex( x0-dx,y0-dy,0,0 )
	
			_.AddPointVertex( x0+dx,y0+dy,0,0 )
			_.AddPointVertex( x1+dx,y1+dy,0,0 )
			_._pmcolor=pmcolor
			_.AddPointVertex( x1,y1,0,0 )
			_.AddPointVertex( x0,y0,0,0 )
		End
		
		Method Line( v0:Vec2f,v1:Vec2f )
			
			Line( v0.x,v0.y,v1.x,v1.y )
		End
		
		#rem monkeydoc Draws a triangle.
		Draws a triangle in the current [[Color]] using the current [[BlendMode]].
		The triangle vertex coordinates are also transform by the current [[Matrix]].
		#End
		Method Triangle( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float )
			
			_.AddDrawOp( _._shader,_._material,_._blendMode,3,1 )
			_.AddVertex( x0,y0,0,0, _._pmcolor )
			_.AddVertex( x1,y1,1,0, _._pmcolor )
			_.AddVertex( x2,y2,1,1, _._pmcolor )
			
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Return 'ATTENTION
			
			_.DrawOutlineLine( x0,y0,x1,y1 )
			_.DrawOutlineLine( x1,y1,x2,y2 )
			_.DrawOutlineLine( x2,y2,x0,y0 )
					
		End
		
		Method Triangle( v0:Vec2f,v1:Vec2f,v2:Vec2f )
			
			Triangle( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y )
		End

		Method Triangle( x:Float, y:Float, w:Float, angle:Float = 0 )
			Local x0:float = x + Sin(angle) * w
			Local y0:float = y + Cos(angle) * w
			angle += Pi * .666666
			Local x1:float = x + Sin(angle) * w
			Local y1:float = y + Cos(angle) * w
			angle += Pi * .666666
			Local x2:float = x + Sin(angle) * w
			Local y2:float = y + Cos(angle) * w
			
			_.AddDrawOp( _._shader, _._material, _._blendMode, 3, 1 )
			_.AddVertex( x0,y0,0,0, _._pmcolor )
			_.AddVertex( x1,y1,1,0, _._pmcolor )
			_.AddVertex( x2,y2,1,1, _._pmcolor )
		End

		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:UInt, color1:UInt, color2:UInt )
			_.AddDrawOp( _._shader, _._material, _._blendMode,3,1 )
	
			_.AddVertex( x0,y0, 0,0, color0 )
			_.AddVertex( x1,y1, 1,0, color1 )
			_.AddVertex( x2,y2, 1,1, color2 )
		End
	
		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:Color, color1:Color, color2:Color )
			_.AddDrawOp( _._shader, _._material, _._blendMode,3,1 )
	
	'		local pmcolor:UInt = _pmcolor
	
			Local col0:uint = UInt(color0.a*255) Shl 24 | UInt(color0.b*255) Shl 16 | UInt(color0.g*255) Shl 8 | UInt(color0.r*255)
			Local col1:uint = UInt(color1.a*255) Shl 24 | UInt(color1.b*255) Shl 16 | UInt(color1.g*255) Shl 8 | UInt(color1.r*255)
			Local col2:uint = UInt(color2.a*255) Shl 24 | UInt(color2.b*255) Shl 16 | UInt(color2.g*255) Shl 8 | UInt(color2.r*255)
	
			_.AddVertex( x0,y0, 0,0, col0 )
			_.AddVertex( x1,y1, 1,0, col1 )
			_.AddVertex( x2,y2, 1,1, col2 )
	
	'		_pmcolor = pmcolor
		End
	
		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
							col0:UInt, col1:UInt, col2:Uint,
							u0:float, v0:float, u1:float, v1:float, u2:float, v2:float )
							
			_.AddDrawOp( _._shader, _._material, _._blendMode, 3,1 )
	
			_.AddVertex( x0,y0, u0,v0, col0 )
			_.AddVertex( x1,y1, u1,v1, col1 )
			_.AddVertex( x2,y2, u2,v2, col2 )
		End
	
		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
							col0:UInt, col1:UInt, col2:Uint,
							srcImage:Image, shader:Shader, material:UniformBlock )
							
			_.AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )
	
			_.AddVertex( x0,y0, 0,0, col0 )
			_.AddVertex( x1,y1, 1,0, col1 )
			_.AddVertex( x2,y2, 1,1, col2 )
		End
	
		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
							col0:UInt, col1:UInt, col2:Uint,
							u0:float, v0:float, u1:float, v1:float, u2:float, v2:float,
							srcImage:Image, shader:Shader, material:UniformBlock )
							
			_.AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )
	
			_.AddVertex( x0,y0, u0,v0, col0 )
			_.AddVertex( x1,y1, u1,v1, col1 )
			_.AddVertex( x2,y2, u2,v2, col2 )
		End
	
		Method Triangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
							col0:UInt, col1:UInt, col2:Uint,
							u0:float, v0:float, u1:float, v1:float, u2:float, v2:float,
							srcImage:Image, shader:Shader )
							
			_.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode,3,1 )
	
			_.AddVertex( x0,y0, u0,v0, col0 )
			_.AddVertex( x1,y1, u1,v1, col1 )
			_.AddVertex( x2,y2, u2,v2, col2 )
		End
		
		Class TTriangle_
	
			Method XYZ( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
							col0:UInt, col1:UInt, col2:Uint,
							u0:float, v0:float, u1:float, v1:float, u2:float, v2:float,
							srcImage:Image, shader:Shader, material:UniformBlock,
							xp0:float, yp0:float, zp0:float,
							xp1:float, yp1:float, zp1:float,
							xp2:float, yp2:float, zp2:float	)
								
				_._.AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )
		
				_._.AddVertex( x0,y0,	u0,v0,	col0,	xp0,yp0,zp0 )
				_._.AddVertex( x1,y1,	u1,v1,	col1,	xp1,yp1,zp1 )
				_._.AddVertex( x2,y2,	u2,v2,	col2,	xp2,yp2,zp2 )
			End
		
			Method XYZNormal( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
								col0:UInt, col1:UInt, col2:Uint,
								u0:float, v0:float, u1:float, v1:float, u2:float, v2:float,
								srcImage:Image, shader:Shader, material:UniformBlock,
								xp0:float, yp0:float, zp0:float,
								xp1:float, yp1:float, zp1:float,
								xp2:float, yp2:float, zp2:float,
								nx:float, ny:float, nz:float )
								
				_._.AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )
		
				_._.AddVertexNormal( x0,y0,	u0,v0,	col0,	xp0,yp0,zp0,	nx,ny,nz )
				_._.AddVertexNormal( x1,y1,	u1,v1,	col1,	xp1,yp1,zp1,	nx,ny,nz )
				_._.AddVertexNormal( x2,y2,	u2,v2,	col2,	xp2,yp2,zp2,	nx,ny,nz )
			End
		
			Method XYZNormal2( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
								col0:UInt, col1:UInt, col2:Uint,
								u0:float, v0:float, u1:float, v1:float, u2:float, v2:float,
								u10:float, v10:float, u11:float, v11:float, u12:float, v12:float,
								srcImage:Image, shader:Shader, material:UniformBlock,
								xp0:float, yp0:float, zp0:float,
								xp1:float, yp1:float, zp1:float,
								xp2:float, yp2:float, zp2:float,
								nx:float, ny:float, nz:float )
								
				_._.AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )
		
				_._.AddVertexNormal2( x0,y0,	u0,v0,	u10,v10,	col0,	xp0,yp0,zp0,	nx,ny,nz )
				_._.AddVertexNormal2( x1,y1,	u1,v1,	u11,v11,	col1,	xp1,yp1,zp1,	nx,ny,nz )
				_._.AddVertexNormal2( x2,y2,	u2,v2,	u12,v12,	col2,	xp2,yp2,zp2,	nx,ny,nz )
			End
			
			Private
			
			Field _:TDraw 'parent
		
		End 

		#rem monkeydoc Draws a quad.
		Draws a quad in the current [[Color]] using the current [[BlendMode]].
		The quad vertex coordinates are also transform by the current [[Matrix]].
		#end
		Method Quad( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float )
			
			_.AddDrawOp( _._shader,_._material,_._blendMode,4,1 )
			_.AddVertex( x0,y0,0,0 )
			_.AddVertex( x1,y1,1,0 )
			_.AddVertex( x2,y2,1,1 )
			_.AddVertex( x3,y3,0,1 )
			
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Return 'ATTENTION
			
			_.DrawOutlineLine( x0,y0,x1,y1 )
			_.DrawOutlineLine( x1,y1,x2,y2 )
			_.DrawOutlineLine( x2,y2,x3,y3 )
			_.DrawOutlineLine( x3,y3,x0,y0 )
		End
	
		Method Quad( v0:Vec2f,v1:Vec2f,v2:Vec2f,v3:Vec2f )
			
			Quad( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y,v3.x,v3.y )
		End
	
		#rem monkeydoc Draws a rectangle.
		Draws a rectangle in the current [[Color]] using the current [[BlendMode]].
		The rectangle vertex coordinates are also transform by the current [[Matrix]].
		#end
		Method Rect( x:Float,y:Float,w:Float,h:Float )
			
			Quad( x,y,x+w,y,x+w,y+h,x,y+h )
		End
		
		Method Rect( rect:Rectf )
			
			Rect( rect.X,rect.Y,rect.Width,rect.Height )
		End
		
		Method Rect( rect:Rectf,srcImage:Image )
			
			Local tc:=srcImage.TexCoords
			_.AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
			
			_.AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
			_.AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
			_.AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
			_.AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )
	
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Return 'ATTENTION
			
			_.DrawOutline( rect )
		End
		
		Method Rect( x:Float,y:Float,width:Float,height:Float,srcImage:Image )
			
			Rect( New Rectf( x,y,x+width,y+height ),srcImage )
		End
		
		Method Rect( rect:Rectf,srcImage:Image,srcRect:Recti )
			
			Local s0:=Float(srcImage.Rect.min.x+srcRect.min.x)/srcImage.Texture.Width
			Local t0:=Float(srcImage.Rect.min.y+srcRect.min.y)/srcImage.Texture.Height
			Local s1:=Float(srcImage.Rect.min.x+srcRect.max.x)/srcImage.Texture.Width
			Local t1:=Float(srcImage.Rect.min.y+srcRect.max.y)/srcImage.Texture.Height
			
			_.AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
			
			_.AddVertex( rect.min.x,rect.min.y,s0,t0 )
			_.AddVertex( rect.max.x,rect.min.y,s1,t0 )
			_.AddVertex( rect.max.x,rect.max.y,s1,t1 )
			_.AddVertex( rect.min.x,rect.max.y,s0,t1 )
	
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Return 'ATTENTION
			
			_.DrawOutline( rect )
		End
		
		Method Rect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int )
	
			Rect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+width,srcY+height ) )
		End
		
		Method Rect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int,srcWidth:Int,srcHeight:Int )
	
			Rect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+srcWidth,srcY+srcHeight ) )
		End
	
		Method Rect( rect:Rectf, srcImage:Image, shader:Shader )
			
			If Not shader
				Rect( rect, srcImage )
				Return
			End
			
			Local tc := srcImage.TexCoords
			_.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 4, 1 )
			_.AddVertex( rect.min.x, rect.min.y, tc.min.x, tc.min.y, _._pmcolor )
			_.AddVertex( rect.max.x, rect.min.y, tc.max.x, tc.min.y, _._pmcolor )
			_.AddVertex( rect.max.x, rect.max.y, tc.max.x, tc.max.y, _._pmcolor )
			_.AddVertex( rect.min.x, rect.max.y, tc.min.x, tc.max.y, _._pmcolor )
		End
	
		Method Rect( x:Float,y:Float,width:Float,height:Float, srcImage:Image, shader:Shader )
			
			If Not shader
				Rect( New Rectf( x,y,x+width,y+height ), srcImage )
				Return
			End
			
			Rect( New Rectf( x,y,x+width,y+height ), srcImage, shader )
		End
	
		Method Rect( rect:Rectf, srcImage:Image, shader:Shader, material:UniformBlock )
			
			If Not shader
				Rect( rect, srcImage )
				Return
			End
			
			Local tc:=srcImage.TexCoords
			_.AddDrawOp( shader, material, srcImage.BlendMode, 4, 1 )
			_.AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y, _._pmcolor )
			_.AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y, _._pmcolor )
			_.AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y, _._pmcolor )
			_.AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y, _._pmcolor )
		End
	
		Method Rect( x:Float,y:Float,width:Float,height:Float, srcImage:Image, shader:Shader, material:UniformBlock )
			
			If Not shader
				Rect( New Rectf( x,y,x+width,y+height ), srcImage )
				Return
			End
			
			Rect( New Rectf( x,y,x+width,y+height ), srcImage, shader, material )
		End
		
		Class TRect_
			
			#rem monkeydoc Get access to the Patches methods.
			#end
			Property Patches:TPatches()
				Return _tpatches
			End

			#rem monkeydoc Get access to the Frame methods.
			#end
			Property Frame:TFrame()
				Return _tframe
			End
	
			Method HFade( x:Float, y:Float, w:Float, h:Float, colLeft:Color, colRight:Color )
				
				Local x0 := x
				Local y0 := y
				Local x1 := x+w
				Local y1 := y+h
			
				_._.AddDrawOp( _._._shader, _._._material, _._._blendMode, 4, 1 )
		
				Local pmcolor_old:UInt = _._._pmcolor
				
				local colL:uint = UInt(colLeft.a*255) Shl 24 | UInt(colLeft.b*255) Shl 16 | UInt(colLeft.g*255) Shl 8 | UInt(colLeft.r*255)
				local colR:uint = UInt(colRight.a*255) Shl 24 | UInt(colRight.b*255) Shl 16 | UInt(colRight.g*255) Shl 8 | UInt(colRight.r*255)
				
				_._._pmcolor = colL
				_._.AddVertex( x0,y0, 0,0, _._._pmcolor )
				_._._pmcolor = colR
				_._.AddVertex( x1,y0, 1,0, _._._pmcolor )
				_._.AddVertex( x1,y1, 1,1, _._._pmcolor )
				_._._pmcolor = colL
				_._.AddVertex( x0,y1, 0,1, _._._pmcolor )
		
				_._._pmcolor = pmcolor_old
			End
		
			Method VFade( x:Float, y:Float, w:Float, h:Float, colTop:Color, colBottom:Color )
				
				Local x0 := x
				Local y0 := y
				Local x1 := x+w
				Local y1 := y+h
			
				_._.AddDrawOp( _._._shader, _._._material, _._._blendMode, 4, 1 )
		
				local pmcolor:UInt = _._._pmcolor
		
				local colT:uint = UInt(colTop.a*255) Shl 24 | UInt(colTop.b*255) Shl 16 | UInt(colTop.g*255) Shl 8 | UInt(colTop.r*255)
				local colB:uint = UInt(colBottom.a*255) Shl 24 | UInt(colBottom.b*255) Shl 16 | UInt(colBottom.g*255) Shl 8 | UInt(colBottom.r*255)
				
				_._.AddVertex( x0,y0, 0,0, colT )
				_._.AddVertex( x1,y0, 1,0, colT )
				_._.AddVertex( x1,y1, 1,1, colB )
				_._.AddVertex( x0,y1, 0,1, colB )
		
				_._._pmcolor = pmcolor
			End

			Method Color( x:Float,y:Float,w:Float,h:Float, color1:Color=stdlib.graphics.Color.Black, color2:Color=stdlib.graphics.Color.White )
				
				Local color_old:Color = _._._color
		
				_._.Color = color1
				_.Wireframe.Rect( x, y, w, h )
		
				_._.Color = color2
				_.Wireframe.Rect( x+1, y+1, w-2, h-2 )
		
				_._.Color = color_old
				_.Rect( x+2, y+2, w-4, h-4 )
			End
	
			#rem wonkeydoc Draws a grid of cells (made from lines).
			@author jean-luc
			@updated 2025-05-29 iDkP from GaragePixel
			@version 2025-05-29
			Draws a grid in the current [[Color]] using the current [[BlendMode]].
			The rectangle vertex coordinates are also transform by the current [[Matrix]].
			#end
			Method Grid( x:Float, y:Float, width:Float, height:Float, cell:Float )
				
				width -= 1
				height -= 1
				Local k:float
				For k = x To x+width Step cell
					_.Line( k, y, k, y+height )
				Next
				If height < 0 Then cell = -cell
				For k = y To y+height Step cell
					_.Line( x, k, x+width, k )
				Next
				_.Line( x, y+height, x+width, y+height )
				_.Line( x+width, y, x+width, y+height )
			End

			Method Diamond( x:Float, y:Float, w:Float )
				
				Local x0 := x-w
				Local y0 := y-w
				Local x1 := x+w
				Local y1 := y+w
				
				_._.AddDrawOp( _._._shader, _._._material, _._._blendMode,4,1 )
				
				_._.AddVertex( x0, y, 0,0, _._._pmcolor )
				_._.AddVertex( x, y0, 1,0, _._._pmcolor )
				_._.AddVertex( x1, y, 1,1, _._._pmcolor )
				_._.AddVertex( x, y1, 0,1, _._._pmcolor )
			End
	
			Method Square( x:Float, y:Float, w:Float )
				
				Local x0 := x-w
				Local y0 := y-w
				Local x1 := x+w
				Local y1 := y+w
				
				_._.AddDrawOp( _._._shader, _._._material, _._._blendMode,4,1 )
				
				_._.AddVertex( x0, y0, 0,0, _._._pmcolor )
				_._.AddVertex( x1, y0, 1,0, _._._pmcolor )
				_._.AddVertex( x1, y1, 1,1, _._._pmcolor )
				_._.AddVertex( x0, y1, 0,1, _._._pmcolor )
			End
	
			Method Square( x:Float, y:Float, w:Float, srcImage:Image, shader:Shader, material:UniformBlock )
				
				If Not shader
					Square( x, y, w )
					Return
				End
		
				Local x0 := x-w
				Local y0 := y-w
				w += w
				
				_.Rect( x0, y0, w, w, srcImage, shader, material )
			End
			
			Class TFrame

				Method Rect3d<T>( 	x:T, y:T, w:T, h:T, 
									color1:Color=stdlib.graphics.Color.White * 0.5, 
									color2:Color=stdlib.graphics.Color.Black * 0.5 	) Where T Implements IReal Or T Implements INumeric
					
					'jl added
					'iDkP modified: made generic

					Local x0 := x
					Local y0 := y
					Local x1 := x+w-1
					Local y1 := y+h-1

					Local color_old:Color = ___._color
					
					___.Color = color1
					__.Line( x0, y0, x1, y0 )
					__.Line( x0, y0, x0, y1 )
					___.Color = color2
					__.Line( x1, y0, x1, y1 )
					__.Line( x0, y1, x1, y1 )
					__.Point(x1, y1)
					
					___.Color = color_old
				End
				
				Private 
				
				Field _:TRect_'parent
				
				Field __:TDraw
				
				Field ___:Canvas
				
			End 

			#rem monkeydoc Mini-Library TPatches (draw a rect9 struct)
			@author iDkP from GaragePixel
			@since 2025-05-14
			@version 2025-05-26
					
			Helpers to draw a Rect9.
					
			Note: the TPatches is a singleton created in the TDraw class
			and addressable as a property. You call the property Draw.Patches to get 
			access to the draw functions.
					
			canvas.Draw.Rect.Patches.Wireframe( myrect9 )
					
			The draw function was originally inclued inside the Rect9, but when I've created stdlib
			and reintegrated my old libraries' stuff, the data was separated from the graphic engine.
			#end
			Class TPatches
	
				#rem monkeydoc Get access to the Debug methods.
				#end
				Property Debug:TDebug()
					Return _tdebug
				End
		
				#rem monkeydoc Draws nine images arranged in a nine-patch pattern within a Rect9 using arrays.
				@author iDkP from GaragePixel
				@since 2025-05-24
				
				Draws a complete nine-patch image using the current BlendMode.
				Uses arrays for images and tiling modes to draw all nine patches of the Rect9.
				The patches are arranged in a 3x3 grid according to the Rect9 layout:
				
				│ 1 2 3 │
				│ 4 5 6 │
				│ 7 8 9 │
				
				The vertex coordinates are also transformed by the current Matrix.
				
				@param this The Rect9 defining the layout boundaries
				@param tiles Array of 9 images in reading order (top-left to bottom-right)
				@param tileModes Array of 9 TileMode values corresponding to each image
				@param blendmodes Array of 9 BlendMode values corresponding to each image
				@param alphas Array of 9 Float values corresponding to each image
				#end
				Method Image<T>( this:Rect9<T>, tiles:Image[], tileModes:TileMode[] ) Where T Implements IReal Or T Implements INumeric
				
					'Compute the rect9's patches
					Local patches:=this.Patches
			
					'Draw the patches
					For Local tile:=0 Until 8
						If tiles[tile]<>Null _._.Image_.Tile( tiles[tile], patches[tile], tileModes[tile] )
					End
				End 
	
				Method Image<T>( this:Rect9<T>, tiles:Image[], tileModes:TileMode[], blendmodes:BlendMode[], alphas:Float[] ) Where T Implements IReal Or T Implements INumeric
				
					'Compute the rect9's patches
					Local patches:=this.Patches
	
					'Store the canvas's state
					Local blendMode_old:=___.BlendMode
					Local alpha_old:=___.Alpha
			
					'Draw the patches
					For Local tile:=0 Until 8
						If tiles[tile]<>Null 
							___.BlendMode=blendmodes[tile]
							'TODO: Use Trim for alpha as guard
							If alphas[tile]<0 alphas[tile]=0
							If alphas[tile]>1 alphas[tile]=1
							___.Alpha=alphas[tile]
							_._.Image_.Tile( tiles[tile], patches[tile], tileModes[tile] )
						End
					End
	
					'Restore the canvas's state
					___.BlendMode=blendMode_old
					___.Alpha=alpha_old
				End 
		
				#rem monkeydoc Draws nine images arranged in a nine-patch pattern using direct pointers.
				@author iDkP from GaragePixel
				@since 2025-05-24
				
				Draws a complete nine-patch image using the current BlendMode.
				It's the faster method used in mojo to draw nine-patch using rect9 and mojo.image.
				Uses direct pointers to rect9, image and tilemode arrays for maximum performance.
				The pointers points the 1st element of each collection objects.
				
				The patches are arranged in a 3x3 grid according to the Rect9 layout:
		
				│ 1 2 3 │
				│ 4 5 6 │
				│ 7 8 9 │
		
				The vertex coordinates are also transformed by the current Matrix.
				
				@param this The Rect9 defining the layout boundaries
				@param tiles Pointer to array of 9 images in reading order (top-left to bottom-right)
				@param tileModes Pointer to array of 9 TileMode values corresponding to each image
				#end
				Method Image<T>( this:Rect9<T> Ptr, tiles:Image Ptr, tileModes:TileMode Ptr, blendmodes:BlendMode Ptr, alphas:Float Ptr ) Where T Implements IReal Or T Implements INumeric
	
					'Compute the rect9's patches
					Local patches:=this[0].Patches
	
					'Store the canvas's state
					Local blendMode_old:=___.BlendMode
					Local alpha_old:=___.Alpha
			
					'Draw the patches
					For Local tile:=0 Until 8
						If tiles[tile]<>Null 
							___.BlendMode=blendmodes[tile]
							'TODO: Use Trim for alpha as guard
							If alphas[tile]<0 alphas[tile]=0
							If alphas[tile]>1 alphas[tile]=1
							___.Alpha=alphas[tile]
							___.Image_.Tile( tiles[tile], patches[tile], tileModes[tile] )
						End
					End
	
					'Restore the canvas's state
					___.BlendMode=blendMode_old
					___.Alpha=alpha_old
				End 
		
				#rem monkeydoc Draws nine images arranged in a nine-patch pattern within a Rect9.
				@author iDkP from GaragePixel
				@since 2025-05-24
				
				Draws a nine-patch image using the current BlendMode.
				The images are positioned according to the Rect9 patches layout, with each edge patches having theirs own tiling mode
				while the central patch can have is own tiling mode. The corners are always fitted.
				It's a fast way to draw nine-patches.
		
				Layouts:
		
					Patches:
						│ 1 2 3 │
						│ 4 5 6 │
						│ 7 8 9 │
						
					Edges mode:
						│ 0 1 0 │
						│ 1 0 1 │
						│ 0 1 0 │
						
					Middle mode:
						│ 0 0 0 │
						│ 0 1 0 │
						│ 0 0 0 │
				
				The vertex coordinates are also transformed by the current Matrix.
				
				@param this The Rect9 defining the layout boundaries
				
				@param cornerTopLeft Image for top-left corner
				@param top Image for top edge
				@param cornerTopRight Image for top-right corner
				@param left Image for left edge
				@param middle Image for center area
				@param right Image for right edge
				@param cornerBottomLeft Image for bottom-left corner
				@param bottom Image for bottom edge
				@param cornerBottomRight Image for bottom-right corner
				
				@param edgeMode TileMode for each edge patches
				@param middleMode TileMode for the middle patch
				#end		
				Method Image<T>(	this:Rect9<T>,
													
									' Patches:
													
									cornerTopLeft:Image,		top:Image,					cornerTopRight:Image,		
									left:Image,					middle:Image,				right:Image,
									cornerBottomLeft:Image,		bottom:Image,				cornerBottomRight:Image,
													
									' Edges mode:
						
									edgeMode:TileMode=TileMode.Fit,
													
									' Middle mode:
		
									middleMode:TileMode=TileMode.Fit	) Where T Implements IReal Or T Implements INumeric
					
					'Init a sequence of:
					Local imgCorners:=New Image[](		cornerTopLeft,		cornerTopRight,			cornerBottomRight,		cornerBottomLeft)
					Local imgEdges:=New Image[](		top,				right,					bottom,					left)
					
					'Compute the rect9's patches
					Local rectCorners:=this.Corners
					Local rectEdges:=this.NotCorners
					
					'Draw the image of the inside view
					If imgEdges[4]<>Null _._.ImageTile( imgEdges[4], this.Inner, middleMode )
					
					'Draw the images of the corners
					For Local corner:=0 Until 3
						If imgCorners[corner]<>Null _._.Image._Rect( imgCorners[corner], rectCorners[corner] )
					End
					
					'Draw the images of the edges
					For Local edge:=0 Until 3
						If imgEdges[edge]<>Null _._.Image_.Tile( imgEdges[edge], rectEdges[edge], edgeMode)
					End 
				End 
		
				#rem monkeydoc Draws nine images arranged in a nine-patch pattern within a Rect9 with individual tiling modes.
				@author iDkP from GaragePixel
				@since 2025-05-24
				
				Draws a complete nine-patch image using the current BlendMode.
				Each of the nine patches has its own image and tiling mode for maximum flexibility.
				The patches are arranged in a 3x3 grid and positioned according to the Rect9 layout:
		
				│ 1 2 3 │
				│ 4 5 6 │
				│ 7 8 9 │
				
				The vertex coordinates are also transformed by the current Matrix.
				
				@param this The Rect9 defining the layout boundaries
				
				@param cornerTopLeft Image for top-left corner (patch 1)
				@param top Image for top edge (patch 2)
				@param cornerTopRight Image for top-right corner (patch 3)
				@param left Image for left edge (patch 4)
				@param middle Image for center area (patch 5)
				@param right Image for right edge (patch 6)
				@param cornerBottomLeft Image for bottom-left corner (patch 7)
				@param bottom Image for bottom edge (patch 8)
				@param cornerBottomRight Image for bottom-right corner (patch 9)
				
				@param patch1mode TileMode for top-left corner
				@param patch2mode TileMode for top edge
				@param patch3mode TileMode for top-right corner
				@param patch4mode TileMode for left edge
				@param patch5mode TileMode for center area
				@param patch6mode TileMode for right edge
				@param patch7mode TileMode for bottom-left corner
				@param patch8mode TileMode for bottom edge
				@param patch9mode TileMode for bottom-right corner
	
				@param blendmode1 BlendMode for top-left corner
				@param blendmode2 BlendMode for top edge
				@param blendmode3 BlendMode for top-right corner
				@param blendmode4 BlendMode for left edge
				@param blendmode5 BlendMode for center area
				@param blendmode6 BlendMode for right edge
				@param blendmode7 BlendMode for bottom-left corner
				@param blendmode8 BlendMode for bottom edge
				@param blendmode9 BlendMode for bottom-right corner
	
				@param alpha1 Float for top-left corner
				@param alpha2 Float for top edge
				@param alpha3 Float for top-right corner
				@param alpha4 Float for left edge
				@param alpha5 Float for center area
				@param alpha6 Float for right edge
				@param alpha7 Float for bottom-left corner
				@param alpha8 Float for bottom edge
				@param alpha9 Float for bottom-right corner
				#end
				Method Image<T>(	this:Rect9<T>,
										
									' Patches:
													
									cornerTopLeft:Image,		top:Image,					cornerTopRight:Image,		
									left:Image,					middle:Image,				right:Image,
									cornerBottomLeft:Image,		bottom:Image,				cornerBottomRight:Image,
													
									' Patches mode:
			
									patch1mode:TileMode,		patch2mode:TileMode,		patch3mode:TileMode,
									patch4mode:TileMode,		patch5mode:TileMode,		patch6mode:TileMode,
									patch7mode:TileMode,		patch8mode:TileMode,		patch9mode:TileMode		) Where T Implements IReal Or T Implements INumeric
			
					'Init a sequence of:
					Local imgs:=New Image[](		cornerTopLeft,				top,						cornerTopRight,			
													left,						middle, 					right,
													cornerBottomLeft,			bottom,						cornerBottomRight		)
			
					Local modes:=New TileMode[](	patch1mode,					patch2mode,					patch3mode,	
													patch4mode,					patch5mode,					patch6mode,
													patch7mode,					patch8mode,					patch9mode				)
				
					'Compute the rect9's patches
					Local patches:=this.Patches
			
					'Draw the patches
					For Local tile:=0 Until 8
						If imgs[tile]<>Null _._.Image_.Tile( imgs[tile], patches[tile], modes[tile] )
					End
				End 
	
				Method Image<T>(	this:Rect9<T>,
	
									' Patches:
													
									cornerTopLeft:Image,		top:Image,					cornerTopRight:Image,		
									left:Image,					middle:Image,				right:Image,
									cornerBottomLeft:Image,		bottom:Image,				cornerBottomRight:Image,
													
									' Patches mode:
			
									patch1mode:TileMode,		patch2mode:TileMode,		patch3mode:TileMode,
									patch4mode:TileMode,		patch5mode:TileMode,		patch6mode:TileMode,
									patch7mode:TileMode,		patch8mode:TileMode,		patch9mode:TileMode,
									
									' blendmode:
	
									blendmode1:BlendMode,		blendmode2:BlendMode,		blendmode3:BlendMode,
									blendmode4:BlendMode,		blendmode5:BlendMode,		blendmode6:BlendMode,
									blendmode7:BlendMode,		blendmode8:BlendMode,		blendmode9:BlendMode,
									
									' alpha:
									
									alpha1:Float=1.0,			alpha2:Float=1.0,			alpha3:Float=1.0,
									alpha4:Float=1.0,			alpha5:Float=1.0,			alpha6:Float=1.0,
									alpha7:Float=1.0,			alpha8:Float=1.0,			alpha9:Float=1.0	) Where T Implements IReal Or T Implements INumeric
			
					'Init a sequence of:
					Local imgs:=New Image[](		cornerTopLeft,				top,						cornerTopRight,			
													left,						middle, 					right,
													cornerBottomLeft,			bottom,						cornerBottomRight		)
			
					Local modes:=New TileMode[](	patch1mode,					patch2mode,					patch3mode,	
													patch4mode,					patch5mode,					patch6mode,
													patch7mode,					patch8mode,					patch9mode				)
				
					Local bmodes:=New BlendMode[](	blendmode1,					blendmode2,					blendmode3,
													blendmode4,					blendmode5,					blendmode6,
													blendmode7,					blendmode8,					blendmode9				)
	
					Local alphas:=New BlendMode[](	alpha1,						alpha2,						alpha3,
													alpha4,						alpha5,						alpha6,
													alpha7,						alpha8,						alpha9					)
					
					'Compute the rect9's patches
					Local patches:=this.Patches
					
					'Store the canvas's state
					Local blendMode_old:=___.BlendMode
					Local alpha_old:=___.Alpha
			
					'Draw the patches
					For Local tile:=0 Until 8
						If imgs[tile]<>Null 
							___.BlendMode=bmodes[tile]
							'TODO: Use Trim for alpha as guard
							If alphas[tile]<0 alphas[tile]=0
							If alphas[tile]>1 alphas[tile]=1
							___.Alpha=alphas[tile]
							_._.Image_.Tile( imgs[tile], patches[tile], modes[tile] )
						End
					End
	
					'Restore the canvas's state
					___.BlendMode=blendMode_old
					___.Alpha=alpha_old
				End 	
				
				#rem monkeydoc Draws the outter frame of a rect9, precise the color.
				Draws the rect9's outter rect using the current BlendMode.
				The outter rect have his own color as an optional parameter.
				The vertex coordinates are also transform by the current Matrix. 	
				@param The rect9 to draw
				@param Outter frame color
				#end	
				Method OutterFrame<T>( this:Rect9<T>, colorOutterRect:Color=___.Color ) Where T Implements IReal Or T Implements INumeric
					
					Local oldColor:=___.Color
					___.Color=colorOutterRect
					__.Wireframe.Rect(this._rect0.min.x,this._rect0.min.y,this._rect0.Width,this._rect0.Height)
					___.Color=oldColor
				End 
				
				#rem monkeydoc Draws a rect9's inner frame.	
				Draws the rect9's inner rect using the current BlendMode.
				The vertex coordinates are also transform by the current Matrix. 	
				The inner rect have his own color as an optional parameter.
				@param The rect9 to draw
				@param Inner frame color
				#end		
				Method InnerFrame<T>( this:Rect9<T>, colorInnerRect:Color=___.Color ) Where T Implements IReal Or T Implements INumeric
					
					Local oldColor:=___.Color
					___.Color=colorInnerRect
					__.Wireframe.Rect(this.Inner.min.x,this.Inner.min.y,this.Inner.Width,this.Inner.Height)
					___.Color=oldColor
				End 	
		
				#rem monkeydoc Draw the outter rect with a H inside representing the zone delimitations
				Because the wireframe method actually draws the two rectangles of rect9, while this
				method draws the lines projected from the inner rect to the outter rect.
				@param The Rect9 to draw
				@param optional color for the exterior frame
				@param optional color for the H lines
				#end 
				Method GridH<T>( this:Rect9<T>, externColor:Color=New Color(1,1,0), gridColor:Color=New Color(1,0,0) ) Where T Implements IReal Or T Implements INumeric				
					
					Local old_color:=___.Color
					
					___.Color=externColor
					__.Wireframe.Rect(this.Outter.min.x,this.Outter.min.y,this.Outter.Width,this.Outter.Height)
					
					___.Color=gridColor
					H(this)
					
					___.Color=old_color
				End
	
				#rem monkeydoc Mini-Library TPatches.Debug
				@author iDkP from GaragePixel
				@since 2025-05-25
						
				Specialized debugging visualization tools for Rect9 structures.
				
				Note: the TPatches.TDebug is a singleton created in the TPatches class
				and addressable as a property. You call the property Debug to get 
				access to the debug drawing functions specific to Rect9 structures.
				
				canvas.Draw.Rect.Patches.Debug.GridZ( myrect9 )
				
				This debugging library provides specialized drawing operations for
				visualizing Rect9 structures during development. Methods include
				grid patterns (H, Z, Cross) that highlight the 9 distinct regions
				of a Rect9. These grid patterns are invaluable for debugging nine-patch
				rendering and complex UI layouts.
				
				All methods support generic type parameters for coordinate systems
				and provide consistent coloring options for visual distinction.
				#end			
				Class TDebug
			
					#rem monkeydoc Draw the outter rect with a H inside and a Z in the H zones
					Because the wireframe method actually draws the two rectangles of rect9, while this
					method draws the lines projected from the inner rect to the outter rect.
					@param The Rect9 to draw
					@param optional color for the exterior frame
					@param optional color for the Z lines
					#end 
					Method GridZ<T>( this:Rect9<T>, externColor:Color=New Color(1,1,0), gridColor:Color=New Color(1,0,0) ) Where T Implements IReal Or T Implements INumeric
						
						Local old_color:=___.Color
						
						____.Color=externColor
						_._._.Wireframe.Rect(this.Outter.min.x,this.Outter.min.y,this.Outter.Width,this.Outter.Height)
						
						____.Color=gridColor
						H(this)
						Z(this)
						
						____.Color=old_color
					End
				
					#rem monkeydoc Draw the outter rect with a H inside and a X in the H zones
					Because the wireframe method actually draws the two rectangles of rect9, while this
					method draws the lines projected from the inner rect to the outter rect.
					@param The Rect9 to draw
					@param optional color for the exterior frame
					@param optional color for the X lines
					#end
					Method GridCross<T>( this:Rect9<T>, externColor:Color=New Color(1,1,0), gridColor:Color=New Color(1,0,0) ) Where T Implements IReal Or T Implements INumeric				
						
						Local old_color:=____.Color
						
						____.Color=externColor
						_._._.Wireframe.Rect(this.Outter.min.x,this.Outter.min.y,this.Outter.Width,this.Outter.Height)
						
						____.Color=gridColor
						H(this)
						Self.X(this) 'Self is used by caution
						
						____.Color=old_color
					End
				
					#rem monkeydoc Draw only the grid H
					Because the wireframe method actually draws the two rectangles of rect9, while this
					method draws the lines projected from the inner rect to the outter rect.
					@param The Rect9 to draw
					#end
					Method H<T>( this:Rect9<T>) Where T Implements IReal Or T Implements INumeric
						
						'V Lines
						____.Draw.Line(	this.InnerLeft,		this.Top,			this.InnerLeft,		this.Bottom)
						____.Draw.Line(	this.InnerRight,	this.Top,			this.InnerRight,	this.Bottom)
						
						'H Lines
						____.Draw.Line(	this.Left,			this.InnerTop,		this.Right,			this.InnerTop)
						____.Draw.Line(	this.Left,			this.InnerBottom,	this.Right,			this.InnerBottom)
					End 
				
					#rem monkeydoc Draw only the Z
					@param The Rect9 to draw
					#end
					Method Z<T>( this:Rect9<T> ) Where T Implements IReal Or T Implements INumeric
						Local verts:=this.Vertices
						Zinternal(this, verts)
					End
				
					#rem monkeydoc Draw only the cross (X shape)
					@param The Rect9 to draw
					#end
					Method X<T>( this:Rect9<T> )  Where T Implements IReal Or T Implements INumeric'Method Cross<T>( this:Rect9<T> ) 'iDkP: CANNOT CALL IT 'DRAWX' BECAUSE INTERNAL BUG!
						
						Local verts:Vec2<T>[]=this.Vertices
						
						Zinternal(this, verts)
				
						'X Boxes 1,2,3
						____.Draw.Line(	verts[00].x,	verts[01].y,	verts[05].x,	verts[04].y)
						____.Draw.Line(	verts[01].x,	verts[02].y,	verts[06].x,	verts[05].y)
						____.Draw.Line(	verts[02].x,	verts[03].y,	verts[07].x,	verts[06].y)
						
						'X Boxes 4,5,6
						____.Draw.Line(	verts[04].x,	verts[05].y,	verts[09].x,	verts[08].y)
						____.Draw.Line(	verts[05].x,	verts[06].y,	verts[10].x,	verts[09].y)
						____.Draw.Line(	verts[06].x,	verts[07].y,	verts[11].x,	verts[10].y)
				
						'X Boxes 7,8,9
						____.Draw.Line(	verts[08].x,	verts[09].y,	verts[13].x,	verts[12].y)
						____.Draw.Line(	verts[09].x,	verts[10].y,	verts[14].x,	verts[13].y)
						____.Draw.Line(	verts[10].x,	verts[11].y,	verts[15].x,	verts[14].y)
					End
				
					Private 
				
					#rem monkeydoc @hidden
					#end
					Method Zinternal<T>( this:Rect9<T>, verts:Vec2<T>[] ) Where T Implements IReal Or T Implements INumeric
						
						'Z Boxes 1,2,3
						____.Draw.Line(	verts[01].x,	verts[01].y,	verts[04].x,	verts[04].y)
						____.Draw.Line(	verts[02].x,	verts[02].y,	verts[05].x,	verts[05].y)
						____.Draw.Line(	verts[03].x,	verts[03].y,	verts[06].x,	verts[06].y)
						
						'Z Boxes 4,5,6
						____.Draw.Line(	verts[05].x,	verts[05].y,	verts[08].x,	verts[08].y)
						____.Draw.Line(	verts[06].x,	verts[06].y,	verts[09].x,	verts[09].y)
						____.Draw.Line(	verts[07].x,	verts[07].y,	verts[10].x,	verts[10].y)
				
						'Z Boxes 7,8,9
						____.Draw.Line(	verts[09].x,	verts[09].y,	verts[12].x,	verts[12].y)
						____.Draw.Line(	verts[10].x,	verts[10].y,	verts[13].x,	verts[13].y)
						____.Draw.Line(	verts[11].x,	verts[11].y,	verts[14].x,	verts[14].y)
					End	
					
					Field _:TPatches 'parent of TPatches.TDebug
					
					Field __:TRect_
					
					Field ___:TDraw
					
					Field ____:Canvas 'canvas of the tdebug's tpatches' trect's tdraw's parent (bypass some redundant internal pointing processes)
				End 
				
				Private
				
				Field _:TRect_ 'parent of TPatches
				
				Field __:TDraw
				
				Field ___:Canvas 'canvas of the tpatches' trect's tdraw's parent (bypass some redundant internal pointing processes)
				
				Field _tdebug:TDebug=New TDebug() 'Special tpatches's draw functions for debugging purpose
			End
			
			Private
		
			Field _:TDraw 'parent
			
			Field __:Canvas 'canvas of the trect's tdraw's parent (bypass some redundant internal pointing processes)
			
			Field _tpatches:TPatches=New TPatches() 'Patches's dedicaced draw methods
			
			Field _tframe:TFrame=New TFrame() 'Frame's dedicaced draw methods

		End  

		#rem monkeydoc Draws an oval.
		Draws an oval in the current [[Color]] using the current [[BlendMode]].
		The oval vertex coordinates are also transform by the current [[Matrix]].
		@param x Top left x coordinate for the oval.
		@param y Top left y coordinate for the oval.
		@param width Width of the oval.
		@param height Height of the oval.
		#end
		Method Oval( x:Float,y:Float,width:Float,height:Float )
		
			Local xr:=width/2,yr:=height/2
			
			Local dx_x:=xr*_._matrix.i.x
			Local dx_y:=xr*_._matrix.i.y
			Local dy_x:=yr*_._matrix.j.x
			Local dy_y:=yr*_._matrix.j.y
			Local dx:=Sqrt( dx_x*dx_x+dx_y*dx_y )
			Local dy:=Sqrt( dy_x*dy_x+dy_y*dy_y )
	
			Local n:=Max( Int( dx+dy ),12 ) & ~3
			
			Local x0:=x+xr,y0:=y+yr
			
			_.AddDrawOp( _._shader,_._material,_._blendMode,n,1 )
			
			For Local i:=0 Until n
				Local th:=(i+.5)*Pi*2/n
				Local px:=x0+Cos( th ) * xr
				Local py:=y0+Sin( th ) * yr
				_.AddPointVertex( px,py,0,0 )
			Next
			
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Return 'ATTENTION
			
			For Local i:=0 until n
	
				Local th0:=(i+.5)*TwoPi/n
				Local px0:=x0+Cos( th0 ) * xr
				Local py0:=y0+Sin( th0 ) * yr
				
				Local th1:=(i+1.5)*TwoPi/n
				Local px1:=x0+Cos( th1 ) * xr
				Local py1:=y0+Sin( th1 ) * yr
				
				_.DrawOutlineLine( px0,py0,px1,py1 )
			
			Next
			
		End
		
		#rem monkeydoc Draws an ellipse.
		Draws an ellipse in the current [[Color]] using the current [[BlendMode]].
		The ellipse is also transformed by the current [[Matrix]].
		@param x Center x coordinate for the ellipse.
		@param y Center y coordinate for the ellipse.
		@param xRadius X axis radius for the ellipse.
		@param yRadius Y axis radius for the ellipse.
		#end
		Method Ellipse( x:Float,y:Float,xRadius:Float,yRadius:Float )
			
			Oval( x-xRadius,y-yRadius,xRadius*2,yRadius*2 )
		End
		
		#rem monkeydoc Draws a circle.
		Draws a circle in the current [[Color]] using the current [[BlendMode]] and transformed by the current [[Matrix]].
		@param x Center x coordinate for the circle.
		@param y Center y coordinate for the circle.
		@param radius The circle radius.
		#end
		Method Circle( x:Float,y:Float,radius:Float )
			
			Oval( x-radius,y-radius,radius*2,radius*2 )
		End
	
		#rem monkeydoc Draws a polygon.
		Draws a polygon using the current [[Color]], [[BlendMode]] and [[Matrix]].
		The `vertices` array must be at least 2 elements long
		@param vertices Array of x/y vertex coordinate pairs.
		#end
		Method Poly( vertices:Float[] )
			
			Local order:=vertices.Length/2
			DebugAssert( order>=1,"Invalid polygon" )
			
			_.AddDrawOp( _._shader,_._material,_._blendMode,order,1 )
			
			For Local i:=0 Until order*2 Step 2
				
				_.AddVertex( vertices[i],vertices[i+1],0,0 )
			Next
	
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Or order<3 Return 'ATTENTION
			
			For Local i:=0 Until order-1
				
				Local k:=i*2
				_.DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
			Next
			
			Local kn:=(order-1)*2
			_.DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[0],vertices[1] )
		End
		
		#rem monkeydoc Draws a sequence of polygons.
		Draws a sequence of polygons using the current [[Color]], [[BlendMode]] and [[Matrix]].
		@param order The type of polygon: 3=triangles, 4=quads, >4=n-gons.
		@param count The number of polygons.
		@param vertices Array of x/y vertex coordinate pairs.
		#end
		Method Polys( order:Int,count:Int,vertices:Float[] )
			
			DebugAssert( order>=1 And count>0 And order*count<=vertices.Length,"Invalid polyon" )
	
			_.AddDrawOp( _._shader,_._material,_._blendMode,order,count )
			
			For Local i:=0 Until order*count*2 Step 2
				
				_.AddVertex( vertices[i],vertices[i+1],0,0 )
			Next
			
			If _._outlineMode=sdk_mojo.m2.graphics.OutlineMode.None Or order<3 Return 'ATTENTION
			
			For Local i:=0 Until count
				
				For Local j:=0 Until order-1
					
					Local k:=(i*order+j)*2
					_.DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
				Next
				
				Local k0:=i*order*2,kn:=(i*order+order-1)*2
				_.DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[k0],vertices[k0+1] )
			Next
			
		End
		
		#rem monkeydoc Draws a sequence of primtives.
		Draws a sequence of convex primtives using the current [[Color]], [[BlendMode]] and [[Matrix]].
		@param order The type of primitive: 1=points, 2=lines, 3=triangles, 4=quads, >4=n-gons.
		@param count The number of primitives to draw.
		@param vertices Pointer to the first vertex x,y pair.
		@param verticesPitch Number of bytes from one vertex x,y pair to the next. Set to 8 for 'tightly packed' vertices.
		@param texCoords Pointer to the first texCoord s,t pair. This can be null.
		@param texCoordsPitch Number of bytes from one texCoord s,y to the next. Set to 8 for 'tightly packed' texCoords.
		@param colors Pointer to the first RGBA uint color value. This can be null.
		@param colorsPitch Number of bytes from one RGBA color to the next. Set to 4 for 'tightly packed' colors.
		@param image Source image for rendering. This can be null.
		@param indices Pointer to sequence of integer indices for indexed drawing. This can by null for non-indexed drawing.
		#end
		Method Primitives( order:Int,count:Int,vertices:Float Ptr,verticesPitch:Int,texCoords:Float Ptr,texCoordsPitch:Int,colors:UInt Ptr,colorsPitch:Int,image:Image,indices:Int Ptr )
			
			DebugAssert( order>0 And count>0,"Illegal primitive" )
	
			If image
				_.AddDrawOp( image.Shader,image.Material,image.BlendMode,order,count )
			Else
				_.AddDrawOp( _._shader,_._material,_._blendMode,order,count )
			End
			
			Local n:=order*count
			
			If indices
				If texCoords And colors
					For Local i:=0 Until n
						Local j:=indices[i]
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
						Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
						Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
						_.AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
					Next
				ElseIf texCoords
					For Local i:=0 Until n
						Local j:=indices[i]
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
						Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
						_.AddVertex( vp[0],vp[1],tp[0],tp[1] )
					Next
				ElseIf colors
					For Local i:=0 Until n
						Local j:=indices[i]
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
						Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
						_.AddVertex( vp[0],vp[1],0,0,cp[0] )
					Next
				Else
					For Local i:=0 Until n
						Local j:=indices[i]
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
						_.AddVertex( vp[0],vp[1],0,0 )
					Next
				End
			Else
				If texCoords And colors
					For Local i:=0 Until n
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
						Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
						Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
						_.AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
					Next
				ElseIf texCoords
					For Local i:=0 Until n
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
						Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
						_.AddVertex( vp[0],vp[1],tp[0],tp[1] )
					Next
				ElseIf colors
					For Local i:=0 Until n
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
						Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
						_.AddVertex( vp[0],vp[1],0,0,cp[0] )
					Next
				Else
					For Local i:=0 Until n
						Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
						_.AddVertex( vp[0],vp[1],0,0 )
					Next
				End
			End
		End

		Method Image( image:Image,tx:Float,ty:Float ) 'iDkP here, forced overload -> no branch test
		
			Local vs:=image.Vertices
			Local ts:=image.TexCoords
			
			_.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
			
			_.AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
			_.AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
			_.AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
			_.AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
			
			If _lighting And image.ShadowCaster
				_.AddShadowCaster( image.ShadowCaster,tx,ty )
			End
		End
		
		Method Image( image:Image,tx:Float,ty:Float,rz:Float )
			Local matrix:=_.Matrix
			_.Matrix=matrix.Translate( tx,ty ).Rotate( rz )
			Image( image,0,0 )
			_.Matrix=matrix
		End
	
		Method Image( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
			Local matrix:=_.Matrix
			_.Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
			Image( image,0,0 )
			_.Matrix=matrix
		End
	
		Method Image( image:Image,tv:Vec2f )
			Image( image,tv.x,tv.y )
		End
		
		Method Image( image:Image,tv:Vec2f,rz:Float )
			Image( image,tv.x,tv.y,rz )
		End
		
		Method Image( image:Image,tv:Vec2f,rz:Float,sv:Vec2f )
			Image( image,tv.x,tv.y,rz,sv.x,sv.y )
		End

		Method Image( 'ATTENTION
			'Added by iDkP
			image:ImageWrapperMojo,
			x:Float,y:Float,
			rotation:Float,
			scaleX:Float,scaleY:Float)
			
			Image(image.Image,x,y,rotation,scaleX,scaleY)
		End
		
		Class TImage_ 

			#rem monkeydoc Draw an image tiled within a rectangle with various tiling patterns.
			@author iDkP for GaragePixel
			@since 2025-05-23
			@version 2025-05-26
			
			This method tiles an image throughout a rectangle using specified tiling mode.
			It automatically handles scissoring to prevent drawing outside the rectangle bounds.
			Uses DrawImageFit for each individual tile in the pattern.
		
			@param imgTile The image to be tiled
			@param this The rectangle that will contain the tiled pattern
			@param mode Controls tiling arrangement (combination of horizontal and vertical modes)
			#end
			Method Tiled<T>( imgTile:Image, this:Rect<T>, mode:TileMode=TileMode.Tiled ) Where T Implements IReal Or T Implements INumeric
				
				' iDkP note 2025-05-23:
				'
				'	TODO: Make a shader for tiling
				'
				'	We can do it faster with a shader. For now, this function uses DrawImageFit
				'	and the function Tiled of Rect to compute the tiles.
				'	With this GPU-non shader version of the tiling, we can access to the
				'	tile individually instead of just repeating the same tile.
				'	Since Draw.Rect_.Tiled do not offer this granulality, it will be replaced
				'	by a shader version under a few time.
		
				Local tileField:=this.Tiled<T>(imgTile.Bounds,mode) '<-- We can use the Int type
				
				If tileField=Null Return 'Do not draw flat tile
				
				Local scissor_old:=_._.Scissor
				_._.Scissor=this
				
				For Local tile:=Eachin tileField 
					Rect( imgTile, tile )
				End
				
				_._.Scissor=scissor_old
			End
		
			#rem monkeydoc Draw an image using a rect as reference.
			@author iDkP for GaragePixel
			@since 2025-05-23
			@version 2025-05-28 (Fit renamed Rect)
			@param image the image to draw
			@param fit the rect used to get the image in position
			#end 
			Method Rect<T>( 	image:Image, 
								fit:Rect<T> ) Where T Implements IReal Or T Implements INumeric 'by iDkP
										
				Local sH:Float=fit.Height/image.Height
				Local sW:Float=fit.Width/image.Width
				_._.Draw.Image(image,fit.X,fit.Y,0,sW,sH)
			End 
		
			Method Rect( 	x:Float, y:Float, x1:Float, y1:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int ) 'by jl
							
				Local srcRect := New Recti( srcX, srcY, srcX1, srcY1 )
				Local s0 := Float( srcImage.Rect.min.x + srcRect.min.x ) / srcImage.Texture.Width
				Local t0 := Float( srcImage.Rect.min.y + srcRect.min.y ) / srcImage.Texture.Height
				Local s1 := Float( srcImage.Rect.min.x + srcRect.max.x ) / srcImage.Texture.Width
				Local t1 := Float( srcImage.Rect.min.y + srcRect.max.y ) / srcImage.Texture.Height
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
				_._.AddVertex( x, y, s0, t0, _._._pmcolor )
				_._.AddVertex( x1,y, s1, t0, _._._pmcolor )
				_._.AddVertex( x1,y1, s1, t1, _._._pmcolor )
				_._.AddVertex( x, y1, s0, t1, _._._pmcolor )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, inset:Float = 0.0015 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
				
				Local tx0:double = (wd * srcX) +inset
				Local ty0:double = (ht * srcY) +inset
				Local tx1:double = (wd * srcX1) -inset
				Local ty1:double = (ht * srcY1) -inset
				
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
		
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0, 0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1, 0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1, 1 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0, 1 )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, 
							shader:Shader, inset:Float = 0.0015 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
				
				Local tx0:double = (wd * srcX) +inset
				Local ty0:double = (ht * srcY) +inset
				Local tx1:double = (wd * srcX1) -inset
				Local ty1:double = (ht * srcY1) -inset
				
				_._.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 4,1 )
		
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0, 0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1, 0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1, 1 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0, 1 )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, 
							shader:Shader, mat:UniformBlock, inset:Float = 0.0015 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
				
				Local tx0:double = (wd * srcX) +inset
				Local ty0:double = (ht * srcY) +inset
				Local tx1:double = (wd * srcX1) -inset
				Local ty1:double = (ht * srcY1) -inset
				
				_._.AddDrawOp( shader, mat, srcImage.BlendMode, 4,1 )
		
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0, 0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1, 0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1, 1 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0, 1 )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
				
				Local tx0:double = (wd * srcX)
				Local ty0:double = (ht * srcY)
				Local tx1:double = (wd * srcX1)
				Local ty1:double = (ht * srcY1)
				
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
		
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0, 0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1, 0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1, 1 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0, 1 )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, fx:Shader 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
				
				Local tx0:double = (wd * srcX)
				Local ty0:double = (ht * srcY)
				Local tx1:double = (wd * srcX1)
				Local ty1:double = (ht * srcY1)
				
				_._.AddDrawOp( fx, srcImage.Material, srcImage.BlendMode, 4,1 )
		
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0, 0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1, 0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1, 1 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0, 1 )
			End
		
			Method Quad( 	x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, 
							srcImage:Image, 
							srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, fx:Shader, mat:UniformBlock 	)
							
				Local wd:double = 1.0 / float(srcImage.Width)
				Local ht:double = 1.0 / float(srcImage.Height)
	'			
				Local tx0:double = (wd * srcX)
				Local ty0:double = (ht * srcY)
				Local tx1:double = (wd * srcX1)
				Local ty1:double = (ht * srcY1)
	'			
				_._.AddDrawOp( fx, mat, srcImage.BlendMode, 4,1 )
	'	
				'jl modded
				_._.AddVertex( x0, y0,	tx0, ty0,	0.0, 0.0 )
				_._.AddVertex( x1, y1,	tx1, ty0,	1.0, 0.0 )
				_._.AddVertex( x2, y2,	tx1, ty1,	1.0, 1.0 )
				_._.AddVertex( x3, y3,	tx0, ty1,	0.0, 1.0 )
			End

			Method QuadIntersect( 	x0:Float, y0:Float, 
									x1:Float, y1:Float, 
									x2:Float, y2:Float, 
									x3:Float, y3:Float, 
									srcImage:Image 	)
				
				_.Tool.LineIntersect( x0, y0, x2, y2,	x1, y1, x3, y3 )
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x0,y0, 0,0 )
				_._.AddVertex( x1,y1, 1,0 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x1,y1, 1,0 )
				_._.AddVertex( x2,y2, 1,1 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x2,y2, 1,1 )
				_._.AddVertex( x3,y3, 0,1 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x3,y3, 0,1 )
				_._.AddVertex( x0,y0, 0,0 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
			End
		
			Method QuadIntersect( 	x0:Float, y0:Float, 
									x1:Float, y1:Float, 
									x2:Float, y2:Float, 
									x3:Float, y3:Float, 
									srcImage:Image, shader:Shader 	)
				
				_.Tool.LineIntersect( x0, y0, x2, y2,	x1, y1, x3, y3 )
		
				_._.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x0,y0, 0,0 )
				_._.AddVertex( x1,y1, 1,0 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
		
				_._.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x1,y1, 1,0 )
				_._.AddVertex( x2,y2, 1,1 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
		
				_._.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x2,y2, 1,1 )
				_._.AddVertex( x3,y3, 0,1 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )

				_._.AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
				_._.AddVertex( x3,y3, 0,1 )
				_._.AddVertex( x0,y0, 0,0 )
				_._.AddVertex( _.Tool._iX,_.Tool._iY, 0.5,0.5 )
			End
			
			Private 
			
			Field _:TDraw 'parent
			
		End 

		Class TIcon

			Method Icon( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, sx:Float, sy:Float )
				
				Local matrix_old:=_._._matrix
				_._.Translate( tx, ty )
				_._.Scale( sx, sy )
				_._.Rotate( 0 )
				
				Icon( image, 0,0, iconNumber, iconCount )
				
				_._._matrix = matrix_old
			End
		
			Method IconRotate( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, rot:Float, sx:Float, sy:Float )
				
				If iconCount < 0 Then Return
		
				Local matrix_old:=_._._matrix
				_._.Translate( tx, ty )
				_._.Scale( sx, sy )
				_._.Rotate( rot )
				
				Icon( image, 0,0, iconNumber, iconCount, rot )
				
				_._._matrix = matrix_old
			End
		
			#rem wonkeydoc Draws an image icon frame.
			Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].
			@param tx X coordinate to draw image at.
			@param ty Y coordinate to draw image at.
			@param tx1 X1 coordinate to draw image to.
			@param ty1 Y1 coordinate to draw image to.
			@param iconNumber number from 0 of the icon frame to draw (frames start from 0 and go left to right in equal pixel amounts).
			@param iconCount how many icon frames are packed into the image
			@param sx X axis scale factor for drawing.
			@param sy Y axis scale factor for drawing.
			@param rotate (in radians) of the icon. 0 = no rotation
		  	#end
			Method Icon( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, rotate:Float = 0 )
				
				If iconCount < 0 Then Return
			
				Local vs:=image.Vertices
				Local wd:double = (vs.max.x - vs.min.x) / iconCount
				vs.max.x = vs.min.x + wd
		
				Local tc:=image.TexCoords
				wd = (tc.max.x - tc.min.x) / iconCount
				tc.min.x = tc.min.x + (iconNumber * wd)
				tc.max.x = tc.min.x + wd
				
				If rotate <> 0 Then
					Local x:float = vs.min.x
					Local x1:float = vs.max.x
					Local y:float = vs.min.y
					Local y1:float = vs.max.y
		
					Local xm:float = (x1 + x) * .5
					Local ym:float = (y1 + y) * .5
					
					x -= xm
					y -= ym
					x1 -= xm
					y1 -= ym
		
					Local x2:float = x1
					Local y2:float = y1
					Local x3:float = x
					Local y3:float = y1
					x1 = x1
					y1 = y
					
					_._.AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
					_._.AddVertex( x + tx, y + ty,	tc.min.x, tc.min.y, _._._pmcolor )
					_._.AddVertex( x1 + tx, y1 + ty,	tc.max.x, tc.min.y, _._._pmcolor )
					_._.AddVertex( x2 + tx, y2 + ty,	tc.max.x, tc.max.y, _._._pmcolor )
					_._.AddVertex( x3 + tx, y3 + ty,	tc.min.x, tc.max.y, _._._pmcolor )
		
				Else
					Local x:float = vs.min.x + tx
					Local x1:float = vs.max.x + tx
					Local y:float = vs.min.y + ty
					Local y1:float = vs.max.y + ty
		
					_._.AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
					_._.AddVertex( x, y,	tc.min.x, tc.min.y, _._._pmcolor )
					_._.AddVertex( x1,y,	tc.max.x, tc.min.y, _._._pmcolor )
					_._.AddVertex( x1,y1,	tc.max.x, tc.max.y, _._._pmcolor )
					_._.AddVertex( x, y1,	tc.min.x, tc.max.y, _._._pmcolor )
				End
			End
		
			Method IconSize( image:Image, tx:Float, ty:Float, tx1:Int, ty1:Int, iconNumber:Int, iconCount:Int )
				
				If iconCount < 0 Then Return
			
				Local vs:=image.Vertices
				Local wd:double = (vs.max.x - vs.min.x) / iconCount
				vs.max.x = vs.min.x + wd
		
				Local tc:=image.TexCoords
				wd = (tc.max.x - tc.min.x) / iconCount
				tc.min.x = tc.min.x + (iconNumber * wd)
				tc.max.x = tc.min.x + wd
				
				Local x:float = vs.min.x + tx
				Local x1:float = tx1 + tx
				Local y:float = vs.min.y + ty
				Local y1:float = ty1 + ty
		
				_._.AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
				_._.AddVertex( x, y,	tc.min.x, tc.min.y, _._._pmcolor )
				_._.AddVertex( x1, y,	tc.max.x, tc.min.y, _._._pmcolor )
				_._.AddVertex( x1, y1,	tc.max.x, tc.max.y, _._._pmcolor )
				_._.AddVertex( x, y1,	tc.min.x, tc.max.y, _._._pmcolor )
			End
	
			#rem wonkeydoc Draws a quad from a source image.
			The source image is used and drawn at the given quad position in the current [[Color]] using the current [[BlendMode]].
			The quad vertex coordinates are also transformed by the current [[Matrix]].
			#end
			Method IconQuad( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, iconNumber:Int, iconCount:Int )
				If iconCount < 0 Then Return
			
				Local vs := srcImage.Vertices
				Local wd:Double = (vs.max.x - vs.min.x) / iconCount
		
				Local tc := srcImage.TexCoords
				wd = (tc.max.x - tc.min.x) / iconCount
				tc.min.x = tc.min.x + (iconNumber * wd)
				tc.max.x = tc.min.x + wd
		
				_._.AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
				_._.AddVertex( x0, y0, tc.min.x, tc.min.y, _._._pmcolor )
				_._.AddVertex( x1, y1, tc.max.x, tc.min.y, _._._pmcolor )
				_._.AddVertex( x2, y2, tc.max.x, tc.max.y, _._._pmcolor )
				_._.AddVertex( x3, y3, tc.min.x, tc.max.y, _._._pmcolor )
			End	
		
			Private 
		
			Field _:TDraw 'parent
		
		End 
	
		#rem monkeydoc Draws text.
		Draws text using the current [[Color]], [[BlendMode]] and [[Matrix]].
		@param text The text to draw.
		@param tx X coordinate to draw text at.
		@param ty Y coordinate to draw text at.
		@param handleX X handle for drawing.
		@param handleY Y handle for drawing.
		#end
		Method Text( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
		
			If Not text.Length Return
		
			tx-=_._font.TextWidth( text ) * handleX
			ty-=_._font.Height * handleY
			
			Local gpage:=_._font.GetGlyphPage( text[0] )
			If Not gpage gpage=_._font.GetGlyphPage( 0 )
	
			Local sx:Float,sy:Float
			Local tw:Float,th:Float
			
			Local i0:=0,lastChar:=0
			
			while i0<text.Length
			
				Local i1:=i0+1
				Local page:Image
				
				While i1<text.Length
				
					page=_._font.GetGlyphPage( text[i1] )
					If page And page<>gpage Exit
					
					i1+=1
				Wend
	
				Local image:=gpage
				sx=image.Rect.min.x;sy=image.Rect.min.y
				tw=image.Texture.Width;th=image.Texture.Height
				_.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
				
				For Local i:=i0 Until i1
					
					Local char:=text[i]
	
					tx+=_._font.GetKerning( lastChar,char )	'add kerning before render
				
					Local g:=_._font.GetGlyph( char )
				
					Local s0:=Float(g.rect.min.x+sx)/tw
					Local t0:=Float(g.rect.min.y+sy)/th
					Local s1:=Float(g.rect.max.x+sx)/tw
					Local t1:=Float(g.rect.max.y+sy)/th
					
					Local x0:=Round( tx+g.offset.x )
					Local y0:=Round( ty+g.offset.y )
					Local x1:=x0+g.rect.Width
					Local y1:=y0+g.rect.Height
		
					_.AddVertex( x0,y0,s0,t0, _._pmcolor )
					_.AddVertex( x1,y0,s1,t0, _._pmcolor )
					_.AddVertex( x1,y1,s1,t1, _._pmcolor )
					_.AddVertex( x0,y1,s0,t1, _._pmcolor )
					
					tx+=g.advance							'add advance after render
	
					lastChar=char
				Next
				
				gpage=page
				
				i0=i1
			Wend
		End

		Class TText_

			Method VSize( text:String, tx:Float, ty:Float, xSize:Float = 1, ySize:Float = 1 )
				
				If Not text.Length Return
			
		'		tx-=_font.TextWidth( text ) * handleX
		'		ty-=_font.Height * handleY
				
				Local gpage:=_._._font.GetGlyphPage( text[0] )
				If Not gpage gpage=_._._font.GetGlyphPage( 0 )
		
				Local sx:Float
				Local sy:Float
				Local tw:Float
				Local th:Float
				
				Local i0:=0
				
				while i0 < text.Length
					Local i1:=i0+1
					Local page:Image'GlyphPage
					
					While i1<text.Length
						page=_._._font.GetGlyphPage( text[i1] )
						If page And page<>gpage Exit
						
						i1+=1
					Wend
		
					Local image:Image = gpage
					sx = image.Rect.min.x
					sy = image.Rect.min.y
					tw = image.Texture.Width
					th = image.Texture.Height
					_._.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
					
					For Local i:=i0 Until i1
						Local g:=_._._font.GetGlyph( text[i] )
					
						Local s0:float = Float( g.rect.min.x + sx ) / tw
						Local t0:float = Float( g.rect.min.y + sy ) / th
						Local s1:float = Float( g.rect.max.x + sx ) / tw
						Local t1:float = Float( g.rect.max.y + sy ) / th
						
						Local x0:float = Round( tx + g.offset.y )
						Local y0:float = Round( ty + g.offset.x )
						Local x1:float = x0 + g.rect.Height * ySize
						Local y1:float = y0 + g.rect.Width * xSize
			
						_._.AddVertex( x0,y0, s0,t1, _._._pmcolor )
						_._.AddVertex( x1,y0, s0,t0, _._._pmcolor )
						_._.AddVertex( x1,y1, s1,t0, _._._pmcolor )
						_._.AddVertex( x0,y1, s1,t1, _._._pmcolor )
						
						ty += g.rect.Width * xSize
					Next
					
					gpage=page
					
					i0=i1
				Wend
			End
		
			Method Size( text:String, tx:Float, ty:Float, xSize:Float = 1, ySize:Float = 1 )
				
				If Not text.Length Return
			
		'		tx-=_font.TextWidth( text ) * handleX
		'		ty-=_font.Height * handleY
				
				Local gpage:=_._._font.GetGlyphPage( text[0] )
				If Not gpage gpage=_._._font.GetGlyphPage( 0 )
		
				Local sx:Float
				local sy:Float
				Local tw:Float
				Local th:Float
				
				Local i0:=0
				
				while i0 < text.Length
					Local i1:=i0+1
					Local page:Image'GlyphPage
					
					While i1<text.Length
						page=_._._font.GetGlyphPage( text[i1] )
						If page And page<>gpage Exit
						
						i1+=1
					Wend
		
					Local image:=gpage
					sx = image.Rect.min.x
					sy = image.Rect.min.y
					tw = image.Texture.Width
					th = image.Texture.Height
					_._.AddDrawOp( image.Shader, image.Material, image.BlendMode, 4, i1-i0 )
					
					For Local i:=i0 Until i1
						Local g:=_._._font.GetGlyph( text[i] )
					
						Local s0:float = Float( g.rect.min.x + sx ) / tw
						Local t0:float = Float( g.rect.min.y + sy ) / th
						Local s1:float = Float( g.rect.max.x + sx ) / tw
						Local t1:float = Float( g.rect.max.y + sy ) / th
						
						Local x0 := Round( tx+g.offset.x )
						Local y0 := Round( ty+g.offset.y )
						Local x1 := x0 + g.rect.Width * xSize
						Local y1 := y0 + g.rect.Height * ySize
			
						_._.AddVertex( x0, y0, s0, t0, _._._pmcolor )
						_._.AddVertex( x1, y0, s1, t0, _._._pmcolor )
						_._.AddVertex( x1, y1, s1, t1, _._._pmcolor )
						_._.AddVertex( x0, y1, s0, t1, _._._pmcolor )
						
						tx += g.advance * xSize
					Next
					
					gpage=page
					
					i0=i1
				Wend
			End	
		
			Method Bold( text:String, tx:Float, ty:Float )
				
				If Not text.Length Return
		
				_.Text( text, tx, ty )
				_.Text( text, tx+1, ty )
			End
		
			Method Bold( text:String, tx:Float, ty:Float, bold:Float, handleX:Float=0,handleY:Float=0 )
				
				If Not text.Length Return
				
				bold /= 10
				Local bold2:float = bold + bold
			
				tx-=_._._font.TextWidth( text ) * handleX
				ty-=_._._font.Height * handleY
				
				Local gpage:=_._._font.GetGlyphPage( text[0] )
				If Not gpage gpage=_._._font.GetGlyphPage( 0 )
		
				Local sx:Float
				local sy:Float
				Local tw:Float
				Local th:Float
				
				Local i0:=0
				
				while i0<text.Length
					Local i1:=i0+1
					Local page:Image'GlyphPage
					
					While i1<text.Length
						page=_._._font.GetGlyphPage( text[i1] )
						If page And page<>gpage Exit
						
						i1+=1
					Wend
		
					Local image:=gpage
					sx=image.Rect.min.x;sy=image.Rect.min.y
					tw=image.Texture.Width;th=image.Texture.Height
					_._.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
					
					For Local i:=i0 Until i1
						Local g:=_._._font.GetGlyph( text[i] )
					
						Local s0:=(Float(g.rect.min.x+sx)/tw)
						Local t0:=(Float(g.rect.min.y+sy)/th)
						Local s1:=(Float(g.rect.max.x+sx)/tw)
						Local t1:=(Float(g.rect.max.y+sy)/th)
						
						Local x0:=Round( tx+g.offset.x ) - bold
						Local y0:=Round( ty+g.offset.y ) - bold
						Local x1:=(x0+g.rect.Width) + bold2
						Local y1:=(y0+g.rect.Height) + bold2
			
						_._.AddVertex( x0,y0,s0,t0, _._._pmcolor )
						_._.AddVertex( x1,y0,s1,t0, _._._pmcolor )
						_._.AddVertex( x1,y1,s1,t1, _._._pmcolor )
						_._.AddVertex( x0,y1,s0,t1, _._._pmcolor )
						
						tx+=g.advance
					Next
					
					gpage=page
					
					i0=i1
				Wend
			End
		
			Method V( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
				
				If Not text.Length Return
			
				tx-=_._._font.TextWidth( text ) * handleX
				ty-=_._._font.Height * handleY
				
				Local gpage:=_._._font.GetGlyphPage( text[0] )
				If Not gpage gpage=_._._font.GetGlyphPage( 0 )
		
				Local sx:Float
				Local sy:Float
				Local tw:Float
				Local th:Float
				
				Local i0:=0
				
				while i0 < text.Length
					Local i1:=i0+1
					Local page:Image'GlyphPage
					
					While i1<text.Length
						page=_._._font.GetGlyphPage( text[i1] )
						If page And page<>gpage Exit
						
						i1+=1
					Wend
		
					Local image:Image = gpage
					sx = image.Rect.min.x
					sy = image.Rect.min.y
					tw = image.Texture.Width
					th = image.Texture.Height
					_._.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
					
					For Local i:=i0 Until i1
						Local g:=_._._font.GetGlyph( text[i] )
					
						Local s0:float = Float( g.rect.min.x + sx ) / tw
						Local t0:float = Float( g.rect.min.y + sy ) / th
						Local s1:float = Float( g.rect.max.x + sx ) / tw
						Local t1:Float = Float( g.rect.max.y + sy ) / th
		
						Local x0:float = Round( tx + g.offset.y )
						Local y0:float = Round( ty + g.offset.x )
						Local x1:float = x0 + g.rect.Height
						Local y1:float = y0 + g.rect.Width
			
						_._.AddVertex( x0,y0, s0,t1, _._._pmcolor )
						_._.AddVertex( x1,y0, s0,t0, _._._pmcolor )
						_._.AddVertex( x1,y1, s1,t0, _._._pmcolor )
						_._.AddVertex( x0,y1, s1,t1, _._._pmcolor )
						
						ty += g.rect.Width
					Next
					
					gpage=page
					
					i0=i1
				Wend
			End
		
			Method Spacing( text:String, tx:Float, ty:Float, spacing:Float, handleX:Float=0,handleY:Float=0 )
				
				If Not text.Length Return
				
				If spacing < 0.1 Then spacing = 0.1
			
				tx-=_._._font.TextWidth( text ) * handleX
				ty-=_._._font.Height * handleY
				
				Local gpage:=_._._font.GetGlyphPage( text[0] )
				If Not gpage gpage=_._._font.GetGlyphPage( 0 )
		
				Local sx:Float,sy:Float
				Local tw:Float,th:Float
				
				Local i0:=0
				
				while i0 < text.Length
					Local i1:=i0+1
					Local page:Image'GlyphPage
					
					While i1<text.Length
						page=_._._font.GetGlyphPage( text[i1] )
						If page And page<>gpage Exit
						
						i1+=1
					Wend
		
					Local image:=gpage
					sx=image.Rect.min.x;sy=image.Rect.min.y
					tw=image.Texture.Width;th=image.Texture.Height
					_._.AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
					
					For Local i:=i0 Until i1
						Local g:=_._._font.GetGlyph( text[i] )
					
						Local s0:=Float(g.rect.min.x+sx)/tw
						Local t0:=Float(g.rect.min.y+sy)/th
						Local s1:=Float(g.rect.max.x+sx)/tw
						Local t1:=Float(g.rect.max.y+sy)/th
						
						Local x0:=Round( tx+g.offset.x )
						Local y0:=Round( ty+g.offset.y )
						Local x1:=x0+g.rect.Width
						Local y1:=y0+g.rect.Height
			
						_._.AddVertex( x0,y0,s0,t0, _._._pmcolor )
						_._.AddVertex( x1,y0,s1,t0, _._._pmcolor )
						_._.AddVertex( x1,y1,s1,t1, _._._pmcolor )
						_._.AddVertex( x0,y1,s0,t1, _._._pmcolor )
						
						tx += g.advance * spacing
					Next
					
					gpage=page
					
					i0=i1
				Wend
			End
			
			Private
			
			Field _:TDraw 'parent
			
		End
		
		Class TWireframe
			
			'iDkP note: 'Wireframe' instead of 'Frame'. It takes me 2 days to figure what was meaning
			'frame' in this context until I read the code.

			#rem wonkeydoc Draws a rectangle wireframe (made from lines).
			Draws a rectangleline in the current [[Color]] using the current [[BlendMode]].
			The rectangle vertex coordinates are also transform by the current [[Matrix]].
			#end
			Method Rect( x:Float, y:Float, w:Float, h:Float )
			
				Local x0 := x
				Local y0 := y
				Local x1 := x+w-1
				Local y1 := y+h-1
				
				_.Line( x0, y0, x1, y0 )
				_.Line( x0, y0, x0, y1 )
				_.Line( x1, y0, x1, y1 )
				_.Line( x0, y1, x1, y1 )
				_.Point(x1, y1)
			End

			Method Rect<T>( rect:Rect<T> ) Where T Implements IReal Or T Implements INumeric
			
				Local x0 := rect.x
				Local y0 := rect.y
				Local x1 := rect.x+rect.w-1
				Local y1 := rect.y+rect.h-1
				
				_.Line( x0, y0, x1, y0 )
				_.Line( x0, y0, x0, y1 )
				_.Line( x1, y0, x1, y1 )
				_.Line( x0, y1, x1, y1 )
				_.Point(x1, y1)
			End

			#rem monkeydoc Draws a rect9, inner/outter rect using the same color.
			@author iDkP from GaragePixel
			@since 2025-05-29
			@version 2025-05-29
			Draws a rect9 in the current Color using the current BlendMode.
			The vertex coordinates are also transform by the current Matrix. 	
			@param The rect9 to draw
			#end	
			Method Patches<T>( this:Rect9<T> ) Where T Implements IReal Or T Implements INumeric
				
				Rect(this._rect0.min.x,this._rect0.min.y,this._rect0.Width,this._rect0.Height)
			End 
			
			#rem monkeydoc Draws a rect9, inner/outter rect using different colors.
			@author iDkP from GaragePixel
			@since 2025-05-29
			@version 2025-05-29
			Draws a rect9 using the current BlendMode.
			The outter rect and the inner rect have their own colors.
			The vertex coordinates are also transform by the current Matrix. 	
			@param The rect9 to draw
			@param Outter frame color
			@param Inner frame color
			#end
			Method Patches<T>( this:Rect9<T>, colorOutterRect:Color, colorInnerRect:Color ) Where T Implements IReal Or T Implements INumeric
				
				Local oldColor:=___.Color
				___.Color=colorOutterRect
				Rect(this.Outter.min.x,this.Outter.min.y,this.Outter.Width,this.Outter.Height)
				___.Color=colorInnerRect
				Rect(this.Inner.min.x,this.Inner.min.y,this.Inner.Width,this.Inner.Height)
				___.Color=oldColor
			End
			
			Method Circle( x:Float, y:Float, width:Float )
				Oval( x, y, width, width )
			End

		    #rem wonkeydoc Draws a frame around an oval with optional start and end angles in Radians.
		    Draws a wireframed oval in the current [[Color]] using the current [[BlendMode]].
		    The oval vertex coordinates are also transform by the current [[Matrix]].
		    @param x Center x coordinate for the oval.
		    @param y Center y coordinate for the oval.
		    @param xRadius X axis radius for the oval.
		    @param yRadius Y axis radius for the oval.
		    @param fromAngle the start angle in radians (optional).
		    @param toAngle the end angle in radians (optional).
		    Pi2 is a complete circle. 0 is east, PiHalf is south, etc.
		    Radians run clockise. Use Deg2Rad() to convert Degrees to Radians.
		    #end
		    Method Oval( x:Float, y:Float, xRadius:Float, yRadius:Float )
		        Local xr := xRadius
		        Local yr := yRadius
		        
		        Local dx_x := xr*_._._matrix.i.x
		        Local dx_y := xr*_._._matrix.i.y
		        Local dy_x := yr*_._._matrix.j.x
		        Local dy_y := yr*_._._matrix.j.y
		        Local dx := Sqrt( dx_x*dx_x+dx_y*dx_y )
		        Local dy := Sqrt( dy_x*dy_x+dy_y*dy_y )
		
		        Local n := (Max( Int( dx+dy ),13 ) & ~3)
		        
		        Local x0 := x
		        local y0 := y
		        
		        local th:float = .5*Pi*2/n
		        local px:float
		        local py:float
		        local pxo:float = x0+Cos( th ) * xr
		        local pyo:float = y0+Sin( th ) * yr
		        
		        For Local i:=1 to n
		            th = (i+.5)*Pi*2/n
		            px = x0+Cos( th ) * xr
		            py = y0+Sin( th ) * yr
		            _.Line( px, py, pxo, pyo )
		            pxo = px
		            pyo = py
		        Next
		    End
		
		    Method Oval( x:Float, y:Float, xRadius:Float, yRadius:Float, fromAngle:float, toAngle:float )
		        Local xr:float = xRadius
		        Local yr:float = yRadius
		        
		        Local dx_x:float = xr*_._._matrix.i.x
		        Local dx_y:float = xr*_._._matrix.i.y
		        Local dy_x:float = yr*_._._matrix.j.x
		        Local dy_y:float = yr*_._._matrix.j.y
		        Local dx:float = Sqrt( dx_x*dx_x+dx_y*dx_y )
		        Local dy:float = Sqrt( dy_x*dy_x+dy_y*dy_y )
		
		        Local n:int = (Max( Int( dx+dy ),13 ) & ~3)*0.2
		        local th:float = (toAngle - fromAngle) / n
		        
		        local pxo:float = x + Cos( fromAngle ) * xr
		        local pyo:float = y + Sin( fromAngle ) * yr
		        local px:float
		        local py:float
		        
		        local k:int
		        For k = 1 To n
		            fromAngle += th
		            px = x + Cos( fromAngle ) * xr
		            py = y + Sin( fromAngle ) * yr
		            
		            _.Line( pxo,pyo, px,py )
		            pxo = px
		            pyo = py
		        Next
		    End
		
			Method OvalDepth( x:Float, y:Float, width:Float, height:Float, depth:float, scale:float )
				Local xr := width
				local yr := height
				
				Local dx_x := xr
				Local dx_y := xr
				Local dy_x := yr
				Local dy_y := yr
				Local dx := Sqrt( dx_x*dx_x+dx_y*dx_y )
				Local dy := Sqrt( dy_x*dy_x+dy_y*dy_y )
		
				Local n := (Max( Int( dx+dy ),13 ) & ~3) * 0.2
				
				Local x0 := x
				local y0 := y
				
				local th:float = .5*Pi*2/n
				local px:float
				local py:float
				
				local div:float = (Pi*2) / n
				th = -Pi*0.5
				local pxo:float = x0+Cos( th ) * xr
				local pyo:float = y0+Sin( th ) * yr
				th += div
				local offset:float
				local scaleDepth:float = scale * depth
				local cs:float
				'right side
				For Local i:=0 to n
					cs = Cos( th )
					offset = cs * scaleDepth
					px = x0 + cs * xr
					py = y0 + Sin( th ) * yr + offset
					_.Line( px, py, pxo, pyo )
					pxo = px
					pyo = py
					th += div
				Next
			End

			Method RectRounded( x:Float, y:Float, width:Float, height:Float, radius:Float )
				radius += 2
				If radius < 2 Then
					Rect( x, y, width, height )
					Return
				End If
		
				Local n:float = radius * 0.75
				local pointX:float[] = New float[n]
				local pointY:float[] = New float[n]
				
				local x0:float = x + radius
				local y0:float = y + radius
				local px:float
				local py:float
		
				local div:float = (Pi*0.5) / n
				local theta:float = Pi
				n -= 1
				
				local k:int
				local k1:int
				For k = 0 to n
					pointX[k] = Cos( theta ) * radius
					pointY[k] = Sin( theta ) * radius
					theta += div
				Next
				
				local x1:float = x + width
				local x1r:float = x1 - radius
				local y1:float = y + height
				local y1r:float = y1 - radius

				k1 = 1
				For k = 0 to n-1
					_.Line( x0+pointX[k], y0+pointY[k], x0+pointX[k1], y0+pointY[k1] )
					k1 += 1
				Next
		
				k1 -= 1
				_.Line( x0+pointX[k1], y0+pointY[k1], x1r-pointX[k1], y0+pointY[k1] )
		
				k1 = 1
				For k = 0 To n-1
					_.Line( x1r-pointX[k], y0+pointY[k], x1r-pointX[k1], y0+pointY[k1] )
					k1 += 1
				Next
		
				k1 -= 1
				_.Line( x1r-pointX[0], y0+pointY[0], x1r-pointX[0], y1r-pointY[0] )
		
				k1 = 1
				For k = 0 To n-1
					_.Line( x1r-pointX[k], y1r-pointY[k], x1r-pointX[k1], y1r-pointY[k1] )
					k1 += 1
				Next
		
				k1 -= 1
				_.Line( x0+pointX[k1], y1r-pointY[k1], x1r-pointX[k1], y1r-pointY[k1] )
		
				k1 = 1
				For k = 0 to n-1
					_.Line( x0+pointX[k], y1r-pointY[k], x0+pointX[k1], y1r-pointY[k1] )
					k1 += 1
				Next
		
				k1 -= 1
				_.Line( x0+pointX[0], y1r-pointY[0], x0+pointX[0], y0-pointY[0] )
			End

			Method RectChamfer( x:Float, y:Float, w:Float, h:Float, c:Float )
				Local x0:float = x
				Local y0:float = y
				Local x1:float = x+w
				Local y1:float = y+h
				
				Local cx0:float = x0 + c
				Local cx1:float = x1 - c
				Local cy0:float = y0 + c
				Local cy1:Float = y1 - c
				
				_.Line( cx0, y0, cx1, y0 )
				_.Line( cx1, y0, x1, cy0 )
				_.Line( x1, cy0, x1, cy1 )
				_.Line( x1, cy1, cx1, y1 )
				_.Line( cx1, y1, cx0, y1 )
				_.Line( cx0, y1, x0, cy1 )
				_.Line( x0, cy1, x0, cy0 )
				_.Line( x0, cy0, cx0, y0 )
			End

			Method Triangle( x:Float, y:Float, w:Float, angle:Float = 0 )
				Local x0:float = x + Sin(angle) * w
				Local y0:float = y + Cos(angle) * w
				angle += Pi * .666666
				Local x1:float = x + Sin(angle) * w
				Local y1:float = y + Cos(angle) * w
				angle += Pi * .666666
				Local x2:float = x + Sin(angle) * w
				Local y2:float = y + Cos(angle) * w
				
				_.Line( x0, y0, x1, y1)
				_.Line( x1, y1, x2, y2)
				_.Line( x2, y2, x0, y0)
			End
		
			Method Diamond( x:Float, y:Float, w:Float )
				Local x0 := x-w
				Local y0 := y-w
				Local x1 := x+w
				Local y1 := y+w
				
				_.Line( x0, y, x, y0 )
				_.Line( x, y0, x1, y )
				_.Line( x1, y, x, y1 )
				_.Line( x, y1, x0, y )
				_.Point(x0, y)
			End

			Method Square( x:Float, y:Float, w:Float )
				Local x0 := x-w
				Local y0 := y-w
				Local x1 := x+w
				Local y1 := y+w
				
				_.Line( x0, y0, x1, y0 )
				_.Line( x1, y0, x1, y1 )
				_.Line( x1, y1, x0, y1 )
				_.Line( x0, y1, x0, y0 )
				_.Point(x0, y0)
			End
			
			Private 
			
			Field _:TDraw 'parent of TWireframe
		End

		#rem monkeydoc Mini-Library Debug Drawing
		@author iDkP from GaragePixel
		@since 2025-05-25
		@version 2025-05-26
				
		Helpers to program debug drawing operations in mojo.
		
		Note: the TDebug is a singleton created in the TDraw class
		and addressable as a property. You call the property Debug to get 
		access to the debug drawing functions.
				
		canvas.Draw.Debug.Cross( x, y, w )
		
		This debugging library provides specialized drawing operations for
		visualizing geometric structures during development. Methods include
		cross markers, Z patterns, and slash patterns for highlighting points
		and shapes. These functions are optimized for rapid iteration and 
		visual debugging rather than final presentation.
		
		Most methods support generic type parameters for coordinate systems
		and provide overloaded versions for different geometric primitives.
		#end		
		Class TDebug 
		
			#rem monkeydoc Draw a X with lines in a square for debugging purpose
			@author jl (jeanluc as Seyanjin)
			
				│ x,y 	0	0	│
				│ 0 	0 	0	│
				│ 0 	0 	w,w	│
								
			@param x the position x of the square
			@param y the position y of the square
			@param w the size w of the square
			#end 
			Method Cross<T>( x:T, y:T, w:T ) Where T Implements IReal Or T Implements INumeric 'iDkP added: Doc and generic type
		
				Local x0 := x-w
				Local y0 := y-w
				Local x1 := x+w
				Local y1 := y+w
				
				_.Line( x0, y, x1, y )
				_.Line( x, y0, x, y1 )
			End
		
			#rem monkeydoc Draw a X with lines in a Rect for debugging purpose
			@author iDkP for GaragePixel
			@since 2025-05-24
			
				│ x,y 	0	0	│
				│ 0 	0 	0	│
				│ 0 	0 	u,v	│
				
			@param x the position x of the rect
			@param y the position y of the rect
			@param u the absolute position u of a rect
			@param v the absolute position v of a rect
			#end 
			Method Cross<T>( x:T, y:T, u:T, v:T ) Where T Implements IReal Or T Implements INumeric
				
				Local x0 := x
				Local y0 := y
				Local x1 := u
				Local y1 := v
				
				_.Line( x0, y, x1, y )
				_.Line( x, y0, x, y1 )
			End
			
			#rem monkeydoc Draw a X with lines in a quad for debugging purpose
			@author iDkP for GaragePixel
			@since 2025-05-23
			@param p0 the four vertices of a quad
			@param p1 the four vertices of a quad
			@param p2 the four vertices of a quad
			@param p3 the four vertices of a quad
			#end 
			Method Cross<T>( p0:Vec2<T>, p1:Vec2<T>, p2:Vec2<T>, p3:Vec2<T>) Where T Implements IReal Or T Implements INumeric
				
				_.Line(	p0.x,	p0.y,	p2.x,	p2.y)
				_.Line(	p1.x,	p1.y,	p3.x,	p3.y)
			End
		
			#rem monkeydoc Draw a Z with lines in a quad for debugging purpose
			@author iDkP for GaragePixel
			@since 2025-05-23
			@param p0 the four vertices of a quad
			@param p1 the four vertices of a quad
			@param p2 the four vertices of a quad
			@param p3 the four vertices of a quad
			#end
			Method Z<T>( p0:Vec2<T>, p1:Vec2<T>, p2:Vec2<T>, p3:Vec2<T>) Where T Implements IReal Or T Implements INumeric
				
				'TODO: Inspect that
				
				_.Line(	p0.x,	p0.y,	p1.x,	p1.y)
				_.Line(	p1.x,	p1.y,	p2.x,	p2.y)
				_.Line(	p2.x,	p2.y,	p3.x,	p3.y)
			End
		
			#rem monkeydoc Draw a line \ in a quad for debugging purpose
			@author iDkP for GaragePixel
			@since 2025-05-23
			@param p0 the four vertices of a quad
			@param p1 the four vertices of a quad
			@param p2 the four vertices of a quad
			@param p3 the four vertices of a quad
			#end
			Method Slash<T>( p0:Vec2<T>, p1:Vec2<T>, p2:Vec2<T>, p3:Vec2<T>) Where T Implements IReal Or T Implements INumeric
		
				_.Line(	p2.x,	p2.y,	p3.x,	p3.y)
			End
			
			Private 
			
			Field _:TDraw 'parent of TDebug
		End 

		Private 
		
		Property Tool:TTool()
			Return _tool 
		End
		
		Class TTool
			
			'--- TMP
			
			Method LineIntersect( ax1:float, ay1:float, ax2:float, ay2:float, bx1:float, by1:float, bx2:float, by2:float )
				Local dx:double = ax2 - ax1
				Local dy:double = ay2 - ay1
				
				Local m1:double = dy / dx
				' y = mx + c
				' intercept c = y - mx
				Local c1:double = ay1 - m1 * ax1 ' which is same as y2 - slope * x2
				
				dx = bx2 - bx1
				dy = by2 - by1
				
				Local m2:double = dy / dx
				Local c2:double = by2 - m2 * bx2 'which is same as y2 - slope * x2
		
				If m1 - m2 = 0
					_iX = -1
					_iY = -1
		'			Print "No Intersection between the lines"
				Else
					_iX = (c2 - c1) / (m1 - m2)
					_iY = m1 * _iX + c1
		'			Print "intersection:"+ iX+" "+iY
				End
			End

			'line intersection
			Field _iX:Double
			Field _iY:Double
			
			Field _:TDraw 'parent
		
		End

		Private
		
		Field _:Canvas 'parent of TDraw
		
		Field _ttriangle_:TTriangle_=New TTriangle_() 'triangle's dedicaced draw methods
		
		Field _trect_:TRect_=New TRect_() 'rect's dedicaced draw methods
		
		Field _timage_:TImage_=New TImage_() 'image's dedicaced draw methods
		
		Field _ticon:TIcon=New TIcon() 'icon's dedicaced draw methods
		
		Field _ttext_:TText_=New TText_() 'text's dedicaced draw methods
		
		Field _twireframe:TWireframe=New TWireframe() 'frame's dedicaced draw methods
		
		Field _tdebug:TDebug=New TDebug() 'Special tdraw's draw functions for debugging purpose
		
		Field _tool:TTool=New TTool() 'Tools (mostly tmp)
	End 
	
	Private

	Method DrawOutlineLine( x0:Float,y0:Float,x1:Float,y1:Float )
		
'		x0+=.5;y0+=.5;x1+=.5;y1+=.5
		
		Local blendMode:=_outlineMode=OutlineMode.Smooth ? BlendMode.Alpha Else BlendMode.Opaque
		
		Local pmcolor:=_pmcolor
		
		_pmcolor=_outlinepmcolor
		
		If _outlineWidth<=0
			AddDrawOp( _shader,_material,blendMode,2,1 )
			AddPointVertex( x0,y0,0,0 )
			AddPointVertex( x1,y1,1,1 )
			_pmcolor=pmcolor
			Return
		Endif
		
		Local dx:=y0-y1,dy:=x1-x0
		Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_outlineWidth
		dx*=sc;dy*=sc
		
		If _outlineMode=OutlineMode.Solid
			AddDrawOp( _shader,_material,_blendMode,4,1 )
'			AddPointVertex( x0-dx-dy,y0-dy+dx,0,0 )
'			AddPointVertex( x0+dx-dy,y0+dy+dx,0,0 )
'			AddPointVertex( x1+dx+dy,y1+dy-dx,0,0 )
'			AddPointVertex( x1-dx+dy,y1-dy-dx,0,0 )
			AddPointVertex( x0-dx,y0-dy,0,0 )
			AddPointVertex( x0+dx,y0+dy,0,0 )
			AddPointVertex( x1+dx,y1+dy,0,0 )
			AddPointVertex( x1-dx,y1-dy,0,0 )
			_pmcolor=pmcolor
			Return
		End
		
		AddDrawOp( _shader,_material,blendMode,4,2 )

		AddPointVertex( x0,y0,0,0 )
		AddPointVertex( x1,y1,0,0 )
		_pmcolor=0
		AddPointVertex( x1-dx,y1-dy,0,0 )
		AddPointVertex( x0-dx,y0-dy,0,0 )

		AddPointVertex( x0+dx,y0+dy,0,0 )
		AddPointVertex( x1+dx,y1+dy,0,0 )
		_pmcolor=_outlinepmcolor
		AddPointVertex( x1,y1,0,0 )
		AddPointVertex( x0,y0,0,0 )
		
		_pmcolor=pmcolor
	End
	
	Method DrawOutlineLine( v0:Vec2f,v1:Vec2f )
		
		DrawOutlineLine( v0.x,v0.y,v1.x,v1.y )
	End
	
	Method DrawOutline( rect:Rectf )
		
		DrawOutlineLine( rect.min.x,rect.min.y,rect.max.x,rect.min.y )
		DrawOutlineLine( rect.max.x,rect.min.y,rect.max.x,rect.max.y )
		DrawOutlineLine( rect.max.x,rect.max.y,rect.min.x,rect.max.y )
		DrawOutlineLine( rect.min.x,rect.max.y,rect.min.x,rect.min.y )
	End
	
	Public

	Method DrawImage( 'ATTENTION
		'Added by iDkP
		image:ImageWrapperMojo,
		x:Float,y:Float,
		rotation:Float,
		scaleX:Float,scaleY:Float)
'		
		Draw.Image(image.Image,x,y,rotation,scaleX,scaleY)
	End 
	
	'***** INTERNAL *****
	
	#rem monkeydoc @hidden
	#end	
	Property GraphicsDevice:GraphicsDevice()
		
		If _lighting Return Null
		
		Flush()
	
		Return _device
	End

	#rem monkeydoc @hidden
	#end
	Property RenderMatrix:AffineMat3f()
		
		Return _rmatrix
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderBounds:Recti()
		
		Return _rbounds
	End
	
	Private
	
	Enum Dirty
		GBuffer=1
		Viewport=2
		Scissor=4
	End
	
	Class DrawOp
		Field shader:Shader
		Field material:UniformBlock
		Field blendMode:BlendMode
		Field colorMask:ColorMask 'jl added
		Field primOrder:Int
		Field primCount:Int
		Field primOffset:Int
	End
	
	Class LightOp
		Field light:Image
		Field lightPos:Vec2f
		Field primOrder:Int
		Field primOffset:Int
	End
	
	Class ShadowOp
		Field caster:ShadowCaster
		Field firstVert:Int
	End
	
	Global _tmpPixmap1x1:Pixmap
	
	Global _quadIndices:IndexBuffer
	Global _shadowVB:VertexBuffer
	Global _defaultFont:Font

	Global _lighting:Bool=False
	Global _gbuffers:=New Texture[2]
	Global _gbrtargets:=New RenderTarget[2]

	Field _userUniformCallback:Void(canvas:Canvas, uniform:UniformBlock) 'Added by jl
	Field _pmcolor2:UInt=~0 'Added by jl
	Field _color2:Color 'Added by jl
	Field _xyzPosition:Vec3f = new Vec3f() 'Added by jl
	Field _width:Int 'Added by jl
	Field _height:Int 'Added by jl

	Field _rtarget:RenderTarget
	Field _device:GraphicsDevice
	Field _uniforms:UniformBlock
	
	Field _shader:Shader
	Field _material:UniformBlock
	
	Field _viewport:Recti
	Field _scissor:Recti
	Field _ambientLight:Color
	
	Field _retroMode:Bool
	Field _blendMode:BlendMode
	Field _colorMask:ColorMask 'jl added
	Field _font:Font
	Field _alpha:Float
	Field _color:Color
	'Public 'iDkP 2024: Temporary switched to public to allow some Extension
	Field _pmcolor:UInt=~0 
	'Private
	Field _pointSize:Float=1
	Field _lineWidth:Float=1
	Field _lineSmoothing:Bool
	Field _matrix:=New AffineMat3f
	Field _tanvec:Vec2f=New Vec2f( 1,0 )
	Field _matrixStack:=New Stack<AffineMat3f>

	Field _outlineMode:OutlineMode
	Field _outlineColor:Color
	Field _outlinepmcolor:UInt
	Field _outlineSmoothing:Bool
	Field _outlineWidth:Float
	
	Field _rmatrix:=New AffineMat3f
	Field _rbounds:=New Recti( 0,0,$40000000,$40000000 )
	Field _rmatrixStack:=New Stack<AffineMat3f>
	Field _rboundsStack:=New Stack<Recti>
	
	Field _dirty:Dirty
	Field _projMatrix:Mat4f
	Field _rviewport:Recti
	Field _rviewportClip:Vec2i
	Field _rscissor:Recti
	
	Field _vp:Vertex2f Ptr

	Field _drawVB:VertexBuffer
	Field _drawVP0:Vertex2f Ptr
	Field _drawNV:Int
	Field _drawOps:=New Stack<DrawOp>
	Field _drawOp:=New DrawOp

	Field _lightVB:VertexBuffer
	Field _lightVP0:Vertex2f Ptr
	Field _lightNV:Int
	Field _lightOps:=New Stack<LightOp>
	
	Field _shadowOps:=New Stack<ShadowOp>
	Field _shadowVerts:=New Stack<Vec2f>
	
	Const MaxVertices:=65536
	Const MaxShadowVertices:=16384
	Const MaxLights:=1024

	'Used to access to the sublibrary Draw
	Field _tdraw:TDraw=New TDraw() ' Added by iDkP 2025-05-25
	
	'Used to access to the sublibrary Transform
	Field _ttransform:TTransform=New TTransform() ' Added by iDkP 2025-05-29
	
	Function Init2()
		Global inited:=False
		If inited Return
		inited=True
		
		_tmpPixmap1x1=New Pixmap( 1,1,PixelFormat.RGBA8 )

		Local nquads:=MaxVertices/4
		
		_quadIndices=New IndexBuffer( IndexFormat.UINT16,nquads*6 )
		
		Local ip:=Cast<UShort Ptr>( _quadIndices.Lock() )
		
		For Local i:=0 Until nquads*4 Step 4
			ip[0]=i
			ip[1]=i+1
			ip[2]=i+2
			ip[3]=i
			ip[4]=i+2
			ip[5]=i+3
			ip+=6
		Next

		_quadIndices.Invalidate( 0,nquads*6 )
		
		_quadIndices.Unlock()
		
		_shadowVB=New VertexBuffer( Vertex2f.Format,MaxShadowVertices )

		_defaultFont=sdk_mojo.m2.graphics.Font.Load( "font::DejaVuSans.ttf",16 ) 'ATTENTION
	End 
	
	Method Init( rtarget:RenderTarget,device:GraphicsDevice )
		
		LinkSublibs() ' Added by iDkP 2025-05-25
		
		Init2()
		
		_rtarget=rtarget
		_device=device

		_device.RenderTarget=_rtarget
		
		_device.CullMode=CullMode.None
		_device.DepthFunc=DepthFunc.Always
		_device.DepthMask=False
		
		_uniforms=New UniformBlock( 1 )
		_device.BindUniformBlock( _uniforms )

		_drawVB=New VertexBuffer( Vertex2f.Format,MaxVertices )
		_drawVP0=Cast<Vertex2f Ptr>( _drawVB.Lock() )
		_drawNV=0
		
		_lightVB=New VertexBuffer( Vertex2f.Format,MaxLights*4 )
		_lightVP0=Cast<Vertex2f Ptr>( _lightVB.Lock() )
		_lightNV=0
		
'		_shadowVB=New VertexBuffer( Vertex2f.Format,65536 )
		
		_device.IndexBuffer=_quadIndices

		_shader=Shader.GetShader( "null" )
		_material=New UniformBlock( 2 )
		
		_viewport=New Recti( 0,0,640,480 )
		_ambientLight=Color.Black
		_blendMode=BlendMode.Alpha
		_colorMask=ColorMask.All 'jl added
		
		_font=_defaultFont
		
		_alpha=1
		_color=Color.White
		_pmcolor=$ffffffff
		
		_outlineMode=OutlineMode.None
		_outlineColor=Color.Yellow
		_outlinepmcolor=$ffffffff
		_outlineWidth=0

		_color2=Color.White 'jl added
		_pmcolor2=$ffffffff 'jl added
		
		_matrix=New AffineMat3f
	End

	#rem monkeydoc hidden 
	@author iDkP from GaragePixel 
	@since 2025-05-25
	@version 2025-05-28
	#end
	Method LinkSublibs()
		
		#rem iDkP's note:
		
		The nested classes' structure:
		
			· canvas
				· _ttransform
				· _tdraw
					· _ttriangle_
					· _trect_
						· _tframe
						· _tpatches
							· _tdebug				
					· _timage_
					· _ticon
					· _ttext_
					· _twireframe
					· _tdebug
		#end
		
		_ttransform._=Self
		
		_tdraw._=Self
		
		_tdraw._tool._=_tdraw 'Tmp mostly
		
		_tdraw._ttriangle_._=_tdraw
		
		_tdraw._trect_._=_tdraw

		_tdraw._trect_._tframe._=_tdraw._trect_
		_tdraw._trect_._tframe.__=_tdraw
		_tdraw._trect_._tframe.___=Self

		_tdraw._trect_._tpatches._=_tdraw._trect_
		_tdraw._trect_._tpatches.__=_tdraw
		_tdraw._trect_._tpatches.___=Self
		
		_tdraw._trect_._tpatches._tdebug._=_tdraw._trect_._tpatches
		_tdraw._trect_._tpatches._tdebug.__=_tdraw._trect_
		_tdraw._trect_._tpatches._tdebug.___=_tdraw
		_tdraw._trect_._tpatches._tdebug.____=Self
		
		_tdraw._timage_._=_tdraw
		
		_tdraw._ticon._=_tdraw

		_tdraw._ttext_._=_tdraw
		
		_tdraw._twireframe._=_tdraw
		
		_tdraw._tdebug._=_tdraw
	End

	'Vertices
	'
	#rem
	Method AddVertex( x:Float,y:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		_vp->position.x=x
		_vp->position.y=y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		_vp+=1
	End
	#end
	
	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		'param color:UInt=0 added by iDkP
	
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		
		_vp->color2 = _pmcolor2 'jl added
		_vp->xyzPosition = _xyzPosition 'jl added
		
		_vp+=1
	End
	
	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,color:UInt=Null )
		If color=Null color=_pmcolor 'iDkP added
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=color
		
		_vp->color2 = _pmcolor2 'jl added
		_vp->xyzPosition = _xyzPosition 'jd added
		
		_vp+=1
	End
	
'	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,color:UInt )
'		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
'		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
'		_vp->texCoord0.x=s0
'		_vp->texCoord0.y=t0
'		_vp->texCoord1.x=_tanvec.x
'		_vp->texCoord1.y=_tanvec.y
'		_vp->color=_pmcolor
'		_vp+=1
'	End


	Method AddVertex( tx:Float,ty:Float, s0:Float,t0:Float,	s1:float,t1:float )
		'jladded
		_vp->position.x = _matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y = _matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x = s0
		_vp->texCoord0.y = t0
		_vp->texCoord1.x = s1
		_vp->texCoord1.y = t1
		_vp->color = _pmcolor
		_vp->color2 = _pmcolor2
		_vp->xyzPosition = _xyzPosition
		_vp+=1
	End
	
	Method AddVertex( tx:Float,ty:Float, s0:Float,t0:Float, color:UInt, xp:Float, yp:Float, zp:Float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=color
		
		_vp->color2 = _pmcolor2 'jl added
		_vp->xyzPosition.x = xp 'jl added
		_vp->xyzPosition.y = yp 'jl added
		_vp->xyzPosition.z = zp 'jl added
		
		_vp+=1
	End

	Method AddPointVertex( tx:Float,ty:Float,s0:Float,t0:Float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x + .5
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y + .5
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->color=_pmcolor
		
		_vp->color2 = _pmcolor2 'jl added
		_vp->xyzPosition = _xyzPosition 'jl added
		
		_vp+=1
	End

	Method AddVertexNormal( tx:Float,ty:Float,s0:Float,t0:Float, color:UInt, xp:Float, yp:Float, zp:Float, nx:Float, ny:Float, nz:Float )		
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s0
		_vp->texCoord1.y=t0
		_vp->color=color
		
		_vp->color2 = _pmcolor2 'jl added
		_vp->xyzPosition.x = xp 'jl added
		_vp->xyzPosition.y = yp 'jl added
		_vp->xyzPosition.z = zp 'jl added
		_vp->Normal.x = nx 'jl added
		_vp->Normal.y = ny 'jl added
		_vp->Normal.z = nz 'jl added
		
		_vp+=1
	End

	Method AddVertexNormal2( tx:Float,ty:Float,s0:Float,t0:Float, s1:float, t1:float, color:UInt, xp:float, yp:float, zp:float, nx:float, ny:float, nz:float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		
		'jl added
		
		_vp->color2 = _pmcolor2
		_vp->xyzPosition.x = xp
		_vp->xyzPosition.y = yp
		_vp->xyzPosition.z = zp
		_vp->Normal.x = nx
		_vp->Normal.y = ny
		_vp->Normal.z = nz
		
		_vp+=1
	End

	'Drawing
	'	
	Method AddDrawOp( shader:Shader,material:UniformBlock,blendMode:BlendMode,primOrder:int,primCount:Int )

		If _drawNV+primCount*primOrder>_drawVB.Length
			Flush()
		Endif
		
		If blendMode=BlendMode.None blendMode=_blendMode
		
		If shader<>_drawOp.shader Or material<>_drawOp.material Or blendMode<>_drawOp.blendMode Or primOrder<>_drawOp.primOrder
		
			'pad quads so primOffset always on a 4 vert boundary
			If primOrder=4 And _drawNV & 3
				_drawNV+=4-(_drawNV&3)
			Endif
			
			_drawOp=New DrawOp
			_drawOp.shader=shader
			_drawOp.material=material
			_drawOp.blendMode=blendMode
			_drawOp.colorMask=_colorMask 'jl added
			_drawOp.primOrder=primOrder
			_drawOp.primCount=primCount
			_drawOp.primOffset=_drawNV
			_drawOps.Push( _drawOp )
		Else
			_drawOp.primCount+=primCount
		Endif
		
		_vp=_drawVP0+_drawNV
		_drawNV+=primCount*primOrder
	End
	
	Method Validate()
	
		If _dirty & Dirty.Viewport

			Local tviewport:=TransformRecti( _viewport,_rmatrix )
			
			_rviewport=tviewport & _rbounds
			
			_rviewportClip=tviewport.Origin-_rviewport.Origin
	
			Local rmatrix:=New Mat4f
			rmatrix.i.x=_rmatrix.i.x
			rmatrix.j.y=_rmatrix.j.y
			rmatrix.t.x=_rviewportClip.x
			rmatrix.t.y=_rviewportClip.y
			
			If _rtarget
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,0,_rviewport.Height,-1,1 ) * rmatrix
			Else
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,_rviewport.Height,0,-1,1 ) * rmatrix
			Endif
			
			_uniforms.SetMat4f( "ModelViewProjectionMatrix",_projMatrix )
			
			_uniforms.SetVec2f( "ViewportOrigin",_rviewport.Origin )
			
			_uniforms.SetVec2f( "ViewportSize",_rviewport.Size )
	
			_uniforms.SetVec2f( "ViewportClip",_rviewportClip )
			
			_device.Viewport=_rviewport
		End

		'jl added this block about uniforms
		If Not UserUniforms.Empty
			For Local useruniform:=Eachin UserUniforms
				useruniform.callback(useruniform, _uniforms)
			Next
		End
		
		If _dirty & Dirty.Scissor

			_rscissor=TransformRecti( _scissor+_viewport.Origin,_rmatrix ) & _rviewport
			
			_device.Scissor=_rscissor
		End
		
		_dirty=Null
	End
	
	Method RenderDrawOps( rpass:Int )
	
		_device.RenderPass=rpass
		
		_device.VertexBuffer=_drawVB
		
		Local rpassMask:=1 Shl rpass
		
		For Local op:=Eachin _drawOps
		
			Local shader:=op.shader
			If Not (shader.RenderPassMask & rpassMask) Continue
		
			_device.Shader=shader
			_device.BlendMode=op.blendMode
			_device.ColorMask=op.colorMask 'jl added
			_device.BindUniformBlock( op.material )

			Select op.primOrder
			Case 4
				_device.RenderIndexed( 3,op.primCount*2,op.primOffset/4*6 )
			Default
				_device.Render( op.primOrder,op.primCount,op.primOffset )
			End

'			_device.Render( op.primOrder,op.primCount,op.primOffset )

		Next
	End
	
	'Shadows
	'
	Method DrawShadows:Int( lightOp:LightOp )
	
		Const EXTRUDE:=1024.0
		
		Local lv:=lightOp.lightPos
		
		Local vp0:=Cast<Vertex2f Ptr>( _shadowVB.Lock() ),n:=0
		
		For Local op:=Eachin _shadowOps
		
			Local vert0:=op.firstVert
			Local nverts:=op.caster.Vertices.Length
			
			Local tv:=_shadowVerts[vert0+nverts-1]
			
			For Local iv:=0 Until nverts
			
				Local pv:=tv
				tv=_shadowVerts[vert0+iv]
				
				Local dv:=tv-pv
				Local nv:=dv.Normal.Normalize()
				Local pd:=-pv.Dot( nv )
				
				Local d:=lv.Dot( nv )+pd
				If d<0 Continue
				
				If n+9>_shadowVB.Length Exit
				Local tp:=vp0+n
				n+=9
			
				Local hv:=(pv+tv)/2
				
				Local pv2:=pv + (pv-lv).Normalize() * EXTRUDE
				Local tv2:=tv + (tv-lv).Normalize() * EXTRUDE
				Local hv2:=hv + (hv-lv).Normalize() * EXTRUDE
				
				tp[0].position=tv;tp[1].position=tv2;tp[2].position=hv2
				tp[3].position=tv;tp[4].position=hv2;tp[5].position=pv
				tp[6].position=hv2;tp[7].position=pv2;tp[8].position=pv
				
			Next
			
		Next
		
		_shadowVB.Invalidate( 0,n )
		
		_shadowVB.Unlock()
		
		Return n
	End
		
	'Lighting
	'
	Method RenderLighting()
	
		_device.BlendMode=BlendMode.Additive
		
		_device.VertexBuffer=_lightVB
		
		For Local op:=Eachin _lightOps
		
			Local n:=DrawShadows( op )
			
			If n
				_device.RenderPass=4
				_device.RenderTarget=_gbrtargets[0]
				_device.BlendMode=BlendMode.Opaque
				_device.ColorMask=ColorMask.Alpha
				_device.VertexBuffer=_shadowVB
				_device.Shader=Shader.GetShader( "shadow" )

				_device.Clear( Color.White )
				_device.Render( 3,n/3,0 )
				
				_device.RenderPass=5
				_device.RenderTarget=_rtarget
				_device.BlendMode=BlendMode.Additive
				_device.ColorMask=ColorMask.All
				_device.VertexBuffer=_lightVB
				
			Else
				_device.RenderPass=4
			Endif
			
			Local light:=op.light
			
			_device.Shader=light.Shader
			_device.BindUniformBlock( light.Material )
			
			_device.Render( 4,1,op.primOffset )
		Next
	End
	
	Public 

	'================================================================================
	'DEPRECATED (BUT NEED TO BE KEEP A WHILE)
	'================================================================================

	#rem monkeydoc The current drawing matrix (Deprecated, use Transform.Matrix).
	All coordinates passed to draw methods are multiplied by this matrix for rendering.
	#end
	Property Matrix:AffineMat3f() 'Deprecated 
	
		Return _matrix
	
	Setter( matrix:AffineMat3f )
	
		_matrix=matrix
		
		_tanvec=_matrix.i.Normalize()
	End

	#rem monkeydoc Pushes the drawing matrix onto the internal matrix stack (Deprecated).
	#end
	Method PushMatrix() 'Deprecated
	
		_matrixStack.Push( _matrix )
	End
	
	#rem monkeydoc Pops the drawing matrix off the internal matrix stack (Deprecated).
	#end
	Method PopMatrix() 'Deprecated
	
		_matrix=_matrixStack.Pop()
	End
	
	#rem monkeydoc Clears the internal matrix stack and sets the drawing matrix to the identitity matrix (Deprecated).
	#end
	Method ClearMatrix() 'Deprecated
	
		_matrixStack.Clear()
		_matrix=New AffineMat3f
	End
	
	#rem monkeydoc Translates the drawing matrix (Deprecated).
	Translates the drawing matrix. This has the effect of translating all drawing coordinates by `tx` and `ty`.
	@param tx X translation.
	@param ty Y translation.
	@param tv X/Y translation.
	#end
	Method Translate( tx:Float,ty:Float ) 'Deprecated
	
		Matrix=Matrix.Translate( tx,ty )
	End
	
	Method Translate( tv:Vec2f )
	
		Matrix=Matrix.Translate( tv )
	End

	#rem monkeydoc Rotates the drawing matrix (Deprecated).
	Rotates the drawing matrix. This has the effect of rotating all drawing coordinates by the angle `rz'.
	@param rz Rotation angle in radians.
	#end
	Method Rotate( rz:Float ) 'Deprecated
	
		Matrix=Matrix.Rotate( rz )
	End

	#rem monkeydoc Scales the drawing matrix (Deprecated).
	Scales the drawing matrix. This has the effect of scaling all drawing coordinates by `sx` and `sy`.
	@param sx X scale factor.
	@param sy Y scale factor.
	@param sv X/Y scale factor.
	#end
	Method Scale( sx:Float,sy:Float ) 'Deprecated
	
		Matrix=Matrix.Scale( sx,sy )
	End
	
	Method Scale( sv:Vec2f ) 'Deprecated
	
		Matrix=Matrix.Scale( sv )
	End	

	#rem monkeydoc Draws a quad (Deprecated).
	Draws a quad in the current [[Color]] using the current [[BlendMode]].
	The quad vertex coordinates are also transform by the current [[Matrix]].
	#end
	Method DrawQuad( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float )
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
		
		If _outlineMode=OutlineMode.None Return
		
		DrawOutlineLine( x0,y0,x1,y1 )
		DrawOutlineLine( x1,y1,x2,y2 )
		DrawOutlineLine( x2,y2,x3,y3 )
		DrawOutlineLine( x3,y3,x0,y0 )
	End

	Method DrawQuad( v0:Vec2f,v1:Vec2f,v2:Vec2f,v3:Vec2f )
		
		DrawQuad( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y,v3.x,v3.y )
	End
'
	#rem monkeydoc Draws a rectangle (Deprecated).
	Draws a rectangle in the current [[Color]] using the current [[BlendMode]].
	The rectangle vertex coordinates are also transform by the current [[Matrix]].
	#end
	Method DrawRect( x:Float,y:Float,w:Float,h:Float )
		
		DrawQuad( x,y,x+w,y,x+w,y+h,x,y+h )
	
		#rem
		Local x0:=x,y0:=y,x1:=x+w,y1:=y+h
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y0,1,0 )
		AddVertex( x1,y1,1,1 )
		AddVertex( x0,y1,0,1 )
		#end
	End
	
	Method DrawRect( rect:Rectf )
		
		DrawRect( rect.X,rect.Y,rect.Width,rect.Height )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image )
		
		Local tc:=srcImage.TexCoords
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
		
		AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
		AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
		AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
		AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )

		If _outlineMode=OutlineMode.None Return
		
		DrawOutline( rect )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image )
		
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image,srcRect:Recti )
		
		Local s0:=Float(srcImage.Rect.min.x+srcRect.min.x)/srcImage.Texture.Width
		Local t0:=Float(srcImage.Rect.min.y+srcRect.min.y)/srcImage.Texture.Height
		Local s1:=Float(srcImage.Rect.min.x+srcRect.max.x)/srcImage.Texture.Width
		Local t1:=Float(srcImage.Rect.min.y+srcRect.max.y)/srcImage.Texture.Height
		
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
		
		AddVertex( rect.min.x,rect.min.y,s0,t0 )
		AddVertex( rect.max.x,rect.min.y,s1,t0 )
		AddVertex( rect.max.x,rect.max.y,s1,t1 )
		AddVertex( rect.min.x,rect.max.y,s0,t1 )

		If _outlineMode=OutlineMode.None Return
		
		DrawOutline( rect )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int )

		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+width,srcY+height ) )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int,srcWidth:Int,srcHeight:Int )

		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+srcWidth,srcY+srcHeight ) )
	End

'	#rem monkeydoc Draws an image (Deprecated).
'	Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].
'	@param tx X coordinate to draw image at.
'	@param ty Y coordinate to draw image at.
'	@param tv X/Y coordinates to draw image at.
'	@param rz Rotation angle, in radians, for drawing.
'	@param sx X axis scale factor for drawing.
'	@param sy Y axis scale factor for drawing.
'	@param sv X/Y scale factor for drawing. 
'	#end	
	Method DrawImage( image:Image,tx:Float,ty:Float ) 'iDkP here, forced overload -> no branch test
	
		Local vs:=image.Vertices
		Local ts:=image.TexCoords
		
		AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
		
		If _lighting And image.ShadowCaster
			AddShadowCaster( image.ShadowCaster,tx,ty )
		Endif
	End

	#rem monkeydoc Draws text (Deprecated).
	Draws text using the current [[Color]], [[BlendMode]] and [[Matrix]].
	@param text The text to draw.
	@param tx X coordinate to draw text at.
	@param ty Y coordinate to draw text at.
	@param handleX X handle for drawing.
	@param handleY Y handle for drawing.
	#end
	Method DrawText( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
	
		If Not text.Length Return
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float,sy:Float
		Local tw:Float,th:Float
		
		Local i0:=0,lastChar:=0
		
		while i0<text.Length
		
			Local i1:=i0+1
			Local page:Image
			
			While i1<text.Length
			
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage
			sx=image.Rect.min.x;sy=image.Rect.min.y
			tw=image.Texture.Width;th=image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				
				Local char:=text[i]

				tx+=_font.GetKerning( lastChar,char )	'add kerning before render
			
				Local g:=_font.GetGlyph( char )
			
				Local s0:=Float(g.rect.min.x+sx)/tw
				Local t0:=Float(g.rect.min.y+sy)/th
				Local s1:=Float(g.rect.max.x+sx)/tw
				Local t1:=Float(g.rect.max.y+sy)/th
				
				Local x0:=Round( tx+g.offset.x )
				Local y0:=Round( ty+g.offset.y )
				Local x1:=x0+g.rect.Width
				Local y1:=y0+g.rect.Height
	
				AddVertex( x0,y0,s0,t0, _pmcolor )
				AddVertex( x1,y0,s1,t0, _pmcolor )
				AddVertex( x1,y1,s1,t1, _pmcolor )
				AddVertex( x0,y1,s0,t1, _pmcolor )
				
				tx+=g.advance							'add advance after render

				lastChar=char
			Next
			
			gpage=page
			
			i0=i1
		Wend
	End

	'================================================================================
	'DEPRECATED (FULLY DEPRECATED)
	'================================================================================

'	#rem monkeydoc Draws a point.
'	Draws a point in the current [[Color]] using the current [[BlendMode]].
'	The point coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
'	@param x Point x coordinate.
'	@param y Point y coordinate.
'	@param v Point coordinates.
'	#end
'	Method DrawPoint( x:Float,y:Float )
'	
'		If _pointSize<=0
'			AddDrawOp( _shader,_material,_blendMode,1,1 )
'			AddPointVertex( x,y,0,0 )
'			Return
'		Endif
'		
'		Local d:=_pointSize/2
'		AddDrawOp( _shader,_material,_blendMode,4,1 )
'		AddVertex( x-d,y-d,0,0 )
'		AddVertex( x+d,y-d,1,0 )
'		AddVertex( x+d,y+d,1,1 )
'		AddVertex( x-d,y+d,0,1 )
'	End
'	
'	Method DrawPoint( v:Vec2f )
'		DrawPoint( v.x,v.y )
'	End
'	
'	#rem monkeydoc Draws a line.
'	Draws a line in the current [[Color]] using the current [[BlendMode]].
'	The line coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
'	@param x0 X coordinate of first endpoint of the line.
'	@param y0 Y coordinate of first endpoint of the line.
'	@param x1 X coordinate of first endpoint of the line.
'	@param y1 Y coordinate of first endpoint of the line.
'	@param v0 First endpoint of the line.
'	@param v1 Second endpoint of the line.
'	#end
'	Method DrawLine( x0:Float,y0:Float,x1:Float,y1:Float )
'
'		If _lineWidth<=0
'			AddDrawOp( _shader,_material,_blendMode,2,1 )
'			AddPointVertex( x0,y0,0,0 )
'			AddPointVertex( x1,y1,1,1 )
'			Return
'		Endif
'		
''		x0+=.5;y0+=.5;x1+=.5;y1+=.5
'		
'		Local dx:=y0-y1,dy:=x1-x0
'		Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_lineWidth
'		dx*=sc;dy*=sc
'		
'		If Not _lineSmoothing
'			AddDrawOp( _shader,_material,_blendMode,4,1 )
'			AddPointVertex( x0-dx,y0-dy,0,0 )
'			AddPointVertex( x0+dx,y0+dy,0,0 )
'			AddPointVertex( x1+dx,y1+dy,0,0 )
'			AddPointVertex( x1-dx,y1-dy,0,0 )
'			Return
'		End
'		
'		Local pmcolor:=_pmcolor
'		
'		AddDrawOp( _shader,_material,_blendMode,4,2 )
'
'		AddPointVertex( x0,y0,0,0 )
'		AddPointVertex( x1,y1,0,0 )
'		_pmcolor=0
'		AddPointVertex( x1-dx,y1-dy,0,0 )
'		AddPointVertex( x0-dx,y0-dy,0,0 )
'
'		AddPointVertex( x0+dx,y0+dy,0,0 )
'		AddPointVertex( x1+dx,y1+dy,0,0 )
'		_pmcolor=pmcolor
'		AddPointVertex( x1,y1,0,0 )
'		AddPointVertex( x0,y0,0,0 )
'	End
'	
'	Method DrawLine( v0:Vec2f,v1:Vec2f )
'		
'		DrawLine( v0.x,v0.y,v1.x,v1.y )
'	End
'	
'	#rem monkeydoc Draws a triangle.
'	Draws a triangle in the current [[Color]] using the current [[BlendMode]].
'	The triangle vertex coordinates are also transform by the current [[Matrix]].
'	#End
'	Method DrawTriangle( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float )
'		
'		AddDrawOp( _shader,_material,_blendMode,3,1 )
'		AddVertex( x0,y0,0,0, _pmcolor )
'		AddVertex( x1,y1,1,0, _pmcolor )
'		AddVertex( x2,y2,1,1, _pmcolor )
'		
'		If _outlineMode=OutlineMode.None Return
'		
'		DrawOutlineLine( x0,y0,x1,y1 )
'		DrawOutlineLine( x1,y1,x2,y2 )
'		DrawOutlineLine( x2,y2,x0,y0 )
'				
'	End
'	
'	Method DrawTriangle( v0:Vec2f,v1:Vec2f,v2:Vec2f )
'		
'		DrawTriangle( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y )
'	End
'	
'	#rem monkeydoc Draws an oval.
'	Draws an oval in the current [[Color]] using the current [[BlendMode]].
'	The oval vertex coordinates are also transform by the current [[Matrix]].
'	@param x Top left x coordinate for the oval.
'	@param y Top left y coordinate for the oval.
'	@param width Width of the oval.
'	@param height Height of the oval.
'	#end
'	Method DrawOval( x:Float,y:Float,width:Float,height:Float )
'	
'		Local xr:=width/2,yr:=height/2
'		
'		Local dx_x:=xr*_matrix.i.x
'		Local dx_y:=xr*_matrix.i.y
'		Local dy_x:=yr*_matrix.j.x
'		Local dy_y:=yr*_matrix.j.y
'		Local dx:=Sqrt( dx_x*dx_x+dx_y*dx_y )
'		Local dy:=Sqrt( dy_x*dy_x+dy_y*dy_y )
'
'		Local n:=Max( Int( dx+dy ),12 ) & ~3
'		
'		Local x0:=x+xr,y0:=y+yr
'		
'		AddDrawOp( _shader,_material,_blendMode,n,1 )
'		
'		For Local i:=0 Until n
'			Local th:=(i+.5)*Pi*2/n
'			Local px:=x0+Cos( th ) * xr
'			Local py:=y0+Sin( th ) * yr
'			AddPointVertex( px,py,0,0 )
'		Next
'		
'		If _outlineMode=OutlineMode.None Return
'		
'		For Local i:=0 until n
'
'			Local th0:=(i+.5)*TwoPi/n
'			Local px0:=x0+Cos( th0 ) * xr
'			Local py0:=y0+Sin( th0 ) * yr
'			
'			Local th1:=(i+1.5)*TwoPi/n
'			Local px1:=x0+Cos( th1 ) * xr
'			Local py1:=y0+Sin( th1 ) * yr
'			
'			DrawOutlineLine( px0,py0,px1,py1 )
'		
'		Next
'		
'	End
'	
'	#rem monkeydoc Draws an ellipse.
'	Draws an ellipse in the current [[Color]] using the current [[BlendMode]].
'	The ellipse is also transformed by the current [[Matrix]].
'	@param x Center x coordinate for the ellipse.
'	@param y Center y coordinate for the ellipse.
'	@param xRadius X axis radius for the ellipse.
'	@param yRadius Y axis radius for the ellipse.
'	#end
'	Method DrawEllipse( x:Float,y:Float,xRadius:Float,yRadius:Float )
'		
'		DrawOval( x-xRadius,y-yRadius,xRadius*2,yRadius*2 )
'	End
'	
'	#rem monkeydoc Draws a circle.
'	Draws a circle in the current [[Color]] using the current [[BlendMode]] and transformed by the current [[Matrix]].
'	@param x Center x coordinate for the circle.
'	@param y Center y coordinate for the circle.
'	@param radius The circle radius.
'	#end
'	Method DrawCircle( x:Float,y:Float,radius:Float )
'		
'		DrawOval( x-radius,y-radius,radius*2,radius*2 )
'	End
'
'	#rem monkeydoc Draws a polygon.
'	Draws a polygon using the current [[Color]], [[BlendMode]] and [[Matrix]].
'	The `vertices` array must be at least 2 elements long
'	@param vertices Array of x/y vertex coordinate pairs.
'	#end
'	Method DrawPoly( vertices:Float[] )
'		
'		Local order:=vertices.Length/2
'		DebugAssert( order>=1,"Invalid polygon" )
'		
'		AddDrawOp( _shader,_material,_blendMode,order,1 )
'		
'		For Local i:=0 Until order*2 Step 2
'			
'			AddVertex( vertices[i],vertices[i+1],0,0 )
'		Next
'
'		If _outlineMode=OutlineMode.None Or order<3 Return
'		
'		For Local i:=0 Until order-1
'			
'			Local k:=i*2
'			DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
'		Next
'		
'		Local kn:=(order-1)*2
'		DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[0],vertices[1] )
'	End
'	
'	#rem monkeydoc Draws a sequence of polygons.
'	Draws a sequence of polygons using the current [[Color]], [[BlendMode]] and [[Matrix]].
'	@param order The type of polygon: 3=triangles, 4=quads, >4=n-gons.
'	@param count The number of polygons.
'	@param vertices Array of x/y vertex coordinate pairs.
'	#end
'	Method DrawPolys( order:Int,count:Int,vertices:Float[] )
'		
'		DebugAssert( order>=1 And count>0 And order*count<=vertices.Length,"Invalid polyon" )
'
'		AddDrawOp( _shader,_material,_blendMode,order,count )
'		
'		For Local i:=0 Until order*count*2 Step 2
'			
'			AddVertex( vertices[i],vertices[i+1],0,0 )
'		Next
'		
'		If _outlineMode=OutlineMode.None Or order<3 Return
'		
'		For Local i:=0 Until count
'			
'			For Local j:=0 Until order-1
'				
'				Local k:=(i*order+j)*2
'				DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
'			Next
'			
'			Local k0:=i*order*2,kn:=(i*order+order-1)*2
'			DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[k0],vertices[k0+1] )
'		Next
'		
'	End
'	
'	#rem monkeydoc Draws a sequence of primtives.
'	Draws a sequence of convex primtives using the current [[Color]], [[BlendMode]] and [[Matrix]].
'	@param order The type of primitive: 1=points, 2=lines, 3=triangles, 4=quads, >4=n-gons.
'	@param count The number of primitives to draw.
'	@param vertices Pointer to the first vertex x,y pair.
'	@param verticesPitch Number of bytes from one vertex x,y pair to the next. Set to 8 for 'tightly packed' vertices.
'	@param texCoords Pointer to the first texCoord s,t pair. This can be null.
'	@param texCoordsPitch Number of bytes from one texCoord s,y to the next. Set to 8 for 'tightly packed' texCoords.
'	@param colors Pointer to the first RGBA uint color value. This can be null.
'	@param colorsPitch Number of bytes from one RGBA color to the next. Set to 4 for 'tightly packed' colors.
'	@param image Source image for rendering. This can be null.
'	@param indices Pointer to sequence of integer indices for indexed drawing. This can by null for non-indexed drawing.
'	#end
'	Method DrawPrimitives( order:Int,count:Int,vertices:Float Ptr,verticesPitch:Int,texCoords:Float Ptr,texCoordsPitch:Int,colors:UInt Ptr,colorsPitch:Int,image:Image,indices:Int Ptr )
'		DebugAssert( order>0 And count>0,"Illegal primitive" )
'
'		If image
'			AddDrawOp( image.Shader,image.Material,image.BlendMode,order,count )
'		Else
'			AddDrawOp( _shader,_material,_blendMode,order,count )
'		Endif
'		
'		Local n:=order*count
'		
'		If indices
'			If texCoords And colors
'				For Local i:=0 Until n
'					Local j:=indices[i]
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
'					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
'					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
'					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
'				Next
'			ElseIf texCoords
'				For Local i:=0 Until n
'					Local j:=indices[i]
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
'					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
'					AddVertex( vp[0],vp[1],tp[0],tp[1] )
'				Next
'			ElseIf colors
'				For Local i:=0 Until n
'					Local j:=indices[i]
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
'					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
'					AddVertex( vp[0],vp[1],0,0,cp[0] )
'				Next
'			Else
'				For Local i:=0 Until n
'					Local j:=indices[i]
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
'					AddVertex( vp[0],vp[1],0,0 )
'				Next
'			End
'		Else
'			If texCoords And colors
'				For Local i:=0 Until n
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
'					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
'					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
'					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
'				Next
'			ElseIf texCoords
'				For Local i:=0 Until n
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
'					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
'					AddVertex( vp[0],vp[1],tp[0],tp[1] )
'				Next
'			ElseIf colors
'				For Local i:=0 Until n
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
'					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
'					AddVertex( vp[0],vp[1],0,0,cp[0] )
'				Next
'			Else
'				For Local i:=0 Until n
'					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
'					AddVertex( vp[0],vp[1],0,0 )
'				Next
'			End
'		End
'	End
'
'#rem -------------------------------------- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	
'	#rem monkeydoc Draws an image.
'	Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].
'	@param tx X coordinate to draw image at.
'	@param ty Y coordinate to draw image at.
'	@param tv X/Y coordinates to draw image at.
'	@param rz Rotation angle, in radians, for drawing.
'	@param sx X axis scale factor for drawing.
'	@param sy Y axis scale factor for drawing.
'	@param sv X/Y scale factor for drawing. 
'	#end	
'	'Method DrawImage( image:Image,tx:Float,ty:Float,shader:Shader ) 'iDkP Note: Forced Overload -> avoids branch test
'	Method DrawImage( image:Image,tx:Float,ty:Float,shader:Shader=null )
'	
'		Local vs:=image.Vertices
'		Local ts:=image.TexCoords
'
'		If shader
'			AddDrawOp( shader, image.Material, image.BlendMode,4,1 )
'		Else
'			AddDrawOp( image.Shader, image.Material, image.BlendMode,4,1 )
'		End
'		
'		AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
'		
'		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
'		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
'		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
'		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
'		
'		If _lighting And image.ShadowCaster
'			AddShadowCaster( image.ShadowCaster,tx,ty )
'		Endif
'	End
'
''	Method DrawImage( image:Image,tx:Float,ty:Float ) 'iDkP added: Unlined overload to avoid the branch test
'	
''		Local vs:=image.Vertices
''		Local ts:=image.TexCoords
'		
''		AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
'		
''		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
''		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
''		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
''		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
'		
''		If _lighting And image.ShadowCaster
''			AddShadowCaster( image.ShadowCaster,tx,ty )
''		Endif
''	End
'	
'	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float, shader:Shader = null )
'		Local matrix:=Matrix
'		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
'		DrawImage( image,0,0,shader )
'		Matrix=matrix
'	End
'
'	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float, shader:Shader = null )
'		Local matrix:=Matrix
'		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
'		DrawImage( image,0,0,shader )
'		Matrix=matrix
'	End
'
'	Method DrawImage( image:Image,tv:Vec2f,shader:Shader = null )
'		DrawImage( image,tv.x,tv.y,shader )
'	End
'	
'	Method DrawImage( image:Image,tv:Vec2f,rz:Float,shader:Shader = null )
'		DrawImage( image,tv.x,tv.y,rz,shader )
'	End
'	
'	Method DrawImage( image:Image,tv:Vec2f,rz:Float,sv:Vec2f,shader:Shader = null )
'		DrawImage( image,tv.x,tv.y,rz,sv.x,sv.y,shader )
'	End
'	
'	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float )
'		Local matrix:=Matrix
'		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
'		DrawImage( image,0,0 )
'		Matrix=matrix
'	End
'
'	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
'		Local matrix:=Matrix
'		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
'		DrawImage( image,0,0 )
'		Matrix=matrix
'	End
'
'	Method DrawImage( image:Image,tv:Vec2f )
'		DrawImage( image,tv.x,tv.y )
'	End
'	
'	Method DrawImage( image:Image,tv:Vec2f,rz:Float )
'		DrawImage( image,tv.x,tv.y,rz )
'	End
'	
'	Method DrawImage( image:Image,tv:Vec2f,rz:Float,sv:Vec2f )
'		DrawImage( image,tv.x,tv.y,rz,sv.x,sv.y )
'	End
''	#end rem
'	
'	#end -------------------------------------- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
''#rem

End
