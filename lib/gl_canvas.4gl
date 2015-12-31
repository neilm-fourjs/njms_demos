
--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.00.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

#+ Canvas Specific Library Code (Work in Progress)

--------------------------------------------------------------------------------
#+ Example calls
#+ @code
#+ LET c = gl_canvasInit("Canv1")
#+ LET obj = gl_canvasRec(c, x, y, ex, ey, col, act1, act3)
#+ LET obj = gl_canvasOval(c, x, y, ex, ey, col, act1, act3)
#+ LET obj = gl_canvasArc(c, x, y, d, sa, ea, col, act1, act2 )
#+ LET obj = gl_canvasCircle(c, x, y, d, col, act1, act2 )
#+ LET obj = gl_canvasLine(c, x, y, ex, ey, w, col, act1, act3 )
#+ LET obj = gl_canvasText(c, x, y, ori, txt , col )
--------------------------------------------------------------------------------
&include "genero_lib1.inc"

--------------------------------------------------------------------------------
#+ Initialze the Canvas
#+
#+ @param nam Name of window object.
#+ @return canvas node for the 'nam' in current window - or return null.
FUNCTION gl_canvasInit(nam) --{{{
	DEFINE w ui.Window
	DEFINE c om.domNode
	DEFINE nam STRING
GL_MODULE_ERROR_HANDLER
	LET w = ui.Window.getCurrent()
	IF w IS NULL THEN 
		CALL fgl_winmessage("Error","No current Window !","exclamation")
		RETURN NULL 
	END IF

	LET c = w.findNode("Canvas",nam)
	IF c IS NULL THEN 
		CALL fgl_winmessage("Error","Couldn't find Canvas '"||nam||"' !","exclamation")
	END IF

	RETURN c

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw a rectangle
#+
#+ @param c Node for the canvas object
#+ @param x bottom left = up/down    0 = top / 1000 = bottom
#+ @param y bottom left = left/right 0 = left / 1000 = right
#+ @param ex top right   = up/down    0 = top / 1000 = bottom
#+ @param ey top right   = left/right 0 = left / 1000 = right
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @param act1 Key name ie F1
#+ @param act3 Key name ie F1
#+ @return the node for the object created.
FUNCTION gl_canvasRec(c, x, y, ex, ey, col, act1, act3) --{{{
	DEFINE c, s om.domNode
	DEFINE col, act1, act3 STRING
	DEFINE x, y, ex, ey SMALLINT

	GL_DBGMSG(1, "gl_canvasRec: X:"||x||" Y:"||y||" EX:"||ex||" EY:"||ey||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Rectangle", col, act1, act3)

	CALL s.setAttribute( "endX", ex )
	CALL s.setAttribute( "endY", ey )

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw a Oval
#+
#+ @param c Node for the canvas object
#+ @param x bottom left = up/down    0 = top / 1000 = bottom
#+ @param y bottom left = left/right 0 = left / 1000 = right
#+ @param ex top right   = up/down    0 = top / 1000 = bottom
#+ @param ey top right   = left/right 0 = left / 1000 = right
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @param act1 Key name ie F1
#+ @param act3 Key name ie F1
#+ @return the node for the object created.
FUNCTION gl_canvasOval(c, x, y, ex, ey, col, act1, act3) --{{{
	DEFINE c, s om.domNode
	DEFINE col, act1, act3 STRING
	DEFINE x, y, ex, ey SMALLINT

	GL_DBGMSG(1, "gl_canvasOval: X:"||x||" Y:"||y||" EX:"||ex||" EY:"||ey||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Oval", col, act1, act3)

	CALL s.setAttribute( "endX", ex )
	CALL s.setAttribute( "endY", ey )

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw a line
#+
#+ @param c Node for the canvas object
#+ @param x start point = up/down    0 = top / 1000 = bottom
#+ @param y start point = left/right 0 = left / 1000 = right
#+ @param ex end point   = up/down    0 = top / 1000 = bottom
#+ @param ey end point   = left/right 0 = left / 1000 = right
#+ @param w width
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @param act1 Key name ie F1
#+ @param act3 Key name ie F1
#+ @return the node for the object created.
FUNCTION gl_canvasLine(c, x, y, ex, ey, w, col, act1, act3 ) --{{{
	DEFINE c, s om.domNode
	DEFINE col, act1, act3 STRING
	DEFINE x, y, ex, ey, w SMALLINT

	GL_DBGMSG(1, "gl_canvasLine: X:"||x||" Y:"||y||" W:"||w||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Line", col, act1, act3)

	CALL s.setAttribute( "endX", ex )
	CALL s.setAttribute( "endY", ey )
	CALL s.setAttribute( "width", w )

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw text
#+
#+ @param c Node for the canvas object
#+ @param x start point = up/down    0 = top / 1000 = bottom
#+ @param y start point = left/right 0 = left / 1000 = right
#+ @param ori "n","e","w","s"
#+ @param txt STRING 
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @return the node for the object created.
FUNCTION gl_canvasText(c, x, y, ori, txt , col ) --{{{
	DEFINE c, s om.domNode
	DEFINE x,y SMALLINT
	DEFINE ori CHAR(1)
	DEFINE txt,col STRING

	IF ori IS NULL THEN LET ori = "w" END IF

	GL_DBGMSG(1, "gl_canvasText: X:"||x||" Y:"||y||" O:"||ori||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Text", col, NULL, NULL)

	CALL s.setAttribute( "anchor", ori )
	CALL s.setAttribute( "text", txt)

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw Arc
#+
#+ @param c Node for the canvas object
#+ @param x center point = up/down    0 = top / 1000 = bottom
#+ @param y center point = left/right 0 = left / 1000 = right
#+ @param d Diameter
#+ @param sa Start Angle
#+ @param ea End Angle
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @param act1 Key name ie F1
#+ @param act3 Key name ie F1
#+ @return the node for the object created.
FUNCTION gl_canvasArc(c, x, y, d, sa, ea, col, act1, act2 ) --{{{
	DEFINE c, s om.domNode
	DEFINE x,y,d,sa,ea SMALLINT
	DEFINE col,act1,act2 STRING

	GL_DBGMSG(1, "gl_canvasArc: X:"||x||" Y:"||y||" D:"||d||" SA:"||sa||" EA:"||ea||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Arc", col, act1, act2)

	CALL s.setAttribute( "diameter", d)
	CALL s.setAttribute( "startDegrees", sa)
	CALL s.setAttribute( "extentDegrees", ea)

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Draw Circle
#+ 
#+ @param c Node for the canvas object
#+ @param x top left point = up/down    0 = top / 1000 = bottom
#+ @param y top left point = left/right 0 = left / 1000 = right
#+ @param d Diameter
#+ @param col Colour = name (blue, red etc ) or Hex value ( #ffffff )
#+ @param act1 Key name ie F1
#+ @param act3 Key name ie F1
#+ @return the node for the object created.
FUNCTION gl_canvasCircle(c, x, y, d, col, act1, act2 ) --{{{
	DEFINE c, s om.domNode
	DEFINE x,y,d SMALLINT
	DEFINE col,act1,act2 STRING

	GL_DBGMSG(1, "gl_canvasArc: X:"||x||" Y:"||y||" D:"||d||" Col:"||col)

	LET s = gl_canvasObj(c, x, y, "Circle", col, act1, act2)

	CALL s.setAttribute( "diameter", d)

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Generic function for creating the object and setting basic params
FUNCTION gl_canvasObj(c, x, y, wid, col, act1, act3) --{{{
	DEFINE c, s om.domNode
	DEFINE x,y SMALLINT
	DEFINE wid, col, act1, act3 STRING

	LET s = c.createChild("Canvas"||wid)

	CALL s.setAttribute( "startX", x )
	CALL s.setAttribute( "startY", y )

	IF col IS NOT NULL THEN
		CALL s.setAttribute( "fillColor", col )
	END IF
	IF act1 IS NOT NULL THEN
		CALL s.setAttribute( "acceleratorKey1", act1 )
	END IF
	IF act3 IS NOT NULL THEN
		CALL s.setAttribute( "acceleratorKey3", act3 )
	END IF

	RETURN s

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ gl_rgbToHex: Generate a Hex Colour String from r,g,b SMALLINTs
#+
#+ @param r Values from 0 to 255 eg 255,255,255 = white
#+ @param g Values from 0 to 255 eg 255,255,255 = white
#+ @param b Values from 0 to 255 eg 255,255,255 = white
#+ @return "#FFFFFF" eg 255,255,255 = white
FUNCTION gl_rgbToHex(r,g,b) --{{{
	DEFINE r,g,b SMALLINT
	DEFINE hex CHAR(7)

	LET hex[1] = "#"
	LET hex[2,3] = gl_intToHex(r)
	LET hex[4,5] = gl_intToHex(g)
	LET hex[6,7] = gl_intToHex(b)

	RETURN hex

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Generate a CHAR(2) Hex Value from a SMALLINT
#+
#+ @param i Values from 0 to 255 eg 16 = a
#+ @return CHAR(2) : eg "0a"
--------------------------------------------------------------------------------
FUNCTION gl_intToHex(i) --{{{
	DEFINE i,a1,a2 SMALLINT
	DEFINE hex CHAR(2)

	LET hex = "00"

	IF i > 15 THEN
		LET a1 = i / 16	
		CASE a1
			WHEN 10 LET hex[1] = "a"
			WHEN 11 LET hex[1] = "b"
			WHEN 12 LET hex[1] = "c"
			WHEN 13 LET hex[1] = "d"
			WHEN 14 LET hex[1] = "e"
			WHEN 15 LET hex[1] = "f"
			OTHERWISE LET hex[1] = a1
		END CASE
		LET a2 = i - ( a1 * 16 )
	ELSE
		LET a2 = i
	END IF
	CASE a2
		WHEN 10 LET hex[2] = "a"
		WHEN 11 LET hex[2] = "b"
		WHEN 12 LET hex[2] = "c"
		WHEN 13 LET hex[2] = "d"
		WHEN 14 LET hex[2] = "e"
		WHEN 15 LET hex[2] = "f"
		OTHERWISE LET hex[2] = a2
	END CASE

	RETURN hex

END FUNCTION --}}}
