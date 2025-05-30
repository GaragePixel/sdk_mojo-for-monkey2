
Namespace sdk_mojo.m2.graphics

#rem monkeydoc The ImageSlice class.
@author jl (jean-luc)
@added by Danilo
@doc Documentation by iDkP from GaragePixel, 2025-05-28
@since 2021-01-13 (commit d3bf2134506c2b9c4e7f254a121b7f34ac879a71)
@version 2025-05-28 (Update documentation and coding style alignement)

SUMMARY:

Imageslice is a rectangular array of pixels that can be drawn by [Canvas.DrawQuadImageSlice] methods.

You can load an image from a file using one of the [[Load]] function.

ImageSlice provides a 3D grid abstraction for a PNG image atlas, 
automatically slicing by X and Y (tile grid) and Z (frames, or "depth" via _frameWidth).

Intended for high-performance 2D/2.5D game rendering: detects active slices, 
computes per-slice texcoords, and supports multi-frame spritesheets.

PURPOSE:

The ImageSlice class provides a way to handle image atlases/spritesheets split 
into rectangular slices, with support for multi-frame and multi-slice
(potentially for 2.5D, 9-slice, or animation grid usage). 
Slices can be queried for activity (transparency check) 
and mapped to texture coordinates.

The whole image is a stack of 2D grids (one for each frame), where each grid is made up of X,Y slices.

    X = slice index within a frame (horizontal tile index)
    Y = slice index within a frame (vertical tile index)
    Z = frame index (animation frame or "depth" layer)
    
FEATURES:

- Supports automatic discovery of frame/slice counts from filename (no config/code change required).
- Detects live/empty slices, allowing for sparse usage or 2.5D tilemaps.
- Texture coordinates precomputed for each slice, making rendering fast and robust.
- Flexible for animation (frame count), grid atlases, and layered images.

NOTE:

In this code, Hezkind is an ad-hoc term, likely coined by the author (jl, Jean-Luc), 
to describe an alternate way of slicing and parsing the PNG filename and layout,
so I'm trying for figure the exact meaning^^ ..... :>
#end
Class ImageSlice

	#rem monkeydoc Load constructor.
	Loads and slices a PNG image from the supplied path.
	Loads and slice a PNG image. Requires valid "_WxHxZf.png" convention:
	Handles both standard and Hezkind formats
	
	@param image PNG file path (requires "_WxHxZf.png" naming)
	#end
	Method New( )
	End

	Method New( image:string )
		ImportPngSlices( image )
	End

	#rem monkeydoc ImagePath
	Loads (or reloads) PNG file and reslices. Requires valid "_WxHxZf.png" convention:
	Handles both standard and Hezkind formats
	
	Returns the file path of the current loaded image.
	@param imagePath New PNG file path
	#end	
	Property ImagePath:string()
		Return _imagePath
	Setter( imagePath:string )
		'Populates all relevant fields (_frames, _sliceX, _sliceY, _sliceCount, etc)
		ImportPngSlices( imagePath )
	End

	#rem monkeydoc Image property
	Returns the backing Image object for this ImageSlice
	#end
	Property Image:Image()
		Return _image
	End

	#rem monkeydoc Width property
	Returns the width (in pixels) of a single slice (tile)
	#end
	Property Width:int()
		Return _sliceX
	End

	#rem monkeydoc Height property
	Returns the height (in pixels) of a single slice (tile)
	#end
	Property Height:int()
		Return _sliceY
	End

	#rem monkeydoc FrameCount property
	Returns the number of animation frames in the image
	Frames are parsed from the filename and validated at load
	#end	
	Property FrameCount:int()
		Return _frames
	End

	#rem monkeydoc SliceXCount property
	Returns the number of horizontal slices (tiles) per frame
	Computed from image and slice width
	#end
	Property SliceXCount:int()
		Return _sliceXCount
	End

	#rem monkeydoc SliceYCount property
	Returns the number of vertical slices (tiles) per frame
	Computed from image and slice height
	#end
	Property SliceYCount:int()
		Return _sliceYCount
	End

	#rem monkeydoc SliceCount property
	Returns the number of slices per frame (the "depth" or Z)
	Useful for multi-state, 2.5D, or layer-based atlases
	#end
	Property SliceCount:int()
		Return _sliceCount
	End

	Field _sliceLive:bool[, ] = New bool[ 12, 42 ]
	Field _sliceTexCoords:Rectf[, ] = New Rectf[ 12, 42 ]

	private

	#rem monkeydoc hidden
	Internal PNG loader and slice parser
	Loads, validates, and parses the PNG file, extracting grid/frame info from the filename ("_WxHxZf.png")
	Builds per-frame and per-slice tables for activity and texcoords
	Handles both standard and Hezkind formats. Populates all relevant fields (_frames, _sliceX, _sliceY, _sliceCount, etc).
	@param filePath Path to PNG image file (must conform to slice naming)
	#end	
	Method ImportPngSlices( filePath:String )
		'
		' Internal loader: validates PNG, parses filename for grid/framing (using "_WxHxZf.png"),
		' loads Image & Pixmap, slices into frames/slices, computes live slices & texcoords.
		'
		' Steps:
		'   - Validates PNG extension and file existence.
		'   - Extracts slice grid info from filename (WxHxZf).
		'   - Loads Image & Pixmap for pixel-level transparency checks.
		'   - Fills _sliceLive table (tracks if each slice has alpha > 0).
		'   - Computes & fills _sliceTexCoords for each slice/frame.
		'   - Handles two slice layout formats (Hezkind and standard).
		'   - Sets fields: _frames, _frameWidth, _sliceX, _sliceY, _sliceCount, etc.
		'
		_imagePath = ""
		If Not filePath Return
		If ExtractExt( filePath ).ToLower() <> ".png" Return
		
		Local fStream:Stream = Stream.Open( filePath, "r" )
		If Not fStream
			Print filePath + " not opened"
			Return
		End
		fStream.Close()
		
		Local file:String = StripDir(filePath)
		If file.Find("_") < 0 Return

'		Print file+" ok"
		
'		Print "png ok"
		Local Split:String[] = file.Split("_")
		Local SplitL:String = Split[Split.Length - 1]
		If SplitL.Contains("x") And SplitL.Contains(".png")
			_image = Image.Load( filePath )
			If Not _image
				Print "Can't load image"
				Return
			End
			_imagePath = filePath

			Local hezKind:Bool = SplitL.Mid( SplitL.Length-6, 1 ) = "x"

			Local maxX:Int = Int(SplitL.Split("x")[0])
			Local maxY:Int = Int(SplitL.Split("x")[1])

			Local maxZ:Int
			Local mz:String = SplitL.Split("x")[2]
			If hezKind
				maxZ = Int( mz.Split("x")[0] )
'				Print "hezkind"
			Else
				maxZ = Int( mz.Split("f")[0] )
			End If

'			_frames = int( SplitL.Mid( SplitL.Length-5, 1 ) )
			Local f1:String = SplitL.Mid( SplitL.Length-6, 1 )
			Local f2:String = SplitL.Mid( SplitL.Length-6, 2 )
			_frames = Int( f1 )
			If f2.Right( 1 ) <> "." _frames = int( f2 )
			If _frames = 0 _frames = Int( SplitL.Mid( SplitL.Length-5, 1 ) )

			if _frames < 1 _frames = 1
			If maxZ < 1 maxZ = 1
'			Print "contains  maxx="+maxX+" maxy="+maxY+" maxz(height)="+maxZ+" frames="+_frames
			
			_frameWidth = _image.Width / _frames
'			Print "image width="+_image.Width+" height="+_image.Height+" frameWidth="+_frameWidth

			Local pixImage:Pixmap = Pixmap.Load( filePath )
			If Not pixImage
				Print "Can't load pixmap"
				Return
			End
			
			_sliceX = maxX
			_sliceXCount = _frameWidth / maxX
			_sliceY = maxY
			_sliceYCount = _image.Height / maxY
			_sliceCount = maxZ -1

			Local x:Int
			Local y:Int
			Local xp:Int
			Local yp:Int
			Local slice:Int
			Local col:Color
			Local sx:Int
			Local sy:Int
			Local frame:Int
			Local frameX:Int
			
			Local liveSlice:Bool
			
			If hezKind

				For frame = 0 To _frames -1
					For slice = 0 until maxZ

						liveSlice = False

						For y = 0 Until maxY
							For x = 0 until maxX
								col = pixImage.GetPixel( xp+x, yp+y )
	'							Print col.r+" "+col.g+" "+col.b+" "+col.a
								If col.a > 0
									If col.a > 0
										liveSlice = True
									End
								End
							Next
						Next

						_sliceLive[frame, slice] = liveSlice
'						If liveSlice Then
'							Print "slice "+slice+" live"
'						Else
'							Print "slice "+slice+" -"
'						End If

						xp += maxX
						If xp >= pixImage.Width
							xp = 0
							yp += maxY
						End
					Next
				Next
			Else
				frameX = 0
				For frame = 0 To _frames -1
				
					sx = 0
					sy = 0
				
					For slice = 0 until maxZ
						yp = sy

						liveSlice = False

						For y = 0 Until maxY
							xp = sx
							For x = 0 until maxX
								If xp + frameX < pixImage.Width And yp < pixImage.Height
									col = pixImage.GetPixel( xp + frameX, yp )
		'							Print col.r+" "+col.g+" "+col.b+" "+col.a
									If col.a > 0
										liveSlice = True
									End
								End
								xp += 1
							Next
							yp += 1
						Next
						
						_sliceLive[frame, slice] = liveSlice
'						If liveSlice Then
'							Print "slice "+slice+" live"
'						Else
'							Print "slice "+slice+" -"
'						End If

						_sliceTexCoords[frame, slice] = Image.TexCoords
						Local frameWidth:Double = (_sliceTexCoords[frame, slice].max.x - _sliceTexCoords[frame, slice].min.x) / FrameCount
						Local wd:Double = frameWidth / SliceXCount
						Local ht:Double = 1.0 / SliceYCount
				
						_sliceTexCoords[frame, slice].min.x = _sliceTexCoords[frame, slice].min.x + ((slice Mod SliceXCount) * wd) + (frameWidth * frame)
						_sliceTexCoords[frame, slice].max.x = _sliceTexCoords[frame, slice].min.x + wd
				
						_sliceTexCoords[frame, slice].min.y = _sliceTexCoords[frame, slice].min.y + (Int(slice / SliceXCount) * ht)
						_sliceTexCoords[frame, slice].max.y = _sliceTexCoords[frame, slice].min.y + ht
				
						_sliceTexCoords[frame, slice].min.x += 0.0001
						_sliceTexCoords[frame, slice].max.x -= 0.0001
						_sliceTexCoords[frame, slice].min.y += 0.0001
						_sliceTexCoords[frame, slice].max.y -= 0.0001
						
						sx += maxX
						If sx >= _frameWidth
							sx = 0
							sy += maxY
						End
					Next
					
					frameX += _frameWidth
				Next
			End

			pixImage.Discard()
		End
	End

	Field _frames:Int
	Field _frameWidth:Int
	
	Field _sliceX:Int
	Field _sliceXCount:Int
	Field _sliceY:Int
	Field _sliceYCount:Int
	Field _sliceCount:Int

	Field _image:Image
	Field _imagePath:String
End
