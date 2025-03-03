
namespace sdk_mojo.m3

'FIXME: Problems with openvr.h on linux...
'
#If __DESKTOP_TARGET__ And __TARGET__<>"linux"

'#Import "<stdlib>"
'#Import "<mojo>"
'#Import "<mojo3d>"

'Using stdlib..
Using sdk_mojo.m2..
Using sdk_mojo.m3..
Using sdk_mojo.m3.openvr..

#Import "openvr/openvr-sdk/openvr"

#Import "openvr/vrrenderer"
#Import "openvr/geomtrans"

#end