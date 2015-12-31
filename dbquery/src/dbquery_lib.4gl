
{ CVS Header
$Author: test4j $
$Date: 2008/04/17 17:11:25 $
$Revision: 326 $
$Source: /usr/home/test4j/cvs/all/demos/dbquery/src/dbquery_lib.4gl,v $
$Log: dbquery_lib.4gl,v $
Revision 1.14  2008/04/17 17:11:25  test4j
*** empty log message ***

Revision 1.13  2008/01/22 16:14:08  test4j

Updated for dbdrivers ie Genero 2.0>




Revision 1.12  2007/12/24 11:01:39  test4j
*** empty log message ***

Revision 1.11  2007/11/16 11:48:20  test4j

Small fix for 2.10

Revision 1.10  2007/11/16 11:30:07  test4j
*** empty log message ***

Revision 1.9  2007/07/12 16:42:43  test4j

Changes for built in precompiler

Revision 1.8  2006/07/21 11:34:25  test4j

restructures make

Revision 1.7  2006/06/23 10:24:54  test4j

gl_about added gl_verFmt to call.

Revision 1.6  2006/06/19 18:39:18  test4j
*** empty log message ***

Revision 1.5  2006/03/13 16:11:26  test4j
*** empty log message ***

Revision 1.4  2006/03/13 14:40:21  test4j

cvs tags

Revision 1.3  2006/03/03 17:14:40  test4j

updated library code and changed debug to genero_lib debug.

Revision 1.2  2006/01/12 17:20:57  test4j

Make file should work on DOS, started on other DOS compat issues

Revision 1.1  2005/11/14 17:19:50  test4j

renamed from lib.4gl

Revision 1.41  2005/11/14 17:08:23  test4j

remove functions from lib.4gl that are in genero_lib1.4gl and changed other
files to call the standard library code.

Revision 1.40  2005/11/14 16:55:31  test4j

Changed to use standard library code.

Revision 1.39  2005/11/04 11:49:04  test4j

splash update again.

Revision 1.38  2005/11/03 14:16:59  test4j

update splash screen

Revision 1.37  2005/10/06 12:51:58  test4j

Added action for generate_sch

Revision 1.36  2005/10/06 12:49:19  test4j

Added generate schema options.

Revision 1.35  2005/10/04 17:02:01  test4j

Added driver, so can load odi driver at runtime.

Revision 1.34  2005/08/05 15:59:36  test4j

new build

Revision 1.34  2005/08/05 16:01:17  test4j

New release and tidied some bits.

Revision 1.33  2005/05/10 14:42:35  test4j

CVS header added.

}

IMPORT os

&include "version.inc"
&include "dbquery.inc"
&include "../lib/genero_lib1.inc"

DEFINE col_typ SMALLINT

--DEFINE lay_n base.Channel
--DEFINE lay_a base.Channel
--------------------------------------------------------------------------------
FUNCTION read_sch(fname)
	DEFINE fname STRING
	DEFINE filename CHAR(80)
	DEFINE ret,x,field_cnt SMALLINT
	DEFINE line STRING
	DEFINE tok base.StringTokenizer
	DEFINE dbpath STRING
	DEFINE sch_fil base.Channel

	CALL tables.clear()
	LET tabs = 0

	LET xml_sch = om.domdocument.create("database")
	LET xml_root = xml_sch.getdocumentelement()
	CALL xml_root.setAttribute("name",db_nam CLIPPED)
	CALL xml_root.setAttribute("schema",fname CLIPPED)
	CALL xml_root.setAttribute("source",db_src CLIPPED)
	CALL xml_root.setAttribute("host",db_hst CLIPPED)
	CALL xml_root.setAttribute("userid",db_usr CLIPPED)
	CALL xml_root.setAttribute("passwd",db_psw CLIPPED)
	CALL xml_root.setAttribute("type",db_typ CLIPPED)

	IF db_nam IS NULL OR db_nam = " " THEN
		LET db_nam = db_sch
	END IF

	IF fname IS NULL OR fname = " " THEN
		DISPLAY "Usage: fglrun dbquery schema-name"
		DISPLAY "NOTE: schema-name without the .sch"
		EXIT PROGRAM
	END IF

	LET dbpath = fgl_getenv("FGLDBPATH")
	LET x = dbpath.getIndexOf(fgl_file_pathseperator(),2)
	IF x > 0 THEN
		LET dbpath = dbpath.subString(1,x-1)
	END IF
	IF dbpath.getLength() > 0 THEN
		LET filename = dbpath || fgl_file_seperator() || fname CLIPPED,".sch"
	ELSE
		LET filename = fname CLIPPED,".sch"
	END IF
	GL_DBGMSG(2,"Reading Schema '"||filename CLIPPED||"'")

	WHENEVER ERROR CONTINUE
	LET sch_fil = base.Channel.create()
	CALL sch_fil.openfile(filename,"r")
	IF STATUS != 0 THEN
		LET filename = "./" || fname CLIPPED,".sch"
		GL_DBGMSG(0,"Failed, Trying:"||filename CLIPPED)
		CALL sch_fil.openfile( filename,"r")
		IF STATUS != 0 THEN
			DISPLAY "Unable to open schema file:",filename CLIPPED
			EXIT PROGRAM
		END IF
	END IF
	WHENEVER ERROR STOP
	LET ret = 1
	WHILE ret = 1
		LET ret = sch_fil.read( line )
		IF ret = 1 THEN
			LET tok = base.StringTokenizer.create( line, "^" )
			LET field_cnt = 1
			WHILE tok.hasMoreTokens()
				IF NOT build_arrays(field_cnt,tok.nextToken()) THEN
					EXIT WHILE
				END IF
				LET field_cnt = field_cnt + 1
			END WHILE
		END IF
	END WHILE
	CALL sch_fil.close()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION build_arrays(field_cnt,data) -- Called from read_Sch
	DEFINE data STRING
	DEFINE len,wh,dec,field_cnt SMALLINT
	
	CASE field_cnt
		WHEN 1 
			IF chk_tab(data.trim()) THEN
				IF tabs > 0 THEN 
					IF data = tables[tabs].tabname THEN
						EXIT CASE
					END IF
				END IF
				LET tabs = tabs + 1
				LET tables[tabs].tabname = data
				IF xml_tab IS NOT NULL THEN
					 CALL xml_tab.setattribute("no_of_cols",cols CLIPPED)
				END IF
				LET xml_tab = xml_root.createchild("table")
				CALL xml_tab.setattribute("name",tables[tabs].tabname CLIPPED)
				LET cols = 0
			ELSE
				RETURN FALSE
			END IF
		WHEN 2
			LET cols = cols + 1
			LET xml_col = xml_tab.createchild("column")
			CALL xml_col.setattribute("name",data CLIPPED)
		WHEN 3
			LET col_typ = data
			IF col_typ > 255 THEN
				LET col_typ = col_typ - 256
				CALL xml_col.setattribute("nulls",1)
			ELSE
				CALL xml_col.setattribute("nulls",0)
			END IF
			CALL xml_col.setattribute("type2",col_typ CLIPPED)
		WHEN 4
			LET len = data
			CALL xml_col.setattribute("type",conv_type(col_typ,len) CLIPPED)
			CALL xml_col.setattribute("length",data CLIPPED)
			CASE col_typ
				WHEN 1
					LET len = 5
				WHEN 2
					LET len = 10
				WHEN 6
					LET len = 10
				WHEN 7
					LET len = 10
				WHEN 10 
					LET len = 30
				WHEN 14 
					LET len = 30
			END CASE

			IF col_typ = 5 OR col_typ = 8 THEN
	 			LET wh = len / 256
	 			LET dec = len - ( wh * 256 )
				IF dec = 255 THEN LET dec = -1 END IF
				LET len = wh+1+dec
			END IF
			CALL xml_col.setattribute("collen",len CLIPPED)
	END CASE
	IF xml_tab IS NOT NULL THEN
		CALL xml_tab.setattribute("no_of_cols",cols CLIPPED)
	END IF
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION chk_tab( tabname )
	DEFINE tabname STRING

	CASE tabname
 		WHEN " GL_COLLATE" RETURN FALSE
 		WHEN " GL_CTYPE" RETURN FALSE
 		WHEN " VERSION" RETURN FALSE
		WHEN "sysblobs" RETURN FALSE
		WHEN "syschecks" RETURN FALSE
		WHEN "syscolauth" RETURN FALSE
		WHEN "syscoldepend" RETURN FALSE
		WHEN "syscolumns" RETURN FALSE
		WHEN "sysconstraints" RETURN FALSE
		WHEN "syscoval" RETURN FALSE
		WHEN "sysdefaults" RETURN FALSE
		WHEN "sysdepend" RETURN FALSE
		WHEN "sysdistrib" RETURN FALSE
		WHEN "sysfragauth" RETURN FALSE
		WHEN "sysfragments" RETURN FALSE
		WHEN "sysglobval" RETURN FALSE
		WHEN "sysindexes" RETURN FALSE
		WHEN "sysobjstate" RETURN FALSE
		WHEN "sysopclstr" RETURN FALSE
		WHEN "sysprocauth" RETURN FALSE
		WHEN "sysprocbody" RETURN FALSE
		WHEN "sysprocedures" RETURN FALSE
		WHEN "sysprocplan" RETURN FALSE
		WHEN "sysreferences" RETURN FALSE
		WHEN "sysroleauth" RETURN FALSE
		WHEN "syssynonyms" RETURN FALSE
		WHEN "syssyntable" RETURN FALSE
		WHEN "systabauth" RETURN FALSE
		WHEN "systables" RETURN FALSE
		WHEN "systabval" RETURN FALSE
		WHEN "systrigbody" RETURN FALSE
		WHEN "systriggers" RETURN FALSE
		WHEN "sysusers" RETURN FALSE
		WHEN "sysviews" RETURN FALSE
		WHEN "sysviolations" RETURN FALSE

		OTHERWISE
			RETURN TRUE
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_db_list()
	DEFINE x SMALLINT
	DEFINE dbpath, path STRING
	DEFINE d SMALLINT

	LET dbpath = fgl_getenv("FGLDBPATH")
	GL_DBGMSG(0,"Looking schema files in '"||dbpath||"'")
	LET x = dbpath.getIndexOf(fgl_file_pathseperator(),2)
	IF x > 0 THEN
		LET dbpath = dbpath.subString(1,x-1)
	END IF

	CALL os.Path.dirSort( "name", 1 )
	LET d = os.Path.dirOpen( dbpath )
	IF d > 0 THEN
		CALL db_arr.clear()
		WHILE TRUE
			LET path = os.Path.dirNext( d )
			IF path IS NULL THEN EXIT WHILE END IF
			IF os.path.extension( path ) = "sch" THEN
				LET db_arr[db_arr.getLength()+1] = os.path.rootname(path)
			END IF
		END WHILE
		LET db_cnt = db_arr.getLength()
	END IF

	IF db_cnt = 0 THEN
		GL_DBGMSG(0,"No schema files found in '"||dbpath||"'")
		CALL gl_winMessage("Error", "No schema files found in '"||dbpath||"'", "exclamation")
		RETURN FALSE
	ELSE
		GL_DBGMSG(0,"Schema files found:"||db_cnt)
	END IF
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION choose_db()
	DEFINE ret SMALLINT
	DEFINE win, frm, grid, lb, edit, ff om.DomNode
	DEFINE cb ui.ComboBox
	DEFINE l_db_nam, l_db_drv, l_db_sch,l_db_usr,
					l_db_psw,l_db_src,l_db_hst,
					l_tabnam CHAR(20)

	IF db_cnt = 0 THEN
		IF NOT get_db_list() THEN
			RETURN FALSE
		END IF
	END IF

	OPEN WINDOW choosedb AT 1,1 WITH 1 ROWS, 20 COLUMNS
	LET win = gl_getWinNode(NULL)
	CALL win.setAttribute("style","dialog")
	CALL win.setAttribute("text","DBQuery "||gl_verFmt(gl_version)||"("||gl_build||")")

	LET frm = gl_genForm( "dbsel" )
	LET grid = frm.createChild('Grid')
	CALL grid.setAttribute("height","8")
	CALL grid.setAttribute("width","25")

	ADDFLD("Schema",1,"l_db_sch","ComboBox",20)
	ADDFLD("Driver",2,"l_db_drv","ComboBox",20)
	ADDFLD("Database",3,"l_db_nam","Edit",20)
	ADDFLD("Host",4,"l_db_hst","Edit",20)
	ADDFLD("Source",5,"l_db_src","Edit",20)
	ADDFLD("User Id",6,"l_db_usr","Edit",20)
	ADDFLD("Password",7,"l_db_psw","Edit",20)
	ADDFLD("Start Table",8,"l_tabnam","Edit",20)

	LET cb = ui.ComboBox.forName("l_db_sch")
	FOR ret = 1 TO db_cnt
		CALL cb.addItem(db_arr[ret] CLIPPED,db_arr[ret] CLIPPED)
	END FOR
	LET cb = ui.ComboBox.forName("l_db_drv")
	CALL find_drivers(cb)

	LET db_src = FGL_GETENV("ANTS_DSN")
	IF db_src IS NOT NULL THEN
		LET db_drv = "dbmads381"
	END IF

	LET l_db_sch = db_sch
	LET l_db_nam = db_sch
	LET l_db_hst = db_hst
	LET l_db_drv = db_drv
	IF db_hst IS NULL OR db_hst = " " THEN
		LET l_db_hst = "localhost"
	END IF
	LET l_db_src = db_src
	LET l_db_usr = db_usr
	IF l_db_usr IS NULL OR l_db_usr = " " THEN
		LET l_db_usr = fgl_getenv("LOGNAME")
		IF l_db_usr IS NULL OR l_db_usr = " " THEN
			LET l_db_usr = fgl_getenv("USERNAME")
		END IF
	END IF
	LET l_db_psw = db_psw
	LET l_tabnam = sel_tabname
		
	LET int_flag = FALSE
	INPUT BY NAME l_db_sch,	
								l_db_drv, 
								l_db_nam, 
								l_db_hst, 
								l_db_src,
								l_db_usr,	
								l_db_psw, 
								l_tabnam
						WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
		ON CHANGE l_db_sch
			IF NOT field_touched(l_db_nam) THEN LET l_db_nam = l_db_sch END IF
		ON CHANGE l_db_drv
			IF l_db_drv = "dbmads381" THEN 
				LET l_db_src = FGL_GETENV("ANTS_DSN") 
				LET l_db_usr = l_db_sch
				LET l_db_psw = l_db_sch
			END IF
		ON ACTION generate_sch
			LET db_nam = l_db_nam
			LET db_sch = l_db_sch
			LET db_drv = l_db_drv
			LET db_hst = l_db_hst
			LET db_src = l_db_src
			LET db_usr = l_db_usr
			LET db_psw = l_db_psw
			IF generate_sch() THEN
				LET l_db_sch = l_db_nam
				EXIT INPUT
			END IF
		AFTER FIELD l_db_psw
			NEXT FIELD l_db_nam
	END INPUT
	IF l_db_nam IS NULL OR l_db_nam = " " THEN
		LET l_db_nam = l_db_sch
	END IF
	IF l_db_sch IS NULL OR l_db_sch = " " THEN
		LET l_db_sch = l_db_nam
	END IF

	CLOSE WINDOW choosedb
		
	IF int_flag THEN
		RETURN FALSE
	ELSE
		LET db_nam = l_db_nam
		LET db_sch = l_db_sch
		LET db_drv = l_db_drv
		LET db_hst = l_db_hst
		LET db_src = l_db_src
		LET db_usr = l_db_usr
		LET db_psw = l_db_psw
	END IF
	IF db_hst IS NOT NULL
	AND db_hst != " "
	AND db_hst != "localhost" THEN
		LET db_nam = db_nam CLIPPED,"@",db_hst
	END IF
	IF db_src IS NOT NULL
	AND db_src != " "
	AND db_src != "localhost" THEN
		LET db_nam = db_nam CLIPPED,"@",db_src
	END IF
	
	IF db_sch IS NOT NULL AND db_sch != " " THEN
		CALL read_sch(db_sch)
	END IF
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION conv_type(typ,len)
	DEFINE typ SMALLINT
	DEFINE len,len2,si INTEGER
	DEFINE ctyp CHAR(40)
	DEFINE tmp,tmp2 DECIMAL(8,2)
	
	CASE typ
		WHEN 0
			LET ctyp = "CHAR(",len USING "<<<<<",")"
		WHEN 1
			LET ctyp = "SMALLINT"
		WHEN 2
			LET ctyp = "INTEGER"
		WHEN 3
			LET ctyp = "FLOAT"
		WHEN 4
			LET ctyp = "SMALLFLOAT"
		WHEN 6
			LET ctyp = "SERIAL"
		WHEN 5
			LET len2 = len
			LET si = len / 256
			LET len = len - ( si * 256 )
			IF len = 255 THEN
				LET ctyp = "INTEGER"
			ELSE
				LET ctyp = "DECIMAL(",si USING "<<<<",",",len USING "<<<<&",")"
			END IF
		WHEN 7
			LET ctyp = "DATE"
		WHEN 8
			LET si = len / 256
			LET len = len - ( si * 256 )
			LET ctyp = "MONEY(",si USING "<<<<",",",len USING "<<<<&",")"
		WHEN 10
			LET ctyp = "DATETIME"
			LET tmp = len MOD 16
			LET tmp2 = ((len - tmp) MOD 256 ) / 16
			CASE tmp2
				WHEN	0 LET ctyp = ctyp CLIPPED," YEAR TO"
				WHEN	2 LET ctyp = ctyp CLIPPED," MONTH TO"
				WHEN	4 LET ctyp = ctyp CLIPPED," DAY TO"
				WHEN	6 LET ctyp = ctyp CLIPPED," HOUR TO"
				WHEN	8 LET ctyp = ctyp CLIPPED," MINUTE TO"
				WHEN 10 LET ctyp = ctyp CLIPPED," SECOND TO"
				OTHERWISE
				LET ctyp = ctyp CLIPPED," 2(",tmp2,")"
			END CASE
			CASE tmp
				WHEN	0 LET ctyp = ctyp CLIPPED," YEAR"
				WHEN	2 LET ctyp = ctyp CLIPPED," MONTH"
				WHEN	4 LET ctyp = ctyp CLIPPED," DAY"
				WHEN	6 LET ctyp = ctyp CLIPPED," HOUR"
				WHEN	8 LET ctyp = ctyp CLIPPED," MINUTE"
				WHEN 10 LET ctyp = ctyp CLIPPED," SECOND"
				WHEN 15 LET ctyp = ctyp CLIPPED," FRACTION(5)"
				OTHERWISE
				LET ctyp = ctyp CLIPPED," (",tmp,")"
			END CASE
		WHEN 11
			LET ctyp = "TEXT"
		WHEN 12
			LET ctyp = "BYTE"
		WHEN 13
			LET ctyp = "VARCHAR(",len USING "<<<<<",")"
		WHEN 14
			LET ctyp = "INTERVAL"
			LET tmp = len MOD 16
			LET tmp2 = ((len - tmp) MOD 256 ) / 16
			DISPLAY "Len:",len, " tmp:",tmp, " tmp2:",tmp2
			CASE tmp2
				WHEN	0 LET ctyp = ctyp CLIPPED," YEAR TO"
				WHEN	2 LET ctyp = ctyp CLIPPED," MONTH TO"
				WHEN	4 LET ctyp = ctyp CLIPPED," DAY(4) TO"
				WHEN	6 LET ctyp = ctyp CLIPPED," HOUR TO"
				WHEN	8 LET ctyp = ctyp CLIPPED," MINUTE TO"
				WHEN 10 LET ctyp = ctyp CLIPPED," SECOND TO"
			END CASE
			CASE tmp
				WHEN	0 LET ctyp = ctyp CLIPPED," YEAR"
				WHEN	2 LET ctyp = ctyp CLIPPED," MONTH"
				WHEN	4 LET ctyp = ctyp CLIPPED," DAY"
				WHEN	6 LET ctyp = ctyp CLIPPED," HOUR"
				WHEN	8 LET ctyp = ctyp CLIPPED," MINUTE"
				WHEN 10 LET ctyp = ctyp CLIPPED," SECOND"
				WHEN 15 LET ctyp = ctyp CLIPPED," FRACTION(5)"
				OTHERWISE
				LET ctyp = ctyp CLIPPED," (",tmp,")"
			END CASE
	END CASE

	RETURN ctyp

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_startmenu( root )
	DEFINE root, sm, smg,smg2, smc om.domNode

	LET sm = root.createChild('StartMenu')
	CALL sm.setAttribute("text","mystarmenu")
	CALL sm.setAttribute("fileName","no file")

	LET smg = sm.createChild('StartMenuGroup')
	CALL smg.setAttribute("text","Programs")

	LET smg2 = smg.createChild('StartMenuGroup')
	CALL smg2.setAttribute("text","Maintenance Programs")
	LET smc = smg2.createChild('StartMenuCommand')
	CALL smc.setAttribute("text","Customer Maint")
	CALL smc.setAttribute("exec","fglrun gcust.42r")
	LET smc = smg2.createChild('StartMenuCommand')
	CALL smc.setAttribute("text","Product Maint")
	CALL smc.setAttribute("exec","fglrun gprod.42r")

	LET smg2 = smg.createChild('StartMenuGroup')
	CALL smg2.setAttribute("text","Utils")
	LET smc = smg2.createChild('StartMenuCommand')
	CALL smc.setAttribute("text","DBQuery")
	CALL smc.setAttribute("exec","cd ../dbquery/make run")

	LET smg = sm.createChild('StartMenuGroup')
	CALL smg.setAttribute("text","Help")
	LET smc = smg.createChild('StartMenuCommand')
	CALL smc.setAttribute("text","About")
	CALL smc.setAttribute("exec","fglrun about.42r")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_topmenu( frm, extra, notb )
	DEFINE frm, tm, tmg, tmc om.DomNode
	DEFINE extra, notb SMALLINT

	LET tm = frm.createChild('TopMenu')
	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","file")
	CALL tmg.setAttribute("text","File")

	IF extra = 3 THEN -- sqlfe
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"open","","Open","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"save","","Save as","" )
		LET tmc = tmg.createChild('TopMenuSeparator')
	END IF

	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"exit","","Exit","" )

	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","Edit")
	CALL tmg.setAttribute("text","Edit")
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"editcut","","Cut","cut" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"editcopy","","Copy","copy" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"editpaste","","Paste","paste" )

	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","view")
	CALL tmg.setAttribute("text","View")
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL tmc.setAttribute("name","notb")
	CALL tmc.setAttribute("text","Toolbar")
	IF notb THEN
		CALL tmc.setAttribute("image","hook")
	ELSE
		CALL tmc.setAttribute("image","delete")
	END IF

	IF extra THEN
		LET tmg = tm.createChild('TopMenuGroup')
		CALL tmg.setAttribute("name","extra")
		CALL tmg.setAttribute("text","Database")
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"sql","","Sql","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"writesch","","Write XML Schema","export" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"opendb","","Open Database","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"closedb","","Close Database","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"chgdb","","Change Database","" )
	END IF

	IF extra = 2 THEN
		LET tmg = tm.createChild('TopMenuGroup')
		CALL tmg.setAttribute("name","extra")
		CALL tmg.setAttribute("text","Table")
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"listview","","List View","printer" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"writeform","","Write Form","" )
		LET tmc = tmg.createChild('TopMenuSeparator')
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"addtab","","Add Table","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"altertab","","Alter Table","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"droptab","","Drop Table","" )

		LET tmg = tm.createChild('TopMenuGroup')
		CALL tmg.setAttribute("name","schema")
		CALL tmg.setAttribute("text","Schema")
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"schema_t","","In a Table","" )
		LET tmc = tmg.createChild('TopMenuCommand')
		CALL setVal( tmc,"schema_e","","In TextEdit","" )
	END IF

	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","help")
	CALL tmg.setAttribute("text","Help")
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"help","","Help","" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"about","","About","" )

	RETURN tm

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_toolbar( root, ccp, extra )
	DEFINE root, tb, tbi om.domNode
	DEFINE ccp,extra SMALLINT

	GL_DBGMSG(2,"Building Toolbar")

	LET tb = root.createChild('ToolBar')
	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"exit","","Exit","exit" )

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"accept","","Accept","accept" )

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"cancel","","Cancel","cancel" )

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"query","","Query","find" )

	CALL tbi.setAttribute("comment","Exit")
	IF extra = 3 THEN -- sqlfe
		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"open","","Open","open" )
		CALL tbi.setAttribute("comment","Open a SQL file")
		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"save","","Save As","disk" )
		CALL tbi.setAttribute("comment","Save a SQL file")
	END IF

	IF ccp THEN
		LET tbi = tb.createChild('ToolBarSeparator')

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"editcut","","Cut","cut" )
		CALL tbi.setAttribute("comment","Cut")
	
		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"editcopy","","Copy","copy" )
		CALL tbi.setAttribute("comment","copy")
	
		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"editpaste","","Paste","paste" )
		CALL tbi.setAttribute("comment","Paste")
	END IF

	IF extra = 1 THEN
		LET tbi = tb.createChild('ToolBarSeparator')

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"first","","First","first" )
		CALL tbi.setAttribute("comment","Go First Record")

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"previous","","Previous","prev" )
		CALL tbi.setAttribute("comment","Go Previous Record")

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"next","","Next","next" )
		CALL tbi.setAttribute("comment","Go Next Record")

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"last","","Last","last" )
		CALL tbi.setAttribute("comment","Go Last Record")
	END IF

	IF extra = 2 THEN
		LET tbi = tb.createChild('ToolBarSeparator')

		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"sql","","Sql","" )
		CALL tbi.setAttribute("comment","Sql Front End")
	
		LET tbi = tb.createChild('ToolBarSeparator')
	
		LET tbi = tb.createChild('ToolBarItem')
		CALL setVal( tbi,"writesch","","XML Schema","" )
		CALL tbi.setAttribute("comment","Write a XML Schema")
	END IF

	RETURN tb

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_defaults( root )
	DEFINE root, nod om.domNode
	DEFINE found_ad SMALLINT

	LET found_ad = FALSE
	LET nod = root.getFirstChild()
	WHILE TRUE
		IF nod IS NULL THEN RETURN END IF
		GL_DBGMSG(2,"Building "||nod.getTagName())
		CASE nod.getTagName() 
			WHEN "StyleList"
				CALL create_styles( nod )
			WHEN "ActionDefaultList"
				LET found_ad = TRUE
				CALL create_actions( nod )
		END CASE
		LET nod = nod.getNext()
	END WHILE
	IF NOT found_ad THEN
		LET nod = root.getFirstChild()
		LET nod = nod.createChild("ActionDefaultList")
		CALL create_actions( nod )
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_styles( sl )
	DEFINE sl, s, sa om.domNode
	DEFINE nl om.NodeList

-- mywin
	LET s = sl.createChild('Style')
	CALL s.setAttribute("name","Window.mywin")
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"windowType","normal","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"actionPanelPosition","bottom","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"ringMenuPosition","bottom","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"toolBarPosition","top","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"startMenuPosition","none","","" )

-- about
	LET s = sl.createChild('Style')
	CALL s.setAttribute("name",".about")
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"backgroundColor","#FFFFFF","","" )

-- Table
	LET s = sl.createChild('Style')
	CALL s.setAttribute("name","Table")
	LET sa = s.createChild('StyleAttribute')
	CALL sa.setAttribute("name","backgroundImage")
--	CALL sa.setAttribute("value","\\fourjs\\pics\\fourjs_watermark.jpg")
	LET sa = s.createChild('StyleAttribute')
--	CALL setVal( sa,"backgroundColor","white","","" )

-- Table Title 
	LET s = sl.createChild('Style')
	CALL s.setAttribute("name",".tabtitl")
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"textColor","darkblue","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"fontSize","12pt","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"fontWeight","bold","","" )

-- Copyright Message
	LET s = sl.createChild('Style')
	CALL s.setAttribute("name",".copyright")
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"font","Comic Sans MS","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"fontSize","14pt","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"fontStyle","italic","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"textColor","darkred","","" )

-- dialog
	LET nl = sl.selectByPath("//Style[@name='Window.dialog']")
	IF nl.getLength() > 0 THEN
		LET s = nl.item(1)
		LET sa = s.GetFirstChild()
		WHILE sa IS NOT NULL
			CALL s.removeChild( sa )
			LET sa = s.GetFirstChild()
		END WHILE
	ELSE
		GL_DBGMSG(2,"Failed to find entry in StyleList for Window.dialog!")
		LET s = sl.createChild('Style')
		CALL s.setAttribute("name","Window.dialog")
	END IF
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"windowType","modal","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"actionPanelPosition","bottom","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"ringMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"startMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"toolBarPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"defaultStatusBar","0","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"position","center","","" )

-- naked
	LET nl = sl.selectByPath("//Style[@name='Window.naked']")
	IF nl.getLength() > 0 THEN
		LET s = nl.item(1)
		LET sa = s.GetFirstChild()
		WHILE sa IS NOT NULL
			CALL s.removeChild( sa )
			LET sa = s.GetFirstChild()
		END WHILE
	ELSE
		GL_DBGMSG(2,"Failed to find entry in StyleList for Window.naked!")
		LET s = sl.createChild('Style')
		CALL s.setAttribute("name","Window.naked")
	END IF
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"position","center","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"border","tool","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"windowType","modal","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"actionPanelPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"ringMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"startMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"toolBarPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"defaultStatusBar","0","","" )

-- splash
	LET nl = sl.selectByPath("//Style[@name='Window.splash']")
	IF nl.getLength() > 0 THEN
		LET s = nl.item(1)
		LET sa = s.GetFirstChild()
		WHILE sa IS NOT NULL
			CALL s.removeChild( sa )
			LET sa = s.GetFirstChild()
		END WHILE
	ELSE
		GL_DBGMSG(2,"Failed to find entry in StyleList for Window.splash!")
		LET s = sl.createChild('Style')
		CALL s.setAttribute("name","Window.splash")
	END IF
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"position","center","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"border","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"windowType","modal","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"actionPanelPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"ringMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"startMenuPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"toolBarPosition","none","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"defaultStatusBar","0","","" )
	LET sa = s.createChild('StyleAttribute')
	CALL setVal( sa,"backgroundColor","#DDDDFF","","" )

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION create_actions( adl )
	DEFINE adl, ad om.domNode

	LET ad = adl.GetFirstChild()
	WHILE ad IS NOT NULL
		CALL adl.removeChild( ad )
		LET ad = adl.GetFirstChild()
	END WHILE

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"accept","","OK","accept" )
	CALL ad.setAttribute("acceleratorName","Return")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"cancel","","Cancel","cancel" )
	CALL ad.setAttribute("acceleratorName","Escape")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"close","","Close","cancel" )
	CALL ad.setAttribute("acceleratorName","Escape")
	CALL ad.setAttribute("defaultView","no")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"quit","","Exit","uplevel" )
	CALL ad.setAttribute("acceleratorName","Escape")
	
	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"listview","","ListView","" )
	CALL ad.setAttribute("acceleratorName","f9")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"list","","ShowList","" )
	CALL ad.setAttribute("acceleratorName","Return")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"gen_rpt","","Report","" )
	CALL ad.setAttribute("acceleratorName","Return")
	
	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"query","","Query","find" )
	CALL ad.setAttribute("acceleratorName","f4")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"sql","","Sql","smiley" )
	CALL ad.setAttribute("acceleratorName","f5")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"copy","","Copy","copy" )
	CALL ad.setAttribute("acceleratorName","alt-c")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"clear","","Clear","garbage" )
	CALL ad.setAttribute("acceleratorName","Backspace")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"default","","Default","wizard" )
	CALL ad.setAttribute("acceleratorName","Space")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"writesch","","Write XML Schema","export" )
	CALL ad.setAttribute("acceleratorName","w")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"opendb","","Open Database","" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"closedb","","Close Database","" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"chgdb","","Change Database","" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"gen_rpt","","Report","printer" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"prn_cli","","Print Client","printer" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"all_recs","","All Records","smiley" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"update","","","" )
	CALL ad.setAttribute("acceleratorName","f12")

-- Sqlfe
	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"open","","Open","fileopen" )
	CALL ad.setAttribute("acceleratorName","control-o")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"save","","Save","disk" )
	CALL ad.setAttribute("acceleratorName","control-s")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"exesql","","Execute","services" )
	CALL ad.setAttribute("acceleratorName","f5")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"presql","","Prepare","circle" )
	CALL ad.setAttribute("acceleratorName","f6")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"clrsql","","Clear Sql","new" )
	CALL ad.setAttribute("acceleratorName","f7")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"clrdbg","","Clear Debug","new" )
	CALL ad.setAttribute("acceleratorName","f8")

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"hdedbg","","Hide Debug","debug_logo" )

	LET ad = adl.createChild('ActionDefault')
	CALL setVal( ad,"generate_sch","","Create Schema","" )

	CALL adl.writeXml("my.4ad")
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setVal( nd,nm,vl,tx,im )
	DEFINE nd om.DomNode
	DEFINE nm,vl,tx,im STRING

--	DISPLAY "act:",nm
	CALL nd.setAttribute("name",nm)
	IF vl IS NOT NULL THEN CALL nd.setAttribute("value",vl) END IF
	IF tx IS NOT NULL THEN CALL nd.setAttribute("text",tx) END IF
	IF im IS NOT NULL THEN CALL nd.setAttribute("image",im) END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION file_acc(mode,srv_cli,ext,titl)
	DEFINE mode STRING
	DEFINE srv_cli SMALLINT -- TRUE srv / FALSE cli
	DEFINE ext STRING
	DEFINE titl STRING
	DEFINE fn STRING
	
	LET int_flag = FALSE
	IF srv_cli THEN
--		PROMPT "Enter file name (without ."||ext||" extension):" FOR fn
		LET fn = file_lst(mode,ext)
		IF int_flag OR fn IS NULL OR fn = " " THEN
			MESSAGE "Cancelled!"
			RETURN NULL
		END IF
		LET fn = fn.append("."||ext)
		IF mode = "savefile" THEN
			DISPLAY "file_acc: save file as '"||fn||"'"
		ELSE
			DISPLAY "file_acc: load file '"||fn||"'"
		END IF
	ELSE
		CALL ui.Interface.frontCall( "standard", mode, ["c:\\",titl,ext,"Save"], [fn] )
		DISPLAY "file_acc: filename:",fn.trim()
		IF mode = "savefile" THEN
			LET fn = ext||fgl_getpid()||"."||ext
			-- Need to rcp file to client
		ELSE
			-- Need to rcp file from client
		END IF
	END IF
	
	RETURN fn

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION file_lst(mode,ext)
	DEFINE mode,ext,fn STRING
	DEFINE win, frm, vbox, grid, lb, edit, ff, tabl, tabc om.DomNode
	DEFINE files DYNAMIC ARRAY OF RECORD
		filname STRING,
		fildate STRING
	END RECORD
	DEFINE fil_cnt, x, y, sp, ret SMALLINT
	DEFINE dir,cmd,line STRING
	DEFINE fil_pip base.Channel
	DEFINE tok base.StringTokenizer

	OPEN WINDOW file_choose AT 1,1 WITH 1 ROWS, 20 COLUMNS
	LET win = gl_getWinNode(NULL)
	CALL win.setAttribute("style","dialog")
	CALL win.setAttribute("text","DBQuery "||gl_verFmt(gl_version)||"("||gl_build||")")

	LET frm = gl_genForm( "file_choose" )
  LET vbox = frm.createChild('VBox')

	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("height","2")
	CALL grid.setAttribute("width","40")
	ADDFLD("Directory:",1,"dir","Edit",40)

  LET tabl = vbox.createChild('Table')
  CALL tabl.setAttribute("tabName","files")
  CALL tabl.setAttribute("width",30)
  CALL tabl.setAttribute("height","20")
  CALL tabl.setAttribute("pageSize","10")
  CALL tabl.setAttribute("size","10")
  LET tabc = tabl.createChild('TableColumn')
  CALL tabc.setAttribute("colName","filname")
  LET edit = tabc.createChild('Edit')
  CALL tabc.setAttribute("text","Name")
  CALL edit.setAttribute("width",15)
  LET tabc = tabl.createChild('TableColumn')
  CALL tabc.setAttribute("colName","fildate")
  LET edit = tabc.createChild('Edit')
  CALL tabc.setAttribute("text","Date")
  CALL edit.setAttribute("width",12)

	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("height","2")
	CALL grid.setAttribute("width","40")
	ADDFLD("File name",1,"fn","Edit",20)

	LET dir = fgl_getenv("PWD")

	LET cmd = "ls -l *."||ext

	LET fil_pip = base.Channel.create()
	LET fil_cnt = 1
	CALL fil_pip.openpipe( cmd ,"r")
	LET ret = 1
	WHILE ret = 1
		LET ret = fil_pip.read( line )
		IF ret = 1 THEN
			LET tok = base.StringTokenizer.create(line,"/")
			WHILE tok.hasMoreTokens()
				LET line = tok.nextToken()
			END WHILE
			LET x = line.getIndexOf(".",1)
			LET sp = 0
			FOR y = x TO 1 STEP -1
				IF line.subString(y,y) = " " THEN
					LET sp = sp + 1
					IF sp = 1 THEN
						LET files[fil_cnt].filname = line.subString(y+1,x-1)
						LET x = y-1
					END IF
					IF sp = 4 THEN
						LET files[fil_cnt].fildate = line.subString(y,x)
						EXIT FOR
					END IF
				END IF
			END FOR
			LET fil_cnt = fil_cnt + 1
		END IF
	END WHILE
	LET fil_cnt = fil_cnt - 1

	DISPLAY BY NAME dir
	LET int_flag = FALSE
	LET fn = NULL
	IF fil_cnt > 0 THEN
		DISPLAY ARRAY files TO files.* ATTRIBUTE(COUNT=fil_cnt)
			BEFORE DISPLAY
				IF mode = "savefile" THEN EXIT DISPLAY END IF
		END DISPLAY
		IF NOT int_flag THEN
			LET fn = files[arr_curr()].filname
		END IF
		LET int_flag = FALSE
	END IF

	IF mode = "savefile" THEN
		INPUT BY NAME fn
	END IF
	
	CLOSE WINDOW file_choose
	
	RETURN fn

END FUNCTION
--------------------------------------------------------------------------------
-- Title a window
FUNCTION win_title(desc, tab)
	DEFINE desc, tab, win_title STRING

	LET win_title = "DBQuery "||gl_verFmt(gl_version)||"("||gl_build||") ",desc.trim(),
									"  DB: ",UPSHIFT(db_nam CLIPPED),"(",db_stat,") Type:",db_typ
	IF tab IS NOT NULL THEN
		LET win_title = win_title.append(" Table:"||tab.trim())
	END IF
	RETURN win_title
END FUNCTION
--------------------------------------------------------------------------------
-- find dbm drivers
FUNCTION find_drivers( cb )
	DEFINE cb ui.ComboBox
	DEFINE dbd_pip base.channel
	DEFINE ret,x,gotone SMALLINT
	DEFINE line STRING
	DEFINE list DYNAMIC ARRAY OF STRING

--	CALL cb.AddItem("dbmifx930","Informix 9.30")

	LET dbd_pip = base.Channel.create()
	CALL dbd_pip.openpipe( "cd $FGLDIR/dbdrivers; ls -1 dbm*.so","r")
	LET ret = TRUE
	LET gotone = FALSE
	WHILE ret
		LET ret = dbd_pip.read( line )
		IF ret THEN
			LET x = line.getIndexOf(".",1)
			LET line = line.subString(1,x-1)
			CALL cb.AddItem( line.trim(),line.trim() )
			LET gotone = TRUE
		END IF
	END WHILE
	CALL dbd_pip.close()

	IF NOT gotone THEN
		LET list[ list.getLength() + 1 ] = "dbmads380"
		LET list[ list.getLength() + 1 ] = "dbmads381"
		LET list[ list.getLength() + 1 ] = "dbmasa8x"
		LET list[ list.getLength() + 1 ] = "dbmdb27x"
		LET list[ list.getLength() + 1 ] = "dbmdb28x"
		LET list[ list.getLength() + 1 ] = "dbmdb29x"
		LET list[ list.getLength() + 1 ] = "dbmifx9x"
		LET list[ list.getLength() + 1 ] = "dbmmsv80"
		LET list[ list.getLength() + 1 ] = "dbmmsv90"
		LET list[ list.getLength() + 1 ] = "dbmmsvA0"
		LET list[ list.getLength() + 1 ] = "dbmmys41x"
		LET list[ list.getLength() + 1 ] = "dbmmys50x"
		LET list[ list.getLength() + 1 ] = "dbmmys51x"
		LET list[ list.getLength() + 1 ] = "dbmodc3x"
		LET list[ list.getLength() + 1 ] = "dbmora81x"
		LET list[ list.getLength() + 1 ] = "dbmora90x"
		LET list[ list.getLength() + 1 ] = "dbmora92x"
		LET list[ list.getLength() + 1 ] = "dbmoraA1x"
		LET list[ list.getLength() + 1 ] = "dbmoraA2x"
		LET list[ list.getLength() + 1 ] = "dbmoraB1x"
		LET list[ list.getLength() + 1 ] = "dbmpgs80x"
		LET list[ list.getLength() + 1 ] = "dbmpgs81x"
		LET list[ list.getLength() + 1 ] = "dbmpgs82x"
		LET list[ list.getLength() + 1 ] = "dbmpgs83x"
		LET list[ list.getLength() + 1 ] = "dbmsnc90"
		LET list[ list.getLength() + 1 ] = "dbmsncA0"
		FOR gotone = 1 TO list.getLength()
			CALL cb.AddItem( list[ gotone ].trim(),list[ gotone ].trim() )
		END FOR
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION generate_sch()
	DEFINE cmd CHAR(80)
	DEFINE ret SMALLINT

	LET cmd = "fgldbsch -db ",db_nam CLIPPED,
						" -un ",db_usr CLIPPED, 
						" -up ",db_psw CLIPPED,
						" -ie"
	
	GL_DBGMSG(0,"Running:\n'"||cmd CLIPPED||"'")
	RUN cmd
	GL_DBGMSG(0,"Ret:"||ret)
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION fgl_file_seperator()

	RETURN os.path.separator()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION fgl_file_pathseperator()

	RETURN os.path.pathseparator()

END FUNCTION
--------------------------------------------------------------------------------
