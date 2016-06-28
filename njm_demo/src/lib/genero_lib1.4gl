
--------------------------------------------------------------------------------
#+ Genero Library 1 - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 1.33 & 2.2x.
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ $Id: genero_lib1.4gl 344 2015-08-18 11:23:17Z neilm $
#+
#+ Environment Variables:
#+
#+	FJS_GL_DBGLEV: 0-3 Debug output.
#+
#+	FJS_MDICONT: MDI Container name
#+
#+	FJS_MDITITLE: MDI Text for container program
#+
#+	FJS_STYLE: Style file to use if not default
#+
#+	FJS_STYLE2: Additional Style file to merge with current.
#+
#+	FJS_GL_NOINIT: Don't use Form Initializer
#+
#+	FJS_PICS: Add this path to images used for splash etc. Will default to FGLIMAGEPATH
#+

&ifdef genero13x
-- No importing of file functions, use dummy code?
&else
IMPORT os
&endif

&include "genero_lib1.inc" -- Contains GL_DBGMSG & g_dbgLev

-- These are used in gl_about.
CONSTANT gl_genlibver = "$Revision: 344 $" -- Now have to manually do this because svn is not setup right yet.
CONSTANT gl_genlibdte = "$Date: 2010-11-08 17:27:22 +0000 (Mon, 08 Nov 2010) $"
CONSTANT gl_libauth = "Neil J Martin"

CONSTANT MAX_COLS = 12 -- Used by gl_dyntab

DEFINE style_about SMALLINT
DEFINE style_wabout SMALLINT
DEFINE style_splash SMALLINT
DEFINE m_styleList om.DomNode
DEFINE m_key STRING
DEFINE m_pics STRING
DEFINE m_langname, m_user_agent STRING
--------------------------------------------------------------------------------
#+ Initialize Function
#+
#+ @param mdi_sdi 	Char(1):	"S"-Sdi "M"-mdi Container "C"-mdi Child
#+ @param l_key 		String:		name for .4ad/.4st/.4tb - default="default"
#+ @param l_use_fi 	Smallint:	TRUE/FALSE Set Form Initializer to gl_forminit.
#+ @return Nothing.
FUNCTION gl_init(mdi_sdi, l_key, l_use_fi) --{{{
	DEFINE mdi_sdi CHAR(1)
	DEFINE l_key,l_desc,fe_typ,fe_ver,l_container,l_sttype STRING
	DEFINE l_use_fi,x SMALLINT

--If not set then use ARG_VAL(0) and remove path and extensions from it
	IF gl_progname IS NULL THEN
		LET gl_progname = base.Application.getProgramName()
		LET x = gl_progname.getIndexOf(".",1)
		IF x > 0 THEN
			LET gl_progname = gl_progname.subString(1,x-1)
		END IF
	END IF

	LET m_user_agent = fgl_getEnv("FGL_WEBSERVER_HTTP_USER_AGENT")
	IF fgl_getEnv("STUDIO") = 1 AND m_user_agent.getLength() < 2 THEN
		CALL startlog(base.Application.getProgramName()||".s.log")
	ELSE
		CALL startlog(base.Application.getProgramName()||".log")
	END IF

GL_MODULE_ERROR_HANDLER
	OPTIONS ON CLOSE APPLICATION CALL gl_appClose
	OPTIONS ON TERMINATE SIGNAL CALL gl_appTerm

	LET g_dbgLev = fgl_getEnv("FJS_GL_DBGLEV") -- my environment variable.
																-- 0 = None -- 1 = General Messages -- 2 = All

	IF g_dbgLev IS NULL THEN LET g_dbgLev = 0 END IF
	GL_DBGMSG(1, "gl_init: Debug Level:"||g_dbgLev)

	LET gl_auditFile = fgl_getEnv("GL_AUDITFILE")
	LET gl_auditTable = fgl_getEnv("GL_AUDITTABLE")
	CALL gl_auditLog(TRUE,"start")

	LET l_desc = base.application.getResourceEntry("fglrun.localization.file.1.name")
	IF l_desc IS NULL THEN
--		GL_DBGMSG(0, "gl_init:WARNING: No localization file specified in FGLPROFILE!")
	END IF

	IF mdi_sdi IS NULL THEN LET mdi_sdi = "S" END IF
	IF gl_os IS NULL THEN
&ifdef genero13x
		LET gl_os = "No Idea!"
&else
		IF os.Path.separator() = "\\" THEN
			LET gl_os = "Windows"
		ELSE
			LET gl_os = gl_getUname()
			LET gl_os = gl_os.append(" - "||gl_getLinuxVer() )
		END IF
&endif
	END IF
	GL_DBGMSG(1, "gl_init: OS:"||gl_os)

	GL_DBGMSG(1, "gl_init: FGLDIR="||fgl_getEnv("FGLSDIR"))
	GL_DBGMSG(1, "gl_init: FGLSERVER="||fgl_getEnv("FGLSERVER"))
	GL_DBGMSG(1, "gl_init: FGLPROFILE="||fgl_getEnv("FGLPROFILE"))
	GL_DBGMSG(1, "gl_init: DBPATH="||fgl_getEnv("DBPATH"))
	GL_DBGMSG(1, "gl_init: DBDATE="||fgl_getEnv("DBDATE"))

	IF fgl_getEnv("FGLIMAGEPATH") = " " THEN
		LET m_pics = fgl_getEnv("FJS_PICS")
		IF m_pics IS NULL OR m_pics = " " THEN
			LET m_pics = "./pics"
		ELSE
			GL_DBGMSG(1, "gl_init: FJS_PICS Set.")
		END IF
		LET m_pics = m_pics.append("/")
	ELSE
		GL_DBGMSG(1, "gl_init: FGLIMAGEPATH Set.")
		LET m_pics = NULL
	END IF
	IF m_pics IS NULL THEN
		GL_DBGMSG(1, "gl_init: m_pics=NULL")
	ELSE
		GL_DBGMSG(1, "gl_init: m_pics='"||m_pics||"'")
	END IF

	IF l_key IS NULL THEN LET l_key = "default" END IF
	LET m_key = l_key
	IF gl_toolbar IS NULL THEN LET gl_toolbar = m_key END IF
	IF gl_topmenu IS NULL THEN LET gl_topmenu = m_key END IF
	LET m_langname = fgl_getEnv("LANGNAME")
	IF m_langname IS NULL OR m_langname = " " THEN
		LET m_langname = m_key
	END IF

	LET l_key = fgl_getEnv("FJS_STYLE")
	IF l_key.getLength() < 2 THEN LET l_key = m_key END IF -- Style name taken from l_key

-- Added for web client.
	IF fgl_getEnv("FJS_GL_NOINIT") = 1 THEN
		GL_DBGMSG(1, "gl_init: FJS_GL_NOINIT is set.")
		LET l_use_fi = FALSE
	END IF

	IF l_use_fi THEN
		GL_DBGMSG(1, "gl_init: Form Initializer 'gl_forminit'.")
		CALL ui.form.setDefaultInitializer( "gl_forminit" )
	ELSE
		GL_DBGMSG(1, "gl_init: No Form Initializer.")
	END IF

	LET fe_typ = ui.interface.getFrontEndName()
	LET fe_ver = ui.interface.getFrontEndVersion()
	GL_DBGMSG(1, "gl_init: FE:"||fe_typ||" version:"||fe_ver)
	LET gl_cli_os = "?"
	LET gl_cli_osver = "?"
	LET gl_cli_un = "?"
	LET gl_cli_res = "?"
	LET gl_cli_dir = "?"
	IF fe_typ = "GWC" THEN LET gl_cli_os = "www" END IF
	IF mdi_sdi != "M" AND mdi_sdi != "C" AND fe_typ != "GWC" THEN
		CALL ui.interface.frontcall("standard","feinfo",[ "ostype" ], [ gl_cli_os ] )
		CALL ui.interface.frontcall("standard","feinfo",[ "osversion" ], [ gl_cli_osver ] )
		CALL ui.interface.frontCall("standard","feinfo",[ "screenresolution" ], [ gl_cli_res ])
		CALL ui.interface.frontCall("standard","feinfo",[ "fepath" ], [ gl_cli_dir ])
		CALL ui.interface.frontCall("standard","getenv","USERNAME",gl_cli_un)
	END IF

	CASE gl_cli_os
		WHEN "www" LET l_sttype = "www"
		WHEN "LINUX" LET l_sttype = "lnx"
		WHEN "WINDOWS" LET l_sttype = "win"
		WHEN "MAC" LET l_sttype = "osx"
		OTHERWISE LET l_sttype = "win"
	END CASE
	DISPLAY "l_sttype:",l_sttype," :gl_cli_os:",gl_cli_os
	WHENEVER ERROR CONTINUE
	CALL ui.interface.loadStyles( m_key||"_"||l_sttype||".4st" )
	IF STATUS = 0 THEN
		GL_DBGMSG(1, "gl_init: Styles '"||m_key||"_"||l_sttype||"' loaded.")
	ELSE
		GL_DBGMSG(1, "gl_init: Styles '"||m_key||"_"||l_sttype||"' FAILED to load!")
		CALL ui.interface.loadStyles( m_key )
		IF STATUS = 0 THEN
			GL_DBGMSG(1, "gl_init: Styles '"||m_key.trim()||"' loaded.")
		ELSE
			GL_DBGMSG(0, "gl_init: Styles '"||m_key.trim()||"' FAILED to load!")
		END IF
	END IF
	LET l_key = fgl_getEnv("FJS_STYLE2")
	IF l_key.getLength() > 1 THEN
		CALL gl_mergeST(l_key,2,NULL) -- Merge this style file in with the default one.
	END IF
	CALL gl_addStyles() -- Add default colours and font sizes.
	LET l_key = fgl_getEnv("FJS_ACTIONS")
	IF l_key.getLength() < 1 THEN LET l_key = m_langname END IF
	CALL ui.interface.loadActionDefaults( l_key )
	IF STATUS = 0 THEN
		GL_DBGMSG(1, "gl_init: Action Defaults '"||l_key.trim()||"' loaded.")
	ELSE
		GL_DBGMSG(0, "gl_init: Action Defaults '"||l_key.trim()||"' FAILED to load!")
	END IF

	IF NOT l_use_fi AND NOT gl_noToolBar THEN
		CALL ui.interface.loadToolbar( gl_toolbar )
		IF STATUS = 0 THEN
			GL_DBGMSG(1, "gl_init: Toolbar '"||gl_toolbar||"' loaded.")
		ELSE
			GL_DBGMSG(0, "gl_init: Toolbar '"||gl_toolbar||"' FAILED to load!")
		END IF
	END IF

	IF mdi_sdi = "M" OR mdi_sdi = "s" THEN -- Startmenu only for MDI Container.
		CALL ui.Interface.loadStartMenu( m_key )
		IF STATUS = 0 THEN
			GL_DBGMSG(1, "gl_init: Start Menu '"||m_key.trim()||"' loaded.")
		ELSE
			GL_DBGMSG(0, "gl_init: Start Menu'"||m_key.trim()||"' FAILED to load!")
		END IF
	END IF
	WHENEVER ERROR CALL gl_error

	IF gl_progIcon IS NOT NULL THEN
		IF m_pics IS NOT NULL THEN
			CALL ui.interface.setImage( m_pics.trim()||gl_progIcon )
		ELSE
			CALL ui.interface.setImage( gl_progIcon )
		END IF
		GL_DBGMSG(1, "gl_init: load progIcon '"||gl_progIcon||"'.")
	END IF

	LET l_container = fgl_getEnv("FJS_MDICONT")
	IF l_container IS NULL OR l_container = " " THEN
		LET l_container = "MDIcontain"
	END IF
	LET l_desc = fgl_getEnv("FJS_MDITITLE")
	IF l_desc IS NULL OR l_desc = " " THEN
		LET l_desc = "MDI Container:"||l_container
	END IF
	CASE mdi_sdi
		WHEN "C" -- Child
			GL_DBGMSG(2, "gl_init: Child")
			CALL ui.Interface.setType("child")
			CALL ui.Interface.setContainer(l_container)
		WHEN "M" -- MDI Container
			GL_DBGMSG(2, "gl_init: Container:"||l_container)
			CALL ui.Interface.setText(l_desc)
			CALL ui.Interface.setType("container")
			CALL ui.Interface.setName(l_container)
	END CASE

	IF gl_progname IS NOT NULL AND gl_progname != " " THEN
		CALL gl_titleApp( gl_progname.trim() )
	END IF

	LET l_key = fgl_getEnv("WCBASEURL")
	IF LENGTH( l_key ) THEN
		TRY
			CALL ui.Interface.frontCall("standard","setwebcomponentpath",l_key,x)
		CATCH
-- 2.30 GDDC feature!
		END TRY
		IF NOT x THEN
-- should do error message
		END IF
		GL_DBGMSG(1, "gl_init: WebComponent Base:"||l_key.trim())
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Cleanly exit program, setting exit status.
#+
#+ @param stat Exit status 0 or -1 normally.
#+ @param reason For Exit, clean, crash, closed, terminated etc
#+ @return none
FUNCTION gl_exitProgram(stat,reason)
	DEFINE stat SMALLINT
	DEFINE reason STRING
	IF reason IS NULL THEN LET reason = "clean" END IF
	CALL gl_auditLog(FALSE,reason)
	EXIT PROGRAM stat
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ On Application Close - auditLog
FUNCTION gl_appClose()
	CALL gl_auditLog(FALSE,"close")
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ On Application Terminalate - auditLog
FUNCTION gl_appTerm()
	CALL gl_auditLog(FALSE,"terminate")
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Audit Log
#+
#+ User Environment variables for destination of log:
#+
#+	See gl_init for setting of gl_auditFile and gl_auditTable
#+ @code
#+ 	LET gl_auditFile = fgl_getEnv("GL_AUDITFILE")
#+	LET gl_auditTable = fgl_getEnv("GL_AUDITTABLE")
#+
#+ @param start 1=Start 0=Finished 2=Updating
#+ @param how Text for Finishing/Updating
#+ @return none
FUNCTION gl_auditLog(start,how)
	DEFINE start SMALLINT
	DEFINE how, progName, msg, username, args, stmt STRING
	DEFINE c base.Channel
	DEFINE l_pid INTEGER
	DEFINE l_dte DATE
	DEFINE auditFile, auditTable BOOLEAN
	DEFINE x, l_stat SMALLINT
	DEFINE l_cur DATETIME HOUR TO SECOND
	DEFINE dbcon STRING
	CONSTANT del = "|"

	LET dbcon = fgl_getEnv("DBCON") -- set in gl_db.4gl
	IF gl_auditFile.getLength() < 1
	AND gl_auditTable.getLength() < 1 THEN RETURN END IF

	LET auditTable = FALSE
	LET auditFile = FALSE
	IF gl_auditFile.getLength() > 1 THEN
		LET c = base.Channel.create()
		TRY
			CALL c.openFile(gl_auditFile,"a")
			LET auditFile = TRUE
		CATCH
--TODO: error message
		END TRY
	END IF
	LET l_dte = TODAY
	LET l_pid = fgl_getPID()
	IF gl_auditTable.getLength() > 1 AND dbcon.getLength() > 1 THEN
		TRY
			DISPLAY "Doing count on gl_audit"
			PREPARE a_chk FROM "SELECT COUNT(*) FROM "||gl_auditTable||" WHERE pid = ? AND start_date = ?"
			EXECUTE a_chk USING l_pid, l_dte INTO x
			LET auditTable = TRUE
		CATCH
			LET l_stat = STATUS
			CASE l_stat
				WHEN 0
					DISPLAY "Okay" -- Okay
				WHEN -349  -- no db connection
					GL_DBGMSG(1,"gl_auditLog: no db connection")
				WHEN -1803 -- no db connection
					GL_DBGMSG(1,"gl_auditLog: no db connection")
				WHEN -206 -- no table
					GL_DBGMSG(1,"gl_auditLog: no table")
					TRY
						LET stmt = "CREATE TABLE "||gl_auditTable||" ("||
														"start_date DATE,"||
														"start_time DATETIME HOUR TO SECOND,"||
														"end_time DATETIME HOUR TO SECOND,"||
														"pid INTEGER,"||
														"username VARCHAR(20),"||
														"progname VARCHAR(20),"||
														"what VARCHAR(40),"||
														"args VARCHAR(50) )"

						TRY
							PREPARE a_cre FROM stmt
						CATCH
							IF NOT gl_sqlStatus(__LINE__,__FILE__,stmt) THEN ERROR "failed!" END IF
						END TRY
						TRY
							EXECUTE a_cre
							LET auditTable = TRUE
						CATCH
							IF NOT gl_sqlStatus(__LINE__,__FILE__,stmt) THEN ERROR "failed!" END IF
						END TRY
						TRY
							CREATE UNIQUE INDEX gl_audit_idx ON gl_audit (pid,start_date)
						CATCH
							IF NOT gl_sqlStatus(__LINE__,__FILE__,"Create index on gl_audit") THEN ERROR "failed!" END IF
						END TRY
					CATCH
						CALL gl_winMessage("Audit","Failed to crea
Update Audit recordte audit table\n"||SQLERRMESSAGE,"exclamation")
						GL_DBGMSG(1,"gl_auditLog: create failed\n"||SQLERRMESSAGE)			
					END TRY
				OTHERWISE
					LET STATUS = l_stat
					IF NOT gl_sqlStatus(__LINE__,__FILE__,NULL) THEN ERROR "failed!" END IF
			END CASE
		END TRY
	END IF
	LET username = fgl_getEnv("GL_USERNAME")
	IF username.getLength() < 1 THEN
		LET username = "unknown" -- gl_cliUserName()
	END IF
	LET progName = base.Application.getProgramName()
	LET args = base.Application.getArgument(1)
	FOR x = 2 TO base.Application.getArgumentCount()
		LET args = args.append( " "||base.Application.getArgument(x) )
	END FOR
	IF args.getLength() < 1 THEN LET args = "No args" END IF

	CASE start
		WHEN TRUE
			LET msg = progName||del||"Started"||del||how||del||args
		WHEN FALSE
			LET msg = progName||del||"Finished"||del||how||del
		OTHERWISE
			LET msg = progName||del||"Update"||del||how||del
	END CASE

	IF auditTable THEN
		TRY
			EXECUTE a_chk USING l_pid, l_dte INTO x
		CATCH
			-- this can happen if the table has jus been created, so don't panic.
		END TRY
		IF x = 0 THEN 
			LET stmt = "INSERT INTO "||gl_auditTable||" VALUES(TODAY,?,NULL,"||
									l_pid||",'"||username||"','"||progName||"','"||
									how||"','"||args||"')"
			TRY
				PREPARE a_ins FROM stmt
				LET l_cur = (CURRENT HOUR TO SECOND)
				EXECUTE a_ins USING l_cur
				DISPLAY "Inserted Audit record"
			CATCH
				CALL gl_winMessage("Audit","Failed to insert into audit table!\n"||stmt||"\n"||SQLERRMESSAGE,"exclamation")
			END TRY
		ELSE
			IF start = 0 THEN
				LET stmt = "UPDATE "||gl_auditTable||
					" SET (end_time, what) = (?,'"||how||"')"||
					" WHERE pid = ?"
			ELSE
				LET stmt = "UPDATE "||gl_auditTable||
					" SET (username, what) = ('"||username||"','"||how||"')"||
					"WHERE pid = ?"
			END IF
			TRY
				PREPARE a_upd FROM stmt
				LET l_cur = (CURRENT HOUR TO SECOND)
				IF start = 0 THEN
					EXECUTE a_upd USING l_cur, l_pid
				ELSE
					EXECUTE a_upd USING l_pid
				END IF
				DISPLAY "Update Audit record"
			CATCH
				IF NOT gl_sqlStatus(__LINE__,__FILE__,NULL) THEN ERROR "failed!" END IF
				DISPLAY "stmt:",stmt 
				CALL gl_winMessage("Audit","Failed to update audit record!\n"||stmt||"\n"||SQLERRMESSAGE,"exclamation")
			END TRY
		END IF
	END IF

	IF auditFile THEN
		CALL c.writeLine(CURRENT||del||l_pid||del||username||del||msg)
		CALL c.close()
	END IF
	GL_DBGMSG(0,"gl_auditLog:"||msg)
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Set the gl variables for version / splash / progname etc
#+
#+ @param p_version Version
#+ @param p_splash Splash Image
#+ @param p_progicon Icon Image
#+ @param p_progname Program Name
#+ @param p_progdesc Program description
#+ @param p_progauth Program Author
#+ @return none
FUNCTION gl_setInfo(p_version, p_splash, p_progicon, p_progname, p_progdesc, p_progauth) --{{{
	DEFINE p_version, p_splash, p_progicon, p_progname, p_progdesc, p_progauth STRING

	LET gl_version = p_version
	LET gl_splash = p_splash
	LET gl_progicon = p_progicon
	LET gl_progname = p_progname
	LET gl_progdesc = p_progdesc
	LET gl_progauth = p_progauth

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Set the gl variables for application name and build number
#+
#+ @param app_name Appliciation Name
#+ @param app_build Build No / SVN/CVS Revision
FUNCTION gl_setAppInfo(app_name, app_build) --{{{
	DEFINE app_name, app_build STRING

	LET gl_app_name = app_name
	LET gl_app_build = gl_verFmt( app_build )

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Form Initializer. Call automatically set setDefaultinitializer is used.
#+
#+ @param fm Form object to be initialized.
FUNCTION gl_formInit(fm) --{{{
	DEFINE fm ui.Form
	DEFINE fn om.DomNode
	DEFINE nam,styl,tag STRING
	DEFINE win ui.Window
	DEFINE nl om.nodeList

	GL_DBGMSG(1, "gl_formInit: start")

	LET fn = fm.getNode()

	LET nam = fn.getAttribute("name")
	LET styl = fn.getAttribute("style")
	LET tag = fn.getAttribute("tag")
	IF tag IS NULL THEN LET tag = "(null)" END IF
	GL_DBGMSG(0, "gl_formInit: tag='"||tag||"'")
	IF styl IS NULL THEN -- check to see if the window had the style set.
		LET win = ui.Window.getCurrent()
		LET fn = win.getNode()
		LET styl = fn.getAttribute("style")
		LET fn = fm.getNode()
	END IF
	IF styl IS NULL THEN
		GL_DBGMSG(1, "gl_formInit: form='"||nam||"' style=NULL")
		LET styl = "NULL"
	ELSE
		GL_DBGMSG(1, "gl_formInit: form='"||nam||"' style='"||styl||"'")
	END IF
	LET nl = fn.selectByTagName("ToolBar")
	
	IF styl != "splash" 
	AND styl != "dialog" 	AND styl != "dialog2" 	AND styl != "dialog3" 
	AND styl != "menu" AND styl != "pricecalc"
	AND styl != "lookup" AND styl != "naked" AND styl != "about"  AND styl != "viewer"
	AND styl != "wizard" THEN
		GL_DBGMSG(1, "gl_formInit: loading Toolbar '"||gl_toolbar||"'")
		IF NOT gl_noToolBar AND nl.getlength() < 1 THEN
			TRY
				CALL fm.loadToolbar( gl_toolbar )
			CATCH
				GL_DBGMSG(0, "gl_formInit: Failed to load Toolbar '"||gl_toolbar||"'")
			END TRY
		END IF

		IF styl != "main" AND gl_topmenu != "default" THEN -- normal won't want default?
			GL_DBGMSG(1, "gl_formInit: loading Topmenu '"||gl_topmenu||"'")
			TRY
				CALL fm.loadTopmenu( gl_topmenu )
			CATCH
				GL_DBGMSG(0, "gl_formInit: Failed to load Topmenu '"||gl_topmenu||"'")
			END TRY
		END IF
	END IF

	CALL gl_titleWin(NULL)

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+  title the application ( Text on start menu! )
#+
#+ @param titl title for application
#+ @return none
FUNCTION gl_titleApp( titl ) --{{{
	DEFINE titl STRING
	DEFINE n om.domNode

	LET n = ui.interface.getRootNode()
	CALL n.setAttribute( "text", titl )
-- Why not use ui.interface.setText ?

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ set Window image.
#+
#+ @param l_img image name (without extension)
#+ @return none
FUNCTION gl_winImage( l_img ) --{{{
	DEFINE l_img STRING
	DEFINE win ui.Window
	DEFINE n om.domNode

	LET win = ui.Window.getCurrent()
	IF win IS NULL THEN
		GL_DBGMSG(1, "gl_winImage: No Current Window!")
		RETURN
	END IF
	GL_DBGMSG(3, "gl_winImage: Image set to "||l_img)
    
	CALL ui.interface.setImage( l_img )
--	CALL win.setImage( img )
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Title the application
#+
#+ @param titl title for the window, can be NULL ( defaults to title from Form )
#+ @return none
FUNCTION gl_titleWin( titl ) --{{{
	DEFINE titl,new STRING
	DEFINE win ui.Window
	DEFINE n om.domNode

	LET win = ui.Window.getCurrent()
	IF win IS NULL THEN
		GL_DBGMSG(1, "gl_titleWin: No Current Window!")
		RETURN
	END IF

	LET n = gl_getFormN( NULL )
	IF n IS NULL THEN
--		CALL gl_errMsg(__FILE__,__LINE__,"gl_titleWin: No Form object found!")
	END IF
	IF titl IS NULL OR titl = " " THEN
		IF n IS NOT NULL THEN
			LET titl = n.getAttribute("text")
		END IF
		IF ( titl IS NULL OR titl = " " ) THEN
			LET titl = win.getText()
		END IF
		IF ( titl IS NULL OR titl = " " ) THEN
			LET titl = gl_progdesc
		ELSE
			IF titl.subString(11,11) = ":" THEN LET titl = titl.subString(12,titl.getLength()) END IF
		END IF
-- 01/01/1970:
-- 12345678901
	END IF

	LET new = TODAY,":"
	IF gl_progname IS NOT NULL THEN
		LET new = new.trim()," ",gl_progname.trim()
	END IF
	IF gl_version IS NOT NULL THEN
		LET new = new.trim()," ",gl_verFmt(gl_version)
	END IF
	IF titl IS NOT NULL THEN
		LET new = new.trim()," - ",titl.trim()
	END IF

	GL_DBGMSG(1, "gl_titleWin: new '"||new||"'")
	CALL win.setText( new )
	IF n IS NOT NULL THEN
		CALL n.setAttribute("text",new )
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Return the node for a named window.
#+
#+ @param l_nam The name of window, if null current window node is returned.
#+ @return ui.Window.
FUNCTION gl_getWinNode(l_nam) --{{{
	DEFINE l_nam STRING
	DEFINE uiwin ui.Window

	IF l_nam IS NULL THEN
		LET uiwin = ui.Window.getCurrent()
		LET l_nam = "SCREEN"
	ELSE
		LET uiwin = ui.Window.forName(l_nam)
	END IF

	IF uiwin IS NULL THEN
--		CALL gl_errMsg(__FILE__,__LINE__,"gl_getWinNode: Failed to get Window '"||nam||"'. ")
		CALL gl_errMsg(__FILE__,__LINE__,SFMT(%"lib.getwinnode.error",l_nam) )
	ELSE
		RETURN uiwin.getNode()
	END IF
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically generate a form object & return it's node.
#+
#+ @param l_nam name of Form, Should not be NULL!
#+ @return ui.Form.
FUNCTION gl_genForm( l_nam ) --{{{
	DEFINE l_nam STRING
	DEFINE uiwin ui.Window
	DEFINE uifrm ui.Form

	LET uiwin = ui.Window.getCurrent()
	IF uiwin IS NULL THEN
		CALL gl_errMsg(__FILE__,__LINE__,SFMT(%"genForm: failed to get Window '%1'","CURRENT") )
		RETURN NULL
	END IF

	LET uifrm = uiwin.createForm( l_nam )
	IF uifrm IS NULL THEN
--		CALL gl_errMsg(__FILE__,__LINE__,SFMT(%"lib.genForm.error",nam) )
		CALL gl_errMsg(__FILE__,__LINE__,SFMT(%"genForm: createForm('%1') failed !!",l_nam) )
		RETURN NULL
	END IF

	RETURN uifrm.getNode()
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Return the form object for the named form.
#+
#+ @param l_nam name of Form, if null current Form object is returned.
#+ @return ui.Form.
FUNCTION gl_getForm( l_nam ) --{{{
	DEFINE l_nam STRING
	DEFINE uiwin ui.Window
	DEFINE uifrm ui.Form

	IF l_nam IS NULL THEN
		LET uiwin = ui.Window.getCurrent()
		LET uifrm = uiwin.getForm()
	ELSE
	-- not written yet!
	END IF

	RETURN uifrm
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Return the form NODE for the named form.
#+
#+ @param l_nam name of Form, if null current Form node is returned.
#+ @return Node.
FUNCTION gl_getFormN( l_nam ) --{{{
	DEFINE l_nam STRING
	DEFINE uiwin ui.Window
	DEFINE uifrm ui.Form
	DEFINE nl om.nodeList
	DEFINE n om.domNode

	IF l_nam IS NULL THEN
		LET uiwin = ui.Window.getCurrent()
		LET uifrm = uiwin.getForm()
		IF uifrm IS NULL THEN
--			CALL gl_errMsg(__FILE__,__LINE__,"gl_getFormN: Couldn't get Form for Current Window!")
			RETURN NULL
		END IF
		LET n = uifrm.getNode()
	ELSE
		LET nl = n.selectByPath("//Form[@name='"||l_nam.trim()||"']")
		IF nl.getLength() < 1 THEN
			CALL gl_errMsg(__FILE__,__LINE__,"gl_getFormN: Form not found '"||l_nam.trim()||"'!")
			RETURN NULL
		ELSE
			LET n = nl.item(1)
		END IF
	END IF

	RETURN n
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Append a node(+it's children) from a different DomDocument to a node.
#+
#+ @param cur = Node:			node to append to
#+ @param new = Node:			node to append from
#+ @param lev = Smallint:	0 - Used by this function for recursive calls.
#+ @return Nothing.
FUNCTION gl_appendNode( cur, new, lev ) --{{{
	DEFINE cur, new, tmp, cld om.DomNode
	DEFINE x,lev SMALLINT

	WHILE new IS NOT NULL
		IF new.getTagName() = "LStr" THEN RETURN END IF
		LET tmp = cur.createChild( new.getTagName() )
		FOR x = 1 TO new.getAttributesCount()
			CALL tmp.setAttribute( new.getAttributeName(x), new.getAttributeValue(x) )
		END FOR
		LET cld = new.getFirstChild()
		IF cld IS NOT NULL THEN
			CALL gl_appendNode( tmp, cld, lev+1 )
		END IF
		IF lev = 0 THEN EXIT WHILE END IF
		LET new = new.getNext()
	END WHILE

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically add a form as a snippet to the passed node
#+
#+ @param cont node of Containt to add snippet to.
#+ @param fname name of the .42f to load ( without the extension )
#+ @return Nothing.
FUNCTION gl_addSnippet( cont, fname ) --{{{
	DEFINE frm, cont om.DomNode
	DEFINE fname, addname STRING
	DEFINE tabn,coln STRING
	DEFINE new, tmp, tmp2 om.DomNode
	DEFINE newfrm om.DomDocument
	DEFINE nl,nl2 om.NodeList
	DEFINE x,x2,fldn SMALLINT

	GL_DBGMSG(1, "gl_addSnippet: fname='"||fname||"'")

-- Get the node for current form. Needed to add record views.
	LET frm = gl_getFormN( NULL )

-- Load the .42f and find the 1st child of the Form element.
	LET addname = fname.append(".42f")
	LET newfrm = om.DomDocument.createFromXMLFile(addname)
	IF newfrm IS NULL THEN
		GL_DBGMSG(1, SFMT("Faied to open %1",addname) ) -- "Failed to open ''."
		CALL gl_winMessage("Error",SFMT("Faied to open %1",addname),"exclamation")
		RETURN NULL
	END IF
	LET new = newfrm.getDocumentElement()
	LET nl = new.selectByPath("//Form")
	GL_DBGMSG(1, "gl_addSnippet: New Form Found:"||nl.getLength())
	LET tmp = nl.item(1)
	LET tmp = tmp.getFirstChild()
	WHILE TRUE
		IF tmp.getTagName() != "ActionDefaultList"
		AND tmp.getTagName() != "TopMenu"
		AND tmp.getTagName() != "ToolBar" THEN EXIT WHILE END IF
		LET tmp = tmp.getNext()
	END WHILE

-- Re-number the fieldIdRef's so record views can be done.
	LET nl2 = tmp.selectByPath("//FormField")
	FOR x2 = 1 TO nl2.getLength()
		LET tmp2 = nl2.item(x2)
		LET fldn = tmp2.getAttribute("fieldId")
		CALL tmp2.setAttribute("fieldId",fldn+4000 )
	END FOR

-- Append the new form to the 'cont' node.
	CALL gl_appendNode( cont, tmp, 0 )

-- Dynamically add any record views + re-number the fieldIdRefs
	LET nl = new.selectByPath("//RecordView")
	FOR x = 1 TO nl.getLength()
		LET tmp = nl.item(x)
		LET tabn = tmp.getAttribute("tabName")
		IF tabn != "formonly" THEN
			LET nl2 = tmp.selectByPath("//Link")
			FOR x2 = 1 TO nl2.getLength()
				LET tmp2 = nl2.item(x2)
				LET coln = tmp2.getAttribute("colName")
				LET fldn = tmp2.getAttribute("fieldIdRef")
				CALL tmp2.setAttribute("fieldIdRef",fldn+4000 )
			END FOR
			CALL gl_appendNode( frm, tmp, 0 )
		END IF
	END FOR

	RETURN cont.getFirstChild()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically remove snippet form from passed node
#+
#+ @param cont node to remove.
#+ @return Nothing.
FUNCTION gl_removeSnippet( cont ) --{{{
	DEFINE frm, cont, part om.DomNode
	DEFINE tmp, tmp2 om.DomNode
	DEFINE nl,nl2 om.NodeList
	DEFINE x,x2,fldn SMALLINT

	GL_DBGMSG(1, "gl_removeSnippet")

	LET part = cont.getParent()
	CALL part.removeChild( cont )

-- Get the node for current form. Needed to add record views.
	LET frm = gl_getFormN( NULL )

-- Dynamically remove re-numbered fieldIdRefs
	LET nl = frm.selectByPath("//RecordView")
	FOR x = 1 TO nl.getLength()
		LET tmp = nl.item(x)
		LET nl2 = tmp.selectByPath("//Link")
		FOR x2 = 1 TO nl2.getLength()
			LET tmp2 = nl2.item(x2)
			LET fldn = tmp2.getAttribute("fieldIdRef")
			IF fldn > 4000 THEN
				CALL tmp.removeChild( tmp2 )
			END IF
		END FOR
	END FOR

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically add folder
#+
#+ @param nam Node of the folder, can be NULL
#+ @return Folder node
FUNCTION gl_addFolder(nam) --{{{
	DEFINE nam STRING
	DEFINE win ui.window
	DEFINE n om.domNode
	DEFINE nl om.nodeList

	LET win = ui.window.getCurrent()

	LET n = win.getNode()
	LET nl = n.selectByPath("//VBox")
	IF nl.getLength() < 1 THEN
		RETURN NULL
	END IF
	LET n = nl.item(1)

	LET n = n.createChild("Folder")
	CALL n.setAttribute("name",nam)

	RETURN n

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically add a form as a page to the passed folder tab
#+
#+ @param fld node of Folder to add pages to.
#+ @param pgno number of the page, ie 1,2,3 etc
#+ @param fname name of the .42f to load ( without the extension )
#+ @param pgnam Title of the Page. - If NULL using text from LAYOUT
#+ @return Nothing.
FUNCTION gl_addPage( fld, pgno, fname, pgnam ) --{{{
	DEFINE frm, fld, pg om.DomNode
	DEFINE pgnam, fname, addname STRING
	DEFINE tabn,coln STRING
	DEFINE new, tmp, tmp2, tmp3, tmp4 om.DomNode
	DEFINE newfrm om.DomDocument
	DEFINE nl,nl2 om.NodeList
	DEFINE pgno, x, x2, x3,fldn SMALLINT

	GL_DBGMSG(1, "gl_addPage: fname='"||fname||"' pgnam='"||pgnam||"'")

-- Get the node for current form. Needed to add record views.
	LET frm = gl_getFormN( NULL )

-- Load the .42f and find the 1st child of the Form element.
	LET addname = fname.append(".42f")
	LET newfrm = om.DomDocument.createFromXMLFile(addname)
	IF newfrm IS NULL THEN
		GL_DBGMSG(1, SFMT(%"lib.addpage.error",addname) ) -- "Failed to open ''."
		CALL gl_winMessage("Error",SFMT(%"lib.addpage.error",addname),"exclamation")
		RETURN
	END IF
	LET new = newfrm.getDocumentElement()
	LET nl = new.selectByPath("//Form")
	GL_DBGMSG(1, "gl_addPage: New Form Found:"||nl.getLength())
	LET tmp = nl.item(1)
	IF pgnam IS NULL THEN LET pgnam = tmp.getAttribute( "text" ) END IF
	LET tmp = tmp.getFirstChild()
	WHILE TRUE
		IF tmp.getTagName() != "ActionDefaultList"
		AND tmp.getTagName() != "TopMenu"
		AND tmp.getTagName() != "ToolBar" THEN EXIT WHILE END IF
		LET tmp = tmp.getNext()
	END WHILE

-- Re-number the fieldIdRef's so record views can be done.
	LET nl2 = tmp.selectByPath("//FormField")
	FOR x2 = 1 TO nl2.getLength()
		LET tmp2 = nl2.item(x2)
		LET fldn = tmp2.getAttribute("fieldId")
		CALL tmp2.setAttribute("fieldId",fldn+(pgno*100) )
	END FOR
	LET nl2 = tmp.selectByPath("//PhantomColumn")
	FOR x2 = 1 TO nl2.getLength()
		LET tmp2 = nl2.item(x2)
		LET fldn = tmp2.getAttribute("fieldId")
		CALL tmp2.setAttribute("fieldId",fldn+(pgno*100) )
	END FOR

-- Create new page in the folder and add the form to it
	LET pg = fld.createChild("Page")
-- Check to see if fname has path info
	FOR x  = fname.getLength() TO 1 STEP -1
		IF fname.getCharAt(x) = "/" THEN
			LET fname = fname.subString(x+1, fname.getLength() )
			EXIT FOR
		END IF	
	END FOR
	CALL pg.setAttribute("name",fname)
	CALL pg.setAttribute("text",pgnam)
	CALL pg.setAttribute("action","page"||pgno) -- default action.
	CALL gl_appendNode( pg, tmp, 0 )

	LET nl = pg.selectByPath("//Table")
	FOR x = 1 TO nl.getLength()
		LET tmp = nl.item(x)
		LET x2 = tmp.getAttribute("pageSize")
		--DISPLAY "TABLE:", tmp.getAttribute("isTree"),":",x2
		IF tmp.getAttribute("isTree") = "1" THEN
			--DISPLAY "TREE!!!!"
			LET tmp3 = tmp.getFirstChild()
			LET tmp2 = tmp.createChild("TreeInfo")
			CALL tmp.insertBefore(tmp2,tmp3)
			LET nl2 = tmp.selectByPath("//PhantomColumn")
			FOR fldn = 1 TO nl2.getLength()
				LET tmp3 = nl2.item(fldn)
				LET tmp3 = tmp3.createChild("ValueList")
			END FOR
			LET nl2 = tmp.selectByPath("//TableColumn")
			FOR fldn = 1 TO nl2.getLength()
				LET tmp3 = nl2.item(fldn)
				LET tmp3 = tmp3.createChild("ValueList")
				FOR x3 = 1 TO x2 
					LET tmp4 = tmp3.createChild("Value")
					CALL tmp4.setAttribute("value","")
				END FOR
			END FOR
		END IF
	END FOR

	--DISPLAY "ADDING RECORDVIEW"
-- Dynamically add any record views + re-number the fieldIdRefs
	LET nl = new.selectByPath("//RecordView")
	FOR x = 1 TO nl.getLength()
		LET tmp = nl.item(x)
		LET tabn = tmp.getAttribute("tabName")
		--DISPLAY "tabname:",tabn
		IF tabn != "formonly" THEN
			LET nl2 = tmp.selectByPath("//Link")
			FOR x2 = 1 TO nl2.getLength()
				LET tmp2 = nl2.item(x2)
				LET coln = tmp2.getAttribute("colName")
				--DISPLAY "colname:",coln
				LET fldn = tmp2.getAttribute("fieldIdRef")
				CALL tmp2.setAttribute("fieldIdRef",fldn+(pgno*100) )
			END FOR
			CALL gl_appendNode( frm, tmp, 0 )
		END IF
	END FOR

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically find a folder
#+
#+ @param nam Node of the folder, can be NULL
#+ @return Folder node
FUNCTION gl_findFolder(nam) --{{{
	DEFINE nam STRING
	DEFINE win ui.window
	DEFINE n om.domNode
	DEFINE nl om.nodeList

	LET win = ui.window.getCurrent()
	LET n = win.getNode()
	IF nam IS NOT NULL THEN
		LET nl = n.selectByPath("//Folder[@name='"||nam||"']")
	ELSE
		LET nl = n.selectByPath("//Folder")
	END IF
	IF nl.getLength() < 1 THEN
		RETURN NULL
	END IF
	RETURN nl.item(1)
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Find a folder page.
#+ NOTE: fld or fname need to be supplied, both can't be NULL!
#+
#+ @param folder node of Folder to add pages to. Can be NULL
#+ @param fname name of the Folder ( if fld is NULL )
#+ @param page name of the Page to find
#+ @return Node of page
FUNCTION gl_findPage( folder,fname, page ) --{{{
	DEFINE folder om.DomNode
	DEFINE frm ui.Form
	DEFINE fname, page STRING
	DEFINE nl om.NodeList

	IF folder IS NULL THEN
		LET frm = gl_getForm(NULL)
		LET folder = frm.findNode("Folder",fname.trim())
		IF folder IS NULL THEN
			CALL gl_errMsg(__FILE__,__LINE__,"gl_findPage: Not found Folder '"||fname.trim()||"'!")
			RETURN NULL
		END IF
	END IF

	LET nl = folder.selectByPath("//Page[@name=\""||page.trim()||"\"]")
	IF nl.getLength() != 1 THEN -- not found or too many!!
		CALL gl_errMsg(__FILE__,__LINE__,"gl_findPage: Not found Page '"||page.trim()||"'!")
		RETURN NULL
	END IF

	RETURN nl.item(1)

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically change title of a page
#+
#+ @param folder Node of the folder, can be NULL
#+ @param fname  Name of the folder, can be NULL only if folder is passed.
#+ @param page   Name of the page to affected.
#+ @param title  New title for the page.
#+ @return Nothing.
FUNCTION gl_titlePage( folder,fname, page, title) --{{{
	DEFINE folder,n om.DomNode
	DEFINE fname, page, title STRING

	LET n = gl_findPage( folder, fname, page )
	IF n IS NOT NULL THEN
		CALL n.setAttribute("text",title)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically hide/unhide a page
#+
#+ @param folder Node of the folder, can be NULL
#+ @param fname  Name of the folder, can be NULL only if folder is passed.
#+ @param page   Name of the page to hide/unhide
#+ @param hide   TRUE/FALSE = Hide/Unhide
#+ @return Nothing.
FUNCTION gl_hidePage( folder, fname, page, hide) --{{{
	DEFINE folder,n om.DomNode
	DEFINE fname, page STRING
	DEFINE hide SMALLINT

	LET n = gl_findPage( folder, fname, page )
	IF n IS NOT NULL THEN
		CALL n.setAttribute("hidden",hide)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically change the current page in a folder
#+  NOTE: looks more complicated than needed because it's making sure it only effect pages that are visable.
#+
#+ @param folder Node of the folder, can be NULL
#+ @param fname  Name of the folder, can be NULL only if folder is passed.
#+ @param page   Name of the page to set current.
#+ @return Nothing.
FUNCTION gl_showPage( folder, fname, page ) --{{{
	DEFINE folder,n,n1 om.DomNode
	DEFINE frm ui.Form
	DEFINE fname, page STRING
	DEFINE nl om.NodeList
	DEFINE x SMALLINT

	IF folder IS NULL THEN
		LET frm = gl_getForm(NULL)
		LET folder = frm.findNode("Folder",fname.trim())
		IF folder IS NULL THEN
			GL_DBGMSG(0, SFMT(%"gl_showPage: Folder '%1' not Found!",fname))
			RETURN
		END IF
	END IF

-- First get list of pages
	LET nl = folder.selectByPath("//Page")
	IF nl.getLength() < 1 THEN -- not found any pages.
		GL_DBGMSG(0, %"gl_showPage: no pages Found!")
		RETURN
	END IF
-- Make sure all pages have the hidden attribute set to 0 or 1
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		IF n.getAttribute("hidden") = "1" THEN
-- page not currently visible
			IF n.getAttribute("name") = page THEN
				RETURN -- not allowed to make hidden page current.
			END IF
		ELSE
			CALL n.setAttribute("hidden",0)
		END IF
	END FOR
-- Find all the unhidden pages and set to hidden, also store wanted page node.
	LET nl = folder.selectByPath("//Page[@hidden=\"0\"]")
	IF nl.getLength() < 1 THEN -- not found any pages.
		GL_DBGMSG(0, %"gl_showPage: no unhidden pages Found!")
		RETURN
	END IF
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		IF n.getAttribute("name") = page THEN LET n1 = n END IF
		CALL n.setAttribute("hidden",1)
	END FOR
-- set wanted page to unhidden.
	IF n1 IS NULL THEN
		GL_DBGMSG(0, %"gl_showPage: Something went wrong!")
	ELSE
		CALL n1.setAttribute("hidden",0)
	END IF
	CALL ui.interface.refresh()
-- set all pages(effected) to unhidden.
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CALL n.setAttribute("hidden",0)
	END FOR
	CALL ui.interface.refresh()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Hides a toolbar item.
#+
#+ @param nam Name of item
#+ @param hid TRUE/FALSE hide/unhide
#+ @return none
FUNCTION gl_hideToolBarItem(nam,hid) --{{{
	DEFINE nam STRING
	DEFINE hid SMALLINT
	DEFINE nl om.nodeList
	DEFINE n om.domNode

	LET n = ui.interface.getRootNode()
	LET nl = n.selectByPath("//ToolBarItem[@name=\""||nam||"\"]")
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
		GL_DBGMSG(1, "gl_hideToolBarItem: Setting Hidden on '"||nam||"'")
		CALL n.setAttribute("hidden",hid)
	ELSE
		GL_DBGMSG(1, "gl_hideToolBarItem: didn't find '"||nam||"'!")
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Finds a column within a table in the xml schema.
#+
#+ @param tabname Table name
#+ @param colname Colum name
#+ @param xml_sch Your xml_schema
#+ @return Node.
FUNCTION gl_findXmlCol(tabname,colname, xml_sch) --{{{
	DEFINE tabname STRING
	DEFINE colname STRING
	DEFINE xml_sch om.DomNode
	DEFINE xml_cols om.NodeList
	DEFINE xml_col om.DomNode

	IF tabname IS NOT NULL THEN
		LET xml_cols = xml_sch.selectbypath("//table[@name=\""||tabname CLIPPED||"\"]")
		IF xml_cols IS NULL OR xml_cols.getlength() < 1 THEN
			GL_DBGMSG(1, "glfindXmlCol: XML Error!//table[@name=\""||tabname CLIPPED||"\"]")
			RETURN NULL
		END IF
		LET xml_col = xml_cols.item(1)
	ELSE
		LET xml_col = xml_sch
	END IF

	LET xml_cols = xml_col.selectbypath("//column[@name=\""||colname CLIPPED||"\"]")
	IF xml_cols IS NULL OR xml_cols.getlength() < 1 THEN
		RETURN NULL
	END IF
	LET xml_col = xml_cols.item(1)
	RETURN xml_col

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically change a comment(tooltip), for the named item.
#+
#+ @param dia ui.dialog for the current dialog - can be NULL
#+ @param frm ui.form for the current form - can be NULL - defaults to current
#+ @param nam Name of form element to be affected.
#+ @param com New comment value for the named element.
#+ @return Node.
FUNCTION gl_chgComment(dia,frm,nam,com) --{{{
	DEFINE dia ui.dialog
	DEFINE frm ui.Form
	DEFINE nam,com STRING
	DEFINE nl om.NodeList
	DEFINE n om.DomNode

	IF dia IS NOT NULL THEN
		LET frm = dia.getForm()
	END IF
	IF frm IS NULL THEN
		LET n = gl_getFormN( NULL )
	ELSE
		LET n = frm.getNode()
	END IF
	LET nl = n.selectbypath("//*[@name=\""||nam CLIPPED||"\"]")
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
		IF n.getTagName() = "FormField" THEN
			LET n = n.getFirstChild()
		END IF
		CALL n.setAttribute("comment",com)
	ELSE
		CALL gl_errMsg(__FILE__,__LINE__,"gl_chgComment: name '"||nam.trim()||"' not found.")
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Splash screen
#+
#+ @return Nothing.
FUNCTION gl_splash() --{{{
	DEFINE frm,g,n om.DomNode

	CALL gl_addStyle("Window.splash")
	CALL gl_addStyle(".about")

	OPEN WINDOW splash AT 1,1 WITH 1 ROWS,1 COLUMNS ATTRIBUTE(STYLE="splash")
	LET frm = gl_genForm("splash")
	LET g = frm.createChild("Grid")

	LET n = g.createChild("Image")
	CALL n.setAttribute("name","logo" )
	CALL n.setAttribute("style","about" )
	CALL n.setAttribute("width","36" )
	CALL n.setAttribute("height","8" )
	IF m_pics IS NOT NULL THEN
		CALL n.setAttribute("image",m_pics.trim()||gl_splash )
	ELSE
		CALL n.setAttribute("image",gl_splash )
	END IF
	CALL n.setAttribute("posY","0" )
	CALL n.setAttribute("posX","0" )
	CALL n.setAttribute("gridWidth","40" )
	CALL n.setAttribute("gridHeight","8")
--	CALL n.setAttribute("sizePolicy", "dynamic" )
&ifdef genero13x
	CALL n.setAttribute("pixelHeight","200" )
	CALL n.setAttribute("pixelWidth", "570" )
&else
	CALL n.setAttribute("height","200px" )
	CALL n.setAttribute("width", "570px" )
&endif
	CALL n.setAttribute("stretch","both" )
	CALL n.setAttribute("autoScale","1" )

--	LET n = g.createChild("Label")
--	CALL n.setAttribute("posY",12)
--	CALL n.setAttribute("posX","0" )
--	CALL n.setAttribute("text",gl_progname||" - "||gl_version||"(Build "||GL_BUILD||")")
--	LET n = g.createChild("Label")

	CALL ui.interface.refresh()
	SLEEP 2
	CLOSE WINDOW splash
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Get client username
#+
FUNCTION gl_cliUserName() --{{{
	DEFINE un STRING

	IF UPSHIFT(ui.Interface.getFrontEndName()) = "GDC" THEN
		CALL ui.interface.frontCall("standard","getenv","USERNAME",un)
		IF un IS NULL THEN
			CALL ui.interface.frontCall("standard","getenv","LOGNAME",un)
		END IF
	ELSE
		LET un = fgl_getEnv("USERNAME")
		IF un IS NULL THEN
			LET un = fgl_getenv("LOGNAME")
		END IF
	END IF
	IF un IS NULL THEN LET un = "unknown" END IF
	CALL FGL_SETENV("GL_USERNAME",un)
	RETURN un
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamic About Window
#+
#+ @param gl_ver a version string
#+ @return Nothing.
FUNCTION gl_about(gl_ver) --{{{
	DEFINE gl_ver STRING
	DEFINE f,n,g,w om.DomNode
	DEFINE nl om.nodeList
	DEFINE gdcver,gver,logname, servername, info, txt STRING
	DEFINE y SMALLINT

	IF os.Path.pathSeparator() = ";" THEN -- Windows
		LET logname = fgl_getEnv("USERNAME")
		LET servername = fgl_getEnv("COMPUTERNAME")
	ELSE -- Unix / Linux
		LET logname = fgl_getEnv("LOGNAME")
		LET servername = fgl_getEnv("HOSTNAME")
	END IF
	LET gdcver = gl_feVer()
	LET gver = "build ",fgl_getVersion()

	IF gl_cli_os = "?" THEN
		CALL ui.interface.frontcall("standard","feinfo",[ "ostype" ], [ gl_cli_os ] )
		CALL ui.interface.frontcall("standard","feinfo",[ "osversion" ], [ gl_cli_osver ] )
		CALL ui.interface.frontCall("standard","feinfo",[ "screenresolution" ], [ gl_cli_res ])
		CALL ui.interface.frontCall("standard","feinfo",[ "fepath" ], [ gl_cli_dir ])
	END IF
	LET gl_cli_un = gl_cliUserName()
	CALL gl_addStyle("Window.about")
	CALL gl_addStyle(".about")

	OPEN WINDOW about AT 1,1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTE(STYLE="about")
	LET n = gl_getWinNode(NULL)
	CALL n.setAttribute("text",gl_progdesc)
	LET f = gl_genForm("about")
	LET n = f.createChild("VBox")
	CALL n.setAttribute("posY","0" )
	CALL n.setAttribute("posX","0" )

	IF gl_splash IS NOT NULL AND gl_splash != " " THEN
		LET g = n.createChild("HBox")
		CALL g.setAttribute("posY",y)
		CALL g.setAttribute("gridWidth",36)
		LET w = g.createChild("SpacerItem")

		LET w = g.createChild("Image")
		CALL w.setAttribute("posY","0" )
		CALL w.setAttribute("posX","0" )
		CALL w.setAttribute("name","logo" )
		CALL w.setAttribute("style","about")
		CALL w.setAttribute("stretch","both" )
		CALL w.setAttribute("autoScale","1" )
		CALL w.setAttribute("gridWidth","12" )
		IF m_pics IS NOT NULL THEN
			CALL w.setAttribute("image",m_pics.trim()||gl_splash )
		ELSE
			CALL w.setAttribute("image",gl_splash )
		END IF
&ifdef genero13x
		CALL w.setAttribute("pixelHeight","100" )
		CALL w.setAttribute("pixelWidth", "290" )
&else
		CALL w.setAttribute("height","100px" )
		CALL w.setAttribute("width", "290px" )
&endif

		LET w = g.createChild("SpacerItem")
		LET y = 10
	ELSE
		LET y = 1
	END IF

	LET g = n.createChild("Group")
	CALL g.setAttribute("text","About")
	CALL g.setAttribute("posY","10" )
	CALL g.setAttribute("posX","0" )
	CALL g.setAttribute("style","about")

	IF gl_app_build IS NOT NULL THEN
		CALL gl_addLabel(g, 0,y,LSTR("lib.about.application"),"right","black")
		CALL gl_addLabel(g,10,y,gl_app_name||" - "||gl_app_build,NULL,NULL) LET y = y + 1
	END IF

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.program"),"right","black")
	CALL gl_addLabel(g,10,y,gl_progname||" - "||gl_ver,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.progdesc"),"right","black")
	CALL gl_addLabel(g,10,y,gl_progdesc,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.progauth"),"right","black")
	CALL gl_addLabel(g,10,y,gl_progauth,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.generolib1"),"right","black")
	CALL gl_addLabel(g,10,y,gl_verFmt(gl_genlibver),NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.generolibd1"),"right","black")
	CALL gl_addLabel(g,10,y,gl_verFmt(gl_genlibdte),NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.genlibauth"),"right","black")
	CALL gl_addLabel(g,10,y,gl_libauth,NULL,"black") LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY",y) LET y = y + 1
	CALL w.setAttribute("posX",0)
	CALL w.setAttribute("gridWidth",25)

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.generort"),"right","black")
	CALL gl_addLabel(g,10,y,gver,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.serveros"),"right","black")
	CALL gl_addLabel(g,10,y,gl_os,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.servername"),"right","black")
	CALL gl_addLabel(g,10,y,servername,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.serveruser"),"right","black")
	CALL gl_addLabel(g,10,y,logname,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.datetime"),"right","black")
	CALL gl_addLabel(g,10,y,TODAY||" "||TIME,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.dbname"),"right","black")
	CALL gl_addLabel(g,10,y,fgl_getEnv("DBNAME"),NULL,NULL) LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.dbtype"),"right","black")
	CALL gl_addLabel(g,10,y,UPSHIFT( fgl_db_driver_type() ),NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.dbdate"),"right","black")
	CALL gl_addLabel(g,10,y,fgl_getEnv("DBDATE"),NULL,"black") LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY",y) LET y = y + 1
	CALL w.setAttribute("posX",0)
	CALL w.setAttribute("gridWidth",25)

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.clientos"),"right","black")
	CALL gl_addLabel(g,10,y,gl_cli_os||" / "||gl_cli_osver,NULL,"black") LET y = y + 1

	CALL gl_addLabel(g, 0,y,LSTR("lib.about.clientuser"),"right","black")
	CALL gl_addLabel(g,10,y,gl_cli_un,NULL,"black") LET y = y + 1

	IF m_user_agent.getLength() > 1 THEN
		CALL gl_addLabel(g, 0,y,LSTR("lib.about.useragent"),"right","black")
		CALL gl_addLabel(g,10,y,m_user_agent,NULL,"black") LET y = y + 1
	END IF
	IF gdcver.getLength() > 1 THEN
		CALL gl_addLabel(g, 0,y,LSTR("lib.about.gdcver"),"right","black")
		CALL gl_addLabel(g,10,y,gdcver,NULL,"black") LET y = y + 1

		CALL gl_addLabel(g, 0,y,LSTR("lib.about.clientdir"),"right","black")
		CALL gl_addLabel(g,10,y,gl_cli_dir,NULL,"black") LET y = y + 1

		CALL gl_addLabel(g, 0,y,LSTR("lib.about.clientres"),"right","black")
		CALL gl_addLabel(g,10,y,gl_cli_res,NULL,"black") LET y = y + 1
	END IF

	LET g = g.createChild("HBox")
	CALL g.setAttribute("posY",y)
	CALL g.setAttribute("gridWidth",40)
	LET w = g.createChild("SpacerItem")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY",y)
	CALL w.setAttribute("text","Copy to Clipboard")
	CALL w.setAttribute("name","copyabout")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY",y)
	CALL w.setAttribute("text","Show Env")
	CALL w.setAttribute("name","showenv")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY",y)
	CALL w.setAttribute("text","Show License")
	CALL w.setAttribute("name","showlicence")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY",y)
	CALL w.setAttribute("text","ReadMe")
	CALL w.setAttribute("name","showreadme")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY",y)
	CALL w.setAttribute("text","Close")
	CALL w.setAttribute("name","closeabout")
	LET w = g.createChild("SpacerItem")

	LET nl = f.selectByTagName("Label")
	FOR y = 1 TO nl.getLength()
		LET w = nl.item( y )
		LET txt = w.getAttribute("text")
		IF txt IS NULL THEN LET txt = "(null)" END IF
		LET info = info.append( txt )
		IF NOT y MOD 2 THEN
			LET info = info.append( "\n" )
		END IF
		--DISPLAY info
	END FOR

	MENU "Options"
		ON ACTION close	EXIT MENU
		ON ACTION closeabout	EXIT MENU
		ON ACTION showenv CALL gl_showEnv()
		ON ACTION showreadme CALL gl_showReadMe()
		ON ACTION copyabout 
			CALL ui.interface.frontCall("standard","cbset",info,y )
		ON ACTION showlicence
			CALL gl_showlicence()
	END MENU
	CLOSE WINDOW about

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Format revision string
#+
#+ @param ver = String : a cvs revisions string ie : $Revision: 344 $
#+ @return String.
FUNCTION gl_verFmt( ver ) --{{{
	DEFINE ver STRING
	DEFINE x SMALLINT

	LET x = ver.getIndexOf(":",1)

	RETURN ver.subString(X+2, ver.getLength() - 1 )
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Get FrontEnd type and Version String.
#+
#+ @return String.
FUNCTION gl_feVer() --{{{

	RETURN ui.interface.getFrontEndName()||" "||ui.interface.getFrontEndVersion()
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Show the Genero & GRE license
#+
FUNCTION gl_showLicence( ) --{{{
	DEFINE licstring STRING
	DEFINE winnode, frm, g, frmf, txte om.DomNode
	DEFINE c base.Channel

	OPEN WINDOW lic WITH 1 ROWS, 1 COLUMNS
	LET winnode = gl_getWinNode(NULL)
	CALL winnode.setAttribute("style","naked")
	CALL winnode.setAttribute("width",80)
	CALL winnode.setAttribute("height",20)
	CALL winnode.setAttribute("text","Licence Info")
	LET frm = gl_genForm("help")

	LET g = frm.createChild('Grid')
	CALL g.setAttribute("width",80)
	CALL g.setAttribute("height",20)

	LET frmf = g.createChild('FormField')
	CALL frmf.setAttribute("colName","licstring")
	LET txte = frmf.createChild('TextEdit')
	CALL txte.setAttribute("gridWidth",80)
	CALL txte.setAttribute("gridHeight",20)

	CALL ui.interface.refresh()

	LET c = base.Channel.create()
	CALL c.openPipe("fglWrt -a info 2>&1","r")
	DISPLAY "Status:",STATUS
	LET licString = "fglWrt -a info:\n"
	WHILE NOT c.isEof()
		LET licstring = licstring.append( c.readLine()||"\n" )
	END WHILE
	CALL c.close()

	CALL c.openPipe("greWrt -a info 2>&1","r")
	LET licString = licString.append("\n\ngreWrt -a info:\n")
	WHILE NOT c.isEof()
		LET licstring = licstring.append( c.readLine()||"\n" )
	END WHILE
	CALL c.close()

	DISPLAY "Lic:",licstring.trim()
	DISPLAY BY NAME licstring

	MENU COMMAND "close" EXIT MENU COMMAND "cancel" EXIT MENU END MENU

	CLOSE WINDOW lic
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Help Window -- NOT WRITTEN YET!!
#+
#+ @param msgno No of help message to display.
#+ @return Nothing.
FUNCTION gl_help( msgno ) --{{{
	DEFINE msgno SMALLINT
	DEFINE helptext CHAR(500)
	DEFINE helpstring STRING
	DEFINE winnode, frm, g, frmf, txte om.DomNode

-- NOTE: this is Informix Specific!!
	WHENEVER ERROR CONTINUE
	SELECT COUNT(*) FROM helptexts
	IF STATUS != 0 THEN
		CREATE TABLE helptexts (
			message_no SERIAL,
			help_text CHAR(500)
		)
	END IF
	WHENEVER ERROR STOP

	SELECT help_text INTO helptext FROM helptexts WHERE message_no = msgno
	IF STATUS = NOTFOUND THEN
		CALL gl_winMessage("Help","Sorry, help message "||msgno||" not found.","info")
		RETURN
	END IF

	OPEN WINDOW help WITH 1 ROWS, 1 COLUMNS
	LET winnode = gl_getWinNode(NULL)
	CALL winnode.setAttribute("style","naked")
	CALL winnode.setAttribute("width",80)
	CALL winnode.setAttribute("height",20)
	CALL winnode.setAttribute("text","Help Message - "||msgno)
	LET frm = gl_genForm("help")

	LET g = frm.createChild('Grid')
	CALL g.setAttribute("width",80)
	CALL g.setAttribute("height",20)

	LET frmf = g.createChild('FormField')
	CALL frmf.setAttribute("colName","helpstring")
	LET txte = frmf.createChild('TextEdit')
	CALL txte.setAttribute("gridWidth",80)
	CALL txte.setAttribute("gridHeight",20)

	CALL ui.interface.refresh()

	LET helpstring = helptext CLIPPED
	DISPLAY "Help:",helpstring.trim()
	DISPLAY BY NAME helpstring

	MENU COMMAND "close" EXIT MENU END MENU

	CLOSE WINDOW help

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Help Window - Display help message from URL
#+ Needs the style to exist:
#+ @code   <Style name="Image.browser">
#+ @code    <StyleAttribute name="imageContainerType" value="browser" />
#+ @code  </Style>
#+
#+ @param url url to display.
#+ @return Nothing.
FUNCTION gl_helpURL( url ) --{{{
	DEFINE url STRING
	DEFINE winnode, frm, g, frmf, txte om.DomNode

	OPEN WINDOW help WITH 1 ROWS, 1 COLUMNS
	LET winnode = gl_getWinNode(NULL)
	CALL winnode.setAttribute("style","naked")
	CALL winnode.setAttribute("width",80)
	CALL winnode.setAttribute("height",20)
	CALL winnode.setAttribute("text","Help Message - "||url)
	LET frm = gl_genForm("help")

	LET g = frm.createChild('Grid')
	CALL g.setAttribute("width",80)
	CALL g.setAttribute("height",20)

	LET frmf = g.createChild('FormField')
	CALL frmf.setAttribute("colName","url")
	LET txte = frmf.createChild('Image')
	CALL txte.setAttribute("gridWidth",80)
	CALL txte.setAttribute("gridHeight",20)
	CALL txte.setAttribute("style","browser")
	CALL ui.interface.refresh()

	DISPLAY BY NAME url

	MENU COMMAND "close" EXIT MENU END MENU

	CLOSE WINDOW help

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ A Simple Prompt function
#+
#+ @code LET tmp = gl_prompt("A Simple Prompt","Enter a value","C",5,NULL)
#+
#+ @param win_tit Window Title
#+ @param prmpt_txt Label text
#+ @param prmpt_typ Data type for prompt C=char D=date
#+ @param prmpt_sz Size of field for entry.
#+ @param prmpt_def Default value ( can be NULL )
#+ @return Char(50): Entered value.
FUNCTION gl_prompt(win_tit, prmpt_txt, prmpt_typ, prmpt_sz, prmpt_def) --{{{
	DEFINE win_tit, prmpt_txt,prmpt_def STRING
	DEFINE prmpt_typ CHAR(1)
	DEFINE prmpt_sz SMALLINT
	DEFINE frm,g om.DomNode
	DEFINE fldnam,wgt STRING
	DEFINE tmp CHAR(50)
	DEFINE tmp_date DATE

-- setup field name
	CASE prmpt_typ
		WHEN "D"
			LET tmp_date = prmpt_def
			LET fldnam = "tmp_date"
		OTHERWISE
			LET tmp = prmpt_def
			LET fldnam = "tmp"
	END CASE

	OPEN WINDOW myprompt WITH 1 ROWS,1 COLUMNS ATTRIBUTES(TEXT=win_tit, STYLE="dialog")

-- Get window object and create a form
	LET frm = gl_genForm("myprompt")

-- create the grid, label, formfield and edit/dateedit nodes.
	LET g = frm.createChild('Grid')
	CALL g.setAttribute("height","4")
	CALL g.setAttribute("width","50")
	IF prmpt_typ = "D" THEN
		LET wgt = "DateEdit"
	ELSE
		LET wgt = "Edit"
	END IF
	CALL gl_addLabel(g, 1,2,prmpt_txt,NULL,NULL)
	CALL gl_addField(g,20,2,wgt,fldnam,prmpt_sz,NULL,NULL,NULL)

-- do the input.
	CASE prmpt_typ
		WHEN "D"
			INPUT BY NAME tmp_date WITHOUT DEFAULTS
			LET tmp = tmp_date
		OTHERWISE
			INPUT BY NAME tmp WITHOUT DEFAULTS
	END CASE
	IF int_flag THEN LET tmp = NULL END IF

	CLOSE WINDOW myprompt
	RETURN tmp

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Generic Window notify message.
#+
#+ @param msg   = String: Message text
#+ @return none
FUNCTION gl_notify(msg) --{{{
	DEFINE msg STRING
	DEFINE frm,g om.domNode
	
	IF msg IS NULL THEN
		CLOSE WINDOW notify
		RETURN
	ELSE
		OPEN WINDOW notify AT 1,1 WITH 1 ROWS, 2 COLUMNS ATTRIBUTES(STYLE="naked")
	END IF

	LET frm = gl_genForm("myprompt")

-- create the grid, label, formfield and edit/dateedit nodes.
	LET g = frm.createChild('Grid')
	CALL g.setAttribute("height","4")
	CALL g.setAttribute("width",msg.getLength() + 1)
	CALL g.setAttribute("gridWidth",msg.getLength() + 1)
	CALL gl_addLabel(g, 1,2,msg,NULL,"big")
	GL_DBGMSG(1, "gl_notify"||msg)
	CALL ui.interface.refresh()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Generic message in statusbar.
#+
#+ @param l_mess   = String: Message text
#+ @return none
FUNCTION gl_message(l_mess) --{{{
	DEFINE l_mess STRING

	MESSAGE l_mess.trim()
	CALL ui.interface.refresh()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Generic Windows message Dialog.  NOTE: This handles messages when there is no window!
#+
#+ @param title     = String: Window Title
#+ @param message   = String: Message text
#+ @param icon      = String: Icon name, "exclamation"
#+ @return none
FUNCTION gl_winMessage(title, message, icon) --{{{
	DEFINE title, message, icon STRING
	DEFINE w ui.window
	
	LET w = ui.window.getcurrent()
	IF w IS NULL THEN -- Needs a current window or dialog doesn't work!!
		OPEN WINDOW dummy AT 1,1 WITH 1 ROWS, 1 COLUMNS
	END IF
	IF icon = "exclamation" THEN ERROR "" END IF -- Beep
--	CALL fgl_winMessage(title, message, icon)
	MENU title ATTRIBUTES(STYLE="dialog",COMMENT=message, IMAGE=icon)
		COMMAND "Okay" EXIT MENU
	END MENU

	IF w IS NULL THEN
		CLOSE WINDOW dummy
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Generic Windows Question Dialog
#+
#+ @param title Window Title
#+ @param message Message text
#+ @param ans   Default Answer
#+ @param items List of Answers ie "Yes|No|Cancel"
#+ @param icon  Icon name, "exclamation"
#+ @return string: Entered value.
FUNCTION gl_winQuestion(title,message,ans,items,icon) --{{{
	DEFINE title,message,ans,items,icon STRING
	DEFINE l_result STRING
	DEFINE l_toks base.STRINGTOKENIZER
	DEFINE l_dum BOOLEAN
	DEFINE l_opt DYNAMIC ARRAY OF STRING
	DEFINE x SMALLINT

	LET icon=icon.trim()
	LET title=title.trim()
	LET message=message.trim()
	LET icon=icon.trim()
	IF icon = "info" THEN LET icon = "information" END IF

	LET l_toks = base.StringTokenizer.create(items,"|")
	IF NOT l_toks.hasMoreTokens() THEN RETURN NULL END IF
	WHILE l_toks.hasMoreTokens()
		LET l_opt[ l_opt.getLength() + 1 ] = l_toks.nextToken()
	END WHILE

	-- Handle the case when there is no current window
	LET l_dum = FALSE
	IF ui.window.getCurrent() IS NULL THEN
		OPEN WINDOW dummy AT 1,1 WITH 1 ROWS, 2 COLUMNS ATTRIBUTE(STYLE="naked")
		CALL fgl_settitle(title)
		LET l_dum = TRUE
	END IF

	MENU title ATTRIBUTE(STYLE="dialog", COMMENT=message, IMAGE=icon)
		BEFORE MENU
			HIDE OPTION ALL
			FOR x = 1 TO l_opt.getLength()
				IF l_opt[x] IS NOT NULL THEN
					SHOW OPTION l_opt[x]
					IF ans.equalsIgnoreCase(l_opt[x]) THEN
						NEXT OPTION l_opt[x]
					END IF
				END IF
			END FOR
		COMMAND l_opt[1]	LET l_result = l_opt[1]
		COMMAND l_opt[2]	LET l_result = l_opt[2]
		COMMAND l_opt[3]	LET l_result = l_opt[3]
		COMMAND l_opt[4]	LET l_result = l_opt[4]
		COMMAND l_opt[5]	LET l_result = l_opt[5]
		COMMAND l_opt[6]	LET l_result = l_opt[6]
		COMMAND l_opt[7]	LET l_result = l_opt[7]
		COMMAND l_opt[8]	LET l_result = l_opt[8]
		COMMAND l_opt[9]	LET l_result = l_opt[9]
		COMMAND l_opt[10]	LET l_result = l_opt[10]
	END MENU
	IF l_dum THEN CLOSE WINDOW dummy END IF
	RETURN l_result
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Progressbar Routine.
#+
#+ @code 
#+ CALL gl_progBar(1,10,"Working...")   Open window and set max = 10
#+ FOR x = 1 TO 10
#+ 	CALL gl_progBar(2,x,NULL)  Move the bar to x position
#+ END FOR
#+ CALL gl_progBar(3,0,NULL)   Close the window
#+
#+ @param meth 1=Open Window / 2=Update bar / 3=Close Window
#+ @param curval 1=Max value for Bar / 2=Current value position for Bar / 3=Ignored.
#+ @param txt Text display below the bar in the window.
#+ @return Nothing.
FUNCTION gl_progBar(meth,curval,txt) --{{{

	DEFINE meth INTEGER
	DEFINE curval INTEGER
	DEFINE txt STRING
	DEFINE winnode, frm, g, frmf, pbar om.DomNode

	IF meth = 1 OR meth = 0 THEN
		OPEN WINDOW progbar WITH 1 ROWS, 50 COLUMNS
		LET winnode = gl_getWinNode(NULL)
		CALL winnode.setAttribute("style","naked")
		CALL winnode.setAttribute("width",45)
		CALL winnode.setAttribute("height",2)
		CALL winnode.setAttribute("text",txt)
		LET frm = gl_genForm("gl_progbar")
		CALL frm.setAttribute("text","ProgressBar")

		LET g = frm.createChild('Grid')

		LET frmf = g.createChild('FormField')
		CALL frmf.setAttribute("colName","progress")
		CALL frmf.setAttribute("value",0)
		LET pbar = frmf.createChild('ProgressBar')
		CALL pbar.setAttribute("width",40)
		CALL pbar.setAttribute("posY",1)
		CALL pbar.setAttribute("valueMax",curval)
		CALL pbar.setAttribute("valueMin",1)

		CALL gl_addLabel(g, 0,2,txt,NULL,NULL)
		IF meth = 0 THEN
			LET g = g.createChild('HBox')
			CALL g.setAttribute("posY",3)
			LET frmf = g.createChild('SpacerItem')
			LET frmf = g.createChild('Button')
			CALL frmf.setAttribute("name","cancel")
			LET frmf = g.createChild('SpacerItem')
		END IF
	END IF

	IF meth = 2 THEN
		DISPLAY curval TO progress
	END IF

	IF meth = 3 THEN
		CLOSE WINDOW progbar
	END IF

	CALL ui.interface.refresh()

END FUNCTION --}}}
#+ Test to see an action exists at this point in time.
#+
#+ @param nam = Action name
#+ @return true/false.
FUNCTION gl_actionExists( nam ) --{{{
	DEFINE nam STRING
	DEFINE w ui.Window
	DEFINE wn, dn om.domNode
	DEFINE dl om.nodeList
	DEFINE nl om.nodeList
	DEFINE x SMALLINT

	LET w = ui.window.getCurrent()
	LET wn = w.getNode()

	LET dl = wn.selectByPath("//Dialog[@active=\"1\"]")	
	FOR x = 1 TO dl.getLength()
		LET dn = dl.item(x)
		LET nl = dn.selectByPath("//Action[@name=\""||nam.trim()||"\"]")	
		IF nl.getLength() > 0 THEN RETURN TRUE END IF
	END FOR
	LET dl = wn.selectByPath("//Menu[@active=\"1\"]")	
	FOR x = 1 TO dl.getLength()
		LET dn = dl.item(x)
		LET nl = dn.selectByPath("//MenuAction[@name=\""||nam.trim()||"\"]")	
		IF nl.getLength() > 0 THEN RETURN TRUE END IF
	END FOR
	RETURN FALSE
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dynamically define a live actions properties.
#+
#+ @code 
#+	BEFORE INPUT
#+ 		CALL add_action("D","special","Special","A Special Action","wizard", "F9")
#+
#+ @param typ = CHAR(1): D=dialog / M=MenuAction.
#+ @param nam = String: Name of Action.
#+ @param txt = String: Text for Action - If NULL then action view is hidden - if '*' unhidden.
#+ @param com = String: Comment/Tooltip for Action.
#+ @param img = String: Image for Action.
#+ @param acc = String: acceleratorName.
#+ @return Nothing.
FUNCTION gl_defAction( typ, nam, txt, com, img, acc ) --{{{
	DEFINE typ CHAR(1)
	DEFINE nam, txt, com, img, acc STRING
	DEFINE ret SMALLINT

	IF typ = "D" THEN
		CALL gl_setAttr("Action", nam.trim(), txt.trim(), com.trim(), img.trim(), acc.trim() ) RETURNING ret
	ELSE
		CALL gl_setAttr("MenuAction", nam.trim(), txt.trim(), com.trim(), img.trim(), acc.trim() ) RETURNING ret
	END IF
	IF NOT ret THEN
		GL_DBGMSG(1, "gl_defAction: failed to find '"||nam.trim()||"'!")
	END IF

	CALL gl_setAttr("ToolBarItem", nam.trim(), txt.trim(), com.trim(), img.trim(), NULL ) RETURNING ret
	CALL gl_setAttr("TopMenuCommand", nam.trim(), txt.trim(), com.trim(), img.trim(), NULL ) RETURNING ret
	CALL gl_setAttr("Button", nam.trim(), txt.trim(), com.trim(), img.trim(), NULL ) RETURNING ret

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Set Attributes for a node.
#+
#+ @param typ ToolBarItem / TopMenuCommand / Button / MenuAction / Action
#+ @param nam Name of Action.
#+ @param txt Text for Action - If NULL then action view is hidden - if '*' unhidden.
#+ @param com Comment/Tooltip for Action.
#+ @param img Image for Action.
#+ @param acc acceleratorName.
#+ @return Number of nodes changes.
FUNCTION gl_setAttr( typ, nam, txt, com, img, acc ) --{{{
	DEFINE typ ,nam, txt, com, img, acc STRING
	DEFINE r,n om.DomNode
	DEFINE nl om.nodeList
	DEFINE x SMALLINT

	LET r = ui.interface.getRootNode()
	LET nl = r.selectByPath("//"||typ||"[@name=\""||nam||"\"]")
	IF nl.getLength() < 1 THEN
		GL_DBGMSG(1, "gl_setAttr: not found "||typ||" '"||nam.trim()||"'!")
		RETURN 0
	END IF
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		GL_DBGMSG(1, "gl_setAttr: found "||typ||" '"||nam.trim()||"'")
		IF txt.trim() IS NULL OR txt = " " THEN
			CALL n.setAttribute("hidden",1)
		ELSE
			IF txt.trim() = "*" THEN
				CALL n.setAttribute("hidden",0)
			ELSE
				CALL n.setAttribute("hidden",0)
				CALL n.setAttribute("text",txt)
			END IF
			IF com IS NOT NULL THEN
				CALL n.setAttribute("comment",com)
			END IF
			IF img IS NOT NULL THEN
				CALL n.setAttribute("image",img)
			END IF
		END IF
		IF acc IS NOT NULL THEN
			CALL n.setAttribute("acceleratorName",acc)
		END IF
	END FOR
	RETURN nl.getLength()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Find a Node and set an attribute to a value.
#+
#+ @param par       = Parent Node Tag
#+ @param par_nam   = Parent Node Name
#+ @param child     = Child Node Tag
#+ @param child_nam = Child Node Name
#+ @param attr      = Attribute to set
#+ @param val       = Value to set attribute to
FUNCTION gl_setNodeAtt( par, par_nam, child, child_nam, attr, val ) --{{{
	DEFINE par, par_nam, child, child_nam, attr, val STRING
	DEFINE nl om.NodeList
	DEFINE ui_r, n om.domNode

	LET ui_r = ui.interface.getRootNode()
	LET nl = ui_r.selectByPath("//"||par.trim()||"[@name=\""||par_nam.trim()||"\"]")
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
	ELSE
		GL_DBGMSG(1, "gl_setNodeAtt: failed to find parent '"||par.trim()||"' with name '"||par_nam.trim()||"'!")
	END IF
	IF child IS NOT NULL THEN
		LET nl = n.selectByPath("//"||child||"[@name=\""||child_nam.trim()||"\"]")
		LET n = NULL
		IF nl.getLength() > 0 THEN
			LET n = nl.item(1)
		ELSE
			GL_DBGMSG(1, "gl_setNodeAtt: failed to find child'"||child.trim()||"' with name '"||child_nam.trim()||"'!")
		END IF
	END IF

	IF n IS NOT NULL THEN
		CALL n.setAttribute( attr, val )
	END IF
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Set the min and max values for a progress bar.
#+
#+ @param fld = String: tag property on the ProgressBar element.
#+ @param mn  = Integer: Min value
#+ @param mx  = Integer: Max value
#+ @return Nothing.
FUNCTION gl_setProgMinMax( fld, mn, mx ) --{{{
	DEFINE fld STRING
	DEFINE mn, mx INTEGER
	DEFINE nl om.nodeList
	DEFINE n om.DomNode

	LET n = gl_getWinNode( NULL )
	LET nl = n.selectByPath("//ProgressBar[@tag=\""||fld.trim()||"\"]")
	IF nl.getLength() > 0 THEN
		LET n = nl.item(1)
		CALL n.setAttribute("valueMax",mx)
		CALL n.setAttribute("valueMin",mn)
	ELSE
		GL_DBGMSG(1, "gl_setProgMinMax: failed to find '"||fld.trim()||"'!")
	END IF
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Default error handler
#+
#+ @return Nothing.
FUNCTION gl_error() --{{{

  DEFINE l_err,l_mod STRING
  DEFINE l_stat INTEGER
  DEFINE x,y SMALLINT

  LET l_stat = STATUS

  LET l_mod = base.Application.getStackTrace()
  LET x = l_mod.getIndexOf("#",2) + 3
  LET y = l_mod.getIndexOf("#",x+1) - 1
  LET l_mod = l_mod.subString(x,y)
  IF y < 1 THEN LET y = l_mod.getLength() END IF
  LET l_mod = l_mod.subString(x,y)
  IF l_mod IS NULL THEN LET l_mod = "(null)" END IF

  LET l_err = SQLERRMESSAGE
  IF l_err IS NULL THEN LET l_err = ERR_GET(l_stat) END IF
  IF l_err IS NULL THEN LET l_err = "Unknown!" END IF
  LET l_err = l_stat||":"||l_err||"\n"||l_mod
--  CALL gl_logIt("Error:"||l_err)
  CALL gl_winMessage("Error",l_err,"exclamation")


END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Display an error message in a window, console & logfile.
#+
#+ @param fil __FILE__ - File name
#+ @param lno __LINE__ - Line Number
#+ @param err Error Message.
#+ @return Nothing.
FUNCTION gl_errMsg(fil, lno, err) --{{{
	DEFINE fil STRING
	DEFINE lno INTEGER
	DEFINE err STRING

	CALL gl_winMessage(%"Error!", err, "exclamation")
	ERROR "* ",err.trim()," *"
	IF fil IS NOT NULL THEN
		DISPLAY fil.trim(),":",lno,": ",err.trim()
		CALL errorlog(fil.trim()||":"||lno||": "||err)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Display debug messages to console.
#+
#+ @param fil __FILE__ - File name
#+ @param lno __LINE__ - Line Number
#+ @param lev Level of debug
#+ @param msg Message
#+ @return Nothing.
FUNCTION gl_dbgMsg(fil, lno, lev, msg) --{{{
	DEFINE fil STRING
	DEFINE lno INTEGER
	DEFINE msg STRING
	DEFINE lev STRING
	DEFINE lin CHAR(22)
	DEFINE x SMALLINT

	IF g_dbgLev = 0 AND lev = 0 THEN
		DISPLAY gl_progname CLIPPED,":",msg.trim()
	ELSE
		IF g_dbgLev >= lev THEN
&ifndef genero13x
			LET fil = os.path.basename( fil )
&endif
			LET x = fil.getIndexOf(".",1)
			LET fil = fil.subString(1,x-1)
			LET lin = "...............:",lno USING "##,###"
			LET x = fil.getLength()
			IF x > 22 THEN LET x = 22 END IF
			LET lin[1,x] = fil.trim()
			DISPLAY lin,":",lev USING "<<&",": ",msg.trim()
			CALL ERRORLOG(lin||":"||(lev USING "<<&")||": "||msg.trim())
		END IF
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Change dialog type - HACK!!
#+
#+ @param l_tag = String: tag name, ie Table
#+ @param l_nam = String: name of table
#+ @param l_typ = String: type, ie inputArray, displayArray
#+ @return None.
FUNCTION gl_chgDialogType( l_tag, l_nam, l_typ ) --{{{
	DEFINE l_tag, l_nam, l_typ STRING
	DEFINE l_n om.domNode
	DEFINE l_nl om.nodeList

	LET l_n = gl_getFormN( NULL )
	IF l_n IS NULL THEN RETURN END IF -- Panic!

	LET l_nl = l_n.selectByPath("//"||l_tag||"[@name='"||l_nam||"']")
	IF l_nl.getLength() > 0 THEN	
		LET l_n = l_nl.item(1)
		CALL l_n.setAttribute("dialogType",l_typ)
	ELSE
		CALL gl_errMsg(__FILE__,__LINE__,"gl_chgDialogType: Didn't find "||l_tag||" name of '"||l_nam||"'")
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Populate the named combobox,
#+
#+ @param nam The name of the combobox.
#+ @param val The Value to add - NULL=clear combo ASK!=allow editting of values
#+ @param txt Text value for the item.
#+ @param win Open window you use gl_lookup2 ( not included with dbquery )
#+ @return True / False: Worked / Failed
FUNCTION gl_popCombo(nam, val, txt, win) --{{{
	DEFINE nam,txt,val STRING
	DEFINE win SMALLINT
	DEFINE cb ui.ComboBox
	DEFINE hb,wfrm,frm,g,ff,w,tabl,tabc om.DomNode
	DEFINE x,val_w,txt_w SMALLINT
	DEFINE org,arr DYNAMIC ARRAY OF RECORD
		txt STRING,
		val STRING
	END RECORD

	LET cb = ui.ComboBox.forName(nam)
	IF cb IS NULL THEN
		CALL gl_errMsg(__FILE__,__LINE__,"Failed to find combobox '"||nam||"'!")
		RETURN FALSE
	END IF
	IF val IS NULL THEN
		CALL cb.clear()
		RETURN TRUE
	END IF

	LET int_flag = FALSE
	IF val = "ASK!" THEN
		FOR x = 1 TO cb.getItemCount()
			LET arr[x].val = cb.getItemName(x)
			LET arr[x].txt = cb.getItemText(x)
			LET org[x].val = cb.getItemName(x)
			LET org[x].txt = cb.getItemText(x)
			IF arr[x].val.getLength() > val_w THEN LET val_w = arr[x].val.getLength() END IF
			IF arr[x].val.getLength() > txt_w THEN LET txt_w = arr[x].txt.getLength() END IF
		END FOR
		IF win THEN
			OPEN WINDOW popcombo WITH 1 ROWS,1 COLUMNS ATTRIBUTES(TEXT="New ComboBox Item", STYLE="dialog")
-- Get window object and create a form
			LET wfrm = gl_genForm("popcombo")
		ELSE
&ifdef FULLLIBRARY
			LET wfrm = gl_lookup2_open()
&endif
		END IF
-- create the grid, label, formfield and edit nodes.
		LET frm = wfrm.createChild('VBox')
		LET g = frm.createChild('Grid')
		CALL g.setAttribute("height","4")
		CALL g.setAttribute("width","50")
		CALL gl_addLabel(g, 1,2,"Display Value:",NULL,NULL)
		LET ff = g.createChild('FormField')
		CALL ff.setAttribute("colName","txt")
		LET w = ff.createChild("Edit")
		CALL w.setAttribute("width",20)
		CALL w.setAttribute("posX","20")
		CALL w.setAttribute("posY",2)

		CALL gl_addLabel(g, 1,3,"Return Value:",NULL,NULL)
		LET ff = g.createChild('FormField')
		CALL ff.setAttribute("colName","val")
		LET w = ff.createChild("Edit")
		CALL w.setAttribute("width",20)
		CALL w.setAttribute("posX",20)
		CALL w.setAttribute("posY",3)

		LET hb = frm.createChild('HBox')
		LET g = hb.createChild('Grid')
		LET tabl = g.createChild("Table")
		CALL tabl.setAttribute("tabName","comboarr")
		CALL tabl.setAttribute("height",arr.getLength()+1)
		CALL tabl.setAttribute("pageSize",arr.getLength()+1)
		CALL tabl.setAttribute("posX",1)
		CALL tabl.setAttribute("posY",6)
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName","txt")
		CALL tabc.setAttribute("text","Text")
		LET w = tabc.createChild('Edit')
		CALL w.setAttribute("width",txt_w)
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName","val")
		CALL tabc.setAttribute("text","Value")
		LET w = tabc.createChild('Edit')
		CALL w.setAttribute("width",val_w)

		LET g = hb.createChild('Grid')
		LET w = g.createChild("Button")
		CALL w.setAttribute("posX",10)
		CALL w.setAttribute("posY",7)
		CALL w.setAttribute("name","add")
		CALL w.setAttribute("text","Add")

		LET w = g.createChild("Button")
		CALL w.setAttribute("posX",10)
		CALL w.setAttribute("posY",8)
		CALL w.setAttribute("name","clear")
		CALL w.setAttribute("text","Clear Combobox")

		LET w = g.createChild("Button")
		CALL w.setAttribute("posX",10)
		CALL w.setAttribute("posY",9)
		CALL w.setAttribute("name","closewin")
		CALL w.setAttribute("text","Close Window")

		DISPLAY ARRAY arr TO comboarr.* ATTRIBUTE( COUNT=arr.getLength() )
			BEFORE DISPLAY EXIT DISPLAY
		END DISPLAY
		INPUT BY NAME txt,val ATTRIBUTES(UNBUFFERED)
			BEFORE INPUT
				CALL DIALOG.setActionHidden("cancel",1)
				CALL DIALOG.setActionHidden("accept",1)
				CALL DIALOG.setActionActive("accept",0)
			ON ACTION closewin
				EXIT INPUT
			ON ACTION add
				IF gl_addCombo( cb, val, txt) THEN
					LET arr[ arr.getLength() + 1 ].val = val
					LET arr[ arr.getLength() ].txt = txt
					CALL tabl.setAttribute("height",arr.getLength())
					CALL tabl.setAttribute("pageSize",arr.getLength())
					CALL ui.interface.refresh()
					DISPLAY ARRAY arr TO comboarr.* ATTRIBUTE( COUNT=arr.getLength() )
						BEFORE DISPLAY EXIT DISPLAY
					END DISPLAY
				END IF
			ON ACTION clear
				CALL cb.clear()
				CALL arr.clear()
				DISPLAY ARRAY arr TO comboarr.* ATTRIBUTE( COUNT=arr.getLength() )
					BEFORE DISPLAY EXIT DISPLAY
				END DISPLAY
			AFTER FIELD val
				NEXT FIELD txt
		END INPUT
		IF int_flag THEN -- restore combo.
			CALL cb.clear()
			FOR x = 1 TO org.getLength()
				IF gl_addCombo( cb, org[x].val, org[x].txt) THEN
				-- Shouldn't fail
				END IF
			END FOR
			IF win THEN 
				CLOSE WINDOW popcombo
			ELSE
&ifdef FULLLIBRARY
				CALL gl_lookup2_close(wfrm)
&endif
			END IF
			MESSAGE "Aborted."
			RETURN FALSE
		END IF
		IF win THEN 
			CLOSE WINDOW popcombo
		ELSE
&ifdef FULLLIBRARY
			CALL gl_lookup2_close(wfrm)
&endif
		END IF
	ELSE
		RETURN gl_addCombo(cb, val, txt )
	END IF
	RETURN TRUE

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Populate the named combo box - checks to see if item already exists.
#+
#+ @param cb The Combobox object
#+ @param val The value - ie return value for item.
#+ @param txt The Text - ie display text for the item.
#+ @return True / False: Worked / Failed
FUNCTION gl_addCombo(cb, val, txt) --{{{
	DEFINE txt,val STRING
	DEFINE cb ui.ComboBox
	DEFINE x SMALLINT

	IF cb IS NULL THEN RETURN FALSE END IF
	FOR x = 1 TO cb.getItemCount()
		IF val = cb.getItemName(x) THEN
			ERROR "Value already exists in combobox."
			RETURN FALSE
		END IF
		IF txt = cb.getItemText(x) THEN
			ERROR "Text already exists in combobox."
			RETURN FALSE
		END IF
	END FOR
	CALL cb.addItem( val.trim(), txt.trim() )
	RETURN TRUE

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Set the stlye attribute on an element of current form.
#+
#+ @param ele  = String: Elements name attribute.
#+ @param styl = String: Style to set.
#+ @return Nothing.
FUNCTION gl_setElementStyle( ele, styl ) --{{{
	DEFINE ele, styl STRING
	DEFINE frm ui.Form
	DEFINE n om.DomNode
	DEFINE nl om.NodeList

	LET frm = gl_getForm(NULL)
	LET n = frm.getNode()

	LET nl = n.selectByPath("//*[@name=\""||ele||"\"]")
	IF nl.getLength() < 1 THEN
		CALL gl_errMsg(__FILE__,__LINE__,"Failed to setElementStyle for '"||ele||"'!")
		RETURN
	END IF

	LET n = nl.item(1)
	IF n.getTagName() = "FormField" THEN
		LET n = n.getFirstChild()
	END IF
	CALL n.setAttribute("style",styl)

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Change exec line of a start menu command ( use name="?" in the .4sm )
#+
#+ @param nam Name
#+ @param args New Args
FUNCTION gl_chgArgs(nam, args) --{{{
	DEFINE nam,args,ex STRING
	DEFINE sm om.domNode
	DEFINE nl om.nodeList

	LET sm = ui.interface.getRootNode()

	LET nl = sm.selectByPath("//StartMenuCommand[@name=\""||nam||"\"]")
	IF nl.getLength() < 1 THEN
		CALL gl_errMsg(__FILE__,__LINE__,"Failed to find the item '"||nam||"'!")
		RETURN
	END IF

	LET sm = nl.item(1)
	LET ex = sm.getAttribute("exec")
	CALL sm.setAttribute("exec",ex||" "||args)

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ A generic dynamic lookup table.
#+
#+ @code 
#+  LET key = dyntab( tabnam, tot_recs, colts, ftyp, flen )
#+
#+ @param tabnam screen array name
#+ @param wintitle title for the window and the form.
#+ @param colts columns title up to MAX_COLS ( comma seperated ) can be NULL to use column names
#+ @param ftyp  types of cols D=Date, C=Char, N=Numeric/Decimal, I=Integer can be ?,?,? etc for default of column type from xml sch
#+ @param flen  length of columns ( comma seperated ) If NULL then defaults the sizes
#+ @param tot_recs total number of records.
FUNCTION gl_dyntab( tabnam, wintitle, colts, ftyp, flen, tot_recs ) --{{{
	DEFINE tabnam, wintitle, colts, flen STRING
	DEFINE ftyp CHAR(MAX_COLS)
	DEFINE tot_recs,x,i INTEGER
	DEFINE win, frm, grid, tabl, tabc, edit, curr om.DomNode
	DEFINE hb,sp,titl om.DomNode
	DEFINE col_ar ARRAY[MAX_COLS] OF CHAR(18)
	DEFINE col_cnt SMALLINT
	DEFINE tok base.StringTokenizer
	DEFINE tlen SMALLINT
	DEFINE col_len ARRAY[MAX_COLS] OF SMALLINT

	LET win = gl_getWinNode(NULL)
	LET frm = gl_genForm(NULL)
	CALL win.setAttribute("style","naked")

	CALL win.setAttribute("text",wintitle)
	CALL frm.setAttribute("name",tabnam CLIPPED)

	LET grid = frm.createChild('Grid')

-- Create a centered window title.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","0")
	LET sp = hb.createChild('SpacerItem')
	LET titl = hb.createChild('Label')
	CALL titl.setAttribute("text",wintitle)
	CALL titl.setAttribute("style","tabtitl")
	LET sp = hb.createChild('SpacerItem')

-- Create the table
	LET tabl = grid.createChild('Table')
	CALL tabl.setAttribute("tabName",tabnam)
	CALL tabl.setAttribute("height","20")
	CALL tabl.setAttribute("pageSize","20")
	CALL tabl.setAttribute("size","20")
	CALL tabl.setAttribute("posY","1")

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
	LET col_cnt = x - 1
	IF flen IS NOT NULL THEN
		LET tok = base.StringTokenizer.create( flen, "," )
		LET x = 1
		WHILE tok.hasMoreTokens()
			LET col_len[x] = tok.nextToken()
			LET x = x + 1
			IF x > MAX_COLS THEN EXIT WHILE END IF
		END WHILE
	END IF

-- Create Columns & Headings for the table.
	FOR i = 1 TO col_cnt
		IF ftyp[i] = "C" THEN LET tlen = 30 END IF
		IF ftyp[i] = "I" THEN LET tlen = 10 END IF
		IF ftyp[i] = "N" THEN LET tlen = 12 END IF
		IF ftyp[i] = "D" THEN LET tlen = 10 END IF
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName","f"||i)
		LET edit = tabc.createChild('Edit')
		IF ftyp[i] != "C" AND ftyp[i] != "D" THEN
			CALL edit.setAttribute("justify","right")
		END IF
		CALL tabc.setAttribute("text",col_ar[i])
		IF col_len[i] IS NULL OR col_len[i] = 0 THEN
			CALL edit.setAttribute("width",tlen)
		ELSE
			CALL edit.setAttribute("width",col_len[i])
		END IF
	END FOR

-- Create centered buttons.
	LET hb = grid.createChild('HBox')
	CALL hb.setAttribute("posY","21")
	LET titl = hb.createChild('Label')
	CALL titl.setAttribute("text","Row:")
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
	CALL titl.setAttribute("sizePolicy","dynamic")
	CALL titl.setAttribute("text",tot_recs USING "###,###,##&" ||" Rows")

	RETURN curr

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Generate a Strings file for use with localized strings.
#+
#+ @param nam file name to output to.
FUNCTION gl_genStrs(nam) --{{{
	DEFINE nam STRING
	DEFINE fil base.Channel
	DEFINE add om.DomDocument
	DEFINE r, adl, n, act om.domNode
	DEFINE nl,nl2,nl3 om.nodeList
	DEFINE tg,nm,tx,cm STRING
	DEFINE x,x1,y SMALLINT

	LET fil = base.Channel.create()
	CALL fil.openFile(nam||".str","w")

	GL_DBGMSG(1, "gl_genStrs: Processing ActionDefaults")
	LET r = ui.interface.getRootNode()
	LET add = om.DomDocument.create("ActionDefaultList")
	LET adl = add.getDocumentElement()

	LET nl = r.selectByPath("//ActionDefault")
	FOR x = 1 TO nl.getLength()
		LET act = nl.item(x)
		LET nm = act.getAttribute("name")
		LET tx = act.getAttribute("text")
		LET cm = act.getAttribute("comment")
		IF tx IS NOT NULL THEN CALL fil.writeLine('"action.'||nm||'" = "'||tx||'"') END IF
		IF cm IS NOT NULL THEN CALL fil.writeLine('"comment.'||nm||'" = "'||cm||'"') END IF
		LET n = adl.createChild("ActionDefault")
		FOR y = 1 TO act.getAttributesCount()
			CALL n.setAttribute(act.getAttributeName(y),act.getAttributeValue(y))
		END FOR
		IF tx IS NOT NULL OR cm IS NOT NULL THEN
			LET n = n.createChild("LStr")
			IF tx IS NOT NULL THEN CALL n.setAttribute("text","action."||nm) END IF
			IF cm IS NOT NULL THEN CALL n.setAttribute("comment","comment."||nm) END IF
		END IF
	END FOR
	CALL adl.writeXml(nam||".4ad")

	GL_DBGMSG(1, "gl_genStrs: Processing TopMenus")
	LET nl = r.selectByPath("//TopMenu")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		GL_DBGMSG(1, "gl_genStrs: topmenu "||x)
		LET add = om.DomDocument.createFromXmlFile( n.getAttribute("fileName") )
		IF add IS NULL THEN CONTINUE FOR END IF
		LET adl = add.getDocumentElement()
		LET nl2 = adl.selectByPath("//TopMenuGroup")
		GL_DBGMSG(1, "gl_genStrs: topmenu items "||nl.getLength() )
		FOR x1 = 1 TO nl2.getLength()
			LET act = nl2.item(x1)
			LET nm = act.getAttribute("name")
			LET tx = act.getAttribute("text")
			IF nm IS NOT NULL AND tx IS NOT NULL THEN
				LET n = act.getFirstChild()
				IF n IS NULL THEN
					CALL fil.writeLine('"'||tg.toLowerCase()||'.'||nm||'" = "'||tx||'"')
					LET n = act.createChild("LStr")
					CALL n.setAttribute("text",tg.toLowerCase()||"."||nm)
				END IF
			END IF
		END FOR
		LET nl2 = adl.selectByPath("//TopMenuCommand")
		FOR x1 = 1 TO nl2.getLength()
			LET act = nl2.item(x1)
			LET tx = act.getAttribute("text")
			LET nm = act.getAttribute("name")
			LET nl3 = r.selectByPath("//ActionDefault[@name=\""||nm||"\"]")
			IF nl3.getLength() > 0 THEN
				IF tx IS NOT NULL THEN CALL act.removeAttribute("text") END IF
			ELSE
				GL_DBGMSG(0, "gl_genStrs: WARNING: Action '"||nm||"' not in .4ad")
			END IF
		END FOR
		CALL adl.writeXml("menu"||x||".4tm")
	END FOR

	CALL fil.close()

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @param l_line Line number - should be __LINE__
#+ @param l_mod Module name - should be __FILE__
#+ @param l_stmt = String: The SQL Statement / Message, Can be NULL.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION gl_sqlStatus(l_line, l_mod, l_stmt) --{{{
	DEFINE l_mod, l_stmt STRING
	DEFINE l_line, l_stat INTEGER

	LET l_stat = STATUS
	LET l_mod = l_mod||" Line:",(l_line USING "<<<<<<<")
	IF l_stat = 0 THEN RETURN TRUE END IF
	IF l_stmt IS NULL THEN
		CALL gl_winMessage("Error","Status:"||l_stat||"\nSqlState:"||SQLSTATE||"\n"||SQLERRMESSAGE||"\n"||l_mod,"exclamation")
	ELSE
		CALL gl_winMessage("Error",l_stmt||"\nStatus:"||l_stat||"\nSqlState:"||SQLSTATE||"\n"||SQLERRMESSAGE||"\n"||l_mod,"exclamation")
		GL_DBGMSG(0, "gl_sqlStatus: Stmt         ='"||l_stmt||"'")
	END IF
	GL_DBGMSG(0, "gl_sqlStatus: WHERE        :"||l_mod)
	GL_DBGMSG(0, "gl_sqlStatus: STATUS       :"||l_stat)
	GL_DBGMSG(0, "gl_sqlStatus: SQLSTATE     :"||SQLSTATE)
	GL_DBGMSG(0, "gl_sqlStatus: SQLERRMESSAGE:"||SQLERRMESSAGE)

	RETURN FALSE

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Add a label to a grid/group
#+
#+ @param g Node of the Grid or Group
#+ @param x X position
#+ @param y Y Position
#+ @param txt Text for label
#+ @param j Justify : NULL, center or right
#+ @param s Style.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION gl_addLabel(g,x,y,txt,j,s) --{{{
	DEFINE g,l om.domNode
	DEFINE txt,j,s STRING
	DEFINE x,y SMALLINT

	LET l = g.createChild("Label")
	CALL l.setAttribute("posX",x)
	CALL l.setAttribute("posY",y)
	CALL l.setAttribute("text",txt)
	IF j IS NOT NULL THEN
		CALL l.setAttribute("justify",j)
	END IF
	IF s IS NOT NULL THEN
		CALL l.setAttribute("style",s)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Add a RadioGroup to the 'win' or and 'grid/group' passed
#+
#+ @param l_winnam = String: name of Window - NULL = Current
#+ @param l_grptyp = String: name of group or grid to add to
#+ @param l_grpnam = String: name of field - for input.
#+ @param l_com = String: Comment
#+ @param l_ori = char 1: H or V - "horizontal" or "vertical"
#+ @return Node of radiogroup
FUNCTION gl_newRadio( l_winnam, l_grptyp, l_grpnam, l_nam, l_com, l_ori ) --{{{
	DEFINE l_winnam, l_grptyp, l_grpnam, l_nam, l_com STRING
	DEFINE l_ori CHAR(1)
	DEFINE l_frm ui.Form
	DEFINE l_grp,l_ff,l_rad om.domNode
	DEFINE l_h SMALLINT

	LET l_frm = gl_getForm( l_winnam )
	LET l_grp = l_frm.findNode(l_grptyp,l_grpnam)
	IF l_grp IS NULL THEN
		CALL gl_errMsg(__FILE__,__LINE__,"Failed to find "||l_grptyp||" of name '"||l_grpnam||"'!")
		RETURN NULL
	END IF
	LET l_h = l_grp.getAttribute("gridHeight")
	IF l_h IS NULL THEN LET l_h = l_grp.getAttribute("height") END IF

	LET l_ff = l_grp.createChild("FormField")
	CALL l_ff.setAttribute("name","formonly."||l_nam)
	CALL l_ff.setAttribute("colName",l_nam)
	LET l_rad = l_ff.createChild("RadioGroup")
	CASE l_ori
		WHEN "H" CALL l_rad.setAttribute("orientation","horizontal")
		WHEN "V" CALL l_rad.setAttribute("orientation","vertical")
	END CASE
	CALL l_rad.setAttribute("posX","1")
	IF l_h IS NOT NULL THEN
		CALL l_rad.setAttribute("posY",l_h)
	END IF
	IF l_com IS NOT NULL THEN CALL l_rad.setAttribute("comment",l_com) END IF
	
	RETURN l_rad

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Repopulate a radio group item list.
#+
#+ @code gl_popRadio("formonly.print_dest","1|2|3|4","File|Screen|PDF|Print")
#+ @param fnam form name e.g. formonly.print_dest
#+ @param namval name attributes, pipe delimited.
#+ @param txtval text attributes, pipe delimited.
FUNCTION gl_popRadio(fnam,namval,txtval)
	DEFINE fnam, namval, txtval STRING
	DEFINE st,st1 base.StringTokenizer
	DEFINE w ui.Window
	DEFINE n ,n1 om.DomNode
	
	LET w = ui.Window.getCurrent()
	LET n1 = w.findNode("FormField",fnam)
	IF n1 IS NULL THEN
		CALL gl_winMessage("Error","gl_popRadio: Failed to find '"||fnam||"'","exclamation")
		RETURN
	END IF
	LET n = n1.getFirstChild() -- Get the RadioGroup widget.
	IF n.getTagName() != "RadioGroup" THEN
		CALL gl_winMessage("Error","gl_popRadio: '"||fnam||"' is not a RadioGroup","exclamation")
		RETURN
	END IF

-- Remove current Item list
	LET n1 = n.getFirstChild() -- get Item
	WHILE n1 IS NOT NULL
		CALL n.removeChild(n1)
		LET n1 = n.getFirstChild() -- get Item
	END WHILE

-- Create the new list of Items.
	LET st = base.StringTokenizer.create(namval,"|")
	LET st1 = base.StringTokenizer.create(txtval,"|")
	WHILE st.hasMoreTokens()
		LET n1 = n.createChild("Item")
		CALL n1.setAttribute("name",st.nextToken() )
		CALL n1.setAttribute("text",st1.nextToken() )
	END WHILE
	
END FUNCTION
----------------------------------------------------------------------------------
#+ Add items to a RadioGroup
#+
#+ @param l_rad RadioGroup node.
#+ @param l_val value
#+ @param l_txt Text
#+ @return Node of radiogroup
FUNCTION gl_addRadioItem( l_rad , l_val, l_txt ) --{{{
	DEFINE l_rad, l_itm om.domNode	
	DEFINE l_val, l_txt STRING
	
	LET l_itm = l_rad.createChild("Item")
	CALL l_itm.setAttribute("name",l_val)
	CALL l_itm.setAttribute("text",l_txt)

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Add a label to a grid/group with a name
#+
#+ @param g Node of the Grid or Group
#+ @param x X position
#+ @param y Y position
#+ @param txt Text for label
#+ @param nam Name for label.
#+ @param j Justify : NULL, center or right
#+ @param s Style.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION gl_addLabelN(g,x,y,txt,nam,j,s) --{{{
	DEFINE g,l om.domNode
	DEFINE txt,nam,j,s STRING
	DEFINE x,y SMALLINT

	LET l = g.createChild("Label")
	CALL l.setAttribute("posX",x)
	CALL l.setAttribute("posY",y)
	CALL l.setAttribute("text",txt)
	IF nam IS NOT NULL THEN
		CALL l.setAttribute("name",nam)
	END IF
	IF j IS NOT NULL THEN
		CALL l.setAttribute("justify",j)
	END IF
	IF s IS NOT NULL THEN
		CALL l.setAttribute("style",s)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Add a label to a grid/group
#+
#+ @param g Node of the Grid or Group
#+ @param x X position
#+ @param y Y Position
#+ @param wgt Widget: Edit, ButtonEdit, ComboBox, DateEdit
#+ @param fld Text for label
#+ @param w Width
#+ @param com NULL or Comment
#+ @param j Justify : NULL, center or right
#+ @param s Style.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION gl_addField(g,x,y,wgt,fld,w,com,j,s) --{{{
	DEFINE g,f,n om.domNode
	DEFINE wgt, fld, com, j, s STRING
	DEFINE x,y,w,h SMALLINT

	LET f = g.createChild("FormField")
	CALL f.setAttribute("name",fld)
	CALL f.setAttribute("colName",fld)
	LET n = f.createChild(wgt)
	CALL n.setAttribute("posX",x)
	CALL n.setAttribute("posY",y)
	IF w > 80 THEN 
		LET h = w / 80 
		LET w = 80
		CALL n.setAttribute("height",h)
	END IF
	CALL n.setAttribute("width",w)
	IF com IS NOT NULL THEN
		CALL n.setAttribute("comment",com)
	END IF
	IF j IS NOT NULL THEN
		CALL n.setAttribute("justify",j)
	END IF
	IF s IS NOT NULL THEN
		CALL n.setAttribute("style",s)
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Add defaults colours and fonts to stylelist
#+
#+ uses ../etc/colours.txt
FUNCTION gl_addStyles(  ) --{{{
	DEFINE c Base.Channel
	DEFINE fname STRING
	DEFINE ret, x SMALLINT
	DEFINE colours DYNAMIC ARRAY OF RECORD
			def CHAR(1),
			colName STRING,
			colCode STRING,	
			colDesc STRING
		END RECORD
	DEFINE colourFile BOOLEAN

	LET c = base.Channel.create()
	LET fname = ".."||os.path.separator()||"etc"||os.path.separator()||"colours.txt"
	IF NOT os.path.exists(fname) THEN
		LET fname = "."||os.path.separator()||"etc"||os.path.separator()||"colours.txt"
	END IF
	TRY
		CALL c.openFile(fname,"r")
		LET colourFile = TRUE
	CATCH
		LET colourFile = FALSE
--		CALL gl_winMessage("Error","Failed to open 'colours.txt'","exclamation")
	END TRY

	IF colourFile THEN
		CALL c.setDelimiter("|")
		WHILE NOT c.isEof()
			LET ret = c.read( [colours[ colours.getLength() + 1 ].*] )
			LET x = colours.getLength()
			IF colours[x].colName IS NOT NULL THEN
				IF colours[x].def = 1 THEN
					CALL gl_addStyle2("."||colours[x].colName, "textColor",colours[x].colName)
					CALL gl_addStyle2(".bg_"||colours[x].colName, "backgroundColor",colours[x].colName)
				ELSE
					CALL gl_addStyle2("."||colours[x].colName, "textColor",colours[x].colCode)
					CALL gl_addStyle2(".bg_"||colours[x].colName, "backgroundColor",colours[x].colCode)
				END IF
			END IF
		END WHILE
		CALL c.close()
		GL_DBGMSG(1, "gl_addStyles: Add colours from colours.txt!")
	ELSE
		GL_DBGMSG(0, "gl_addStyles: No colours.txt!")
	END IF

	CALL gl_addStyle2(".defsettigns", "forceDefaultSettings","1")
	CALL gl_addStyle2("Image.browser", "imageContainerType","browser")
	CALL gl_addStyle2(".html", "textFormat","html")
	CALL gl_addStyle2(".noborder", "border","none")
	CALL gl_addStyle2(".bold", "fontWeight","bold")
	CALL gl_addStyle2(".notbold", "fontWeight","normal")
	CALL gl_addStyle2(".fixed", "fontFamily","'Courier New'")
	CALL gl_addStyle2(".font1em", "fontSize","1em")
	CALL gl_addStyle2(".font-1", "fontSize",".9em")
	CALL gl_addStyle2(".font-2", "fontSize",".8em")
	CALL gl_addStyle2(".font-3", "fontSize",".7em")
	CALL gl_addStyle2(".font-4", "fontSize",".6em")
	CALL gl_addStyle2(".font-5", "fontSize",".5em")
	CALL gl_addStyle2(".font-6", "fontSize",".4em")
	CALL gl_addStyle2(".font+1", "fontSize","1.1em")
	CALL gl_addStyle2(".font+2", "fontSize","1.2em")
	CALL gl_addStyle2(".font+3", "fontSize","1.3em")
	CALL gl_addStyle2(".font+4", "fontSize","1.4em")
	CALL gl_addStyle2(".font+5", "fontSize","1.5em")
	CALL gl_addStyle2(".font+6", "fontSize","1.6em")
END FUNCTION --}}}
--------------------------------------------------------------------------------
FUNCTION gl_addStyle2(nam,att,val)
	DEFINE nam, att, val STRING
	DEFINE l_aui, n_s, n_a om.DomNode
	DEFINE nl_s om.NodeList

	IF m_styleList IS NULL THEN
		LET l_aui = ui.interface.getRootNode()
		LET nl_s = l_aui.selectByTagName("StyleList")
		LET m_styleList = nl_s.item(1)
	END IF
	IF m_styleList IS NULL THEN
		CALL gl_winMessage("Error","No StyleList!!!","exclamation")
		RETURN
	END IF

	LET n_s = m_styleList.createChild("Style")
	CALL n_s.setAttribute("name",nam)
	LET n_a = n_s.createChild("StyleAttribute")
	CALL n_a.setAttribute("name",att)
	CALL n_a.setAttribute("value",val)
END FUNCTION
----------------------------------------------------------------------------------
#+ Add a style to stylelist
#+
#+ @param styl Style name.
#+ @return none
FUNCTION gl_addStyle( styl ) --{{{
	DEFINE styl STRING
	DEFINE r,sl,s,sa om.domNode
	DEFINE nl om.nodeList

	CASE styl
		WHEN ".about" IF style_about THEN RETURN END IF
		WHEN "Window.about" IF style_wabout THEN RETURN END IF
		WHEN "Window.splash" IF style_splash THEN RETURN END IF
	END CASE
	LET r = ui.interface.getRootNode()
	LET nl = r.selectByTagName("StyleList")
	IF nl.getLength() > 0 THEN
		LET sl = nl.item(1)
		LET nl = sl.selectByPath("//Style[@name=\""||styl||"\"]")
		IF nl.getLength() > 0 THEN
			LET s = nl.item(1)
		ELSE
			LET s = NULL
		END IF
	ELSE
		LET sl = r.createChild("StyleList")
		LET s = NULL
	END IF
	IF s IS NULL THEN
		LET s = sl.createChild("Style")
		CALL s.setAttribute( "name", styl )
	END IF

	CASE styl
		WHEN ".about"
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","backgroundColor")
			CALL sa.setAttribute( "value", "white")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","border")
			CALL sa.setAttribute( "value", "none")
			LET style_about = TRUE
		WHEN "Window.about"
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","windowType")
			CALL sa.setAttribute( "value", "modal")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","backgroundColor")
			CALL sa.setAttribute( "value", "white")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","border")
			CALL sa.setAttribute( "value", "tool")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","actionPanelPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","ringMenuPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","toolBarPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","startMenuPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","statusBarType")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","position")
			CALL sa.setAttribute( "value", "center")
			LET style_wabout = TRUE
		WHEN "Window.splash"
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","windowType")
			CALL sa.setAttribute( "value", "modal")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","backgroundColor")
			CALL sa.setAttribute( "value", "white")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","border")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","actionPanelPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","startMenuPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","ringMenuPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","toolBarPosition")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","statusBarType")
			CALL sa.setAttribute( "value", "none")
			LET sa = s.createChild("StyleAttribute")
			CALL sa.setAttribute( "name","position")
			CALL sa.setAttribute( "value", "center")
			LET style_splash = TRUE
	END CASE

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Show ReadMe local file
#+
#+ @return none
FUNCTION gl_showReadMe() --{{{
	DEFINE vb,frm,g,ff,t om.DomNode
	DEFINE txt STRING
	DEFINE c base.Channel

	LET c = base.channel.create()
	LET txt = fgl_getEnv("README")
	IF txt IS NULL THEN LET txt = "readme.txt" END IF
	WHENEVER ERROR CONTINUE
	CALL c.openFile(txt,"r")
	IF STATUS != 0 THEN
		CALL gl_winMessage("ReadMe",SFMT(%"No '%1' file found.",txt),"information")
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET txt = "ReadMe.txt:\n"
	WHILE NOT c.isEOF()
		LET txt = txt.append( c.readLine()||"\n" )
	END WHILE
	CALL c.close()

	OPEN WINDOW showRM AT 1,1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTES(STYLE="about")
	LET frm = gl_genForm("showRM")
	CALL gl_titleWin("Read Me")
	LET vb = frm.createChild("VBox")
	LET g = vb.createChild("Grid")
	LET ff = g.createChild("FormField")
	CALL ff.setATtribute("colName","txt")
	LET t = ff.createChild("TextEdit")
	CALL t.setATtribute("scroll","both")
	CALL t.setATtribute("stretch","both")
	CALL t.setATtribute("gridWidth","80")
	CALL t.setATtribute("height","60")

	DISPLAY BY NAME txt
	MENU
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
	END MENU	
	CLOSE WINDOW showRM

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Show Environment variables in a dynamic table.
#+ @return none
FUNCTION gl_showEnv() --{{{
	DEFINE vb,frm,w,tabl,tabc om.DomNode
	DEFINE x,val_w,txt_w SMALLINT
	DEFINE env DYNAMIC ARRAY OF RECORD
		nam STRING,
		val STRING
	END RECORD
--TODO: maybe read list of environment variables from a file?
	LET env[env.getLength()+1].nam = "FGLDIR"
	LET env[env.getLength()+1].nam = "FGLASDIR"
	LET env[env.getLength()+1].nam = "FGLSERVER"
	LET env[env.getLength()+1].nam = "FGLLDPATH"
	LET env[env.getLength()+1].nam = "FGLRESOURCEPATH"
	LET env[env.getLength()+1].nam = "FGLIMAGEPATH"
	LET env[env.getLength()+1].nam = "FGLPROFILE"
	LET env[env.getLength()+1].nam = "FGLRUN"
	LET env[env.getLength()+1].nam = "GREDIR"

	LET env[env.getLength()+1].nam = "FGLDBPATH"
	LET env[env.getLength()+1].nam = "FGLSQLDEBUG"

	LET env[env.getLength()+1].nam = "DBPATH"
	LET env[env.getLength()+1].nam = "DBDATE"
	LET env[env.getLength()+1].nam = "DBCENTURY"

	LET env[env.getLength()+1].nam = "INFORMIXDIR"
	LET env[env.getLength()+1].nam = "INFORMIXSERVER"
	LET env[env.getLength()+1].nam = "INFORMIXSQLHOSTS"

	LET env[env.getLength()+1].nam = "ANTSHOME"
	LET env[env.getLength()+1].nam = "ANTS_DSN"

	LET env[env.getLength()+1].nam = "PATH"
	LET env[env.getLength()+1].nam = "LD_LIBRARY_PATH"

	LET env[env.getLength()+1].nam = "TEMP"
	LET env[env.getLength()+1].nam = "TMP"

	LET env[env.getLength()+1].nam = "LANG"
	LET env[env.getLength()+1].nam = "LOCALE"
	LET env[env.getLength()+1].nam = "HOSTNAME"
	LET env[env.getLength()+1].nam = "RHOSTNAME"


	LET env[env.getLength()+1].nam = "FGL_WEBSERVER_PATH"
--	LET env[env.getLength()].val = fgl_getEnv( env[env.getLength()].nam ) -- means GASd Used.
--	IF env[env.getLength()].val IS NOT NULL THEN
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_PATH_INFO"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_PATH_TRANSLATED"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_GATEWAY_INTERFACE"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_ACCEPT"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_ACCEPT_CHARSET"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_ACCEPT_ENCODING"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_ACCEPT_LANGUAGE"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_CONNECTION"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_HOST"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_KEEP_ALIVE"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_HTTP_USER_AGENT"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_REMOTE_ADDR"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_REMOTE_PORT"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_REQUEST_METHOD"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_REQUEST_URI"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SCRIPT_FILENAME"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SCRIPT_NAME"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_ADDR"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_ADMIN"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_NAME"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_PORT"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_PROTOCOL"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_SIGNATURE"
		LET env[env.getLength()+1].nam = "FGL_WEBSERVER_SERVER_SOFTWARE"
--	END IF

	FOR x = 1 TO env.getLength()
		LET env[x].val = fgl_getEnv( env[x].nam )
		IF env[x].nam.getLength() > txt_w THEN LET txt_w = env[x].nam.getLength() END IF
		IF env[x].val.getLength() > val_w THEN LET val_w = env[x].val.getLength() END IF
	END FOR

	OPEN WINDOW showEnv AT 1,1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTES(STYLE="about")
	LET frm = gl_genForm("showEnv")
	CALL gl_titleWin("Current Environment")
	LET vb = frm.createChild("VBox")
	LET tabl = vb.createChild("Table")
	CALL tabl.setAttribute("tabName","showenv")
	CALL tabl.setAttribute("height",env.getLength()+1)
	CALL tabl.setAttribute("pageSize",env.getLength()+1)
	CALL tabl.setAttribute("posX",1)
	CALL tabl.setAttribute("posY",6)
	LET tabc = tabl.createChild('TableColumn')
	CALL tabc.setAttribute("colName","nam")
	CALL tabc.setAttribute("text","Name")
	LET w = tabc.createChild('Edit')
	CALL w.setAttribute("width",txt_w)
	LET tabc = tabl.createChild('TableColumn')
	CALL tabc.setAttribute("colName","val")
	CALL tabc.setAttribute("text","Value")
	LET w = tabc.createChild('Edit')
	CALL w.setAttribute("width",val_w)

	DISPLAY ARRAY env TO showenv.* ATTRIBUTE( COUNT=env.getLength() )
	CLOSE WINDOW showEnv
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Get the product version from the $FGLDIR/etc/fpi-fgl
#+ @return String or NULL
FUNCTION gl_getProductVer() --{{{
	DEFINE verfile base.channel
	DEFINE line STRING
	LET verfile = base.channel.create()
	WHENEVER ERROR CONTINUE
	CALL verfile.openFile( fgl_getEnv("FGLDIR")||"/etc/fpi-fgl", "r")
	WHENEVER ERROR STOP
	IF STATUS != 0 THEN RETURN NULL END IF
&ifdef genero13x
	LET line = "."
	WHILE line IS NOT NULL
&else
	WHILE NOT verfile.isEof() -- Version 2 ONLY!
&endif
		LET line = verfile.readLine()
		IF line.getIndexOf("product.version", 1) > 0 THEN
			RETURN line.subString(20,line.getLength() - 1 )
		END IF
	END WHILE
	RETURN NULL
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Search a path for gdc installer in path, returns filename or null.
#+
#+ @param path STRING: Path to search for fjs-gdc-* files.
#+ @return String or NULL
FUNCTION gl_checkLatestGDC(path) --{{{
	DEFINE path STRING
	DEFINE child STRING
	DEFINE h INTEGER

&ifdef genero13x
	RETURN NULL
&else
	IF NOT os.Path.exists(path) THEN RETURN NULL END IF
	IF NOT os.Path.isdirectory(path) THEN RETURN NULL END IF
	DISPLAY "[", path, "]"

	CALL os.Path.dirsort("name", 1)
	LET h = os.Path.diropen(path)
	LET path = NULL
	WHILE h > 0
		LET child = os.Path.dirnext(h)
		IF child IS NULL THEN EXIT WHILE END IF
		IF child.subString(1,8) == "fjs-gdc-" THEN LET path = child END IF
	END WHILE
	CALL os.Path.dirclose(h)
	RETURN path
&endif
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Merge the default style file with a custom one.
#+
#+ @param nam Name of the custom style file
#+ @param mode Mode of merge: 1=Only add new Style/Attributes 2=Replace is already exists
#+ @param out File name of output file for merge result. Null for no output file.
#+
#+ @return Nothing
FUNCTION gl_mergeST( nam, mode, out ) --{{{
	DEFINE nam,out,nam1,snam,anam,oval,nval STRING
	DEFINE mode,x,y SMALLINT
	DEFINE d_ns om.domDocument
	DEFINE n_ns om.domNode
	DEFINE n_sa om.domNode
	DEFINE nl_ns om.nodeList
	DEFINE nl_sa om.nodeList

	DEFINE d_ns_aui om.domDocument
	DEFINE n_sl_aui om.domNode
	DEFINE n_sa_aui om.domNode
	DEFINE n_ns_aui om.domNode
	DEFINE nl_ns_aui om.nodeList
	DEFINE nl_sa_aui om.nodeList

	LET nam = nam.trim()
	LET nam = nam.append(".4st")
	
	WHENEVER ERROR CONTINUE
	LET d_ns = om.domDocument.createFromXMLFile(nam)
	WHENEVER ERROR STOP
	IF d_ns IS NULL THEN
		CALL gl_winMessage("Error",SFMT(%"Failed to read '%1'.",nam),"exclamation")
		RETURN
	END IF

	LET d_ns_aui = ui.interface.getDocument()
	LET n_sl_aui = ui.interface.getRootNode()	
	LET nl_ns_aui = n_sl_aui.selectByTagName("StyleList")
	IF nl_ns_aui.getLength() < 1 THEN
		CALL gl_winMessage("Error",%"No default Styles found!","exclamation")
		RETURN
	END IF
	LET n_sl_aui = nl_ns_aui.item(1)
	LET nam1 = n_sl_aui.getAttribute("fileName")
	GL_DBGMSG(3,"Default Style: "||nam1||" New Styles:"||nam)

	LET n_ns = d_ns.getDocumentElement()
	LET nl_ns = n_ns.selectByTagName("Style")			
	IF nl_ns.getLength() < 1 THEN
		CALL gl_winMessage("Error",SFMT(%"No Styles in '%1'.",nam),"exclamation")
		RETURN
	END IF

	FOR x = 1 TO nl_ns.getLength()
		LET n_ns = nl_ns.item(x)
		LET snam = n_ns.getAttribute("name")
		LET nl_ns_aui = n_sl_aui.selectByPath("//Style[@name='"||snam||"']")
		IF nl_ns_aui.getLength() = 0 THEN
			GL_DBGMSG(3, "Added :"||snam)
			LET n_ns_aui = d_ns_aui.copy( n_ns, TRUE )
			CALL n_sl_aui.appendChild( n_ns_aui )
		ELSE
			-- Process StyleAttribute nodes
			LET n_ns_aui = nl_ns_aui.item(1)
			GL_DBGMSG(3, "Exists:"||snam)
			LET nl_sa = n_ns.selectByTagName("StyleAttribute")			
			FOR y = 1 TO nl_sa.getLength()
				LET n_sa = nl_sa.item(y)
				LET anam = n_sa.getAttribute("name")
				LET nval = n_sa.getAttribute("value")
				LET nl_sa_aui = n_ns_aui.selectByPath("//StyleAttribute[@name='"||anam||"']")
				IF nl_sa_aui.getLength() > 0 THEN
					LET n_sa_aui = nl_sa_aui.item(1)
					LET oval = n_sa_aui.getAttribute("value")
					IF nval != oval THEN
						GL_DBGMSG(3, "Update:"||snam||" : "||anam||" Updated Old:"||oval||" New:"||nval)
					ELSE
						GL_DBGMSG(3, "Okay  :"||snam||" : "||anam)
					END IF
				ELSE
					GL_DBGMSG(3, "Update:"||snam||" : "||anam||" Added New:"||nval)
					LET n_sa_aui = n_ns_aui.createChild("StyleAttribute")
				END IF
				CALL n_sa_aui.setAttribute("name",anam)				
				CALL n_sa_aui.setAttribute("value",nval)				
			END FOR
		END IF
	END FOR

	IF out IS NOT NULL THEN
		CALL n_sl_aui.writeXml( out||".4st" )
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Merge the default Actiona file with a custom one.
#+
#+ @param nam Name of the custom Actiona file
#+ @param mode Mode of merge: 1=Only add new Actiona 2=Replace if already exists
#+ @param out File name of output file for merge result. Null for no output file.
#+
#+ @return Nothing
FUNCTION gl_mergeAD( nam, mode, out ) --{{{
	DEFINE nam,out,nam1,snam,anam,oval,nval STRING
	DEFINE mode,x,y SMALLINT
	DEFINE d_na om.domDocument
	DEFINE n_na om.domNode
	DEFINE nl_na om.nodeList

	DEFINE d_na_aui om.domDocument
	DEFINE n_al_aui om.domNode
	DEFINE n_na_aui om.domNode
	DEFINE nl_na_aui om.nodeList

	LET nam = nam.append(".4ad")
	
	WHENEVER ERROR CONTINUE
	LET d_na = om.domDocument.createFromXMLFile(nam)
	WHENEVER ERROR STOP
	IF d_na IS NULL THEN
		CALL gl_winMessage("Error",SFMT(%"Failed to read '%1'.",nam),"exclamation")
		RETURN
	END IF

	LET d_na_aui = ui.interface.getDocument()
	LET n_al_aui = ui.interface.getRootNode()	
	LET nl_na_aui = n_al_aui.selectByTagName("ActionDefaultList")
	IF nl_na_aui.getLength() < 1 THEN
		CALL gl_winMessage("Error",%"No default Actions found!","exclamation")
		RETURN
	END IF
	LET n_al_aui = nl_na_aui.item(1)
	LET nam1 = n_al_aui.getAttribute("fileName")
	GL_DBGMSG(3, "Default Actions: "||nam1|| " New Actions:"||nam)

	LET n_na = d_na.getDocumentElement()
	LET nl_na = n_na.selectByTagName("ActionDefault")			
	IF nl_na.getLength() < 1 THEN
		CALL gl_winMessage("Error",SFMT(%"No ActionDefault in '%1'.",nam),"exclamation")
		RETURN
	END IF

	FOR x = 1 TO nl_na.getLength()
		LET n_na = nl_na.item(x)
		LET snam = n_na.getAttribute("name")
		LET nl_na_aui = n_al_aui.selectByPath("//ActionDefault[@name='"||snam||"']")
		IF nl_na_aui.getLength() = 0 THEN
			GL_DBGMSG(3, "Added :"||snam)
			LET n_na_aui = d_na_aui.copy( n_na, TRUE )
			CALL n_al_aui.appendChild( n_na_aui )
		ELSE
			LET n_na_aui = nl_na_aui.item(1)
			-- Process Attribute values
			FOR y = 1 TO n_na.getAttributesCount()
				LET anam = n_na.getAttributeName(y)
				IF anam = "name" THEN CONTINUE FOR END IF
				LET nval = n_na.getAttributeValue(y)
				LET oval = n_na_aui.getAttribute(anam)
				IF oval IS NOT NULL THEN
					IF nval != oval THEN
						GL_DBGMSG(3, "Update:"||snam||" : "||anam||" Updated Old:"||oval||" New:"||nval)
					ELSE
						GL_DBGMSG(3, "Okay  :"||snam||" : "||anam)
					END IF
				ELSE
					GL_DBGMSG(3, "Update:"||snam||" : "||anam||" Added New:"||nval)
				END IF
				CALL n_na_aui.setAttribute(anam,nval)				
			END FOR
		END IF
	END FOR

	IF out IS NOT NULL THEN
		CALL n_al_aui.writeXml( out||".4ad" )
	END IF

END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Attempt to convert a String to a date
FUNCTION gl_strToDate(str) --{{{
	DEFINE str STRING
	DEFINE d DATE
	
	TRY
		LET d = str
	CATCH
	END TRY
	IF d IS NOT NULL THEN RETURN d END IF
	IF str.getCharAt(5) = "-" THEN
		LET d = str.subString(9,10)||"/"||str.subString(6,7)||"/"||str.subString(1,4)
	END IF
	RETURN d
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Return the result from the uname commend.
#+
#+ @return uname of the OS
FUNCTION gl_getUname() --{{{
	DEFINE uname STRING
	DEFINE c base.channel
	LET c = base.channel.create()
	CALL c.openPipe("uname","r")
	LET uname = c.readLine()
	CALL c.close()
	RETURN uname
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Return the Linux Version
#+
#+ @return OS Version
FUNCTION gl_getLinuxVer() --{{{
	DEFINE ver STRING
	DEFINE c base.channel
	DEFINE file DYNAMIC ARRAY OF STRING
	DEFINE x SMALLINT
	LET file[ file.getLength() + 1 ] = "/etc/issue.net"
	LET file[ file.getLength() + 1 ] = "/etc/issue"
	LET file[ file.getLength() + 1 ] = "/etc/debian_version"
	LET file[ file.getLength() + 1 ] = "/etc/SuSE-release"
&ifdef genero13x
	RETURN "unknown"
&else
	FOR x = 1 TO file.getLength() + 1
		IF file[x] IS NULL THEN RETURN "Unknown" END IF
		IF os.Path.exists(file[x]) THEN
			EXIT FOR
		END IF
	END FOR
&endif
	LET c = base.channel.create()
	CALL c.openFile(file[x],"r")
	LET ver = c.readLine()
	CALL c.close()
	RETURN ver
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dump the ui to a file
#+
#+ @param file File name to dump the ui to.
#+
#+ @return none
FUNCTION gl_dumpUI( file ) --{{{
	DEFINE file STRING
	DEFINE n om.domNode

	LET n = ui.interface.getRootNode()
	CALL n.writeXML( file )
END FUNCTION --}}}
----------------------------------------------------------------------------------
#+ Dump the styles to a file
#+
#+ @param file File name to dump the ui to.
#+
#+ @return none
FUNCTION gl_dumpStyles( file ) --{{{
	DEFINE file STRING
	DEFINE n om.domNode
	DEFINE nl om.NodeList

	LET n = ui.interface.getRootNode()
	LET nl = n.selectByTagName("StyleList")
	LET n = nl.item(1)
	CALL n.writeXML( file )
END FUNCTION --}}}
----------------------------------------------------------------------------------
-- Experimental Functions !!

--------------------------------------------------------------------------------
#+ Float Window of Action Keys - Doesn't work!
FUNCTION gl_floatKeys(o_c) --{{{
	DEFINE o_c,x SMALLINT
	DEFINE nam STRING
	DEFINE fk_win, orig_win_n, n, but om.DomNode
	DEFINE nl om.NodeList


	IF NOT o_c THEN
		CLOSE WINDOW floatKeys
		RETURN
	ELSE
		LET orig_win_n = gl_getWinNode(NULL)
		OPEN WINDOW floatKeys AT 1,1 WITH 1 ROWS,1 COLUMNS ATTRIBUTES(STYLE="naked")
		LET n = gl_genForm("floatKeys")
		CALL n.setAttribute("style","naked")
		LET fk_win = n.createChild("Grid")
	END IF

-- Get list of current action
	LET nl = orig_win_n.selectByPath("//Action")
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		LET nam = n.getAttribute("name")
	 	LET but = fk_win.createChild("Button")
		CALL but.setAttribute("name",nam)
		CALL but.setAttribute("posX",1)
		CALL but.setAttribute("posY",x)
		LET nam = n.getAttribute("text")
		CALL but.setAttribute("text",nam)
		LET nam = n.getAttribute("image")
		IF nam IS NOT NULL THEN CALL but.setAttribute("image",nam) END IF
		LET nam = n.getAttribute("comment")
		IF nam IS NOT NULL THEN CALL but.setAttribute("comment",nam) END IF
	END FOR

END FUNCTION --}}}
--------------------------------------------------------------------------------
&ifndef genero23x
#+ Special - this function is built in to 2.3x
FUNCTION fgl_db_driver_type()
	DEFINE dbname, dbdrv STRING

	LET dbname = fgl_getEnv("DBNAME")
	IF dbname IS NULL THEN LET dbname = "unknown" END IF
	GL_DBGMSG(0, "fgl_db_driver_type, dbname:"||dbname)
	LET dbdrv = fgl_getresource("dbi.database."||dbname||".driver")
	IF dbdrv IS NULL THEN LET dbdrv = "???" END IF
	RETURN dbdrv.subString(4,6)
END FUNCTION
&endif
