
&include "db.inc"

MAIN
  DEFINE con VARCHAR(300)
	DEFINE db VARCHAR(20)
	DEFINE src,drv STRING

	CALL startlog( base.application.getProgramName()||".log" )

	LET db = fgl_getenv("DBNAME")
	IF db IS NULL OR db = " " THEN LET db = DEF_DB_NAME END IF

	LET drv = fgl_getenv("DBDRIVER")
	IF drv IS NULL OR drv = " " THEN LET drv = DEF_DB_DRIVER END IF

	IF drv.subString(4,6) != "ifx" THEN
		CALL fgl_winMessage("ERROR","This program is only intended for Informix!","exclamation")
		EXIT PROGRAM
	END IF

	LET src = fgl_getenv("INFORMIXSERVER")

	DISPLAY "DB:",db," FGLPROFILE:",fgl_getenv("FGLPROFILE")," SRC:",src
	LET con = db||"+driver='"||drv||"'" --,source='"||src||"'"

	IF NOT connect( con ) THEN
		EXIT PROGRAM
	END IF

	CALL insert()
END MAIN
---------------------------------------------------
#+ Custom load routine for database specific loading
FUNCTION load()
END FUNCTION
---------------------------------------------------
FUNCTION create()
END FUNCTION