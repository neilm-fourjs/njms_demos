
&define GL_DBGMSG( lev, msg ) \
	CALL gl_dbgMsg( __FILE__, __LINE__, lev, NVL(msg,"NULL!")) \


&define GL_MODULE_ERROR_HANDLER   WHENEVER ANY ERROR CALL gl_error

GLOBALS
  DEFINE g_dbgLev SMALLINT  -- debug level for display messages from this library code.
							 -- 0 = None
							 -- 1 = General Messages
							 -- 2 = All
											-- in gl_init using using FGL_GL_DBGLEV environment variable.

	DEFINE gl_version STRING
	DEFINE gl_splash STRING
	DEFINE gl_progicon STRING
	DEFINE gl_progname STRING
	DEFINE gl_progdesc STRING
	DEFINE gl_progauth STRING

	DEFINE gl_auditFile STRING
	DEFINE gl_auditTable STRING
	DEFINE gl_noToolBar SMALLINT
	DEFINE gl_toolbar,  gl_topmenu STRING

	DEFINE gl_db CHAR(3)
	DEFINE gl_os STRING
	DEFINE gl_cli_os STRING
	DEFINE gl_cli_osver STRING
	DEFINE gl_cli_un STRING
	DEFINE gl_cli_res STRING
	DEFINE gl_cli_dir STRING
	DEFINE gl_uname STRING

	DEFINE gl_app_build STRING -- Applcation Build 
	DEFINE gl_app_name STRING -- Applcation Name
END GLOBALS

