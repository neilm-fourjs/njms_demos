
&include "schema.inc"

CONSTANT PRGNAME = "menu_mnt"
CONSTANT PRGDESC = "Menu Maintenance Demo"
CONSTANT PRGAUTH = "Neil J.Martin"
&include "../lib/genero_lib1.inc"	
	
&define RECNAME sys_menus.*

&define TABNAMEQ "sys_menus"
&define TABNAME sys_menus

&define KEYFLDQ "menu_key"
&define KEYFLD menu_key
&define LABFLD m_text
&define LABFLDQ "m_text"
&define RECKEY m_rec.KEYFLD

DEFINE m_rec RECORD LIKE RECNAME
DEFINE m_rec_o RECORD LIKE RECNAME
DEFINE m_recs DYNAMIC ARRAY OF RECORD
			key LIKE TABNAME.KEYFLD,
			desc LIKE TABNAME.LABFLD
	END RECORD
DEFINE m_roles DYNAMIC ARRAY OF RECORD LIKE sys_roles.*
DEFINE m_mroles DYNAMIC ARRAY OF RECORD 
				menu_key LIKE sys_menu_roles.menu_key,
				role_key LIKE sys_menu_roles.role_key,
				role_name LIKE sys_roles.role_name,
				active LIKE sys_menu_roles.active
		END RECORD
DEFINE m_func CHAR
DEFINE m_row INTEGER
DEFINE m_wher STRING
DEFINE m_allowedActions CHAR(6) --Y/N for Find / List / Update / Insert / Delete / Sample
                              -- NNYNNN = Only update allowed.
DEFINE m_drag_source STRING
DEFINE m_menu_key LIKE sys_menus.menu_key
DEFINE m_save BOOLEAN
DEFINE m_user_key LIKE sys_users.user_key
MAIN
	DEFINE dnd ui.DragDrop

	LET gl_toolbar = "dynmaint"
	CALL gl_setInfo(NULL, "njm_demo", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),"default",TRUE)
	WHENEVER ANY ERROR CALL gl_error
	LET m_user_key = ARG_VAL(2)
	LET m_allowedActions = ARG_VAL(3) 
	LET m_allowedActions = (m_allowedActions CLIPPED),"YYYYY"
	DISPLAY "AllowedActions:",m_allowedActions

	CALL gldb_connect(NULL)

	OPEN FORM frm FROM "menu_mnt"
	DISPLAY FORM frm

	DECLARE r_cur CURSOR FOR SELECT * FROM sys_roles
	FOREACH r_cur INTO m_roles[m_roles.getLength()+1].*
	END FOREACH
	CALL m_roles.deleteElement( m_roles.getLength() )

	PREPARE mr_pre FROM 
		"SELECT mr.menu_key, mr.role_key, r.role_name, mr.active"||
		" FROM sys_menu_roles mr,sys_roles r WHERE menu_key = ? AND r.role_key = mr.role_key"
	DECLARE mr_cur CURSOR FOR mr_pre

	DECLARE fetch_row CURSOR FOR SELECT * FROM TABNAME
			WHERE KEYFLD = ?
	
	DIALOG ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY m_recs TO m_arr.*
			BEFORE DISPLAY
				IF m_save THEN
					IF fgl_winQuestion("Confirm","Save these changes?","No","Yes|No","question",1) = "Yes" THEN
						CALL saveRoles()
					ELSE
						CALL setSave("FALSE")
					END IF
				END IF
			BEFORE ROW 
				CALL showRow( ARR_CURR() )
				CALL m_mroles.clear()
				LET m_menu_key = m_recs[ DIALOG.getCurrentRow("m_arr") ].key
				FOREACH mr_cur USING m_menu_key INTO m_mroles[m_mroles.getLength()+1].*
				END FOREACH
				CALL  m_mroles.deleteElement(m_mroles.getLength())
		END DISPLAY

		DISPLAY ARRAY m_mroles TO mr_arr.*
			ON ACTION dblclick
				IF fgl_winQuestion("Confirm","Toggle activate state for users role?","No","Yes|No","question",1) = "Yes" THEN
					LET m_mroles[ ARR_CURR() ].active = toggle(m_mroles[ ARR_CURR() ].active)
					CALL setSave(TRUE)
				END IF
			ON ACTION removeRoles
				CALL removeRoles(DIALOG)
			ON DRAG_ENTER(dnd)
				IF m_drag_source = "roles" THEN
					CALL dnd.setOperation("copy")
				ELSE
					CALL dnd.setOperation(NULL)
				END IF
			ON DROP(dnd)
				CALL addRoles(DIALOG)
			ON DRAG_FINISHED(dnd)
				LET m_drag_source = NULL
		END DISPLAY

		DISPLAY ARRAY m_roles TO r_arr.*
			ON DRAG_START(dnd)
				LET m_drag_source = "roles"
			ON ACTION addRoles
				CALL addRoles(DIALOG)
		END DISPLAY

		BEFORE DIALOG
			CALL gl2_setActions(m_row,m_recs.getLength(), m_allowedActions)
			CALL setSave(FALSE)

		ON ACTION exit EXIT DIALOG
		ON ACTION close EXIT DIALOG
		ON ACTION save CALL saveRoles()
		ON ACTION enquire LET m_func = "E"
			IF NOT query() THEN CONTINUE DIALOG END IF
			IF m_recs.getLength() > 0 THEN
				CALL showRow(1)
			END IF
			CALL gl2_setActions(m_row,m_recs.getLength(),m_allowedActions)

		ON ACTION insert LET m_func = "N"
			IF NOT inp(TRUE) THEN MESSAGE "Cancelled" END IF
		ON ACTION update LET m_func = "U"
			IF m_rec.KEYFLD IS NULL THEN
				IF NOT query() THEN CONTINUE DIALOG END IF
			END IF
			IF NOT inp(FALSE) THEN MESSAGE "Cancelled" END IF

		ON ACTION delete LET m_func = "D"
			IF m_rec.KEYFLD IS NULL THEN
				IF NOT query() THEN CONTINUE DIALOG END IF
			END IF
			IF delete() THEN MESSAGE "Row deleted." END IF

	 	ON ACTION list 
			LET RECKEY = gl2_fldChoose( TABNAMEQ, base.typeInfo.create( m_rec ) )
			DISPLAY "key:",RECKEY
			LET m_wher = KEYFLDQ||"='"||RECKEY||"'"
			IF getRec() THEN CALL showRow(1) END IF

		ON ACTION report
			CALL rpt1()

		ON ACTION nextrow
			CALL showRow(m_row + 1)
			CALL gl2_setActions(m_row,m_recs.getLength(),m_allowedActions)
		ON ACTION prevrow
			CALL showRow(m_row - 1)
			CALL gl2_setActions(m_row,m_recs.getLength(),m_allowedActions)
		ON ACTION firstrow
			CALL showRow(1)
			CALL gl2_setActions(m_row,m_recs.getLength(),m_allowedActions)
		ON ACTION lastrow
			CALL showRow(m_recs.getLength())
			CALL gl2_setActions(m_row,m_recs.getLength(),m_allowedActions)
	END DIALOG

END MAIN
--------------------------------------------------------------------------------
FUNCTION query()
	LET int_flag = FALSE
	CONSTRUCT BY NAME m_wher ON RECNAME
	IF int_flag THEN LET int_flag = FALSE RETURN FALSE END IF
	RETURN getRec()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getRec()
	PREPARE q_pre FROM "SELECT "||KEYFLDQ||","||LABFLDQ||" FROM "||TABNAMEQ||" WHERE "||m_wher
	DECLARE q_cur CURSOR FOR q_pre
	CALL m_recs.clear()
	FOREACH q_cur INTO m_recs[ m_recs.getLength() + 1].*
	END FOREACH
	CALL m_recs.deleteElement( m_recs.getLength() )
	MESSAGE m_recs.getLength()," Rows found."
	IF m_recs.getLength() < 1 THEN LET m_row = 0 RETURN FALSE END IF
	LET m_row = 1
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION showRow(x)
	DEFINE x INTEGER

	IF x > m_recs.getLength() THEN RETURN END IF
	IF x < 1 THEN RETURN END IF

	OPEN fetch_row USING m_recs[x].key
	FETCH fetch_row INTO m_rec.*
	CLOSE fetch_row
	DISPLAY BY NAME m_rec.*
	LET m_rec_o.* = m_rec.*
	LET m_row = x
END FUNCTION
--------------------------------------------------------------------------------
-- @param ins Insert True/False
FUNCTION inp( ins )
	DEFINE ins, ret BOOLEAN
	
	OPTIONS INPUT WRAP
	IF ins THEN LET m_rec.menu_key = 0 END IF
	LET int_flag = FALSE
	INPUT BY NAME m_rec.* WITHOUT DEFAULTS ATTRIBUTES( UNBUFFERED )
		BEFORE INPUT
			IF NOT ins THEN
				CALL DIALOG.setFieldActive(TABNAMEQ||"."||KEYFLDQ,FALSE)
				MESSAGE %"Disable:",TABNAMEQ||"."||KEYFLDQ
			END IF
	END INPUT
	
	LET ret = FALSE

	IF NOT int_flag THEN
		IF ins THEN
			LET ret = insert()
		ELSE
			LET ret = update()
		END IF
	END IF
	RETURN ret

END FUNCTION
--------------------------------------------------------------------------------
#+ Confirm and delete the current row
FUNCTION delete()
	DEFINE l_stmt VARCHAR(100)

	IF NOT checkUserRoles(m_user_key,"Delete",TRUE) THEN
		RETURN FALSE
	END IF

	LET l_stmt = "SELECT * FROM "||TABNAMEQ||" WHERE "||KEYFLDQ||" = '"||m_rec.KEYFLD||"'"
	LET m_rec_o.KEYFLD = m_rec.KEYFLD
	IF NOT gl2_checkRec(TRUE,m_rec.KEYFLD,l_stmt) THEN RETURN FALSE END IF

	IF gl2_confirm("delete") THEN
		LET l_stmt = "DELETE FROM "||TABNAMEQ||" WHERE "||KEYFLDQ||" = ?"
		PREPARE pre_del FROM l_stmt
		EXECUTE pre_del USING RECKEY
		RETURN gl_sqlStatus(__LINE__,__FILE__,"DELETE FROM "||TABNAMEQ||" WHERE "||KEYFLDQ||" = '"||RECKEY||"'")
	END IF
	RETURN FALSE
END FUNCTION
--------------------------------------------------------------------------------
#+ Update a row in the database table.
#+
#+ @return True / False - fails / works.
FUNCTION update()
	DEFINE l_stmt VARCHAR(20000)
	DEFINE l_wher VARCHAR(100)

	IF m_rec.* = m_rec_o.* THEN
--		DISPLAY "Nothing changed!"
		ERROR "Nothing changed!"
		RETURN TRUE
	END IF
	IF NOT checkUserRoles(m_user_key,"System Admin Update",TRUE) THEN
		RETURN FALSE
	END IF
	LET l_stmt = "SELECT * FROM "||TABNAMEQ||" WHERE "||KEYFLDQ||" = '"||m_rec.KEYFLD||"'"
	LET m_rec_o.KEYFLD = m_rec.KEYFLD
	IF NOT gl2_checkRec(TRUE,m_rec.KEYFLD,l_stmt) THEN RETURN FALSE END IF

	LET l_wher = KEYFLDQ||" = ?"
	LET l_stmt = gl2_genUpdate2(TABNAMEQ, l_wher, base.typeInfo.create(m_rec), base.typeInfo.create(m_rec_o),0, TRUE )
--	DISPLAY "Update:",l_stmt CLIPPED
	TRY
		PREPARE pre_upd FROM l_stmt CLIPPED
	CATCH
		RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
	END TRY

	TRY
		EXECUTE pre_upd USING m_rec_o.KEYFLD
		LET m_recs[ m_row ].key = m_rec.KEYFLD
		RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
	CATCH
		RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
	END TRY
	RETURN FALSE

END FUNCTION
--------------------------------------------------------------------------------
#+ Insert a new row into the database table.
#+
#+ @return True / False - fails / works.
FUNCTION insert()
	DEFINE l_stmt VARCHAR(4000)

	LET l_stmt = "SELECT * FROM "||TABNAMEQ||" WHERE "||KEYFLDQ||" = '"||m_rec.KEYFLD||"'"
	LET m_rec_o.KEYFLD = m_rec.KEYFLD
	IF NOT gl2_checkRec(FALSE,m_rec.KEYFLD,l_stmt) THEN RETURN FALSE END IF
	
	IF gl2_confirm("insert") THEN
		LET l_stmt = gl2_genInsert(TABNAMEQ, base.typeInfo.create( m_rec ), TRUE )
		TRY
			PREPARE pre_ins FROM l_stmt
		CATCH
			RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
		END TRY
		TRY
			EXECUTE pre_ins
			RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
		CATCH
			RETURN gl_sqlStatus(__LINE__,__FILE__,l_stmt)
		END TRY
	END IF
	RETURN FALSE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION removeRoles(d)
	DEFINE d ui.Dialog
	DEFINE x SMALLINT
	FOR x = 1 TO m_roles.getLength()
		IF d.isRowSelected("mr_arr",x) THEN
			CALL m_mroles.deleteElement(x)
			LET m_save = TRUE
		END IF
	END FOR
	CALL setSave(m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION addRoles(d)
	DEFINE d ui.Dialog
	DEFINE x,y SMALLINT
	FOR x = 1 TO m_roles.getLength()
		IF d.isRowSelected("r_arr",x) THEN
			FOR y = 1 TO m_mroles.getLength()
				IF m_roles[x].role_key = m_mroles[y].role_key THEN
					EXIT FOR
				END IF
			END FOR
			LET m_mroles[y].active = m_roles[x].active
			LET m_mroles[y].role_key = m_roles[x].role_key
			LET m_mroles[y].menu_key = m_menu_key
			LET m_mroles[y].role_name = m_roles[x].role_name
			LET m_save = TRUE
		END IF
	END FOR
	CALL setSave(m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION rpt1()
	DEFINE l_rec RECORD LIKE RECNAME
	DEFINE l_row INTEGER

	IF m_wher IS NULL OR m_wher.getLength() < 1 THEN LET m_wher = "1=1" END IF
	PREPARE rpt_pre FROM "SELECT * FROM "||TABNAMEQ||
				" WHERE "||m_wher||" ORDER BY "||KEYFLDQ
	DECLARE rpt_cur CURSOR FOR rpt_pre
	LET l_row = 0
	FOREACH rpt_cur INTO l_rec.*
		IF l_row = 0 THEN
			START REPORT trad_rpt TO SCREEN
		END IF
		LET l_row = l_row + 1
		OUTPUT TO REPORT trad_rpt(l_row,l_rec.*)
	END FOREACH
	IF l_row > 0 THEN
		FINISH REPORT trad_rpt
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setSave(tf)
	DEFINE tf BOOLEAN
	DEFINE d ui.Dialog
	LET m_save = tf
	LET d = ui.Dialog.getCurrent()
	CALL d.setactionActive("save",m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION saveRoles()
	DEFINE x SMALLINT
	IF NOT checkUserRoles(m_user_key,"System Admin Update",TRUE) THEN
		CALL setSave(FALSE)
		RETURN
	END IF
	BEGIN WORK
	DELETE FROM sys_menu_roles WHERE menu_key = m_menu_key
	FOR x = 1 TO m_mroles.getLength()
		INSERT INTO sys_menu_roles VALUES( m_menu_key,m_mroles[x].role_key,m_mroles[x].active )
	END FOR
	COMMIT WORK
	CALL setSave(FALSE)
END FUNCTION
--------------------------------------------------------------------------------
REPORT trad_rpt(l_row,l_rec)
	DEFINE l_rec RECORD LIKE RECNAME
	DEFINE l_row INTEGER
  DEFINE l_print_date DATE
	DEFINE l_rpt_user, l_head1, l_head2 STRING
	DEFINE x SMALLINT

	ORDER EXTERNAL BY l_rec.KEYFLD

  FORMAT
		FIRST PAGE HEADER
			LET l_rpt_user = glGRW_getUser()
			LET l_print_date = TODAY
			LET l_head2 = "Printed:",l_print_date, " By:", l_rpt_user.trim()
			LET x = 132 - LENGTH( l_head2 )
			LET l_head1 = "Menu Listing"
			PRINT l_head1,COLUMN x,l_head2
			PRINT "--------------------------------------------";
			PRINT "--------------------------------------------";
			PRINT "-------------------------------------------"

			PRINT "        Key Id";
			PRINT COLUMN 20,"Pid";
			PRINT COLUMN 30,"Type";
			PRINT COLUMN 40,"Text";
			PRINT COLUMN 82,"Command"

		ON EVERY ROW
			PRINT l_rec.menu_key," ";
			PRINT l_rec.m_id," ";
			PRINT COLUMN 20,l_rec.m_pid;
			PRINT COLUMN 30,l_rec.m_type;
			PRINT COLUMN 40,l_rec.m_text;
			PRINT COLUMN 82,l_rec.m_item
END REPORT