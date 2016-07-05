
-- A Simple Menu example program.
-- $Id: menu.4gl 957 2016-06-13 10:11:24Z neilm $

CONSTANT PRGNAME = "Menu"
CONSTANT PRGDESC = "NJM Demo"
CONSTANT PRGAUTH = "Neil J.Martin"

CONSTANT D_IDLETIME = 300

&define TIMELOG CALL timeLogIt(PRGNAME,__LINE__)
&include "lib/gitver.inc"
&include "schema.inc"
DEFINE m_compno SMALLINT
DEFINE m_user, m_titl VARCHAR(60)
DEFINE m_menu DYNAMIC ARRAY OF RECORD LIKE sys_menus.*
DEFINE m_menus DYNAMIC ARRAY OF VARCHAR(6)
DEFINE m_curMenu SMALLINT
DEFINE m_args STRING
DEFINE m_user_key LIKE sys_users.user_key
DEFINE m_bm STRING
MAIN
	DEFINE l_idle SMALLINT
	DEFINE l_arg1, l_prog, l_args STRING
	DEFINE l_w ui.Window
	DEFINE l_f ui.Form

	WHENEVER ANY ERROR CALL gl_error
	LET l_prog = base.Application.getProgramName()||"_"||DOWNSHIFT(ui.Interface.getFrontEndName())
	CALL gl_setInfo(NULL, "njm_demo_logo_256", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),NULL,FALSE)

	CALL timeLogOn()

--	CALL logIt("Started")

	LET m_bm = fgl_getEnv("BENCHMARK")

	CALL gldb_connect(NULL)
	TIMELOG

	OPEN FORM menu FROM "menu"
	DISPLAY FORM menu
	CALL gl_titleWin(NULL)

	LET l_idle = D_IDLETIME
	LET m_user_key = ARG_VAL(2)
	IF m_user_key = 0 OR m_user_key IS NULL THEN
		LET m_user_key = login()
		IF m_user_key < 0 THEN
			CALL exit_Program()
		END IF
	END IF
	IF m_user_key > 255 THEN LET m_user_key = m_user_key - 255 END IF
	TIMELOG

	LET l_w = ui.window.getCurrent()
	LET l_f = l_w.getForm()

	LET m_user = getUserName(m_user_key)
	LET l_arg1  = ARG_VAL(1)
	IF l_arg1.getLength() < 1 THEN LET l_arg1 = "S" END IF
	IF l_arg1 = "MDI" THEN LET l_arg1 = "C" END IF -- child
	LET m_args = l_arg1||" "||m_user_key

	--IF fgl_getEnv("STARTMENU") = "true" THEN
	--	CALL genStartMenu("main")
	--END IF

	LET m_curMenu = 1
	LET m_menus[1] = "main"
	CALL ui.interface.setText("Fjs-Demo Menu")
	IF NOT populate_menu(m_menus[m_curMenu]) THEN -- should not happen!
--		CALL logIt("'main' menu not found!")
		CALL exit_Program()
	END IF

	IF m_user IS NOT NULL THEN CALL gl_titleWin(m_user) END IF
	DISPLAY BY NAME m_compno, m_user
	DISPLAY TODAY TO dte
	TIMELOG
	DISPLAY ARRAY m_menu TO menu.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY	
			TIMELOG
			IF m_user = "benchmark@4js-emea.com" THEN
				IF m_bm IS NOT NULL AND m_bm.getLength() > 1 THEN
--					CALL logIt("RUN:"||m_bm)
					RUN m_bm WITHOUT WAITING
					LET int_flag = TRUE
					CALL exit_Program()
				END IF
			END IF

		{ON IDLE l_idle
			LET int_flag = TRUE
			EXIT DISPLAY}

		ON ACTION back
			IF m_curMenu > 1 THEN
				IF populate_menu(m_menus[m_curMenu - 1]) THEN
					LET m_curMenu = m_curMenu - 1
				END IF
			END IF
		ON ACTION accept
			CALL progArgs( m_menu[ arr_curr() ].m_item ) RETURNING l_prog, l_args
			DISPLAY "Menu line accepted:",m_menu[ arr_curr() ].m_type||"-"||m_menu[ arr_curr() ].m_text
			CASE m_menu[ arr_curr() ].m_type 
				WHEN "C"
					CASE m_menu[ arr_curr() ].m_item 
						WHEN "quit"
							EXIT DISPLAY
						WHEN "back" 
							--DISPLAY "back:",m_curMenu
							IF m_curMenu > 1 AND populate_menu(m_menus[m_curMenu - 1]) THEN
								LET m_curMenu = m_curMenu - 1
							END IF
							--DISPLAY "back:",m_curMenu
							CALL DIALOG.setCurrentRow("menu",1)
					END CASE

				WHEN "F" 
					CALL logIt("RUN:fglrun "||l_prog||" "||m_args||" "||l_args)
					DISPLAY "m_args:",m_args, " l_args:",l_args
					DISPLAY "Run: fglrun "||l_prog||" "||m_args||" "||l_args
					RUN "fglrun "||l_prog||" "||m_args||" "||l_args WITHOUT WAITING

				WHEN "P" 
					CALL logIt("RUN:"||l_prog||" "||l_args)
					DISPLAY "Run: "||l_prog||" "||l_args
					RUN l_prog||" "||l_args WITHOUT WAITING

				WHEN "O" 
					CALL logIt("OSRUN:"||m_menu[ arr_curr() ].m_item)
					DISPLAY "exec: "||m_menu[ arr_curr() ].m_item
					RUN m_menu[ arr_curr() ].m_item WITHOUT WAITING

				WHEN "M"
					LET m_menus[m_curMenu + 1] = m_menu[ arr_curr() ].m_item
					IF populate_menu(m_menus[m_curMenu + 1]) THEN
						LET m_curMenu = m_curMenu + 1
					END IF
					CALL DIALOG.setCurrentRow("menu",1)
			END CASE
		ON ACTION about
			CALL gl_about( GITVER )
		ON ACTION exit 
			IF ARG_VAL(1) = "MDI" THEN
				IF ui.Interface.getChildCount() > 0 THEN
					CALL fgl_winMessage("Warning","Must close child windows first!","exclamation")
					CONTINUE DISPLAY
				END IF
			END IF
			EXIT DISPLAY
		ON ACTION close 
			IF ARG_VAL(1) = "MDI" THEN
				IF ui.Interface.getChildCount() > 0 THEN
					CALL fgl_winMessage("Warning","Must close child windows first!","exclamation")
					CONTINUE DISPLAY
				END IF
			END IF
			EXIT DISPLAY
	END DISPLAY
	CALL exit_Program()
--	CALL logIt("Finished")
END MAIN
--------------------------------------------------------------------------------
FUNCTION populate_menu(l_mname)
	DEFINE l_mname LIKE sys_menus.m_id
	DEFINE l_role_name LIKE sys_roles.role_name
	DEFINE l_prev_key LIKE sys_menus.menu_key

--	DISPLAY "menu:",mname," n:",m_curMenu
	SELECT m_text INTO m_titl FROM sys_menus 
		WHERE m_id = l_mname AND m_type = "T"
	IF STATUS = NOTFOUND THEN 
--		DISPLAY "Menu:"||mname||" not found!"
		RETURN FALSE
	END IF
	DISPLAY BY NAME m_titl;

	CALL m_menu.clear()
	DECLARE cur CURSOR FOR SELECT sys_menus.*,sys_roles.role_name 
		FROM sys_menus 		--OUTER(sys_menu_roles,sys_roles)
		LEFT OUTER JOIN sys_menu_roles
		ON sys_menu_roles.menu_key = sys_menus.menu_key
		LEFT OUTER JOIN sys_roles
		ON sys_menu_roles.role_key = sys_roles.role_key
		WHERE m_id = l_mname 
		AND m_type != "T" 
		ORDER BY sys_menus.menu_key

	LET l_prev_key  = -1
	FOREACH cur INTO m_menu[ m_menu.getLength() + 1 ].*, l_role_name
		IF l_role_name IS NOT NULL THEN
			DISPLAY "Role:",l_role_name
			IF NOT checkUserRoles(m_user_key,l_role_name,FALSE) THEN
				CALL m_menu.deleteElement( m_menu.getLength() )
				CONTINUE FOREACH
			END IF
			IF m_menu[ m_menu.getLength() ].menu_key = l_prev_key THEN
				CALL m_menu.deleteElement( m_menu.getLength() )
				CONTINUE FOREACH
			END IF
			LET l_prev_key = m_menu[ m_menu.getLength() ].menu_key 
		END IF
	END FOREACH
	LET m_menu[m_menu.getLength()].m_type = "C"
	LET m_menu[m_menu.getLength()].m_text = "Back"
	LET m_menu[m_menu.getLength()].m_item = "back"
	IF m_menu[m_menu.getLength() - 1].m_pid IS NULL THEN
		LET m_menu[m_menu.getLength()].m_text = "Quit"
		LET m_menu[m_menu.getLength()].m_item = "quit"
	END IF
	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION genStartMenu(mname)
	DEFINE mname LIKE sys_menus.m_id
	DEFINE l_root,l_sm om.DomNode

	DISPLAY "StartMenu Generating..."
	LET l_root = ui.Interface.getRootNode()
	LET l_sm = l_root.createChild("StartMenu")
	CALL l_sm.setAttribute("text","Four J's Demos")
	
	CALL genStartMenu2(l_sm,mname,1)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION genStartMenu2(l_sm, mname,l_lev)
	DEFINE mname LIKE sys_menus.m_id
	DEFINE l_smi,l_smg,l_sm om.DomNode
	DEFINE l_lev,x SMALLINT
	DEFINE l_menu DYNAMIC ARRAY OF RECORD LIKE sys_menus.*
	DEFINE l_args,l_prog STRING

	CALL l_menu.clear()
	DECLARE l_menucurr CURSOR FOR SELECT * FROM sys_menus
		WHERE m_id = mname 
		ORDER BY menu_key
	FOREACH l_menucurr INTO l_menu[ l_menu.getLength() + 1 ].*
	END FOREACH

	FOR x = 1 TO l_menu.getLength() - 1
		CALL progArgs( l_menu[x].m_item) RETURNING l_prog, l_args

		CASE l_menu[x].m_type 
			WHEN "T"
				LET l_smg = l_sm.createChild("StartMenuGroup")
				CALL l_smg.setAttribute("text",l_menu[x].m_text)
			WHEN "M"
				CALL genStartMenu2(l_smg,l_menu[x].m_item,l_lev+1)
			WHEN "F"
				LET l_smi = l_smg.createChild("StartMenuCommand")
				CALL l_smi.setAttribute("text",l_menu[x].m_text)
				CALL l_smi.setAttribute("exec","fglrun "||l_prog||" "||m_args||" "||l_args)
			WHEN "P"
				LET l_smi = l_smg.createChild("StartMenuCommand")
				CALL l_smi.setAttribute("text",l_menu[x].m_text)
				CALL l_smi.setAttribute("exec",l_prog||" "||l_args)
		END CASE
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION progArgs( l_prog )
	DEFINE l_prog, l_args STRING
	DEFINE y SMALLINT
	DISPLAY "l_prog:",l_prog
	LET y = l_prog.getIndexOf(" ",1)
	LET l_args = " "
	IF y > 0 THEN
		LET l_args = l_prog.subString(y,l_prog.getLength())
		LET l_prog = l_prog.subString(1,y)
	END IF
	IF l_args IS NULL THEN LET l_args = " " END IF
	DISPLAY "l_prog:",l_prog," l_args:",l_args
	RETURN l_prog, l_args
END FUNCTION
--------------------------------------------------------------------------------