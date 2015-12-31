
--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.00.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

#+ Dynamic lookup table added to existing Window.
#+ $Id: gl_lookup2.4gl 334 2014-01-20 09:51:45Z test4j $

&include "genero_lib1.inc"
&include "gl_lookup.inc"

DEFINE ret SMALLINT

GLOBALS
  DEFINE xml_sch om.domdocument
  DEFINE xml_root om.domnode
END GLOBALS

CONSTANT MAX_RECS=2000
CONSTANT MAX_COLS=8

DEFINE data_ar DYNAMIC ARRAY OF RECORD
	DEF_DATA_AR
END RECORD
DEFINE recs INTEGER

#+ A generic dynamic lookup - Dynamic Table in Form Verison.
FUNCTION gl_lookup2( tabnam, cols, colts, ftyp, wher, ordby ) --{{{
	DEFINE tabnam, cols, colts, wher, ordby STRING
	DEFINE ftyp CHAR(MAX_COLS)
	DEFINE frm, vbox, grid, tabl, tabc, edit, curr  om.DomNode
	DEFINE hb,sp,titl om.DomNode
	DEFINE col_ar ARRAY[MAX_COLS] OF CHAR(18)
	DEFINE fn CHAR(4)
	DEFINE col_cnt SMALLINT
	DEFINE tot_recs,x,i,startIndex,bufferLength INTEGER
	DEFINE tok base.StringTokenizer
	DEFINE ttyp CHAR(1)
	DEFINE ttype CHAR(20)
	DEFINE tlen SMALLINT
	DEFINE xml_col ARRAY[MAX_COLS] OF om.DomNode
	DEFINE col_len ARRAY[MAX_COLS] OF SMALLINT
	DEFINE sel_stmt STRING
	DEFINE ret_key,ret_desc STRING
GL_MODULE_ERROR_HANDLER
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

-- Break column list into columns for table headings
	LET tok = base.StringTokenizer.create( cols, "," )
	LET col_cnt = 1
	WHILE tok.hasMoreTokens()
		LET col_ar[col_cnt] = tok.nextToken()
		LET col_cnt = col_cnt + 1
		IF col_cnt > MAX_COLS THEN EXIT WHILE END IF
	END WHILE
	LET col_cnt = col_cnt - 1

-- Prepare/Declare main cursor
	LET sel_stmt = 
		"SELECT "||cols CLIPPED||" FROM "||tabnam CLIPPED," WHERE "||wher
	IF ordby IS NOT NULL THEN
		LET sel_stmt = sel_stmt CLIPPED," ORDER BY "||ordby
	END IF
--	DISPLAY "lookup: sel_stmt:",sel_stmt
	PREPARE listpre FROM sel_stmt
	DECLARE listcur SCROLL CURSOR FOR listpre
-- If only one record then just return it's key.
	IF tot_recs = 1 THEN
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
		RETURN data_ar[1].cf1 --,data_ar[1].cf2
	END IF

	LET frm = gl_lookup2_open()
	LET vbox = frm.createChild('VBox')
	CALL vbox.setAttribute("style","gl_lookup2")
	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("name","gl_lookup2_titl")
	CALL grid.setAttribute("style","tabtitl")

-- Create a centered window title.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("style","tabtitl")
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

-- Create the table
	LET grid = vbox.createChild('Grid')
	CALL grid.setAttribute("name","gl_lookup2_tab")
	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName","tablistv")
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","20")
	CALL tabl.setAttribute("size","20")
	CALL tabl.setAttribute("posY","1")
	
-- Get column length from xml schema if xml_root is not null
	IF xml_root IS NOT NULL THEN
  	FOR x = 1 TO col_cnt
    	LET xml_col[x] = gl_findXmlCol(tabnam,col_ar[x],xml_root)
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
			LET col_ar[x] = tok.nextToken()
			LET x = x + 1
			IF x > MAX_COLS THEN EXIT WHILE END IF
		END WHILE
	END IF
	
-- Create Columns & Headings for the table.
	FOR i = 1 TO MAX_COLS
		FOR x = 1 TO 4
			CASE x
				WHEN 1 LET fn = "cf",i USING "&" LET ttyp = "C" LET tlen = 30
				WHEN 2 LET fn = "if",i USING "&" LET ttyp = "I" LET tlen = 10 
				WHEN 3 LET fn = "nf",i USING "&" LET ttyp = "N" LET tlen = 12
				WHEN 4 LET fn = "df",i USING "&" LET ttyp = "D" LET tlen = 10
			END CASE
			LET tabc = tabl.createChild('TableColumn')
			CALL tabc.setAttribute("colName",fn)
			LET edit = tabc.createChild('Edit')
			IF ftyp[i] != "C" AND ftyp[i] != "D"  THEN
				CALL edit.setAttribute("justify","right")
			END IF
			IF i > col_cnt OR ftyp[i] != ttyp THEN
				CALL tabc.setAttribute("text","empty")
				CALL edit.setAttribute("width",1)
				CALL tabc.setAttribute("hidden","1")
				CALL edit.setAttribute("hidden","1")
			ELSE
				CALL tabc.setAttribute("text",col_ar[i])
				IF col_len[i] IS NULL OR col_len[i] = 0 THEN
					CALL edit.setAttribute("width",tlen)
				ELSE
					CALL edit.setAttribute("width",col_len[i])
				END IF
			END IF
		END FOR
	END FOR

  GL_DBGMSG(2,"gl_lookup2: Adding buttons...")
-- Create centered buttons.
--	LET grid = vbox.createChild('Grid')
--	CALL grid.setAttribute("name","gl_lookup2_tail")
--  CALL grid.setAttribute("style","gl_lookup2_tail")
  LET hb = grid.createChild('HBox')
  CALL hb.setAttribute("posY","21")
  CALL hb.setAttribute("style","gl_lookup2_tail")
  LET sp = hb.createChild('SpacerItem')
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
  LET sp = hb.createChild('SpacerItem')

-- If less than MAX_RECS records then use a normal display array.
-- else use a paged array
	IF tot_recs < MAX_RECS THEN
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
			CALL gl_lookup_mvdta(data_ar,recs,ftyp)
			CALL gl_progBar(2,recs,"")
			LET recs = recs + 1
		END FOREACH
		LET recs = recs - 1
		CALL gl_progBar(3,recs,"")
		MESSAGE "Read ",recs," Rows."

		DISPLAY ARRAY data_ar TO tablistv.* ATTRIBUTE(COUNT=recs)
			BEFORE ROW
				CALL curr.setAttribute("text",arr_curr() USING "#,##&")
		END DISPLAY
		IF arr_curr() > 0 THEN
			LET ret_key = data_ar[ arr_curr() ].cf1
			LET ret_desc = data_ar[ arr_curr() ].cf2
		END IF
	ELSE
		OPEN listcur
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
					CALL gl_lookup_mvdta(data_ar,recs,ftyp)
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
	CALL gl_lookup2_close(frm)
	LET ret_key = ret_key.trim()
	LET ret_desc = ret_desc.trim()
	IF int_flag THEN
		RETURN NULL
	ELSE
		RETURN ret_key --,ret_desc
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Remove the lookup grid
FUNCTION gl_lookup2_close(frm) --{{{
	DEFINE frm, n om.DomNode
	
	LET n = frm.getFirstChild()
	DISPLAY "close: n=",n.getTagName()," frm=",frm.getTagName()
	WHILE n.getAttribute("name") != "gl_lookup2"
		DISPLAY "close: name=",n.getAttribute("name")
		LET n = n.getNext()
	END WHILE
	CALL frm.removeChild( n )

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Open the lookup Grid
FUNCTION gl_lookup2_open() --{{{
	DEFINE frm, grd, n, new om.DomNode
	DEFINE dd om.DomDocument
	DEFINE dn om.DomNode
	DEFINE x SMALLINT

	LET frm = gl_getFormN(NULL)
	LET n = frm.getFirstChild()
	LET grd = n
	IF grd.getTagName() = "HBox" THEN
		RETURN grd
	ELSE
		FOR x = 1 TO frm.getChildCount()
			IF grd.getTagName() != "TopMenu" AND grd.getTagName() != "ToolBar" THEN
				EXIT FOR
			END IF
			LET grd = frm.getChildByIndex(x)
		END FOR
		LET new = frm.createChild("HBox")
		CALL frm.insertBefore( new , n )
	END IF

	LET dd = om.DomDocument.Create("Tmp")
	LET dn = dd.getDocumentElement()
	IF grd.getAttribute("name") IS NULL THEN
		CALL grd.setAttribute("name", "gl_lookup2_tmp")
	END IF
	CALL gl_appendNode( new, grd, 0 )
	CALL frm.removeChild( grd )

	DISPLAY "open: frm=",frm.getTagName()
	DISPLAY " grd=",grd.getTagName()	
	DISPLAY " new=",new.getTagName()	
	DISPLAY " n=",n.getTagName()

	RETURN new

END FUNCTION --}}}