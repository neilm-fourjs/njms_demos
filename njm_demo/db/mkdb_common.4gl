
--------------------------------------------------------------------------------
FUNCTION connect( con )
	DEFINE con VARCHAR(300)

	DISPLAY TIME,":Connecting using:",con
	TRY
		DATABASE con
	CATCH
		DISPLAY "Failed:",SQLCA.SQLCODE
		DISPLAY "Error:",STATUS,":",SQLERRMESSAGE
		RETURN FALSE
	END TRY
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION doit()

	IF ARG_VAL(1) = "DELETE" THEN
		CALL delete()
		EXIT PROGRAM
	END IF

	IF ARG_VAL(1) = "INSERT" THEN
		CALL delete()
		RUN "fglrun pop_db"
		EXIT PROGRAM
	END IF

	CALL drop()
	CALL create()

	RUN "fglrun pop_db"

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION delete()
	DISPLAY "Deleting data..."
&ifdef DEL
	DELETE FROM customer
	DELETE FROM addresses
	DELETE FROM countries
	DELETE FROM stock
	DELETE FROM pack_items
	DELETE FROM stock_cat
	DELETE FROM supplier
	DELETE FROM ord_detail
	DELETE FROM ord_head
	DELETE FROM ord_payment
	DELETE FROM disc
	DELETE FROM sys_users
	DELETE FROM sys_user_roles
	DELETE FROM sys_roles
	DELETE FROM sys_menus
	DELETE FROM sys_menu_roles
&else
	TRUNCATE customer
	TRUNCATE addresses
	TRUNCATE countries
	TRUNCATE stock
	TRUNCATE pack_items
	TRUNCATE stock_cat
	TRUNCATE supplier
	TRUNCATE ord_detail
	TRUNCATE ord_payment
	TRUNCATE ord_head
	TRUNCATE disc
	TRUNCATE sys_users
	TRUNCATE sys_user_roles
	TRUNCATE sys_roles
	TRUNCATE sys_menus
	TRUNCATE sys_menu_roles
&endif
	DISPLAY "Done."
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION drop()
	DISPLAY "Dropping tables..."
	WHENEVER ERROR CONTINUE
	DROP TABLE customer
	DROP TABLE addresses
	DROP TABLE countries
	DROP TABLE stock
	DROP TABLE pack_items
	DROP TABLE stock_cat
	DROP TABLE supplier
	DROP TABLE ord_detail
	DROP TABLE ord_head
	DROP TABLE ord_payment
	DROP TABLE disc
	DROP TABLE sys_users
	DROP TABLE sys_user_roles
	DROP TABLE sys_roles
	DROP TABLE sys_menus
	DROP TABLE sys_menu_roles
	WHENEVER ERROR STOP
	DISPLAY "Done."
END FUNCTION