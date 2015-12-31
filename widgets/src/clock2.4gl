
&ifdef genero13x
-- nothing
&else
IMPORT util
&endif

{ CVS Header
$Author: $
$Date: 2008-10-14 12:42:28 +0100 (Tue, 14 Oct 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/clock2.4gl,v $
$Log: clock2.4gl,v $
Revision 1.9  2008/04/04 10:05:14  test4j

Added form dump to xml

Revision 1.8  2007/07/12 16:43:03  test4j
*** empty log message ***

Revision 1.7  2006/09/01 10:55:11  test4j

Change clock2 so it uses util.math for sin/cos instead of using Informix DB.

Revision 1.6  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.3  2005/05/10 14:48:12  test4j

Added cvs header.

}

GLOBALS
	DEFINE aniyn SMALLINT
END GLOBALS

	DEFINE tim CHAR(8)
	DEFINE dsp CHAR(2)
	DEFINE scrw,w SMALLINT
	DEFINE x,y SMALLINT
	DEFINE r,a SMALLINT
	DEFINE pi DECIMAL(12,11)
	DEFINE d DECIMAL(12,5)
	DEFINE h,m,s SMALLINT
	DEFINE ret INTEGER

--------------------------------------------------------------------------------
-- Draw a clock using Canvas
FUNCTION clock2()

-- THIS CAN BE ANY DATABASE. ITS ONLY NEEDED BECAUSE OF THE COS & SIN FUNCTIONS
-- Not Needed for version 2
&ifdef genero13x
	DATABASE call_log
&endif

	CALL drawselect("canv")
	CALL drawlinewidth(2)

	IF aniyn THEN 
		CALL clock_face()
		RETURN
	END IF

-- format is x,y,h,w ( NOTE x,y is from bottom left of canvas area )

	CALL cls()
	DISPLAY "Y" TO chk1
--	CALL ui.interface.refresh()

-- DRAW A PALE BLUE RECTANGLE
	CALL drawfillcolor("#C6DEF4")
	CALL drawrectangle (51,1,900,1000) RETURNING ret
	DISPLAY "Y" TO chk2
--	CALL ui.interface.refresh()
--	DRAW AN OVAL
	CALL drawfillcolor("#093B73")
	CALL drawoval(51,1,900,1000) RETURNING ret
	DISPLAY "Y" TO chk3
--	CALL ui.interface.refresh()

	CALL time(1)

END FUNCTION
--------------------------------------------------------------------------------
-- Reset the clock face and display to checkboxes
FUNCTION cls()
	DEFINE c, s om.DomNode
	DEFINE win ui.Window

	LET aniyn = FALSE

	DISPLAY "N" TO chk1
	DISPLAY "N" TO chk2
	DISPLAY "N" TO chk3
	DISPLAY "N" TO chk4
	DISPLAY "N" TO chk5
	DISPLAY "N" TO chk6

	LET win = ui.Window.getCurrent()
	LET c = win.findnode("Canvas","canv")
	IF c IS NOT NULL THEN 
		LET s=c.getFirstChild()
		WHILE s IS NOT NULL
			CALL c.removeChild(s)
			LET s=c.getFirstChild()
		END WHILE
	END IF

	CALL drawfillcolor("black")
	CALL drawrectangle (1,1,1000,1000) RETURNING ret

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION time(seconds)

	DEFINE seconds INTEGER
	DEFINE loop SMALLINT
	DEFINE t CHAR(1)

	LET pi = 3.14159265358
	LET scrw = 33

	CALL drawanchor("n")
	CALL drawlinewidth(2)

	-- DRAW A SMALLER YELLOW CIRCLE
	CALL drawfillcolor("#CFB57D")
	CALL drawcircle(941,61,880) RETURNING w
	DISPLAY "Y" TO chk4
--	CALL ui.interface.refresh()

	-- WRITE THE NUMBER AROUND THE CLOCK FACE
	LET r = 400
	LET h = 0
	FOR a = 30 TO 360 STEP 30
		LET h = h + 1
		LET d = ( pi / 180 ) * a
		LET y = r * ( sin(d) )
		LET x = r * ( cos(d) )
		LET dsp = h
		CALL drawfillcolor("black")
		CALL drawtext(520+x,500+y, dsp ) RETURNING w
	END FOR
	DISPLAY "Y" TO chk5
--	SLEEP 1
--	CALL ui.interface.refresh()
	-- DRAW INNER WHITE CIRCLE
	CALL drawfillcolor("#F5F8E4")
	CALL drawcircle(851,151,700) RETURNING w

	-- LOOP FOR seconds DRAWING THE CENTRAL WRITE FACE AND HANDS
	LET seconds = 1 -- Stopped the loop
	FOR loop = 1 TO seconds
		CALL clock_face()
		DISPLAY "Y" TO chk6
		CALL ui.interface.refresh()
--		SLEEP 1
	END FOR
	LET aniyn = TRUE

END FUNCTION
--------------------------------------------------------------------------------
-- Draw the clock face
FUNCTION clock_face()
  DEFINE c, n om.DomNode
  DEFINE win ui.Window
	DEFINE ll om.NodeList
	DEFINE x SMALLINT

	LET tim = TIME

	LET aniyn = TRUE

-- Remove Hands
  LET win = ui.Window.getCurrent()
  LET c = win.findnode("Canvas","canv")
	LET ll = c.selectByPath("//CanvasLine")
  FOR x = 1 TO ll.getLength()
    LET n = ll.item(x)
		CALL c.removeChild(n)
	END FOR

	LET h = tim[1,2]
	LET m = tim[4,5]
	LET s = tim[7,8]

	-- CALCULATE THE XY OF HOUR HAND AND DRAW IT
	LET r = 300
	LET a = (360 / 12 ) * h
	LET a = a + (( 30 / 60 ) * m )
	LET d = ( pi / 180 ) * a
	LET y = r * ( sin(d) )
	LET x = r * ( cos(d) )
	CALL drawlinewidth(4)
	CALL drawfillcolor("red")
	CALL drawline(501,501,x,y) RETURNING w

	-- CALCULATE THE XY OF MINUTE HAND AND DRAW IT
	LET r = 350
	LET a = (360 / 60 ) * m
	LET d = ( pi / 180 ) * a
	LET y = r * ( sin(d) )
	LET x = r * ( cos(d) )
	CALL drawfillcolor("blue")
	CALL drawlinewidth(2)
	CALL drawline(501,501,x,y) RETURNING w
	
	-- CALCULATE THE XY OF SECOND HAND AND DRAW IT
	LET r = 350
	LET a = (360 / 60 ) * s
	LET d = ( pi / 180 ) * a
	LET y = r * ( sin(d) )
	LET x = r * ( cos(d) )
	CALL drawlinewidth(1)
	CALL drawfillcolor("black")
	CALL drawline(501,501,x,y) RETURNING w

END FUNCTION
--------------------------------------------------------------------------------
-- Asking database engine to provide the SIN
FUNCTION sin( a )
	DEFINE a DECIMAL(12,9)
	DEFINE s DECIMAL(12,6)

&ifdef genero13x
	SELECT SIN( a ) INTO s FROM systables WHERE tabid = 1
&else
	LET s = util.math.sin( a )
&endif

	RETURN s

END FUNCTION
--------------------------------------------------------------------------------
-- Asking database engine to provide the COS
FUNCTION cos( a )
	DEFINE a DECIMAL(12,9)
	DEFINE c DECIMAL(12,6)

&ifdef genero13x
	SELECT COS( a ) INTO c FROM systables WHERE tabid = 1
&else
	LET c = util.math.cos( a )
&endif

	RETURN c

END FUNCTION
