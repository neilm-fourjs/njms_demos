
#+ General library code for Database access.
#+
#+ $Id: gl_db.4gl 795 2010-09-15 08:32:16Z  $

IMPORT os
&include "genero_lib1.inc"
CONSTANT VER = "$Rev: 795 $"
CONSTANT PRG = "gl_db"
CONSTANT PRGDESC = "Library code DB"
CONSTANT PRGAUTH = "Neil J.Martin"

CONSTANT DEF_DBDRIVER="dbmifx9x"
CONSTANT DEF_DBNAME="genero_demos"
CONSTANT DEF_DBDSN="genero_dsn"
CONSTANT DEF_DBDIR="sqlite_db"

DEFINE m_dbtyp, m_dbnam, m_dbsrc,  m_dbdrv,  m_dbcon STRING

FUNCTION gldb_connect(db)
	DEFINE db VARCHAR(20)
  DEFINE con VARCHAR(300)
	DEFINE dbdir, src, drv, msg STRING
	DEFINE lockMode, fglprofile BOOLEAN
	DEFINE dbt CHAR(3)
GL_MODULE_ERROR_HANDLER
	IF db IS NULL OR db = " " THEN LET db = fgl_getenv("DBNAME") END IF
	IF db IS NULL OR db = " " THEN LET db = DEF_DBNAME END IF

	LET dbdir = fgl_getenv("DBDIR")
	IF dbdir IS NULL OR dbdir = " " THEN LET dbdir = DEF_DBDIR END IF

	LET fglprofile = FALSE
	LET drv = fgl_getresource("dbi.database."||db||".driver")
	IF drv IS NOT NULL AND drv != " " THEN LET fglprofile = TRUE END IF

	IF drv IS NULL OR drv = " " THEN LET drv = fgl_getenv("DBDRIVER") END IF
	IF drv IS NULL OR drv = " " THEN LET drv = DEF_DBDRIVER END IF

	LET lockMode = TRUE
	LET dbt = drv.subString(4,6)
	LET m_dbtyp = dbt
	IF fglprofile THEN
		LET src = fgl_getresource("dbi.database."||db||".source")
		LET con = db
	ELSE
		CASE dbt
			WHEN "pgs"
				LET src = fgl_getEnv("PGSERVER") -- ???
				LET m_dbnam = "PostgreSQL "||drv.subString(7,9)
				LET con = "db+driver='"||drv||"',source='"||src||"'"
			WHEN "ifx"
				LET src = fgl_getEnv("INFORMIXSERVER")
				LET m_dbnam = "Informix "||drv.subString(7,9)
				LET src = fgl_getEnv("INFORMIXSERVER")
				LET con = db
			WHEN "ads"
				LET src = fgl_getEnv("ANTS_DSN")
				IF src IS NULL OR src = " " THEN LET src = DEF_DBDSN END IF
				LET m_dbnam = "GeneroDB "||drv.subString(7,9)
				LET con = "db+driver='"||drv||"',source='"||src||"'"
			WHEN "sqt"	
				LET src = fgl_getEnv("SQLITEDB")
				IF src IS NULL OR src = " " THEN LET src = dbdir||os.path.separator()||db||".db" END IF
				LET lockMode = FALSE
				LET m_dbnam = "SQLite "||drv.subString(7,9)
				LET con = "db+driver='"||drv||"',source='"||src||"'"
		END CASE
		IF dbt = "ads" THEN
			LET con = con CLIPPED,",username='",db,"',password='",db,"'"
		END IF
	END IF

	LET m_dbsrc = src
	LET m_dbdrv = drv
	LET m_dbcon = con
	TRY
		DISPLAY "Connecting to "||db||" Using:",drv, " Source:",src," ..."
		DATABASE con
		DISPLAY "Connected to "||db||" Using:",drv, " Source:",src
	CATCH
		LET msg = "Connection to database failed\nDB:",db,"\nSource:",src, "\nDriver:",drv,"\n",
			 "Status:",SQLCA.SQLCODE,"\n",SQLERRMESSAGE
		DISPLAY msg
		IF dbt = "ads" AND SQLCA.SQLCODE = -6366 THEN
			RUN "echo $LD_LIBRARY_PATH;ldd $FGLDIR/dbdrivers/"||drv||".so"
		END IF
		CALL fgl_winMessage("Fatal Error",msg,"exclamation")
		CALL gl_about( VER ) --, PRG, PRGDESC, PRGAUTH)
		EXIT PROGRAM
	END TRY

	IF lockMode THEN
		SET LOCK MODE TO WAIT 3 -- Should hit any locked rows.
	END IF
	CALL fgl_setEnv("DBCON",db)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gldb_getDBName()
	RETURN m_dbnam
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gldb_getDBType()
	DEFINE drv STRING
	IF m_dbtyp IS NULL THEN
		LET drv = fgl_getenv("DBDRIVER")
		IF drv IS NULL OR drv = " " THEN LET drv = DEF_DBDRIVER END IF
		LET m_dbtyp = drv.subString(4,6)
	END IF
	RETURN m_dbtyp
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gldb_getDBInfo()
	RETURN m_dbtyp, m_dbsrc, m_dbdrv, m_dbcon
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
