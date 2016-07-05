
#+ Web Order Entry Demo - by N.J.Martin neilm@4js.com
#+
#+ $Id: webOE.4gl 960 2016-06-13 14:39:50Z neilm $

IMPORT FGL lib_weboe
IMPORT FGL genero_lib1
IMPORT FGL gl_db

CONSTANT PRGNAME = "webOE2"
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
		qty2 INTEGER,
		stock_code3 STRING,
		img3 STRING,
		desc3 STRING,
		qty3 INTEGER,
		stock_code4 STRING,
		img4 STRING,
		desc4 STRING,
		qty4 INTEGER
	END RECORD
	DEFINE m_form ui.Form
MAIN
	DEFINE l_cookie STRING
	DEFINE l_cc LIKE customer.customer_code
	DEFINE l_win ui.Window

	CALL gl_setInfo(NULL, "njm_demo_logo_256", "njm_demo", PRGNAME, PRGDESC, PRGAUTH)
	CALL gl_init(ARG_VAL(1),"weboe",TRUE)

	CALL gldb_connect(NULL)

	LET m_arg1 = ARG_VAL(1)
	IF m_arg1 IS NULL OR m_arg1 = " " THEN LET m_arg1 = "SDI" END IF

	LET m_dbtyp = gldb_getDBType()

	IF ui.Interface.getFrontEndName() != "GDC" THEN
		CALL ui.Interface.FrontCall("session","getvar","login",l_cookie)
		DISPLAY "From Cookie:",l_cookie
	END IF

	OPEN FORM weboe FROM "webOE2"
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
		IF m_stock_cats[ m_stock_cats.getLength() ].desc IS NOT NULL THEN
			CALL m_form.setElementText("cat"||m_stock_cats.getLength(), m_stock_cats[ m_stock_cats.getLength() ].desc)
			CALL m_form.setElementImage("cat"||m_stock_cats.getLength(), "products/"||DOWNSHIFT(m_stock_cats[ m_stock_cats.getLength() ].id CLIPPED))
			CALL m_form.setElementHidden("cat"||m_stock_cats.getLength(), FALSE)
		END IF
	END FOREACH
	CALL m_stock_cats.deleteElement( m_stock_cats.getLength() )

	DIALOG ATTRIBUTE(UNBUFFERED)
		{DISPLAY ARRAY m_stock_cats TO stkcats.*
			BEFORE ROW
				CALL getItems( m_stock_cats[ arr_curr() ].id )
		END DISPLAY}
		INPUT ARRAY m_items FROM items.* 
			ATTRIBUTES(WITHOUT DEFAULTS, DELETE ROW=FALSE, INSERT ROW=FALSE, APPEND ROW=FALSE)

			ON CHANGE qty1
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1)
			ON CHANGE qty2
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2)
			ON CHANGE qty3
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code3,m_items[DIALOG.getCurrentRow("items")].qty3)
			ON CHANGE qty4
				CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code4,m_items[DIALOG.getCurrentRow("items")].qty4)

			ON ACTION add1
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code1,m_items[DIALOG.getCurrentRow("items")].qty1+1)
			ON ACTION add2 
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code2,m_items[DIALOG.getCurrentRow("items")].qty2+1)
			ON ACTION add3
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code3,m_items[DIALOG.getCurrentRow("items")].qty3+1)
			ON ACTION add4
					CALL detLine(m_items[DIALOG.getCurrentRow("items")].stock_code4,m_items[DIALOG.getCurrentRow("items")].qty4+1)

			ON ACTION detlnk1 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code1,
																		 m_items[DIALOG.getCurrentRow("items")].desc1,
                                     m_items[DIALOG.getCurrentRow("items")].img1,
                                     m_items[DIALOG.getCurrentRow("items")].qty1 )
			ON ACTION detlnk2 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code2,
																		 m_items[DIALOG.getCurrentRow("items")].desc2,
                                     m_items[DIALOG.getCurrentRow("items")].img2,
                                     m_items[DIALOG.getCurrentRow("items")].qty2 )
			ON ACTION detlnk3 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code3,
																		 m_items[DIALOG.getCurrentRow("items")].desc3,
                                     m_items[DIALOG.getCurrentRow("items")].img3,
                                     m_items[DIALOG.getCurrentRow("items")].qty3 )
			ON ACTION detlnk4 CALL detLnk( m_items[DIALOG.getCurrentRow("items")].stock_code4,
																		 m_items[DIALOG.getCurrentRow("items")].desc4,
                                     m_items[DIALOG.getCurrentRow("items")].img4,
                                     m_items[DIALOG.getCurrentRow("items")].qty4 )
		END INPUT
		BEFORE DIALOG
			CALL DIALOG.setActionActive("viewb", FALSE)
			CALL DIALOG.setActionActive("gotoco", FALSE)
			CALL getItems( m_stock_cats[ 1 ].id )

		ON ACTION signin 
			CALL lib_weboe.signin()

		ON ACTION cat1 CALL getItems( m_stock_cats[ 1 ].id )
		ON ACTION cat2 CALL getItems( m_stock_cats[ 2 ].id )
		ON ACTION cat3 CALL getItems( m_stock_cats[ 3 ].id )
		ON ACTION cat4 CALL getItems( m_stock_cats[ 4 ].id )
		ON ACTION cat5 CALL getItems( m_stock_cats[ 5 ].id )
		ON ACTION cat6 CALL getItems( m_stock_cats[ 6 ].id )
		ON ACTION cat7 CALL getItems( m_stock_cats[ 7 ].id )
		ON ACTION cat8 CALL getItems( m_stock_cats[ 8 ].id )
		ON ACTION cat9 CALL getItems( m_stock_cats[ 9 ].id )
		ON ACTION cat10 CALL getItems( m_stock_cats[ 10 ].id )
		ON ACTION cat11 CALL getItems( m_stock_cats[ 11 ].id )
		ON ACTION cat12 CALL getItems( m_stock_cats[ 12 ].id )

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
	DEFINE rec SMALLINT
	DEFINE img STRING

	CALL m_items.clear()
	LET rec = 1
	FOREACH stkcur USING sc INTO l_stk.*
		LET img = "products/"||(l_stk.img_url CLIPPED)
		CASE rec
			WHEN 1
				LET m_items[ m_items.getLength() + 1 ].stock_code1 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img1 = img.trim()
				LET m_items[ m_items.getLength() ].desc1 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty1 = 0
			WHEN 2
				LET m_items[ m_items.getLength() ].stock_code2 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img2 = img.trim()
				LET m_items[ m_items.getLength() ].desc2 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty2 = 0
			WHEN 3
				LET m_items[ m_items.getLength() ].stock_code3 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img3 = img.trim()
				LET m_items[ m_items.getLength() ].desc3 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty3 = 0
			WHEN 4
				LET m_items[ m_items.getLength() ].stock_code4 = l_stk.stock_code
				LET m_items[ m_items.getLength() ].img4 = img.trim()
				LET m_items[ m_items.getLength() ].desc4 = mkDesc( l_stk.*)
				LET m_items[ m_items.getLength() ].qty4 = 0
				LET rec = 0
		END CASE
		LET rec = rec + 1
	END FOREACH
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION recalcOrder()
	DEFINE x,y SMALLINT

	FOR x = 1 TO m_items.getLength()
		LET m_items[x].qty1 = 0
		LET m_items[x].qty2 = 0
		LET m_items[x].qty3 = 0
		LET m_items[x].qty4 = 0
		FOR y = 1 TO g_detailArray.getLength()
			IF m_items[x].stock_code1 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty1 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code2 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty2 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code3 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty3 = g_detailArray[y].quantity
			END IF
			IF m_items[x].stock_code4 = g_detailArray[y].stock_code THEN
				LET m_items[x].qty4 = g_detailArray[y].quantity
			END IF
		END FOR
	END FOR

	CALL oe_uiUpdate()

END FUNCTION