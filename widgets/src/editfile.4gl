{ CVS Header
$Author: $
$Date: 2008-07-22 17:56:39 +0100 (Tue, 22 Jul 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/editfile.4gl,v $
$Log: editfile.4gl,v $
Revision 1.5  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.4  2005/05/10 14:48:12  test4j

Added cvs header.

}

--------------------------------------------------------------------------------
-- Program to view a file using a TEXTEDIT widget

DEFINE source STRING
DEFINE filename STRING
DEFINE line STRING
DEFINE ret SMALLINT
DEFINE chl base.channel
DEFINE fnd STRING
DEFINE fnd_lne SMALLINT
DEFINE ro CHAR(2)
MAIN
	DEFINE lne_cnt INTEGER

	CALL ui.interface.loadStyles("mydef.4st")

	LET filename = base.application.getArgument(1)
	LET ro = base.application.getArgument(2)
	LET fnd = base.application.getArgument(3)

	LET chl = base.channel.create()

	WHENEVER ERROR CONTINUE
	CALL chl.openFile( filename,"r")
	IF STATUS != 0 THEN
		DISPLAY "Failed to open '",filename.trim(),"'!!"
		EXIT PROGRAM
	END IF

	WHENEVER ERROR STOP
	LET ret = 1
	LET lne_cnt = 0
	LET fnd_lne = 0
	WHILE ret = 1
		CALL chl.setDelimiter("")
		LET ret = chl.read( line )
		IF ret = 1 THEN
			IF fnd IS NOT NULL AND strstr(line,fnd) THEN
				IF fnd_lne = 0 THEN LET fnd_lne = lne_cnt END IF
			END IF
			LET source = source.append(line||ASCII(10))
			LET lne_cnt = lne_cnt + 1
		END IF
	END WHILE
	CALL chl.close()
	CALL do_form()
	
	MESSAGE fnd," @ line ",fnd_lne

	IF ro[1] = "R" THEN
		DISPLAY BY NAME source
		MENU ""
			COMMAND "Close"
				EXIT MENU
		END MENU
	ELSE
		INPUT BY NAME source WITHOUT DEFAULTS
	END IF

-- Add code to write back file here!

END MAIN
--------------------------------------------------------------------------------
-- Dynamically create a form
FUNCTION do_form()
	DEFINE win ui.Window
	DEFINE winnode, frm, grid, frmf, edit  om.DomNode
	DEFINE x,y SMALLINT
	DEFINE frm_obj ui.Form

	LET x = 100
	LET y = 30

	CURRENT WINDOW IS SCREEN
	LET win = ui.Window.GetCurrent()
	LET winnode = win.getNode()
	CALL winnode.setAttribute("style","dialog")
	CALL winnode.setAttribute("width",x)
	CALL winnode.setAttribute("height",y)
	LET frm_obj = win.CreateForm("EditFile")
--	LET frm = winnode.createChild('Form')
	LET frm = frm_obj.getNode()
	CALL frm.setAttribute("text","File: "||filename.trim())
	CALL winnode.setAttribute("text","File: "||filename.trim())

	LET grid = frm.createChild('Grid')

	LET frmf = grid.createChild('FormField')
	CALL frmf.setAttribute("colName","source")
	CALL frmf.setAttribute("value",source)
	LET edit = frmf.createChild('TextEdit')
	CALL edit.setAttribute("width",x)
	IF ro[2] != "H" THEN
		CALL edit.setAttribute("fontPitch","fixed")
		CALL edit.setAttribute("scrollBars","both")
	ELSE
		CALL edit.setAttribute("scrollBars","vertical")
	END IF
	CALL edit.setAttribute("height",y)
	CALL edit.setAttribute("stretch","both")

END FUNCTION
--------------------------------------------------------------------------------
-- Search for a string within a string
FUNCTION strstr(str,fnd)
	DEFINE str,fnd STRING
	DEFINE x,y SMALLINT
	
	LET y = fnd.getLength() - 1
	FOR x = 1 TO ( str.getLength() - y)
		IF str.substring(x,x+y) = fnd THEN
			RETURN TRUE
		END IF
	END FOR
	RETURN FALSE
END FUNCTION
--------------------------------------------------------------------------------
