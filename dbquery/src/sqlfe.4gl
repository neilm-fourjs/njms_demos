
{ CVS Header
$Author: test4j $
$Date: 2007/07/12 16:42:43 $
$Revision: 314 $
$Source: /usr/home/test4j/cvs/all/demos/dbquery/src/sqlfe.4gl,v $
$Log: sqlfe.4gl,v $
Revision 1.21  2007/07/12 16:42:43  test4j

Changes for built in precompiler

Revision 1.20  2006/07/21 11:34:25  test4j

restructures make

Revision 1.19  2006/03/13 16:11:26  test4j
*** empty log message ***

Revision 1.18  2006/03/03 17:14:40  test4j

updated library code and changed debug to genero_lib debug.

Revision 1.17  2005/11/14 17:08:23  test4j

remove functions from lib.4gl that are in genero_lib1.4gl and changed other
files to call the standard library code.

Revision 1.16  2005/11/14 16:55:31  test4j

Changed to use standard library code.

Revision 1.15  2005/08/05 15:59:36  test4j

new build

Revision 1.14  2005/05/10 14:42:35  test4j

CVS header added.

}

-- Sql Front End 1.0

&include "dbquery.inc"
&include "../../lib/genero_lib1.inc"
&define SQL_LEN 300

DEFINE sqldbg base.channel
DEFINE sqlfil base.channel
DEFINE fglsqldebug SMALLINT
DEFINE sqldebug STRING
DEFINE sql_sel STRING
DEFINE sql_nocols SMALLINT
DEFINE hdedbg SMALLINT
DEFINE sql_cols DYNAMIC ARRAY OF STRING
DEFINE sql_coll DYNAMIC ARRAY OF SMALLINT
DEFINE sql_cola DYNAMIC ARRAY OF CHAR(1)
DEFINE xml_sql_doc om.DomDocument
DEFINE xml_sql_root om.DomNode
DEFINE xml_sql om.DomNode

--------------------------------------------------------------------------------
FUNCTION sql()
	DEFINE win, frm, vbox, hbox,dbgrid, grid, edit,
				 textedt, ff, tab, tabc	om.DomNode,
					x SMALLINT
	DEFINE sql CHAR(SQL_LEN)
	DEFINE ok SMALLINT

	LET fglsqldebug = FALSE
	LET hdedbg = TRUE
	IF fgl_getenv("FGLSQLDEBUG") > 0 THEN
		LET sqldbg = base.channel.create()
		WHENEVER ERROR CONTINUE
		CALL sqldbg.openfile("sqlfe.dbg","r")
		WHENEVER ERROR STOP
		IF STATUS = 0 THEN
			LET hdedbg = FALSE
			LET fglsqldebug = TRUE
		END IF
		GL_DBGMSG(2,"fglsqldebug="||fglsqldebug)
	END IF

	OPEN WINDOW sql AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode("sql")
	CALL win.setAttribute("style","mywin")
	CALL win.setAttribute("text",win_title("SqlFE",""))
	LET frm = gl_genForm("sqlfe")
	CALL frm.setAttribute("name","sqlfe")
--	CALL frm.setAttribute("text","Sqlfe - Current Database:"||db_nam)

	CALL create_topmenu( frm, 3, 0) RETURNING ff -- create default topmenu
	CALL sql_topmenu( ff ) -- Added extra items
	CALL create_toolbar( frm, TRUE, 3) RETURNING ff		-- create default toolbar
	CALL sql_toolbar( ff ) -- Added extra items

	LET vbox = frm.createChild('VBox')
	CALL vbox.setAttribute("splitter","1")
	LET hbox = vbox.createChild('HBox')
	LET grid = hbox.createChild('Grid')

	CALL grid.setAttribute("height","12")
	LET ff = grid.createChild('FormField')
	CALL ff.setAttribute("colName","sql")
	LET textedt = ff.createChild('TextEdit')
	CALL textedt.setAttribute("height","10")
	CALL textedt.setAttribute("width","40")
	CALL textedt.setAttribute("posX","1")
	CALL textedt.setAttribute("posY","1")
	CALL textedt.setAttribute("fontPitch","fixed")
	CALL textedt.setAttribute("scrollBars","both")
	CALL textedt.setAttribute("stretch","both")

	LET dbgrid = hbox.createChild('Grid')
	CALL dbgrid.setAttribute("hidden",hdedbg)
	CALL dbgrid.setAttribute("height","12")
	LET ff = dbgrid.createChild('FormField')
	CALL ff.setAttribute("colName","sqldebug")
	LET textedt = ff.createChild('TextEdit')
	CALL textedt.setAttribute("height","10")
	CALL textedt.setAttribute("width","40")
	CALL textedt.setAttribute("posX","1")
	CALL textedt.setAttribute("fontPitch","fixed")
	CALL textedt.setAttribute("scrollBars","both")
	CALL textedt.setAttribute("stretch","both")

	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("height","2")
	LET ff = grid.createChild('Label')
	CALL ff.setAttribute("text","Results:")
	LET ff = grid.createChild('FormField')
	CALL ff.setAttribute("colName","results")
	LET textedt = ff.createChild('Edit')
	CALL textedt.setAttribute("width","40")
	CALL textedt.setAttribute("posX","10")
	LET ff = grid.createChild('FormField')
	CALL ff.setAttribute("colName","results2")
	LET textedt = ff.createChild('Edit')
	CALL textedt.setAttribute("width","40")
	CALL textedt.setAttribute("posX","50")

	LET tab = vbox.createChild('Table')
	CALL tab.setAttribute("tabName","results")
	CALL tab.setAttribute("height","10")
	CALL tab.setAttribute("pageSize","10")
	CALL tab.setAttribute("bufferSize","10")
	CALL tab.setAttribute("size","10")
	FOR x = 1 TO 1 -- 100
		LET tabc = tab.createChild('TableColumn')
		CALL tabc.setAttribute("colName","fld"||x)
		CALL tabc.setAttribute("hidden","1")
		LET edit = tabc.createChild('Edit')
		CALL tabc.setAttribute("text","Col"||x)
		CALL edit.setAttribute("width",10)
	END FOR

	LET int_flag = FALSE
	WHILE NOT int_flag
		INPUT BY NAME sql WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
			ON ACTION presql		
				LET ok = pre_sql(sql)
				IF fglsqldebug THEN CALL sql_debug(TRUE) END IF
			ON ACTION exesql		
				IF pre_sql(sql) THEN
					CALL exe_sql(tab)
				END IF
				IF fglsqldebug THEN CALL sql_debug(TRUE) END IF
			ON ACTION clrsql		
				LET sql = NULL
				DISPLAY BY NAME sql

			ON ACTION clrdbg
				LET sqldebug = NULL
				DISPLAY BY NAME sqldebug
			ON ACTION hdedbg
				LET hdedbg = NOT hdedbg
				CALL dbgrid.setAttribute("hidden",hdedbg)

			ON ACTION schema_e
				CALL schema_view("E")
			ON ACTION schema_t
				CALL schema_view("T")

			ON ACTION closedb
				IF NOT close_db() THEN
					DISPLAY "Manual disconnect failed."
				ELSE
					CALL win.setAttribute("text",win_title("SqlFE",""))
				END IF
			ON ACTION opendb
				IF NOT open_db() THEN
					DISPLAY "Manual connect failed."
				ELSE
					CALL win.setAttribute("text",win_title("SqlFE",""))
				END IF
			ON ACTION chgdb
				IF NOT close_db() THEN
					DISPLAY "Manual disconnect failed."
				END IF
				CALL fgl_set_arr_curr(1)
				IF choose_db() THEN
					LET choose_db = TRUE
					MESSAGE "Database changed to "||db_nam
				END IF
				CALL win.setAttribute("text",win_title("SqlFE",""))

			ON ACTION save
				CALL save_sql(sql)
			ON ACTION open
				LET sql = open_sql()
			ON ACTION exit
				LET int_flag = TRUE
				EXIT INPUT
		END INPUT
	END WHILE

	CLOSE WINDOW sql

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION pre_sql(sql)
	DEFINE sql CHAR(200)

	IF sql IS NULL OR sql = " " THEN RETURN FALSE END IF

	IF NOT db_open THEN
		IF NOT open_db() THEN RETURN FALSE END IF
		CALL fgl_settitle(win_title("SqlFE",""))
		IF fglsqldebug THEN CALL sql_debug(FALSE) END IF
	END IF
	
	CALL chk_sql(sql)

	WHENEVER ERROR CONTINUE
	PREPARE sql_pre FROM sql
	WHENEVER ERROR STOP
	IF STATUS = 0 THEN
		DISPLAY "Statement prepared okay" TO results
		RETURN TRUE
	ELSE
		DISPLAY "Statement failed to prepare" TO results
	END IF	
	RETURN FALSE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION exe_sql(tab)
	DEFINE tab om.domnode -- Results table.
	DEFINE sql_ar DYNAMIC ARRAY OF RECORD
			DBQ_REC
		END RECORD
	DEFINE sql_ar_cnt INTEGER
	DEFINE x SMALLINT
	DEFINE titles,lens, align STRING

	GL_DBGMSG(2,"exe_sql - start.")
	WHENEVER ERROR CONTINUE
	IF sql_sel THEN
		LET sql_ar_cnt = 1
		DECLARE sql_dec CURSOR FOR sql_pre 
		IF fglsqldebug THEN CALL sql_debug(FALSE) END IF
		DISPLAY "Reading Data..." TO results2
		CALL ui.interface.refresh()
		FOREACH sql_dec INTO sql_ar[sql_ar_cnt].*
			LET sql_ar_cnt = sql_ar_cnt + 1
		END FOREACH
		LET sql_ar_cnt = sql_ar_cnt - 1
		IF fglsqldebug THEN CALL sql_debug(FALSE) END IF
		IF sql_ar_cnt = 0 THEN
			DISPLAY "No rows found." TO results2
			CALL ui.interface.refresh()
		ELSE
			DISPLAY sql_ar_cnt USING "<<<<<&"||" Rows found." TO results2
			CALL ui.interface.refresh()
			IF sql_nocols > 0 THEN
				LET titles = ""
				FOR x = 1 TO sql_nocols
					LET titles = titles.append(sql_cols[x]||"|")
					LET lens = lens.append(sql_coll[x]||"|")
					LET align = align.append(sql_cola[x]||"|")
				END FOR
				CALL build_tab("sql","results",titles,lens, align)
				GL_DBGMSG(2,"display array - started.")
				DISPLAY ARRAY sql_ar TO results.* ATTRIBUTE(COUNT=sql_ar_cnt)
					BEFORE DISPLAY
						IF sql_ar_cnt < 5 THEN EXIT DISPLAY END IF
				END DISPLAY
				GL_DBGMSG(2,"display array - finished.")
			END IF
		END IF
	ELSE
		EXECUTE sql_pre
	END IF
	WHENEVER ERROR STOP 
	IF STATUS = 0 THEN
		DISPLAY "Statement executed okay" TO results
	ELSE
		DISPLAY "Statement failed to execute" TO results
	END IF	
	GL_DBGMSG(2,"exe_sql - finished.")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sql_debug(cls)
	DEFINE cls SMALLINT
	DEFINE line STRING

	IF hdedbg THEN RETURN END IF
	MESSAGE "Reading Debug file..."
	LET line = sqldbg.readline()
	WHILE line IS NOT NULL
		LET sqldebug = sqldebug.append(line)
		LET line = sqldbg.readline()
		LET sqldebug = sqldebug.append(ASCII(10))
	END WHILE
	DISPLAY BY NAME sqldebug
	MESSAGE "."
	IF cls THEN LET sqldebug = "" END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION chk_sql(sql)
	DEFINE sql CHAR(SQL_LEN)
	DEFINE cols CHAR(200)
	DEFINE x,y,len SMALLINT
	DEFINE str_cols,str_col STRING
	DEFINE tok base.StringTokenizer

	LET sql_sel =	FALSE 
	LET sql = DOWNSHIFT(sql)
	LET sql = normalize_sql(sql) -- Remove ascii 10,13,9 and whitespace
	LET len = LENGTH(sql)

	IF sql[1,6] != "select " THEN
		RETURN
	END IF

	LET sql_sel = TRUE
	LET sql_nocols = 0

	CALL sql_cols.clear()
	CALL sql_coll.clear()
	CALL sql_cola.clear()

	FOR x = 1 TO len
		IF sql[x,x+5] = " from " THEN
			LET cols = sql[8,x]
			FOR y = x+6 TO LENGTH(sql)
				IF sql[y] = " " OR sql[y] = "," THEN EXIT FOR END IF
			END FOR
			CALL fnd_tabs(sql[x+6,len])
		END IF
	END FOR
	IF cols[1,2] = "* " THEN
		LET xml_cols = xml_sql_root.selectbypath("//column")
		LET sql_nocols = xml_cols.getLength()
		FOR x = 1 TO sql_nocols
			LET xml_col = xml_cols.item(x)
			LET sql_cols[x] = xml_col.getAttribute("name")
			LET sql_coll[x] = xml_col.getAttribute("collen")
			LET sql_cola[x] = "L"
			IF xml_col.getAttribute("type2") != "0" THEN
				LET sql_cola[x] = "R"
			END IF
		END FOR
		GL_DBGMSG(2,"chk_sql - xml columns:"||xml_cols.getLength())
	ELSE
		LET str_cols = cols CLIPPED
		LET tok = base.StringTokenizer.create( str_cols, "," )
		WHILE tok.hasMoreTokens()
			LET str_col = tok.nextToken()
			IF str_col IS NULL THEN EXIT WHILE END IF
			LET x = str_col.getIndexOf(".",2)
			IF x > 0 THEN
				LET str_col = str_col.subString(x+1,str_col.getLength())
			END IF
			GL_DBGMSG(2,"column='"||str_col.trim()||"'")
			LET sql_nocols = sql_nocols + 1
			LET xml_col = gl_findXmlCol("",str_col,xml_sql_root)
			IF xml_col IS NOT NULL THEN
				LET sql_cols[sql_nocols] = xml_col.getAttribute("name")
				LET sql_coll[sql_nocols] = xml_col.getAttribute("collen")
				LET sql_cola[sql_nocols] = "L"
				IF xml_col.getAttribute("type2") != "0" THEN
					LET sql_cola[sql_nocols] = "R"
				END IF
			ELSE
				GL_DBGMSG(2,"Column not found in sql schema:"||str_col)
				ERROR "Column not found in sql schema:",str_col
				LET sql_cols[sql_nocols] = str_col
				LET sql_coll[sql_nocols] = 10
				LET sql_cola[sql_nocols] = "L"
			END IF
		END WHILE					
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sql_toolbar( tb )
	DEFINE tb, tbi om.domNode

	LET tbi = tb.createChild('ToolBarSeparator')

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"presql","","Prepare","" )
	CALL tbi.setAttribute("comment","Prepare the statement")
	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"exesql","","Execute","" )
	CALL tbi.setAttribute("comment","Execute the statement")

	LET tbi = tb.createChild('ToolBarSeparator')

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"clrsql","","Clear Sql","" )
	CALL tbi.setAttribute("comment","Clear Sql statement")

	LET tbi = tb.createChild('ToolBarSeparator')

	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"clrdbg","","Clear Debug","" )
	CALL tbi.setAttribute("comment","Clear the debug pane")
	LET tbi = tb.createChild('ToolBarItem')
	CALL setVal( tbi,"hdedbg","","Hide Debug","" )
	CALL tbi.setAttribute("comment","Hide the debug pane")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sql_topmenu( tm )
	DEFINE tm, tmg, tmc om.DomNode

	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","sql")
	CALL tmg.setAttribute("text","Sql")
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"presql","","Prepare","" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"exesql","","Execute","" )
	LET tmc = tmg.createChild('TopMenuSeparator')
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"clrsql","","Clear Sql","" )
	LET tmc = tmg.createChild('TopMenuSeparator')
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"clrdbg","","Clear Debug","" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"hdedbg","","Hide Debug","" )

	LET tmg = tm.createChild('TopMenuGroup')
	CALL tmg.setAttribute("name","schema")
	CALL tmg.setAttribute("text","Schema")
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"schema_t","","In a Table","" )
	LET tmc = tmg.createChild('TopMenuCommand')
	CALL setVal( tmc,"schema_e","","In TextEdit","" )

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION normalize_sql(sql)
	DEFINE sql CHAR(SQL_LEN)
	DEFINE newsql CHAR(SQL_LEN)
	DEFINE x,y SMALLINT
	DEFINE store,first SMALLINT
	
	LET y = 1
	FOR x = 1 TO LENGTH(sql)
		IF sql[x] = ASCII(10) THEN LET sql[x] = ' ' END IF
		IF sql[x] = ASCII(13) THEN LET sql[x] = ' ' END IF
		IF sql[x] = ASCII( 9) THEN LET sql[x] = ' ' END IF
	END FOR
	LET first = FALSE
	FOR x = 1 TO LENGTH(sql)
		LET store = FALSE
		IF sql[x] != ' ' THEN LET first = TRUE END IF
		IF first THEN LET store = TRUE END IF
		IF sql[x] = ' ' AND sql[x+1] = ' ' THEN LET store = FALSE END IF
		IF sql[x] = ' ' AND sql[x+1] = ',' THEN LET store = FALSE END IF
		IF sql[x] = ' ' AND sql[x+1] = '.' THEN LET store = FALSE END IF
		IF y > 1 THEN
			IF sql[x] = ' ' AND newsql[y-1] = ',' THEN LET store = FALSE END IF
			IF sql[x] = ' ' AND newsql[y-1] = '.' THEN LET store = FALSE END IF
		END IF
		IF store THEN 
			LET newsql[y] = sql[x] 
			LET y = y + 1
		END IF
	END FOR

	GL_DBGMSG(2,"SQL='"||sql CLIPPED||"'")
	GL_DBGMSG(2,"NOW='"||newsql CLIPPED||"'")

	RETURN newsql
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION fnd_tabs(sql)
	DEFINE sql CHAR(SQL_LEN)
	DEFINE x,y SMALLINT
	DEFINE tab_arr ARRAY[10] OF CHAR(20)
	DEFINE aliases ARRAY[10] OF CHAR(18)
	DEFINE tab_cnt, tot_cols SMALLINT
	DEFINE xml_tab om.DomNode

	LET y = 1
	LET tab_cnt = 1
	FOR x = 1 TO LENGTH(sql)
		IF sql[x] = "," OR sql[x] = " " THEN
			LET aliases[tab_cnt] = NULL
			LET x = x + 1
			IF sql[x-1] = " " AND sql[x,x+6] != " where " THEN -- alias
				LET y = 1
				WHILE sql[x] != " " AND sql[x] != "," AND x <= LENGTH(sql)
					LET aliases[tab_cnt][y] = sql[x]
					LET y = y + 1
					LET x = x + 1
				END WHILE
				LET x = x + 1
			END IF
			LET tab_cnt = tab_cnt + 1
			LET y = 1
		END IF
		IF sql[x,x+5] = "where " THEN 
			LET tab_cnt = tab_cnt - 1
			EXIT FOR 
		END IF
		LET tab_arr[tab_cnt][y] = sql[x]
		LET y = y + 1
	END FOR
	LET xml_sql_doc = om.DomDocument.create("SQL")
	LET xml_sql_root = xml_sql_doc.getDocumentElement()
	LET tot_cols = 0
	FOR x = 1 TO tab_cnt
		GL_DBGMSG(2,"table "||x||" "||tab_arr[x])
		LET xml_cols = xml_root.selectbypath("//table[@name=\""||tab_arr[x] CLIPPED||"\"]")
		IF xml_cols.getLength() > 0 THEN
			LET xml_tab = xml_cols.item(1) 
			LET tot_cols = tot_cols + xml_tab.getAttribute("no_of_cols")
			IF aliases[x] IS NOT NULL THEN
				CALL xml_tab.setAttribute("alias",aliases[x] CLIPPED)
			END IF
			LET xml_sql = xml_sql_doc.copy( xml_tab,2 )
			CALL xml_sql_root.appendChild( xml_sql )
		ELSE
			GL_DBGMSG(2,"selectbypath failed-table "||x||" '"||tab_arr[x] CLIPPED||"'")
			ERROR "Table not found:",tab_arr[x] CLIPPED
		END IF
	END FOR
	CALL xml_sql_root.setAttribute("tot_cols",tot_cols)
	CALL xml_sql_root.writeXML("sql.xml")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION build_tab(winname, tabname, titles, lens, align)
	DEFINE winname, tabname, titles, lens, align STRING
	DEFINE tb_nl om.nodeList
	DEFINE win, vbox, tab, tabc, edit,vall,val om.domNode
	DEFINE tok1, tok2, tok3 base.StringTokenizer
	DEFINE x,y SMALLINT
	DEFINE just CHAR(1)

	LET win = gl_getWinNode(winname)
	LET tb_nl = win.selectByPath("//Table[@tabName=\""||tabname||"\"]")
	IF tb_nl.getLength() != 1 THEN
		GL_DBGMSG(2,"build_tab search for '"||tabname||"' found:"||tb_nl.getLength())
		RETURN 
	END IF
	LET tab = tb_nl.item(1)
	LET vbox = tab.getParent()
	CALL vbox.removeChild(tab)
	LET tab = vbox.createChild('Table')
	CALL tab.setAttribute("tabName",tabname)
	CALL tab.setAttribute("height","10")
	CALL tab.setAttribute("pageSize","9")
	CALL tab.setAttribute("size","10")
	CALL tab.setAttribute("bufferSize","11")

	LET x = 0
	LET tok1 = base.StringTokenizer.create( titles, "|" )
	LET tok2 = base.StringTokenizer.create( lens, "|" )
	LET tok3 = base.StringTokenizer.create( align, "|" )
	WHILE tok1.hasMoreTokens()
		LET x = x + 1
		LET tabc = tab.createChild('TableColumn')
		CALL tabc.setAttribute("colName","fld"||x)
		CALL tabc.setAttribute("hidden","0")
		CALL tabc.setAttribute("text",tok1.nextToken())
		LET edit = tabc.createChild('Edit')
		CALL edit.setAttribute("width",tok2.nextToken())
		LET just = tok3.nextToken()
		IF just = "R" THEN
			CALL edit.setAttribute("justify","right")
		END IF
		LET vall= tabc.createChild('ValueList')
		FOR y = 1 TO 11
			LET val = vall.createChild('Value')
			CALL val.setAttribute("value","")
		END FOR
	END WHILE
	WHILE x < 100
		LET x = x + 1
		LET tabc = tab.createChild('TableColumn')
		CALL tabc.setAttribute("colName","fld"||x)
		CALL tabc.setAttribute("hidden","1")
		CALL tabc.setAttribute("text","Col"||x)
		LET edit = tabc.createChild('Edit')
		CALL edit.setAttribute("width",10)
		LET vall= tabc.createChild('ValueList')
		FOR y = 1 TO 11
			LET val = vall.createChild('Value')
			CALL val.setAttribute("value","")
		END FOR
	END WHILE
	
	CALL ui.interface.refresh()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION open_sql()
	DEFINE l_sql CHAR(SQL_LEN)
	DEFINE s,line STRING
	DEFINE fn STRING

	LET fn = file_acc("openfile",TRUE,"sql","Sql Files")
	IF fn IS NULL THEN RETURN NULL END IF

	LET sqlfil = base.channel.create()
	WHENEVER ERROR CONTINUE
	CALL sqlfil.openfile(fn,"r")
	WHENEVER ERROR STOP
	IF STATUS != 0 THEN
		ERROR "Open failed!!"
		RETURN NULL
	END IF

	LET s = NULL
	LET line = sqlfil.readline()
	WHILE line IS NOT NULL
		LET s = s.append(line)
		LET line = sqlfil.readline()
		LET s = s.append(ASCII(10))
	END WHILE

	CALL sqlfil.close()

	LET l_sql = s

	RETURN l_sql

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION save_sql(sql)
	DEFINE sql CHAR(SQL_LEN)
	DEFINE fn STRING

	LET fn = file_acc("savefile",TRUE,"sql","Sql Files")
	IF fn IS NULL THEN RETURN END IF

	LET sqlfil = base.channel.create()
	WHENEVER ERROR CONTINUE
--	CALL sqlfil.openfile(fn,"r") -- check for already exists
	CALL sqlfil.openfile(fn,"w")
	WHENEVER ERROR STOP
	IF STATUS != 0 THEN
		ERROR "Save failed!!"
		RETURN
	END IF
	
	CALL sqlfil.writeline(sql CLIPPED)

	CALL sqlfil.close()

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION tab_maint(func,tabname)
	DEFINE func CHAR(1)
	DEFINE tabname CHAR(20)
	DEFINE ans CHAR(3)
	DEFINE coltyp CHAR(20)
	DEFINE stmt CHAR(4096)
	DEFINE win, frm, vbox, grid, edit, lb, ff, tab, tabc om.DomNode
	DEFINE x SMALLINT
	DEFINE i INTEGER
	DEFINE orgtab DYNAMIC ARRAY OF RECORD
		colname CHAR(18),
		coltype SMALLINT,
		colsize1 SMALLINT,
		colsize2 SMALLINT,
		nulls SMALLINT
	END RECORD
	DEFINE newtab DYNAMIC ARRAY OF RECORD
		colname CHAR(18),
		coltype SMALLINT,
		colsize1 SMALLINT,
		colsize2 SMALLINT,
		nulls SMALLINT
	END RECORD
	DEFINE coltype ui.ComboBox

	IF func = "D" THEN
		LET ans = fgl_winquestion("DROP TABLE",
											"Are you REALLY sure you want do:\nDROP TABLE "||tabname CLIPPED||" ?",
											"No","Yes|No","question",0)
		IF ans = "Yes" THEN
			GL_DBGMSG(0,"DROP TABLE "||tabname CLIPPED||": Feature not implemented yet!")
		ELSE
			GL_DBGMSG(0,"Table "||tabname||" not Dropped!")
		END IF
	END IF

	OPEN WINDOW tabmaint AT 1,1 WITH 20 ROWS, 80 COLUMNS
	LET win = gl_getWinNode("tabmaint")
	CALL win.setAttribute("style","mywin")
	CALL win.setAttribute("text",win_title("Table Maintenace",""))
	LET frm = gl_genForm("tabmaint")
	CALL frm.setAttribute("name","tabmaint")

--	CALL create_topmenu( frm, 3, 0) RETURNING ff -- create default topmenu
--	CALL sql_topmenu( ff ) -- Added extra items
--	CALL create_toolbar( frm, TRUE, 3) RETURNING ff		-- create default toolbar
--	CALL sql_toolbar( ff ) -- Added extra items

	LET vbox = frm.createChild('VBox')
	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("height","12")
	ADDFLD("Table name",1,"tabname","Edit",18)
	LET tab = vbox.createChild('Table')
	CALL tab.setAttribute("tabName","tabledef")
	CALL tab.setAttribute("height","10")
	CALL tab.setAttribute("pageSize","10")
	CALL tab.setAttribute("bufferSize","10")
	CALL tab.setAttribute("size","10")
	LET tabc = tab.createChild('TableColumn')
	CALL tabc.setAttribute("colName","colname")
	CALL tabc.setAttribute("text","Column")
	LET edit = tabc.createChild('Edit')
	CALL edit.setAttribute("width","18")

	LET tabc = tab.createChild('TableColumn')
	CALL tabc.setAttribute("colName","coltype")
	CALL tabc.setAttribute("text","Type")
--	CALL tabc.setAttribute("justify","left")
	LET edit = tabc.createChild('ComboBox')
	CALL edit.setAttribute("width","10")

	LET tabc = tab.createChild('TableColumn')
	CALL tabc.setAttribute("colName","colsize1")
	CALL tabc.setAttribute("text","Size1")
	LET edit = tabc.createChild('Edit')
	CALL edit.setAttribute("width","10")

	LET tabc = tab.createChild('TableColumn')
	CALL tabc.setAttribute("colName","colsize2")
	CALL tabc.setAttribute("text","Size2")
	LET edit = tabc.createChild('Edit')
	CALL edit.setAttribute("width","10")

	LET tabc = tab.createChild('TableColumn')
	CALL tabc.setAttribute("colName","nulls")
	CALL tabc.setAttribute("text","NotNull")
	LET edit = tabc.createChild('CheckBox')
	CALL edit.setAttribute("width","6")
	CALL edit.setAttribute("valueChecked","1")
	CALL edit.setAttribute("valueUnchecked","0")

	LET coltype = ui.ComboBox.ForName("coltype")
	CALL coltype.addItem(0,"CHAR")
	CALL coltype.addItem(1,"SMALLINT")
	CALL coltype.addItem(2,"INTEGER")
	CALL coltype.addItem(3,"FLOAT")
	CALL coltype.addItem(4,"SMALLFLOAT")
	CALL coltype.addItem(5,"DECIMAL")
	CALL coltype.addItem(6,"SERIAL")
	CALL coltype.addItem(7,"DATE")
	CALL coltype.addItem(8,"MONEY")
	CALL coltype.addItem(10,"DATETIME")
	CALL coltype.addItem(13,"VARCHAR")

	LET tabname = sel_tabname

--	IF func = "M" THEN
		DISPLAY BY NAME tabname
  	LET xml_cols = xml_root.selectbypath("//table[@name=\""||sel_tabname CLIPPED||"\"]")
  	IF xml_cols IS NULL OR xml_cols.getlength() < 1 THEN
     	GL_DBGMSG(0,"XML Error!//table[@name=\""||sel_tabname CLIPPED||"\"]")
			RETURN
  	ELSE
    	LET xml_tab = xml_cols.item(1)
		END IF	
		LET xml_cols = xml_tab.selectbytagname("column")
		FOR x = 1 TO xml_cols.getlength()
    	LET xml_col = xml_cols.item(x)
			LET orgtab[x].colname = xml_col.getAttribute("name")
			LET orgtab[x].coltype = xml_col.getAttribute("type2")
			LET orgtab[x].colsize1 = xml_col.getAttribute("length")
			IF orgtab[x].coltype = 5 OR orgtab[x].coltype = 8 THEN
				LET i = orgtab[x].colsize1 / 256
				LET orgtab[x].colsize2 = orgtab[x].colsize1 - (i * 256)
				LET orgtab[x].colsize1 = i
			END IF
			LET orgtab[x].nulls = xml_col.getAttribute("nulls")

			LET newtab[x].colname = orgtab[x].colname
			LET newtab[x].coltype = orgtab[x].coltype
			LET newtab[x].colsize1 = orgtab[x].colsize1
			LET newtab[x].colsize2 = orgtab[x].colsize2
			LET newtab[x].nulls = orgtab[x].nulls
		END FOR
--	END IF

	CALL frm.writeXML("tabmod1.xml")	
	IF func = "A" THEN
		LET x = 1
		INPUT BY NAME tabname WITHOUT DEFAULTS
		IF int_flag THEN
			LET int_flag = FALSE
			CLOSE WINDOW tabmaint
			RETURN
		END IF
	END IF
	CALL frm.writeXML("tabmod2.xml")	

	INPUT ARRAY newtab WITHOUT DEFAULTS FROM tabledef.* ATTRIBUTE(COUNT=x)
		AFTER FIELD coltype
			IF coltype = 2 THEN NEXT FIELD nulls END IF
			IF coltype = 3 THEN NEXT FIELD nulls END IF
			IF coltype = 0 THEN NEXT FIELD nulls END IF
			IF coltype = 6 THEN NEXT FIELD nulls END IF
			IF coltype = 7 THEN NEXT FIELD nulls END IF
		AFTER FIELD colsize1
			IF coltype = 0 THEN NEXT FIELD nulls END IF
			IF coltype = 13 THEN NEXT FIELD nulls END IF
	END INPUT

	IF func = "A" THEN
		LET stmt = "CREATE TABLE "||tabname CLIPPED||" ("
		LET i = ( newtab[x].colsize1 * 256 ) + newtab[x].colsize2
		LET coltyp = conv_type(newtab[1].coltype,i)
		LET stmt = stmt CLIPPED,newtab[1].colname CLIPPED," ",coltyp
		FOR x = 2 TO newtab.getLength()
			LET i = ( newtab[x].colsize1 * 256 ) + newtab[x].colsize2
			LET coltyp = conv_type(newtab[x].coltype,i)
			LET stmt = stmt CLIPPED,", ",newtab[x].colname CLIPPED," ",coltyp
		END FOR
		LET stmt = stmt CLIPPED,")"
		DISPLAY "stmt:",stmt CLIPPED
	END IF

-- To do everything else
	LET int_flag = FALSE
	CLOSE WINDOW tabmaint

END FUNCTION
