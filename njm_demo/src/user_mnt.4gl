
#+ User Maintenance Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: user_mnt.4gl 692 2011-07-28 15:36:19Z  $
#+
#+ Two Preprocess variable can be set for this Project:
#+ -DGRE this enables Genero Report Writer for invoice printing
#+
#+ -DgotJAVA enables java based server side printer detection

CONSTANT PRGNAME = "user_mnt"
CONSTANT PRGDESC = "User Maintenance Demo"
CONSTANT PRGAUTH = "Neil J.Martin"

&define ABOUT 		ON ACTION about \
			CALL gl_about( VER, PRGNAME, PRGDESC, PRGAUTH)

&include "schema.inc"

DEFINE m_user DYNAMIC ARRAY OF RECORD LIKE sys_users.*
DEFINE m_roles DYNAMIC ARRAY OF RECORD LIKE sys_roles.*
DEFINE m_uroles DYNAMIC ARRAY OF RECORD 
				user_key LIKE sys_user_roles.user_key,
				role_key LIKE sys_user_roles.role_key,
				role_name LIKE sys_roles.role_name,
				active LIKE sys_user_roles.active
		END RECORD
DEFINE m_user_rec RECORD LIKE sys_users.*
DEFINE m_fullname DYNAMIC ARRAY OF LIKE sys_users.fullname
DEFINE m_user_key INTEGER
DEFINE m_curruser INTEGER
DEFINE m_drag_source STRING
DEFINE m_save, m_saveUser, m_saveRoles BOOLEAN

MAIN
	DEFINE dnd ui.DragDrop

	CALL gl_setInfo(NULL, "njm_demo_logo_256", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),NULL,TRUE)
	WHENEVER ANY ERROR CALL gl_error
	LET m_curruser = ARG_VAL(2)

	CALL gldb_connect(NULL)

	LET m_saveUser = FALSE
	OPEN FORM um FROM "user_mnt"
	DISPLAY FORM um

	DECLARE u_cur CURSOR FOR SELECT * FROM sys_users
	FOREACH u_cur INTO m_user[m_user.getLength()+1].*
		LET m_fullname[ m_user.getLength() ] = m_user[ m_user.getLength() ].fullname
	END FOREACH
	LET m_fullname[ m_user.getLength() ]  = "Click here for new User"

	DECLARE r_cur CURSOR FOR SELECT * FROM sys_roles
	FOREACH r_cur INTO m_roles[m_roles.getLength()+1].*
	END FOREACH
	CALL m_roles.deleteElement( m_roles.getLength() )

	PREPARE ur_pre FROM 
		"SELECT ur.user_key, ur.role_key, r.role_name, ur.active"||
		" FROM sys_user_roles ur,sys_roles r WHERE user_key = ? AND r.role_key = ur.role_key"
	DECLARE ur_cur CURSOR FOR ur_pre

	LET m_save = FALSE
	DIALOG ATTRIBUTES(UNBUFFERED)
		DISPLAY ARRAY m_fullname TO u_arr.*
			BEFORE DISPLAY
				IF m_save THEN
					IF fgl_winQuestion("Confirm","Save these changes?","No","Yes|No","question",1) = "Yes" THEN
						CALL saveRoles()
					ELSE
						CALL setSave(FALSE)
					END IF
				END IF
			BEFORE ROW
				MESSAGE "DA User:",DIALOG.getCurrentRow("u_arr")," of ",m_fullname.getLength()," ",m_user[ DIALOG.getCurrentRow("u_arr") ].fullname
				LET m_user_rec.* = m_user[ DIALOG.getCurrentRow("u_arr") ].*
				LET m_user_key = m_user[ DIALOG.getCurrentRow("u_arr") ].user_key
				CALL m_uroles.clear()
				FOREACH ur_cur USING m_user_key INTO m_uroles[m_uroles.getLength()+1].*
				END FOREACH
				CALL  m_uroles.deleteElement(m_uroles.getLength())
				IF m_user_rec.user_key IS NULL THEN
					NEXT FIELD username
				END IF
			ON DRAG_START(dnd)
				LET m_drag_source = "users"
			ON DRAG_ENTER(dnd)
				CALL dnd.setOperation(NULL)
			ON ACTION delete
				CALL del_user(arr_curr())
		END DISPLAY

		DISPLAY ARRAY m_uroles TO ur_arr.*
			ON ACTION dblclick
				IF fgl_winQuestion("Confirm","Toggle activate state for users role?","No","Yes|No","question",1) = "Yes" THEN
					LET m_uroles[ ARR_CURR() ].active = toggle(m_uroles[ ARR_CURR() ].active)
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
			ON ACTION dblclick
				IF fgl_winQuestion("Confirm","Toggle activate state for this role?","No","Yes|No","question",1) = "Yes" THEN
					LET m_roles[ ARR_CURR() ].active = toggle(m_roles[ ARR_CURR() ].active)
				END IF
			ON DRAG_START(dnd)
				LET m_drag_source = "roles"
			ON ACTION addRoles
				CALL addRoles(DIALOG)
		END DISPLAY

		INPUT m_user_rec.* FROM sys_users.* ATTRIBUTE(WITHOUT DEFAULTS)
			ON ACTION dialogTouched
				CALL DIALOG.setActionActive("dialogtouched",FALSE)
				LET m_saveUser = TRUE
				CALL setSave(TRUE)
				DISPLAY "Touched!"
			BEFORE INPUT
				CALL DIALOG.setactionActive("save",FALSE)
				IF m_user_rec.user_key IS NULL THEN
					LET m_user_rec.active = "Y"
				END IF
				LEt m_saveUser = FALSE
				MESSAGE "IN User:",DIALOG.getCurrentRow("u_arr")," of ",m_fullname.getLength()," ",m_user[ DIALOG.getCurrentRow("u_arr") ].fullname
				CALL checkSave()
			ON ACTION save
				IF DIALOG.validate("sys_users.*") < 0 THEN
					CONTINUE DIALOG
				ELSE
					CALL checkSave()
					CALL setSave(FALSE)
				END IF
			ON ACTION cancel
				CALL setSave(FALSE)
				LET m_user_rec.* = m_user[ DIALOG.getCurrentRow("u_arr") ].*
			AFTER INPUT
				CALL DIALOG.setActionActive("dialogtouched",TRUE)
		END INPUT
		BEFORE DIALOG
			CALL DIALOG.setSelectionMode( "r_arr", TRUE )
			CALL DIALOG.setSelectionMode( "ur_arr", TRUE )
			CALL DIALOG.setactionActive("save",m_save)
		ON ACTION save
			CALL checkSave()
		ON ACTION EXIT
			CALL checkSave()
			EXIT DIALOG
		ON ACTION CLOSE
			EXIT DIALOG
	END DIALOG
END MAIN
--------------------------------------------------------------------------------
FUNCTION removeRoles(d)
	DEFINE d ui.Dialog
	DEFINE x SMALLINT
	FOR x = 1 TO m_roles.getLength()
		IF d.isRowSelected("ur_arr",x) THEN
			CALL m_uroles.deleteElement(x)
			LET m_saveRoles = TRUE
			LET m_save = TRUE
		END IF
	END FOR
	CALL d.setactionActive("save",m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION addRoles(d)
	DEFINE d ui.Dialog
	DEFINE x,y SMALLINT
	FOR x = 1 TO m_roles.getLength()
		IF d.isRowSelected("r_arr",x) THEN
			FOR y = 1 TO m_uroles.getLength()
				IF m_roles[x].role_key = m_uroles[y].role_key THEN
					EXIT FOR
				END IF
			END FOR
			LET m_uroles[y].active = m_roles[x].active
			LET m_uroles[y].role_key = m_roles[x].role_key
			LET m_uroles[y].user_key = m_user_key
			LET m_uroles[y].role_name = m_roles[x].role_name
			LET m_save = TRUE
			LET m_saveRoles = TRUE
		END IF
	END FOR
	CALL d.setactionActive("save",m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setSave(tf)
	DEFINE tf BOOLEAN
	DEFINE d ui.Dialog
	DISPLAY "setSave:",tf
	LET m_save = tf
	LET d = ui.Dialog.getCurrent()
	CALL d.setactionActive("save",m_save)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION checkSave()
	IF m_save THEN 
		IF fgl_winQuestion("Confirm","Save these changes?","No","Yes|No","question",1) = "Yes" THEN
			IF m_saveUser THEN CALL saveUser() END IF	
			IF m_saveRoles THEN CALL saveRoles() END IF
		END IF
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION saveUser()
	DEFINE x SMALLINT
	DEFINE d ui.Dialog
	DEFINE l_comment VARCHAR(20)
	LET l_comment = "User added:"||TODAY
	LET d = ui.Dialog.getCurrent()
	LET x = d.getCurrentRow("u_arr")
	IF m_user_rec.user_key IS NULL OR m_user_rec.user_key < 1 THEN
		LET m_user_rec.user_key = 0
		INSERT INTO sys_users VALUES( m_user_rec.* )
		LET m_user_key = SQLCA.sqlerrd[2]
		LET m_user_rec.user_key = m_user_key
		LET m_user[x].user_key = m_user_rec.user_key
		LET m_fullname[ m_user.getLength() + 1 ]  = "Click here for new User"
	ELSE
		UPDATE sys_users SET sys_users.* = m_user_rec.* 
			WHERE sys_users.user_key = m_user_rec.user_key
	END IF
	LET m_fullname[ x ] = m_user_rec.fullname
	LET m_user[ x ].* = m_user_rec.*
	LET m_save = FALSE
	LET m_saveUser = FALSE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION saveRoles()
	DEFINE x SMALLINT

	IF NOT checkUserRoles(m_curruser,"System Admin Update",TRUE) THEN
		CALL setSave(FALSE)
		RETURN
	END IF

	BEGIN WORK
	DELETE FROM sys_user_roles WHERE user_key = m_user_key
	FOR x = 1 TO m_uroles.getLength()
		INSERT INTO sys_user_roles VALUES( m_user_key,m_uroles[x].role_key,m_uroles[x].active )
	END FOR
	COMMIT WORK
	CALL setSave(FALSE)
-- Need to actually update tables here!
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION del_user(x)
	DEFINE x SMALLINT

	IF m_user[x].user_key IS NULL THEN RETURN END IF
	IF fgl_winQuestion("Confirm","Are you sure you want to delete this user?","No","Yes|No","question",0)
		= "Yes" THEN
		DELETE FROM sys_users WHERE user_key = m_user[x].user_key
		CALL m_user.deleteElement( x )
		CALL m_fullname.deleteElement( x )
	END IF
	MESSAGE "User Deleted"
END FUNCTION
--------------------------------------------------------------------------------