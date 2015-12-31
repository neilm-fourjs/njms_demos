
--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.00.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------

#+ DDE Specific Library Code (Work in Progress)
#+ $Id: gl_ddelib.4gl 309 2011-05-31 10:10:49Z  $

&include "genero_lib1.inc"
&include "gl_ddelib.inc"

DEFINE gl_dde_ret SMALLINT

#+
#+
#+
#+
FUNCTION gl_ddeConnect( prog, doc ) --{{{
	DEFINE prog, doc STRING
	DEFINE stat SMALLINT
GL_MODULE_ERROR_HANDLER
	LET gl_dde_ret = 1
	CALL ui.interface.frontCall( DDEMOD,  "DDEConnect",[ prog, doc ] , [ stat ] )
	IF stat != 1 THEN	
		CALL gl_ddeError("Connect",stat,__LINE__)
		LET gl_dde_ret = 0
	END IF
	GL_DBGMSG(gl_dde_ret,"gl_ddeConnect: mod:"||DDEMOD||" prog:"||prog.trim()||" doc:"||doc.trim()||" stat="||stat)
	RETURN gl_dde_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeSend(prog,doc,cells,vals) --{{{
	DEFINE prog,doc,cells,vals STRING
	DEFINE stat SMALLINT

	LET gl_dde_ret = 1
--	GL_DBGMSG(2, "Vals:"||vals.trim())
	CALL ui.interface.frontCall( DDEMOD,  "DDEPoke", [prog, doc, cells, vals], [stat] )
	IF stat != 1 THEN
		CALL gl_ddeError("Poke",stat,__LINE__)
		LET gl_dde_ret = 0
	END IF
	GL_DBGMSG(gl_dde_ret,"gl_ddeSend: prog:"||prog.trim()||" doc:"||doc.trim()||" stat="||stat)
	RETURN gl_dde_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeExecute(prog,doc,cmd) --{{{
	DEFINE prog,doc,cmd STRING
	DEFINE stat SMALLINT

	LET cmd = "[",__fgl_convertTclString(cmd),"]"

	LET gl_dde_ret = 1
	CALL ui.interface.frontCall( DDEMOD,  "DDEExecute", [prog, doc, cmd], [stat] )
	IF stat != 1 THEN
		CALL gl_ddeError("Execute",stat,__LINE__)
		LET gl_dde_ret = 0
	END IF
	GL_DBGMSG(gl_dde_ret,"gl_ddeExecute: prog:"||prog.trim()||" doc:"||doc.trim()||" cmd:"||cmd.trim()||" stat="||stat)
	RETURN gl_dde_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeFinish( prog, doc ) --{{{
	DEFINE prog, doc STRING
	DEFINE stat SMALLINT

	LET gl_dde_ret = 1
	CALL ui.interface.frontCall( DDEMOD,  "DDEFinish",[ prog, doc ] , [ stat ] )
	IF stat != 1 THEN
		CALL gl_ddeError("Finish",stat,__LINE__)
		LET gl_dde_ret = 0
	END IF
	GL_DBGMSG(gl_dde_ret,"gl_ddeFinish: prog:"||prog.trim()||" doc:"||doc.trim()||" stat="||stat)
	RETURN gl_dde_ret

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeSendRow(prog,doc,row,col,vals) --{{{
	DEFINE prog, doc, cells, vals STRING
	DEFINE row,col SMALLINT
--	DEFINE tok base.StringTokenizer 
--	DEFINE dta DYNAMIC ARRAY OF STRING
	DEFINE vals2 STRING
	DEFINE x,cols INTEGER
	DEFINE c CHAR(1)

--	LET tok = base.StringTokenizer.create( vals, "|" )
--	LET dta[ 1 ] = tok.nextToken()
--	LET vals2 = dta[ 1 ]||"	"
--	WHILE tok.hasMoreTokens()
--		CALL dta.appendElement()
--		LET dta[ dta.getLength() ] = tok.nextToken()
--		LET vals2 = vals2.append( dta[ dta.getLength() ]||"	" )
--	END WHILE

	LET vals2 = vals.getCharAt(1)
	LET cols = 0
	FOR x = 2 TO vals.getLength()
		LET c = vals.getCharAt(x) 	
		IF c = "|" THEN LET c = "\t" LET cols = cols + 1 END IF
		LET vals2 = vals2.append( c )
	END FOR
	
	LET cells = "R",row USING "<<<<<","C",col USING "<<<<<",":R",row USING "<<<<<","C",col+cols USING "<<<<<"
	GL_DBGMSG(1, "Cells:"||cells.trim())
	GL_DBGMSG(1, "Vals:"||vals2.trim())

	IF NOT gl_ddeSend(prog, doc, cells, vals2) THEN
		RETURN FALSE
	END IF
	RETURN TRUE

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddePoke(prog, doc, cells, vals) --{{{
	DEFINE prog, doc, cells, vals STRING
	DEFINE stat SMALLINT

	GL_DBGMSG(gl_dde_ret,"gl_ddePoke: prog:"||prog.trim()||" doc:"||doc.trim()||" cells:"||cells||" vals:"||vals||" stat="||stat)
	CALL ui.interface.frontCall( DDEMOD,  "DDEPoke", [prog, doc, cells, vals], [stat] )

	RETURN stat
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddePeek(prog,doc,cells) --{{{
	DEFINE prog, doc, cells, vals STRING
	DEFINE stat SMALLINT

	GL_DBGMSG(gl_dde_ret,"gl_ddePeek: prog:"||prog.trim()||" doc:"||doc.trim()||" cells:"||cells||" stat="||stat)
	CALL ui.interface.frontCall( DDEMOD,  "DDEPeek", [prog, doc, cells], [vals, stat] )

	RETURN vals

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeGetError() --{{{
	DEFINE err STRING
	CALL ui.interface.frontCall(DDEMOD,"DDEError",[],err)
	RETURN err
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_ddeError(func,stat, line) --{{{
	DEFINE func STRING
	DEFINE stat,line SMALLINT

	ERROR "DDE Error: line:",line," ",func," Status:",stat," ",gl_DDEGeterror()
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+
#+
#+
#+
FUNCTION gl_runExcelWord(prog,doc, loadMeth, office) --{{{
	DEFINE prog, doc, cmd, off STRING
	DEFINE loadMeth, office,stat SMALLINT
	DEFINE runit STRING
	DEFINE sl CHAR(2)

	LET sl = "\\\\"

	IF loadMeth THEN
		CASE office
			WHEN MSOFFICE LET off = "Office"
			WHEN MSOFFICE_XP LET off = "Office10"
			WHEN MSOFFICE_2003 LET off = "Office11"
		OTHERWISE
			LET off = "Office"
		END CASE
		LET runit = "C:",sl,"Program Files",sl,"Microsoft Office",sl,off,sl,prog
		LET cmd = "execute"
	ELSE
--		LET runit = "cmd /c start"
		IF WINEXEC THEN LET cmd = "winexec" END IF
		IF SHELLEXEC THEN LET cmd = "shellexec" END IF
	END IF

	IF doc IS NOT NULL THEN	
		LET runit = runit.append(" "||doc)
--	ELSE
--		LET runit = prog
	END IF
	
	IF cmd IS NULL THEN LET cmd = "NULL" END IF
	IF runit IS NULL THEN LET runit = "NULL" END IF

	LET gl_dde_ret = 1
	GL_DBGMSG(gl_dde_ret,"gl_runExcelWord cmd:"||cmd.trim()||":"||runit.trim()||":")
	IF cmd = "execute" THEN 
		CALL ui.interface.frontCall("standard", cmd.trim() ,[ runit.trim(),0 ], [ stat ] )
	ELSE
		CALL ui.interface.frontCall("standard", cmd.trim() ,[ runit.trim() ], [ stat ] )
	END IF

	IF stat = 1 THEN
		SLEEP 1 -- On slow machines this is required.
	ELSE
		LET gl_dde_ret = 0
	END IF
	GL_DBGMSG(gl_dde_ret,"gl_runExcelWord cmd:"||cmd.trim()||" : "||runit.trim()||":"||stat)
	RETURN gl_dde_ret

END FUNCTION --}}}
