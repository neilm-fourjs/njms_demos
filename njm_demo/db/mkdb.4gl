
IMPORT os
MAIN
	DEFINE drv,prg,msg STRING
	LET drv = fgl_getenv("DBDRIVER")
	IF drv IS NULL OR drv = " " THEN LET drv = "dbmmys51x" END IF

	CASE drv.subString(4,6)
		WHEN "mys" LET prg = "mkdb_mysql"
		WHEN "gdb" LET prg = "mkdb_generodb"
		WHEN "ifx" LET prg = "mkdb_informix"
		WHEN "msv" LET prg = "mkdb_sqlServer"
		WHEN "snc" LET prg = "mkdb_sqlServer"
		WHEN "sqt" LET prg = "mkdb_sqlite"
		WHEN "pgs" LET prg = "mkdb_postgresql"
		OTHERWISE
			LET msg = "No program for driver ",drv
			CALL endProg(msg)
	END CASE

	IF os.Path.exists(prg||".42r") THEN
		LET msg = "Ran:", prg
		RUN "fglrun "||prg
	ELSE
		LET msg = "Program '",prg,".42r' does not exist"
	END IF
	CALL endprog(msg)

END MAIN
--------------------------------------------------------------------------------
FUNCTION endprog(msg)
	DEFINE msg STRING

	DISPLAY msg
	CALL fgl_winMessage("mkdb",msg,"information")

	EXIT PROGRAM
END FUNCTION