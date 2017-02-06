--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 2.41>
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------
#+ Dynamic Lookup function.
#+ $Id: gl_lookup.4gl 342 2015-07-03 11:54:51Z neilm $
--------------------------------------------------------------------------------

&include "genero_lib1.inc"
&include "gl_lookup.inc"

GLOBALS
  DEFINE xml_sch om.domdocument
  DEFINE xml_root om.domnode
	DEFINE gl_currRow INTEGER -- Can be used to set current row.
END GLOBALS

CONSTANT MAX_RECS=2000
CONSTANT MAX_COLS=12

	DEFINE m_data_ar DYNAMIC ARRAY OF RECORD
DEF_DATA_AR
	END RECORD

--------------------------------------------------------------------------------
#+ @code LET key = gl_lookup( tabnam, cols, colts, ftyp, wher, ordby )
#+
#+ @param tabnam table name
#+ @param cols  columns names up to MAX_COLS ( comma seperated )
#+ @param colts columns titles up to MAX_COLS ( comma seperated )
#+					can be NULL to use column names
#+					can be _ to have a hidden column - ie 1st col if it's a key
#+          can include ~X to set column width - ie Code~8 ( width=8 )
#+ @param ftyp  types of columns D=Date, C=Char, N=Numeric/Decimal, I=Integer
#+					can be ?,?,? etc for default of column type from xml sch
#+ @param wher  The WHERE clause, 1=1 means all, or use result of construct
#+ @param ordby The ORDER BY clause
FUNCTION gl_lookup( tabnam, cols, colts, ftyp, wher, ordby ) --{{{
	DEFINE tabnam, cols, colts, wher, ordby STRING
	DEFINE ftyp CHAR(MAX_COLS)
	DEFINE win, frm, grid, tabl, tabc, edit, curr  om.DomNode
	DEFINE hb,sp,titl om.DomNode
	DEFINE fn CHAR(4)
	DEFINE col_cnt SMALLINT
	DEFINE tot_recs,x,i,startIndex,bufferLength, recs INTEGER
	DEFINE tok base.StringTokenizer
	DEFINE ttyp CHAR(1)
	DEFINE ttype CHAR(20)
	DEFINE tlen SMALLINT
	DEFINE xml_col ARRAY[MAX_COLS] OF om.DomNode
	DEFINE col_len ARRAY[MAX_COLS] OF SMALLINT
	DEFINE sel_stmt STRING
	DEFINE ret_key,ret_desc STRING
	DEFINE col_titles ARRAY[MAX_COLS] OF STRING -- Needed for hidden cols
	DEFINE col_width ARRAY[MAX_COLS] OF SMALLINT -- Columns Width

	GL_MODULE_ERROR_HANDLER
	GL_DBGMSG(2,"gl_lookup: table(s)="||tabnam)
	GL_DBGMSG(2,"gl_lookup: cols    ="||cols)
	GL_DBGMSG(2,"gl_lookup: titles  ="||colts)
	GL_DBGMSG(2,"gl_lookup: ftypes  ="||ftyp)
	GL_DBGMSG(2,"gl_lookup: where   ="||wher)
	GL_DBGMSG(2,"gl_lookup: orderby ="||ordby)

	LET int_flag = FALSE
	CALL m_data_ar.clear()

	GL_DBGMSG(2,"gl_lookup: Declaring Count Cursor...")
-- Check to make sure there are records.
	TRY
		LET sel_stmt = "SELECT COUNT(*) FROM "||tabnam||" WHERE "||wher
		PREPARE listcntpre FROM sel_stmt
	CATCH
		CALL gl_winMessage("Error!","Failed to prepare:\n"||sel_stmt||"\n"||SQLERRMESSAGE,"exclamation")
		RETURN NULL
	END TRY
	DECLARE listcntcur CURSOR FOR listcntpre
	OPEN listcntcur
	FETCH listcntcur INTO tot_recs
	CLOSE listcntcur
	IF tot_recs < 1 THEN
		CALL fgl_winmessage("Error", "No Records Found", "exclamation")
		RETURN NULL --, NULL
	END IF
	GL_DBGMSG(2,"gl_lookup: Counted:"||tot_recs)

-- Break column list into columns for default table headings
	LET tok = base.StringTokenizer.create( cols, "," )
	LET col_cnt = 1
	WHILE tok.hasMoreTokens()
		LET col_titles[col_cnt] = tok.nextToken()
		LET col_cnt = col_cnt + 1
		IF col_cnt > MAX_COLS THEN EXIT WHILE END IF
	END WHILE
	LET col_cnt = col_cnt - 1
	GL_DBGMSG(2,"gl_lookup: col_cnt ="||col_cnt)

-- Prepare/Declare main cursor
	LET sel_stmt = 
		"SELECT "||cols CLIPPED||" FROM "||tabnam CLIPPED," WHERE "||wher
	IF ordby IS NOT NULL THEN
		LET sel_stmt = sel_stmt CLIPPED," ORDER BY "||ordby
	END IF

--	DISPLAY "lookup: sel_stmt:",sel_stmt
	GL_DBGMSG(2,"gl_lookup: Declaring Main Cursor...")
	TRY
		PREPARE listpre FROM sel_stmt
	CATCH
		DISPLAY "Prepare failed!\n"||SQLERRMESSAGE||"\n-\n"||(sel_stmt CLIPPED)||"\n-\n"||base.application.getStackTrace()
		CALL gl_winMessage("Error","Prepare failed!\n"||SQLERRMESSAGE||"\n-\n"||(sel_stmt CLIPPED)||"\n-\n"||base.application.getStackTrace(),"exclamation")
		RETURN NULL
	END TRY

	IF tot_recs != 1 THEN
-- Open the window and define a table.
		GL_DBGMSG(2,"gl_lookup: Opening Window.")
		OPEN WINDOW listv AT 1,1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE="naked")
		LET win = gl_getWinNode(NULL)
		CALL win.setAttribute("text","Listing from "||tabnam)
		LET frm = gl_genForm("gl_"||tabnam.trim() )
	END IF

	DECLARE listcur SCROLL CURSOR FOR listpre
-- If only one record then just return it's key.
	IF tot_recs = 1 THEN
		GL_DBGMSG(2,"gl_lookup: Only one 1 record so fetching it.")
		OPEN listcur
		FETCH listcur INTO INTO_DATA_AR( 1 )
		CLOSE listcur
		GL_DBGMSG(2,"gl_lookup: Done, returning.")
		RETURN m_data_ar[1].cf1 --,m_data_ar[1].cf2
	END IF
	GL_DBGMSG(2,"gl_lookup: Cursor Okay.")

	CALL frm.setAttribute("name","gl_"||tabnam.trim() )

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

	GL_DBGMSG(2,"gl_lookup: Generating Table...")
-- Create the table
	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName","tablistv")
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","20")
	CALL tabl.setAttribute("posY","1")
	
-- Get column length from xml schema if xml_root is not null
	IF xml_root IS NOT NULL THEN
  	FOR x = 1 TO col_cnt
    	LET xml_col[x] = gl_findXmlCol(tabnam,col_titles[x],xml_root)
    	LET col_len[x] = xml_col[x].getAttribute("collen")
			IF ftyp[x] = "?" THEN
    		LET ttype = xml_col[x].getAttribute("type")
				CASE 
					WHEN ttype[1,7] = "DECIMAL"
    				LET ftyp[x] = "N"
					WHEN ttype[1,7] = "INTEGER"
    				LET ftyp[x] = "I"
					WHEN ttype[1,8] = "SMALLINT"
    				LET ftyp[x] = "I"
					WHEN ttype[1,4] = "DATE"
    				LET ftyp[x] = "D"
					WHEN ttype[1,4] = "CHAR"
    				LET ftyp[x] = "C"
					WHEN ttype[1,7] = "VARCHAR"
    				LET ftyp[x] = "C"
				END CASE
			END IF
  	END FOR
	END IF

-- Setup column titles if supplied.
	IF colts IS NOT NULL THEN 
		LET tok = base.StringTokenizer.create( colts, "," )
		LET x = 1
		WHILE tok.hasMoreTokens()
			LET col_titles[x] = tok.nextToken()
			LET i = col_titles[x].getIndexOf("~",2)
			IF i > 0 THEN 
				LET col_width[x] = col_titles[x].subString(i+1,col_titles[x].getLength())
				LET col_titles[x] = col_titles[x].subString(1,i-1)
			ELSE
				LET col_width[x] = 0
			END IF
			LET x = x + 1
			IF x > MAX_COLS THEN EXIT WHILE END IF
		END WHILE
	END IF
	
-- Create Columns & Headings for the table.
	FOR i = 1 TO MAX_COLS
		FOR x = 1 TO 4
			CASE x
				WHEN 1 LET fn = "cf",i USING "&" LET ttyp = "C" LET tlen = 30
				WHEN 2 LET fn = "if",i USING "&" LET ttyp = "I" LET tlen = 12 
				WHEN 3 LET fn = "nf",i USING "&" LET ttyp = "N" LET tlen = 12
				WHEN 4 LET fn = "df",i USING "&" LET ttyp = "D" LET tlen = 10
			END CASE
			IF col_width[i] > 0 THEN LET tlen = col_width[i] END IF
			IF col_len[i] IS NOT NULL AND col_len[i] != 0 THEN LET tlen = col_len[i] END IF
			LET tabc = tabl.createChild('TableColumn')
			CALL tabc.setAttribute("colName",fn)
			LET edit = tabc.createChild('Edit')
			IF ftyp[i] != "C" AND ftyp[i] != "D"  THEN
				CALL edit.setAttribute("justify","right")
				IF ftyp[i] = "I" THEN
					IF tlen > 5 THEN
						CALL edit.setAttribute("format","--,---,--&")
					ELSE
						CALL edit.setAttribute("format","--,--&")
						LET tlen = tlen + 1
					END IF
				END IF
			END IF
			IF i > col_cnt OR ftyp[i] != ttyp OR col_titles[i] = "_" THEN
				CALL tabc.setAttribute("text","empty")
				CALL edit.setAttribute("width",0)
				CALL tabc.setAttribute("hidden","1")
				CALL edit.setAttribute("hidden","1")
			ELSE
				CALL tabc.setAttribute("text",col_titles[i])
				CALL edit.setAttribute("width",tlen)
			END IF
		END FOR
	END FOR

	GL_DBGMSG(2,"gl_lookup: Adding buttons...")
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

-- If less than MAX_RECS records then use a normal display array.
-- else use a paged array
	IF tot_recs < MAX_RECS THEN
		GL_DBGMSG(2,"gl_lookup: Reading Data...")
		CALL m_data_ar.clear()
		CALL gl_progBar(1,tot_recs,"Reading Data...")
		LET recs = 1
		FOREACH listcur INTO INTO_DATA_AR( recs )
			LET recs = recs + 1
			CALL gl_lookup_mvdta(m_data_ar,m_data_ar.getLength(),ftyp)
			CALL gl_progBar(2,m_data_ar.getLength(),"")
		END FOREACH
		CALL m_data_ar.deleteElement( m_data_ar.getLength() )
		CALL gl_progBar(3,m_data_ar.getLength(),"")
		MESSAGE "Read ",m_data_ar.getLength()," Rows."
		GL_DBGMSG(2,"gl_lookup: DISPLAY ARRAY COUNT:"||m_data_ar.getLength()) 

		DISPLAY ARRAY m_data_ar TO tablistv.*
			BEFORE DISPLAY
				IF gl_currRow IS NOT NULL AND gl_currRow > 0 THEN
					CALL fgl_set_arr_curr( gl_currRow )
				END IF
			BEFORE ROW
				CALL curr.setAttribute("text",arr_curr() USING "#,##&")
&ifdef genero3x
			ON SORT
				DISPLAY "Sorted!!"
&endif
		END DISPLAY
		IF arr_curr() > 0 THEN
			LET ret_key = m_data_ar[ arr_curr() ].cf1
			LET ret_desc = m_data_ar[ arr_curr() ].cf2
		END IF
	ELSE
		GL_DBGMSG(2,"gl_lookup: Opening Cursor...") 
		OPEN listcur
		GL_DBGMSG(2,"gl_lookup: Doing Paged Array...") 
		DISPLAY ARRAY m_data_ar TO tablistv.* ATTRIBUTE(COUNT=tot_recs)
			BEFORE DISPLAY
				IF gl_currRow IS NOT NULL AND gl_currRow > 0 THEN
					CALL fgl_set_arr_curr( gl_currRow )
				END IF
			BEFORE ROW
				CALL curr.setAttribute("text",arr_curr() USING "#,###,##&")
			ON FILL BUFFER
				LET startIndex = fgl_dialog_getBufferStart()
				LET bufferLength = fgl_dialog_getBufferLength()
				FOR recs = 1 TO bufferLength
					FETCH ABSOLUTE startIndex+recs-1 listcur INTO INTO_DATA_AR( recs )
					CALL gl_lookup_mvdta(m_data_ar,recs,ftyp)
				END FOR
		END DISPLAY
		IF arr_curr() > 0 THEN
			LET recs = arr_curr()
			FETCH ABSOLUTE recs listcur INTO m_data_ar[1].cf1, m_data_ar[1].cf2
			LET ret_key = m_data_ar[1].cf1
			LET ret_desc = m_data_ar[1].cf2
		END IF
		CLOSE listcur
	END IF
	CLOSE WINDOW listv	
	DISPLAY "Arr:",arr_curr(), " Scr:",scr_line()
	GL_DBGMSG(2,"gl_lookup: Window Closed, returning.") 
	LET ret_key = ret_key.trim()
	LET ret_desc = ret_desc.trim()
	IF int_flag THEN
		RETURN NULL
	ELSE
		RETURN ret_key --,ret_desc
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Move the data into the revant fields in the array.
FUNCTION gl_lookup_mvdta(m_data_ar,rec,ftyp) --{{{
	DEFINE m_data_ar DYNAMIC ARRAY OF RECORD
DEF_DATA_AR
	END RECORD
	DEFINE ftyp CHAR(MAX_COLS)
	DEFINE rec INTEGER

	GL_DBGMSG(2,"gl_lookup: gl_lookup_mvdta: '"||ftyp||"' rec:"||rec)

	IF ftyp[1] = "N" THEN LET m_data_ar[rec].nf1 = m_data_ar[rec].cf1 END IF
	IF ftyp[2] = "N" THEN LET m_data_ar[rec].nf2 = m_data_ar[rec].cf2 END IF
	IF ftyp[3] = "N" THEN LET m_data_ar[rec].nf3 = m_data_ar[rec].cf3 END IF
	IF ftyp[4] = "N" THEN LET m_data_ar[rec].nf4 = m_data_ar[rec].cf4 END IF
	IF ftyp[5] = "N" THEN LET m_data_ar[rec].nf5 = m_data_ar[rec].cf5 END IF
	IF ftyp[6] = "N" THEN LET m_data_ar[rec].nf6 = m_data_ar[rec].cf6 END IF
	IF ftyp[7] = "N" THEN LET m_data_ar[rec].nf7 = m_data_ar[rec].cf7 END IF
	IF ftyp[8] = "N" THEN LET m_data_ar[rec].nf8 = m_data_ar[rec].cf8 END IF
	IF ftyp[9] = "N" THEN LET m_data_ar[rec].nf9 = m_data_ar[rec].cf9 END IF
	IF ftyp[10] = "N" THEN LET m_data_ar[rec].nf10 = m_data_ar[rec].cf10 END IF
	IF ftyp[11] = "N" THEN LET m_data_ar[rec].nf11 = m_data_ar[rec].cf11 END IF
	IF ftyp[12] = "N" THEN LET m_data_ar[rec].nf12 = m_data_ar[rec].cf12 END IF

	IF ftyp[1] = "D" THEN LET m_data_ar[rec].df1 = gl_strToDate(m_data_ar[rec].cf1) END IF
	IF ftyp[2] = "D" THEN LET m_data_ar[rec].df2 = gl_strToDate(m_data_ar[rec].cf2) END IF
	IF ftyp[3] = "D" THEN LET m_data_ar[rec].df3 = gl_strToDate(m_data_ar[rec].cf3) END IF
	IF ftyp[4] = "D" THEN LET m_data_ar[rec].df4 = gl_strToDate(m_data_ar[rec].cf4) END IF
	IF ftyp[5] = "D" THEN LET m_data_ar[rec].df5 = gl_strToDate(m_data_ar[rec].cf5) END IF
	IF ftyp[6] = "D" THEN LET m_data_ar[rec].df6 = gl_strToDate(m_data_ar[rec].cf6) END IF
	IF ftyp[7] = "D" THEN LET m_data_ar[rec].df7 = gl_strToDate(m_data_ar[rec].cf7) END IF
	IF ftyp[8] = "D" THEN LET m_data_ar[rec].df8 = gl_strToDate(m_data_ar[rec].cf8) END IF
	IF ftyp[9] = "D" THEN LET m_data_ar[rec].df9 = gl_strToDate(m_data_ar[rec].cf9) END IF
	IF ftyp[10] = "D" THEN LET m_data_ar[rec].df10 = gl_strToDate(m_data_ar[rec].cf10) END IF
	IF ftyp[11] = "D" THEN LET m_data_ar[rec].df11 = gl_strToDate(m_data_ar[rec].cf11) END IF
	IF ftyp[12] = "D" THEN LET m_data_ar[rec].df12 = gl_strToDate(m_data_ar[rec].cf12) END IF

	IF ftyp[1] = "I" THEN LET m_data_ar[rec].if1 = m_data_ar[rec].cf1 END IF
	IF ftyp[2] = "I" THEN LET m_data_ar[rec].if2 = m_data_ar[rec].cf2 END IF
	IF ftyp[3] = "I" THEN LET m_data_ar[rec].if3 = m_data_ar[rec].cf3 END IF
	IF ftyp[4] = "I" THEN LET m_data_ar[rec].if4 = m_data_ar[rec].cf4 END IF
	IF ftyp[5] = "I" THEN LET m_data_ar[rec].if5 = m_data_ar[rec].cf5 END IF
	IF ftyp[6] = "I" THEN LET m_data_ar[rec].if6 = m_data_ar[rec].cf6 END IF
	IF ftyp[7] = "I" THEN LET m_data_ar[rec].if7 = m_data_ar[rec].cf7 END IF
	IF ftyp[8] = "I" THEN LET m_data_ar[rec].if8 = m_data_ar[rec].cf8 END IF
	IF ftyp[9] = "I" THEN LET m_data_ar[rec].if9 = m_data_ar[rec].cf9 END IF
	IF ftyp[10] = "I" THEN LET m_data_ar[rec].if10 = m_data_ar[rec].cf10 END IF
	IF ftyp[11] = "I" THEN LET m_data_ar[rec].if11 = m_data_ar[rec].cf11 END IF
	IF ftyp[12] = "I" THEN LET m_data_ar[rec].if12 = m_data_ar[rec].cf12 END IF
END FUNCTION --}}}
--------------------------------------------------------------------------------
