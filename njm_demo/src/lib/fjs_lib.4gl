
&include "schema.inc"
&define TIMELOG CALL timeLogIt("fjs_lib",__LINE__)

DEFINE m_timelogfile STRING
DEFINE m_prev, m_start DATETIME HOUR TO FRACTION(5)

FUNCTION exit_Program()
{
	IF UPSHIFT(ui.Interface.getFrontEndName()) = "GWC" THEN
		OPEN WINDOW w WITH 1 ROWS, 80 COLUMNS
		CALL fgl_setTitle("Program Finished")
		MESSAGE "Program Finished, bye bye."
		CALL ui.Interface.refresh()
	END IF
}
	CALL timeLogIt("fjs_lib-EXIT",__LINE__)
	EXIT PROGRAM
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getUserName(l_user_key)
	DEFINE l_user_key LIKE sys_users.user_key
	DEFINE l_fullname LIKE sys_users.fullname

	SELECT fullname INTO l_fullname FROM sys_users 
		WHERE user_key = l_user_key
	IF STATUS = NOTFOUND THEN
		LET l_fullname = "Unknown User:",l_user_key USING "<<<"
	END IF
	RETURN l_fullname
END FUNCTION
--------------------------------------------------------------------------------
#+ Check the user has the role
#+ 
#+ @param l_user_key Users Serial key
#+ @param l_role Role Name
#+ @param l_verb TRUE=Verbose error FALSE=silent
FUNCTION checkUserRoles(l_user_key,l_role,l_verb)
	DEFINE l_user_key LIKE sys_users.user_key
	DEFINE l_user LIKE sys_users.username
	DEFINE l_role LIKE sys_roles.role_name
	DEFINE l_role_key LIKE sys_roles.role_key
	DEFINE l_verb BOOLEAN
	DEFINE l_u_act, l_r_act, l_ur_act CHAR(1)
	DEFINE l_err STRING

	DISPLAY "checkUserRoles U:",l_user_key," r:",l_role

	SELECT u.active,u.username INTO l_u_act,l_user FROM sys_users u WHERE u.user_key = l_user_key
	IF STATUS = NOTFOUND THEN
		LET l_err = "User not found! key:",l_user_key
		CALL fgl_winMessage("Error",l_err,"exclamation")
		RETURN FALSE
	END IF
	IF l_u_act != "Y" THEN
		LET l_err = "User '"||l_user||"' not active!"
		IF l_verb THEN CALL fgl_winMessage("Error",l_err,"exclamation") END IF
		RETURN FALSE
	END IF


	SELECT r.active,role_key INTO l_r_act,l_role_key 
		FROM sys_roles r WHERE r.role_name = l_role
	IF STATUS = NOTFOUND THEN
		LET l_err = "Role not found! Role:",l_role
		CALL fgl_winMessage("Error",l_err,"exclamation")
		RETURN FALSE
	END IF
	IF l_r_act != "Y" THEN
		LET l_err = "Role '"||l_role||"' not longer active!"
		IF l_verb THEN CALL fgl_winMessage("Error",l_err,"exclamation") END IF
		RETURN FALSE
	END IF
	DISPLAY "checkUserRoles U:",l_u_act,":",l_user," R:",l_r_act

	SELECT ur.active
		INTO l_ur_act
		FROM sys_user_roles ur 
	WHERE ur.user_key = l_user_key
		AND ur.role_key = l_role_key
	IF STATUS = NOTFOUND THEN
		IF l_verb THEN
			LET l_err = "You don't have permission to do that\nPlease contact your system administrator\n"||"Role:"||l_role
			CALL fgl_winMessage("Error",l_err,"exclamation")
		END IF
		RETURN FALSE
	END IF
	DISPLAY "checkUserRoles UR:",l_ur_act

	IF l_ur_act != "Y" THEN
		LET l_err = "Role '"||l_role||"' not active for this user!"
		IF l_verb THEN CALL fgl_winMessage("Error",l_err,"exclamation") END IF
		RETURN FALSE
	END IF

	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION toggle(var)
	DEFINE var CHAR(1)
	IF var = "Y" THEN RETURN "N" END IF
	RETURN "Y"
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION logIt(mess)
	DEFINE mess STRING
	DISPLAY mess
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION timeLogOn()
	LET m_timeLogFile = fgl_getEnv("TIMELOG")
	IF m_timeLogFile.getLength() < 2 THEN LET m_timeLogFile = NULL END IF
	LET m_start = CURRENT
	LET m_prev = m_start
	CALL timeLogIt("fjs_lib-START",__LINE__)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION timeLogIt(l_mod,l_line)
	DEFINE l_line INTEGER
	DEFINE l_mod STRING
	DEFINE l_mess STRING
	DEFINE c base.Channel
	DEFINE l_curr DATETIME HOUR TO FRACTION(5)
	IF m_timelogfile IS NULL THEN RETURN END IF
	LET c = base.Channel.create()
	CALL c.openFile(m_timelogfile,"a")
	LET l_curr = CURRENT
	LET l_mess = l_mod,":",l_line,":",TODAY,":",l_curr,":",(l_curr - m_prev),":",(l_curr - m_start)
	LET m_prev = l_curr
	CALL c.writeLine( l_mess )
	CALL c.close()
END FUNCTION