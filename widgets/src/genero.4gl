
{ CVS Header
$Author: $
$Date: 2008-07-22 17:56:39 +0100 (Tue, 22 Jul 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/genero.4gl,v $
$Log: genero.4gl,v $
Revision 1.12  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.10  2005/11/16 13:24:30  test4j
*** empty log message ***

Revision 1.9  2005/11/14 15:46:15  test4j

Updated genero_lib1 and removed some things from genero.4gl

Revision 1.8  2005/11/03 15:37:57  test4j

Changed to use splash, about, progbar from genero_lib1 ( from library demo )

Revision 1.7  2005/11/03 14:17:22  test4j

changed splash screen.

Revision 1.6  2005/05/10 14:48:12  test4j

Added cvs header.

}

#include "widgets.inc"

DEFINE mmenu,lev1, lev2, lev3, lev4, lev5 om.DomNode

--------------------------------------------------------------------------------
FUNCTION njm_sm_create(startmenu,fname)
	DEFINE startmenu SMALLINT
	DEFINE fname CHAR(18)
	DEFINE winn,themenu,grp1,grp2,itm1,itm2,grp om.DomNode
	DEFINE key CHAR(1)
	DEFINE win ui.Window

	IF startmenu THEN
		LET winn = ui.Interface.GetRootNode()
		LET mmenu = winn.createChild('StartMenu')
		CALL mmenu.setAttribute('text',"The Menu")
	ELSE
		LET win = ui.Window.GetCurrent()
		LET winn = win.GetNode()
		LET winn = winn.getFirstChild()
		LET mmenu = winn.createChild('TopMenu')
	END IF

--	LET mmenu = themenu.createChild('TopMenuGroup')
--  CALL mmenu.setAttribute('text',"Sys Menu")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION njm_sm_add(startmenu, lev, g_c, desc, exec )
	DEFINE startmenu SMALLINT
	DEFINE lev SMALLINT
	DEFINE g_c CHAR(1)
	DEFINE desc STRING
	DEFINE exec CHAR(80)
	DEFINE itm om.DomNode
	DEFINE child_type CHAR(18)
	DEFINE cmd STRING

	IF exec IS NULL OR exec = " " THEN RETURN END IF
	IF desc IS NULL OR desc = " " THEN RETURN END IF
	IF startmenu THEN
		LET cmd = "exec"
	ELSE
		LET cmd = "name"
	END IF

	IF g_c = "G" THEN 
		IF startmenu THEN
			LET child_type = "StartMenuGroup"
		ELSE
			LET child_type = "TopMenuGroup"
		END IF
	ELSE
		IF startmenu THEN
			LET child_type = "StartMenuCommand"
		ELSE
			LET child_type = "TopMenuCommand"
		END IF
--		DISPLAY "ON ACTION ",exec CLIPPED," LET act = \"",exec CLIPPED,"\""
	END IF

	IF lev = 1 THEN
--		DISPLAY "NJM:1  :",desc CLIPPED
		LET lev1 = mmenu.createChild(child_type CLIPPED)
		CALL lev1.setAttribute('text',desc CLIPPED)
		IF g_c = "C" THEN
			CALL lev1.setAttribute(cmd CLIPPED,exec CLIPPED)
		ELSE
			CALL lev1.setAttribute("image","zoom")
		END IF
		RETURN lev1
	END IF

	IF lev = 2 THEN
--		DISPLAY "NJM: 2 :",desc CLIPPED
		LET lev2 = lev1.createChild(child_type CLIPPED)
	 	CALL lev2.setAttribute('text',desc CLIPPED)
		IF g_c = "C" THEN
			CALL lev2.setAttribute(cmd CLIPPED,exec CLIPPED)
		ELSE
			CALL lev2.setAttribute("image","zoom")
		END IF
		RETURN lev2
	END IF

	IF lev = 3 THEN
--		DISPLAY "NJM: 2 :",desc CLIPPED
		LET lev3 = lev2.createChild(child_type CLIPPED)
	 	CALL lev3.setAttribute('text',desc CLIPPED)
		IF g_c = "C" THEN
			CALL lev3.setAttribute(cmd CLIPPED,exec CLIPPED)
		ELSE
			CALL lev3.setAttribute("image","zoom")
		END IF
		RETURN lev3
	END IF

	IF lev = 4 THEN
--		DISPLAY "NJM: 2 :",desc CLIPPED
		LET lev4 = lev3.createChild(child_type CLIPPED)
	 	CALL lev4.setAttribute('text',desc CLIPPED)
		IF g_c = "C" THEN
			CALL lev4.setAttribute(cmd CLIPPED,exec CLIPPED)
		ELSE
			CALL lev4.setAttribute("image","zoom")
		END IF
		RETURN lev4
	END IF

	IF lev = 5 THEN
		LET lev5 = lev4.createChild(child_type CLIPPED)
	 	CALL lev5.setAttribute('text',desc CLIPPED)
		IF g_c = "C" THEN
			CALL lev5.setAttribute(cmd CLIPPED,exec CLIPPED)
		ELSE
			CALL lev5.setAttribute("image","zoom")
		END IF
		RETURN lev5
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION njm_sm_end(startmenu)
	DEFINE startmenu SMALLINT
	DEFINE itm om.DomNode

	IF startmenu THEN
		LET lev1 = mmenu.createChild('StartMenuGroup')
		CALL lev1.setAttribute('text',"Help")
		LET itm = lev1.createChild('StartMenuCommand')
		CALL itm.setAttribute('text',"About")
		CALL itm.setAttribute('name',"about")
		CALL itm.setAttribute('exec',"fglrun -V")
	ELSE
		LET lev1 = mmenu.createChild('TopMenuGroup')
		CALL lev1.setAttribute('text',"Help")
		LET itm = lev1.createChild('TopMenuCommand')
		CALL itm.setAttribute('text',"About")
		CALL itm.setAttribute('name',"about")
	END IF

END FUNCTION
--------------------------------------------------------------------------------
-- Center a some text
FUNCTION centerit(tmp,len)
	DEFINE tmp CHAR(132)
	DEFINE newtmp CHAR(132)
	DEFINE len,x,tmplen SMALLINT

	LET tmplen = LENGTH(tmp)
	LET x = ( len / 2 ) - ( tmplen / 2 )
	LET newtmp[x,len] = tmp CLIPPED

	RETURN newtmp

END FUNCTION
--------------------------------------------------------------------------------
-- Change Active/InActive fields to style 'live'/'dead'
FUNCTION chg_flds()
	DEFINE win ui.Window
	DEFINE frm ui.Form
	DEFINE nl om.NodeList
	DEFINE frm_n, n om.DomNode
	DEFINE x SMALLINT
	DEFINE nam STRING

	LET win = ui.Window.GetCurrent()
	LET frm = win.getForm()
	LET frm_n = frm.getNode()

	LET nl = frm_n.selectByPath("//FormField")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		LET nam = n.getAttribute("colName")
		DISPLAY nam,"=",n.getAttribute("active"),"(",n.getAttribute("dialogType"),")"
		IF n.getAttribute("active") THEN
			CALL frm.setFieldStyle(nam,"live")
		ELSE
			CALL frm.setFieldStyle(nam,"dead")
		END IF
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
