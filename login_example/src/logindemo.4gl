
#+ Login Demo
#+
#+ This module initially written by: Neil J.Martin ( neilm@4js.com ) 
#+

IMPORT FGL lib_secure
IMPORT FGL lib_login
IMPORT FGL gl_lib
&include "schema.inc"

CONSTANT VER = "1.0"
CONSTANT APP = %"Login Demo"

MAIN
	DEFINE l_login STRING

	OPEN FORM ld FROM "logindemo"
	DISPLAY FORM ld

	DISPLAY "Hello" TO msg

	CALL gl_lib.gl_init(TRUE)

	MENU
		ON ACTION close EXIT MENU
		ON ACTION login
			LET l_login = do_login()
			IF l_login IS NOT NULL THEN
				DISPLAY "Welcome "||l_login TO msg
				CALL DIALOG.setActionActive("login", FALSE)
			END IF
		ON ACTION quit EXIT MENU
	END MENU

END MAIN
--------------------------------------------------------------------------------
FUNCTION do_login()
	DEFINE l_login STRING

	LET int_flag = FALSE
	WHILE NOT int_flag
		LET l_login = lib_login.login(APP, VER, TRUE)
		DISPLAY "Login:",l_login
		IF l_login = "NEW" THEN 
			CALL new_acct()
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE

	IF l_login != "Cancelled" THEN
		CALL gl_lib.gl_winMessage(%"Login Okay",SFMT(%"Login for user %1 accepted.",l_login),"information")
		RETURN l_login
	END IF
	RETURN NULL
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION new_acct()
	DEFINE l_acc RECORD LIKE accounts.*

	LET l_acc.acct_id = 0
	LET l_acc.acct_type = 1
	LET l_acc.active = TRUE
	LET l_acc.forcepwchg = "Y"

	OPEN WINDOW new_acct WITH FORM "new_acct"

	INPUT BY NAME l_acc.* ATTRIBUTES(WITHOUT DEFAULTS, FIELD ORDER FORM, UNBUFFERED)
		AFTER FIELD email
			SELECT * FROM accounts WHERE email = l_acc.email
			IF STATUS != NOTFOUND THEN
				CALL gl_lib.gl_winMessage("Error","This Email is already registered.","exclamation")
				NEXT FIELD email
			END IF
		BEFORE INPUT
			CALL DIALOG.setFieldActive("accounts.acct_id",FALSE)
			CALL DIALOG.setFieldActive("accounts.forcepwchg",FALSE)
			CALL DIALOG.setFieldActive("accounts.active",FALSE)
			CALL DIALOG.setFieldActive("accounts.acct_type",FALSE)
		ON ACTION generate
			LET l_acc.login_pass = lib_secure.glsec_genPassword()
			CALL fgl_winMessage(%"Password",SFMT(%"Your Generated Password is:\n%1\nDon't forget it!",l_acc.login_pass),"information")
	END INPUT

	CLOSE WINDOW new_acct

	IF NOT int_flag THEN
		LET l_acc.salt = lib_secure.glsec_genSalt()
		LET l_acc.pass_hash = lib_secure.glsec_genHash(l_acc.login_pass ,l_acc.salt)
		LET l_acc.login_pass = "PasswordEncrypted!"
		INSERT INTO accounts VALUES l_acc.*
	END IF

	LET int_flag = FALSE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION pop_combo(l_cb)
	DEFINE l_cb ui.ComboBox

	CASE l_cb.getColumnName()
		WHEN "acct_type"
			CALL l_cb.addItem(1,"Normal User")
			CALL l_cb.addItem(2,"Admin User")
	END CASE
END FUNCTION
--------------------------------------------------------------------------------