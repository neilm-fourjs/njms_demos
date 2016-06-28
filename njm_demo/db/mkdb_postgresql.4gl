
-- Create the database.
--
-- $Id: mkdb_mysql.4gl 715 2011-09-26 08:38:56Z neilm $

IMPORT util
IMPORT os

CONSTANT DEF_DB_DRIVER="dbmpgs84x"
CONSTANT DEF_DB_NAME="fjs_demos"

DEFINE db VARCHAR(20)
DEFINE dbdir, drv STRING

MAIN
  DEFINE con VARCHAR(300)
	DEFINE un,pw STRING

	CALL startlog( base.application.getProgramName()||".log" )

	LET db = fgl_getenv("DBNAME")
	IF db IS NULL OR db = " " THEN LET db = DEF_DB_NAME END IF

	LET drv = fgl_getenv("DBDRIVER")
	IF drv IS NULL OR drv = " " THEN LET drv = DEF_DB_DRIVER END IF

	IF drv.subString(4,6) != "pgs" THEN
		CALL fgl_winMessage("ERROR","This program is only intended for PostgreSQL!","exclamation")
		EXIT PROGRAM
	END IF

	LET un = fgl_getenv("DBUSER")
	LET pw = fgl_getenv("DBPASS")
	DISPLAY "DB:",db," DBDir:",dbdir, "UN:",un," PW:",pw

	LET con = "db+driver='"||drv||"', source='"||db
	IF un.getLength() > 1 THEN
		LET con = con||"',username='"||un
	END IF
	IF pw.getLength() > 1 THEN
		LET con = con||"',password='"||pw
	END IF
	LET con = con||"'"

	IF NOT connect( con ) THEN
		CALL mkdb(db,un,pw)
	END IF

	IF NOT connect( con ) THEN
		EXIT PROGRAM
	END IF

	DISPLAY "doit" EXIT PROGRAM
	CALL doit()

END MAIN
---------------------------------------------------
-- Create the db
FUNCTION mkdb(db,un,pw)
	DEFINE db,un,pw,cmd STRING

--	LET cmd = 'createdb -w -h localhost ',db.trim()
	LET cmd = 'createdb ',db.trim()
	DISPLAY "mkdb: Execute:",cmd
	RUN cmd

	LET cmd = "createlang plpgsql ",db.trim()
	DISPLAY "mkdb: Execute:",cmd
	RUN cmd

	DISPLAY "mkdb: Done."
END FUNCTION
---------------------------------------------------
-- Custom load routine for database specific loading
FUNCTION load()
END FUNCTION
---------------------------------------------------
FUNCTION create()
	DISPLAY "Creating tables..."
	CREATE TABLE customer (
		customer_code CHAR(8) PRIMARY KEY,
		customer_name VARCHAR(30),
		contact_name VARCHAR(30),
		email VARCHAR(100),
		web_passwd CHAR(10),
		del_addr INTEGER,
		inv_addr INTEGER,
		disc_code CHAR(2),
		credit_limit INTEGER,
		total_invoices DECIMAL(12,2),
		outstanding_amount DECIMAL(12,2)
		--UNIQUE(customer_code)
	)

	CREATE TABLE countries (
		country_code CHAR(3) PRIMARY KEY,
		country_name CHAR(40)
	)

	CREATE TABLE addresses (
		rec_key SERIAL, -- PRIMARY KEY,
		line1 VARCHAR(40),
		line2 VARCHAR(40),
		line3 VARCHAR(40),
		line4 VARCHAR(40),
		line5 VARCHAR(40),
		postal_code VARCHAR(8),
		country_code CHAR(3),
		UNIQUE(line1, postal_code)
	)
	CREATE INDEX addr_idx ON addresses ( line2, line3 )

	EXECUTE IMMEDIATE "
	CREATE TABLE stock (
		stock_code CHAR(8) PRIMARY KEY,
		stock_cat CHAR(10),
		pack_flag CHAR(1),
		supp_code CHAR(10),
		barcode CHAR(13),
		description CHAR(30),
		price DECIMAL(12,2),
		cost DECIMAL(12,2),
		tax_code CHAR(1),
		disc_code CHAR(2),
		physical_stock INTEGER,
		allocated_stock INTEGER,
		free_stock INTEGER CHECK(free_stock >= 0),
		long_desc VARCHAR(100),
		img_url VARCHAR(100),
		UNIQUE( barcode )
	)"

	--EXECUTE IMMEDIATE "ALTER TABLE stock ADD CONSTRAINT "
	CREATE INDEX stk_idx ON stock ( description )

	CREATE TABLE pack_items (
		pack_code CHAR(8),
		stock_code CHAR(8),
		qty INTEGER,
		price DECIMAL(12,2),
		cost DECIMAL(12,2),
		tax_code CHAR(1),
		disc_code CHAR(2)
	)

	CREATE TABLE stock_cat (
		catid CHAR(10),
		cat_name CHAR(80)
	);

	CREATE TABLE supplier (
		supp_code CHAR(10),
		supp_name CHAR(80),
		disc_code CHAR(2),
		addr_line1 VARCHAR(40),
		addr_line2 VARCHAR(40),
		addr_line3 VARCHAR(40),
		addr_line4 VARCHAR(40),
		addr_line5 VARCHAR(40),
		postal_code VARCHAR(8),
		tel CHAR(20),
		email VARCHAR(60)
	)

	CREATE TABLE ord_head (
		order_number SERIAL, -- PRIMARY KEY,
		order_datetime DATETIME YEAR TO SECOND,
		order_date DATE,
		order_ref VARCHAR(40),
		req_del_date DATE,
		customer_code VARCHAR(8),
		customer_name VARCHAR(30),
		del_address1 VARCHAR(40),
		del_address2 VARCHAR(40),
		del_address3 VARCHAR(40),
		del_address4 VARCHAR(40),
		del_address5 VARCHAR(40),
		del_postcode VARCHAR(8),
		inv_address1 VARCHAR(40),
		inv_address2 VARCHAR(40),
		inv_address3 VARCHAR(40),
		inv_address4 VARCHAR(40),
		inv_address5 VARCHAR(40),
		inv_postcode VARCHAR(8),
		username CHAR(8),
		items INTEGER,
		total_qty INTEGER,
		total_nett DECIMAL(12,2),
		total_tax DECIMAL(12,2),
		total_gross DECIMAL(12,2),
		total_disc DECIMAL(12,3),
		PRIMARY KEY( order_number )
	)
--	CREATE UNIQUE INDEX oh_idx ON ord_head ( order_number )

	CREATE TABLE ord_payment (
		order_number INTEGER,
		payment_type CHAR(1),
		del_type CHAR(1),
		card_type CHAR(1),
		card_no CHAR(20),
		expires_m SMALLINT,
		expires_y SMALLINT,
		issue_no SMALLINT,
		payment_amount DECIMAL(12,2),
		del_amount DECIMAL(6,2)
	)

	CREATE TABLE ord_detail (
		order_number INTEGER,
		line_number SMALLINT,
		stock_code VARCHAR(8),
		pack_flag CHAR(1),
		price DECIMAL(12,2),
		quantity INTEGER,
		disc_percent DECIMAL(5,2),
		disc_value DECIMAL(10,3),
		tax_code CHAR(1),
		tax_rate DECIMAL(5,2),
		tax_value DECIMAL(10,2),
		nett_value DECIMAL(10,2),
		gross_value DECIMAL(10,2),
			PRIMARY KEY (order_number, line_number),
			FOREIGN KEY (order_number) REFERENCES ord_head
	)

	CREATE TABLE disc (
		stock_disc CHAR(2),
		customer_disc CHAR(2),
		disc_percent DECIMAL(5,2),
			PRIMARY KEY (stock_disc, customer_disc)
	)

	CREATE TABLE sys_users (
		user_key SERIAL, -- PRIMARY KEY,
		username VARCHAR(10),
		fullname VARCHAR(40),
		password VARCHAR(20),
		email VARCHAR(40),
		office_tel VARCHAR(30),
		mobile_tel VARCHAR(30),
		def_cust VARCHAR(8),
		user_type CHAR(1),
		prog_no SMALLINT,
		active CHAR(1)
	)
	CREATE TABLE sys_roles (
		role_key SERIAL, -- PRIMARY KEY,
		role_type CHAR(1),
		role_name VARCHAR(30),
		active CHAR(1)
	)
	CREATE TABLE sys_menus (
		menu_key	SERIAL,
		m_id      VARCHAR(6),
		m_pid     VARCHAR(6),
		m_type    CHAR(1),
		m_text    VARCHAR(40),
		m_item    VARCHAR(80),
		m_passw   VARCHAR(8)
	);
	CREATE TABLE sys_user_roles (
		user_key INTEGER,
		role_key INTEGER,
		active CHAR(1),
			PRIMARY KEY (user_key, role_key)
	)
	CREATE TABLE sys_menu_roles (
		menu_key INTEGER,
		role_key INTEGER,
		active CHAR(1),
			PRIMARY KEY (menu_key, role_key)
	)
	DISPLAY "Done."
END FUNCTION
