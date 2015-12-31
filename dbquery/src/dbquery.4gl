
--------------------------------------------------------------------------------
-- GeneroDB - by Neil J Martin ( neilm@4js.com )
-- This is intended as an example of general database enquiry tool.
-- Genero 1.33 & 2.00.
--
-- No warrantee of any kind, express or implied, is included with this software;
-- use at your own risk, responsibility for damages (if any) to anyone resulting
-- from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

{ CVS Header
$Author: test4j $
$Date: 2008/04/17 17:29:43 $
$Revision: 318 $
$Source: /usr/home/test4j/cvs/all/demos/dbquery/src/dbquery.4gl,v $
$Log: dbquery.4gl,v $
Revision 1.66  2008/04/17 17:29:43  test4j
*** empty log message ***

Revision 1.65  2008/01/22 16:14:08  test4j

Updated for dbdrivers ie Genero 2.0>

Revision 1.64  2007/12/24 11:01:39  test4j
*** empty log message ***

Revision 1.63  2007/07/13 11:15:08  test4j
*** empty log message ***

Revision 1.62  2007/07/12 16:42:43  test4j

Changes for built in precompiler

Revision 1.61  2006/09/29 12:14:14  test4j
*** empty log message ***

Revision 1.60  2006/07/21 11:34:25  test4j

restructures make

Revision 1.59  2006/06/23 10:24:54  test4j

gl_about added gl_verFmt to call.

Revision 1.58  2006/05/10 15:53:58  test4j
*** empty log message ***

Revision 1.57  2006/03/13 16:11:26  test4j
*** empty log message ***

Revision 1.56  2006/03/13 14:40:21  test4j

cvs tags

Revision 1.55  2006/03/13 14:18:32  test4j

cvs tabs

Revision 1.54  2006/03/09 16:36:27  test4j

library code updated

Revision 1.53  2006/03/03 17:14:40  test4j

updated library code and changed debug to genero_lib debug.

Revision 1.52  2005/11/17 18:12:15  test4j
*** empty log message ***

Revision 1.51  2005/11/14 17:16:03  test4j

remove help() from lib.4gl

Revision 1.50  2005/11/14 17:08:23  test4j

remove functions from lib.4gl that are in genero_lib1.4gl and changed other
files to call the standard library code.

Revision 1.49  2005/11/14 16:55:30  test4j

Changed to use standard library code.

Revision 1.48  2005/11/09 11:28:45  test4j

added dbquerydemo_icon as icon using setImage

Revision 1.47  2005/11/04 11:45:34  test4j

Changed so easier to build on Windows.

Revision 1.46  2005/10/04 17:02:01  test4j

Added driver, so can load odi driver at runtime.

Revision 1.45  2005/08/05 15:59:36  test4j

new build

Revision 1.45  2005/08/05 16:01:17  test4j

New release and tidied some bits.

Revision 1.44  2005/08/05 12:39:30  test4j

Fixed field size bug, and added colname/type tooltips.

Revision 1.43  2005/07/27 17:48:04  test4j

fixed bug when table has 24 columns.

Revision 1.42  2005/06/29 08:15:11  test4j

Fixed syntax on frontcall

Revision 1.41  2005/06/28 11:31:27  test4j

1.32 change

Revision 1.40  2005/06/28 11:29:20  test4j

V4=1.32 Genero

Revision 1.39  2005/05/17 11:44:14  test4j
*** empty log message ***

Revision 1.38  2005/05/10 14:42:35  test4j

CVS header added.

}
-- <README>
-- Usage:
-- 	If command line args are used then dbquery doesn't prompt for 
--	database details
--
-- Command Line args: 
--	-db <database name>
--	-tn <table name>
--	-nosplash	-	No splash screen on load.
--	-sqlfe		- This only launches the SQL Front End
--							If no database specified then it prompts as normal
-- 
-- Enviroment Variable - used as default values for database window only.
-- DBQ_DBNAME		- Database name
-- DBQ_DBSOURCE	- Database source
-- DBQ_DBHOST		- Host ip/name for database
-- DBQ_DBUSER		- User name for connection
-- DBQ_DBPASS		- Password for connection
-- DBQ_TABNAME	- Table name to start with selected
--
-- ******************************************************************
-- Building instructions ( NOTE: Some Makefile options will fail Windows )
-- 	make clean	- remove built objects
-- 	make 				- builds dbquery.42r & README
-- 	make tgz		- builds dbquery.42r & README & makes a tgz distro
--  To enable g_dbgLev outuput:
--		export DBQUERYDB=1
--		make clean
--		make
-- ******************************************************************
-- Version 1.0 - 20th Jan 2003
--		. If not passed a databse then it gives a combo of all .sch in
--			the first directory in DBPATH and all .sch in current directory.
--		. Can display large tables using a multitab form.
--		. Option to show the schema for the current table.
--		. Can display the first 6 fields on the current table in a list view.
--		. Can generate an XML form of the current screen.
--		. Can dump the entire XML tree to a file.
--
-- Version 2.0 - 14th Apr 2004
--		. Internal change so program works from an XML schema of the db.
--		. Can now user Environment variable as well as command line args.
--		. Changed layout of main screen to include table list.
--		. Option now to show the schema for ANY table.
--		. Provides a front end to SQL entry.
--				This includes the ability to do SELECT * FROM tabname to populate
--				a screen TABLE. 
--		. Handles connection strings to databases.
--		. Can now change database from within dbquery.
--		. Can print the first 6 fields on the current table to a report.
--		. Can print the first 6 fields on the current table to PrintClient.
-- Version 2.1 - 2nd Dec 2004
--		. Added splash screen, help & about windows.
--
-- TODO: Ablity to add/drop/modify tables. ( STARTED 1/10/04 )
-- ******************************************************************
--
-- This program using the following Genero features:-
--		DYNAMIC ARRAYS
--		CONSTANT
--		STRING
--		PRINTX
--		StringTokenizer
--		base.Application.getArgumentCount
--		base.Application.getArgument
--		ui.ComboBox
--		om.DomNode
--		Preprocessor
--			#define - see dbquery.inc
--			#include
--			#ifdef
--
-- All forms, dialogs, toolbars, topmenus and styles are generated dynamically.
--
--	Limitations of dynamic screens & listview:-
--	No columns beyond first 100(hard coded) are populated.
--	Only first 150(constant) chars of a char column are read/displayed.
--	List view only shows/prints 6(hard coded) fields.
--
-- The constants can be changed to increase some limits. see dbquery.inc
-- </README>

GLOBALS
CONSTANT p_version = "$Revision: 318 $"
END GLOBALS

&include "dbquery.inc"
&include "version.inc"
&include "../lib/genero_lib1.inc"

DEFINE sel_cols ARRAY[6] OF SMALLINT
DEFINE where_clause CHAR(200)
DEFINE win_title STRING

DEFINE sel_tabno SMALLINT

DEFINE notb SMALLINT

DEFINE rec RECORD 
	DBQ_REC -- See dbquery.inc
END RECORD
		
DEFINE cur_open SMALLINT
DEFINE sqlfe_only SMALLINT

DEFINE no_of_cols SMALLINT

DEFINE root om.domNode
DEFINE main_win, main_frm, main_hbox, main_vbox om.domNode
DEFINE nrows INTEGER
DEFINE tab_txt STRING -- Used in schema_view

DEFINE splash SMALLINT

MAIN
	DEFINE y SMALLINT

	CALL STARTLOG("errors.log")
	DISPLAY "DBPATH:",fgl_getenv("DBPATH")
	DISPLAY "FGL_GL_DBGLEV:",fgl_getenv("FGL_GL_DBGLEV")
	CALL gl_setInfo(p_version,p_splash, p_progicon, p_progname, p_progdesc, p_progauth)
	LET g_dbgLev = 0
	IF fgl_getenv("FGL_GL_DBGLEV") != "0" THEN
		LET g_dbgLev = fgl_getenv("FGL_GL_DBGLEV")
	END IF
&ifdef DEBUG
	LET g_dbgLev = 2
&endif
	IF fgl_getenv("DBQUERYDB") = "1" THEN
		LET g_dbgLev = 2
	END IF

	GL_DBGMSG(0,"Started")
	LET cwd = base.application.getProgramDir()
	LET gdcver = ui.interface.getFrontEndName()," ",
								ui.interface.getFrontEndVersion()
	LET gver = "build ",fgl_getversion()
	LET gdcip = fgl_getenv("FGLSERVER")
	GL_DBGMSG(0,"Runtime:"||gver)
	GL_DBGMSG(0,"Client:"||gdcver||" on "||gdcip)

	GL_DBGMSG(2,"info-max_flds:"||max_flds)

	CLOSE WINDOW SCREEN

	LET root = ui.Interface.getRootNode()
	CALL create_defaults(root) -- Function in dbquery_lib.4gl - styles & actions

	CALL ui.interface.setImage(gl_progicon)

	LET splash = TRUE
	LET where_clause = "1=1"
	LET db_cnt = 0
	LET db_open = FALSE
	LET db_stat = "Disconnected"
	LET db_typ = "sch"
	LET sqlfe_only = FALSE
	LET tabs = 0
	IF base.Application.getArgumentCount() != 0 THEN
		CALL proc_args(base.Application.getArgumentCount())
	END IF
	IF UPSHIFT(ui.Interface.getFrontEndName()) = "GWC" THEN
		LET splash = FALSE
	END IF
	IF splash THEN CALL gl_splash() END IF

	IF db_sch IS NULL OR db_sch = " " THEN
		GL_DBGMSG(2,"Generating choose_db dialog.")
		LET db_drv = fgl_getenv("DBQ_DBDRIVER")
		LET db_sch = fgl_getenv("DBQ_DBNAME")
		LET db_src = fgl_getenv("DBQ_DBSOURCE")
		LET db_hst = fgl_getenv("DBQ_DBHOST")
		LET db_usr = fgl_getenv("DBQ_DBUSER")
		LET db_psw = fgl_getenv("DBQ_DBPASS")
		LET sel_tabname = fgl_getenv("DBQ_TABNAME")
		LET choose_db = choose_db() -- Function in dbquery_lib.4gl
		IF NOT choose_db THEN EXIT PROGRAM END IF
	END IF

	IF sqlfe_only THEN
		CALL sql()
		EXIT PROGRAM
	END IF

	CALL create_tables_form()
	IF sel_tabname IS NULL OR sel_tabname = " " THEN
		LET sel_tabno = 1
	ELSE
		FOR y = 1 TO tabs
			IF sel_tabname = tables[y].tabname THEN EXIT FOR END IF
		END FOR
		IF y > tabs THEN LET y = 1 END IF
		LET sel_tabno = y
	END IF
	LET sel_tabname = tables[sel_tabno].tabname
	CALL mktable_form()
	CALL disp_arr()

	CLOSE WINDOW main

	GL_DBGMSG(0,"Program finished.")

END MAIN
--------------------------------------------------------------------------------
FUNCTION open_cur(sel)
	DEFINE sel CHAR(200)

	PREPARE pre FROM sel
	IF STATUS != 0 THEN RETURN FALSE END IF

	DECLARE cur SCROLL CURSOR FOR pre
	IF STATUS != 0 THEN RETURN FALSE END IF

	OPEN cur
	IF STATUS != 0 THEN RETURN FALSE END IF

	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION disp_arr()

	WHILE TRUE
		LET int_flag = FALSE
		GL_DBGMSG(2,"main - display array tables, count:"||tabs||" getLength:"||tables.getLength())
		--DISPLAY ARRAY tables TO tables.* ATTRIBUTE(COUNT=tabs)
		DISPLAY ARRAY tables TO tables.* ATTRIBUTE(COUNT=tables.getLength())
			BEFORE DISPLAY
				CALL fgl_set_arr_curr(sel_tabno)
			ON ACTION exit
				LET int_flag = TRUE
				EXIT DISPLAY

			ON ACTION notb
				LET notb = NOT notb
				CALL no_tb( notb )			

			ON ACTION sql
				CALL sql()
				LET int_flag = FALSE

			ON ACTION writesch
				CALL xml_root.writeXML(db_sch CLIPPED||".xml")
				MESSAGE "Schema written to '",db_sch CLIPPED,".xml'."

			ON ACTION addtab
				CALL tab_maint("A",sel_tabname)
			ON ACTION droptab
				CALL tab_maint("D",sel_tabname)
			ON ACTION altertab
				CALL tab_maint("M",sel_tabname)

			ON ACTION query
				CALL construct()
				LET nrows = get_data()
				CALL disp_rec()
		
			ON ACTION first
				IF nrows > 0 THEN FETCH FIRST cur INTO rec.* END IF
				CALL disp_rec()
			ON ACTION previous
				IF nrows > 0 THEN FETCH PREVIOUS cur INTO rec.* END IF
				CALL disp_rec()
			ON ACTION next
				IF nrows > 0 THEN FETCH NEXT cur INTO rec.* END IF
				CALL disp_rec()
			ON ACTION last
				IF nrows > 0 THEN FETCH LAST cur INTO rec.* END IF
				CALL disp_rec()

			ON ACTION schema_e
				CALL schema_view("E")

			ON ACTION schema_t
				CALL schema_view("T")

			ON ACTION listview
				CALL choose_fields()

			ON ACTION closedb
				IF NOT close_db() THEN
					ERROR "Manual disconnect failed."
					GL_DBGMSG(0,"Manual disconnect failed.")
				END IF

			ON ACTION opendb
				IF NOT open_db() THEN
					ERROR "Manual connect failed."
					GL_DBGMSG(0,"Manual connect failed.")
				END IF

			ON ACTION chgdb
				IF NOT close_db() THEN
					ERROR "Manual disconnect failed."
					GL_DBGMSG(0,"Manual disconnect failed.")
				END IF
				CALL fgl_set_arr_curr(1)
				IF choose_db() THEN
					LET choose_db = TRUE
					EXIT DISPLAY
				END IF

			ON ACTION writeform
				CALL main_vbox.writeXML(sel_tabname CLIPPED||".xml")
				MESSAGE "Form written to '",sel_tabname CLIPPED,".xml'."

			ON ACTION help CALL gl_help(0)
			ON ACTION about CALL gl_about( gl_verFmt( gl_version) )
		END DISPLAY
		IF int_flag THEN 
			GL_DBGMSG(2,"int_flag set")
			EXIT WHILE
		END IF
		LET sel_tabno = arr_curr()
		LET sel_tabname = tables[sel_tabno].tabname
		CALL mktable_form()
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION mktable_form()

	LET xml_cols = xml_root.selectbypath("//table[@name=\""||sel_tabname CLIPPED||"\"]")
	IF xml_cols IS NULL OR xml_cols.getlength() < 1 THEN 
		 DISPLAY "XML Error!//table[@name=\""||sel_tabname CLIPPED||"\"]"
	ELSE
		LET xml_tab = xml_cols.item(1)
		LET no_of_cols = xml_tab.getattribute("no_of_cols")
		LET xml_cols = xml_tab.selectbytagname("column")
		GL_DBGMSG(2,"Columns for "||sel_tabname CLIPPED||"="||xml_cols.getlength())
	END IF
	IF no_of_cols > max_flds THEN
		CALL show_form(TRUE)
	ELSE
		CALL show_form(FALSE)
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION show_form(mtab)
	DEFINE mtab,x,scr_x SMALLINT
	DEFINE vbox,grp,sp om.DomNode

--	GL_DBGMSG(2,"show_form() - opening window.")
--	OPEN WINDOW tabdetails AT 1,1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTES(BORDER)

	GL_DBGMSG(2,"show_form() - generating form.")
	LET win_title = win_title("",sel_tabname)
	CALL main_win.setAttribute("text",win_title)
	CALL main_frm.setAttribute("name",DOWNSHIFT(sel_tabname) CLIPPED)

	LET vbox = main_vbox.getFirstChild()
	IF vbox IS NULL THEN
		LET vbox = main_vbox
	ELSE
		CALL main_hbox.removeChild( main_vbox )
		LET main_vbox = main_hbox.createChild("VBox")
		LET vbox = main_vbox
	END IF
	
	IF mtab THEN
		CALL build_tabform(vbox)
	ELSE
		CALL build_form(vbox)
	END IF

	IF no_of_cols < max_dsp_cols THEN
		LET grp = vbox.createChild('Group')
		CALL grp.setAttribute('text',"Credits")
		LET grp = grp.createChild("HBox")
		LET sp = grp.createChild("SpacerItem")
		CALL add_widget(grp,"Label",copyright,100,x,1,1,"","copyright")
		LET sp = grp.createChild("SpacerItem")

		LET grp = vbox.createChild('Grid')
		CALL grp.setAttribute('hidden',"1")

		LET scr_x = 1
		FOR x = no_of_cols+1 TO max_dsp_cols
			CALL add_widget(grp,"FormField","Test1",10,x,scr_x,20,"CHAR(10)","")
			LET scr_x = scr_x + 1
		END FOR
		CALL grp.setAttribute('hidden',"1")
	END IF
 
	GL_DBGMSG(2,"show_form() - done.")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION build_form(vbox)
	DEFINE x,scr_x,len SMALLINT
	DEFINE vbox,grp om.DomNode
	DEFINE tabn CHAR(18)
	DEFINE com STRING

	LET grp = vbox.createChild('Group')
	LET tabn = sel_tabname
	LET tabn[1] = UPSHIFT(tabn[1])
	CALL grp.setAttribute('text',tabn)

	LET scr_x = 0
	FOR x = 1 TO xml_cols.getlength()
		LET xml_col = xml_cols.item(x)
-- com = comment/tooltip ie account_no CHAR(10)
		LET com = xml_col.getattribute("name")||" "||xml_col.getattribute("type")
		CALL add_widget(grp,"Label",xml_col.getattribute("name"),18,x,scr_x,1,"",com)
		LET len = xml_col.getAttribute("collen")
		CALL add_widget(grp,"FormField","1",len,x,scr_x,20,xml_col.getattribute("type"),com)
		IF len > textedit_len THEN 
			LET scr_x = scr_x + (len/textedit_len)
		END IF
		LET scr_x = scr_x + 1
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION build_tabform(vbox)
	DEFINE vbox, pagectrl, page, hbox, grid om.DomNode
	DEFINE x,scr_x,y,len SMALLINT
	DEFINE tabno SMALLINT
	DEFINE tabn CHAR(18)
	DEFINE com STRING

	LET pagectrl = vbox.createChild('Folder')
	
	LET y = 1
	FOR tabno = 1 TO ((no_of_cols / max_flds) + 1)
		LET page = pagectrl.createChild('Page')
		LET tabn = "Tab",tabno USING "<<"
		CALL page.setAttribute('text',tabn)
		LET hbox = page.createChild('HBox')
		LET grid = hbox.createChild('Group')
		LET tabn = sel_tabname CLIPPED,"-",tabno USING "<<"
		LET tabn[1] = UPSHIFT(tabn[1])
		CALL grid.setAttribute('text',tabn)
		LET scr_x = 0
		FOR x = 1 TO max_flds
			LET xml_col = xml_cols.item(y)
			IF y > xml_cols.getlength() THEN EXIT FOR END IF
-- com = comment/tooltip ie account_no CHAR(10)
			LET com = xml_col.getattribute("name")||" "||xml_col.getattribute("type")
			IF com IS NULL THEN 
				LET com = "NULL!"
			END IF
			CALL add_widget(grid,"Label",xml_col.getattribute("name"),18,y,scr_x,1,"",com)
			LET len = xml_col.getattribute("collen")
			CALL add_widget(grid,"FormField","1",len,y,scr_x,20,xml_col.getattribute("type"),com)
			IF len > textedit_len THEN 
				LET scr_x = scr_x + (len/textedit_len)
			END IF
			LET scr_x = scr_x + 1
			LET y = y + 1
		END FOR
		IF y > xml_cols.getlength() THEN EXIT FOR END IF
	END FOR
 
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION close_db()
	DEFINE stat INTEGER

	IF NOT db_open THEN RETURN TRUE END IF
	IF cur_open THEN CALL close_cur() END IF
	GL_DBGMSG(2,"Closing Database:"||db_nam)
	DISCONNECT db_nam
	IF STATUS != 0 THEN
		LET stat = STATUS
		GL_DBGMSG(2,"Disconnect failed, status='"||STATUS||"'")
		ERROR "Unable to Disconnect from Database:",db_nam
		CALL fgl_winmessage("Error", "Failed to Disconnect from database - Status:"||stat, "exclamation")
		RETURN FALSE
	END IF
	LET db_open = FALSE
	LET db_stat = "Disconnected"
	LET win_title = win_title("",sel_tabname)
	CALL main_win.setAttribute("text",win_title)
	MESSAGE "Database connection closed."
	RETURN TRUE
 
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION open_db()
	DEFINE stat INTEGER
	DEFINE dbc VARCHAR(200)

	IF db_open THEN RETURN TRUE END IF
	WHENEVER ERROR CONTINUE

	IF db_drv IS NOT NULL THEN
		LET dbc = db_nam CLIPPED,"+driver='",db_drv CLIPPED,"'"
		IF db_src IS NOT NULL THEN
			LET dbc = dbc CLIPPED,",source='",db_src CLIPPED,"'"
		END IF
	ELSE
		LET dbc = db_nam CLIPPED
	END IF

	IF db_usr IS NOT NULL AND db_usr != " " 
	AND db_psw IS NOT NULL AND db_psw != " " THEN
		GL_DBGMSG(2,"Connecting to Database:"||db_nam CLIPPED||" AS "||db_usr)
--		CONNECT TO db_nam AS db_usr USING db_psw
		LET dbc = dbc CLIPPED,",username='",db_usr CLIPPED,"',password='",db_psw CLIPPED,"'"
		GL_DBGMSG(0,"DBC:"||dbc CLIPPED)
		DATABASE dbc
	ELSE
		GL_DBGMSG(2,"Connecting to Database:"||dbc)
--		CONNECT TO db_nam
		GL_DBGMSG(0,"DBC:"||dbc CLIPPED)
		DATABASE dbc
	END IF
	WHENEVER ERROR STOP
	IF STATUS != 0 THEN
		LET stat = STATUS
		GL_DBGMSG(0,"Connect failed, status='"||STATUS||"'")
		ERROR "Unable to Connect to Database:",db_nam
		CALL fgl_winmessage("Error", "Failed to Connec to database - Status:"||stat||"\n"||SQLERRMESSAGE, "exclamation")
		RETURN FALSE
	END IF
	LET db_typ = db_get_database_type()
	GL_DBGMSG(2,"Database connection open, type='"||db_typ||"'.")
	LET db_open = TRUE

	LET db_stat = "Connected"
	
	LET win_title = win_title("",sel_tabname)
	CALL main_win.setAttribute("text",win_title)
	MESSAGE "Database connection open."

	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_data()
	DEFINE sel CHAR(2000)
	DEFINE err SMALLINT

	IF where_clause IS NULL OR where_clause = " " THEN
		LET where_clause = "1=1"
	END IF

	IF NOT db_open THEN
		IF NOT open_db() THEN RETURN 0 END IF
	END IF

	IF cur_open THEN CALL close_cur() END IF

	GL_DBGMSG(2,"get_data() - accessing database.")
	LET err = FALSE
	LET sel = "SELECT COUNT(*) FROM ",sel_tabname
	LET sel = sel CLIPPED," WHERE ",where_clause
	WHENEVER ERROR CONTINUE
	GL_DBGMSG(2,"sel='"||sel CLIPPED||"'")
	PREPARE cnt_pre FROM sel
	WHENEVER ERROR STOP
	IF STATUS != 0 THEN
		DISPLAY sel
		CALL gl_winMessage("Error","Invalid Select statement!\n"||STATUS||":"||SQLERRMESSAGE||"\n"||sel,"exclamation")
		RETURN 0
	END IF
	DECLARE cnt_cur CURSOR FOR cnt_pre
	OPEN cnt_cur
	IF STATUS != 0 THEN
		LET err = TRUE
	END IF
	FETCH cnt_cur INTO nrows
	CLOSE cnt_cur
	ERROR nrows," Rows Found."
--	MESSAGE nrows," Rows Found."

	INITIALIZE rec TO NULL

	IF nrows > 0 THEN
		LET sel = "SELECT * FROM ",sel_tabname -- CLIPPED," FOR UPDATE"
		LET sel = sel CLIPPED," WHERE ",where_clause
		LET cur_open = open_cur(sel)
		IF cur_open THEN
			FETCH FIRST cur INTO rec.*
		ELSE
			LET err = TRUE
			RETURN 0
		END IF
	ELSE
		LET err = TRUE
	END IF
	RETURN nrows

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION close_cur()

	CLOSE cur	
	LET cur_open = FALSE

END FUNCTION
--------------------------------------------------------------------------------
-- add_widget
-- 	box		: container node
--	wid		: widget ( ie FormField, Label )
-- 	tex		: text / label text
--  len		: Length of decoration item 
--  x 		: field no
--  scr_x : screen X
--  scr_y : screen Y
--  ctyp  : SQLtype
--  com   : Comment / Tooltip
FUNCTION add_widget(box,wid,tex,len,x,scr_x,y,ctyp,com)
	DEFINE box,lab om.DomNode
	DEFINE len,x,scr_x,y,h,texlen SMALLINT
	DEFINE ctyp,com STRING
	DEFINE wid,tex, newtex,nam String

	LET lab = box.createChild(wid)
	IF wid = "FormField" THEN
		LET nam = "fld",x USING "<<<<&"
		CALL lab.setAttribute('colName',nam)
--		CALL lab.setAttribute('value',"test")
		CALL lab.setAttribute('sqlType',ctyp CLIPPED)
		CALL lab.setAttribute('sqlTabName',"formonly")
		IF len > textedit_len THEN
			CALL add_widget(lab,"TextEdit",tex,len,x,scr_x,y,"",com)
		ELSE
			CALL add_widget(lab,"Edit",tex,len,x,scr_x,y,"",com)
		END IF
		RETURN
	END IF
	IF wid = "Label" THEN
		LET texlen = tex.getLength()
		LET newtex = UPSHIFT( tex.getCharAt(1) ) 
		LET newtex = newtex.append( tex.subString(2,texlen) )
		LET h = newtex.getIndexOf("_",1)
		IF h > 0 THEN
			LET newtex = newtex.subString(1,h-1)," ",newtex.subString(h+1,texlen)
		END IF
		LET h = newtex.getIndexOf("_",1)
		IF h > 0 THEN
			LET newtex = newtex.subString(1,h-1)," ",newtex.subString(h+1,texlen)
		END IF
		CALL lab.setAttribute('text',newtex CLIPPED)
		IF com = "copyright" THEN
			CALL lab.setAttribute('style',com)
			LET com = NULL
		END IF
	ELSE
		CALL lab.setAttribute('text',tex CLIPPED)
	END IF
	CALL lab.setAttribute('posY',scr_x)
	CALL lab.setAttribute('posX',y)
	IF wid = "TextEdit" THEN
		CALL lab.setAttribute('width',textedit_len)
		CALL lab.setAttribute('gridWidth',textedit_len)
		LET h = (len/textedit_len)+1
		IF h > 10 THEN LET h = 10 END IF
		CALL lab.setAttribute('height',h)
	ELSE
		CALL lab.setAttribute('width',len)
		CALL lab.setAttribute('gridWidth',len)
		CALL lab.setAttribute('height',"1")
	END IF
	CALL lab.setAttribute('justify',"left")
	IF wid = "Edit" OR wid = "TextEdit" THEN
--		CALL lab.setAttribute('color',"magenta")
--	ELSE
		CALL lab.setAttribute('color',"blue")
	END IF
	IF com IS NOT NULL THEN
		CALL lab.setAttribute('comment',com)
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION disp_rec()

	DISPLAY BY NAME rec.*

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION schema_view(typ)
	DEFINE l_tabno SMALLINT
	DEFINE typ CHAR(1)
	DEFINE win, frm, hbox, grid, tabl, tabc, edit	om.DomNode

	OPEN WINDOW schema AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode("schema")
	CALL win.setAttribute("style","dialog")
	LET frm = gl_genForm("schema")
	CALL frm.setAttribute("name",sel_tabname CLIPPED)
	LET win_title = "Schema View:	", UPSHIFT(sel_tabname)
	CALL win.setAttribute("text",win_title)

	LET hbox = frm.createChild('HBox')
	CALL hbox.setAttribute("splitter",1)
	LET grid = hbox.createChild('Grid')
	CALL grid.setAttribute("width",22)

	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName","tables")
	CALL tabl.setAttribute("width",20)
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","10")
	CALL tabl.setAttribute("size","10")
	LET tabc = tabl.createChild('TableColumn')
	CALL tabc.setAttribute("colName","tabname")
	LET edit = tabc.createChild('Edit')
	CALL tabc.setAttribute("text","Table")
	CALL edit.setAttribute("width",18)

	LET grid = hbox.createChild('Grid')
	CALL grid.setAttribute("width",28)
	IF typ = "T" THEN
		LET tabl = grid.createChild('Table')
		CALL tabl.setAttribute("tabName","schema")
		CALL tabl.setAttribute("height","20")
		CALL tabl.setAttribute("pageSize","20")
		CALL tabl.setAttribute("size","20")
	
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName","colname")
		LET edit = tabc.createChild('Edit')
		CALL tabc.setAttribute("text","Name")
		CALL edit.setAttribute("width",18)
	
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName","coltype")
		LET edit = tabc.createChild('Edit')
		CALL tabc.setAttribute("text","Type")
		CALL edit.setAttribute("width",40)
	ELSE
		LET tabl = grid.createChild('FormField')
		CALL tabl.setAttribute("colName","schema")
		LET edit = tabl.createChild('TextEdit')
		CALL edit.setAttribute("width",40)
		CALL edit.setAttribute("fontPitch","fixed")
		CALL edit.setAttribute("height",20)
		CALL edit.setAttribute("stretch","both")
	END IF

	LET int_flag = FALSE
	LET l_tabno = sel_tabno
	WHILE NOT int_flag
		DISPLAY ARRAY tables TO tables.* ATTRIBUTE(COUNT=tabs)
			BEFORE DISPLAY
				CALL fgl_set_arr_curr(l_tabno)
			BEFORE ROW
				LET l_tabno = arr_curr()
				CALL schema_view_tab(l_tabno,typ)
			ON ACTION copy
					CALL ui.Interface.frontCall("standard","cbclear", [], [])
					CALL ui.Interface.frontCall("standard","cbset",tab_txt, [])
					MESSAGE "Table copied to clipboard."
--			ON ACTION help CALL gl_help(2)
--			ON ACTION about CALL gl_about( gl_verFmt( gl_version) )
		END DISPLAY	
	END WHILE
	LET int_flag = FALSE

	CLOSE WINDOW schema

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION schema_view_tab(l_tabno,typ)
	DEFINE x,l_tabno SMALLINT
	DEFINE typ CHAR(1)
	DEFINE l_xml_cols om.NodeList
	DEFINE l_xml_tab om.domNode
	DEFINE sch DYNAMIC ARRAY OF RECORD
		colname CHAR(18),
		coltype CHAR(40)
	END RECORD

--	GL_DBGMSG(2,"schema view for ",tables[l_tabno].tabname
	LET l_xml_cols = xml_root.selectbypath("//table[@name=\""||tables[l_tabno].tabname CLIPPED||"\"]")
	IF l_xml_cols IS NULL OR l_xml_cols.getlength() < 1 THEN 
	 	DISPLAY "XML Error!//table[@name=\""||tables[l_tabno].tabname CLIPPED||"\"]"
	ELSE
		LET l_xml_tab = l_xml_cols.item(1)
		LET l_xml_cols = l_xml_tab.selectbytagname("column")
	END IF
	GL_DBGMSG(2,"schema view columns:"||l_xml_cols.getLength())
	CALL sch.clear()
	LET tab_txt = ASCII(10)
	FOR x = 1 TO l_xml_cols.getLength()	
		LET xml_col = l_xml_cols.item(x)
		LET sch[x].colname = xml_col.getAttribute("name")
		LET sch[x].coltype = xml_col.getAttribute("type")
		LET tab_txt = tab_txt.append(sch[x].colname||" ")
		LET tab_txt = tab_txt.append(sch[x].coltype CLIPPED)
		IF x != l_xml_cols.getLength() THEN
			LET tab_txt = tab_txt.append(","||ASCII(10))
		END IF
	END FOR
	IF typ = "T" THEN
		DISPLAY ARRAY sch TO schema.* ATTRIBUTE(COUNT=l_xml_cols.getLength())
			BEFORE DISPLAY
				IF l_xml_cols.getLength() < 20 THEN
					EXIT DISPLAY
				END IF
		END DISPLAY
	ELSE
		DISPLAY tab_txt TO schema
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION list_view(output)
				 DEFINE output CHAR(1)
				 DEFINE sel CHAR(200)
	DEFINE x, col_no SMALLINT
	DEFINE key CHAR(20)
	DEFINE ty CHAR(20)
	DEFINE coltypes CHAR(max_lst_cols)

	IF NOT db_open THEN
		IF NOT open_db() THEN RETURN END IF
	END IF

	LET sel = ""
	LET coltypes = "xxxxxx"
	FOR x = 1 TO max_lst_cols
		LET col_no = sel_cols[x]
		IF col_no = 0 THEN CONTINUE FOR END IF
		LET xml_col = xml_cols.item(col_no)
		LET sel = sel CLIPPED,xml_col.getAttribute("name") CLIPPED,","
		LET ty = xml_col.getAttribute("type")
		CASE ty[1,2]
			WHEN "SE"
				LET coltypes[x] = "I"
			WHEN "SM"
				LET coltypes[x] = "I"
			WHEN "IN"
				LET coltypes[x] = "I"
			WHEN "MO"
				LET coltypes[x] = "N"
			WHEN "DE"
				LET coltypes[x] = "N"
			WHEN "FL"
				LET coltypes[x] = "N"
			WHEN "RE"
				LET coltypes[x] = "N"
			WHEN "DA"
				LET coltypes[x] = "D"
			OTHERWISE
				LET coltypes[x] = "C"
		END CASE
	END FOR
	LET col_no = LENGTH( sel )
	LET sel[ col_no ] = " "
	CASE output
		WHEN "T"
			LET key = gl_lookup(sel_tabname,sel,"",coltypes,"1=1","")
		WHEN "P"
			CALL gen_rpt(sel_tabname,sel,coltypes,"1=1",TRUE)
		WHEN "R"
			CALL gen_rpt(sel_tabname,sel,coltypes,"1=1",FALSE)
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_tables_form()
	DEFINE tabl, tabc, edit	om.DomNode

	OPEN WINDOW main AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET main_win = gl_getWinNode("main")
	CALL main_win.setAttribute("style","mywin")

	LET main_frm = gl_genForm( "tables" )
	CALL main_frm.setAttribute("name",db_sch CLIPPED)
	CALL main_frm.setAttribute("height","24")
	CALL create_topmenu( main_frm, 2, notb) RETURNING edit
	CALL create_toolbar( main_frm, TRUE, TRUE) RETURNING edit

	LET main_hbox = main_frm.createChild('HBox')
	CALL main_hbox.setAttribute("splitter","1")

	LET tabl = main_hbox.createChild('Table')
	CALL tabl.setAttribute("tabName","tables")
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("width","20")
	CALL tabl.setAttribute("pageSize","20")
--	CALL tabl.setAttribute("unsizableColumns","1")
	CALL tabl.setAttribute("size","20")
	LET tabc = tabl.createChild('TableColumn')
	CALL tabc.setAttribute("colName","tables")
	CALL tabc.setAttribute("text","Tables")
	LET edit = tabc.createChild('Edit')
	CALL edit.setAttribute("width","20")

	LET main_vbox = main_hbox.createChild('VBox')

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION construct()
	DEFINE win, frm, vbox, grid,
				 textedt,ff	om.DomNode,
					x SMALLINT

	OPEN WINDOW con AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode("con")
	CALL win.setAttribute("style","dialog")
	LET frm = gl_genForm("con")
	CALL frm.setAttribute("text","Enter Where Clause")
	CALL frm.setAttribute("name","construct")

	LET vbox = frm.createChild('VBox')
	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("height","10")
	LET ff = grid.createChild('FormField')
	CALL ff.setAttribute("colName","where_clause")
	LET textedt = ff.createChild('TextEdit')
	CALL textedt.setAttribute("height","6")
	CALL textedt.setAttribute("width","40")
	CALL textedt.setAttribute("posX","1")
	CALL textedt.setAttribute("posY","1")

	INPUT BY NAME where_clause WITHOUT DEFAULTS
		ON ACTION all_recs
			LET where_clause = "1=1"
			EXIT INPUT
		ON ACTION help CALL gl_help(10)
		ON ACTION about CALL gl_about( gl_verFmt( gl_version) )
	END INPUT

	FOR x = 1 TO LENGTH( where_clause )
		IF where_clause[x] = ASCII(10) THEN LET where_clause[x] = " " END IF
	END FOR

	CLOSE WINDOW con

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION insupd_rec(doit)
	DEFINE doit SMALLINT

	MENU "Function" ATTRIBUTE(STYLE="dialog",COMMENT="What would you like to do?")
		COMMAND "Insert" "Insert this record"
			CALL ins_rec(doit)
		COMMAND "Update" "Update this record"
			CALL upd_rec(doit)
		COMMAND "Cancel" "Cancel the request"
			EXIT MENU
	END MENU

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION upd_rec(upd)
	DEFINE upd SMALLINT
	DEFINE stmt CHAR(2000)
	DEFINE fld VARCHAR(max_col_len)
	DEFINE x SMALLINT

	LET stmt = "UPDATE ",sel_tabname CLIPPED, " SET ("
	FOR x = 1 TO xml_cols.getLength()
		LET xml_col = xml_cols.item(x)
		LET fld = get_fld(x)
		IF fld IS NOT NULL AND fld != " " THEN
			LET stmt = stmt CLIPPED,xml_col.getAttribute("name") CLIPPED,","
		END IF
	END FOR
	LET x = LENGTH( stmt )
	LET stmt[x,2000] = ") = ("
	FOR x = 1 TO no_of_cols
		LET fld = get_fld(x)
		IF fld IS NOT NULL AND fld != " " THEN
			LET stmt = stmt CLIPPED,"'",fld CLIPPED,"',"
		END IF
	END FOR
	LET x = LENGTH( stmt )
	LET stmt[x,2000] = ") CURRENT OF cur"
	GL_DBGMSG(2,"stmt:"||stmt CLIPPED)
	IF upd THEN
		WHENEVER ERROR CONTINUE
		PREPARE upd_stmt FROM stmt
		EXECUTE upd_stmt
		IF STATUS = 0 THEN
			GL_DBGMSG(2,"Record Update.")
			MESSAGE "M:Record Update."
			ERROR "E:Record Update."
		ELSE
			GL_DBGMSG(0,"Update Failed.")
			MESSAGE "Update FAILED:",STATUS
			ERROR "Update FAILED:",STATUS
		END IF
		WHENEVER ERROR STOP
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION ins_rec(ins)
	DEFINE ins SMALLINT
	DEFINE stmt CHAR(2000)
	DEFINE fld VARCHAR(max_col_len)
	DEFINE x SMALLINT

	LET stmt = "INSERT INTO ",sel_tabname CLIPPED, " ("
	FOR x = 1 TO xml_cols.getLength()
		LET xml_col = xml_cols.item(x)
		LET fld = get_fld(x)
		IF fld IS NOT NULL AND fld != " " THEN
			LET stmt = stmt CLIPPED,xml_col.getAttribute("name") CLIPPED,","
		END IF
	END FOR
	LET x = LENGTH( stmt )
	LET stmt[x,2000] = ") VALUES("
	FOR x = 1 TO no_of_cols
		LET fld = get_fld(x)
		IF fld IS NOT NULL AND fld != " " THEN
			LET stmt = stmt CLIPPED,"'",fld CLIPPED,"',"
		END IF
	END FOR
	LET x = LENGTH( stmt )
	LET stmt[x] = ")"
	GL_DBGMSG(2,"Stmt:"||stmt CLIPPED)
	IF ins THEN
		WHENEVER ERROR CONTINUE
		PREPARE ins_stmt FROM stmt
		EXECUTE ins_stmt
		IF STATUS = 0 THEN
			GL_DBGMSG(2,"Record Inserted.")
			MESSAGE "M:Record Inserted."
			ERROR "E:Record Inserted."
		ELSE
			GL_DBGMSG(0,"Insert Failed:"||STATUS)
			MESSAGE "Insert FAILED:",STATUS
			ERROR "Insert FAILED:",STATUS
		END IF
		WHENEVER ERROR STOP
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_fld(x)
	DEFINE x SMALLINT
	CASE x
		WHEN	1 RETURN rec.fld1
		WHEN	2 RETURN rec.fld2
		WHEN	3 RETURN rec.fld3
		WHEN	4 RETURN rec.fld4
		WHEN	5 RETURN rec.fld5
		WHEN	6 RETURN rec.fld6
		WHEN	7 RETURN rec.fld7
		WHEN	8 RETURN rec.fld8
		WHEN	9 RETURN rec.fld9
		WHEN 10 RETURN rec.fld10
		WHEN 11 RETURN rec.fld11
		WHEN 12 RETURN rec.fld12
		WHEN 13 RETURN rec.fld13
		WHEN 14 RETURN rec.fld14
		WHEN 15 RETURN rec.fld15
		WHEN 16 RETURN rec.fld16
		WHEN 17 RETURN rec.fld17
		WHEN 18 RETURN rec.fld18
		WHEN 19 RETURN rec.fld19
		WHEN 20 RETURN rec.fld20
		WHEN 21 RETURN rec.fld21
		WHEN 22 RETURN rec.fld22
		WHEN 23 RETURN rec.fld23
		WHEN 24 RETURN rec.fld24
		WHEN 25 RETURN rec.fld25
		WHEN 26 RETURN rec.fld26
		WHEN 27 RETURN rec.fld27
		WHEN 28 RETURN rec.fld28
		WHEN 29 RETURN rec.fld29
		WHEN 30 RETURN rec.fld30
		WHEN 31 RETURN rec.fld31
		WHEN 32 RETURN rec.fld32
		WHEN 33 RETURN rec.fld33
		WHEN 34 RETURN rec.fld34
		WHEN 35 RETURN rec.fld35
		WHEN 36 RETURN rec.fld36
		WHEN 37 RETURN rec.fld37
		WHEN 38 RETURN rec.fld38
		WHEN 39 RETURN rec.fld39
		WHEN 40 RETURN rec.fld40
		WHEN 41 RETURN rec.fld41
		WHEN 42 RETURN rec.fld42
		WHEN 43 RETURN rec.fld43
		WHEN 44 RETURN rec.fld44
		WHEN 45 RETURN rec.fld45
		WHEN 46 RETURN rec.fld46
		WHEN 47 RETURN rec.fld47
		WHEN 48 RETURN rec.fld48
		WHEN 49 RETURN rec.fld49
		WHEN 50 RETURN rec.fld50
		WHEN 51 RETURN rec.fld31
		WHEN 52 RETURN rec.fld52
		WHEN 53 RETURN rec.fld53
		WHEN 54 RETURN rec.fld54
		WHEN 55 RETURN rec.fld55
		WHEN 56 RETURN rec.fld56
		WHEN 57 RETURN rec.fld57
		WHEN 58 RETURN rec.fld58
		WHEN 59 RETURN rec.fld59
		WHEN 60 RETURN rec.fld60
		WHEN 61 RETURN rec.fld61
		WHEN 62 RETURN rec.fld62
		WHEN 63 RETURN rec.fld63
		WHEN 64 RETURN rec.fld64
		WHEN 65 RETURN rec.fld65
		WHEN 66 RETURN rec.fld66
		WHEN 67 RETURN rec.fld67
		WHEN 68 RETURN rec.fld68
		WHEN 69 RETURN rec.fld69
		WHEN 70 RETURN rec.fld70
		WHEN 71 RETURN rec.fld71
		WHEN 72 RETURN rec.fld72
		WHEN 73 RETURN rec.fld73
		WHEN 74 RETURN rec.fld74
		WHEN 75 RETURN rec.fld75
		WHEN 76 RETURN rec.fld76
		WHEN 77 RETURN rec.fld77
		WHEN 78 RETURN rec.fld78
		WHEN 79 RETURN rec.fld79
		WHEN 80 RETURN rec.fld80
		WHEN 81 RETURN rec.fld81
		WHEN 82 RETURN rec.fld82
		WHEN 83 RETURN rec.fld83
		WHEN 84 RETURN rec.fld84
		WHEN 85 RETURN rec.fld85
		WHEN 86 RETURN rec.fld86
		WHEN 87 RETURN rec.fld87
		WHEN 88 RETURN rec.fld88
		WHEN 89 RETURN rec.fld89
		WHEN 90 RETURN rec.fld90
		WHEN 91 RETURN rec.fld91
		WHEN 92 RETURN rec.fld92
		WHEN 93 RETURN rec.fld93
		WHEN 94 RETURN rec.fld94
		WHEN 95 RETURN rec.fld95
		WHEN 96 RETURN rec.fld96
		WHEN 97 RETURN rec.fld97
		WHEN 98 RETURN rec.fld98
		WHEN 99 RETURN rec.fld99
		WHEN 100 RETURN rec.fld100
	END CASE

	RETURN "1"
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION no_tb( tf )
	DEFINE tf SMALLINT
	DEFINE tb om.domNode
	DEFINE tmc om.domNode
	DEFINE lst om.NodeList

	LET lst = root.selectByPath("//TopMenuCommand[@name=\"notb\"]")
	LET tmc = lst.item(1)
	GL_DBGMSG(2,"tmc:"||tmc.getAttribute("name")||":"||tmc.getAttribute("image"))

	IF tf THEN
		CALL tmc.setAttribute("image","hook")
		LET lst	= root.selectByPath("//ToolBar")
		LET tb = lst.item(1)
		CALL root.removeChild( tb )
	ELSE
		CALL tmc.setAttribute("image","delete")
		CALL create_toolbar( root, TRUE, TRUE ) RETURNING tb
	END IF
	
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION choose_fields()
	DEFINE win, frm, vbox, hbox,grp, grid, 
				 but, tabl, tabc, edit, textedt,ff	om.DomNode
	DEFINE choosen STRING
	DEFINE cols DYNAMIC ARRAY OF CHAR(18)
	DEFINE x SMALLINT

	OPEN WINDOW chf AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode("chf")
	CALL win.setAttribute("style","naked")
	LET frm = gl_genForm("chf")
	LET win_title = "Choose Field:	", UPSHIFT(sel_tabname)
	CALL win.setAttribute("text",win_title)
	CALL frm.setAttribute("name","choose_fields")

	LET vbox = frm.createChild('VBox')
	LET hbox = vbox.createChild('HBox')
	LET tabl = hbox.createChild('Table')
	CALL tabl.setAttribute("tabName","columns")
	CALL tabl.setAttribute("height","10")
	CALL tabl.setAttribute("pageSize","10")
	CALL tabl.setAttribute("size","10")
	LET tabc = tabl.createChild('TableColumn')
	CALL tabc.setAttribute("colName","columns")
	CALL tabc.setAttribute("text","Columns")
	LET edit = tabc.createChild('Edit')
	CALL edit.setAttribute("width","18")

	LET grp = hbox.createChild('Group')
	CALL grp.setAttribute("text","Selected")
	LET grid = grp.createChild('Grid')
	CALL grid.setAttribute("height","10")
	LET ff = grid.createChild('FormField')
	CALL ff.setAttribute("colName","choosen")
	LET textedt = ff.createChild('TextEdit')
	CALL textedt.setAttribute("scrollBars","none")
	CALL textedt.setAttribute("height","6")
	CALL textedt.setAttribute("width","16")
	CALL textedt.setAttribute("posX","1")
	CALL textedt.setAttribute("posY","1")
	LET but = grid.createChild('Button')
	CALL but.setAttribute("name","clear")
	CALL but.setAttribute("width","10")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","1")
	CALL but.setAttribute("posY","7")
	LET but = grid.createChild('Button')
	CALL but.setAttribute("name","default")
	CALL but.setAttribute("width","10")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","1")
	CALL but.setAttribute("posY","8")
	
	LET hbox = vbox.createChild('HBox')
	LET but = hbox.createChild('SpacerItem')
	LET but = hbox.createChild('Button')
	CALL but.setAttribute("name","close")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","1")
	CALL but.setAttribute("posY","1")
	LET but = hbox.createChild('Button')
	CALL but.setAttribute("name","list")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","8")
	CALL but.setAttribute("posY","1")
	LET but = hbox.createChild('Button')
	CALL but.setAttribute("name","gen_rpt")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","16")
	CALL but.setAttribute("posY","1")
	LET but = hbox.createChild('Button')
	CALL but.setAttribute("name","prn_cli")
	CALL but.setAttribute("height","1")
	CALL but.setAttribute("posX","24")
	CALL but.setAttribute("posY","1")
	LET but = hbox.createChild('SpacerItem')
	
	FOR x = 1 TO 6
		LET sel_cols[x] = 0
	END FOR
	FOR x = 1 TO xml_cols.getLength()
		LET xml_col = xml_cols.item(x)
		LET cols[x] = xml_col.getAttribute("name")
		IF x < 7 THEN
			LET sel_cols[x] = x
			LET choosen = choosen.append( cols[x] || ASCII(10) )
		END IF
	END FOR
	DISPLAY BY NAME choosen
	LET int_flag = FALSE
	LET x = 7
	DISPLAY ARRAY cols TO columns.* ATTRIBUTE(COUNT=no_of_cols)
--		ON ACTION exit
--			EXIT DISPLAY

		ON ACTION clear
			LET choosen = NULL
			FOR x = 1 TO 6
				LET sel_cols[x] = 0
			END FOR
			LET x = 0
			DISPLAY BY NAME choosen

		ON ACTION default
			LET choosen = NULL
			FOR x = 1 TO 6
				LET choosen = choosen.append( cols[x] || ASCII(10) )
				LET sel_cols[x] = x
			END FOR
			DISPLAY BY NAME choosen

		ON KEY(ACCEPT)
			LET x = x + 1
			IF x < 7 THEN
				LET sel_cols[x] = arr_curr()
				LET choosen = choosen.append( cols[ arr_curr() ] || ASCII(10) )
				DISPLAY BY NAME choosen
			END IF
		ON ACTION List
			IF x > 0 THEN
				CALL list_view("T") -- Table View
			ELSE
				ERROR "Must select at least one column!"
			END IF
		ON ACTION gen_rpt
			IF x > 0 THEN
				CALL list_view("R") -- Report
			END IF
		ON ACTION prn_cli
			IF x > 0 THEN
				CALL list_view("P") -- To Print Client
			END IF
		ON ACTION close
			EXIT DISPLAY
		ON ACTION help CALL gl_help(1)
		ON ACTION about CALL gl_about( gl_verFmt( gl_version) )
	END DISPLAY

	CLOSE WINDOW chf
	IF int_flag THEN
		LET int_flag = FALSE
--		RETURN FALSE
--	ELSE
--		RETURN TRUE
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION proc_args(cnt)
	DEFINE x,cnt SMALLINT
	DEFINE arg CHAR(20)

	FOR x = 1 TO cnt
		LET arg = base.Application.getArgument(x)
		CASE arg
			WHEN "-db"
				LET db_sch = base.Application.getArgument(x+1)
				LET choose_db = FALSE
				CALL read_sch(db_sch) -- Function in dbquery_lib.4gl
				GL_DBGMSG(2,"dbname:"||db_sch)
				LET x = x + 1
			WHEN "-tn"
				LET sel_tabname = base.Application.getArgument(x+1)
				GL_DBGMSG(2,"tabname:"||sel_tabname)
				LET x = x + 1
			WHEN "-sqlfe"
				LET sqlfe_only = TRUE
			WHEN "-nosplash"
				LET splash = FALSE
		END CASE
	END FOR

END FUNCTION
