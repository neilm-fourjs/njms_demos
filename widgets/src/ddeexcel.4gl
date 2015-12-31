
{ CVS Header
$Author: $
$Date: 2008-07-22 17:56:39 +0100 (Tue, 22 Jul 2008) $
$Revision: 2 $
$Source: /usr/home/test4j/cvs/all/demos/widgets/src/ddeexcel.4gl,v $
$Log: ddeexcel.4gl,v $
Revision 1.10  2007/12/06 09:25:57  test4j
*** empty log message ***

Revision 1.9  2007/07/12 16:43:03  test4j
*** empty log message ***

Revision 1.8  2006/07/21 11:23:08  test4j
*** empty log message ***

Revision 1.1  2005/11/17 18:14:12  test4j
*** empty log message ***

Revision 1.6  2005/11/14 15:46:15  test4j

Updated genero_lib1 and removed some things from genero.4gl

Revision 1.5  2005/05/10 14:48:12  test4j

Added cvs header.

}

DEFINE mess CHAR(60)
--------------------------------------------------------------------------------
FUNCTION excel()

	DEFINE ret SMALLINT
	DEFINE val CHAR(2000)
	DEFINE cls CHAR(50)
	DEFINE rws SMALLINT
	DEFINE cmd STRING
	DEFINE sl STRING

	LET sl = "\\\\"
	LET cmd = "\"c:",sl,"Program Files",sl,"Microsoft Office",sl,"Office",sl,"excel.exe\""
	DISPLAY "Run:",cmd
	IF NOT winexec(cmd) THEN
		LET cmd = "\"c:",sl,"Program Files",sl,"Microsoft Office",sl,"Office10",sl,"excel.exe\""
		DISPLAY "Run:",cmd
		IF NOT winexec(cmd) THEN
			LET cmd = "\"c:",sl,"Program Files",sl,"Microsoft Office",sl,"Office11",sl,"excel.exe\""
			IF NOT winexec(cmd) THEN
				MESSAGE "Failed to Run Excel!"
				RETURN
			END IF
		END IF
	END IF
	MESSAGE "Excel Started."
		
	SLEEP 1

	DISPLAY "DDEConnect.,,"
	CALL DDEConnect("excel","Book1") RETURNING ret
	IF NOT ret THEN
		LET mess = "DDEConnect Failed:", DDEGeterror()
		CALL gl_errMsg(__FILE__,__LINE__, mess )
		RETURN
	ELSE
		DISPLAY "DDEConnect worked."
	END IF

	LET cmd = "SELECT(\"R1C1,R1C2,R1C3\")"
	LET ret = excel_exe( cmd )

	LET cmd = "FONT.PROPERTIES(\"Arial\",\"Bold\",\"14\")"
	LET ret = excel_exe( cmd )

	LET cmd = "ALIGN(\"CENTER\")"
	LET ret = excel_exe( cmd )

	CALL send_dde("R1C1:R1C3", "Col 1\\tCol 2\\tCol 3") RETURNING ret

	FOR rws = 2 TO 20
		LET val = rws,
				"\\t","Row",rws USING "&&",
				"\\t","This is a demo"
		LET cls = "R",rws USING "<<<<","C1:R",rws USING "<<<<","C11"
		CALL send_dde(cls, val) RETURNING ret
	END FOR

	CALL DDEFinish("excel","Book1") RETURNING ret
	IF NOT ret THEN
		LET mess = "DDE Failed",DDEGeterror()
		CALL gl_errMsg(__FILE__,__LINE__,mess)
	ELSE
		DISPLAY "DDEFinish worked."
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION send_dde(cells,vals)
	DEFINE cells CHAR(50)
	DEFINE vals CHAR(2000)

	IF NOT DDEPoke("excel", "Book1", cells CLIPPED, vals CLIPPED) THEN
		LET mess = "DDEPoke Failed:",DDEGeterror()
		CALL gl_errMsg(__FILE__,__LINE__,mess)
		RETURN FALSE
	ELSE
		DISPLAY "DDEPoke worked:",cells CLIPPED
	END IF
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION excel_exe(cmd)

DEFINE
  cmd   STRING,
  ret   SMALLINT


	LET cmd = "["||cmd||"]"

	CALL ui.Interface.frontCall( "WINDDE", "DDEExecute", [ "excel", "Book1", cmd ], [ret] )

  IF ret = FALSE THEN
		DISPLAY "DDEExecute: Failed! ",ret	," cmd:",cmd CLIPPED
		RETURN FALSE
	END IF
	RETURN TRUE

END FUNCTION { excel_exe }
