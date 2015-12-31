--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 3.00 >
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------
#+ Dynamic Lookup function.
#+ $Id: gl_lookup.4gl 334 2014-01-20 09:51:45Z test4j $
--------------------------------------------------------------------------------
&include "genero_lib1.inc"

CONSTANT MAXCOLWIDTH=30
--------------------------------------------------------------------------------
#+ @code LET key = gl_lookup3( tabnam, cols, colts, wher, ordby )
#+
#+ @param tabnam db table name
#+ @param cols  columns names ( comma seperated )
#+ @param colts columns titles ( comma seperated )
#+					can be NULL to use column names
#+					can be _ to have a hidden column - ie 1st col if it's a key
#+ @param wher  The WHERE clause, 1=1 means all, or use result of construct
#+ @param ordby The ORDER BY clause
FUNCTION gl_lookup3( tabnam, cols, colts, wher, ordby ) --{{{
	DEFINE tabnam, cols, colts, wher, ordby STRING
	DEFINE frm, grid, tabl, tabc, edit, curr  om.DomNode
	DEFINE hb, sp, titl om.DomNode
	DEFINE tot_recs, x, i INTEGER
	DEFINE tok base.StringTokenizer
	DEFINE col_titles DYNAMIC ARRAY OF STRING
	DEFINE fields DYNAMIC ARRAY OF RECORD
		name STRING,
		type STRING
	END RECORD
	DEFINE sel_stmt STRING
	DEFINE ret_key STRING
	DEFINE sql_handle base.SqlHandle
	DEFINE dlg ui.Dialog
	DEFINE l_event STRING

	GL_MODULE_ERROR_HANDLER
	GL_DBGMSG(2,"gl_lookup3: table(s)="||tabnam)
	GL_DBGMSG(2,"gl_lookup3: cols    ="||cols)
	GL_DBGMSG(2,"gl_lookup3: titles  ="||colts)
	GL_DBGMSG(2,"gl_lookup3: where   ="||wher)
	GL_DBGMSG(2,"gl_lookup3: orderby ="||ordby)
	GL_DBGMSG(2,"gl_lookup3: Declaring Count Cursor...")
-- Check to make sure there are records.
	TRY
		LET sel_stmt = "SELECT COUNT(*) FROM "||tabnam||" WHERE "||wher
		PREPARE listcntpre FROM sel_stmt
	CATCH
		CALL gl_winMessage("Error!","Failed to prepare:\n"||sel_stmt||"\n"||SQLERRMESSAGE,"exclamation")
		RETURN NULL --, NULL
	END TRY
-- do the count
	DECLARE listcntcur CURSOR FOR listcntpre
	OPEN listcntcur
	FETCH listcntcur INTO tot_recs
	CLOSE listcntcur
	IF tot_recs < 1 THEN
		CALL fgl_winmessage("Error", "No Records Found", "exclamation")
		RETURN NULL --, NULL
	END IF
	GL_DBGMSG(2,"gl_lookup3: Counted:"||tot_recs)

-- Prepare/Declare main cursor
	LET sel_stmt = 
		"SELECT "||cols CLIPPED||" FROM "||tabnam CLIPPED," WHERE "||wher
	IF ordby IS NOT NULL THEN
		LET sel_stmt = sel_stmt CLIPPED," ORDER BY "||ordby
	END IF

-- Version 3.00 feature.
	LET sql_handle = base.SqlHandle.create()
	CALL sql_handle.prepare( sel_stmt )
	CALL sql_handle.openScrollCursor()
	CALL fields.clear()
	FOR x = 1 TO sql_handle.getResultCount()
		LET fields[x].name = sql_handle.getResultName(x)
		LET col_titles[x] = fields[x].name -- default column titles
		LET fields[x].type = sql_handle.getResultType(x)
		GL_DBGMSG(2,"gl_lookup3:"||i||" Name:"||fields[x].name||" Type:"||fields[x].type)
	END FOR
	GL_DBGMSG(2,"gl_lookup3: Cursor Okay.")

-- Open the window and define a table.
	GL_DBGMSG(2,"gl_lookup3: Opening Window.")
	OPEN WINDOW listv AT 1,1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE="naked")
	CALL fgl_setTitle( "Listing from "||tabnam )
	LET frm = gl_genForm("gl_"||tabnam.trim() ) -- ensures form name is specific for this lookup

	LET grid = frm.createChild('Grid')
-- Create a centered window title.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","0")
	LET sp = hb.createChild('SpacerItem')
	LET titl = hb.createChild('Label')
	CALL titl.setAttribute("text","Listing from "||tabnam CLIPPED)
	CALL titl.setAttribute("style","tabtitl")
	LET sp = hb.createChild('SpacerItem')

	GL_DBGMSG(2,"gl_lookup3: Generating Table...")
-- Create the table
	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName","tablistv")
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","20")
	CALL tabl.setAttribute("posY","1")

-- Setup column titles if supplied.
	IF colts IS NOT NULL THEN 
		LET tok = base.StringTokenizer.create( colts, "," )
		CALL col_titles.clear() -- clear the defaults if title supplied.
		WHILE tok.hasMoreTokens()
			LET col_titles[ col_titles.getLength() + 1] = tok.nextToken()
		END WHILE
	END IF
	
-- Create Columns & Headings for the table.
	FOR x = 1 TO fields.getLength()
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName",fields[x].name)
		LET edit = tabc.createChild('Edit')
		CALL tabc.setAttribute("text",col_titles[x])
		CALL edit.setAttribute("width", gl_lookup_getSize(fields[x].type))
		IF col_titles[x].getCharAt(1) = "_" THEN -- if title starts with _ then it's a hidden column
			CALL tabc.setAttribute("hidden","1")
		END IF
	END FOR

	GL_DBGMSG(2,"gl_lookup3: Adding buttons...")
-- Create centered buttons.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","3")
  LET curr = hb.createChild('Label')
  CALL curr.setAttribute("text","Row:")
  LET curr = hb.createChild('Label')
  CALL curr.setAttribute("name","cur_row")
  CALL curr.setAttribute("sizePolicy","dynamic")
	LET sp = hb.createChild('SpacerItem')
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("name","firstrow")
	CALL titl.setAttribute("image","gobegin")
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("name","prevpage")
	CALL titl.setAttribute("image","gorev")
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("text","Okay")
	CALL titl.setAttribute("name","accept")
	CALL titl.setAttribute("width","8")
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("name","cancel")
	CALL titl.setAttribute("text","Cancel")
	CALL titl.setAttribute("width","8")
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("name","nextpage")
	CALL titl.setAttribute("image","goforw")
	LET titl = hb.createChild('Button')
	CALL titl.setAttribute("name","lastrow")
	CALL titl.setAttribute("image","goend")
	LET sp = hb.createChild('SpacerItem')
	LET titl = hb.createChild('Label')
	CALL titl.setAttribute("text",tot_recs USING "###,###,##&"||" Rows")
  CALL titl.setAttribute("sizePolicy","dynamic")

-- Setup the dialog
	LET int_flag = FALSE
	LET dlg = ui.Dialog.createDisplayArrayTo(fields, "tablistv")
	CALL dlg.addTrigger("ON ACTION close")
	CALL dlg.addTrigger("ON ACTION accept")
	CALL dlg.addTrigger("ON ACTION cancel")

-- Fetch the data
	CALL sql_handle.fetchFirst()
	LET x = 0
	WHILE status = 0
		LET x = x + 1
		CALL dlg.setCurrentRow("tablistv", x) -- must set the current row before setting values
		FOR i = 1 TO sql_handle.getResultCount()
			CALL dlg.setFieldValue(sql_handle.getResultName(i), sql_handle.getResultValue(i))
		END FOR
		CALL sql_handle.fetch()
	END WHILE
	CALL sql_handle.close()
	CALL dlg.setCurrentRow("tablistv", 1) -- TODO: should be done by the runtime
-- Loop for events.
	WHILE TRUE
		LET l_event = dlg.nextEvent()
		CASE l_event
			WHEN "BEFORE DISPLAY"
				IF tot_recs = 1 THEN EXIT WHILE END IF -- if only 1 row just select it!
			WHEN "ON ACTION close"
				LET int_flag = TRUE EXIT WHILE
			WHEN "ON ACTION cancel"
				LET int_flag = TRUE EXIT WHILE
			WHEN "ON ACTION accept"
				EXIT WHILE
			WHEN "ON SORT"
				--MESSAGE "Use 'reset sort order' to reset to default."
				EXIT WHILE
			WHEN "ON ACTION tablistv.accept" -- doubleclick
				EXIT WHILE
			WHEN "BEFORE ROW"
				LET x = dlg.arrayToVisualIndex("tablistv", arr_curr())
				CALL curr.setAttribute("text",SFMT("%1 (%2)", x USING "<<<,##&",arr_curr() USING "<<<,##&"))
			OTHERWISE
				GL_DBGMSG(2,"gl_lookup3: Unhandled Event:"||l_event)
		END CASE
	END WHILE
	LET ret_key = dlg.getFieldValue( fields[1].name ) -- get the selected row first field.
	LET dlg = NULL -- FIXME: CALL dlg.terminate()

	CLOSE WINDOW listv	
	IF int_flag THEN
		GL_DBGMSG(2,"gl_lookup3: Window Closed, Cancelled.")
		RETURN NULL
	ELSE
		GL_DBGMSG(2,SFMT("gl_lookup3: Window Closed, returning row:%1 %2",arr_curr(),ret_key)) 
		RETURN ret_key.trim()
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get the size for the table column from the type passed
FUNCTION gl_lookup_getSize(l_type)
	DEFINE l_type STRING
	DEFINE l_size SMALLINT
	DEFINE x,y SMALLINT

	CASE l_type
		WHEN "SMALLINT" LET l_size = 5
		WHEN "SERIAL" LET l_size = 10
		WHEN "INTEGER" LET l_size = 10
		WHEN "FLOAT" LET l_size = 12
		WHEN "DATE" LET l_size = 10
		OTHERWISE
			LET l_size = 5
	END CASE

	LET x = l_type.getIndexOf("(",1)
	IF x > 1 THEN
		LET y = l_type.getIndexOf(",",1)
		IF y = 0 THEN
			LET y = l_type.getIndexOf(")",1)
		END IF
		LET l_size = l_type.subString(x+1,y-1)
	END IF
	IF l_size > MAXCOLWIDTH THEN LET l_size = MAXCOLWIDTH END IF -- shrink big fields to MAXCOLWIDTH
	RETURN l_size
END FUNCTION --}}}
--------------------------------------------------------------------------------