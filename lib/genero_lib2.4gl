
--------------------------------------------------------------------------------
-- Genero Library 2 - by Neil J Martin ( neilm@4js.com )
-- This library is intended as an example of useful library code for use with
-- Genero 1.33 & 2.00.
--
-- No warrantee of any kind, express or implied, is included with this software;
-- use at your own risk, responsibility for damages (if any) to anyone resulting
-- from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

&include "genero_lib1.inc"

CONSTANT FLDSTOPAGE = 16 -- No of fields to a folder page.

-- Used by copyScreen
DEFINE m_scr DYNAMIC ARRAY OF CHAR(400)

--------------------------------------------------------------------------------
#+ Dynamically Generate a screen form from a TypeInfo node of a record.
#+
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param tab Table name
#+ @param titl Title for a the Window.
FUNCTION gl2_dynForm( rec_n, tab, titl ) --{{{
	DEFINE rec_n, grd, ff, n om.domNode
	DEFINE nl om.nodeList
	DEFINE tab, titl STRING
	DEFINE typ CHAR(1)
	DEFINE win ui.Window
	DEFINE frm,fld om.domNode
	DEFINE x,fcnt,len,pgno SMALLINT
GL_MODULE_ERROR_HANDLER
	IF g_dbgLev > 0 THEN CALL rec_n.writeXML("n.xml") END IF
	
	LET win = ui.window.getCurrent()
	CALL win.setText(titl)
	LET frm =	gl_genForm("DynForm")

	LET nl = rec_n.selectByTagName("Field")	

	IF nl.getLength() >= FLDSTOPAGE THEN
		LET fld = frm.createChild("Folder")
		LET grd = fld.createChild("Page")
		CALL grd.setAttribute("text", "Page 1")
		LET grd = grd.createChild("Grid")
	ELSE
		LET grd = frm.createChild("Grid")
	END IF

	LET pgno = 1
	LET fcnt = 0
	FOR x = 1 TO nl.getLength()
		LET fcnt = fcnt + 1
		IF NOT (fcnt MOD FLDSTOPAGE) THEN
			LET pgno = pgno + 1
			LET grd = fld.createChild("Page")
			CALL grd.setAttribute("text", "Page "||pgno)
			LET grd = grd.createChild("Grid")
		END IF
		LET n = nl.item(x)
		LET ff = grd.createChild("Label")
		CALL ff.setAttribute("posY", x )
		CALL ff.setAttribute("posX", 1 )
		CALL ff.setAttribute("justify", "right" )
		CALL ff.setAttribute("text", gl2_niceLab( n.getAttribute("name"), TRUE )  )
-- Can't be done like that - LStr only appears in .42f files NOT in the AUI
--		LET loc = ff.createChild("LStr")
--		CALL loc.setAttribute("text", n.getAttribute("name") )

		LET ff = grd.createChild("FormField")
		CALL ff.setAttribute("name", tab||"."||n.getAttribute("name") )
		CALL ff.setAttribute("fieldId", x-1 )
		CALL ff.setAttribute("sqlTabName", tab )
		CALL ff.setAttribute("colName", n.getAttribute("name") )
		CALL gl2_getType( n.getAttribute("type") ) RETURNING typ,len
		IF len > 50 THEN
			LET n = ff.createChild("TextEdit")
			CALL n.setAttribute("height", 2 )
			LET len = 30
		ELSE
			IF typ = "D" THEN
				LET n = ff.createChild("DateEdit")
			ELSE
--				IF hasCombo( tab||"."||n.getAttribute("name") ) THEN
--					LET n = ff.createChild("ComboBox")
--					CALL n.setAttribute("sizePolicy", "dynamic")
--				ELSE
--					IF hasLookup( tab||"."||n.getAttribute("name") ) THEN
--						LET n = ff.createChild("ButtonEdit")
--						CALL n.setAttribute("action", "lookup")
--					ELSE
--						LET n = ff.createChild("Edit")
--					END IF
--				END IF
			END IF
		END IF
		CALL n.setAttribute("width", len )
		CALL n.setAttribute("gridWidth", len )
		CALL n.setAttribute("posY", x )
		CALL n.setAttribute("posX", 20 )
	END FOR
&ifndef genero13x
	LET grd = frm.createChild("RecordView")
	CALL grd.setAttribute("tabName",tab )
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		LET ff = grd.createChild("Link")
		CALL ff.setAttribute("colName",n.getAttribute("name"))
		CALL ff.setAttribute("fieldIdRef",x-1)
	END FOR
&endif

--	CALL frm.writeXml("temp.42f")

END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Used becaues combo/form initialize doesn't happen on dynamic forms.
FUNCTION gl2_dynpopCombos() --{{{
	DEFINE nl om.nodeList
	DEFINE n om.domNode
	DEFINE x SMALLINT
	DEFINE cb ui.comboBox

	LET n = gl_getFormN( NULL )
	LET nl = n.selectByTagName("ComboBox")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		LET n = n.getParent()
		GL_DBGMSG(1,"gl2_dynpopCombos: Got combobox node '"||n.getAttribute( "name" )||"'")
		LET cb = ui.comboBox.forName( n.getAttribute( "colName" ) )
		IF cb IS NULL THEN
			GL_DBGMSG(0,"gl2_dynpopCombos: Failed to find combobox '"||n.getAttribute( "colName" )||"'")
		ELSE
--			CALL popCombo( cb ) -- This must exist in your code!!
		END IF
	END FOR
END FUNCTION --}}}
--  -------------------------------------------------------------------------------
#+ Get the database column type and return a simple char and len value.
#+ NOTE: SMALLINT INTEGER SERIAL DECIMAL=N, DATE=D, CHAR VARCHAR=C
#+
#+ @param s_typ Type
#+ @return CHAR(1),SMALLINT
FUNCTION gl2_getType( s_typ ) --{{{
	DEFINE s_typ STRING
	DEFINE typ CHAR(1)
	DEFINE len SMALLINT

--TODO: Use I for smallint, integer, serial, N for numeric, decimal
	LET len = 10
	CASE s_typ.subString(1,3)
		WHEN "SMA" LET typ = "N" LET len = 5
		WHEN "INT" LET typ = "N" LET len = 10
		WHEN "SER" LET typ = "N" LET len = 10
		WHEN "DEC" LET typ = "N" LET len = 12
		WHEN "DAT" LET typ = "D" LET len = 10
		WHEN "CHA" LET typ = "C" LET len = gl2_getLength( s_typ )
		WHEN "VAR" LET typ = "C" LET len = gl2_getLength( s_typ )
	END CASE
		
	RETURN typ,len

END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Get the length from a type definiation ie CHAR(10) returns 10
#+
#+ @param s_typ Type
#+ @return Length from type or defaults to 10
FUNCTION gl2_getLength( s_typ ) --{{{
	DEFINE s_typ STRING
	DEFINE x,y SMALLINT
	
--TODO: Handle decimal, numeric ie values with , in.
	LET x = s_typ.getIndexOf("(",4)
	LET y = s_typ.getIndexOf(")",x+1)
	IF x > 0 AND y > 0 THEN
		RETURN s_typ.subString(x+1,y-1)
	END IF
	RETURN 10
END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Generate an insert statement.
#+
#+ @param tab String: Table name
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION gl2_genInsert( tab, rec_n, fixQuote ) --{{{
	DEFINE tab STRING
	DEFINE rec_n, n om.domNode
	DEFINE nl om.nodeList
	DEFINE l_stmt,val STRING
	DEFINE fixQuote, x,len SMALLINT
	DEFINE typ,comma CHAR(1)

	LET l_stmt = "INSERT INTO "||tab||" VALUES("
	LET nl = rec_n.selectByTagName("Field")	
	LET comma = " "
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CALL gl2_getType( n.getAttribute("type") ) RETURNING typ,len
		LET val = n.getAttribute("value")
		IF val IS NULL THEN 
			LET l_stmt = l_stmt.append(comma||"NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(comma||val)
			ELSE
				IF fixQuote THEN LET val = gl2_fixQuote( val ) END IF
				LET l_stmt = l_stmt.append(comma||"'"||val||"'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(")")
--	DISPLAY "Stmt:",l_stmt

	RETURN l_stmt
END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Generate an update statement.
#+
#+ @param tab Table name
#+ @param wher 	Where Clause
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param ser_col Serial Column number or 0 ( colNo of the column that is a serial )
#+ @return SQL Statement
FUNCTION gl2_genUpdate( tab, wher, rec_n, ser_col ) --{{{
	DEFINE tab, wher STRING
	DEFINE ser_col SMALLINT
	DEFINE rec_n, n om.domNode
	DEFINE l_stmt,val STRING
	DEFINE nl om.nodeList
	DEFINE x,len SMALLINT
	DEFINE typ,comma CHAR(1)

	IF g_dbgLev > 0 THEN CALL rec_n.writeXML("u.xml") END IF

	LET l_stmt = "UPDATE "||tab||" SET "
	LET nl = rec_n.selectByTagName("Field")	
	LET comma = " "
	FOR x = 1 TO nl.getLength()
		IF x = ser_col THEN CONTINUE FOR END IF -- Skip Serial Column
		LET n = nl.item(x)
		CALL gl2_getType( n.getAttribute("type") ) RETURNING typ,len
		LET val = n.getAttribute("value")
		LET l_stmt = l_stmt.append(comma||n.getAttribute("name")||" = ")
		IF val IS NULL THEN
			LET l_stmt = l_stmt.append("NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(val)
			ELSE
				LET l_stmt = l_stmt.append("'"||val||"'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(" WHERE "||wher)
--	DISPLAY "Stmt:",l_stmt

	RETURN l_stmt
END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Generate an update statement.
#+
#+ @param tab Table name
#+ @param wher 	Where Clause
#+ @param rec_n TypeInfo Node for NEW record to udpate
#+ @param rec_o TypeInfo Node for ORIGINAL record to udpate
#+ @param ser_col Serial Column number or 0 ( colNo of the column that is a serial )
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION gl2_genUpdate2( tab, wher, rec_n, rec_o, ser_col, fixQuote ) --{{{
	DEFINE tab, wher STRING
	DEFINE ser_col, fixQuote SMALLINT
	DEFINE rec_n,rec_o, n, o om.domNode
	DEFINE l_stmt,val, val_o STRING
	DEFINE nl_n, nl_o om.nodeList
	DEFINE x,len SMALLINT
	DEFINE typ,comma CHAR(1)

	IF g_dbgLev > 0 THEN CALL rec_n.writeXML("u.xml") END IF

	LET l_stmt = "UPDATE "||tab||" SET "
	LET nl_n = rec_n.selectByTagName("Field")	
	LET nl_o = rec_o.selectByTagName("Field")	
	LET comma = " "
	FOR x = 1 TO nl_n.getLength()
		IF x = ser_col THEN CONTINUE FOR END IF -- Skip Serial Column
		LET n = nl_n.item(x)
		LET o = nl_o.item(x)
		CALL gl2_getType( n.getAttribute("type") ) RETURNING typ,len
		LET val_o = o.getAttribute("value")
		LET val = n.getAttribute("value")
		IF (val_o IS NULL AND val IS NULL) OR val_o = val THEN CONTINUE FOR END IF
		GL_DBGMSG(3,n.getAttribute("name")||" N:"||val||" O:"||val_o)
		LET l_stmt = l_stmt.append(comma||n.getAttribute("name")||" = ")
		IF val IS NULL THEN
			LET l_stmt = l_stmt.append("NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(val)
			ELSE
				IF fixQuote THEN LET val = gl2_fixQuote( val ) END IF
				LET l_stmt = l_stmt.append("'"||val||"'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(" WHERE "||wher)
--	DISPLAY "Stmt:",l_stmt

	RETURN l_stmt
END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Dynamically pick fields to do a column listing of from a table.
#+
FUNCTION gl2_fixQuote(in) --{{{
	DEFINE in STRING
	DEFINE y SMALLINT
	DEFINE sb base.StringBuffer

	LET y = in.getIndexOf("'",1)
	IF y > 0 THEN
		GL_DBGMSG(0,"Single Quote Found!")
		LET sb = base.StringBuffer.create()
		CALL sb.append( in )
		CALL sb.replace("'","''",0)
		LET in = sb.toString()
	END IF

	RETURN in
END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ Dynamically pick fields to do a column listing of from a table.
#+
#+ @param tab Table name
#+ @param rec_n TypeInfo Node for record to udpate
#+ @return NULL or key field from selected row.
FUNCTION gl2_fldChoose( tab, rec_n ) --{{{
	DEFINE tab STRING
	DEFINE rec_n,n2 om.domNode
	DEFINE lkup_d om.domDocument
	DEFINE lkup_n om.domNode
	DEFINE nl om.NodeList
	DEFINE c om.domNode
	DEFINE cols_a DYNAMIC ARRAY OF RECORD -- table columns
			nam STRING,
			typ CHAR(20)
		END RECORD
	DEFINE cols_c DYNAMIC ARRAY OF RECORD -- column colours
			c1 STRING,
			c2 STRING
		END RECORD
	DEFINE chns_n DYNAMIC ARRAY OF SMALLINT -- choosen column no
	DEFINE x,y SMALLINT
	DEFINE choosen STRING
	DEFINE key STRING
	DEFINE ordby, cols STRING
	DEFINE typ CHAR(1)
	DEFINE len SMALLINT
	
--	CALL rec_n.writeXML("n.xml")

	LET nl = rec_n.selectByTagName("Field")
	IF nl.getLength() < 1 THEN RETURN NULL END IF
	
	FOR x = 1 TO nl.getLength()
		LET n2 = nl.item(x)
		LET cols_a[ cols_a.getLength() + 1 ].nam = n2.getAttribute("name")
		LET cols_a[ cols_a.getLength() ].typ = n2.getAttribute("type")
		LET chns_n[ chns_n.getLength() + 1 ] = FALSE
	END FOR

	CALL gl2_fldChooserF(TRUE)

	DISPLAY tab TO tablename
	DISPLAY cols_a[1].nam TO keyfield

-- Add key field.
{
	LET choosen = cols_a[ 1 ].nam || ASCII(10)
	LET chns_n[ 1 ] = TRUE
	LET cols_c[ 1 ].c1 = "red"
	LET ordby = cols_a[ 1 ].nam
}
	DISPLAY BY NAME choosen, ordby

	LET int_flag = FALSE
	DISPLAY ARRAY cols_a TO cols_arr.* ATTRIBUTES( COUNT=cols.getLength() )
		BEFORE DISPLAY
			CALL DIALOG.setCellAttributes( cols_c )
			CALL fgl_set_arr_curr(2)
		ON ACTION ACCEPT
			IF NOT chns_n[ arr_curr() ] THEN
				LET chns_n[ arr_curr() ] = TRUE
				LET cols_c[ arr_curr() ].c1 = "red"
				LET choosen = choosen.append( cols_a[ arr_curr() ].nam || ASCII(10) )
				DISPLAY BY NAME choosen
				CALL DIALOG.setCellAttributes( cols_c )
				MESSAGE ""
			ELSE
				MESSAGE "Already Choosen!"
			END IF
		ON ACTION okay
			IF chns_n.getLength() < 1 THEN
				CALL fgl_winMessage("Error","Must select at least 1 Column.","exclamation")
			ELSE	
				EXIT DISPLAY
			END IF

		ON ACTION clear
			FOR x = 2 TO chns_n.getLength()
				LET chns_n[ arr_curr() ] = FALSE	
				DISPLAY BY NAME choosen
				LET cols_c[ arr_curr() ].c1 = "black"
			END FOR
			CALL DIALOG.setCellAttributes( cols_c )
			LET choosen = cols_a[ 1 ].nam || ASCII(10)
			DISPLAY BY NAME choosen
			
		ON ACTION ordby
			IF chns_n[ arr_curr() ] THEN
				LET ordby = cols_a[ arr_curr() ].nam
				DISPLAY BY NAME ordby
			ELSE
				CALL fgl_winMessage("Error","Must by a selected field!","exclamation")
			END IF
	END DISPLAY

	CALL gl2_fldChooserF(FALSE)

	IF int_flag THEN RETURN NULL END IF

	LET lkup_d = om.domDocument.Create("lookup")
	LET lkup_n = lkup_d.getDocumentElement()
	CALL lkup_n.setAttribute("tabname",tab)

	LET cols = NULL
	FOR x = 1 TO chns_n.getLength()
		IF NOT chns_n[ x ] THEN CONTINUE FOR END IF

		LET c = lkup_n.createChild("Column")
		CALL c.setAttribute("colname",cols_a[ x ].nam )
		CALL c.setAttribute("text", gl2_niceLab( cols_a[ x ].nam, FALSE ) CLIPPED )
		LET typ = cols_a[ x ].typ[1]
		IF cols_a[ x ].typ[1,3] = "DAT" THEN LET len = 10 END IF
		IF cols_a[ x ].typ[1,3] = "INT" THEN LET len = 10 END IF
		IF cols_a[ x ].typ[1,3] = "DEC" THEN LET typ = "N" LET len = 12 END IF
		IF cols_a[ x ].typ[1,3] = "SER" THEN LET typ = "I" LET len = 10  END IF
		IF cols_a[ x ].typ[1,3] = "SMA" THEN LET typ = "I" LET len = 5  END IF
		IF cols_a[ x ].typ[1,3] = "VAR" THEN LET typ = "C" END IF
		IF typ = "C" THEN
			FOR y = 5 TO LENGTH( cols_a[ x ].typ )
				IF cols_a[ x ].typ[y] = "(" THEN
					LET len = cols_a[ x ].typ[y+1, LENGTH( cols_a[ x ].typ )-1 ]
				END IF
			END FOR
		END IF
		CALL c.setAttribute("type", typ )
		CALL c.setAttribute("width", len )
		
	END FOR

	CALL lkup_n.setAttribute("where","1=1")
	CALL lkup_n.setAttribute("orderby",ordby )
	
	CALL lkup_n.writeXML("lookup.xml")

	LET key = gl2_lookup( lkup_n )

	RETURN key

END FUNCTION --}}}
--  ------------------------------------------------------------------------------
#+ INTERNAL ONLY - Generate the form for the field chooser.
#+ NOTE: Created by 42fto4gl util program.
FUNCTION gl2_fldChooserF( openWin ) --{{{
	DEFINE openWin SMALLINT
	DEFINE w,n4,n5,n6 om.domNode
	DEFINE form om.domNode
	DEFINE c1_mainvbox om.domNode
	DEFINE c2_hbox om.domNode
	DEFINE c3_tab1 om.domNode
	DEFINE c4_grid om.domNode
	DEFINE c5_hbox om.domNode
	DEFINE c6_hbox om.domNode
	DEFINE c7_grid om.domNode
	DEFINE c8_group om.domNode
	DEFINE c9_grid om.domNode
	DEFINE c10_grid om.domNode
	DEFINE c11_hbox om.domNode
	DEFINE c12_grid om.domNode

	IF NOT openWin THEN
		CLOSE WINDOW w_form
		RETURN
	END IF

	OPEN WINDOW w_form AT 1,1 WITH 1 ROWS, 1 COLUMNS
	LET w = gl_getWinNode( NULL ) 
	LET form = gl_genForm("gl2_fldChooserF")
	CALL form.setAttribute("name","form")
	CALL form.setAttribute("text","Lookup Field Chooser")
	CALL w.setAttribute("text", "Lookup Field Chooser")
	CALL form.setAttribute("style","dialog2")
	CALL w.setAttribute("style", "dialog2")
	CALL form.setAttribute("width","4")
	CALL form.setAttribute("height","1")
	CALL form.setAttribute("formLine","2")

	LET c1_mainvbox = form.createChild("VBox")
	CALL c1_mainvbox.setAttribute("name","mainvbox")

	LET c2_hbox = c1_mainvbox.createChild("HBox")

	LET c3_tab1 = c2_hbox.createChild("Table")
	CALL c3_tab1.setAttribute("pageSize","18")
	CALL c3_tab1.setAttribute("name","tab1")
	CALL c3_tab1.setAttribute("tabName","cols_arr")
	LET n4 = c3_tab1.createChild("TableColumn")
	CALL n4.setAttribute("text","Columns")
	CALL n4.setAttribute("name","formonly.cols")
	CALL n4.setAttribute("colName","cols")
	CALL n4.setAttribute("fieldId","0")
	CALL n4.setAttribute("sqlTabName","formonly")
	CALL n4.setAttribute("tabIndex","1")
	LET n5 = n4.createChild("Edit")
	CALL n5.setAttribute("width","17")
	LET n4 = c3_tab1.createChild("TableColumn")
	CALL n4.setAttribute("text","Type")
	CALL n4.setAttribute("name","formonly.typs")
	CALL n4.setAttribute("colName","typs")
	CALL n4.setAttribute("fieldId","1")
	CALL n4.setAttribute("sqlTabName","formonly")
	CALL n4.setAttribute("tabIndex","2")
	LET n5 = n4.createChild("Edit")
	CALL n5.setAttribute("width","14")

	LET c4_grid = c2_hbox.createChild("Grid")
	CALL c4_grid.setAttribute("width","25")
	CALL c4_grid.setAttribute("height","9")
	LET n4 = c4_grid.createChild("Label")
	CALL n4.setAttribute("text","Choosen")
	CALL n4.setAttribute("posY","0")
	CALL n4.setAttribute("posX","0")
	CALL n4.setAttribute("gridWidth","7")
	LET n4 = c4_grid.createChild("FormField")
	CALL n4.setAttribute("name","formonly.choosen")
	CALL n4.setAttribute("colName","choosen")
	CALL n4.setAttribute("fieldId","2")
	CALL n4.setAttribute("sqlTabName","formonly")
	CALL n4.setAttribute("tabIndex","3")
	LET n5 = n4.createChild("TextEdit")
	CALL n5.setAttribute("width","23")
	CALL n5.setAttribute("height","7")
	CALL n5.setAttribute("wantReturns","1")
	CALL n5.setAttribute("scroll","1")
	CALL n5.setAttribute("stretch","both")
	CALL n5.setAttribute("posY","1")
	CALL n5.setAttribute("posX","1")
	CALL n5.setAttribute("gridWidth","23")
	CALL n5.setAttribute("gridHeight","7")

	LET c5_hbox = c4_grid.createChild("HBox")
	CALL c5_hbox.setAttribute("posY","8")
	CALL c5_hbox.setAttribute("posX","1")
	CALL c5_hbox.setAttribute("gridWidth","23")
	LET n5 = c5_hbox.createChild("SpacerItem")
	LET n5 = c5_hbox.createChild("Label")
	CALL n5.setAttribute("text","Ord By:")
	LET n5 = c5_hbox.createChild("FormField")
	CALL n5.setAttribute("name","formonly.ordby")
	CALL n5.setAttribute("colName","ordby")
	CALL n5.setAttribute("fieldId","5")
	CALL n5.setAttribute("sqlTabName","formonly")
	CALL n5.setAttribute("tabIndex","4")
	LET n6 = n5.createChild("Edit")
	CALL n6.setAttribute("width","10")

	LET c6_hbox = c1_mainvbox.createChild("HBox")

	LET c7_grid = c6_hbox.createChild("Grid")
	CALL c7_grid.setAttribute("width","28")
	CALL c7_grid.setAttribute("height","3")

	LET c8_group = c7_grid.createChild("Group")
	CALL c8_group.setAttribute("text","Details")
	CALL c8_group.setAttribute("posY","0")
	CALL c8_group.setAttribute("posX","0")
	CALL c8_group.setAttribute("gridWidth","28")
	CALL c8_group.setAttribute("gridHeight","4")
	LET n5 = c8_group.createChild("Label")
	CALL n5.setAttribute("text","Table:")
	CALL n5.setAttribute("posY","1")
	CALL n5.setAttribute("posX","1")
	CALL n5.setAttribute("gridWidth","6")
	LET n5 = c8_group.createChild("FormField")
	CALL n5.setAttribute("name","formonly.tablename")
	CALL n5.setAttribute("colName","tablename")
	CALL n5.setAttribute("fieldId","3")
	CALL n5.setAttribute("sqlTabName","formonly")
	CALL n5.setAttribute("tabIndex","5")
	LET n6 = n5.createChild("Edit")
	CALL n6.setAttribute("width","18")
	CALL n6.setAttribute("posY","1")
	CALL n6.setAttribute("posX","8")
	CALL n6.setAttribute("gridWidth","18")
	LET n5 = c8_group.createChild("Label")
	CALL n5.setAttribute("text","Key:")
	CALL n5.setAttribute("posY","2")
	CALL n5.setAttribute("posX","1")
	CALL n5.setAttribute("gridWidth","4")
	LET n5 = c8_group.createChild("FormField")
	CALL n5.setAttribute("name","formonly.keyfield")
	CALL n5.setAttribute("colName","keyfield")
	CALL n5.setAttribute("fieldId","4")
	CALL n5.setAttribute("sqlTabName","formonly")
	CALL n5.setAttribute("tabIndex","6")
	LET n6 = n5.createChild("Edit")
	CALL n6.setAttribute("width","18")
	CALL n6.setAttribute("posY","2")
	CALL n6.setAttribute("posX","8")
	CALL n6.setAttribute("gridWidth","18")

	LET c9_grid = c6_hbox.createChild("Grid")
	CALL c9_grid.setAttribute("width","4")
	CALL c9_grid.setAttribute("height","1")

	LET c10_grid = c6_hbox.createChild("Grid")
	CALL c10_grid.setAttribute("width","25")
	CALL c10_grid.setAttribute("height","3")
	LET n4 = c10_grid.createChild("Label")
	CALL n4.setAttribute("text"," ")
	CALL n4.setAttribute("posY","0")
	CALL n4.setAttribute("posX","1")
	CALL n4.setAttribute("gridWidth","3")
	LET n4 = c10_grid.createChild("Label")
	CALL n4.setAttribute("text"," ")
	CALL n4.setAttribute("posY","1")
	CALL n4.setAttribute("posX","1")
	CALL n4.setAttribute("gridWidth","3")

	LET c11_hbox = c10_grid.createChild("HBox")
	CALL c11_hbox.setAttribute("posY","2")
	CALL c11_hbox.setAttribute("posX","1")
	CALL c11_hbox.setAttribute("gridWidth","23")
	LET n5 = c11_hbox.createChild("Button")
	CALL n5.setAttribute("name","okay")
	CALL n5.setAttribute("width","4")
	CALL n5.setAttribute("text","Okay")
--	CALL n5.setAttribute("image","ok2")
	LET n5 = c11_hbox.createChild("Button")
	CALL n5.setAttribute("name","clear")
	CALL n5.setAttribute("width","5")
	CALL n5.setAttribute("text","Clear")
--	CALL n5.setAttribute("image","reset")
	LET n5 = c11_hbox.createChild("Button")
	CALL n5.setAttribute("name","ordby")
	CALL n5.setAttribute("width","5")
	CALL n5.setAttribute("text","Order By")
--	CALL n5.setAttribute("image","switch")
	LET n5 = c11_hbox.createChild("Button")
	CALL n5.setAttribute("name","cancel")
	CALL n5.setAttribute("width","6")
	CALL n5.setAttribute("text","Cancel")
--	CALL n5.setAttribute("image","cancel2")
	LET n5 = c11_hbox.createChild("SpacerItem")

	LET c12_grid = c6_hbox.createChild("Grid")
	CALL c12_grid.setAttribute("width","4")
	CALL c12_grid.setAttribute("height","1")

END FUNCTION --}}} 
--  ------------------------------------------------------------------------------
#+ Upshift 1st letter : replace _ with space : split capitalised names
#+
#+ @param lab Label to convert
#+ @param colon Boolean - Add trailing Colon ( Table columns title don't what one! )
FUNCTION gl2_niceLab( lab, colon ) --{{{
	DEFINE lab CHAR(60)
	DEFINE colon SMALLINT
	DEFINE x,len SMALLINT

	LET len = LENGTH( lab )

	FOR x = 1 TO len
		IF lab[x] >= "A" AND lab[x] <= "Z" THEN 
			LET lab = lab[1,x-1]||" "||lab[x,60]
			LET len = len + 1
			LET x = x + 1
		END IF
		IF lab[x] = "_" THEN LET lab[x] = " " END IF
	END FOR
	LET lab[1] = UPSHIFT(lab[1])

	IF colon THEN
		RETURN lab CLIPPED||":"
	END IF
	RETURN lab
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Copy current screen to clipboard.
#+
FUNCTION gl2_copyScreen() --{{{
	DEFINE st_node, n om.DomNode
	DEFINE nl om.nodeList
	DEFINE x, y, l, ret SMALLINT

	LET st_node = gl_getFormN(NULL)
	
	LET nl = st_node.selectByTagName("VBox")
	IF nl.getLength() < 1 THEN
		LET nl = st_node.selectByTagName("Form")
	END IF
	IF nl.getLength() < 1 THEN RETURN END IF
	LET n = nl.item(1)

	CALL m_scr.clear()

--	CALL gl2_copyScreen2( n, 1, 1 )
	CALL gl2_copyScreen3( n, 1, 0, NULL, TRUE )

	CALL ui.interface.frontCall("standard","cbclear","",ret )
	LET l = m_scr.getLength()
	FOR x = 1 TO l
		IF m_scr[x] IS NULL THEN LET m_scr[x] = " " END IF
		IF m_scr[x] != " " OR (m_scr[x] = " " AND m_scr[x+1] != " ") THEN
			CALL ui.interface.frontCall("standard","cbadd",(m_scr[x] CLIPPED)||"\n",ret )
		END IF
	END FOR

-- Now to folder pages.
	LET nl = st_node.selectByTagName("Page")
	IF nl.getLength() < 1 THEN RETURN END IF

	FOR y = 1 TO nl.getLength()
		CALL m_scr.clear()
		LET n = nl.item(y) 
		--DISPLAY "Processing Page:",n.getAttribute("name")
		CALL gl2_copyScreen3( n, 1, 0, NULL, TRUE )
		CALL ui.interface.frontCall("standard","cbadd","\n"||n.getAttribute("text")||":\n",ret )
		LET l = m_scr.getLength()
		FOR x = 1 TO l
			IF m_scr[x] IS NULL THEN LET m_scr[x] = " " END IF
			IF m_scr[x] != " " OR (m_scr[x] = " " AND m_scr[x+1] != " ") THEN
				CALL ui.interface.frontCall("standard","cbadd",(m_scr[x] CLIPPED)||"\n",ret )
			END IF
		END FOR
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gl2_copyScreen3( n, lv, go, p_tag, ignore_pages )
	DEFINE n, n2 om.DomNode
	DEFINE w, lv, go, x, y, ignore_pages SMALLINT
	DEFINE val, tag, p_tag, val2, val3, val4, len STRING

	LET n = n.getFirstChild()
	WHILE n IS NOT NULL
		LET tag = n.getTagname()
		LET val2 = NULL
		LET val3 = NULL

		CASE tag
			WHEN "Edit" EXIT WHILE
			WHEN "TextEdit" EXIT WHILE
			WHEN "TopMenuGroup" EXIT WHILE
			WHEN "ToolBar" EXIT WHILE
			WHEN "TopMenuCommand" EXIT WHILE
			WHEN "ToolBarItem" EXIT WHILE
			WHEN "Page" IF ignore_pages THEN LET n = n.getNext() CONTINUE WHILE END IF
			WHEN "Grid" IF n.getAttribute("name") = "fash05_sales" THEN LET n = n.getNext() CONTINUE WHILE END IF
		END CASE

		IF tag = "FormField" THEN
			LET val = n.getAttribute("value")
			LET val = val.trim()
			LET n2 = n.getFirstChild()
			IF n2.getTagName() = "TextEdit" THEN
				LET w = n2.getAttribute("width")	
				LET len = val.getLength()
				IF len > w THEN
					IF len > w*2 THEN
						--DISPLAY "SETTING val2:",w+1,",",w*2
						LET val2 = val.subString(w+1,w*2)
						IF len > w*3 THEN
							LET val3 = val.subString((w*2)+1,w*3)
							IF len > w*4 THEN
								LET val4 = val.subString((w*3)+1,w*4)
							ELSE
								LET val4 = val.subString((w*3)+1,len)
							END IF
						ELSE
							LET val3 = val.subString((w*2)+1,len)
						END IF
					ELSE
						LET val2 = val.subString(w+1,len)
					END IF
				END IF
				LET val = val.subString(1,w)
				GL_DBGMSG(3, "TEXTEDIT - w:"||w||" Len:"||len||"\nval:"||val||"\nval2:"||val2||"\nval3:"||val3)
			END IF
			LET x = n2.getAttribute("posX") + 1
			LET y = n2.getAttribute("posY") + 1
		ELSE
			LET val = n.getAttribute("text")
			LET x = n.getAttribute("posX") + 1
			LET y = n.getAttribute("posY") + 1
		END IF
		IF x IS NULL THEN LET x = 1 END IF
		IF y IS NULL THEN LET y = 1 END IF

		IF val IS NOT NULL THEN
			LET y = y + go
			IF tag = "Group" THEN
				LET go = go + 1 -- Add 1 for the group title.
				LET x = x + 1 -- Indent Group Title.
				LET m_scr[y] = "--------------------------------------------------------------------------------"
			END IF
			GL_DBGMSG(3, tag||" X:"||x||"  Y:"||y||"  GO:"||go)
			LET m_scr[y][x,x+val.getLength()] = val.trim()
			IF val2 IS NOT NULL THEN LET m_scr[y+1][x,x+val2.getLength()] = val2.trim() END IF
			IF val3 IS NOT NULL THEN LET m_scr[y+2][x,x+val3.getLength()] = val3.trim() END IF
			IF val4 IS NOT NULL THEN LET m_scr[y+3][x,x+val4.getLength()] = val4.trim() END IF
		END IF

		IF tag = "Group" OR tag = "Grid" THEN
			IF go > 0 THEN LET go = y END IF
		END IF

		GL_DBGMSG(3, lv||":"||( lv SPACES )||":"||p_tag||" This Tag:"||tag||" X:"||x||"  Y:"||y||"  GO:"||go||"  Val:"||val)

		CALL gl2_copyScreen3( n, lv+1, go, tag, ignore_pages )

		LET n = n.getNext()	
	END WHILE

END FUNCTION --}}}
