
--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.00.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

#+ COM Specific Library Code (Work in Progress)
#+ActiveSheet.Cells(1, iNumCols)).Interior.ColorIndex = 6
#+ActiveSheet.Cells(1, iNumCols)).Font.Bold = True
#+ActiveSheet.Cells(1, iNumCols)).Font.Size = 11

#+ $Id: gl_comlib.4gl 309 2011-05-31 10:10:49Z  $

&include "genero_lib1.inc"

DEFINE gl_comReg DYNAMIC ARRAY OF RECORD
		prg STRING,
		fil STRING,
		app INTEGER,
		doc INTEGER
	END RECORD

DEFINE gl_curIns SMALLINT
DEFINE gl_com_ret SMALLINT

--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comLaunch( prog, doc ) --{{{
	DEFINE prog, doc STRING
	DEFINE stat SMALLINT
GL_MODULE_ERROR_HANDLER
	CASE prog
		WHEN "excel" LET prog = "Excel.application"
	END CASE
	IF prog IS NULL THEN LET prog = "NULL" END IF
	IF doc IS NULL THEN LET doc = "NULL" END IF
	
	GL_DBGMSG(1,"gl_comLaunch: prog:"||prog||" Doc:"||doc)

--	LET gl_curIns = 0

	LET gl_com_ret = 1
	LET stat = -100
	CALL ui.interface.frontCall( "WinCom", "CreateInstance",[ prog ] , [ stat ] )
	IF stat < 0 THEN	
		CALL gl_comError("Launch",stat,__LINE__)
		LET gl_com_ret = 0
	ELSE
		CALL gl_comRegAdd( prog, doc, stat, 0 )

		CALL ui.interface.frontCALL("WinCom", "SetProperty", [gl_comReg[gl_curIns].app, "visible", "1"],[stat])
		IF stat < 0 THEN CALL gl_comError("Visible",stat,__LINE__) END IF

-- If EXCEL and NEW then open a workbook and register it in the comReg
		IF prog = "Excel.application" AND doc = "NEW" THEN
			SLEEP 1 -- just incase it's not finished adding the instance yet.
			GL_DBGMSG(1,"gl_comLaunch: WorkBooks.Add for "||gl_comReg[gl_curIns].app)
			LET stat = -100
			CALL ui.interface.frontCALL("WinCom", "CallMethod", [gl_comReg[gl_curIns].app, "WorkBooks.Add"],[stat])
			IF stat IS NULL OR stat < 0 THEN
				CALL gl_comError("WorkBooks.Add",stat,__LINE__)
			ELSE
				CALL gl_comRegAdd( prog, doc, 0, stat )
			END IF
		END IF
	END IF

	IF stat IS NULL THEN LET stat = -99 END IF
	GL_DBGMSG(gl_com_ret,"gl_comLaunch: prog:"||prog.trim()||" doc:"||doc.trim()||" stat="||stat)
	RETURN gl_com_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comRegAdd( prog, fil, app, doc ) --{{{
	DEFINE prog, fil STRING
	DEFINE app, doc SMALLINT

	IF prog IS NULL THEN LET prog = "NULL" END IF
	IF fil IS NULL THEN LET fil = "NULL" END IF
	IF app IS NULL THEN LET app = -99 END IF
	IF doc IS NULL THEN LET doc = -99 END IF

	IF gl_curIns = 0 OR gl_curIns IS NULL THEN
		CALL gl_comReg.appendElement()
		LET gl_curIns = gl_comReg.getLength()
	END IF
	LET gl_comReg[gl_curIns].prg = prog
	LET gl_comReg[gl_curIns].fil = fil
	LET gl_comReg[gl_curIns].app = app
	LET gl_comReg[gl_curIns].doc = doc

	GL_DBGMSG(gl_com_ret,"gl_comRegAdd: curIns:"||gl_curIns||" prg:"||gl_comReg[gl_curIns].prg.trim()||" fil:"||gl_comReg[gl_curIns].fil.trim()||" app:"||gl_comReg[gl_curIns].app||" doc:"||gl_comReg[gl_curIns].doc)

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comSend(ins,cells,vals) --{{{
	DEFINE ins SMALLINT
	DEFINE cells,vals STRING
	DEFINE stat SMALLINT

	LET gl_com_ret = 1
	LET stat = -100
	GL_DBGMSG(1,"gl_comSend: doc:"||gl_comReg[ins].doc||" activesheet.Range("||cells||").Value:"||vals)
	CALL ui.interface.frontCall( "WinCom", "SetProperty", [gl_comReg[ins].doc, "activesheet.Range(\""||cells||"\").Value", vals], [stat] )
	IF stat < 0 THEN
		CALL gl_comError("comSend",stat,__LINE__)
		LET gl_com_ret = 0
	END IF
	GL_DBGMSG(gl_com_ret,"gl_comSend: stat="||stat)
	RETURN gl_com_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comExecute(ins,cmd) --{{{
	DEFINE ins SMALLINT
	DEFINE cmd STRING
	DEFINE stat SMALLINT

	LET gl_com_ret = 1
	LET stat = -1
	CALL ui.interface.frontCall( "WinCom", "ComExecute", [gl_comReg[ins].doc, cmd], [stat] )
	IF stat < 0 THEN
		CALL gl_comError("comExecute",stat,__LINE__)
		LET gl_com_ret = 0
	END IF
	GL_DBGMSG(gl_com_ret,"gl_comExecute: cmd:"||cmd.trim()||" stat="||stat)
	RETURN gl_com_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comFinish( ins ) --{{{
	DEFINE ins, stat SMALLINT

	IF gl_comReg[ins].app = 0 THEN
		GL_DBGMSG(0,"gl_comFinish: Ins:"||ins||" Doesn't Exist!")
		RETURN FALSE
	END IF

	IF gl_comReg[ins].doc != 0 THEN
		LET stat = -100
		CALL ui.interface.frontCall( "WinCom", "ReleaseInstance", [gl_comReg[ins].doc], [stat] )
		IF stat < 0 THEN
			CALL gl_comError("Finish",stat,__LINE__)
			LET gl_com_ret = 0
		ELSE
			GL_DBGMSG(1,"gl_comFinish: Ins:"||ins||" Doc:"||gl_comReg[ins].doc||" stat="||stat)
		END IF
	END IF
	LET stat = -100
	CALL ui.interface.frontCall( "WinCom", "ReleaseInstance", [gl_comReg[ins].app], [stat] )
	IF stat < 0 THEN
		CALL gl_comError("Finish",stat,__LINE__)
		LET gl_com_ret = 0
	END IF
	GL_DBGMSG(gl_com_ret,"gl_comFinish: Ins:"||ins||" App:"||gl_comReg[ins].app||" stat="||stat)
	RETURN gl_com_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comSendRow(ins,row,col,vals) --{{{
	DEFINE ins SMALLINT
	DEFINE vals STRING
	DEFINE row,col,stat SMALLINT
	DEFINE tok base.StringTokenizer 
	DEFINE vals2 STRING

--	GL_DBGMSG(1, "Row:"||row)
	LET tok = base.StringTokenizer.create( vals, "|" )
	WHILE tok.hasMoreTokens()
		LET vals2 = tok.nextToken()
		IF vals2 IS NOT NULL AND vals2 != " " THEN
--			GL_DBGMSG(1, "Col:"||col||" Vals:"||vals2.trim())
			CALL ui.interface.frontCall( "WinCom", "SetProperty", [gl_comReg[ins].doc, "activesheet.cells("||row||","||col||").Value", vals2], [stat] )
			IF stat < 0 THEN
				CALL gl_comError("comSend",stat,__LINE__)
				RETURN FALSE
			END IF
		END IF
		LET col = col + 1
	END WHILE
	
--	LET cells = "R",row USING "<<<<<","C",col USING "<<<<<",":R",row USING "<<<<<","C",col+dta.getLength() USING "<<<<<"
--	GL_DBGMSG(1, "Cells:"||cells.trim())
--	GL_DBGMSG(1, "Row:"||row)
--	GL_DBGMSG(1, "Col:"||col)
--	GL_DBGMSG(1, "Vals:"||vals2.trim())

	RETURN TRUE
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comSendRow2(ins,row,col,vals) --{{{
	DEFINE ins SMALLINT
	DEFINE vals STRING
	DEFINE row,col,stat SMALLINT
	DEFINE tok base.StringTokenizer 
	DEFINE range STRING
--	DEFINE dta DYNAMIC ARRAY OF STRING
	DEFINE vals2 STRING

	LET tok = base.StringTokenizer.create( vals, "|" )
	LET range = ""
	LET range = "A"||(row USING "<<<")||":K"||(row USING "<<<")
	LET vals2 = "{\""||tok.nextToken()||"\""
	WHILE tok.hasMoreTokens()
--		LET dta[ dta.getLength() + 1] = tok.nextToken()
		LET vals2 = vals2.trim()||",\""||tok.nextToken()||"\""
	END WHILE
	LET vals2 = vals2.trim()||"}"

	GL_DBGMSG(1, "Row:"||row)
	GL_DBGMSG(1, "Col:"||col)
	GL_DBGMSG(1, "Col:"||col||" Vals:"||vals2.trim())

	CALL ui.interface.frontCall( "WinCom", "SetProperty", [gl_comReg[ins].doc, "activesheet.range(\""||range||"\").Value", vals2], [stat] )
	IF stat < 0 THEN
		CALL gl_comError("comSend",stat,__LINE__)
		RETURN FALSE
	END IF
	
	RETURN TRUE
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_colourCells(ins, cells, colour ) --{{{
	DEFINE ins, colour, stat SMALLINT
	DEFINE cells STRING

	CALL ui.interface.frontCall( "WinCom", "SetProperty", [gl_comReg[ins].doc, "activesheet.range(\""||cells||"\").Interior.ColorIndex", colour], [stat] )

	IF stat < 0 THEN
		CALL gl_comError("colourCells",stat,__LINE__)
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_comError(func,stat, line) --{{{
	DEFINE func,err STRING
	DEFINE stat,line SMALLINT

	CALL ui.Interface.frontCall("WinCom","GetError", [], [err] )

	IF func IS NULL THEN LET func = "NULL" END IF
	IF stat IS NULL THEN LET stat = -99 END IF
	IF err IS NULL THEN LET err = "NULL" END IF

	GL_DBGMSG(0, "COM Error: line:"||line||" "||func.trim()||" Status:"||stat||" "||err.trim())

	ERROR "COM Error: line:",line," ",func," Status:",stat," ",err

END FUNCTION --}}}
--------------------------------------------------------------------------------
