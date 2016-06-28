
CONSTANT VER = "$Rev: 747 $"
CONSTANT PRGNAME = "Login"
CONSTANT PRGDESC = "Fjs Demos Suite"
CONSTANT PRGAUTH = "Neil J.Martin"

CONSTANT D_IDLETIME = 300

&define ABOUT 		ON ACTION about \
			CALL gl_about( VER )

&include "schema.inc"

FUNCTION login()
	DEFINE l_user_key LIKE sys_users.user_key
	DEFINE l_username LIKE sys_users.email
	DEFINE l_password LIKE sys_users.password
	DEFINE l_user LIKE sys_users.fullname
	DEFINE l_cookie STRING
	DEFINE l_result INTEGER

	WHENEVER ANY ERROR CALL gl_error
	LET l_cookie = "NJM User:",fgl_getEnv("USERNAME")," RS:",fgl_getEnv("FGLRESOURCEPATH")
	CALL errorlog(l_cookie)

	LET l_cookie = ARG_VAL(2)
	IF l_cookie.getLength() > 3 THEN
		LET l_username = l_cookie
		SELECT user_key INTO l_user_key FROM sys_users WHERE sys_users.email = l_username
		IF STATUS = 0 THEN RETURN l_user_key END IF
	END IF

	OPEN WINDOW login WITH FORM "login"

	CALL ui.interface.setText("Fjs-Demo Login")

	DISPLAY "BEFORE WHILE"
	WHILE TRUE
		LET int_flag = FALSE
		LET l_user_key = -1
		INPUT BY NAME l_username, l_password ATTRIBUTES(UNBUFFERED,WITHOUT DEFAULTS)
			BEFORE INPUT
				DISPLAY "BEFORE INPUT"
			ON IDLE D_IDLETIME
	--			CALL gl_logIt("ON IDLE "||D_IDLETIME)
				LET int_flag = TRUE
				EXIT INPUT
			ABOUT
			AFTER FIELD l_username
				DISPLAY "AFTER FIELD username:",l_username
				IF l_username = "guest" THEN LET l_password = "guest" END IF
			AFTER INPUT
				IF int_flag THEN EXIT INPUT END IF
				DISPLAY "AFTER INPUT username:",l_username
				SELECT user_key,username INTO l_user_key,l_user FROM sys_users 
					WHERE username = l_username AND password = l_password
				IF STATUS = NOTFOUND THEN
					CALL fgl_winMessage("Failed","Login failed ...\nInvalid username or password!","exclamaation")
					LET l_username = ""
					LET l_password = ""
					NEXT FIELD l_username
				END IF
			{ON ACTION dialogtouched
				DISPLAY "Touched:",l_username}
		END INPUT
		DISPLAY "END INPUT"
		IF NOT int_flag THEN
			IF NOT checkUserRoles(l_user_key,"Login",TRUE) THEN
				CONTINUE WHILE
			END IF
			IF ui.Interface.getFrontEndName() = "GWC" THEN
				LET l_cookie = l_user
				CALL ui.Interface.FrontCall("session","setvar",["login",l_cookie],l_result)
			END IF
			--DISPLAY "RealUser:",l_user_key, " result:",l_result
			CALL fgl_setEnv("REALUSER", l_user_key )
			--RUN "fglrun ordent.42r" WITHOUT WAITING
		END IF
		EXIT WHILE
	END WHILE
	DISPLAY "END WHILE"
	CLOSE WINDOW login
	--DISPLAY "Login:",l_user_key
	RETURN l_user_key
END FUNCTION
