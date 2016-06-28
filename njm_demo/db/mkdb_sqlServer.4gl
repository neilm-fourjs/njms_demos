
#+ Create the database.
#+
#+ $Id: mkdb_sqlServer.4gl 801 2012-07-03 16:10:16Z test4j $

#+ <PRE>
#+ NOTES: 
#+ dbexport from Informix must have DBDATE=MDY4/
#+ must do unix2dos on the .unl files.
#+ </PRE>

&include "db.inc"

CONSTANT DEF_SRV_NAME="COPLAND2\\SQLEXPRESS"

DEFINE db VARCHAR(20)
DEFINE src,drv STRING
DEFINE m_result STRING

MAIN
  DEFINE con VARCHAR(300)

	CALL startlog( base.application.getProgramName()||".log" )

	LET db = fgl_getenv("DBNAME")
	IF db IS NULL OR db = " " THEN LET db = DEF_DB_NAME END IF

	LET drv = fgl_getenv("DBDRIVER")
	IF drv IS NULL OR drv = " " THEN LET drv = DEF_DB_DRIVER END IF

	IF drv.subString(4,6) != "snc" AND drv.subString(4,6) != "msv" THEN
		CALL fgl_winMessage("ERROR","This program is only intended for SQL Server!","exclamation")
		EXIT PROGRAM
	END IF

	LET src = DEF_DB_NAME -- fgl_getenv("DNS")

	DISPLAY "DB:",db," FGLPROFILE:",fgl_getenv("FGLPROFILE")," SRC:",src
	LET con = db||"+driver='"||drv||"'" --,source='"||src||"'"

	IF NOT connect( con ) THEN
		EXIT PROGRAM
	END IF

	CALL doit()

END MAIN
---------------------------------------------------
#+ Custom load routine for database specific loading
FUNCTION load()
	DEFINE c base.Channel
	DEFINE sqlfil, lne, tabnam,filnam STRING
	DEFINE rws STRING --INTEGER
	DEFINE x,y SMALLINT

	LET sqlfil = ".\\"||db||".exp\\"||db||".sql"

	LET c = base.Channel.create()
	TRY
		CALL c.openFile(sqlfil,"r")
	CATCH
		DISPLAY "Failed to open .sql file: "||sqlfil
		EXIT PROGRAM
	END TRY

	DISPLAY "Reading sql file:",sqlfil
	LET m_result = "Errors from bcp:\n"
	WHILE NOT c.isEof()
		LET lne = c.readLine()
		IF lne.subString(1,7) = "{ TABLE" THEN
			LET x = lne.getIndexOf(".",8)
			IF x = 0 THEN LET x = lne.getIndexOf(" ",7) END IF
			LET y = lne.getIndexOf(" ",x+1)
			LET tabnam = lne.subString(x+1,y-1)
		END IF
		IF lne.subString(1,8) = "{ unload" THEN
			LET x = lne.getIndexOf("=",8)
			LET y = lne.getIndexOf(".",x+1)
			LET filnam = lne.subString(x+2,y-1)
			LET x = lne.getIndexOf("=",y)
			LET y = lne.getIndexOf(" ",x+2)
			LET rws = lne.subString(x+2,y-1)
			CALL bcp(tabnam,filnam,rws)
		END IF
	END WHILE
	CALL c.close()
	DISPLAY m_result
	DISPLAY "Finished."

END FUNCTION
---------------------------------------------------
FUNCTION bcp(tab,fil,rws)
	DEFINE tab, fil, cmd, lne, l_result STRING
	DEFINE rws,loaded INTEGER
	DEFINE c base.Channel
	DEFINE y SMALLINT

	LET c = base.Channel.create()
	DISPLAY "Loading ",rws," from ",fil,".unl into ",tab," ..."
	LET cmd = "bcp "||db||".dbo."||tab||" in .\\"||db||".exp\\"||fil||".unl -t \"|\" -r \"|\\n\" -E -T -c -S "||DEF_SRV_NAME
	DISPLAY "cmd:",cmd
	CALL c.openPipe(cmd,"r")
	LET l_result = cmd||"\n"
	WHILE NOT c.isEof()
		LET lne = c.readLine()
		LET lne = lne.trim()
		IF lne.getLength() > 1 THEN
			DISPLAY lne
			LET l_result = l_result.append(lne||"\n")
			LET y = lne.getIndexOf(" rows copied.",1)
			IF y > 0 THEN LET loaded = lne.subString(1,y-1) END IF
			IF loaded IS NULL THEN LET loaded = 0 END IF
		END IF
	END WHILE
	CALL c.close()
	IF loaded != rws THEN
		LET m_result = m_result.append(l_result)
		DISPLAY "ERROR : ",loaded," rows into ",TAB," !!"
	ELSE
		DISPLAY "Loaded: ",loaded," rows into ",TAB
	END IF

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
		rec_key SERIAL PRIMARY KEY,
		line1 VARCHAR(40),
		line2 VARCHAR(40),
		line3 VARCHAR(40),
		line4 VARCHAR(40),
		line5 VARCHAR(40),
		postal_code VARCHAR(8),
		country_code CHAR(3)
--		UNIQUE(line1, postal_code)
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
		free_stock INTEGER  CHECK (free_stock >= 0),
		long_desc VARCHAR(100),
		img_url VARCHAR(100),
		UNIQUE( barcode )
	)"
	--EXECUTE IMMEDIATE "ALTER TABLE stock ADD CONSTRAINT CHECK (free_stock >= 0)"
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

--	EXECUTE IMMEDIATE "
	CREATE TABLE ord_head (
		order_number SERIAL PRIMARY KEY,
		order_datetime DATETIME YEAR TO SECOND,
		order_date DATE, --SMALLDATETIME,
		order_ref VARCHAR(40),
		req_del_date DATE, --SMALLDATETIME,
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
		total_disc DECIMAL(12,3)
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
		user_key SERIAL PRIMARY KEY,
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
	CREATE TABLE sys_user_roles (
		user_key INTEGER,
		role_key INTEGER,
		active CHAR(1),
			PRIMARY KEY (user_key, role_key)
	)
	CREATE TABLE sys_roles (
		role_key SERIAL PRIMARY KEY,
		role_type CHAR(1),
		role_name VARCHAR(30),
		active CHAR(1)
	)
	CREATE TABLE sys_menus (
		menu_key	SERIAL PRIMARY KEY,
		m_id      VARCHAR(6),
		m_pid     VARCHAR(6),
		m_type    CHAR(1),
		m_text    VARCHAR(40),
		m_item    VARCHAR(80),
		m_passw   VARCHAR(8)
	);
	CREATE TABLE sys_menu_roles (
		menu_key INTEGER,
		role_key INTEGER,
		active CHAR(1),
			PRIMARY KEY (menu_key, role_key)
	)
	DISPLAY "Done."
END FUNCTION