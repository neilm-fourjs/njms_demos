
#+ Web Order Entry Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: webOE.4gl 961 2016-06-23 10:32:51Z neilm $

IMPORT FGL lib_weboe
IMPORT FGL genero_lib1
IMPORT FGL gl_db

CONSTANT PRGNAME = "webOE"
CONSTANT PRGDESC = "Web Ordering Demo"
CONSTANT PRGAUTH = "Neil J.Martin"

&include "schema.inc"
&include "ordent.inc"

DEFINE m_dbtyp STRING
DEFINE m_arg1 STRING
DEFINE m_stock_cats DYNAMIC ARRAY OF RECORD
		id LIKE stock_cat.catid,
		desc LIKE stock_cat.cat_name
	END RECORD
DEFINE m_items DYNAMIC ARRAY OF RECORD
		stock_code1 STRING,
		img1 STRING,
		desc1 STRING,
		qty1 INTEGER,
		stock_code2 STRING,
		img2 STRING,
		desc2 STRING,
		qty2 INTEGER
	END RECORD
	DEFINE m_form ui.Form
MAIN
	DEFINE l_cookie STRING
	DEFINE l_cc LIKE customer.customer_code
	DEFINE l_win ui.Window
	
	CALL genero_lib1.gl_setInfo(NULL, "njm_demo_logo_256", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL genero_lib1.gl_init(ARG_VAL(1),"weboe",TRUE)

	CALL gl_db.gldb_connect(NULL)

	LET m_arg1 = ARG_VAL(1)
	IF m_arg1 IS NULL OR m_arg1 = " " THEN LET m_arg1 = "SDI" END IF

	LET m_dbtyp = gldb_getDBType()

	IF ui.Interface.getFrontEndName() != "GDC" THEN
		CALL ui.Interface.FrontCall("session","getvar","login",l_cookie)
		DISPLAY "From Cookie:",l_cookie
	END IF

	OPEN FORM weboe FROM "webOE"
	DISPLAY FORM weboe

	LET l_win = ui.Window.getCurrent()
	LET m_form = l_win.getForm()

	CALL lib_weboe.initAll()

	IF l_cookie.getLength() > 0 THEN
		LET l_cc = l_cookie.trim()
		DISPLAY "Selecting customer_code:",l_cc
		SELECT * INTO g_cust.* FROM customer WHERE customer_code = l_cc
		IF STATUS = NOTFOUND THEN
			LET g_custcode = "Guest"
			LET g_custname = "Guest"
			LET g_cust.email = "Guest"
		ELSE
			LET g_custcode = g_cust.customer_code
			LET g_custname = g_cust.customer_name
			CALL oe_setHead( g_cust.customer_code,g_cust.del_addr,g_cust.inv_addr )
		END IF
	END IF

	CALL lib_weboe.logaccess( FALSE ,g_cust.email )
	DISPLAY "Customer:",g_custname
	DISPLAY g_custname TO custname

	CALL lib_weboe.build_sqls()
	DECLARE stkcur CURSOR FROM "SELECT * FROM stock WHERE stock_cat = ?"
	DECLARE sc_cur CURSOR FOR SELECT UNIQUE stock_cat.* FROM stock_cat, stock 
		WHERE stock.stock_cat = stock_cat.catid AND stock_cat.catid != "ARMS"
	FOREACH sc_cur INTO m_stock_cats[ m_stock_cats.getLength() + 1 ].*
	END FOREACH
	CALL m_stock_cats.deleteElement( m_stock_cats.getLength() )

	DIALOG ATTRIBUTE(UNBUFFERED)
		DISPLAY ARRAY m_stock_cats TO stkcats.*
			BEFORE ROW
				CLEAR FORM
				CALL getItems( m_stock_cats[ arr_curr() ].id )
		END DISPLAY
		INPUT ARRAY m_items FROM items.* ATTRIBUTES(WITHOUT DEFAULTS,
				DELETE ROW=FALSE,INSERT ROW=FALSE,APPEND ROW=FALSE)
			ON CHANGE qty1
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1)
			ON CHANGE qty2
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2)

			ON ACTION add1
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1+1)
					CALL recalcOrder()
			ON ACTION add2 
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2+1)
					CALL recalcOrder()
			ON ACTION detlnk1 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code1,
																		 m_items[DIALOG.getCurrentRow("items")].desc1,
                                     m_items[DIALOG.getCurrentRow("items")].img1,
                                     m_items[DIALOG.getCurrentRow("items")].qty1 )
			ON ACTION detlnk2 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code2,
																		 m_items[DIALOG.getCurrentRow("items")].desc2,
                                     m_items[DIALOG.getCurrentRow("items")].img2,
                                     m_items[DIALOG.getCurrentRow("items")].qty2 )
		END INPUT
		BEFORE DIALOG
			CALL DIALOG.setActionActive("viewb", FALSE)
			CALL DIALOG.setActionActive("gotoco", FALSE)

		ON ACTION signin
			CALL lib_weboe.signin()
		ON ACTION viewb CALL lib_weboe.viewb()
		ON ACTION gotoco CALL gotoco()
		ON ACTION about CALL genero_lib1.gl_about( NULL )
		ON ACTION close EXIT DIALOG
		ON ACTION cancel EXIT DIALOG
	END DIALOG

END MAIN
--------------------------------------------------------------------------------
FUNCTION getItems( sc )
	DEFINE sc LiKE stock_cat.catid
	DEFINE l_stk RECORD LIKE stock.*
	DEFINE row,rec SMALLINT
	DEFINE img STRING

	CALL m_items.clear()
	DISPLAY "sc:",sc
	LET row = 1
	LET rec = 1
	FOREACH stkcur USING sc INTO l_stk.*
		LET img = "products/"||(l_stk.img_url CLIPPED)
		IF rec MOD 2 THEN
			LET m_items[ row ].stock_code1 = l_stk.stock_code
			LET m_items[ row ].img1 = img.trim()
			LET m_items[ row ].desc1 = mkDesc( l_stk.*)
			LET m_items[ row ].qty1 = 0
		ELSE
			LET m_items[ row ].stock_code2 = l_stk.stock_code
			LET m_items[ row ].img2 = img.trim()
			LET m_items[ row ].desc2 = mkDesc( l_stk.*)
			LET m_items[ row ].qty2 = 0
			LET row = row + 1
		END IF
		LET rec = rec + 1
	END FOREACH
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION recalcOrder()
	DEFINE x,y SMALLINT

	FOR x = 1 TO m_items.getLength()
		LET m_items[x].qty1 = 0
		LET m_items[x].qty2 = 0
		FOR y = 1 TO g_detailArray.getLength()
			IF m_items[x].stock_code1 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty1 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code2 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty2 = g_detailArray[y].quantity
			END IF
		END FOR
	END FOR

	CALL oe_uiUpdate()
END FUNCTION