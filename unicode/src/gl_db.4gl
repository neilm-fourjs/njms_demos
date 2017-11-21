
#+ General library code for Database access.
#+

IMPORT os
IMPORT FGL gl_lib

&include "genero_lib.inc"
&include "gl_db.inc"

PUBLIC DEFINE m_cre_db BOOLEAN

PUBLIC DEFINE m_dbtyp STRING
PUBLIC DEFINE m_dbnam STRING
PUBLIC DEFINE m_dbdes STRING
PUBLIC DEFINE m_dbsrc STRING
PUBLIC DEFINE m_dbdrv STRING
PUBLIC DEFINE m_dbdir STRING
PUBLIC DEFINE m_dbcon STRING
PUBLIC DEFINE m_dbspa STRING

FUNCTION gldb_connect( l_db STRING )
	DEFINE l_msg STRING
	DEFINE l_lockMode, l_fglprofile BOOLEAN

	GL_MODULE_ERROR_HANDLER
	LET l_fglprofile = FALSE

-- setup stuff from environment or defaults
	IF l_db IS NULL OR l_db = " " THEN LET l_db = fgl_getenv("DBNAME") END IF
	IF l_db IS NULL OR l_db = " " THEN LET l_db = DEF_DBNAME END IF
	LET m_dbnam = l_db

	IF m_dbspa IS NULL THEN	LET m_dbdir = fgl_getenv("DBDIR") END IF
	IF m_dbdir IS NULL OR m_dbdir = " " THEN LET m_dbdir = DEF_DBDIR END IF

	IF m_dbspa IS NULL THEN	LET m_dbspa = fgl_getenv("DBSPACE") END IF
	IF m_dbspa IS NULL OR m_dbspa = " " THEN LET m_dbspa = DEF_DBSPACE END IF

	IF m_dbdrv IS NULL THEN LET m_dbdrv = fgl_getenv("DBDRIVER") END IF
	IF m_dbdrv IS NULL OR m_dbdrv = " " THEN LET m_dbdrv = DEF_DBDRIVER END IF

-- setup stuff from fglprofile
	LET l_msg = fgl_getresource("dbi.database."||l_db||".source")
	IF l_msg IS NOT NULL AND l_msg != " " THEN
		LET m_dbsrc = l_msg
		LET l_fglprofile = TRUE
	END IF
	LET l_msg = fgl_getresource("dbi.database."||m_dbnam||".driver")
	IF l_msg IS NULL OR l_msg = " " THEN
		LET l_msg = fgl_getresource("dbi.default.driver")
	END IF
	IF l_msg IS NOT NULL AND l_msg != " " THEN
		LET m_dbdrv = l_msg
		GL_DBGMSG(0, SFMT("Database Driver: %1 from fglprofile:%2",m_dbdrv,fgl_getEnv("FGLPROFILE")))
	ELSE
		GL_DBGMSG(0, "Database Driver:"||m_dbdrv)
	END IF
 
	LET m_dbtyp = m_dbdrv.subString(4,6)
	LET m_dbcon = m_dbnam
	LET l_lockMode = TRUE
	IF NOT l_fglprofile THEN -- no fglprofile setting to do it the long way.
		CASE m_dbtyp
			WHEN "pgs"
				LET m_dbsrc = fgl_getEnv("PGSERVER") -- ???
				LET m_dbdes = "PostgreSQL "||m_dbdrv.subString(7,9)
				LET m_dbcon = "db+driver='"||m_dbdrv||"',source='"||m_dbsrc||"'"
			WHEN "ifx"
				LET m_dbsrc = fgl_getEnv("INFORMIXSERVER")
				LET m_dbdes = "Informix "||m_dbdrv.subString(7,9)
				LET m_dbsrc = fgl_getEnv("INFORMIXSERVER")
				LET m_dbcon = l_db
			WHEN "sqt"	
				LET m_dbsrc = fgl_getEnv("SQLITEDB")
				IF m_dbsrc IS NULL OR m_dbsrc = " " THEN LET m_dbsrc = os.path.join(m_dbdir,m_dbnam||".db") END IF
				LET l_lockMode = FALSE
				LET m_dbdes = "SQLite "||m_dbdrv.subString(7,9)
				LET m_dbcon = "db+driver='"||m_dbdrv||"',source='"||m_dbsrc||"'"
		END CASE
	END IF

	TRY
		DISPLAY "Connecting to "||m_dbnam||" Using:",m_dbdrv, " Source:",m_dbsrc," ..."
		DATABASE m_dbcon
		DISPLAY "Connected to "||m_dbnam||" Using:",m_dbdrv, " Source:",m_dbsrc
	CATCH
		LET l_msg = "Connection to database failed\nDB:",m_dbnam,"\nSource:",m_dbsrc, "\nDriver:",m_dbdrv,"\n",
			 "Status:",SQLCA.SQLCODE,"\n",SQLERRMESSAGE
		DISPLAY l_msg
		IF m_cre_db AND m_dbtyp = "ifx" AND SQLCA.SQLCODE = -329 THEN
			CALL gldb_ifx_createdb()
			LET l_msg = NULL
		END IF
		IF m_cre_db AND m_dbtyp = "sqt" AND SQLCA.SQLCODE = -6372 THEN
			CALL gldb_sqt_createdb(m_dbdir, m_dbsrc)
			LET l_msg = NULL
		END IF
		IF SQLCA.SQLCODE = -6366 THEN
			RUN "echo $LD_LIBRARY_PATH;ldd $FGLDIR/dbdrivers/"||m_dbdrv||".so"
		END IF
		IF l_msg IS NOT NULL THEN
			CALL gl_lib.gl_errPopup(SFMT(%"Fatal Error %1",l_msg))
			EXIT PROGRAM
		END IF
	END TRY

	IF l_lockMode THEN
		SET LOCK MODE TO WAIT 3 
	END IF

	CALL fgl_setEnv("DBCON",m_dbnam)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gldb_getDBType() RETURNS STRING
	DEFINE drv STRING
	IF m_dbtyp IS NULL THEN
		LET drv = fgl_getenv("DBDRIVER")
		IF drv IS NULL OR drv = " " THEN LET drv = DEF_DBDRIVER END IF
		LET m_dbtyp = drv.subString(4,6)
	END IF
	RETURN m_dbtyp
END FUNCTION
--------------------------------------------------------------------------------
-- create file and folder for the empty sqlite db and then call the db_connect again
FUNCTION gldb_sqt_createdb(l_dir STRING, l_file STRING)
	DEFINE c base.Channel
	LET c = base.Channel.create()
	IF NOT os.path.exists( l_dir ) THEN
		IF NOT os.path.mkdir( l_dir ) THEN
			CALL gl_lib.gl_exitProgram(STATUS,SFMT("DB Folder Creation Failed for: %1",l_dir))
		END IF
	END IF
	CALL c.openFile(l_file,"w")
	CALL c.close()
	LET m_cre_db = FALSE -- avoid infintate loop!
	CALL gldb_connect( m_dbnam )
END FUNCTION
--------------------------------------------------------------------------------
-- create a new informix database and then call the db_connect again
FUNCTION gldb_ifx_createdb()
	DEFINE l_sql_stmt STRING
	LET l_sql_stmt = "CREATE DATABASE "||m_dbnam||" IN "||m_dbspa
	TRY
		EXECUTE IMMEDIATE l_sql_stmt
	CATCH
		IF NOT gldb_sqlStatus( __LINE__, "gl_db", l_sql_stmt ) THEN
			CALL gl_lib.gl_exitProgram(STATUS,"DB Creation Failed!")
		END IF
	END TRY
	LET m_cre_db = FALSE -- avoid infintate loop!
	CALL gldb_connect( m_dbnam )
END FUNCTION




--------------------------------------------------------------------------------
#+ Show Information for a Failed Connections. Debug.
#+
#+ @param stat Status
#+ @param dbname Database Name
FUNCTION gldb_showInfo(stat,dbname) --{{{
	DEFINE stat INTEGER
	DEFINE dbname STRING
	DEFINE dbtyp CHAR(3)
	DEFINE driver, logname STRING
	
	OPEN WINDOW info WITH FORM "show_info"

	DISPLAY "FGLDIR" TO lab1
	DISPLAY fgl_getenv("FGLDIR") TO fld1
	DISPLAY "FGLASDIR" TO lab2
	DISPLAY fgl_getenv("FGLASDIR") TO fld2
	DISPLAY "FGLPROFILE" TO lab3
	DISPLAY fgl_getenv("FGLPROFILE") TO fld3
	DISPLAY "DBNAME" TO lab4
	DISPLAY dbname TO fld4
	DISPLAY "dbi.database."||dbname||".source" TO lab5
	DISPLAY fgl_getResource("dbi.database."||dbname||".source") TO fld5

	DISPLAY "dbi.database."||dbname||".driver" TO lab6
	LET driver = fgl_getResource("dbi.database."||dbname||".driver")
	DISPLAY driver TO fld6

	LET dbtyp = driver.subString(4,6)
	IF dbtyp IS NULL THEN
		DISPLAY "No driver in FGLPROFILE!!!" TO lab7
	ELSE
		DISPLAY "dbi.database."||dbname||"."||dbtyp||".schema" TO lab7
	END IF
	DISPLAY fgl_getResource("dbi.database."||dbname||"."||dbtyp||".schema") TO fld7

	DISPLAY "dbsrc" TO lab8
	DISPLAY m_dbsrc TO fld8

	DISPLAY "dbconn" TO lab9
	DISPLAY m_dbcon TO fld9

	DISPLAY "DBPATH" TO lab10
	DISPLAY fgl_getenv("DBPATH") TO fld10

	DISPLAY "LD_LIBRARY_PATH" TO lab11
	DISPLAY fgl_getenv("LD_LIBRARY_PATH") TO fld11

	DISPLAY "LOGNAME" TO lab12
	LET logname = fgl_getenv("LOGNAME")
	IF logname IS NULL OR logname.getLength() < 1 THEN
		LET logname = fgl_getenv("USERNAME")
	END IF
	IF logname IS NULL OR logname.getLength() < 1 THEN
		LET logname = "(null)"
	END IF
	DISPLAY logname TO fld12

	DISPLAY "STATUS" TO lab13
	DISPLAY stat TO fld13
	DISPLAY "SQLSTATE" TO lab14
	DISPLAY SQLSTATE TO fld14
	DISPLAY "SQLERRMESSAGE" TO lab15
	DISPLAY SQLERRMESSAGE TO fld15

	MENU "Info"
		ON ACTION exit EXIT MENU
		ON ACTION close EXIT MENU
	END MENU

	CLOSE WINDOW info

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @code CALL gldb_sqlStatus( __LINE__, "gl_db", l_sql_stmt )
#+
#+ @param l_line Line number - should be __LINE__
#+ @param l_mod Module name - should be __FILE__
#+ @param l_stmt = String: The SQL Statement / Message, Can be NULL.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION gldb_sqlStatus(l_line, l_mod, l_stmt) RETURNS BOOLEAN --{{{
	DEFINE l_mod, l_stmt STRING
	DEFINE l_line, l_stat INTEGER

	LET l_stat = STATUS
	LET l_mod = l_mod||" Line:",(l_line USING "<<<<<<<")
	IF l_stat = 0 THEN RETURN TRUE END IF
	IF l_stmt IS NULL THEN
		CALL gl_lib.gl_errPopup(%"Status:"||l_stat||"\nSqlState:"||SQLSTATE||"\n"||SQLERRMESSAGE||"\n"||l_mod)
	ELSE
		CALL gl_lib.gl_errPopup(l_stmt||"\nStatus:"||l_stat||"\nSqlState:"||SQLSTATE||"\n"||SQLERRMESSAGE||"\n"||l_mod)
		GL_DBGMSG(0, "gl_sqlStatus: Stmt         ='"||l_stmt||"'")
	END IF
	GL_DBGMSG(0, "gl_sqlStatus: WHERE        :"||l_mod)
	GL_DBGMSG(0, "gl_sqlStatus: STATUS       :"||l_stat)
	GL_DBGMSG(0, "gl_sqlStatus: SQLSTATE     :"||SQLSTATE)
	GL_DBGMSG(0, "gl_sqlStatus: SQLERRMESSAGE:"||SQLERRMESSAGE)

	RETURN FALSE

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Generate an insert statement.
#+
#+ @param tab String: Table name
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION gldb_genInsert( tab STRING, rec_n om.domNode, fixQuote BOOLEAN) RETURNS STRING --{{{
	DEFINE n om.domNode
	DEFINE nl om.nodeList
	DEFINE l_stmt,val STRING
	DEFINE x,len SMALLINT
	DEFINE typ,comma CHAR(1)

	LET l_stmt = "INSERT INTO "||tab||" VALUES("
	LET nl = rec_n.selectByTagName("Field")	
	LET comma = " "
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CALL gldb_getType( n.getAttribute("type") ) RETURNING typ,len
		LET val = n.getAttribute("value")
		IF val IS NULL THEN 
			LET l_stmt = l_stmt.append(comma||"NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(comma||val)
			ELSE
				IF fixQuote THEN LET val = gldb_fixQuote( val ) END IF
				LET l_stmt = l_stmt.append(comma||"'"||val||"'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(")")

	RETURN l_stmt
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Generate an update statement.
#+
#+ @param tab Table name
#+ @param wher 	Where Clause
#+ @param rec_n TypeInfo Node for NEW record to udpate
#+ @param rec_o TypeInfo Node for ORIGINAL record to udpate
#+ @param ser_col Serial Column number or 0 ( colNo of the column that is a serial )
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION gldb_genUpdate( tab, wher, rec_n, rec_o, ser_col, fixQuote ) --{{{
	DEFINE tab, wher STRING
	DEFINE ser_col, fixQuote SMALLINT
	DEFINE rec_n,rec_o, n, o om.domNode
	DEFINE l_stmt,val, val_o, d_val, d_val_o STRING
	DEFINE nl_n, nl_o om.nodeList
	DEFINE x,len SMALLINT
	DEFINE typ,comma CHAR(1)

	LET l_stmt = "UPDATE "||tab||" SET "
	LET nl_n = rec_n.selectByTagName("Field")	
	LET nl_o = rec_o.selectByTagName("Field")	
	LET comma = " "
	FOR x = 1 TO nl_n.getLength()
		IF x = ser_col THEN CONTINUE FOR END IF -- Skip Serial Column
		LET n = nl_n.item(x)
		LET o = nl_o.item(x)
		CALL gldb_getType( n.getAttribute("type") ) RETURNING typ,len
		LET val_o = o.getAttribute("value")
		LET val = n.getAttribute("value")
		IF (val_o IS NULL AND val IS NULL) OR val_o = val THEN CONTINUE FOR END IF
		LET d_val = val
		LET d_val_o = val_o
		IF val IS NULL THEN LET d_val = "(null)" END IF
		IF val_o IS NULL THEN LET d_val_o = "(null)" END IF
		GL_DBGMSG(3,n.getAttribute("name")||" N:"||d_val||" O:"||d_val_o)
		LET l_stmt = l_stmt.append(comma||n.getAttribute("name")||" = ")
		IF val IS NULL THEN
			LET l_stmt = l_stmt.append("NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(val)
			ELSE
				IF fixQuote THEN LET val = gldb_fixQuote( val ) END IF
				LET l_stmt = l_stmt.append("'"||val||"'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(" WHERE "||wher)

	RETURN l_stmt
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Fix single quote
#+
#+ @param l_in String to be fixed
#+ @returns fixed string
FUNCTION gldb_fixQuote(l_in STRING) RETURNS STRING --{{{
	DEFINE y SMALLINT
	DEFINE sb base.StringBuffer

	LET y = l_in.getIndexOf("'",1)
	IF y > 0 THEN
		GL_DBGMSG(0,"Single Quote Found!")
		LET sb = base.StringBuffer.create()
		CALL sb.append( l_in )
		CALL sb.replace("'","''",0)
		LET l_in = sb.toString()
	END IF

	RETURN l_in
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get the database column type and return a simple char and len value.
#+ NOTE: SMALLINT INTEGER SERIAL DECIMAL=N, DATE=D, CHAR VARCHAR=C
#+
#+ @param l_typ Type
#+ @return CHAR(1),SMALLINT
FUNCTION gldb_getType( l_typ STRING) RETURNS ( STRING, STRING ) --{{{
  DEFINE l_len SMALLINT

--TODO: Use I for smallint, integer, serial, N for numeric, decimal
  LET l_len = 10
  CASE l_typ.subString(1,3)
    WHEN "SMA" LET l_typ = "N" LET l_len = 5
    WHEN "INT" LET l_typ = "N" LET l_len = 10
    WHEN "SER" LET l_typ = "N" LET l_len = 10
    WHEN "DEC" LET l_typ = "N" LET l_len = 12
    WHEN "DAT" LET l_typ = "D" LET l_len = 10
    WHEN "CHA" LET l_typ = "C" LET l_len = gldb_getLength( l_typ )
    WHEN "VAR" LET l_typ = "C" LET l_len = gldb_getLength( l_typ )
  END CASE

  RETURN l_typ,l_len
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get the length from a type definiation ie CHAR(10) returns 10
#+
#+ @param s_typ Type
#+ @return Length from type or defaults to 10
FUNCTION gldb_getLength( l_typ STRING ) RETURNS SMALLINT --{{{
  DEFINE x,y,l_len SMALLINT
	LET l_len = 1 -- default
--TODO: Handle decimal, numeric ie values with , in.
  LET x = l_typ.getIndexOf("(",4)
  LET y = l_typ.getIndexOf(")",x+1)
  IF x > 0 AND y > 0 THEN
    LET l_len = l_typ.subString(x+1,y-1)
  END IF
  RETURN l_len
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Check a record for valid update/insert
#+
#+ @param l_ex Exists true/false
#+ @param l_key Key value
#+ @param l_sql SQL to select using
#+ @returns true/false
FUNCTION gldb_checkRec(l_ex BOOLEAN, l_key STRING, l_sql STRING) RETURNS BOOLEAN
	DEFINE l_exists BOOLEAN

	LET l_key = l_key.trim()
	DISPLAY "Key='",l_key,"'"

	IF l_key IS NULL OR l_key = " " OR l_key.getLength() < 1 THEN
		CALL gl_lib.gl_warnPopup(%"You entered a NULL Key value!")
		RETURN FALSE
	END IF

	PREPARE gldb_checkrec_pre FROM l_sql
	DECLARE gldb_checkrec_cur CURSOR FOR gldb_checkrec_pre
	OPEN gldb_checkrec_cur
	LET l_exists = TRUE
	FETCH gldb_checkrec_cur
	IF STATUS = NOTFOUND THEN LET l_exists = FALSE END IF
	CLOSE gldb_checkrec_cur
	IF NOT l_exists THEN
		IF l_ex THEN
			CALL gl_lib.gl_warnPopup(%"Record '"||l_key||"' doesn't Exist!")
			RETURN FALSE
		END IF
	ELSE
		IF NOT l_ex THEN
			CALL gl_lib.gl_warnPopup(%"Record '"||l_key||"' already Exists!")
			RETURN FALSE
		END IF
	END IF
	RETURN TRUE
END FUNCTION