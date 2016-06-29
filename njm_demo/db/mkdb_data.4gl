#+ Insert the data.
#+
#+ $Id: mkdb_data.4gl 963 2016-06-24 12:23:28Z neilm $
IMPORT util

&include "../src/lib/schema.inc"
&include "db.inc"

DEFINE m_ordHead RECORD LIKE ord_head.*
DEFINE m_ordDet RECORD LIKE ord_detail.*
DEFINE m_cust RECORD LIKE customer.*

CONSTANT MAX_ORDERS = 50
CONSTANT MAX_LINES = 30
CONSTANT MAX_QTY = 25

DEFINE m_bc_cnt, m_addr, m_mkey, m_ukey, m_rkey INTEGER
DEFINE m_dbtyp STRING
---------------------------------------------------
FUNCTION insert()
	
	LET m_dbtyp = FGL_DB_DRIVER_TYPE()
	IF m_dbtyp = "snc" OR m_dbtyp = "msv" THEN CALL load() RETURN END IF

	DISPLAY "Inserting test data..."
	INSERT INTO customer VALUES(1,"NJM Software Projects Inc","Neil Martin","njm@njm-projects.com","12njm",1,1, "CC", 10000, 0 ,0)
	INSERT INTO customer VALUES(2,"O'Meara Operations Ltd","Neil O'Meara","nom@nom-ltd.com","12neilom",2,2, "BB", 8000, 0, 0)
	INSERT INTO customer VALUES(3,"Gerrit Enterprises Co.","Gerrit Le Roux","glr@glr-ent.com","12gerrit",3,3, "AA", 8000, 0 ,0)

	IF m_dbtyp = "pgs" THEN
		INSERT INTO addresses VALUES(nextval('addresses_rec_key_seq'),"The Road","The Small Town","Sussex","U.K.","","BN12 XYZ","GBR")
		INSERT INTO addresses VALUES(nextval('addresses_rec_key_seq'),"Some Road","The Large Town","London","U.K.","","SW12","GBR")
		INSERT INTO addresses VALUES(nextval('addresses_rec_key_seq'),"The Street","The Village","Surry","U.K.","","RH1 XYZ","GBR")
	ELSE
		INSERT INTO addresses VALUES(1,"The Road","The Small Town","Sussex","U.K.","","BN12 XYZ","GBR")
		INSERT INTO addresses VALUES(2,"Some Road","The Large Town","London","U.K.","","SW12","GBR")
		INSERT INTO addresses VALUES(3,"The Street","The Village","Surry","U.K.","","RH1 XYZ","GBR")
	END IF
	LET m_addr = 4

	LET m_bc_cnt = 124212

	CALL insStock("FR01",NULL, "06660010001x","An Apple", 0.20, "AA")
	CALL insStock("FR01-10",NULL, "06660010002x","An Apple x 10", 1.90, "AA")
	CALL insStock("FR02",NULL, "06660010003x","A Bannana", 0.30, "AA")

	CALL insStock("GM01",NULL, "06660011001x","Poker Chips", 19.99, "AA")
	CALL insStock("GM02",NULL, "06660011002x","Playing Cards - Cheap", .99, "AA")
	CALL insStock("GM03-R",NULL, "06660011003x","Playing Cards - Bicycle Red", 1.99, "AA")
	CALL insStock("GM03-B",NULL, "06660011004x","Playing Cards - Bicycle Blue", 1.99, "AA")
	CALL insStock("GM05",NULL, "06660011005x","Poker Dice", 2.49, "AA")
	CALL insStock("GM06",NULL, "06660011006x","Card Mat - Green", 1.49, "AA")

	CALL insPackItem("GM04","GM01",1)
	CALL insPackItem("GM04","GM03-R",1)
	CALL insPackItem("GM04","GM03-B",1)
	CALL insPackItem("GM04","GM05",1)
	CALL insPackItem("GM04","GM06",1)
	CALL insStock("GM04","E", "06660011000x","Poker Set", 25.99, "AA")

	CALL insStock("GM15",NULL, "06660011015x","Artist Sketch Pad", 2.49, "AA")
	CALL insStock("GM16",NULL, "06660011016x","5 Pencils HB-B4", 3.49, "AA")
	CALL insStock("GM17",NULL, "06660011017x","5 Pencils H4-HB", 3.49, "AA")
	CALL insStock("GM18",NULL, "06660011018x","Artists Eraser", 1.49, "AA")

	CALL insPackItem("GM19","GM15",2)
	CALL insPackItem("GM19","GM16",1)
	CALL insPackItem("GM19","GM17",1)
	CALL insPackItem("GM19","GM18",2)
	CALL insStock("GM19","P", "06660011019x","Artists Starter Pack", 12.99, "AA")

	CALL insStock("ST13",NULL, "06660012021x","Calculator", 9.99, "CC")
	CALL insStock("ST02-10",NULL, "06660012002x","Envelope x 10", 2.25, "CC")
	CALL insStock("ST01",NULL, "06660012001x","A4 Paper x 500", 9.99, "CC")
	CALL insStock("ST03-BK",NULL, "06660012031x","Bic Ball Point - Black", .49, "CC")
	CALL insStock("ST03-BL",NULL, "06660012032x","Bic Ball Point - Blue", .49, "CC")
	CALL insStock("ST03-RD",NULL, "06660012033x","Bic Ball Point - Red", .49, "CC")

	CALL insStock("WW47",NULL, "06660090021x","AK47", 789.99, "DD")
	CALL insStock("WW10",NULL, "06660092213x","Flame Thrower", 1229.99, "DD")
	CALL insStock("WW01-DES",NULL, "06660091041x","Combat Jacket - Desert", 59.99, "DD")
	CALL insStock("WW01-JUN",NULL, "06660091042x","Combat Jacket - Jungle", 59.99, "DD")

	CALL insStock("HH01",NULL, "03600029145X","Tissues", 1.49, "BB")

	INSERT INTO stock_cat VALUES ('ART', 'Office Decor')
	INSERT INTO stock_cat VALUES ('ENTERTAIN', 'Entertainment')
	INSERT INTO stock_cat VALUES ('FURNITURE', 'Furniture')
	INSERT INTO stock_cat VALUES ('TRAVELLING', 'Travelling')
	INSERT INTO stock_cat VALUES ('HOUSEHOLD', 'House Hold')
	INSERT INTO stock_cat VALUES ('SUPPLIES',  'Supplies')
	INSERT INTO stock_cat VALUES ('FRUIT', 'Fruit')
	INSERT INTO stock_cat VALUES ('ARMY', 'WWIII Supplies')
	INSERT INTO stock_cat VALUES ('GAMES', 'Games/Toys')
	INSERT INTO stock_cat VALUES ('SPORTS', 'Sporting Goods')

	INSERT INTO disc VALUES("AA","AA",2.5)
	INSERT INTO disc VALUES("AA","BB",5)
	INSERT INTO disc VALUES("AA","CC",10)
	INSERT INTO disc VALUES("AA","DD",10.25)
	INSERT INTO disc VALUES("BB","AA",2)
	INSERT INTO disc VALUES("BB","BB",2.5)
	INSERT INTO disc VALUES("BB","CC",4)
	INSERT INTO disc VALUES("BB","DD",4.25)
	INSERT INTO disc VALUES("CC","AA",1.5)
	INSERT INTO disc VALUES("CC","BB",3)
	INSERT INTO disc VALUES("CC","CC",15)
	INSERT INTO disc VALUES("CC","DD",15.25)
	INSERT INTO disc VALUES("DD","AA",1.25)
	INSERT INTO disc VALUES("DD","BB",1.35)
	INSERT INTO disc VALUES("DD","CC",1.45)
	INSERT INTO disc VALUES("DD","DD",1.55)

	LET m_ukey = 1
	CALL addUser("neilm","Neil J.Martin","12neilm","neilm@4js.com","C",0)
	CALL addUser("njm","N J.Martin","12njm","njm@njm-projects.com","A",1)
	CALL addUser("fjs-sxb","FourJ's SXB","fjs-sxb","support@4js.com","C",0)
	CALL addUser("neilom","Neil O'Meara","12neilom","neilom@4js.com","C",0)
	CALL addUser("guest","Guest","guest","","A",1)

	LET m_rkey = 1
	CALL addRole("S","Login")
	CALL addRole("S","Operator")
	CALL addRole("M","System Admin")
	CALL addRole("M","Order Entry")
	CALL addRole("M","Order Edit")
	CALL addRole("S","Invoice Printing")
	CALL addRole("M","Enquiries")
	CALL addRole("M","Customer Management")
	CALL addRole("M","Stock Management")
	CALL addRole("M","System Admin Update")
	CALL addRole("M","Delete")

	INSERT INTO sys_user_roles VALUES(1,1,"Y")
	INSERT INTO sys_user_roles VALUES(1,2,"Y")
	INSERT INTO sys_user_roles VALUES(1,3,"Y")
	INSERT INTO sys_user_roles VALUES(1,4,"Y")
	INSERT INTO sys_user_roles VALUES(1,5,"Y")
	INSERT INTO sys_user_roles VALUES(1,6,"Y")
	INSERT INTO sys_user_roles VALUES(1,10,"Y")

	INSERT INTO sys_user_roles VALUES(2,1,"Y")
	INSERT INTO sys_user_roles VALUES(2,2,"Y")
	INSERT INTO sys_user_roles VALUES(2,6,"Y")

	INSERT INTO sys_user_roles VALUES(3,1,"Y")
	INSERT INTO sys_user_roles VALUES(3,2,"Y")
	INSERT INTO sys_user_roles VALUES(3,6,"Y")

	INSERT INTO sys_user_roles VALUES(4,1,"Y")
	INSERT INTO sys_user_roles VALUES(4,2,"Y")
	INSERT INTO sys_user_roles VALUES(4,3,"Y")
	INSERT INTO sys_user_roles VALUES(4,4,"Y")
	INSERT INTO sys_user_roles VALUES(4,5,"Y")
	INSERT INTO sys_user_roles VALUES(4,6,"Y")

	INSERT INTO sys_user_roles VALUES(5,1,"Y")
	INSERT INTO sys_user_roles VALUES(5,2,"Y")
	INSERT INTO sys_user_roles VALUES(5,3,"Y")
	INSERT INTO sys_user_roles VALUES(5,4,"Y")
	INSERT INTO sys_user_roles VALUES(5,5,"Y")
	INSERT INTO sys_user_roles VALUES(5,6,"Y")

	LET m_mkey = 1
	CALL addMenu("main","","T","Four J's Demos Menu", "","")
	--CALL addMenu("main","","M","Demos Programs", "demo","")
	CALL addMenu("main","","M","Enquiry Programs", "enq","")
	CALL addMenu("main","","M","Maintenance Programs", "mnt","")
	CALL addMenu("main","","M","Order Entry", "oe","")
	CALL addMenu("main","","M","System Maintenance", "sys","")

	CALL addMenu("demo","main","T","Demo Programs", "","")
	CALL addMenu("demo","main","P","Widgets Demo", "../scripts/rundemo widgets","")
	CALL addMenu("demo","main","P","ipodTree Demo", "../scripts/rundemo ipodTree","")
	CALL addMenu("demo","main","P","picFlow Demo", "../scripts/rundemo picFlow","")

	CALL addMenu("sys","main","T","System Maintenance", "","")
	CALL addMenu("sys","main","F","User/Role Maintenance", "user_mnt.42r","")
	CALL addMenu("sys","main","F","Menu/Role Maintenance", "menu_mnt.42r","")

	CALL addMenu("enq","main","T","Enquiry Programs", "","")
	CALL addMenu("enq","main","F","Customer Enquiry", "cust_mnt.42r YYNNNN","")
	CALL addMenu("enq","main","F","Stock Enquiry", "dynMaint.42r stock stock_code YYNNNN","")

	CALL addMenu("mnt","main","T","Maintenance Programs", "","")
	CALL addMenu("mnt","main","F","Customer Maintenance", "cust_mnt.42r","")
	CALL addMenu("mnt","main","F","Stock Maintenance", "dynMaint.42r stock stock_code","")
	CALL addMenu("mnt","main","F","Stock Cat Maintenance", "dynMaint.42r stock_cat catid","")
	CALL addMenu("mnt","main","F","Supplier Maintenance", "dynMaint.42r supplier supp_code","")

	CALL addMenu("oe","main","T","Order Entry", "","")
	CALL addMenu("oe","main","F","Order Entry", "orderEntry.42r ","")
	CALL addMenu("oe","main","F","Web Order Entry", "webOE.42r ","")
	CALL addMenu("oe","main","M","Invoicing Reports", "oeprn","")
	CALL addMenu("oeprn","oe","T","Invoicing Reports", "","")
	CALL addMenu("oeprn","oe","F","Print Invoices", "printInvoices.42r 0 ordent.4rp","")
	CALL addMenu("oeprn","oe","F","Print Picking Notes", "printInvoices.42r picklist.4rp","")

	CALL officeStore()
	IF m_dbtyp = "ifx" THEN
		CALL stores_demo()
	END IF
	CALL insSupp()
	CALL genOrders()

	DISPLAY "Done."
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION addUser(l_username,l_fullname,l_password,l_email,l_user_type,l_prog_no)
DEFINE
		l_username VARCHAR(10),
		l_fullname VARCHAR(40),
		l_password VARCHAR(20),
		l_email VARCHAR(40),
		l_user_type CHAR(1),
		l_prog_no SMALLINT

	IF m_dbtyp = "pgs" THEN
		INSERT INTO sys_users VALUES(nextval('sys_users_user_key_seq'),l_username,l_fullname,l_password,l_email,"","",0,l_user_type,l_prog_no,"Y")
	ELSE
		INSERT INTO sys_users VALUES(m_ukey,l_username,l_fullname,l_password,l_email,"","",0,l_user_type,l_prog_no,"Y")

	END IF
	LET m_ukey = m_ukey + 1
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION addRole(l_type,l_name)
	DEFINE l_type CHAR(1),
		l_name     VARCHAR(30)

	IF m_dbtyp = "pgs" THEN
		INSERT INTO sys_roles VALUES(nextval('sys_roles_role_key_seq'),l_type,l_name,"Y")
	ELSE
		INSERT INTO sys_roles VALUES(m_rkey,l_type,l_name,"Y")
	END IF
	LET m_rkey = m_rkey + 1
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION addMenu(l_id,l_pid,l_type,l_text,l_item,l_passw)
	DEFINE l_id      VARCHAR(6),
		l_pid     VARCHAR(6),
		l_type    CHAR(1),
		l_text    VARCHAR(40),
		l_item    VARCHAR(80),
		l_passw   VARCHAR(8)

	IF m_dbtyp = "pgs" THEN
		INSERT INTO sys_menus VALUES(nextval('sys_menus_menu_key_seq'),l_id,l_pid,l_type,l_text,l_item,l_passw)
	ELSE
		INSERT INTO sys_menus VALUES(m_mkey,l_id,l_pid,l_type,l_text,l_item,l_passw)
	END IF
	LET m_mkey = m_mkey + 1
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION insStock(l_sc,l_pack,l_bc,l_ds,l_pr,l_dc)
	DEFINE
		l_sc CHAR(8),
		l_pack CHAR(1),
		l_bc CHAR(13),
		l_ds CHAR(30),
		l_pr,l_cst DECIMAL(12,2),
		l_dc CHAR(2),
		l_cat CHAR(10),
		l_sup CHAR(10),
		l_tc CHAR(1),
		l_img VARCHAR(100)
	DEFINE l_ps, l_al, l_fr INTEGER --physical/allocated/free

	LET l_tc = "1"
	IF l_sc[1,2]= "FR" THEN LET l_cat = "FRUIT" LET l_sup = getSupp(l_cat) LET l_tc = "0" LET l_dc = "AA" END IF
	IF l_sc[1,2]= "ST" THEN LET l_cat = "SUPPLIES" LET l_sup = getSupp(l_cat) END IF
	IF l_sc[1,2]= "WW" THEN LET l_cat = "ARMY" LET l_sup = getSupp(l_cat) LEt l_tc = "3" LET l_dc = "CC" END IF
	IF l_sc[1,2]= "HH" THEN LET l_cat = "HOUSEHOLD" LET l_sup = getSupp(l_cat) END IF
	IF l_sc[1,2]= "GM" THEN LET l_cat = "GAMES" LET l_sup = getSupp(l_cat)  LET l_dc = "BB" END IF

	LET l_bc = genBarCode(l_sc,l_cat)
	LET l_bc = calcCheck(l_bc)

	IF l_pack = "P" THEN
		SELECT MIN( physical_stock ) INTO l_ps FROM pack_items p,stock s
		 WHERE pack_code = l_sc
			AND p.stock_code = s.stock_code
		SELECT MAX( allocated_stock ) INTO l_al FROM pack_items p,stock s
		 WHERE pack_code = l_sc
			AND p.stock_code = s.stock_code
	ELSE
		LET l_ps = util.math.rand( 200 )
		LET l_al = util.math.rand( 50 )
	END IF
	LET l_ps = l_ps  + 50
	LET l_fr = l_ps - l_al
	LET l_cst = ( l_pr * 0.75 )
	DISPLAY l_sc,"-",l_bc, "-", l_ds, " ps:",l_ps, " al:",l_al, " fr:",l_fr
	LET l_img = DOWNSHIFT(l_sc CLIPPED)
	INSERT INTO stock VALUES(l_sc,l_cat,l_pack,l_sup,l_bc,l_ds,l_pr,l_cst,l_tc,l_dc,l_ps,l_al,l_fr,"",l_img)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION insPackItem(l_pc,l_sc,l_qty)
	DEFINE l_pc,l_sc CHAR(8),
		l_qty SMALLINT,
		l_pr, l_cst DECIMAL(12,2),
		l_tc CHAR(1),
		l_dc CHAR(2)
	SELECT price,cost,tax_code,disc_code 
		INTO l_pr, l_cst, l_tc, l_dc
		FROM stock WHERE stock_code = l_sc
	INSERT INTO pack_items VALUES(l_pc,l_sc,l_qty,l_pr,l_cst,l_tc,l_dc)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION insSupp()
	DEFINE sup CHAR(10)
	DEFINE supname CHAR(20)

	DECLARE sup_cur CURSOR FOR SELECT UNIQUE supp_code FROM stock ORDER BY supp_code
	FOREACH sup_cur INTO sup
		LET supname = "Supplier "||sup
		INSERT INTO supplier VALUES(sup,supname,"DC","al1","al2","al3","al4","al5","pc","tel","email")
	END FOREACH

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION getSupp(l_cat)
	DEFINE l_cat CHAR(10)

	CASE l_cat
		WHEN "FRUIT" RETURN "GRO"
		WHEN "SUPPLIES" RETURN "SS"
		WHEN "ARMY" RETURN "USGOV"
		WHEN "HOUSEHOLD" RETURN "HHINC"
		WHEN "GAMES" RETURN "GRO"
		WHEN "ART" RETURN "GRO"
		WHEN "ENTERTAIN" RETURN "GRO"
		WHEN "FURNITURE" RETURN "FCB"
		WHEN "TRAVELLING" RETURN "TC"
		OTHERWISE RETURN "UNK"
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION calcCheck(bc)
	DEFINE bc CHAR(12)
	DEFINE x,y SMALLINT

	LET x = bc[1] + bc[3] + bc[5] + bc[7] + bc[9] + bc[11]
	LET x = x * 3
	LET x = x + bc[2] + bc[4] + bc[6] + bc[8] + bc[10]
	LET y = ( x MOD 10 )
	IF y != 0 THEN LET y = 10 - y END IF
	LET bc[12] = y

	RETURN bc
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION stores_demo()
	DEFINE
		l_sc CHAR(8),
		l_bc CHAR(13),
		l_ds,l_att CHAR(30),
		l_pr,l_cst DECIMAL(12,2),
		l_cat,l_sup,l_pwd CHAR(10),
		l_ld, l_pic,l_em VARCHAR(100),
		l_dc CHAR(2)
	DEFINE l_ps, l_al, l_fr INTEGER
	DEFINE l_sn SMALLINT
	DEFINE l_ad1,l_ad2,l_ad3,l_ad4,l_ad5,l_pc VARCHAR(40)

	TRY
		DECLARE sdcur CURSOR FOR 
			SELECT *
			FROM stores7:stock
	CATCH
		DISPLAY "stores7 not available:",SQLERRMESSAGE
		RETURN
	END TRY
	DISPLAY "stores7 Stock"
	FOREACH sdcur INTO l_sn,l_sup,l_ds,l_pr,l_bc,l_att
--		DISPLAY "got stock record:",l_sn
		LET l_ds = l_ds CLIPPED,"/",l_att
		LET l_sc = l_sup CLIPPED,"-",l_sn USING "&&&&"
		LET l_ps = util.math.rand( 250 )
		LET l_al = util.math.rand( 50 )
		LET l_ps = l_ps + 50
		LET l_fr = l_ps - l_al
		LET l_cst = ( l_pr * 0.75 )
		LET l_cat = "SPORTS"
		LET l_bc = genBarCode(l_sc,l_cat)
		LET l_bc = calcCheck(l_bc)
		DISPLAY "STK:",l_sc, " ",l_bc
		LET l_dc = discCode()
		LET l_pic = DOWNSHIFT("sd_"||(l_sup CLIPPED)||"_"||l_sn)
		INSERT INTO stock VALUES(l_sc,l_cat,NULL,l_sup,l_bc,l_ds,l_pr,l_cst,"1",l_dc,l_ps,l_al,l_fr,l_ld, l_pic)
--		DISPLAY "inserted."
	END FOREACH

	DISPLAY "stores_demo Customers"
	DECLARE sdcur2 CURSOR FOR
		SELECT customer_num, TRIM(fname)||" "||lname,company, address1,address2,city,state, "USA",zipcode
		FROM stores7:customer ORDER BY 1
	LET l_pwd = "password"
	FOREACH sdcur2 INTO l_sc, l_ds, l_ld, l_ad1,l_ad2,l_ad3,l_ad4,l_ad5,l_pc
		LET l_dc = discCode()
		DISPLAY "CST:",m_addr, " ",l_sc, " ",l_ld
		INSERT INTO customer VALUES(l_sc,l_ld,l_ds,l_em,l_pwd,m_addr,m_addr, l_dc, 8000, 0 ,0)
		INSERT INTO addresses VALUES(m_addr,l_ad1,l_ad2,l_ad3,l_ad4,"",l_pc,l_ad5)
		LET m_addr = m_addr + 1
	END FOREACH

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION discCode()
	DEFINE l_dc CHAR(2)
	CASE util.math.rand(5)
		WHEN 1 LET l_dc = "AA"
		WHEN 2 LET l_dc = "BB"
		WHEN 3 LET l_dc = "CC"
		WHEN 4 LET l_dc = "DD"
		OTHERWISE LET l_dc = "??"
	END CASE
	RETURN l_dc
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION officeStore()
	DEFINE
		l_sc CHAR(8),
		l_bc CHAR(13),
		l_ds,l_att CHAR(30),
		l_pr,l_cst DECIMAL(12,2),
		l_cat,l_sup,l_pwd CHAR(10),
		l_ld, l_pic,l_em VARCHAR(100),
		l_dc CHAR(2)
	DEFINE l_ps, l_al, l_fr INTEGER
	DEFINE l_ad1,l_ad2,l_ad3,l_ad4,l_ad5 VARCHAR(40)
	DEFINE l_pc CHAR(8)
	DEFINE l_stmt,l_stmt2 STRING
	DEFINE retry BOOLEAN
	DEFINE l_sep CHAR(1)
	LET l_sep = "."
	IF m_dbtyp = "ifx" THEN LET l_sep = ":" END IF
	LET l_stmt = "SELECT itemid, catid,supplier, prodname, proddesc, prodpic, listprice, unitcost, i.attr1
		FROM officestore",l_sep,"product p , OUTER officestore",l_sep,"item i WHERE p.productid = i.productid"
	LET l_stmt2 = "SELECT userid, TRIM(firstname)||\" \"||lastname,email, addr1,addr2,city,state, country,zip
		FROM officestore",l_sep,"account ORDER BY 1"
	LET retry = TRUE
	WHILE TRUE
		TRY
			DECLARE oscur CURSOR FROM l_stmt
			EXIT WHILE
		CATCH	
			IF NOT retry THEN
				DISPLAY "Officestore tables not found"
				RETURN
			END IF
			DISPLAY "Officestore not found, looking for tables."
			DISPLAY "Err:",SQLERRMESSAGE
			LET l_stmt = "SELECT itemid, catid,supplier, prodname, proddesc, prodpic, listprice, unitcost, i.attr1
			FROM product p , OUTER item i	WHERE p.productid = i.productid"
			LET l_stmt2 = "SELECT userid, TRIM(firstname)||\" \"||lastname,email, addr1,addr2,city,state, country,zip
			FROM account ORDER BY 1"
			LET retry = FALSE
		END TRY
		CONTINUE WHILE
	END WHILE
	DISPLAY "SQL:",l_stmt
	DISPLAY "Adding officestore stock data..."
	TRY
		FOREACH oscur INTO l_sc, l_cat, l_sup, l_ds, l_ld, l_pic, l_pr, l_cst,l_att

			IF l_cat = "ENTERTAIN" THEN
				LET l_cat = "SPORTS"
				CASE l_ds
					WHEN "Guitar" LET l_cat = "ENTERTAIN"
												LET l_sc = "EN-069-G"
												LET l_pr = "120.99"
					WHEN "Maracas" LET l_cat = "ENTERTAIN"
					WHEN "Chess game" LET l_cat = "GAMES"
					WHEN "Dice" LET l_cat = "GAMES"
				END CASE
			END IF

			IF l_sc IS NULL THEN CONTINUE FOREACH END IF

			IF l_att IS NULL THEN LET l_att =  "Unit" END IF
			IF l_att != "Unit" THEN
				LET l_ds = l_ds CLIPPED,"/",l_att
			END IF
			IF l_pr IS NULL THEN LET l_pr = 9.99 END IF
			IF l_cst IS NULL THEN LET l_cst = l_pr * .20 END IF
			LET l_sup = getSupp(l_cat)
			LET l_bc = genBarCode(l_sc,l_cat)
			LET l_bc = calcCheck(l_bc)
	--		DISPLAY l_sc, " ",l_bc
			LET l_ps = util.math.rand( 250 )
			LET l_ps = l_ps + 50
	--		DISPLAY l_sc, " ",l_bc," Stock:",l_ps
			LET l_al = util.math.rand( l_ps-20 )
			LET l_fr = l_ps - l_al
			DISPLAY l_cat," ",l_ds," ",l_sc, " ",l_bc," free:",l_fr
			LET l_dc = discCode()
			INSERT INTO stock VALUES(l_sc,l_cat,NULL,l_sup,l_bc,l_ds,l_pr,l_cst,"1",l_dc,l_ps,l_al,l_fr,l_ld, l_pic)
		END FOREACH
	CATCH
		DISPLAY "Status:",STATUS,":",ERR_GET(STATUS)
		DISPLAY "Officestore tables not found"
		RETURN
	END TRY
	DISPLAY "Adding officestore customer data..."
	LET l_pwd = "password"
	DECLARE oscur2 CURSOR FROM l_stmt2
	FOREACH oscur2 INTO l_sc, l_ds,l_em, l_ad1,l_ad2,l_ad3,l_ad4,l_ad5,l_pc
		LET l_ld = l_ds CLIPPED," Ltd"
		DISPLAY m_addr, " ",l_sc, " ",l_ld
		LET l_dc = discCode()
		INSERT INTO customer VALUES(l_sc,l_ld,l_ds,l_em,l_pwd,m_addr,m_addr, l_dc, 8000, 0 ,0)
		INSERT INTO addresses VALUES(m_addr,l_ad1,l_ad2,l_ad3,l_ad4,"",l_pc,l_ad5)
		LET m_addr = m_addr + 1
	END FOREACH
	DISPLAY "Done."
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION genBarCode(l_sc,l_cat)
	DEFINE
		l_sc CHAR(8),
		l_cat CHAR(10),
		l_bc CHAR(13)

	CASE l_cat
		WHEN "SPORT" LET l_bc = "060"
		WHEN "FRUIT" LET l_bc = "061"
		WHEN "SUPPLIES" LET l_bc = "062"
		WHEN "ARMY" LET l_bc = "063"
		WHEN "HOUSEHOLD" LET l_bc = "063"
		WHEN "GAMES" LET l_bc = "064"
		WHEN "ART" LET l_bc = "065"
		WHEN "ENTERTAIN" LET l_bc = "066"
		WHEN "FURNITURE" LET l_bc = "067"
		WHEN "TRAVELLING" LET l_bc = "068"
		OTHERWISE LET l_bc = "069"
	END CASE
	LET l_bc[4,11] = m_bc_cnt USING "&&&&&&&&"
	LET m_bc_cnt = m_bc_cnt + 1
--	DISPLAY "bar code:",l_bc
	RETURN l_bc
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION genOrders()
	DEFINE cst DYNAMIC ARRAY OF VARCHAR(8)
	DEFINE stk DYNAMIC ARRAY OF VARCHAR(8)
	DEFINE dets DYNAMIC ARRAY OF RECORD
		sc CHAR(8),
		qt SMALLINT
	END RECORD
	DEFINE z,x,y,q,c,s,l SMALLINT
	DEFINE dte DATE

	DECLARE cstcur CURSOR FOR SELECT customer_code FROM customer
	DECLARE stkcur CURSOR FOR SELECT stock_code FROM stock
	FOREACH cstcur INTO cst[ cst.getLength() + 1 ]
	END FOREACH
	FOREACH stkcur INTO stk[ stk.getLength() + 1 ]
	END FOREACH
	CALL cst.deleteElement( cst.getLength() )
	CALL stk.deleteElement( stk.getLength() )

	DISPLAY "Generating "||MAX_ORDERS||" Orders"
	FOR x = 1 TO MAX_ORDERS
		LET c = util.math.rand( cst.getLength() )
		IF c = 0 OR c > cst.getLength() THEN LET c = 3 END IF
		LET dte = "01/01/2004"
		LET dte = dte + util.math.rand(3650)
		CALL orderHead(cst[c] CLIPPED,dte)
		LET l = util.math.rand(MAX_LINES+1)
		CALL dets.clear()
		IF l >= stk.getLength() THEN LET l = stk.getLength() - 5 END IF
		IF l < 2 THEN LET l = 2 END IF
		FOR y = 1 TO l
			LET q = util.math.rand(MAX_QTY)
			IF q = 0 OR q > MAX_QTY THEN LET q = 5 END IF
			--DISPLAY "Details Line:",y," of",l," qty:",q," stklen:",stk.getLength()
			WHILE TRUE -- loop till we find a stock item that hasn't already be used.
				LET s = util.math.rand( stk.getLength() )
				IF s = 0 OR s > stk.getLength() THEN CONTINUE WHILE END IF
				FOR z = 1 TO dets.getLength()
					IF dets[z].sc = stk[s] THEN CONTINUE WHILE END IF
				END FOR
				EXIT WHILE
			END WHILE
			--DISPLAY "stk:",stk[s]
			LET dets[y].qt = q
			LET dets[y].sc = stk[s]
		END FOR
		FOR y = 1 TO dets.getLength()
			CALL orderDetail(dets[y].sc CLIPPED,dets[y].qt)
		END FOR
		UPDATE ord_head SET ord_head.* = m_ordHead.* WHERE order_number = m_ordHead.order_number
	END FOR
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION orderHead(cst,dte)
	DEFINE cst VARCHAR(8)
	DEFINE dte DATE
	DEFINE dt CHAR(20)
	DEFINE inv_ad, del_ad RECORD LIKE addresses.*

	SELECT * INTO m_cust.* FROM customer WHERE customer_code = cst
	SELECT * INTO del_ad.* FROM addresses WHERE rec_key = m_cust.del_addr
	SELECT * INTO inv_ad.* FROM addresses WHERE rec_key = m_cust.inv_addr
	LET m_ordHead.customer_name = m_cust.customer_name
	LET m_ordHead.del_address1 = del_ad.line1
	LET m_ordHead.del_address2 = del_ad.line2
	LET m_ordHead.del_address3 = del_ad.line3
	LET m_ordHead.del_address4 = del_ad.line4
	LET m_ordHead.del_address5 = del_ad.line5
	LET m_ordHead.del_postcode = del_ad.postal_code
	LET m_ordHead.inv_address1 = inv_ad.line1
	LET m_ordHead.inv_address2 = inv_ad.line2
	LET m_ordHead.inv_address3 = inv_ad.line3
	LET m_ordHead.inv_address4 = inv_ad.line4
	LET m_ordHead.inv_address5 = inv_ad.line5
	LET m_ordHead.inv_postcode = inv_ad.postal_code
	LET m_ordHead.items = 0
	LET m_ordHead.total_qty = 0
	LET m_ordHead.total_disc = 0
	LET m_ordHead.total_gross = 0
	LET m_ordHead.total_nett = 0
	LET m_ordHead.total_tax = 0

	LET m_ordHead.customer_code = cst
	LET m_ordHead.customer_name = m_cust.contact_name
	LET dt = dte USING "YYYY-MM-DD"
	LET m_ordHead.order_date = dte
	LET m_ordHead.order_datetime = dte
	LET m_ordHead.req_del_date = (dte + 10)
	LET m_ordHead.username = "auto"
	LET m_ordHead.order_ref = "Auto Generated "||m_ordHead.order_number||" "||TODAY
	INSERT INTO ord_head VALUES m_ordHead.* 
	LET m_ordHead.order_number = SQLCA.SQLERRD[2] -- Fetch SERIAL order num
	DISPLAY "Order Head:",m_ordHead.order_number,":",cst," ",dte
	LET m_ordDet.line_number = 0
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION orderDetail(stk,q)
	DEFINE stk CHAR(8)
	DEFINE q SMALLINT
	DEFINE stkrec RECORD LIKE stock.*
	DEFINE tax_rate DECIMAL(5,2)
	DEFINE pflag CHAR(1)

	LET tax_rate = 17.5
	SELECT price,tax_code, disc_code, pack_flag
		INTO stkrec.price, stkrec.tax_code, stkrec.disc_code, pflag FROM stock WHERE stock_code = stk
	IF STATUS = NOTFOUND THEN 
		DISPLAY "NOT FOUND STOCK ITEM '",stk,"'"
		RETURN 
	END IF
	SELECT disc_percent INTO m_ordDet.disc_percent FROM disc 
		WHERE stock_disc = stkrec.disc_code
			AND customer_disc = m_cust.disc_code
	IF STATUS = NOTFOUND THEN
		LET m_ordDet.disc_percent = 0
	END IF
	--DISPLAY "DETAIL LINE:",stk," QTY:",q
	LET m_ordDet.order_number = m_ordHead.order_number
	LET m_ordDet.line_number = m_ordDet.line_number + 1
	LET m_ordDet.price = stkrec.price
	LET m_ordDet.tax_code = stkrec.tax_code
	IF m_ordDet.tax_code = "1" THEN
		LET m_ordDet.tax_rate = tax_rate
	ELSE
		LET m_ordDet.tax_rate = 0
	END IF
	LET m_ordDet.quantity = q
	LET m_ordDet.stock_code = stk
	IF pflag = "E" THEN LET pflag = "P" END IF
	LET m_ordDet.pack_flag = pflag

	CALL oe_calcLineTot()

	INSERT INTO ord_detail VALUES( m_ordDet.* )

	LET m_ordHead.items =m_ordHead.items + 1
	LET m_ordHead.total_gross = m_ordHead.total_gross + m_ordDet.gross_value
	LET m_ordHead.total_nett = m_ordHead.total_nett + m_ordDet.nett_value
	LET m_ordHead.total_qty = m_ordHead.total_qty + m_ordDet.quantity
	LET m_ordHead.total_disc = m_ordHead.total_disc + m_ordDet.disc_value
	LET m_ordHead.total_tax = m_ordHead.total_tax + m_ordDet.tax_value

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION oe_calcLineTot()

	IF m_ordDet.price IS NULL THEN LET m_ordDet.price = 0 END IF
	IF m_ordDet.quantity IS NULL THEN LET m_ordDet.quantity = 0 END IF
	IF m_ordDet.disc_percent IS NULL THEN LET m_ordDet.disc_percent = 0 END IF
	IF m_ordDet.tax_rate IS NULL THEN LET m_ordDet.tax_rate = 0 END IF

	LET m_ordDet.gross_value = m_ordDet.price * m_ordDet.quantity
	LET m_ordDet.disc_value = m_ordDet.gross_value * ( m_ordDet.disc_percent / 100)
	LET m_ordDet.nett_value = m_ordDet.gross_value - m_ordDet.disc_value
	LET m_ordDet.tax_value = m_ordDet.nett_value * ( m_ordDet.tax_rate / 100 )
	LET m_ordDet.nett_value =  m_ordDet.nett_value + m_ordDet.tax_value 

END FUNCTION