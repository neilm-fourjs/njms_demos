
--------------------------------------------------------------------------------
#+ Genero Library 2 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.00.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

#+ Dynamic Lookup function.
#+ $Id: gl2_lookup.4gl 334 2014-01-20 09:51:45Z test4j $

&include "genero_lib1.inc"
&include "gl_lookup.inc"

DEFINE ret SMALLINT

CONSTANT MAX_RECS=2000
CONSTANT MAX_COLS=8

DEFINE data_ar DYNAMIC ARRAY OF RECORD
	DEF_DATA_AR
END RECORD
DEFINE recs INTEGER
DEFINE col_ar ARRAY[MAX_COLS] OF CHAR(18) -- Needed by jump row code for hidden cols

--------------------------------------------------------------------------------
#+ gl2_lookup: A generic dynamic lookup used by gl2_fldChooser
#+
#+ @code LET key = gl2_fldChooser( "customer", base.typeInfo.create( cust ) )
#+
#+ @param lk_n DomNode of the typeInfo of the record to do the lookup for
FUNCTION gl2_lookup( lk_n ) --{{{
	DEFINE tabnam, cols, colts, wher, ordby STRING
	DEFINE lk_n,c om.domNode
	DEFINE nl om.nodeList
	DEFINE win, frm, grid, tabl, tabc, edit, curr  om.DomNode
	DEFINE hb,sp,titl om.DomNode
	DEFINE fn CHAR(4)
	DEFINE col_cnt SMALLINT
	DEFINE tot_recs,x,i,startIndex,bufferLength INTEGER
	DEFINE ctyp CHAR(8)
	DEFINE ttyp CHAR(1)
	DEFINE clen SMALLINT
	DEFINE sel_stmt STRING
	DEFINE ret_key,ret_desc STRING
GL_MODULE_ERROR_HANDLER
	LET tabnam = lk_n.getAttribute("tabname")
	LET wher = lk_n.getAttribute("where")
	LET ordby = lk_n.getAttribute("orderby")

	LET nl = lk_n.selectByTagName("Column")	
	LET c = nl.item(1)
	LET cols = c.getAttribute("colname")
	LET ctyp[1] = c.getAttribute("type")
	FOR col_cnt = 2 TO nl.getLength()
		LET c = nl.item(col_cnt)
		LET cols = cols.trim()||","||c.getAttribute("colname")
		LET ctyp[col_cnt] = c.getAttribute("type")
	END FOR

	GL_DBGMSG(2,"gl2_lookup: table(s)="||tabnam)
	GL_DBGMSG(2,"gl2_lookup: cols    ="||cols)
--	GL_DBGMSG(2,"gl2_lookup: titles  ="||colts)
	GL_DBGMSG(2,"gl2_lookup: ctypes  ="||ctyp)
	GL_DBGMSG(2,"gl2_lookup: where   ="||wher)
	GL_DBGMSG(2,"gl2_lookup: orderby ="||ordby)

	LET int_flag = FALSE
	CALL col_ar.clear()
	CALL data_ar.clear()

	GL_DBGMSG(2,"gl2_lookup: Declaring Count Cursor...")
-- Check to make sure there are records.
	PREPARE listcntpre FROM "SELECT COUNT(*) FROM "||tabnam||" WHERE "||wher
	DECLARE listcntcur CURSOR FOR listcntpre
	OPEN listcntcur
	FETCH listcntcur INTO tot_recs
	CLOSE listcntcur
	IF tot_recs < 1 THEN
		CALL fgl_winmessage("Error", "No Records Found", "exclamation")
		RETURN NULL --, NULL
	END IF
	GL_DBGMSG(2,"gl2_lookup: Counted:"||tot_recs)

-- Prepare/Declare main cursor
	LET sel_stmt = 
		"SELECT "||cols CLIPPED||" FROM "||tabnam CLIPPED," WHERE "||wher
	IF ordby IS NOT NULL THEN
		LET sel_stmt = sel_stmt CLIPPED," ORDER BY "||ordby
	END IF
--	DISPLAY "lookup: sel_stmt:",sel_stmt
	GL_DBGMSG(2,"gl2_lookup: Declaring Main Cursor...")
	PREPARE listpre FROM sel_stmt
	DECLARE listcur SCROLL CURSOR FOR listpre
-- If only one record then just return it's key.
	IF tot_recs = 1 THEN
		GL_DBGMSG(2,"gl2_lookup: Only one 1 record so fetching it.")
		OPEN listcur
		FETCH listcur INTO data_ar[1].cf1,
											data_ar[1].cf2,
											data_ar[1].cf3,
											data_ar[1].cf4,
											data_ar[1].cf5,
											data_ar[1].cf6,
											data_ar[1].cf7,
											data_ar[1].cf8
		CLOSE listcur
		GL_DBGMSG(2,"gl2_lookup: Done, returning.")
		RETURN data_ar[1].cf1 --,data_ar[1].cf2
	END IF
	GL_DBGMSG(2,"gl2_lookup: Cursor Okay.")

	GL_DBGMSG(2,"gl2_lookup: Opening Window.")
-- Open the window and define a table.
	OPEN WINDOW listv AT 1,1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE="naked")
	LET win = gl_getWinNode(NULL)
	LET frm = gl_genForm(tabnam CLIPPED)
	CALL win.setAttribute("style","naked")

	CALL win.setAttribute("text","Listing from "||tabnam)
	CALL frm.setAttribute("name",tabnam CLIPPED)

	LET grid = frm.createChild('Grid')

-- Create a centered window title.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","0")
	LET sp = hb.createChild('SpacerItem')
	LET titl = hb.createChild('Label')
	IF tot_recs < MAX_RECS THEN
		CALL titl.setAttribute("text","Sortable Listing from "||tabnam CLIPPED)
	ELSE
		CALL titl.setAttribute("text","Non-Sortable Listing from "||tabnam CLIPPED||"(Paged Array)")
	END IF
	CALL titl.setAttribute("style","tabtitl")
	LET sp = hb.createChild('SpacerItem')

	GL_DBGMSG(2,"gl2_lookup: Generating Table...")
-- Create the table
	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName","tablistv")
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","20")
	CALL tabl.setAttribute("size","20")
	CALL tabl.setAttribute("posY","1")
	
-- Create Columns & Headings for the table.
	FOR i = 1 TO MAX_COLS
		LET c = nl.item(i)
		FOR x = 1 TO 4
			CASE x
				WHEN 1 LET fn = "cf",i USING "&" LET ttyp = "C" LET clen = 30
				WHEN 2 LET fn = "if",i USING "&" LET ttyp = "I" LET clen = 12 
				WHEN 3 LET fn = "nf",i USING "&" LET ttyp = "N" LET clen = 12
				WHEN 4 LET fn = "df",i USING "&" LET ttyp = "D" LET clen = 10
			END CASE
			IF c IS NOT NULL THEN
				LET clen = c.getAttribute("width")
				LET colts = c.getAttribute("text")
			END IF
			LET tabc = tabl.createChild('TableColumn')
			CALL tabc.setAttribute("colName",fn)
			LET edit = tabc.createChild('Edit')
			IF ctyp[i] != "C" AND ctyp[i] != "D"  THEN
				CALL edit.setAttribute("justify","right")
				IF ctyp[i] = "I" THEN
					IF clen > 5 THEN
						CALL edit.setAttribute("format","--,---,--&")
					ELSE
						CALL edit.setAttribute("format","--,--&")
						LET clen = clen + 1
					END IF
				END IF
			END IF
			IF i > nl.getLength() OR ctyp[i] != ttyp OR col_ar[i] = "_" THEN
				CALL tabc.setAttribute("text","empty")
				CALL edit.setAttribute("width",1)
				CALL tabc.setAttribute("hidden","1")
				CALL edit.setAttribute("hidden","1")
			ELSE
				CALL tabc.setAttribute("text", colts)
				CALL edit.setAttribute("width",clen)
			END IF
		END FOR
	END FOR

	GL_DBGMSG(2,"gl2_lookup: Adding buttons...")
-- Create centered buttons.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","21")
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

-- If less than MAX_RECS records then use a normal display array.
-- else use a paged array
	IF tot_recs < MAX_RECS THEN
		GL_DBGMSG(2,"gl2_lookup: Reading Data...")
		LET recs = 1
		CALL gl_progBar(1,tot_recs,"Reading Data...")
		FOREACH listcur INTO data_ar[recs].cf1,
											data_ar[recs].cf2,
											data_ar[recs].cf3,
											data_ar[recs].cf4,
											data_ar[recs].cf5,
											data_ar[recs].cf6,
											data_ar[recs].cf7,
											data_ar[recs].cf8
			CALL gl_lookup_mvdta(data_ar,recs,ctyp)
			CALL gl_progBar(2,recs,"")
			LET recs = recs + 1
		END FOREACH
		LET recs = recs - 1
		CALL gl_progBar(3,recs,"")
		MESSAGE "Read ",recs," Rows."
		GL_DBGMSG(2,"gl2_lookup: DISPLAY ARRAY COUNT:"||recs) 
--		CALL win.writeXML("win.xml")
--		CALL ui.interface.refresh()

		DISPLAY ARRAY data_ar TO tablistv.* ATTRIBUTE(COUNT=recs)
			BEFORE ROW
				CALL curr.setAttribute("text",arr_curr() USING "#,##&")
		END DISPLAY
		IF arr_curr() > 0 THEN
			LET ret_key = data_ar[ arr_curr() ].cf1
			LET ret_desc = data_ar[ arr_curr() ].cf2
		END IF
	ELSE
		GL_DBGMSG(2,"gl2_lookup: Opening Cursor...") 
		OPEN listcur
		GL_DBGMSG(2,"gl2_lookup: Doing Paged Array...") 
		DISPLAY ARRAY data_ar TO tablistv.* ATTRIBUTE(COUNT=tot_recs)
			BEFORE ROW
				CALL curr.setAttribute("text",arr_curr() USING "#,##&")
			ON FILL BUFFER
				LET startIndex = fgl_dialog_getBufferStart()
				LET bufferLength = fgl_dialog_getBufferLength()
				FOR recs = 1 TO bufferLength
					FETCH ABSOLUTE startIndex+recs-1 listcur INTO data_ar[recs].cf1,
											data_ar[recs].cf2,
											data_ar[recs].cf3,
											data_ar[recs].cf4,
											data_ar[recs].cf5,
											data_ar[recs].cf6,
											data_ar[recs].cf7,
											data_ar[recs].cf8
					CALL gl_lookup_mvdta(data_ar,recs,ctyp)
				END FOR
		END DISPLAY
		IF arr_curr() > 0 THEN
			LET recs = arr_curr()
			FETCH ABSOLUTE recs listcur INTO data_ar[1].cf1, data_ar[1].cf2
			LET ret_key = data_ar[1].cf1
			LET ret_desc = data_ar[1].cf2
		END IF
		CLOSE listcur
	END IF
	CLOSE WINDOW listv	
	GL_DBGMSG(2,"gl2_lookup: Window Closed, returning.") 
	LET ret_key = ret_key.trim()
	LET ret_desc = ret_desc.trim()
	IF int_flag THEN
		RETURN NULL
	ELSE
		RETURN ret_key --,ret_desc
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------