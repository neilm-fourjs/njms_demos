
MAIN
	DEFINE l_user_key INTEGER

--	CALL gl_init(ARG_VAL(1),"menu",FALSE)

	CALL gldb_connect(NULL)
	CLOSE WINDOW SCREEN
	WHILE TRUE
		DISPLAY "Running Login... "||fgl_getEnv("USERNAME")
		LET l_user_key = login()
		IF l_user_key > 0 THEN
			CALL ui.Interface.refresh()
			DISPLAY "Running Menu..."
			RUN "fglrun menu "||ARG_VAL(1)||" "||l_user_key
		ELSE
			EXIT WHILE
		END IF
	END WHILE
END MAIN